---
name: ct-wiki-api
description: 사용자가 `$ct-wiki-api`를 명시적으로 호출하면 포함된 PowerShell 도구와 환경변수로 Confluence REST API 호환 위키를 검색·조회·저장하거나 명시된 변경을 수행한다.
---

# CT Wiki API

실행 계약은 `scripts/wiki-api.ps1`이다. 로컬 Markdown 위키는 `ct-wiki-ops`의 범위다.

## 호출

- `$ct-wiki-api`: 역할, 필요한 환경과 대표 예제를 안내한다. 실행하지 않는다.
- `$ct-wiki-api <요청>`: 요청 의도를 판단해 아래 스크립트 명령으로 실행한다.

예: `$ct-wiki-api 333 페이지와 댓글을 조회해줘`

## 명령 선택

- 환경 확인: `check-env`
- 제목·자연어·page id·URL 검색: `smart-search -Query`. 입력 자체가 CQL일 때만 `search -Cql`
- 페이지 조회: `get-page -PageId`; 댓글·첨부·하위 페이지 등은 해당 `get-*`
- 원문 저장: `save-page -PageId`; 댓글 저장은 `save-comments`
- 페이지 생성·수정: `create-page`, `update-page`

page id나 URL의 단순 조회는 검색하지 않고 `get-page`를 사용한다. 여러 검색 결과는 제목, Space와 page id로 구분한다.

## 변경 안전

- 생성·수정의 첫 실행은 `-Write` 없는 dry-run이다.
- dry-run 결과와 실제 반영 범위를 사용자가 명시한 뒤에만 `-Write`를 붙인다.
- 생성 전 같은 Space·부모·제목의 기존 페이지를 확인해 중복 가능성을 보고한다.
- 실제 반영 후 반환값이나 재조회로 page id, 부모, Space와 version을 확인한다.
- 실패한 변경을 자동 재시도하지 않는다.

## 완료 기준

- 실행 전에 `check-env`로 필요한 환경변수의 설정 여부만 확인한다. 인증값은 출력하거나 파일에 쓰지 않는다.
- 스킬 디렉터리의 `scripts/wiki-api.ps1`만 사용하고 다른 클라이언트로 우회하지 않는다.
- 사용한 내부 명령, 대상, 결과와 저장 경로를 보고한다.
- 누락된 환경변수와 실행 실패는 비밀값 없이 이름과 원인만 보고한다.
