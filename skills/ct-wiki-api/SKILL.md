---
name: ct-wiki-api
description: 사용자가 `$ct-wiki-api`를 명시적으로 호출하면 포함된 PowerShell 도구와 환경변수로 Confluence REST API 호환 위키를 검색, 조회, 저장하거나 명시된 변경을 수행한다. 지원 작업은 `env`, `search`, `get`, `save`, `write`다.
---

# CT Wiki API

실행 계약은 `scripts/wiki-api.ps1`이다. 로컬 위키 규칙은 `ct-wiki-ops`다.

## 호출

- `$ct-wiki-api` 또는 `$ct-wiki-api ?`: 안내. 실행하지 않는다.
- `$ct-wiki-api <작업> ?`: 해당 작업 안내.
- `$ct-wiki-api <작업> <대상>`: 실행.

첫 토큰이 `env`, `search`, `get`, `save`, `write`가 아니면 안내만 한다. `--`로 시작하면 지원하지 않는 옵션이다. `env`를 제외하면 대상 없이 실행하지 않는다. 스킬 토큰을 스크립트 `$Command`로 넘기지 않는다.

## 작업

요청은 아래 작업으로만 받고, 표의 스크립트 명령으로 내린다.

| 작업 | 하는 일 | 스크립트 명령 |
|---|---|---|
| `env` | 환경변수 설정 여부만 확인 | 항상 `check-env` |
| `search` | 제목·자연어·page id·URL 검색. CQL은 입력이 CQL일 때만 | 기본 `smart-search -Query`. CQL만 `search -Cql` |
| `get` | 페이지와 부가 정보 조회 | 기본 `get-page -PageId`. 부가 요청은 아래 `get-*` |
| `save` | 로컬 원문 저장 | 기본 `save-page -PageId`. 댓글은 `save-comments` |
| `write` | 페이지 생성·수정 | 생성 `create-page`, 수정 `update-page` |

`get-*`: `get-comments`, `get-attachments`, `get-child-pages`, `get-descendant-pages`, `get-labels`, `get-history`, `get-restrictions`, `get-page-bundle`.

- `search`: 제목, 자연어, page id, URL은 `smart-search -Query`다. 입력이 CQL일 때만 `search -Cql`이다. page id·URL을 CQL `search`로 보내지 않는다. 조회만이면 `get`을 안내해도 된다. Space가 있으면 `-Space`. 여러 결과면 제목·Space·page id로 구분한다.
- `get`: page id 또는 그것이 든 URL은 `get-page`다.
- `write`: 첫 호출은 `-Write` 없이 dry-run이다. 사용자가 반영 범위를 명시한 뒤에만 `-Write`를 붙인다. 스킬 토큰 `write`를 명령이나 `-Write`와 같은 말로 쓰지 않는다.

예: `$ct-wiki-api get 333`

## 역할 규칙

- 스킬 디렉터리의 `scripts/wiki-api.ps1`만 실행한다. 다른 클라이언트로 우회하지 않는다.
- 작업 전에 `check-env`로 환경변수 이름 존재만 확인한다. 인증값은 출력하거나 파일에 쓰지 않는다.
- 누락된 환경변수는 이름만 보고한다.
