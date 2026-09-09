---
name: ct-plan-work
description: 사용자가 `$ct-plan-work`를 명시적으로 호출하면 프로젝트와 요청 자료를 근거로 제품 기획, 설계 검토, 구현 계획 또는 개선 계획을 작성한다. 지원 작업은 `pd`, `review`, `impl`, `improve`다. 운영 코드는 수정하지 않는다.
---

# CT Plan Work

정본은 프로젝트와 사용자가 준 자료다. 산출은 계획이며 코드를 바꾸지 않는다.

## 호출

- `$ct-plan-work` 또는 `$ct-plan-work ?`: 안내. 실행하지 않는다.
- `$ct-plan-work <작업> ?`: 해당 작업 안내.
- `$ct-plan-work <작업> <요청>`: 실행.

첫 토큰이 `pd`, `review`, `impl`, `improve`가 아니면 안내만 한다. `--`로 시작하면 지원하지 않는 옵션이다. 작업만 있고 요청이 없으면 실행하지 않는다.

## 작업

- `pd`: 목표, 사용자 흐름, 요구사항. 설계 검토나 구현 계획이 아니다.
  - 예: `$ct-plan-work pd 주문 취소`
- `review`: 기존 설계의 근거·영향·위험·결정. 새 기획이나 코드 변경이 아니다.
  - 예: `$ct-plan-work review .docs/payment-design.md`
- `impl`: 변경 범위, 구현 순서, 검증 기준 계획. 운영 코드는 수정하지 않는다. Spring 구현은 `ct-code-spring impl`이다.
  - 예: `$ct-plan-work impl 쿠폰 중복 적용 방지`
- `improve`: 현황 근거와 개선 과제·우선순위. 호출 흐름 전환 계획은 `ct-code-tree transition`이다.
  - 예: `$ct-plan-work improve 회원 모듈`

## 역할 규칙

- 옵션은 호출에 적힌 것만 수행한다. 요청 문장으로 다른 옵션을 고르지 않는다.
- 판단은 확인된 근거에 붙인다. 미확인은 확정과 분리한다.
- 공급자 공식 계약이 정본인 연동·이관 설계는 `ct-plan-ext`다.
- 저장 위치와 문서 형식은 사용자 지정 또는 프로젝트 관례를 따른다.
