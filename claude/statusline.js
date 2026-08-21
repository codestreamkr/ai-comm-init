#!/usr/bin/env node
// Claude Code StatusLine - Author: codestream
const { execSync } = require('child_process');
const path = require('path');

let raw = '';
process.stdin.on('data', chunk => raw += chunk);
process.stdin.on('end', () => {
    let data = {};
    try { data = JSON.parse(raw); } catch {}

    const sessionId = (data.session_id || '').slice(0, 8);
    const cwd = data.workspace?.current_dir || data.cwd || '';
    const model = data.model?.display_name || '';
    const style = data.output_style?.name || '';
    const pct = Math.floor(data.context_window?.used_percentage || 0);

    let branch = '';
    try {
        branch = execSync('git branch --show-current', {
            cwd: cwd || undefined,
            encoding: 'utf8',
            stdio: ['pipe', 'pipe', 'ignore']
        }).trim();
    } catch {}

    const gitInfo = branch ? `(${branch})` : '';

    const fiveHour = data.rate_limits?.five_hour;
    const sevenDay = data.rate_limits?.seven_day;

    const fmtTime = epoch => {
        if (typeof epoch !== 'number') return '';
        const d = new Date(epoch * 1000);
        return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    };

    const parts = [`[${sessionId}] ${cwd} ${gitInfo}`, model, style, `ctx:${pct}%`];

    const resetAt = fmtTime(fiveHour?.resets_at);
    if (resetAt) parts.push(`reset ${resetAt}`);

    if (typeof fiveHour?.used_percentage === 'number') {
        parts.push(`5h:${Math.floor(fiveHour.used_percentage)}%`);
    }
    if (typeof sevenDay?.used_percentage === 'number') {
        parts.push(`7d:${Math.floor(sevenDay.used_percentage)}%`);
    }

    process.stdout.write(parts.join(' | '));
});
