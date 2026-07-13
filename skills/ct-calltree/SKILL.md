---
name: ct-calltree
description: Java Controller 또는 Service의 호출 관계를 분석해 3depth CallTree와 최종 `[TC:✅]` 테스트 대상을 문서로 만든다. 사용자가 `$ct-calltree`, `ct-calltree`, legacy `/ct:calltree`, `calltree`, Java 호출 흐름 분석, CallTree 생성 또는 테스트 대상 호출 판정을 요청할 때 사용한다.
---

# CT CallTree

Java 진입점의 의미 있는 호출 흐름과 테스트 대상 호출을 실제 소스 기준으로 정리한다.

## 입력

- Java 파일 경로 또는 클래스명
- 선택 입력: 메서드명, 엔드포인트, 분석 필터
- legacy 호출인 `/ct:calltree`, `calltree`도 같은 입력 규칙으로 처리한다.
- 파일명만 주어지면 저장소에서 찾고 후보가 여러 개일 때만 기준 클래스를 묻는다.

## 분석 범위

- Controller 입력: `Controller → Service/Helper → DAO/Mapper/Repository/외부 연동`
- Service 입력:
  - 상위 호출자 검색
  - `Service → Service/Helper → DAO/Mapper/Repository/외부 연동`
- 기본 깊이: 루트 메서드를 depth 1로 계산한 3depth
- depth 2 메서드의 본문을 열어 의미 있는 직접 collaborator를 depth 3에 기록한다. 의미 있는 호출이 없을 때만 leaf로 둔다.
- depth 2의 private helper 내부에서 직접 호출하는 Service, DAO, Mapper, Repository와 외부 연동도 depth 3에 기록한다.
- 선택 심화: 아래 조건에 해당하는 `[TC:✅]` 노드만 테스트 경계가 드러날 때까지 추적
  - private helper 체인이 2단계 이상 이어져 3depth에서 최종 분기, 대상 호출 또는 assertion 경계가 끊긴다.
  - 예외 삼킴, 후처리 또는 부수효과가 helper 안에 숨어 있다.
  - 심화 대상 노드의 경계가 확인되면 멈추고 형제 노드는 함께 펼치지 않는다.

호출 트리의 별도 노드는 아래 허용 유형에서 선택한다.

- Service와 업무 helper
- DAO, Mapper와 Repository
- 외부 API, MQ, 파일, 메일, SMS
- 분기와 하위 호출을 제어하는 private helper
- 상태 변경, 저장, 보상, 후처리

getter/setter, 로깅, 단순 컬렉션 조작, DTO 필드 설정, 범용 라이브러리 호출은 부모 노드 설명에 필요한 경우만 요약한다.

## 출력 표기

- `[TC:✅]`는 최종 테스트 대상으로 판정한 호출 앞에만 붙인다.
- 대상 노드는 `[TC:✅] [N01] {callNode}` 형식으로 `nodeId`를 함께 표기한다.
- 비대상 호출은 접두사 없이 적는다. 비대상 표시에 `O`, `X` 또는 별도 상태 기호를 사용하지 않는다.
- 루트 메서드도 본문 기준으로 판정한다. 진입점이라는 이유만으로 `[TC:✅]`를 붙이지 않는다.
- 트리의 모든 메서드 노드는 canonical `callNode`로 적는다.
- 트리 본문과 `[TC:✅] 노드 요약`은 `nodeId`, `callPath`, `callNode` 행과 중복 개수까지 정확히 일치시킨다.
- 실제 메서드명과 설명문을 같은 트리 깊이의 노드로 혼용하지 않는다.

## `[TC:✅]` 판정

메서드 본문에 아래 동작이 하나라도 있으면 테스트 대상으로 판정한다.

- 조건 분기, 반복, 검증, 예외 처리
- 데이터 가공, 조합, 후처리
- 외부 연동 또는 부수효과
- 복수 컴포넌트 호출을 조정하는 흐름
- 예외를 삼키고 기본값을 반환하는 처리
- 호출 여부나 하위 호출을 제어하는 private helper

외부 경계 호출은 단순 위임보다 우선해 판정한다.

- 대상 메서드가 외부 API, MQ, 파일, 메일 또는 SMS 경계를 직접 호출하면 즉시 반환하더라도 `[TC:✅]`로 판정한다.
- 내부 Service나 helper에 즉시 위임하고 실제 외부 경계를 호출하지 않는 메서드는 아래 비대상 기준을 적용한다.

아래 조건을 모두 만족하면 비대상으로 둔다.

- 다른 컴포넌트를 즉시 호출하고 반환한다.
- 분기, 변환, 후처리, 예외 처리, 부수효과가 없다.
- 상위 흐름 테스트만으로 동작을 충분히 검증할 수 있다.

판정은 호출자 복잡도가 아니라 대상 메서드 본문을 기준으로 한다. 애매하면 호출자 또는 피호출자를 한 단계 더 확인한다.

## 노드 요약 계약

`[TC:✅] 노드 요약`은 `ct-calltree-test`가 읽는 후속 입력 계약이다.

- 현재 계약 버전: `2`
- `문서 정보`의 `contractVersion`에 현재 버전을 기록한다.
- `문서 정보`의 `nextNodeSequence`에 다음 신규 노드가 사용할 양의 정수 순번을 기록한다.
- `contractVersion`이 없는 기존 문서는 legacy 계약으로 본다.
- 기존 문서를 갱신할 때는 현재 필드와 판정 근거를 다시 확인하고 버전 `2`로 작성한다.
- 기존 문서의 `contractVersion`이 `2`가 아닌 명시 버전이면 덮어쓰지 않는다. 지원하지 않는 버전과 경로를 보고하고 호환 규칙이 확정된 뒤 갱신한다.

| 필드 | 기준 |
|---|---|
| `nodeId` | 문서 안에서 안정적으로 참조할 식별자 |
| `callPath` | 루트부터 대상까지 canonical `callNode`를 ` -> `로 연결한 안정적인 호출 경로 |
| `callNode` | receiver, 메서드명과 파라미터 타입을 포함한 호출 시그니처 |
| `layer` | `controller`, `helper`, `service`, `utility`, `external`, `dao`, `mapper`, `repository` |
| `family` | `precheck`, `mapping`, `payment`, `db-write`처럼 호출이 맡은 업무 역할 |
| `bundle` | `payment-core`, `trx-family`처럼 함께 검증할 업무 단위 |
| `branchType` | 호출자 관점의 호출·미호출 조건 |
| `priority` | `critical`, `high`, `normal` |

`branchType`에는 대상 메서드 내부 분기를 적지 않는다.

`family`와 `bundle`은 메서드명, 클래스명, 테스트 파일명이 아니라 역할 기준으로 작성한다. 같은 역할은 같은 `family`를 사용하고, 하나의 업무 결과를 함께 완성하는 호출은 같은 `bundle`로 묶는다.

`callNode`는 `com.example.PaymentService.pay(java.lang.String,int)`처럼 receiver 구분자에 `.`을 사용해 작성한다. overload가 없더라도 괄호와 canonical 파라미터 타입을 유지하고, 트리 본문과 노드 요약에 같은 시그니처를 사용한다.

### `callNode` canonical 표기

- receiver와 참조형 파라미터는 패키지를 포함한 정규화된 클래스명을 사용한다.
- primitive는 Java 키워드를 그대로 사용한다.
- generic 타입은 타입 인자를 제거한 erasure 타입으로 기록한다. 예: `java.util.List<java.lang.String>`은 `java.util.List`다.
- varargs는 배열로 통일한다. 예: `java.lang.String...`은 `java.lang.String[]`다.
- 배열 차원은 `[]`로 유지하고 nested class는 canonical name의 `.` 구분자를 사용한다.
- annotation, modifier, 파라미터명과 불필요한 공백은 기록하지 않는다.

### `callPath` 표기

- 루트의 canonical `callNode`부터 대상 노드의 canonical `callNode`까지 실제 호출 순서대로 ` -> `로 연결한다.
- 트리에 표시한 경로와 노드 요약의 `callPath`를 동일하게 유지한다.
- 동일한 `callNode`가 여러 호출 경로에 있으면 각 경로를 별도 행과 별도 `nodeId`로 기록한다.

### `nodeId` 안정성

- 신규 문서는 트리 순서대로 `N01`부터 부여하고 마지막 부여 순번의 다음 값을 `nextNodeSequence`에 기록한다. 대상 노드가 없으면 `nextNodeSequence`는 `1`이다.
- 기존 문서를 갱신할 때 같은 `callPath`와 `callNode`에는 기존 `nodeId`를 유지한다.
- 신규 노드는 `nextNodeSequence`를 사용하고 부여 직후 값을 1 증가시킨다. 중간 삽입을 이유로 기존 노드를 재번호화하지 않는다.
- `nodeId`는 `N` 뒤에 순번을 최소 두 자리로 0 채움해 만든다. 예: 순번 `2`는 `N02`, 순번 `105`는 `N105`다.
- 삭제된 번호를 다른 호출에 재사용하지 않는다.
- `nextNodeSequence`는 문서 갱신과 노드 삭제 때 낮추지 않는다. 현재 노드의 최대 번호보다 작거나 같으면 최대 번호의 다음 값으로 올린다.
- `nextNodeSequence`가 없는 기존 문서는 노드를 제거하기 전에 기존 본문과 노드 요약에 남은 모든 `nodeId`의 최대 번호 다음 값으로 초기화한다.
- `callPath`나 `callNode`가 바뀌어 동일 노드인지 확정할 수 없으면 새 번호를 부여하고 `특이사항`에 이전·신규 식별자 관계를 기록한다.

### `branchType` 허용값

호출자에서 확인한 조건 구조를 아래 값으로 기록한다.

| 호출자 조건 | 값 |
|---|---|
| 항상 호출 | `always` |
| 조건 충족 시 호출 | `applicable/skip` |
| 정상 처리와 선행 예외 | `normal/exception` |
| 일반 처리와 조건 생략 | `normal/skip` |
| 예외 시 보상 호출 | `compensation/skip` |

대상 메서드 내부의 도메인 분기는 `[TC:✅]` 판정 근거에 기록한다.

### `priority` 허용값

| 값 | 적용 기준 |
|---|---|
| `critical` | 결제, 인증, 상태 확정, 외부 승인, 보상, 정합성 영향 |
| `high` | 주요 검증, 데이터 조립, 복수 컴포넌트 조정 |
| `normal` | 국소 분기, 후처리, 기본값 처리 |

### 판정 순서

1. 대상 메서드 본문의 분기, 반복, 예외, 변환, 외부 연동을 확인한다.
2. 반환값 후처리와 상태 변경을 확인한다.
3. 복잡성이 호출자에만 있으면 호출자 노드에 판정한다.
4. 상위 흐름 테스트로 충분한 단순 위임은 비대상으로 분류한다.
5. 근거가 경계에 걸리면 호출자 또는 피호출자를 한 단계 더 읽는다.

## 실행 절차

1. 대상 파일과 메서드를 확정한다.
2. 파일 유형과 진입점을 판정한다.
3. 의미 있는 직접 호출을 추출한다.
4. Service 입력이면 상위 호출자를 검색한다.
5. 각 호출의 실제 본문을 읽고 `[TC:✅]` 여부를 판정한다.
6. 트리 본문과 노드 요약의 `[TC:✅]` 목록을 맞춘다.
7. `.docs/call-trees/`, `.0_my/call-trees/`, 저장소 전체 순서로 같은 문서를 찾고 누락과 범위 차이를 확인한다.
   - `.docs/call-trees/`에 기존 문서가 있으면 그 파일을 갱신한다.
   - `.docs/call-trees/`에는 없고 `.0_my/call-trees/`에만 있으면 기존 경로의 파일을 갱신한다.
   - 두 위치에 모두 있으면 `.docs/call-trees/` 문서를 정본으로 갱신하고 legacy 중복 경로를 결과에 기록한다.
   - 앞선 두 위치에는 없고 저장소 전체 탐색 구간에 하나만 있으면 해당 기존 파일을 갱신한다.
   - 저장소 전체 탐색 구간에 후보가 여러 개면 파일을 수정하지 않고 후보 경로를 보고한다.
   - 선순위 위치에서 정본을 확정한 뒤 발견한 후순위 동일 문서는 수정하지 않고 중복 경로로 기록한다.
   - 기존 문서가 없을 때만 `.docs/call-trees/`에 신규 작성한다.
   - 기존 문서를 갱신할 때는 `nodeId`, `nextNodeSequence`와 이력만 보존하고 필수 섹션 전체를 현재 소스 기준으로 다시 구성한다.
   - 삭제되거나 범위에서 빠진 메서드와 노드는 최종 본문과 노드 요약에서 제거한다.
8. 출력 전 `templates/calltree-output-template.md`를 처음부터 끝까지 읽고 해당 구조로 작성한다.

## 출력

- 저장 위치: `.docs/call-trees/`
- 기본 파일명: `callTree-{ClassName}.md`
- 필터 적용 파일명: `callTree-{ClassName}-{filter}.md`
- 필터 slug 생성:
  1. 앞뒤 공백과 `/`, `\\`를 제거한다.
  2. 공백, 경로 구분자와 `[A-Za-z0-9_-]` 이외의 연속 문자를 `-` 하나로 바꾼다.
  3. 연속된 `-`를 하나로 줄이고 앞뒤 `-`, `_`를 제거한다.
  4. ASCII 외 문자에 의미 있는 글자나 숫자가 있으면 UTF-8 원문 SHA-256의 앞 8자를 slug 뒤에 붙인다.
  5. 필터가 입력됐는데 slug가 비면 `filter-{hash8}` 형식을 사용한다.
  6. 필터가 입력된 문서는 접미사를 생략하지 않는다.
  7. 예: `/v4/`는 `v4`, `v1/order detail`은 `v1-order-detail`, `결제`는 `filter-{hash8}`, `결제-v4`는 `v4-{hash8}`로 쓴다.
- 문서 마지막에 `## 이력관리`를 둔다.

## 완료 조건

- 실제 메서드명과 호출 관계가 소스와 일치한다.
- 기본 3depth 또는 선택 심화 기준이 지켜졌다.
- 트리와 노드 요약의 `[TC:✅]` `nodeId`, `callPath`, `callNode` 행과 중복 개수가 일치한다.
- 각 대상과 비대상 판정 근거가 기록됐다.
- 기존 문서를 갱신한 경우 현재 범위에서 빠진 메서드와 노드가 최종본에 남아 있지 않다.
- 출력 템플릿의 필수 섹션과 이력관리가 포함됐다.

## 이력관리

- 2026-07-13: 최종 TC 판정 표현과 외부 경계 우선순위, mapper·repository를 포함한 역할 기반 노드 분류, depth 2 본문과 private helper의 의미 있는 직접 호출을 depth 3에 기록하는 기준, canonical 완전 시그니처 `callNode`, 안정적인 `callPath`, 트리의 `nodeId` 표기, CallTree 계약 버전, `nextNodeSequence` 기반 nodeId 안정성, private helper 심화, legacy 호출 별칭, 혼합 비ASCII 필터 충돌 방지, 기존 문서 전체 재구성과 제3 탐색 경로 호환 규칙을 보강했다.
