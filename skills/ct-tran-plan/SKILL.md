---
name: ct-tran-plan
description: 특정 메서드, Controller API, Service 또는 배치 진입점의 현재 호출 흐름을 분석해 AS-IS/TO-BE CallTree, 구조 판단, 서비스 책임과 메서드 매핑을 담은 전환 계획 문서를 만든다. 사용자가 `$ct-tran-plan`을 명시적으로 호출한 경우에만 사용한다.
---

# CT Transition Plan

현재 코드의 처리 순서와 계약을 근거로 책임 경계를 바꾸는 계획을 작성한다.

## 입력

- 메서드명
- 클래스명과 메서드명
- 파일 경로와 메서드명
- Controller API, Service, 배치, Repository, Listener, Scheduler 또는 그 밖의 컴포넌트 진입점

후보가 여러 개면 소스 경로, 완전한 클래스명과 완전한 메서드 시그니처를 후보별로 제시하고 사용할 대상을 한 번 확인한다.
같은 클래스의 overload도 서로 다른 후보로 취급한다.

## 필수 참조

분석 전에 아래 파일을 처음부터 끝까지 읽는다.

- `references/transition-rules.md`: 분석, 책임 분리, 유지 계약 작성 기준
- `templates/transition-plan.md`: 출력 문서 구조와 섹션 적용 기준

## 프로젝트 기준

프로젝트 기준은 아래 순서로 확인한다.

- `AGENTS.md`
- `.docs/core_project.md`
- `.docs/core_code_style.md`
- `.docs/core_workflow.md`

각 `.docs/core_*.md`가 없으면 같은 이름의 `.0_my/core_*.md`를 읽기 fallback으로 사용한다.

- `.docs` 파일이 있으면 같은 이름의 `.0_my` 파일보다 우선한다.
- fallback은 읽기에만 사용한다.
- 신규 전환 계획은 `.docs/plans/`에 저장한다.

프로젝트 문서가 없어도 소스 코드와 기존 문서 패턴으로 계속 진행한다. 확정할 수 없는 로그, 네이밍, 테스트 실행 기준은 `확인 필요`로 분리한다.

## 분석 절차

1. fully qualified class name, 완전한 메서드 시그니처, 소스 경로, 소스 루트와 base package를 찾는다.
2. 대상 메서드 본문을 읽는다.
3. 직접 호출하는 Service, DAO/Mapper, 외부 연동, private helper를 2depth까지 추적한다.
4. 저장, 상태 변경, 외부 호출, 실패 처리, 후처리 등 의미 있는 호출만 현재 CallTree에 남긴다.
5. 책임 집중, 중복 검증, 저장 책임, 외부 호출, 응답 조립 문제를 코드 근거로 판단한다.
6. 사용자가 변경을 명시하지 않은 처리 순서, 실패 기준과 입출력 계약을 유지하는 목표 CallTree를 작성한다.
7. 목표 서비스 책임과 현재 메서드 매핑을 작성한다.
8. 기존 유지 항목과 신규 제안을 구분한다.
9. 템플릿과 출력 규칙에 따라 문서를 생성하거나 기존 문서를 갱신한다.

## 경로 표기

- base package를 확정하면 package-relative path를 사용한다.
- base package를 확정할 수 없으면 저장소에서 감지한 source root 이후 상대 경로를 사용한다.
- package 접두사는 현재 저장소에서 감지한 값만 사용한다.
- 테스트, 리소스, Mapper XML은 저장소 상대 경로를 사용한다.

## 출력

기본 경로를 기준으로 생성과 갱신을 결정한다.

- 기본 저장 위치: `.docs/plans/`
- 기본 파일명: `{doc_prefix}_tobe_{target_id}_transition_plan.md`
- `doc_prefix`:
  - Controller/API: `api`
  - Service: `service`
  - Batch Job/Step과 배치 실행 Scheduler: `batch`
  - Repository, DAO/Mapper, Listener/Consumer, Handler, 일반 Scheduler와 그 밖의 진입점: `component`
- `target_key`: 저장소 상대 소스 경로, fully qualified class name과 완전한 메서드 시그니처를 `/` 경로 구분자와 UTF-8 기준으로 `{sourcePath}::{fullyQualifiedClassName}::{methodSignature}` 순서로 연결한 문자열
- `target_hash`: `target_key`의 SHA-256 소문자 16진수 값
- `target_hash8`: `target_hash`의 앞 8자리
- `target_id`: simple class name과 method name을 `{className}_{methodName}_{target_hash8}` 순서로 연결한다. 이름 부분의 영문·숫자 이외 문자는 `_`로 바꾸고 연속 `_`는 하나로 합친다.
- 기본 경로가 다른 대상의 문서로 이미 사용 중이면 기존 파일을 보존하고 hash 길이를 12, 16자리 순서로 늘려 비어 있거나 동일 대상인 경로를 사용한다. 16자리 경로도 충돌하면 전체 `target_hash`를 사용하고, 전체 hash 경로도 불일치 문서가 사용 중이면 `_2`, `_3`처럼 가장 작은 미사용 순번을 붙인다.
- legacy 파일명은 `{doc_prefix}_tobe_{methodName}_transition_plan.md`다.
- 후보 문서는 아래 순서로 수집하고 같은 실제 경로는 한 번만 취급한다.
  1. `.docs/plans/`의 기본 파일과 legacy 파일
  2. `.0_my/plans/`의 legacy 파일
  3. 작업 루트의 legacy 파일
  4. 저장소 전체의 `*_tobe_*_transition_plan.md`
- 저장소 전체 탐색은 `.git`, 빌드 산출물과 외부 의존성 디렉터리를 제외한다.
- 수집한 모든 후보는 대상 클래스, 완전한 메서드 시그니처와 소스 경로로 동일 대상, 불일치 대상, 동일성 확인 불가로 분류한다.
- 대상 동일성은 문서의 fully qualified class name, 완전한 메서드 시그니처와 소스 경로를 실제 코드와 대조해 판정한다.
- 동일 대상 문서가 하나면 새 중복 파일을 만들지 않고 해당 문서를 최종본으로 갱신한다. legacy 파일도 이 조건에서만 갱신한다.
- 동일 대상 문서가 없고 불일치 문서만 있으면 불일치 문서를 보존하고 충돌 없는 기본 파일명으로 신규 문서를 생성하며 최종 보고에 충돌 경로를 남긴다.
- 동일 대상 문서가 여러 개이거나 관련 가능성이 있는 문서의 동일성을 확정할 수 없으면 후보 경로와 판정 근거를 제시하고 갱신할 문서를 사용자에게 한 번 확인한다.
- 사용자가 지정한 파일이 없으면 생성하고, 지정 파일이 있으면 같은 대상임을 확인한 뒤 갱신한다. 대상이 다르거나 확정되지 않으면 갱신 전에 확인한다.
- 사용자가 별도 신규본 또는 버전 파일을 명시한 경우에만 지정한 새 파일을 만든다.
- 갱신할 때 이전 본문과 변경 과정은 남기지 않고 `## 이력관리`만 갱신한다.
- 같은 날짜의 이력이 있으면 기존 날짜 항목에 변경 내용을 합친다.

## 완료 조건

- fully qualified class name, 완전한 메서드 시그니처와 소스 경로가 문서에 기록되고 갱신 대상과 일치한다.
- 현재 CallTree와 구조 판단이 실제 코드에 근거한다.
- 목표 CallTree가 변경 요청이 없는 처리 순서와 실패 기준을 보존하고, 명시된 변경 계약은 영향 범위와 확인 필요 항목에 연결한다.
- 목표 CallTree가 필수 섹션으로 남고 중복되는 책임 상세만 서비스 책임 표에 정리됐다.
- 서비스 책임과 현재 메서드 매핑이 서로 맞는다.
- 기존 유지 항목과 신규 제안이 구분된다.
- 응답, 상태 코드와 보상 정책은 코드 근거로 유지 여부가 확인됐거나, 근거 부재가 `확인 필요`로 판정됐다. 근거가 없는 정책은 추측해 확정하지 않았다.
- 문서가 허용된 섹션과 이력관리만 포함한다.

## 이력관리

- 2026-07-23: `$ct-tran-plan` 명시 호출만 허용하고 자연어 호출 조건을 제거했다.
- 2026-07-13: 자연어 호출 표현, 완전한 시그니처 기반 대상 확인, core 문서의 `.docs` 우선·`.0_my` 읽기 fallback, base package 확정 여부에 따른 경로 표기, 변경 요청이 없는 계약 보존과 사용자 목표 계약 전파, source path·FQCN·완전 시그니처의 SHA-256 기반 충돌 회피 파일 식별자, `component` 접두사, legacy 다중 경로 후보 수집과 대상 동일성 검증, 근거 부재의 `확인 필요` 판정, 필수 목표 CallTree와 전환 계획 파일의 신규 생성·기존 갱신 기준을 정리했다.
