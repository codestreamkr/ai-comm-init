---
name: ct-docs-md-format
description: >-
  Create a Markdown file from supplied source material or format an existing
  Markdown file through concise wording, lists, tables, and code blocks.
  Use when a user asks to produce, clean up, standardize, or improve
  the readability of `.md` documentation. Always write the result to a `.md`
  file. Preserve existing content and meaning; do not use for fact correction
  or substantive content review.
---

# Markdown 문서 생성 및 포맷 정리

결과를 답변에만 작성하지 않고 반드시 `.md` 파일로 저장한다.

## 요청 범위

- 스킬 실행 요청과 스킬 자체의 수정 요청을 구분한다.
- 사용자가 이 스킬의 수정을 요청한 경우 스킬 파일만 수정한다.
- 스킬 수정 요청에 첨부된 소스나 Markdown 파일은 명시적인 문서 생성·수정 요청이 없으면
  동작 예시로만 취급하며 해당 파일이나 결과 문서를 생성·수정하지 않는다.

## 출력 파일 결정

1. 사용자가 출력 파일을 지정하면 그 파일을 사용한다.
2. 기존 Markdown 파일을 대상으로 요청하면 해당 파일을 같은 위치에서 수정한다.
3. Markdown이 아닌 원본을 대상으로 요청하면 같은 이름의 `.md` 파일을 찾는다. 있으면 그
   파일과 폴더를 유지해 수정한다.
4. 대상 `.md` 파일이 없으면 저장소의 문서 배치 규칙을 따른다. 필요한 폴더가 없으면 만들고,
   원본 파일명을 기준으로 `.md` 파일을 생성한다.
5. 저장소에 문서 배치 규칙이 없으면 저장소 루트의 `docs` 폴더에 생성한다.

연관된 기존 문서가 여러 개이거나 출력 위치 규칙이 충돌하면 임의로 덮어쓰지 않고 사용자에게
확인한다.

## 내용 작성 범위

- 기존 Markdown 파일은 해당 파일만 읽고 형식과 문체만 정리한다.
- 비 Markdown 원본에서 문서를 생성할 때는 원본에서 관찰되는 사실만 사용한다.
- 원본에서 확인할 수 없는 의도, 동작과 요구사항을 추정해 추가하지 않는다.
- 형식과 문체는 대상 문서와 요청에서 정하고, 그 밖은 보존한다.

## 완료조건

- 자료를 수집한 뒤 이번 요청의 완료조건을 만든다.
- 개선하고 그 조건으로 검증한다. 고칠 수 있는 미달만 한 번 더 개선한 뒤 다시 검증한다.
- 충족했거나, 남은 미달이 보존·불가이거나, 개선이 2회면 끝낸다.

## 작업 절차

1. 요청이 스킬 수정인지 실제 문서 작업인지 구분한다.
2. 실제 문서 작업이면 출력 파일과 폴더를 결정한다.
3. 대상 문서 또는 원본을 읽어 자료를 수집한다.
4. 기존 문서는 형식과 문체만 정리한다. 새 문서는 원본에서 확인한 내용만 구조화한다.
5. 결과를 결정한 `.md` 파일에 저장한 뒤 완료조건을 따른다.

## 결과

완료 후 아래만 짧게 보고한다.

- 파일 경로
- 유지한 내용 오류
