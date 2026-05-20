---
name: wiki-ops
description: "Use only when the user explicitly invokes `$wiki-ops`. Supported actions after the skill name: init, capture, ingest, search, log, daily, synthesis, verify, lint, prune. Examples: `$wiki-ops init`, `$wiki-ops search OO회의 언제지?`, `$wiki-ops ingest 회의록 정리해줘`, `$wiki-ops log 지난 7일`. Do not trigger without `$wiki-ops`."
metadata:
  short-description: Operate raw/wiki Markdown knowledge wikis
---

# Wiki Ops

이 Skill은 프로젝트별 Markdown 지식 위키를 운영한다.

## 적용 기준

현재 작업 디렉터리를 위키 프로젝트 루트로 본다.

- 프로젝트 규칙은 현재 프로젝트의 `AGENTS.md`를 우선한다.
- 사람용 안내는 현재 프로젝트의 `README.md`를 참고한다.
- 원문 자료는 `raw/`에 둔다.
- LLM이 작성하거나 수정하는 문서는 `wiki/`에 둔다.
- `raw/` 안의 원문은 수정하지 않는다.
- 문서 본문에는 최종본만 남긴다.
- 변경 이력은 문서 맨 끝 `## 이력관리`에만 남긴다.

## 명령 선택

사용자 요청이 `$wiki-ops`로 시작할 때만 reference를 하나 읽는다.

- 호출 형식: `$wiki-ops <작업> <질의 또는 대상>`
- 작업 다음 텍스트는 그대로 사용자 질의로 처리한다.

작업별 reference는 `$wiki-ops` 다음 첫 단어로 고른다.

- `init`: `references/wiki-init.md`
- `capture`: `references/wiki-capture.md`
- `ingest`: `references/wiki-ingest.md`
- `search`: `references/wiki-search.md`
- `log`: `references/wiki-log.md`
- `daily`: `references/wiki-daily.md`
- `synthesis`: `references/wiki-synthesis.md`
- `verify`: `references/wiki-verify.md`
- `lint`: `references/wiki-lint.md`
- `prune`: `references/wiki-prune.md`

## 호출 제한

명시적인 `$wiki-ops` 호출이 없으면 이 Skill을 적용하지 않는다.

- `$wiki-ops init`: 적용한다.
- `$wiki-ops search OO회의 언제지?`: 적용한다.
- `$wiki-ops ingest 회의록 정리해줘`: 적용한다.
- `$wiki-ops log 1주일간 정리된 내용 알려줘`: 적용한다.
- `$wiki-ops verify wiki/index.md`: 적용한다.

## 공통 절차

작업 전 프로젝트 상태를 확인한다.

- `AGENTS.md`가 있으면 먼저 읽는다.
- `wiki/index.md`가 있으면 관련 문서 탐색의 출발점으로 쓴다.
- `wiki/log.md`가 있으면 작업 이력과 최근 변경 흐름을 확인한다.
- 독립적인 조회와 검증은 병렬로 실행한다.
- 파일 수정 전에는 어떤 파일을 왜 수정하는지 짧게 알린다.

## 공통 출력

결과는 바로 실행 가능한 형태로 짧게 쓴다.

- 처리한 파일
- 생성하거나 수정한 문서
- 남은 확인 필요 항목
- 실행하지 못한 검증

## 날짜

오늘 날짜가 필요하면 시스템 날짜를 사용한다.

- 이력관리 형식: `- YYYY-MM-DD: 변경 내용 요약`
- 웹 출처 확인일 형식: `YYYY-MM-DD`
