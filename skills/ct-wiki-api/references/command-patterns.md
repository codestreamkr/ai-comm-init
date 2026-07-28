# ct-wiki-api 명령 패턴

이 문서는 `$ct-wiki-api` 요청을 Wiki API 명령으로 바꾸는 기준이다.

## 검색

검색어만 있으면 기본 Space에서 본문 검색을 수행한다.

- 입력: `$ct-wiki-api 333 검색해줘.`
- 검색어: `333`
- CQL: `space = "<WIKI_API_DEFAULT_SPACE>" and text ~ "333"`

## 조회

`page`와 숫자가 함께 있으면 page id 조회로 본다.

- 입력: `$ct-wiki-api page 123456 조회해줘.`
- page id: `123456`

## 저장

`저장`이 있으면 조회 결과를 원문 파일로 저장한다.

- 입력: `$ct-wiki-api page 123456 저장해줘.`
- 저장 위치: `WIKI_API_RAW_DIR`

## 수정

`수정`이 있으면 dry-run을 먼저 수행한다.

- 입력: `$ct-wiki-api page 123456 수정해줘.`
- 기본 실행: `update-page`
- 실제 반영: 사용자가 명시한 경우에만 `-Write`
