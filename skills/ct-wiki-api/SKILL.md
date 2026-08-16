---
name: ct-wiki-api
description: 사용자가 `$ct-wiki-api`를 명시적으로 호출하면 포함된 PowerShell 도구와 현재 환경변수를 사용해 Confluence REST API 호환 위키를 검색, 조회, 저장하거나 명시된 변경을 수행한다.
---

# CT Wiki API

포함된 `scripts/wiki-api.ps1`을 위키 API 작업의 실행 계약으로 사용한다.

## 호출

- `$ct-wiki-api` 또는 `$ct-wiki-api ?`: 사용 가능한 작업과 대표 예제를 안내한다.
- `$ct-wiki-api <요청>`: 요청을 가장 직접적인 도구 명령으로 실행한다.

예제:

- `$ct-wiki-api 333 페이지를 조회해줘`
- `$ct-wiki-api 결제 개편 문서를 검색해줘`
- `$ct-wiki-api 333 페이지와 하위 페이지를 저장해줘`
- `$ct-wiki-api 333 페이지 수정안을 dry-run으로 확인해줘`

## 도구 작업

- 환경 확인: `check-env`
- 검색: `search`, `smart-search`
- 조회: `get-page`, `get-comments`, `get-attachments`, `get-child-pages`, `get-descendant-pages`, `get-labels`, `get-history`, `get-restrictions`, `get-page-bundle`
- 저장: `save-page`, `save-comments`
- 변경: `create-page`, `update-page`

`$ct-wiki-api <도구 작업> ?`가 입력되면 해당 작업의 필수 인자와 실제 예제를 안내한다.

## 실행 준비

1. 현재 스킬 디렉터리를 기준으로 `scripts/wiki-api.ps1`을 찾는다.
2. `check-env`로 필요한 환경변수의 설정 여부만 확인한다.
3. 사용자의 page id, URL, 제목, Space와 저장 요청을 도구 인자로 변환한다.

인증값은 현재 프로세스 환경변수에서 읽고 값 자체를 출력하지 않는다. 실제 페이지 변경은 dry-run 결과를 먼저 제시하고 사용자가 명시한 반영 범위에서 실행한다.

## 검색

- page id 또는 page id가 포함된 URL은 해당 페이지를 직접 조회한다.
- 제목은 `smart-search`로 검색한다.
- 사용자가 Space를 지정한 경우 해당 범위를 적용한다.
- 여러 결과가 있으면 제목, Space, page id를 제시해 대상을 구분한다.

## 출력

- 실행한 도구 작업
- 조회·검색 또는 저장 결과
- 생성된 원문 파일
- 변경 dry-run 또는 반영 결과
- 누락된 환경변수 이름과 확인 필요 항목

## 완료 조건

- 요청 대상과 실행한 API 작업이 일치한다.
- 인증값이 출력이나 생성 파일에 노출되지 않는다.
- 변경 작업은 대상과 반영 결과가 확인된다.
