#!/usr/bin/env node
// Claude Code StatusLine - Author: codestream

let raw = '';
process.stdin.on('data', chunk => raw += chunk);
process.stdin.on('end', () => {
    let data = {};
    try { data = JSON.parse(raw); } catch {}

    const sessionId = (data.session_id || '').slice(0, 8);
    const model = data.model?.display_name || '';
    const usage = data.context_window?.current_usage;
    const cacheRead = usage?.cache_read_input_tokens || 0;
    const cacheTotal = cacheRead + (usage?.cache_creation_input_tokens || 0) + (usage?.input_tokens || 0);
    const pct = Math.floor(data.context_window?.used_percentage || 0);

    const fiveHour = data.rate_limits?.five_hour;
    const sevenDay = data.rate_limits?.seven_day;

    const fmtTime = epoch => {
        if (typeof epoch !== 'number') return '';
        const d = new Date(epoch * 1000);
        return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    };

    const parts = [`[${sessionId}]`, model];
    if (cacheTotal > 0) parts.push(`ch:${Math.floor(cacheRead / cacheTotal * 100)}%`);
    parts.push(`ctx:${pct}%`);

    if (typeof fiveHour?.used_percentage === 'number') {
        parts.push(`5h:${Math.floor(fiveHour.used_percentage)}%`);
    }
    if (typeof sevenDay?.used_percentage === 'number') {
        parts.push(`7d:${Math.floor(sevenDay.used_percentage)}%`);
    }

    const resetAt = fmtTime(fiveHour?.resets_at);
    if (resetAt) parts.push(`reset ${resetAt}`);

    process.stdout.write(parts.join(' | '));
});
