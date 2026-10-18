# 0008. 프로세스 맵을 ct-journal에서 분리해 ct-progress로 둠

- 날짜: 2026-10-18
- 상태: 채택
- 도메인: map
- 관련 실행: apply-9
- 영향 문서: skills/ct-progress/SKILL.md, skills/ct-journal/SKILL.md

## 맥락

- `ct-journal`은 `.debrief/` 영구 기록과 프로세스 맵을 함께 맡고 있었다.
- 맵 열기 지시가 모호해서 Claude 데스크톱에서는 프로젝트마다 `.claude/launch.json`이 생길 수 있었다.

## 결정

- 프로세스 맵(서버, 화면, 이벤트, 브라우저 열기)은 `ct-progress`가 맡는다. `ct-journal`은 `.debrief/` 기록만 맡는다.
- 맵 갱신은 사용자 요청 없이 항상 하는 기본 동작이다.
- 맵 서버는 셸에서 띄우고 브라우저는 주소로 연다. 프로젝트에 런타임 전용 설정 파일을 만들지 않는다.

## 이유

> 다른 ai 도 적용할 수 있는 범용적인 스킬이어야해. 근데 맵열기가 저널에 있어?

## 버린 대안

- 맵을 `ct-journal`에 두고 절 이름만 정리: 기록과 실시간 표시의 성격이 달라 역할이 섞인 채로 남는다.
