# 0005. 수정·재검증 루프는 ct-apply가 관리하고 ct-verify는 판정만 반환

- 날짜: 2026-10-18
- 상태: 채택
- 도메인: workflow
- 관련 실행: apply-4, debrief-1
- 영향 문서: skills/ct-apply/SKILL.md, skills/ct-verify/SKILL.md

## 맥락

- 스킬은 각각 실행할 수 있어야 하고, 하나의 요청에서는 연쇄로 이어져야 한다.
- 기존에는 `ct-verify`가 수정 루프를 관리했다.

## 결정

- `ct-plan` → 승인 → `ct-apply` 순으로 이어진다.
- `ct-apply`가 `ct-verify` 검증과 수정 반복을 관리하고, 통과하면 `ct-debrief`로 이어진다.
- `ct-verify`는 연쇄 중에는 판정만 반환한다. 단독 실행에서는 수정을 `ct-apply`에 넘긴다.
- 스킬 연결은 상대 링크로 SKILL.md를 읽는 방식으로 한다.

## 이유

> 각각의 기능을 하지만 연쇄적으로 호출이 되는게 좋겠어. plan(+analyze) > 사용자 승인요청 > apply(+verify, debrief)

## 버린 대안

- `ct-verify`가 루프 관리(기존 방식): 연쇄의 끝에서 `ct-debrief`로 넘기는 주체가 불분명해진다.
