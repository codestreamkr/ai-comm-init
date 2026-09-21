---
name: ct-docs-md-format
description: >-
  Format Markdown documentation through concise wording, list, table, and code
  block formatting, and line wrapping while preserving its content and meaning.
  Use when a user asks to clean up, reformat, standardize, or improve the
  readability of `.md` documentation without substantive changes. Do not use
  for content review, fact correction, or adding new documentation requirements.
---

# Markdown 문서 포맷 정리

명시적으로 허용한 형식과 문체만 변경하고 나머지는 모두 보존한다.
대상 Markdown 파일만 읽으며 프로젝트 설정, 인접 문서와 다른 참고 파일은 확인하지 않는다.

## 허용하는 변경

- 의미가 달라지지 않는 범위에서 미사여구와 완곡한 표현을 줄이고 문장을 간결하게 쓴다.
- 고유한 조건·근거·강조가 없는 완전한 중복만 통합한다. 판단하기 어려우면 유지한다.
- 단순 나열은 목록으로 정리하고 목록 항목마다 하나의 핵심 내용을 둔다.
- 비교·매핑처럼 열 관계가 중요한 정보만 표로 정리한다.
- 코드, 로그, 명령어와 설정 예시는 fenced code block으로 정리한다.
- 문서에 이미 사용 중인 목록 기호, 제목 스타일과 용어 표기를 우선한다.
- 약 100자를 기준으로 문장 경계나 의미 단위에서 줄을 나누고, 같은 문단은 soft break를 사용한다.
- inline code, Markdown 링크, URL, 파일 경로, 명령어와 코드 토큰 중간은 나누지 않는다.

## 보존하는 내용

- 사실, 결정, 요구사항, 상태, 우선순위, 정보 순서와 의존 관계를 바꾸지 않는다.
- 수치, 날짜, 경로, URL, 명령어, 코드, 식별자와 고유 명칭을 그대로 유지한다.
- 새로운 판단·근거·예시·예외를 추가하거나 의미 있는 내용을 요약·생략하지 않는다.
- 제목 텍스트와 계층, 목록 순서와 들여쓰기 관계를 유지한다.
- YAML frontmatter, HTML·MDX·템플릿 지시문, 주석, 링크 참조, 각주 식별자,
  작업 목록 상태, 명시적 제목 ID와 의도적인 hard break를 유지한다.
- 명백한 오류도 고치지 않고 결과 보고에서 별도로 알린다.
- 위 허용 목록에 없는 변경은 하지 않는다.

## 작업 절차

1. 대상 문서 전체에서 보존할 내용과 Markdown 요소를 식별한다.
2. 허용 목록에 해당하는 부분만 최소 범위로 수정한다.
3. 수정 전후의 대상 문서만 비교해 내용 누락, 의미·순서·식별자 변경과 링크 손상을 확인한다.

## 결과 보고

- 수정한 문서와 적용한 허용 항목을 간단히 보고한다.
- 내용상 문제를 발견했지만 유지한 경우 별도 항목으로 알린다.
- 대상 문서의 비교 결과와 실행하지 않은 검증을 명시한다.
