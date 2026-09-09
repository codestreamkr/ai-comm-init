---
name: ct-code-spring
description: 사용자가 `$ct-code-spring`를 명시적으로 호출하면 현재 프로젝트의 Spring 버전과 코드 관례에 맞춰 구현·검토하거나 공통 컴포넌트를 적용한다. 지원 작업은 `impl`, `review`, `component`다.
---

# CT Code Spring

정본은 이 프로젝트의 Spring 버전, 설정, 같은 역할의 기존 코드다. 일반 Spring 관례보다 프로젝트 패턴을 앞세운다.

## 호출

- `$ct-code-spring` 또는 `$ct-code-spring ?`: 안내. 실행하지 않는다.
- `$ct-code-spring <작업> ?`: 해당 작업 안내.
- `$ct-code-spring <작업> <요청>`: 실행.

첫 토큰이 `impl`, `review`, `component`가 아니면 안내만 한다. `--`로 시작하면 지원하지 않는 옵션이다. 작업만 있고 요청이 없으면 실행하지 않는다.

## 작업

- `impl`: Spring 코드와 설정을 프로젝트 방식에 맞춰 바꾼다. 구현 계획만 쓰면 `ct-plan-work impl`이다.
  - 예: `$ct-code-spring impl 주문 취소 트랜잭션`
- `review`: 버전·관례 적합성을 검토한다. 코드를 수정하지 않는다.
  - 예: `$ct-code-spring review Security 설정`
- `component`: 공통 컴포넌트를 기존 적용 방식에 맞춰 넣는다. 기능 본문 구현은 `impl`이다.
  - 예: `$ct-code-spring component API 예외 응답`

## 역할 규칙

- 이 프로젝트에 없는 버전 API를 쓰지 않는다. 버전을 코드와 lock으로 확인한다.
- 프로젝트 근거만으로 API를 확정하지 못할 때만 해당 버전의 공식 문서를 본다.
- 관련 설정, 호출부, 테스트를 함께 확인한다. 검증을 건너뛰면 이유를 보고한다.
