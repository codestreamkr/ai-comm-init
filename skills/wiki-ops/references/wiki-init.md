# $wiki-ops init

`$wiki-ops init`은 현재 프로젝트에 LLM Wiki 기본 구조를 만든다.

## 대상

사용자가 명시적으로 호출했을 때 실행한다.

- 사용자가 `$wiki-ops init`을 호출했다.

## 선행 조건

프로젝트 공통 규칙 진입점은 `/init`이 만든다.

- `AGENTS.md`가 없으면 작업을 중단한다.
- `AGENTS.md`가 없을 때는 파일을 생성하지 않는다.
- 사용자에게 `/init`을 먼저 실행한 뒤 `$wiki-ops init`을 다시 실행하라고 안내한다.
- 전역 설정, 세션 instructions, 상위 디렉터리 `AGENTS.md`를 현재 프로젝트 `AGENTS.md` 대신 복사하지 않는다.

## 생성 구조

아래 디렉터리와 파일만 만든다.

- `.wiki/raw/`
- `.wiki/raw/assets/`
- `LLM-WIKI.md`
- `.wiki/index.md`
- `.wiki/log.md`
- `.wiki/sources/`
- `.wiki/concepts/`
- `.wiki/entities/`
- `.wiki/questions/`
- `.wiki/synthesis/`
- `.wiki/templates/`

## LLM-WIKI.md 생성

위키 운영 규칙은 별도 문서로 둔다.

- `LLM-WIKI.md`가 없으면 `references/wiki-init-template.md`를 기준으로 생성한다.
- 템플릿의 `YYYY-MM-DD`는 시스템 날짜로 바꾼다.
- `LLM-WIKI.md`가 있으면 덮어쓰지 않는다.
- `LLM-WIKI.md`에는 llm-wiki 운영에 필요한 내용만 둔다.
- `README.md`는 생성하거나 수정하지 않는다.

## AGENTS.md 반영

프로젝트 규칙 파일에는 참조만 추가한다.

- `AGENTS.md`에 `LLM-WIKI.md` 참조가 있으면 유지한다.
- 참조가 없으면 아래 섹션만 추가한다.
- `## 이력관리`가 있으면 이 섹션 바로 앞에 추가한다.
- `## 이력관리`가 있으면 오늘 날짜로 참조 추가 이력을 남긴다.

```md
## LLM Wiki 규칙

`.wiki/raw/`와 `.wiki/`를 다룰 때는 `LLM-WIKI.md`를 따른다.
```

## 기준

기존 문서는 덮어쓰지 않는다.

- 이미 있는 파일은 유지한다.
- 누락된 항목만 추가한다.
- 생성한 Markdown 문서에는 `## 이력관리`를 둔다.
- `.wiki/index.md`에는 비어 있는 섹션을 만든다.
- `.wiki/log.md`에는 초기화 이력을 남긴다.
- 프로젝트 공통 규칙을 `LLM-WIKI.md`에 복사하지 않는다.

## 출력

초기화 결과를 요약한다.

- 생성한 항목
- 이미 존재한 항목
- 중단한 경우 `/init` 선행 안내
- 다음 권장 명령
