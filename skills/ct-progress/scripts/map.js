#!/usr/bin/env node
// 프로세스 맵 도구
//   node map.js serve [--port N]             맵 서버 실행 (기본 포트 4319). 모든 저장소의 맵을 보여 준다
//   node map.js emit <저장소> '<이벤트 JSON>' 이벤트 한 줄 추가
//   node map.js emit <저장소> -              이벤트 JSON을 표준 입력으로 받는다 (Windows PowerShell 5.1용)
//   node map.js clear <저장소>               현재 작업 데이터 삭제
//   node map.js path <저장소>                데이터 파일 경로 출력
//   node map.js status [--port N]            서버 상태 확인. 종료 코드 0 실행 중, 1 꺼짐, 2 다른 프로그램이 포트 사용
// 데이터는 OS 임시 폴더에만 둔다. 저장소에는 파일을 남기지 않는다.

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

// 이벤트 종류 (키를 짧게 두어 토큰을 줄인다)
//   실행 시작: {"run":"apply-1","skill":"ct-apply","title":"...","steps":[{"id":"a1","name":"...","after":["..."],"agent":"haiku","user":true}]}
//   단계 추가: {"run":"apply-1","add":{"id":"f1","name":"...","after":["t1"]}}
//   상태 변경: {"run":"apply-1","step":"a1","s":"start|done|fail|wait|skip","note":"...","ask":"...","tok":1200}
//   ADR 후보: {"run":"plan-1","adr":{"id":"c1","title":"...","why":"...","from":"...","s":"cand|ok|drop"}}
// 자동 보충 (런타임 세션 기록을 읽을 수 있을 때만)
//   실행 시작에 model이 없으면 메인 모델을 채운다.
//   단계 done|fail|skip에 m이 없으면 그 시점의 메인 모델을 채운다. 메인이 중간에 모델을 바꾼 경우를 표시한다.
//   단계 start 시점의 누적 토큰을 저장하고, done|fail|skip에 tok이 없으면 차이를 채운다.
//   세션 기록 찾는 순서: 셸 현재 폴더 → 대상 저장소 → 최근 10분 안에 갱신된 세션 기록 중 최신
//   서브에이전트 단계(agent)는 Claude Code의 <세션>/subagents/agent-<id>.jsonl에서 모델과 토큰을 채운다.
//   완료 이벤트에 "sub":"<id>"가 있으면 그 파일을, 없으면 단계 시작 이후 갱신된 최신 파일을 쓴다.
//   토큰 = 새 입력 + 출력. 캐시에서 다시 읽은 입력은 제외한다.
const STATUSES = ['start', 'done', 'fail', 'wait', 'skip'];
const HTML_FILE = path.join(__dirname, '..', 'assets', 'process-map.html');
const ROOT = path.join(os.tmpdir(), 'ct-progress');

// 저장소마다 폴더를 나눈다. 이름이 같은 저장소가 섞이지 않도록 절대 경로 해시를 붙인다.
function repoKey(repo) {
  const abs = path.resolve(repo || process.cwd());
  return `${path.basename(abs)}-${require('crypto').createHash('sha1').update(abs).digest('hex').slice(0, 8)}`;
}
const dataFile = repo => path.join(ROOT, repoKey(repo), 'live.jsonl');

// Claude Code: ~/.claude/projects/<경로를 -로 바꾼 이름>/*.jsonl. 메시지 id로 중복을 제거한다.
function claudeFile(repo) {
  const root = path.join(os.homedir(), '.claude', 'projects');
  const slug = p => path.resolve(p).replace(/[/.\\:]/g, '-');
  const newest = dir => {
    try {
      return fs.readdirSync(dir).filter(f => f.endsWith('.jsonl'))
        .map(f => ({ f: path.join(dir, f), t: fs.statSync(path.join(dir, f)).mtimeMs }))
        .sort((a, b) => b.t - a.t)[0] || null;
    } catch { return null; }
  };
  for (const p of [process.cwd(), repo]) { const n = newest(path.join(root, slug(p))); if (n) return n.f; }
  let best = null;
  for (const d of fs.readdirSync(root)) { const n = newest(path.join(root, d)); if (n && (!best || n.t > best.t)) best = n; }
  return best && Date.now() - best.t < 10 * 60 * 1000 ? best.f : null;
}

function claudeUsage(repo) {
  const file = claudeFile(repo);
  return file ? usageOf(file) : null;
}

// 서브에이전트 기록: 메인 세션 기록 옆의 <세션 id>/subagents/ 폴더
function subagentUsage(repo, sub, since) {
  const main = claudeFile(repo);
  if (!main) return null;
  const dir = path.join(main.replace(/\.jsonl$/, ''), 'subagents');
  let file = sub ? path.join(dir, `agent-${sub}.jsonl`) : null;
  if (!file) {
    const cands = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl'))
      .map(f => ({ f: path.join(dir, f), t: fs.statSync(path.join(dir, f)).mtimeMs }))
      .filter(x => x.t >= since).sort((a, b) => b.t - a.t);
    file = cands.length ? cands[0].f : null;
  }
  return file && fs.existsSync(file) ? usageOf(file) : null;
}

function usageOf(file) {
  const byId = new Map();
  let model = null;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    if (!line.includes('"usage"')) continue;
    try {
      const m = JSON.parse(line).message;
      if (!m || !m.usage) continue;
      const u = m.usage;
      byId.set(m.id || byId.size, (u.input_tokens || 0) + (u.cache_creation_input_tokens || 0) + (u.output_tokens || 0));
      model = m.model || model;
    } catch {}
  }
  return { model, tok: [...byId.values()].reduce((a, b) => a + b, 0) };
}

// Codex: $CODEX_HOME/sessions/YYYY/MM/DD/rollout-*.jsonl 중 cwd가 저장소인 최신 파일. 마지막 token_count가 누적값이다.
function codexUsage(repo) {
  const root = path.join(process.env.CODEX_HOME || path.join(os.homedir(), '.codex'), 'sessions');
  const desc = d => fs.readdirSync(d).sort().reverse().map(n => path.join(d, n));
  let checked = 0;
  for (const y of desc(root)) for (const m of desc(y)) for (const d of desc(m)) for (const f of desc(d)) {
    if (!f.endsWith('.jsonl') || ++checked > 30) return null;
    let cwd = null, model = null, info = null;
    for (const line of fs.readFileSync(f, 'utf8').split('\n')) {
      try {
        const e = JSON.parse(line), p = e.payload || {};
        if (e.type === 'session_meta') cwd = p.cwd;
        if (e.type === 'turn_context') model = p.model || model;
        if (p.type === 'token_count' && p.info) info = p.info.total_token_usage;
      } catch {}
    }
    if (cwd && [process.cwd(), repo].some(p => path.resolve(cwd) === path.resolve(p)) && info) {
      return { model, tok: (info.input_tokens || 0) - (info.cached_input_tokens || 0) + (info.output_tokens || 0) };
    }
  }
  return null;
}

function usage(repo) {
  for (const fn of [claudeUsage, codexUsage]) { try { const u = fn(repo); if (u) return u; } catch {} }
  return null;
}

function fillUsage(repo, ev) {
  const needModel = ev.steps && !ev.model;
  const isStart = ev.step && ev.s === 'start';
  const isEnd = ev.step && ['done', 'fail', 'skip'].includes(ev.s);
  if (!needModel && !isStart && !isEnd) return;
  const stateFile = path.join(path.dirname(dataFile(repo)), 'usage.json');
  let state = {};
  try { state = JSON.parse(fs.readFileSync(stateFile, 'utf8')); } catch {}
  const key = `${ev.run}/${ev.step}`;
  const start = typeof state[key] === 'number' ? { tok: state[key], t: 0 } : state[key];
  if (isEnd && isAgentStep(repo, ev.run, ev.step)) {
    let su = null;
    try { su = subagentUsage(repo, ev.sub, start ? start.t : 0); } catch {}
    if (su) { if (!ev.m && su.model) ev.m = su.model; if (ev.tok == null && su.tok) ev.tok = su.tok; }
    delete state[key];
    fs.writeFileSync(stateFile, JSON.stringify(state));
    return;
  }
  const u = usage(repo);
  if (!u) return;
  if (needModel && u.model) ev.model = u.model;
  if (isEnd && !ev.m && u.model) ev.m = u.model;
  if (isStart) state[key] = { tok: u.tok, t: Date.now() };
  if (isEnd && ev.tok == null && start && u.tok > start.tok) ev.tok = u.tok - start.tok;
  if (isStart || isEnd) {
    if (isEnd) delete state[key];
    fs.mkdirSync(path.dirname(stateFile), { recursive: true });
    fs.writeFileSync(stateFile, JSON.stringify(state));
  }
}

// 실행 시작과 단계 추가 이벤트에서 그 단계에 agent가 있는지 찾는다.
function isAgentStep(repo, run, step) {
  let agent = false;
  try {
    for (const line of fs.readFileSync(dataFile(repo), 'utf8').split('\n')) {
      if (!line) continue;
      const e = JSON.parse(line);
      if (e.run !== run) continue;
      const def = (e.steps || []).find(x => x.id === step) || (e.add && e.add.id === step ? e.add : null);
      if (def && 'agent' in def) agent = !!def.agent;
    }
  } catch {}
  return agent;
}

function emit(repo, json) {
  const ev = JSON.parse(json);
  if (!ev.run) throw new Error('run 필드가 필요하다.');
  if (!Array.isArray(ev.steps) && !ev.add && !ev.step && !ev.adr) throw new Error('steps, add, step, adr 중 하나가 필요하다.');
  if (ev.adr && (!ev.adr.id || !['cand', 'ok', 'drop', undefined].includes(ev.adr.s))) throw new Error('adr에는 id가 필요하고 s는 cand|ok|drop 중 하나다.');
  if (ev.step && !STATUSES.includes(ev.s)) throw new Error(`s는 ${STATUSES.join('|')} 중 하나다.`);
  ev.t = ev.t || new Date().toISOString();
  fillUsage(repo, ev);
  const file = dataFile(repo);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(path.join(path.dirname(file), 'repo.json'), JSON.stringify({ path: path.resolve(repo || process.cwd()) }));
  fs.appendFileSync(file, JSON.stringify(ev) + '\n');
}

// 맵 데이터가 있는 저장소 목록. 최근에 갱신된 저장소가 앞에 온다.
function repos() {
  let keys = [];
  try { keys = fs.readdirSync(ROOT); } catch {}
  return keys.map(key => {
    const dir = path.join(ROOT, key);
    try {
      const mtime = fs.statSync(path.join(dir, 'live.jsonl')).mtimeMs;
      let repoPath = '';
      try { repoPath = JSON.parse(fs.readFileSync(path.join(dir, 'repo.json'), 'utf8')).path; } catch {}
      return { key, name: path.basename(repoPath) || key, path: repoPath, mtime };
    } catch { return null; }
  }).filter(Boolean).sort((a, b) => b.mtime - a.mtime);
}

function serve(port) {
  http.createServer((req, res) => {
    const [url, query = ''] = req.url.split('?');
    const send = (status, type, body) => {
      res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store' });
      res.end(body);
    };
    if (url === '/') return fs.readFile(HTML_FILE, (err, buf) => err ? send(500, 'text/plain', String(err)) : send(200, 'text/html; charset=utf-8', buf));
    if (url === '/repos') return send(200, 'application/json; charset=utf-8', JSON.stringify(repos()));
    if (url === '/live.jsonl') {
      // repo 값이 없으면 가장 최근에 갱신된 저장소를 보여 준다. 폴더 이름만 허용한다.
      const key = new URLSearchParams(query).get('repo') || (repos()[0] || {}).key || '';
      if (!/^[^/\\]+$/.test(key) || key === '.' || key === '..') return send(200, 'application/x-ndjson; charset=utf-8', '');
      return fs.readFile(path.join(ROOT, key, 'live.jsonl'), (err, buf) => send(200, 'application/x-ndjson; charset=utf-8', err ? '' : buf));
    }
    send(404, 'text/plain', 'not found');
  }).listen(port, '127.0.0.1', () => console.log(`process map: http://127.0.0.1:${port}\ndata: ${ROOT}`));
}

// 맵 서버만 /repos에 JSON 배열로 응답한다. 이것으로 다른 프로그램과 구분한다.
function status(port) {
  const url = `http://127.0.0.1:${port}`;
  const req = http.get(`${url}/repos`, { timeout: 1500 }, res => {
    let body = '';
    res.on('data', c => { body += c; });
    res.on('end', () => {
      let ours = false;
      try { ours = Array.isArray(JSON.parse(body)); } catch {}
      if (ours) { console.log(`running ${url}`); process.exit(0); }
      console.error(`다른 프로그램이 쓰는 포트다: ${port}. --port로 다른 포트를 지정한다.`);
      process.exit(2);
    });
  });
  req.on('timeout', () => req.destroy(new Error('timeout')));
  req.on('error', () => { console.log(`stopped ${url}`); process.exit(1); });
}

const [cmd, ...args] = process.argv.slice(2);
const portIdx = args.indexOf('--port');
const port = portIdx >= 0 ? Number(args.splice(portIdx, 2)[1]) : Number(process.env.CT_MAP_PORT || 4319);

try {
  if (cmd === 'serve') serve(port);
  else if (cmd === 'emit') emit(args[0], args[1] === '-' ? fs.readFileSync(0, 'utf8') : args[1]);
  else if (cmd === 'clear') { fs.rmSync(dataFile(args[0]), { force: true }); fs.rmSync(path.join(path.dirname(dataFile(args[0])), 'usage.json'), { force: true }); }
  else if (cmd === 'path') console.log(dataFile(args[0]));
  else if (cmd === 'status') status(port);
  else { console.error('사용법: node map.js serve|emit|clear|path|status ...'); process.exit(2); }
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
