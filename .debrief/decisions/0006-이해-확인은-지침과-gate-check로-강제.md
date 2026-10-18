# 0006. 이해 확인은 훅 없이 전역 지침과 gate.js check로 강제

- 날짜: 2026-10-18
- 상태: 채택
- 도메인: gate
- 관련 실행: apply-6, debrief-1
- 영향 문서: claude/CLAUDE.md, codex/AGENTS.md, grok/AGENTS.md, pi/AGENTS.md, agy/GEMINI.md

## 맥락

- Claude, Codex, Gemini, Grok, Pi가 같은 스킬과 지침을 쓴다.
- 연쇄 흐름 밖의 코드 변경도 이해 확인이 필요하다.

## 결정

- 전역 지침 5개에 같은 `### 이해 확인` 절을 둔다.
- 커밋 전에 `gate.js check`를 실행하고, 실패하면 `ct-debrief`를 먼저 실행한다.

## 이유

> 훅없이 다른 ai 에서도 사용가능한 구조여야해.

## 버린 대안

- Claude `PreToolUse` 훅으로 커밋 차단: Claude에서만 동작한다.
