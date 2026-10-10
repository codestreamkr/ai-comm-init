---
name: ct-wiki-api
description: 사용자가 `$ct-wiki-api`를 명시적으로 호출하면 사용한다. 포함된 PowerShell 도구와 환경변수로 Confluence REST API 호환 위키를 검색, 조회, 저장한다. 사용자가 명시한 변경도 실행한다.
argument-hint: "<요청>"
disable-model-invocation: true
---

# CT Wiki API

실행 계약은 `scripts/wiki-api.ps1`이다. 로컬 Markdown 위키는 `ct-wiki-ops`가 담당한다.

## 호출

- `$ct-wiki-api`: 역할, 필요한 환경과 대표 예제를 안내한다. 실행하지 않는다.
- `$ct-wiki-api <요청>`: 요청 의도를 판단한다. 그다음 아래 스크립트 명령으로 실행한다.
- Claude Code는 `/ct-wiki-api <요청>`로 호출한다. 요청이 비어 있으면 안내만 한다. 실행하지 않는다.

예: `$ct-wiki-api 333 페이지와 댓글을 조회해줘`

## 명령 선택

실행 형식: `pwsh -NoProfile -File <스킬 디렉터리>/scripts/wiki-api.ps1 <명령> [옵션]`

- Windows PowerShell에서는 `pwsh` 대신 `powershell`을 쓸 수 있다.
- 둘 다 없으면 PowerShell 설치가 필요하다고 보고한다. 다른 방법으로 우회하지 않는다.

- 환경 확인: `check-env`
- 제목·자연어·page id·URL 검색: `smart-search -Query`
- CQL 검색: `search -Cql`. 입력 자체가 CQL일 때만 사용한다.
- 페이지 조회: `get-page -PageId`
- 댓글, 첨부, 하위 페이지 조회: 해당 `get-*` 명령
- 원문 저장: `save-page -PageId`
- 댓글 저장: `save-comments`
- 페이지 생성·수정: `create-page`, `update-page`

page id나 URL의 단순 조회에는 검색을 쓰지 않는다. `get-page`를 사용한다. 검색 결과가 여러 개이면 제목, Space, page id로 구분한다.

## 변경 안전

- 생성과 수정의 첫 실행은 dry-run이다. `-Write`를 붙이지 않는다.
- `-Write`는 사용자가 dry-run 결과를 보고 실제 반영 범위를 명시한 뒤에만 붙인다.
- 생성 전에 같은 Space, 부모, 제목의 기존 페이지를 확인한다. 중복 가능성을 보고한다.
- 실제 반영 후 반환값이나 재조회로 다음 항목을 확인한다: page id, 부모, Space, version
- 실패한 변경을 자동 재시도하지 않는다.

## 완료조건

- 자료를 수집한 뒤 이번 요청의 완료조건을 만든다.
- 결과를 개선하고 완료조건으로 검증한다.
- 고칠 수 있는 미달 항목이 있으면 한 번 더 개선하고 다시 검증한다.
- 다음 중 하나에 해당하면 끝낸다.
  - 완료조건을 모두 충족했다.
  - 남은 미달 항목이 보존 대상이거나 고칠 수 없다.
  - 개선을 2회 했다.

## 완료 기준

- 실행 전에 `check-env`로 필요한 환경변수의 설정 여부만 확인한다.
- 인증값은 출력하지 않는다. 파일에도 쓰지 않는다.
- 스킬 디렉터리의 `scripts/wiki-api.ps1`만 사용한다. 다른 클라이언트로 우회하지 않는다.
- 사용한 내부 명령, 대상, 결과, 저장 경로를 보고한다.
- 누락된 환경변수와 실행 실패는 이름과 원인만 보고한다. 비밀값은 포함하지 않는다.

## 결과

완료 후 아래 항목만 짧게 보고한다.

- 명령
- 대상
- dry-run·반영 결과
