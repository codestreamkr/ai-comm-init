#!/usr/bin/env node
// 이해 게이트 통과 표시 도구
//   node gate.js mark <저장소> [메모]   현재 작업 트리 상태에 통과 표시를 남긴다
//   node gate.js check <저장소>         커밋할 인덱스 상태에 통과 표시가 있는지 확인한다 (없으면 종료 코드 1)
//   node gate.js tree <저장소> [--index] 작업 트리(기본) 또는 인덱스의 트리 id를 출력한다
// 통과 표시는 <git-dir>/understand-gate/<트리 id>에 둔다. 저장소 이력에는 남지 않는다.
// 작업 트리와 인덱스를 같은 트리 id로 비교하므로, 커밋 내용이 debrief 때와 같을 때만 통과한다.

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const git = (repo, args, env) => execFileSync('git', args, { cwd: repo, env: { ...process.env, ...env }, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();

function worktreeTree(repo) {
  const tmp = path.join(os.tmpdir(), `ct-gate-index-${process.pid}`);
  const env = { GIT_INDEX_FILE: tmp };
  try {
    try { git(repo, ['read-tree', 'HEAD'], env); } catch { git(repo, ['read-tree', '--empty'], env); }
    git(repo, ['add', '-A'], env);
    return git(repo, ['write-tree'], env);
  } finally {
    fs.rmSync(tmp, { force: true });
  }
}

const indexTree = repo => git(repo, ['write-tree']);
const markDir = repo => path.resolve(repo, git(repo, ['rev-parse', '--git-dir']), 'understand-gate');

const [cmd, repo = '.', ...rest] = process.argv.slice(2);
try {
  if (!fs.existsSync(repo)) throw new Error(`저장소 경로가 없다: ${repo}`);
  if (cmd === 'mark') {
    const tree = worktreeTree(repo);
    fs.mkdirSync(markDir(repo), { recursive: true });
    fs.writeFileSync(path.join(markDir(repo), tree), JSON.stringify({ t: new Date().toISOString(), note: rest.join(' ') }) + '\n');
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
