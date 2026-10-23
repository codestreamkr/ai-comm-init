#!/usr/bin/env node
// ct 기록 통계 도구
//   node stats.js <저장소> [--since YYYY-MM-DD] [--until YYYY-MM-DD]
// .debrief/의 Markdown 기록만 읽는다. 결과는 Markdown으로 출력한다.
// 형식에 맞지 않는 줄은 버리지 않는다. "형식 외 기록" 절에 위치와 함께 보여 준다.

const fs = require('fs');
const path = require('path');

const TYPES = ['왜', '만약', '어디'];
const VERDICTS = ['정답', '재질문 후 정답', '오답'];
const ADR_VERDICTS = ['확정', '폐기', '보류'];
const DEBT_ACTIONS = ['추가', '해소'];
const KNOWN_FIELDS = ['결과', '결정', '사용자 참여', '이해 확인', '질문', 'ADR', '부채', '남은 항목'];
const WEAK_MIN_QUESTIONS = 2;
const WEAK_MAX_RATE = 70;

const HEAD = /^## (\d{4}-\d{2}-\d{2}) (\S+) · (\S+) · (.+)$/;
const FIELD = /^- ([^:]+): (.*)$/;

const readLines = file => fs.readFileSync(file, 'utf8').replace(/^﻿/, '').split(/\r?\n/);
const listMd = dir => fs.existsSync(dir) ? fs.readdirSync(dir).filter(f => f.endsWith('.md')).sort().map(f => path.join(dir, f)) : [];
const rate = (n, d) => d ? `${Math.round(n * 100 / d)}%` : '-';
const cell = s => String(s).replace(/\|/g, '\\|');
const table = (head, rows) => rows.length
  ? [`| ${head.join(' | ')} |`, `|${head.map(() => '---').join('|')}|`, ...rows.map(r => `| ${r.map(cell).join(' | ')} |`)].join('\n')
  : '없음';

function parseArgs(argv) {
  const opts = { repo: '.', since: null, until: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--since') opts.since = argv[++i];
    else if (argv[i] === '--until') opts.until = argv[++i];
    else opts.repo = argv[i];
  }
  for (const key of ['since', 'until']) {
    if (opts[key] != null && !/^\d{4}-\d{2}-\d{2}$/.test(opts[key])) throw new Error(`--${key}는 YYYY-MM-DD로 쓴다: ${opts[key]}`);
  }
  return opts;
}

// 실행 기록: ## 날짜 run · 스킬 · 제목 아래의 "- 항목: 값" 줄
function parseJournal(file, rel, unparsed) {
  const entries = [];
  let entry = null;
  readLines(file).forEach((text, i) => {
    const at = `${rel}:${i + 1}`;
    if (!text.trim() || /^# /.test(text)) return;
    const head = text.match(HEAD);
    if (head) {
      entry = { date: head[1], run: head[2], skill: head[3], title: head[4], at, result: null, rounds: null, questions: [], adrs: [], debts: [] };
      entries.push(entry);
      return;
    }
    const field = text.match(FIELD);
    if (!entry || !field || !KNOWN_FIELDS.includes(field[1])) { unparsed.push([at, text]); return; }
    const [, key, value] = field;
    const parts = value.split(' · ');
    if (key === '결과') {
      entry.result = value.split(/[ (]/)[0];
      const rounds = value.match(/검증 (\d+)회차/);
      if (rounds) entry.rounds = Number(rounds[1]);
    } else if (key === '질문') {
      if (parts.length < 4 || !TYPES.includes(parts[0]) || !VERDICTS.includes(parts[2])) { unparsed.push([at, text]); return; }
      entry.questions.push({ type: parts[0], domain: parts[1], verdict: parts[2], gist: parts.slice(3).join(' · ') });
    } else if (key === 'ADR') {
      if (parts.length < 2 || !ADR_VERDICTS.includes(parts[1])) { unparsed.push([at, text]); return; }
      entry.adrs.push({ id: parts[0], verdict: parts[1] });
    } else if (key === '부채') {
      if (parts.length < 3 || !DEBT_ACTIONS.includes(parts[0])) { unparsed.push([at, text]); return; }
      entry.debts.push({ action: parts[0], domain: parts[1] });
    }
  });
  return entries;
}

// Markdown 표의 본문 행. 머리 행과 구분 행은 뺀다.
function tableRows(file) {
  if (!fs.existsSync(file)) return [];
  const rows = readLines(file).filter(l => /^\|.*\|\s*$/.test(l))
    .map(l => l.trim().slice(1, -1).split(/(?<!\\)\|/).map(c => c.trim()));
  return rows.slice(2);
}

function adrMeta(file) {
  const meta = {};
  for (const line of readLines(file)) {
    const m = line.match(/^- (상태|도메인): (.+)$/);
    if (m && !meta[m[1]]) meta[m[1]] = m[2].trim();
  }
  return meta;
}

// 질문 목록 → [질문 수, 첫 시도 정답, 재질문 후 정답, 오답]
function tally(questions) {
  const count = v => questions.filter(q => q.verdict === v).length;
  return [questions.length, count('정답'), count('재질문 후 정답'), count('오답')];
}

function groupBy(items, key) {
  const map = new Map();
  for (const item of items) {
    const k = key(item);
    if (!map.has(k)) map.set(k, []);
    map.get(k).push(item);
  }
  return [...map.entries()].sort(([a], [b]) => String(a).localeCompare(String(b)));
}

function report(opts) {
  const repo = path.resolve(opts.repo);
  const base = path.join(repo, '.debrief');
  const rel = file => path.relative(repo, file).split(path.sep).join('/');
  if (!fs.existsSync(base)) return `# ct 기록 통계\n\n- 저장소: ${repo}\n- 기록 없음: \`.debrief/\`가 없다.\n`;

  const unparsed = [];
  const journalFiles = listMd(path.join(base, 'journal'));
  const entries = journalFiles.flatMap(f => parseJournal(f, rel(f), unparsed))
    .filter(e => (!opts.since || e.date >= opts.since) && (!opts.until || e.date <= opts.until));
  const questions = entries.flatMap(e => e.questions.map(q => ({ ...q, entry: e })));
  const debtRows = tableRows(path.join(base, 'debt.md'));
  const candidateRows = tableRows(path.join(base, 'decisions', 'candidates.md'));
  const decisionsDir = path.join(base, 'decisions');
  const adrFiles = listMd(decisionsDir).filter(f => /^\d{4}-/.test(path.basename(f)));
  const archivedFiles = listMd(path.join(decisionsDir, 'archive')).filter(f => /^\d{4}-/.test(path.basename(f)));
  const out = [];

  out.push('# ct 기록 통계', '');
  out.push(`- 저장소: ${repo}`);
  out.push(`- 기간: ${opts.since || '처음'} ~ ${opts.until || '마지막'} (실행 기록 ${entries.length}건)`);
  out.push(`- 근거 파일: ${[...journalFiles, path.join(base, 'debt.md'), path.join(decisionsDir, 'candidates.md')].filter(fs.existsSync).map(f => `\`${rel(f)}\``).join(', ') || '없음'}`);
  out.push(`- ADR 파일: \`${rel(decisionsDir)}/\` ${adrFiles.length}개, \`archive/\` ${archivedFiles.length}개`, '');

  out.push('## 실행', '');
  out.push(table(['스킬', '실행', '완료', '중단', '기타'], groupBy(entries, e => e.skill).map(([skill, list]) => {
    const done = list.filter(e => e.result === '완료').length, stop = list.filter(e => e.result === '중단').length;
    return [skill, list.length, done, stop, list.length - done - stop];
  })), '');

  const verified = entries.filter(e => e.rounds != null);
  const retried = verified.filter(e => e.rounds >= 2);
  out.push('## 검증', '');
  out.push(`- 검증 회차가 있는 실행: ${verified.length}건`);
  out.push(`- 평균 검증 회차: ${verified.length ? (verified.reduce((s, e) => s + e.rounds, 0) / verified.length).toFixed(1) : '-'}`);
  out.push(`- 재검증한 실행(2회차 이상): ${retried.length}건${retried.length ? ` (${retried.map(e => `${e.date} ${e.run}`).join(', ')})` : ''}`, '');

  const qRow = (label, list) => { const [n, ok, retry, wrong] = tally(list); return [label, n, ok, retry, wrong, rate(ok, n)]; };
  const qHead = ['구분', '질문', '첫 시도 정답', '재질문 후 정답', '오답', '첫 시도 정답률'];
  out.push('## 이해 확인', '');
  out.push(table(qHead, questions.length ? [qRow('전체', questions)] : []), '');
  out.push('### 월별', '', table(qHead, groupBy(questions, q => q.entry.date.slice(0, 7)).map(([k, l]) => qRow(k, l))), '');
  out.push('### 유형별', '', table(qHead, groupBy(questions, q => q.type).map(([k, l]) => qRow(k, l))), '');
  const byDomain = groupBy(questions, q => q.domain);
  out.push('### 도메인별', '', table([...qHead, '근거 실행'], byDomain.map(([k, l]) =>
    [...qRow(k, l), [...new Set(l.map(q => `${q.entry.date} ${q.entry.run}`))].join(', ')])), '');

  const adrs = entries.flatMap(e => e.adrs);
  out.push('## 결정', '');
  out.push(`- 실행 기록의 ADR 판정: ${ADR_VERDICTS.map(v => `${v} ${adrs.filter(a => a.verdict === v).length}`).join(', ')}`, '');
  const adrMetas = [...adrFiles.map(f => ({ ...adrMeta(f), archived: false })), ...archivedFiles.map(f => ({ ...adrMeta(f), archived: true }))];
  out.push(table(['도메인', '유효 ADR', '대체됨·폐기'], groupBy(adrMetas, m => m['도메인'] || '(없음)').map(([k, l]) =>
    [k, l.filter(m => !m.archived && m['상태'] === '채택').length, l.filter(m => m.archived || m['상태'] !== '채택').length])), '');

  out.push('## 남은 항목 (현재)', '');
  out.push(`- ADR 후보: ${candidateRows.length}건`);
  out.push(`- 이해 부채: ${debtRows.length}건`, '');
  out.push(table(['도메인', '이해 부채', '발생 실행'], groupBy(debtRows, r => r[0] || '(없음)').map(([k, l]) =>
    [k, l.length, [...new Set(l.map(r => r[4] || '-'))].join(', ')])), '');

  const debtCount = new Map(groupBy(debtRows, r => r[0] || '(없음)').map(([k, l]) => [k, l.length]));
  const qByDomain = new Map(byDomain);
  const weak = [...new Set([...qByDomain.keys(), ...debtCount.keys()])].sort().filter(d => {
    const [n, ok] = tally(qByDomain.get(d) || []);
    return debtCount.get(d) || (n >= WEAK_MIN_QUESTIONS && ok * 100 / n < WEAK_MAX_RATE);
  });
  out.push('## 보강 대상 도메인', '');
  out.push(`- 기준: 질문 ${WEAK_MIN_QUESTIONS}개 이상이고 첫 시도 정답률이 ${WEAK_MAX_RATE}% 미만이다. 또는 남은 이해 부채가 있다.`, '');
  out.push(table(['도메인', '첫 시도 정답', '남은 부채', '근거 실행'], weak.map(d => {
    const list = qByDomain.get(d) || [];
    const [n, ok] = tally(list);
    return [d, n ? `${ok}/${n} (${rate(ok, n)})` : '-', debtCount.get(d) || 0, [...new Set(list.map(q => `${q.entry.date} ${q.entry.run}`))].join(', ') || '-'];
  })), '');

  out.push('## 형식 외 기록', '');
  out.push('- 집계하지 못한 줄이다. 기록 형식에 맞게 고치면 다음 집계에 반영된다.', '');
  out.push(table(['위치', '내용'], unparsed), '');
  return out.join('\n');
}

try {
  process.stdout.write(report(parseArgs(process.argv.slice(2))));
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
