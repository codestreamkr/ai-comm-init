# $wiki-ops init

`$wiki-ops init`은 현재 프로젝트에 위키 기본 구조를 만든다.

## 대상

아래 조건 중 하나에 해당하면 실행한다.

- 사용자가 `$wiki-ops init`을 호출했다.
- 현재 프로젝트에 `raw/` 또는 `wiki/` 구조가 없다.

## 생성 구조

아래 디렉터리와 파일만 만든다.

- `raw/`
- `raw/assets/`
- `wiki/index.md`
- `wiki/log.md`
- `wiki/sources/`
- `wiki/concepts/`
- `wiki/entities/`
- `wiki/questions/`
- `wiki/synthesis/`
- `wiki/templates/`

## 선택 생성

프로젝트 문서가 없을 때만 만든다.

- `AGENTS.md`: LLM 작업 규칙
- `README.md`: 사람용 저장소 안내

## 기준

기존 문서는 덮어쓰지 않는다.

- 이미 있는 파일은 유지한다.
- 누락된 항목만 추가한다.
- 생성한 문서에는 `## 이력관리`를 둔다.
- `wiki/index.md`에는 비어 있는 섹션을 만든다.
- `wiki/log.md`에는 초기화 이력을 남긴다.

## 출력

초기화 결과를 요약한다.

- 생성한 항목
- 이미 존재한 항목
- 다음 권장 명령
