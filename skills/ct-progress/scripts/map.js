#!/usr/bin/env node
// 프로세스 맵 도구
//   node map.js serve [--port N]             맵 서버 실행 (기본 포트 4319). 모든 저장소의 맵을 보여 준다
//   node map.js emit <저장소> '<이벤트 JSON>' 이벤트 한 줄 추가
//   node map.js emit <저장소> -              이벤트 JSON을 표준 입력으로 받는다 (Windows PowerShell 5.1용)
//   node map.js clear <저장소>               현재 작업 데이터 삭제
//   node map.js path <저장소>                데이터 파일 경로 출력
//   node map.js status [--port N]            서버 상태 확인. 종료 코드 0 실행 중, 1 꺼짐, 2 다른 프로그램이 포트 사용, 3 다른 버전의 맵 서버 실행 중
//   node map.js stop [--port N]              맵 서버 종료
// 데이터는 OS 임시 폴더에만 둔다. 저장소에는 파일을 남기지 않는다.

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

// 이벤트 종류 (키를 짧게 두어 토큰을 줄인다)
//   실행 시작: {"run":"apply-1","skill":"ct-apply","title":"...","model":"claude-opus-5-5","usage":{"file":"...","kind":"message"},"steps":[{"id":"a1","name":"...","after":["..."],"agent":"claude-haiku-5-5","user":true}]}
//   단계 추가: {"run":"apply-1","add":{"id":"f1","name":"...","after":["t1"]}}
//   상태 변경: {"run":"apply-1","step":"a1","s":"start|done|fail|wait|skip","note":"...","ask":"...","tok":1200,"m":"...","usage":{...}}
//   ADR 후보: {"run":"plan-1","adr":{"id":"c1","title":"...","why":"...","from":"...","s":"cand|ok|drop"}}
// 토큰 계산 (맵 서버가 응답할 때. 기록 반영이 늦어도 다음 갱신 때 맞는 값이 된다)
//   usage는 에이전트가 특정한 사용량 기록이다. 런타임 이름으로 분기하지 않고 기록 형식(kind)으로 계산한다.
//     message: 줄마다 message.usage와 timestamp가 있다. 누적 = 그 시각까지 메시지별 (input + cache_creation_input + output)의 합
//     total:   줄마다 payload.info.total_token_usage와 timestamp가 있다. 누적 = 그 시각까지 마지막 (input - cached_input + output)
//   메인 단계: done|fail|skip에 tok이 없으면 누적(완료 시각) - 누적(시작 시각). 기록은 실행 시작의 usage다.
//   서브에이전트 단계: 완료 이벤트에 usage가 있으면 그 기록의 마지막 누적이다.
//   토큰 = 새 입력 + 출력. 캐시에서 다시 읽은 입력은 제외한다.
const STATUSES = ['start', 'done', 'fail', 'wait', 'skip'];
const KINDS = ['message', 'total'];
const HTML_FILE = path.join(__dirname, '..', 'assets', 'process-map.html');
const ROOT = path.join(os.tmpdir(), 'ct-progress');
// 실행 중인 서버가 이 파일과 같은 코드인지 확인하는 값
const VERSION = crypto.createHash('sha1').update(fs.readFileSync(__filename)).digest('hex').slice(0, 12);

// 저장소마다 폴더를 나눈다. 이름이 같은 저장소가 섞이지 않도록 절대 경로 해시를 붙인다.
function repoKey(repo) {
  const abs = path.resolve(repo || process.cwd());
  return `${path.basename(abs)}-${crypto.createHash('sha1').update(abs).digest('hex').slice(0, 8)}`;
}
const dataFile = repo => path.join(ROOT, repoKey(repo), 'live.jsonl');

// 사용량 기록을 시각 순 누적값 목록 [{t, cum}]으로 만든다. 파일이 바뀔 때만 다시 읽는다.
const cumCache = new Map();
function cumulative(usage) {
  const st = fs.statSync(usage.file);
  const key = `${usage.kind}:${usage.file}`;
  const hit = cumCache.get(key);
  if (hit && hit.mtime === st.mtimeMs && hit.size === st.size) return hit.points;
  const points = [];
  if (usage.kind === 'message') {
    const byId = new Map();
    for (const line of fs.readFileSync(usage.file, 'utf8').split('\n')) {
      if (!line.includes('"usage"')) continue;
      try {
        const e = JSON.parse(line), m = e.message;
        if (!m || !m.usage) continue;
        const u = m.usage, id = m.id || byId.size;
        const t = byId.has(id) ? byId.get(id).t : Date.parse(e.timestamp) || 0;
        byId.set(id, { t, tok: (u.input_tokens || 0) + (u.cache_creation_input_tokens || 0) + (u.output_tokens || 0) });
      } catch {}
    }
    let cum = 0;
    for (const x of [...byId.values()].sort((a, b) => a.t - b.t)) points.push({ t: x.t, cum: (cum += x.tok) });
  } else {
    for (const line of fs.readFileSync(usage.file, 'utf8').split('\n')) {
      if (!line.includes('total_token_usage')) continue;
      try {
        const e = JSON.parse(line), u = ((e.payload || {}).info || {}).total_token_usage;
        if (u) points.push({ t: Date.parse(e.timestamp) || 0, cum: (u.input_tokens || 0) - (u.cached_input_tokens || 0) + (u.output_tokens || 0) });
      } catch {}
    }
  }
  cumCache.set(key, { mtime: st.mtimeMs, size: st.size, points });
  return points;
}

// 시각 t까지의 누적값
function cumAt(usage, t) {
  let v = 0;
  for (const p of cumulative(usage)) { if (p.t > t) break; v = p.cum; }
  return v;
}

// 비어 있는 단계 토큰을 채운다. 실행 시작의 usage와 단계 시작 시각을 이벤트 순서대로 추적한다.
function withTokens(text) {
  const runUsage = {}, started = {}, agentStep = {};
  return text.split('\n').map(line => {
    if (!line) return line;
    try {
      const ev = JSON.parse(line);
      if (ev.steps) {
        if (ev.usage) runUsage[ev.run] = ev.usage;
        for (const s of ev.steps) agentStep[`${ev.run}/${s.id}`] = !!s.agent;
      }
      if (ev.add && ev.add.id && 'agent' in ev.add) agentStep[`${ev.run}/${ev.add.id}`] = !!ev.add.agent;
      if (!ev.step) return line;
      const key = `${ev.run}/${ev.step}`;
      if (ev.s === 'start') { started[key] = Date.parse(ev.t); return line; }
      if (!['done', 'fail', 'skip'].includes(ev.s) || ev.tok != null) return line;
      let tok = 0;
      if (ev.usage) tok = cumAt(ev.usage, Infinity);
      else if (!agentStep[key] && runUsage[ev.run] && started[key]) tok = cumAt(runUsage[ev.run], Date.parse(ev.t)) - cumAt(runUsage[ev.run], started[key]);
      if (tok <= 0) return line;
      ev.tok = tok;
      return JSON.stringify(ev);
    } catch { return line; }
  }).join('\n');
}

function checkUsage(u) {
  if (u && (typeof u.file !== 'string' || !KINDS.includes(u.kind))) throw new Error(`usage에는 file과 kind(${KINDS.join('|')})가 필요하다.`);
}

function emit(repo, json) {
  const ev = JSON.parse(json);
  if (!ev.run) throw new Error('run 필드가 필요하다.');
  if (!Array.isArray(ev.steps) && !ev.add && !ev.step && !ev.adr) throw new Error('steps, add, step, adr 중 하나가 필요하다.');
  if (ev.adr && (!ev.adr.id || !['cand', 'ok', 'drop', undefined].includes(ev.adr.s))) throw new Error('adr에는 id가 필요하고 s는 cand|ok|drop 중 하나다.');
  if (ev.step && !STATUSES.includes(ev.s)) throw new Error(`s는 ${STATUSES.join('|')} 중 하나다.`);
  checkUsage(ev.usage);
  ev.t = ev.t || new Date().toISOString();
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
  const server = http.createServer((req, res) => {
    const [url, query = ''] = req.url.split('?');
    const send = (status, type, body) => {
      res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store' });
      res.end(body);
    };
    if (url === '/') return fs.readFile(HTML_FILE, (err, buf) => err ? send(500, 'text/plain', String(err)) : send(200, 'text/html; charset=utf-8', buf));
    if (url === '/repos') return send(200, 'application/json; charset=utf-8', JSON.stringify(repos()));
    if (url === '/version') return send(200, 'text/plain', VERSION);
    if (url === '/stop') { send(200, 'text/plain', 'stopped'); return server.close(() => process.exit(0)); }
    if (url === '/live.jsonl') {
      // repo 값이 없으면 가장 최근에 갱신된 저장소를 보여 준다. 폴더 이름만 허용한다.
      const key = new URLSearchParams(query).get('repo') || (repos()[0] || {}).key || '';
      if (!/^[^/\\]+$/.test(key) || key === '.' || key === '..') return send(200, 'application/x-ndjson; charset=utf-8', '');
      return fs.readFile(path.join(ROOT, key, 'live.jsonl'), 'utf8', (err, text) => send(200, 'application/x-ndjson; charset=utf-8', err ? '' : withTokens(text)));
    }
    send(404, 'text/plain', 'not found');
  });
  server.listen(port, '127.0.0.1', () => console.log(`process map: http://127.0.0.1:${port}\ndata: ${ROOT}\nversion: ${VERSION}`));
}

function get(url, done) {
  const req = http.get(url, { timeout: 1500 }, res => {
    let body = '';
    res.on('data', c => { body += c; });
    res.on('end', () => done(null, res.statusCode, body));
  });
  req.on('timeout', () => req.destroy(new Error('timeout')));
  req.on('error', err => done(err));
}

// 맵 서버만 /repos에 JSON 배열로 응답한다. 이것으로 다른 프로그램과 구분한다.
function status(port) {
  const url = `http://127.0.0.1:${port}`;
  get(`${url}/repos`, (err, code, body) => {
    if (err) { console.log(`stopped ${url}`); process.exit(1); }
    let ours = false;
    try { ours = Array.isArray(JSON.parse(body)); } catch {}
    if (!ours) { console.error(`다른 프로그램이 쓰는 포트다: ${port}. --port로 다른 포트를 지정한다.`); process.exit(2); }
    get(`${url}/version`, (err2, code2, ver) => {
      if (!err2 && code2 === 200 && ver.trim() === VERSION) { console.log(`running ${url}`); process.exit(0); }
      console.error(`다른 버전의 맵 서버다: ${url}. stop으로 끄고 serve로 다시 연다.`);
      process.exit(3);
    });
  });
}

// /stop이 없는 이전 버전 서버는 끌 수 없다. 그 포트를 쓰는 프로세스를 직접 종료하도록 알린다.
function stop(port) {
  const url = `http://127.0.0.1:${port}`;
  get(`${url}/stop`, (err, code) => {
    if (err) { console.log(`stopped ${url}`); process.exit(0); }
    if (code === 200) { console.log(`stopped ${url}`); process.exit(0); }
    console.error(`종료 요청을 지원하지 않는 서버다: ${url}. 포트 ${port}를 쓰는 프로세스를 직접 종료한다.`);
    process.exit(1);
  });
}

const [cmd, ...args] = process.argv.slice(2);
const portIdx = args.indexOf('--port');
const port = portIdx >= 0 ? Number(args.splice(portIdx, 2)[1]) : Number(process.env.CT_MAP_PORT || 4319);

try {
  if (cmd === 'serve') serve(port);
  else if (cmd === 'emit') emit(args[0], args[1] === '-' ? fs.readFileSync(0, 'utf8') : args[1]);
  else if (cmd === 'clear') fs.rmSync(dataFile(args[0]), { force: true });
  else if (cmd === 'path') console.log(dataFile(args[0]));
  else if (cmd === 'status') status(port);
  else if (cmd === 'stop') stop(port);
  else { console.error('사용법: node map.js serve|emit|clear|path|status|stop ...'); process.exit(2); }
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
