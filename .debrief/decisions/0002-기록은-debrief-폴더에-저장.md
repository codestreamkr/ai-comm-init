# 0002. ct-wiki-ops를 삭제하고 기록은 .debrief/에 저장

- 날짜: 2026-10-18
- 상태: 채택
- 도메인: record
- 관련 실행: apply-5, debrief-1
- 영향 문서: skills/ct-journal/SKILL.md, skills/ct-wiki-api/SKILL.md

## 맥락

- 최종 문서는 `.docs/`에서 따로 관리한다.
- 로컬 위키(`ct-wiki-ops`)는 자료 저장과 검색 용도였다.

## 결정

- `ct-wiki-ops`를 삭제한다. 조회, 기간 요약, 점검 기능은 `ct-journal`로 옮긴다.
- 실행 기록, ADR, 이해 부채는 저장소 루트의 `.debrief/`에 둔다.

## 이유

> 원래 위키는 자료를 저장하고 쉽게 찾아보려고 한건데 .docs 에서 최종문서를 따로 관리하니까 브리프 용으로만 쓰는게 좋겠어.

## 버린 대안

- 위키를 유지하고 이름만 변경(`ct-wiki-curate`): `.docs/`와 역할이 겹친다.
- `.docs/debrief/`에 저장: 최종 문서와 이력이 같은 폴더에 섞인다.
