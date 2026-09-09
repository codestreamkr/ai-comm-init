#!/usr/bin/env node
// Grok status line: paint session fields from stdin; weekly usage from a cache
// written by this same script on SessionStart / turn-end hooks.
const fs = require('fs');
const https = require('https');
const os = require('os');
const path = require('path');

const grokHome = process.env.GROK_HOME || path.join(os.homedir(), '.grok');
const cachePath = path.join(grokHome, 'usage-cache.json');
const authPath = path.join(grokHome, 'auth.json');
const FETCH_MS = 8000;

let raw = '';
process.stdin.on('data', chunk => raw += chunk);
process.stdin.on('end', () => {
    let data = {};
    try { data = JSON.parse(raw); } catch {}

    const event = hookEvent(data);
    if (event) {
        if (shouldFetch(event, data)) fetchUsage();
        else process.exit(0);
        return;
    }
    paint(data);
});

function hookEvent(data) {
    const name = data.hook_event_name || data.hookEventName || '';
    if (!name) return '';
    return String(name).replace(/_/g, '').toLowerCase();
}

function shouldFetch(event, data) {
    if (data.subagentType) return false;
    if (event === 'sessionstart') return true;
    if (event === 'stopfailure' || event === 'stopcancelled') return true;
    if (event === 'stop') return data.reason === 'end_turn' || !data.reason;
    return false;
}

function paint(data) {
    const sessionId = (data.session_id || data.sessionId || '').slice(0, 8);
    const cwd = data.workspace?.current_dir || data.cwd || '';
    const model = data.model?.display_name || '';
    const pct = Math.floor(data.context_window?.used_percentage || 0);
    const branch = data.workspace?.branch || '';
    const gitInfo = branch ? `(${branch})` : '';

    const parts = [];
    if (sessionId || cwd) parts.push(`[${sessionId}] ${cwd} ${gitInfo}`.trim());
    if (model) parts.push(model);
    if (data.context_window && typeof data.context_window.used_percentage === 'number') {
        parts.push(`ctx:${pct}%`);
    }

    const cache = readCache();
    if (typeof cache.usedPercent === 'number') parts.push(`wk:${Math.floor(cache.usedPercent)}%`);
    const resetAt = fmtTime(cache.resetsAt);
    if (resetAt) parts.push(`reset ${resetAt}`);

    process.stdout.write(parts.join(' | '));
}

function readCache() {
    try { return JSON.parse(fs.readFileSync(cachePath, 'utf8')); }
    catch { return {}; }
}

function fmtTime(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '';
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

function loadAuth() {
    const data = JSON.parse(fs.readFileSync(authPath, 'utf8'));
    const entries = Object.values(data).filter(e => e && e.key);
    entries.sort((a, b) => String(b.expires_at || '').localeCompare(String(a.expires_at || '')));
    return entries[0] || null;
}

function fetchUsage() {
    let auth;
    try { auth = loadAuth(); } catch (e) {
        process.stderr.write(`usage-cache: auth read failed: ${e.message}\n`);
        process.exit(0);
        return;
    }
    if (!auth) {
        process.stderr.write('usage-cache: no token\n');
        process.exit(0);
        return;
    }

    const req = https.get({
        hostname: 'cli-chat-proxy.grok.com',
        path: '/v1/billing?format=credits',
        headers: {
            Authorization: `Bearer ${auth.key}`,
            'X-XAI-Token-Auth': 'xai-grok-cli',
            'x-userid': auth.user_id || '',
            Accept: 'application/json',
        },
    }, res => {
        let body = '';
        res.on('data', c => body += c);
        res.on('end', () => {
            if (res.statusCode !== 200) {
                process.stderr.write(`usage-cache: HTTP ${res.statusCode}\n`);
                process.exit(0);
                return;
            }
            try { writeCache(body); }
            catch (e) { process.stderr.write(`usage-cache: ${e.message}\n`); }
            process.exit(0);
        });
    });
    req.on('error', e => {
        process.stderr.write(`usage-cache: ${e.message}\n`);
        process.exit(0);
    });
    req.setTimeout(FETCH_MS, () => {
        req.destroy();
        process.stderr.write('usage-cache: timeout\n');
        process.exit(0);
    });
}

function writeCache(body) {
    const json = JSON.parse(body);
    const cfg = json.config || json;
    const period = cfg.currentPeriod || {};
    const used = cfg.creditUsagePercent;
    const end = period.end || cfg.billingPeriodEnd;
    if (typeof used !== 'number' && !end) throw new Error('empty billing payload');
    const tmp = `${cachePath}.${process.pid}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify({
        fetchedAt: new Date().toISOString(),
        usedPercent: typeof used === 'number' ? used : undefined,
        resetsAt: end || undefined,
        periodType: period.type || undefined,
    }));
    fs.renameSync(tmp, cachePath);
}
