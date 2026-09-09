---
name: ct-run-script
description: 사용자가 `$ct-run-script`를 명시적으로 호출하면 프로젝트의 실제 빌드·실행 명령으로 대상 OS용 실행 스크립트를 생성하거나 갱신한다. 지원 작업은 `write`다.
---

# CT Run Script

정본은 이 프로젝트가 실제로 쓰는 명령, 포트, 환경변수 이름이다.

## 호출

- `$ct-run-script` 또는 `$ct-run-script ?`: 안내. 실행하지 않는다.
- `$ct-run-script write ?`: `write` 안내.
- `$ct-run-script <요청>` 또는 `$ct-run-script write <요청>`: `write`로 실행.

`--`로 시작하면 지원하지 않는 옵션이다. `write`만 있고 요청이 없으면 실행하지 않고 `write` 안내를 한다.

## 작업

- `write`: 대상 OS용 실행 스크립트를 만들거나 고친다. 기능 구현이 아니다.
  - 예: `$ct-run-script macOS에서 API와 프론트를 함께 실행`

## 역할 규칙

- 같은 역할의 기존 스크립트가 있으면 그것을 갱신한다.
- 인증값과 비밀값을 스크립트에 넣지 않는다. 환경변수 이름만 적는다.
- 명령·경로·순서가 현재 프로젝트와 다르면 쓰지 않는다.
- 대상 OS에서 쓸 수 있는 형식으로 구문 검사를 한다.
