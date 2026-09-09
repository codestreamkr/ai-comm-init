---
name: ct-wiki-ops
description: 사용자가 `$ct-wiki-ops`를 명시적으로 호출하면 프로젝트 Markdown 위키 규칙으로 초기화, 수집, 반영, 조회와 품질 점검을 수행한다. 지원 작업은 `init`, `capture`, `ingest`, `search`, `log`, `merge`, `verify`, `lint`, `prune`이다.
---

# CT Wiki Ops

정본은 프로젝트의 `LLM-WIKI.md`와 현재 위키다. 조직 지식을 다루며, 코드 정본 구현 문서는 `ct-docs-impl`이다.

## 호출

- `$ct-wiki-ops` 또는 `$ct-wiki-ops ?`: 안내. 실행하지 않는다.
- `$ct-wiki-ops <작업> ?`: 해당 작업 안내.
- `$ct-wiki-ops <작업> <대상>`: 실행.

첫 토큰이 지원 작업이 아니면 안내만 한다. `--`로 시작하면 지원하지 않는 옵션이다. 대상이 필요한 작업은 대상 없이 실행하지 않는다.

## 작업

- `init`: 위키 기준과 기본 구조를 준비한다. `$ct-wiki-ops init`
- `capture`: 원문을 위키 원문 영역에 저장한다. `$ct-wiki-ops capture 회의록.md`
- `ingest`: 원문으로 관련 위키 문서를 만들거나 고친다. `$ct-wiki-ops ingest .wiki/raw/회의록.md`
- `search`: 위키 근거로 질문에 답한다. `$ct-wiki-ops search 결제 개편 결정`
- `log`: 지정 기간 요약을 한다. 기간이 없거나 오늘이면 오늘의 변경과 남은 작업이다. `$ct-wiki-ops log 지난 7일`
- `merge`: 여러 위키 문서를 한 주제로 합친다. `$ct-wiki-ops merge 결제 개편`
- `verify`: 근거와 현재성을 검증한다. `$ct-wiki-ops verify .wiki/payment.md`
- `lint`: 구조·링크·필수 메타를 점검한다. `$ct-wiki-ops lint`
- `prune`: 중복·오래된 문서의 정리 후보를 제안한다. `$ct-wiki-ops prune`

## 역할 규칙

- `init`은 현재 프로젝트에 필요한 기준을 모아 `LLM-WIKI.md`와 기본 구조를 제안한다.
- `ingest`와 `merge`는 원문이나 코드에 없는 사실을 만들지 않는다. 미확인은 사실처럼 쓰지 않는다.
- 원격 Confluence 입출력은 `ct-wiki-api`다.
- 선택한 작업에 필요한 파일만 다룬다.
