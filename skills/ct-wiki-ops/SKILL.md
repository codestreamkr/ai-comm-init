---
name: ct-wiki-ops
description: 사용자가 `$ct-wiki-ops`를 명시적으로 호출하면 현재 프로젝트의 Markdown 위키 규칙을 확인해 초기화, 수집, 반영, 조회와 품질 점검을 수행한다. 지원 작업은 `init`, `capture`, `ingest`, `search`, `log`, `daily`, `synthesis`, `verify`, `lint`, `prune`이다.
---

# CT Wiki Ops

프로젝트의 `LLM-WIKI.md`와 현재 위키 구조를 기준으로 작업한다.

## 호출

- `$ct-wiki-ops` 또는 `$ct-wiki-ops ?`: 작업 목록과 대표 예제를 안내한다.
- `$ct-wiki-ops <작업> ?`: 해당 작업의 입력, 출력과 예제를 안내한다.
- `$ct-wiki-ops <작업> <대상>`: 지정한 작업을 실행한다.

## 작업

- `init`: 위키 운영 기준과 기본 구조를 준비한다.
  - 예: `$ct-wiki-ops init`
- `capture`: 사용자가 제공한 원문을 위키 원문 영역에 저장한다.
  - 예: `$ct-wiki-ops capture 회의록.md`
- `ingest`: 원문을 근거로 관련 위키 문서를 생성하거나 갱신한다.
  - 예: `$ct-wiki-ops ingest .wiki/raw/회의록.md`
- `search`: 위키 근거로 질문에 답한다.
  - 예: `$ct-wiki-ops search 결제 개편 결정 사항은?`
- `log`: 지정 기간의 위키 작업을 요약한다.
  - 예: `$ct-wiki-ops log 지난 7일`
- `daily`: 오늘의 위키 변경과 남은 작업을 요약한다.
  - 예: `$ct-wiki-ops daily`
- `synthesis`: 여러 문서를 하나의 주제로 종합한다.
  - 예: `$ct-wiki-ops synthesis 결제 개편`
- `verify`: 문서의 근거와 현재성을 검증한다.
  - 예: `$ct-wiki-ops verify .wiki/payment.md`
- `lint`: 위키 구조, 링크와 필수 메타정보를 점검한다.
  - 예: `$ct-wiki-ops lint`
- `prune`: 중복·오래된 문서의 정리 후보를 제안한다.
  - 예: `$ct-wiki-ops prune`

## 자료 수집

- 적용되는 프로젝트 규칙 문서
- 프로젝트의 `LLM-WIKI.md`
- `.wiki/index.md`와 관련 문서
- 요청 작업에 필요한 원문과 현재 코드

`init`은 현재 프로젝트에 필요한 위키 기준을 수집해 `LLM-WIKI.md`와 기본 구조를 제안한다.

## 실행

1. 요청 작업과 대상을 확인한다.
2. 프로젝트 위키 규칙과 관련 근거를 읽는다.
3. 선택한 작업에 필요한 파일만 처리한다.
4. 링크, 출처와 현재성을 가능한 범위에서 검증한다.

## 출력

- 처리한 작업과 파일
- 사용한 근거
- 생성·수정 또는 조회 결과
- 확인이 필요한 항목

## 완료 조건

- 결과가 프로젝트 위키 규칙과 일치한다.
- 작성된 내용이 확인한 원문이나 코드와 연결된다.
- 미확인 내용이 사실처럼 확정되지 않는다.
