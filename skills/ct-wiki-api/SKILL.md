---
name: ct-wiki-api
description: "환경변수 기반 Wiki API로 Confluence REST API 호환 위키를 검색, 조회, 원문 저장, 제한적으로 수정한다. 사용자가 `$ct-wiki-api`를 명시적으로 호출한 경우에만 사용한다."
---

# ct-wiki-api

이 스킬은 환경변수 값에 따라 대상 Wiki API를 호출한다.

## 기본 원칙

인증값은 이미 세팅된 환경변수에서만 읽는다.

- env 파일은 읽지 않는다.
- env 파일은 dot-source로 실행하지 않는다.
- env 파일 내용 확인을 요청받아도 토큰 노출 위험을 알리고 중단한다.
- 스킬의 `scripts/wiki-api-env.ps1`은 사용자가 직접 복사하거나 수정할 때 참고하는 샘플이다.
- 실제 값이 들어간 env 스크립트는 사용자가 별도 보관하고 직접 실행한다.
- 토큰, 비밀번호, 인증 헤더는 출력하지 않는다.
- 조회 결과 원문은 `WIKI_API_RAW_DIR`에 저장한다.
- 실제 페이지 수정은 사용자가 명시적으로 요청한 경우에만 수행한다.
- Confluence REST API 호환 엔드포인트를 기준으로 실행한다.

## 환경변수

아래 값으로 동작 대상을 결정한다.

- `WIKI_API_BASE_URL`: Wiki 기본 URL
- `WIKI_API_AUTH_TYPE`: `basic`
- `WIKI_API_TOKEN`: `id,password` 형식의 basic 인증값
- `WIKI_API_USER`: basic auth 사용자
- `WIKI_API_PASSWORD`: basic auth 비밀번호 또는 API token
- `WIKI_API_DEFAULT_SPACE`: 기본 Space key
- `WIKI_API_RAW_DIR`: 원문 저장 경로
- `WIKI_API_ROOT`: API root 직접 지정 값

## 실행 준비

스킬 폴더의 스크립트를 직접 사용한다.

- API 스크립트: `C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1`
- env 샘플: `C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api-env.ps1`
- 현재 프로젝트의 `scripts/wiki-api.ps1` 존재 여부는 실행 기준으로 삼지 않는다.
- env 샘플 파일은 자동으로 읽지 않는다.
- 환경변수 확인은 `check-env` 명령으로 수행하고, 값 출력 없이 설정 여부만 확인한다.
- 환경변수 확인을 위해 임의 PowerShell 파이프라인이나 일회성 스크립트를 작성하지 않는다.
- Wiki API 호출은 새 세션에서도 처음부터 `sandbox_permissions=require_escalated`로 실행한다.
- SSL, TLS, 프록시 오류를 먼저 재현하지 않는다.
- `wiki-api.ps1`은 프록시 환경변수를 호출 프로세스에서만 제거한다.
- 직접 `Invoke-RestMethod` 일회성 코드를 작성하지 않는다.

## 사용 가능 명령

명령은 `wiki-api.ps1`의 `Command` 값으로 실행한다.

- `help`: 사용 가능 명령과 예시를 조회한다.
- `check-env`: 환경변수 설정 여부를 확인한다.
- `search`: CQL을 직접 실행한다.
- `smart-search`: page id, URL, 제목, 본문 순서로 검색한다.
- `get-page`: 페이지 본문, 버전, Space를 조회한다.
- `get-comments`: 페이지 코멘트를 조회한다.
- `get-attachments`: 페이지 첨부파일을 조회한다.
- `get-child-pages`: 직접 하위 페이지를 조회한다.
- `get-descendant-pages`: CQL `ancestor` 조건으로 전체 하위 페이지를 조회한다.
- `get-labels`: 페이지 라벨을 조회한다.
- `get-history`: 페이지 히스토리를 조회한다.
- `get-restrictions`: 페이지 제한 정보를 조회한다.
- `get-page-bundle`: 페이지와 관련 정보를 묶어 조회한다.
- `save-page`: 페이지 원문 JSON을 저장한다.
- `save-comments`: 페이지 코멘트 JSON을 저장한다.
- `create-page`: 페이지 생성을 dry-run 또는 실제 반영으로 실행한다.
- `update-page`: 페이지 수정을 dry-run 또는 실제 반영으로 실행한다.

조회 범위는 공통 옵션으로 조절한다.

- `-Start`: 목록 조회 시작 위치
- `-Limit`: 목록 조회 건수
- `-Expand`: Confluence `expand` 값 직접 지정
- `-OutDir`: 저장 위치 직접 지정

## 인증 기준

인증은 basic token 방식을 기준으로 처리한다.

- `WIKI_API_AUTH_TYPE=basic`을 사용한다.
- `WIKI_API_TOKEN`은 `id,password` 형식을 사용한다.
- `WIKI_API_USER`, `WIKI_API_PASSWORD`가 있으면 우선 사용한다.
- `WIKI_API_USER`, `WIKI_API_PASSWORD`가 없으면 `WIKI_API_TOKEN`을 쉼표 기준으로 나눠 사용한다.
- `WIKI_API_AUTH_TYPE=bearer`와 `id,password` 형식 토큰을 함께 사용하지 않는다.
- 토큰, 비밀번호, 인증 헤더는 출력하지 않는다.

## 환경변수 누락 처리

필수 환경변수가 없으면 API 호출을 실행하지 않는다.

- 필수값: `WIKI_API_BASE_URL`, `WIKI_API_AUTH_TYPE`
- `WIKI_API_AUTH_TYPE=basic`: `WIKI_API_TOKEN`
- 선택값: `WIKI_API_DEFAULT_SPACE`, `WIKI_API_RAW_DIR`, `WIKI_API_ROOT`
- 누락 시 안내:
  - 어떤 값이 누락됐는지 값 이름만 알린다.
  - 토큰, 비밀번호, 인증 헤더 값은 출력하지 않는다.
  - 사용자가 별도 보관한 env 스크립트를 직접 실행한 뒤 다시 요청해야 한다고 안내한다.
  - `WIKI_API_DEFAULT_SPACE`가 없으면 사용자가 지정한 Space key를 우선 사용한다.

## 환경변수 확인 절차

환경변수 확인은 전용 명령으로만 수행한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' check-env
```

- 출력은 환경변수명과 설정 여부만 포함한다.
- 토큰, 비밀번호, 인증 헤더 값은 출력하지 않는다.
- 확인 명령을 새로 조립하지 않는다.

## 요청 해석

입력값을 먼저 판별한 뒤 가장 직접적인 방식으로 처리한다.

- `$ct-wiki-api 333 검색해줘.`: page id `333` 조회
- `$ct-wiki-api https://...pageId=333 검색해줘.`: URL에서 page id `333` 추출 후 조회
- `$ct-wiki-api https://.../display/MSN/정산 검색해줘.`: Space와 제목을 추출해 검색
- `$ct-wiki-api [커머스] 직영몰 PG 고도화 검색해줘.`: 특수문자 제거 후 제목 검색
- `$ct-wiki-api 정산 검색해줘.`: 제목 검색 후 본문 검색
- `$ct-wiki-api page 123456 조회해줘.`: page id `123456` 조회
- `$ct-wiki-api page 123456 저장해줘.`: page id `123456` 원문 저장
- `$ct-wiki-api page 123456 수정해줘.`: 수정 의도를 확인하고 dry-run부터 실행

## 검색 절차

검색은 입력값 판별 후 점진적으로 완화한다.

- 숫자만 있으면 page id로 보고 `get-page`를 실행한다.
- URL에 `pageId`가 있으면 page id를 추출해 `get-page`를 실행한다.
- URL이 `/display/{SPACE}/{TITLE}` 형태이면 Space와 제목을 추출한다.
- 사용자가 Space key를 명시한 경우에만 `space = "{SPACE}"` 조건을 붙인다.
- Space를 명시하지 않은 검색에는 기본 Space를 자동으로 붙이지 않는다.
- 제목처럼 보이는 입력은 `title ~` 검색을 먼저 수행한다.
- 제목 검색 실패 시 본문 `text ~` 검색으로 완화한다.
- `0건` 또는 서버 오류가 나면 다음 검색 단계로 넘어간다.

## 제목 검색 절차

제목은 특수문자를 제거한 전체 텍스트로 먼저 검색한다.

- `[]`, `()`, `{}`, `:`, `/`, `-`, `_` 등 특수문자는 공백으로 치환한다.
- 여러 공백은 하나로 줄인다.
- 정리된 전체 문장을 `title ~` 조건에 넣는다.
- 1차 검색이 실패하면 토큰별 `AND` 검색으로 전환한다.
- 토큰은 공백 기준으로 나눈다.
- 한글 2글자 이상 토큰을 사용한다.
- 영문/숫자 토큰은 기본적으로 3글자 이상만 사용한다.
- 짧은 약어가 핵심이면 포함할 수 있다.

1차 제목 검색:

```text
type = page and title ~ "커머스 직영몰 PG 고도화"
```

2차 제목 검색:

```text
type = page and title ~ "커머스" and title ~ "직영몰" and title ~ "고도화"
```

## 본문 검색 절차

제목 검색으로 찾지 못하면 본문 검색으로 완화한다.

- 특수문자 제거 후 전체 텍스트로 먼저 검색한다.
- 실패하면 토큰별 `AND` 검색으로 전환한다.

1차 본문 검색:

```text
text ~ "커머스 직영몰 PG 고도화"
```

2차 본문 검색:

```text
text ~ "커머스" and text ~ "직영몰" and text ~ "고도화"
```

## 스마트 검색 실행

입력값 판별과 단계별 검색은 `smart-search`로 수행한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' smart-search -Query '[커머스] 직영몰 PG 고도화'
```

Space를 사용자가 명시한 경우에만 `-Space`를 붙인다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' smart-search -Query '정산' -Space 'MSN'
```

## 조회 절차

페이지 조회는 page id를 기준으로 수행한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-page -PageId 123456
```

페이지 관련 정보도 page id를 기준으로 조회한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-comments -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-attachments -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-child-pages -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-descendant-pages -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-labels -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-history -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-restrictions -PageId 123456
```

페이지와 관련 정보를 한 번에 확인할 때는 묶음 조회를 사용한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' get-page-bundle -PageId 123456
```

## 저장 절차

원문 저장은 `WIKI_API_RAW_DIR`에 JSON으로 저장한다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' save-page -PageId 123456
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' save-comments -PageId 123456
```

## 생성 절차

페이지 생성은 dry-run을 먼저 실행한다.

- `-ParentId`가 있으면 부모 페이지의 Space를 자동으로 사용한다.
- `-ParentId` 없이 생성할 때는 `-Space`를 지정한다.
- 새 본문 파일을 기준으로 payload를 만든다.
- `-Write`가 없으면 실제 생성하지 않는다.
- 사용자가 실제 생성을 명시하면 `-Write`를 붙인다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' create-page -ParentId 123456 -Title '새 페이지 제목' -BodyFile .\work\page-body.html
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' create-page -ParentId 123456 -Title '새 페이지 제목' -BodyFile .\work\page-body.html -Write
```

## 수정 절차

수정은 dry-run을 먼저 실행한다.

- 현재 페이지와 version을 조회한다.
- 새 본문 파일을 기준으로 payload를 만든다.
- `-Write`가 없으면 실제 수정하지 않는다.
- 사용자가 실제 반영을 명시하면 `-Write`를 붙인다.

```powershell
& 'C:\Users\P268083\.codex\skills\ct-wiki-api\scripts\wiki-api.ps1' update-page -PageId 123456 -BodyFile .\work\page-body.html
```

## 출력

결과는 짧게 정리한다.

- 실행한 작업
- 사용한 CQL 또는 page id
- 저장한 파일
- 실패 원인
- 추가로 필요한 값

## 이력관리

- 2026-06-09: 스킬 폴더의 `wiki-api.ps1`을 직접 실행하고, env 누락 시 설정 안내로 전환하도록 실행 기준 정리. 새 세션에서도 첫 호출에 성공하도록 basic token 인증 기준과 승인 네트워크 실행 기준 추가. 환경변수 확인을 `check-env` 전용 명령으로 고정. 입력값을 page id, URL, 제목, 키워드로 판별하고 특수문자 제거 제목 검색, 토큰 AND 검색, 본문 완화 검색 순서로 처리하는 스마트 검색 기준 추가. `help`, 코멘트, 첨부, 하위 페이지, descendant 페이지, 라벨, 히스토리, 제한 정보, 페이지 묶음 조회, 코멘트 저장 명령 추가. `create-page` 명령과 페이지 생성 절차 추가
