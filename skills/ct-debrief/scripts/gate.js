#!/usr/bin/env node
// 이해 게이트 통과 표시 도구
//   node gate.js mark <저장소> [메모] -- <파일>... 확인한 파일만 반영한 트리에 통과 표시를 남긴다 (.debrief/ 제외)
//   node gate.js check <저장소>         커밋할 인덱스 상태에 통과 표시가 있는지 확인한다 (없으면 종료 코드 1)
//   node gate.js tree <저장소> [--index] 작업 트리(기본) 또는 인덱스의 트리 id를 출력한다
// 통과 표시는 <git-dir>/understand-gate/v2/<트리 id>에 둔다. 이전 버전 표시는 쓰지 않는다.
// 작업 트리와 인덱스를 같은 트리 id로 비교하므로, 커밋 내용이 debrief 때와 같을 때만 통과한다.
// ct 기록(.debrief/)은 이해 확인 대상이 아니므로 트리 비교에서 뺀다.

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const EXCLUDE = '.debrief';
const git = (repo, args, env) => execFileSync('git', args, { cwd: repo, env: { ...process.env, ...env }, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();

function writeTree(repo, env) {
  git(repo, ['--literal-pathspecs', 'rm', '-r', '--cached', '-q', '--ignore-unmatch', '--', EXCLUDE], env);
  return git(repo, ['write-tree'], env);
}

function worktreeTree(repo, files) {
  const tmp = path.join(os.tmpdir(), `ct-gate-index-${process.pid}`);
  const env = { GIT_INDEX_FILE: tmp };
  try {
    try { git(repo, ['read-tree', 'HEAD'], env); } catch { git(repo, ['read-tree', '--empty'], env); }
    git(repo, ['--literal-pathspecs', 'add', '-A', ...(files ? ['--', ...files] : [])], env);
    return writeTree(repo, env);
  } finally {
    fs.rmSync(tmp, { force: true });
  }
}

function indexTree(repo) {
  const tmp = path.join(os.tmpdir(), `ct-gate-index-${process.pid}`);
  const index = path.resolve(repo, git(repo, ['rev-parse', '--git-path', 'index']));
  try {
    if (fs.existsSync(index)) fs.copyFileSync(index, tmp);
    return writeTree(repo, { GIT_INDEX_FILE: tmp });
  } finally {
    fs.rmSync(tmp, { force: true });
  }
}
const markDir = repo => path.resolve(repo, git(repo, ['rev-parse', '--git-dir']), 'understand-gate', 'v2');

const [cmd, inputRepo = '.', ...rest] = process.argv.slice(2);
try {
  if (!fs.existsSync(inputRepo)) throw new Error(`저장소 경로가 없다: ${inputRepo}`);
  const repo = git(inputRepo, ['rev-parse', '--show-toplevel']);
  if (cmd === 'mark') {
    const sep = rest.indexOf('--');
    const files = sep < 0 ? [] : rest.slice(sep + 1);
    if (!files.length) throw new Error('확인한 파일을 -- 뒤에 지정한다. 저장소 루트 기준 경로를 쓴다.');
    for (const file of files) {
      const rel = path.relative(repo, path.resolve(repo, file));
      if (!rel || rel === '..' || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel) || rel.split(path.sep).includes('.git')) throw new Error(`허용하지 않는 파일 경로다: ${file}`);
      if (fs.existsSync(path.resolve(repo, file)) && fs.lstatSync(path.resolve(repo, file)).isDirectory()) throw new Error(`폴더 대신 확인한 파일을 지정한다: ${file}`);
      if (!fs.existsSync(path.resolve(repo, file))) {
        const tracked = git(repo, ['--literal-pathspecs', 'ls-files', '-z', '--', file]).split('\0');
        try { tracked.push(...git(repo, ['--literal-pathspecs', 'ls-tree', '-r', '--name-only', '-z', 'HEAD', '--', file]).split('\0')); } catch {}
        if (!tracked.includes(rel.split(path.sep).join('/'))) throw new Error(`추적한 파일 경로가 아니다: ${file}`);
      }
    }
    const tree = worktreeTree(repo, files);
    fs.mkdirSync(markDir(repo), { recursive: true });
    fs.writeFileSync(path.join(markDir(repo), tree), JSON.stringify({ t: new Date().toISOString(), note: rest.slice(0, sep).join(' '), files }) + '\n');
    console.log(`marked ${tree}`);
  } else if (cmd === 'check') {
    const tree = indexTree(repo);
    if (fs.existsSync(path.join(markDir(repo), tree))) { console.log(`passed ${tree}`); }
    else { console.error(`이해 게이트를 통과하지 않은 변경이다 (${tree}). ct-debrief를 먼저 실행한다.`); process.exit(1); }
  } else if (cmd === 'tree') {
    console.log(rest.includes('--index') ? indexTree(repo) : worktreeTree(repo));
  } else {
    console.error('사용법: node gate.js mark|check|tree <저장소> ...');
    process.exit(2);
  }
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
