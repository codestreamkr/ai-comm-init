---
name: ct-calltree-test
description: "`ct-calltree` 문서의 `[TC:✅]` 노드를 실제 Java 소스와 대조해 단위 테스트, fixture, MainTest와 검증 보고를 만든다. 사용자가 `$ct-calltree-test`를 명시적으로 호출한 경우에만 사용한다."
---

# CT CallTree Test

CallTree는 대상 범위를 제공하고 실제 운영 코드는 테스트 조건과 assertion 근거를 제공한다.

## 입력

- `$ct-calltree-test <calltree-path> [target-call] [--standard-unit] [--parallel] [--benchmark <commit>]`
- 허용 옵션:
  - `--standard-unit`: MainTest 산출물을 만들지 않는 프로젝트 표준 단위 테스트 모드. 초기 입력에 명시하거나 legacy 부적합 보고 뒤 사용자가 선택할 수 있다.
  - `--parallel`: 서로 다른 테스트 파일의 노드를 Agent로 병렬 처리
  - `--benchmark <commit>`: 선택한 테스트 모드 안에서 기존 산출물 구성과 묶음 기준을 참고
- legacy benchmark 표현인 `git > <commit>`, `git <commit> 기준`, `<commit> 수준만큼`, `해당 커밋 수준만큼 <commit>`은 입력 해석 전에 `--benchmark <commit>`으로 정규화한다. `해당 커밋 수준만큼`만 입력되면 같은 요청에서 하나로 확정되는 commit을 사용하고, 없거나 여러 개면 확인이 필요한 입력으로 보고한다.
- 파일명만 주어지면 `.docs/call-trees/`, `.0_my/call-trees/`, 저장소 전체를 순서대로 찾고 처음 결과가 나온 탐색 구간에서 확정한다.
- 한 탐색 구간의 결과가 하나면 사용하고, 같은 구간에 후보가 여러 개면 후보 경로를 보고한다. 선순위 구간에서 파일을 확정하면 후순위 구간의 같은 이름은 입력 후보에 포함하지 않는다.
- 앞선 두 탐색 구간에 결과가 없고 저장소 전체 탐색 구간에서 하나를 찾으면 해당 기존 문서를 사용한다. 이 구간에 후보가 여러 개면 산출물을 수정하지 않고 모든 후보 경로를 보고한다.
- `target-call`이 없으면 `[TC:✅] 노드 요약` 전체를 처리한다.
- 노드 요약이 없는 구형 문서는 트리 본문의 `[TC:✅]` 표기를 대상으로 사용하고 legacy fallback 적용 사실을 audit에 기록한다.
- 옵션이 아닌 두 번째 위치 인자만 `target-call`로 해석한다.
- 허용 옵션 밖의 값은 대상이나 모드로 추정하지 않고 확인이 필요한 입력으로 보고한다.
- 실행 가능한 입력은 탐색 순서에서 하나로 확정된 CallTree와, 지정된 경우 Git commit으로 확인되는 benchmark ref다.
- `target-call`은 아래 우선순위로 대소문자를 유지해 일치시킨다.
  1. `N01` 같은 값이 노드 요약의 `nodeId`와 정확히 일치하거나, legacy fallback에서 `legacy-N01` 같은 값이 임시 식별자와 정확히 일치하면 해당 노드를 확정한다.
  2. 바깥쪽 backtick과 앞뒤 공백을 제거하고 receiver 구분자 `#`을 `.`으로 통일한다.
  3. selector에 ` -> `가 있으면 canonical `callPath`와 정확히 일치시킨다.
  4. selector에 괄호가 있으면 source와 import를 기준으로 receiver와 파라미터 타입을 canonical 표기로 정규화한 뒤 `callNode`와 일치시킨다.
  5. selector에 괄호가 없으면 후보의 마지막 메서드 파라미터 표현만 제거해 일치시킨다.
- 완전 시그니처는 receiver, 메서드명과 canonical 파라미터 타입을 모두 포함한다. source와 import를 확인해 receiver와 참조형은 패키지 포함 클래스명, primitive는 Java 키워드, generic은 erasure 타입, varargs는 배열, nested class는 canonical name의 `.` 표기로 정규화한다. 예: `com.example.PaymentService#pay(java.lang.String,int)`와 `com.example.PaymentService.pay(java.lang.String,int)`는 같은 selector다.
- 파라미터를 생략한 selector가 overload 등 여러 노드와 일치하면 각 후보의 `nodeId` 또는 legacy 임시 식별자, `callPath`, 원본 `callNode`를 보고하고 식별자, canonical `callPath` 또는 완전 시그니처로 하나를 확정한다.
- 완전 시그니처도 여러 호출 경로의 노드와 일치하면 같은 후보 필드를 보고하고 식별자 또는 canonical `callPath`로 확정한다.

## 필수 참조

작업 전에 필요한 파일만 처음부터 끝까지 읽는다.

- 항상: `references/calltree-test-patterns.md`
- 항상: `references/test-strategy.md`
- 항상: `templates/calltree-contract-audit-template.md`
- request fixture를 만들 때: `templates/request-fixture-template.md`
- `testMode=legacy-main-test`일 때: `templates/main-test-template.java.md`
- `testMode=legacy-main-test`에서 보조 문서를 만들거나 갱신할 때: `templates/main-test-doc-template.md`

## 핵심 원칙

- 조건, 예외, 기대값, assertion은 실제 소스에서 추출한다.
- assertion마다 근거 클래스, 메서드, 라인을 확인한다.
- CallTree와 실제 코드가 충돌하면 차이와 적용 기준을 보고하고 CallTree의 대상 책임을 유지한다.
- CallTree 대상을 추가하거나 제외해야 하면 차이를 보고한 뒤 사용자 확인을 받고 범위를 변경한다.
- 운영 코드상 필요도가 낮아 보여도 `[TC:✅]` 대상은 테스트하고 판단 근거를 Javadoc 또는 audit에 기록한다.
- 기존 테스트 구조, JUnit 버전, mocking 방식, fixture 관례를 먼저 따른다.
- 기존 테스트는 패키지, 의존성, 타입 적응과 `reuse` 판정에만 사용하고 테스트 로직을 복제하지 않는다.
- 대상 call 또는 bundle의 assertion 경계까지만 추적한다.
- Spring context가 필요 없는 단위 테스트는 직접 생성과 mock 주입을 우선한다.
- Controller가 단순 위임이면 Service 단위 테스트로 검증한다.
- Controller 고유 분기, 변환, 예외 보상이 있을 때만 해당 Controller 로직을 직접 검증한다.
- Controller 고유 로직 검증을 전체 엔드포인트 호출로 우회하지 않는다.
- 예외 삼킴은 이름, Javadoc 또는 테스트 로그에 의도를 드러내고 관찰 가능한 반환값이나 부수효과를 검증한다.

## 테스트 방식 선택

`references/test-strategy.md`의 허용 모드와 우선순위로 아래를 확정한다.

- `testMode`와 `legacyCompatibility`
- `mainTestClass`
- `fixtureStrategy`
- `fixtureGroup`
- `mainTestGroup`
- JUnit과 mocking 방식

기존 산출물 계약을 보존하는 `legacy-main-test`를 우선 검토한다. 사용자가 `--standard-unit`을 명시하면 프로젝트 표준 단위 테스트 산출물로 축소한다. 미지정 상태에서 legacy 적합성 게이트를 통과하지 못하면 파일을 수정하지 않고 부적합 근거를 제시한 뒤 `--standard-unit` 선택을 확인한다. benchmark commit은 선택된 모드를 바꾸지 않는다.

## 실행 절차

### 1. 대상 확정

1. CallTree의 `문서 정보`, `메서드별 호출 트리`, `[TC:✅] 노드 요약`, `특이사항`을 읽는다.
   - CallTree를 찾지 못하거나 후보가 여러 개면 파일을 수정하지 않고 경로 또는 후보를 보고한다.
   - legacy benchmark 표현을 먼저 `--benchmark <commit>`으로 정규화한다.
   - `--benchmark` 값은 `git rev-parse --verify <commit>^{commit}`으로 확인한다. commit으로 확인되지 않으면 산출물을 수정하지 않고 입력 오류를 보고한다.
   - CallTree 경로, target-call과 benchmark를 모두 확인한 뒤 입력 오류를 한 번에 보고한다.
2. `contractVersion`을 확인하고 아래 기준으로 대상을 수집한다.
   - 버전 `2`: 아래 계약 검증을 모두 통과한 뒤 노드 요약의 `nodeId`, `callPath`, `callNode`, `layer`, `family`, `bundle`, `branchType`, `priority`를 사용한다.
     - `문서 정보`에 `contractVersion=2`와 양의 정수 `nextNodeSequence`가 있다.
     - 노드 요약에 `nodeId`, `callPath`, `callNode`, `layer`, `family`, `bundle`, `branchType`, `priority` 열이 있고 모든 행의 필수 값이 비어 있지 않다.
     - `nodeId`는 `N`과 두 자리 이상의 숫자로 구성되고 문서 안에서 중복되지 않는다.
     - `nextNodeSequence`는 모든 현재 `nodeId` 숫자보다 크다.
     - `layer`는 `controller`, `helper`, `service`, `utility`, `external`, `dao`, `mapper`, `repository` 중 하나다.
     - `branchType`은 `always`, `applicable/skip`, `normal/exception`, `normal/skip`, `compensation/skip` 중 하나다.
     - `priority`는 `critical`, `high`, `normal` 중 하나다.
     - 트리의 모든 메서드 노드와 요약의 `callNode`는 receiver, 메서드명과 canonical 파라미터 타입을 포함한 `com.example.Receiver.method(java.lang.String,int)` 형식이다.
     - `callPath`는 루트부터 대상까지 canonical `callNode`를 ` -> `로 연결하며 마지막 항목이 같은 행의 `callNode`와 일치한다.
     - 트리의 각 `[TC:✅]` 노드는 `[TC:✅] [N01] {callNode}` 형식으로 `nodeId`를 포함한다.
     - 트리의 조상 노드에서 복원한 `callPath`와 `[TC:✅]` 노드의 `nodeId`, `callNode`를 하나의 행으로 만든다.
     - 트리에서 복원한 모든 `nodeId + callPath + callNode` 행과 노드 요약의 행을 일대일로 대조한다. 같은 `callNode`의 중복 경로를 집합으로 합치지 않으며 행별 중복 개수도 정확히 일치해야 한다.
     - 같은 `nodeId`가 다른 `callPath` 또는 `callNode`에 연결되거나, 같은 트리 occurrence가 여러 요약 행에 연결되면 계약 오류다.
   - 버전 `2` 계약 오류는 누락 필드, 잘못된 값과 불일치 항목을 모두 수집해 문서 경로와 함께 보고하고 테스트와 산출물을 수정하지 않는다.
   - 버전 없음, 노드 요약 있음: 노드 요약을 사용하고 트리 본문의 `[TC:✅]` 목록과 대조한다.
   - 노드 요약 없음: 트리 본문의 `[TC:✅]` 호출을 대상으로 사용하고 누락 필드는 실제 코드와 트리 문맥에서 보완한다.
   - legacy fallback에서 추론한 값과 범위 정확도 한계는 audit에 기록한다.
   - 버전 `2`가 아닌 명시 버전: 테스트와 산출물을 수정하지 않고 중단한다. 지원하지 않는 버전, 문서 경로와 필요한 호환 CallTree 재생성 조건을 보고한다.
   - 버전 `2`의 `nodeId`는 입력값을 그대로 유지한다.
   - legacy fallback에서만 트리 순서대로 audit와 `target-call` 선택에 사용하는 임시 식별자 `legacy-N01`부터 부여하며 CallTree 원문에는 쓰지 않는다.
3. 기존 운영 코드, 테스트, fixture, MainTest 위치를 검색한다.
4. 테스트 전략 값과 legacy 적합성을 확정한다.
   - UnitTest를 직접 생성하고 접근 가능한 `setUp()`을 수동 호출해 필요한 상태를 완성할 수 있는지 확인한다.
   - JUnit runner·extension, Spring context, Rule, parameter resolver 또는 컨테이너가 제공하는 lifecycle이 필요한 테스트는 `legacy-incompatible`로 판정한다.
   - request JSON/Map과 base request가 없는 Service, batch, message 흐름은 `legacy-incompatible`로 판정한다.
   - 사용자가 `--standard-unit`을 명시하지 않은 상태에서 `legacy-incompatible`이면 테스트, fixture, MainTest, 문서를 수정하지 않고 부적합 근거와 함께 `--standard-unit` 선택을 확인한다.
   - 사용자가 `--standard-unit`을 선택한 뒤에만 전략 값을 `standard-unit`으로 확정하고 다음 단계로 진행한다.
5. 노드별 상태를 `reuse`, `supplement`, `new`로 판정한다.
6. `supplement`, `new` 노드에 `M01`부터 처리 순번을 부여한다.
7. 처리 목록과 전략 값을 사용자에게 짧게 보여주고 계속 진행한다.

### 2. 노드 구현

각 노드를 순서대로 처리한다.

1. 대상 메서드와 호출자 코드를 읽는다. `layer=external`이면 외부 메서드 본문을 테스트 대상으로 삼지 않고 해당 경계를 직접 소유한 저장소 내부 caller 또는 wrapper를 `testOwner`로 확정한다.
2. 외부 호출 조건과 내부 분기를 분리한다.
3. 정상 경로와 실제로 존재하는 모든 negative·예외 경로를 정한다.
4. negative 케이스도 적용 가능 여부만 검사하고 끝내지 않고 허용 helper를 실제 실행한다.
5. helper가 반환하는 `null`, 빈 컬렉션, `0` 등 기본값이 운영 코드의 생략·기본값 의미와 일치하는지 검증한다.
6. 예외 삼킴 경로는 실제 의존성 예외를 재현하고, 운영 코드가 정한 비전파 결과와 반환값·상태·후속 호출·보상 중 관찰 가능한 의미를 검증한다.
7. mapping과 조립은 `ArgumentCaptor` 등으로 전달값을 검증한다.
8. 호출 여부, 반환값, 상태 변화, 부수효과 중 해당되는 assertion을 닫는다.
9. 기존 테스트 명명과 fixture 관례에 맞춰 작성한다.
10. `layer=external`이면 `testOwner`에서 외부 경계의 호출 여부, 전달값, 반환 처리와 실제 예외 처리를 검증하고 외부 라이브러리·벤더 메서드 자체의 단위 테스트는 만들지 않는다.
11. 노드 완료 게이트를 확인하고 다음 노드로 이동한다.

### 3. 흐름 산출물

- `legacy-main-test` 모드에서는 MainTest와 대응 보조 문서를 함께 생성하거나 갱신한다.
- `standard-unit` 모드에서는 기존 MainTest와 보조 문서를 삭제·대체하지 않고 프로젝트 표준 단위 테스트 산출물과 audit만 생성하거나 갱신한다.
- benchmark commit이 입력되면 선택된 테스트 모드가 허용하는 범위에서 파일 구성과 묶음 기준을 참고한다.
- Markdown 산출물은 `references/test-strategy.md`의 산출물 경로 계약에 따라 기존 문서를 갱신하거나 신규 작성한다.
- 최종 audit에는 계약 버전과 fallback, `nodeId`, `callPath`, `branchType`, `testOwner`, legacy 적합성, 테스트 전략, 적용한 코드 조건, 테스트 메서드, assertion 근거, 검증 결과를 기록한다.

## 노드 완료 게이트

노드별로 아래 항목을 모두 확인한다.

- 대상 노드 전용 테스트가 존재한다.
- 실제 코드에 있는 정상·negative·예외 경로가 검증됐다.
- negative 케이스가 helper 실행과 반환 의미 검증까지 포함한다.
- assertion 근거 위치를 특정할 수 있다.
- 호출 여부, 주요 매핑, 분기 결과, 부수효과가 필요한 범위에서 닫혔다.
- 기존 테스트 프레임워크와 명명 규칙을 따른다.
- shared fixture 대상이면 공통 fixture에서 입력을 파생했다.
- 운영 메서드별 테스트 정본 파일이 하나로 확정됐다.
- 선택한 테스트 모드의 signature, fixture, 로그 계약을 충족했다.
- `layer=external`이면 저장소 내부 caller 또는 wrapper가 `testOwner`로 기록되고 외부 경계 계약이 그 위치에서 검증됐다.

## 병렬 처리

사용자가 `--parallel`을 명시한 경우에만 Agent를 사용한다.

- 같은 테스트 파일을 수정하는 노드는 한 Agent가 처리한다.
- 공통 fixture, MainTest, audit는 메인 흐름에서 관리한다.
- Agent에는 담당 노드, UnitTest 경로, fixture 경로와 적용할 스킬 규칙을 전달한다.
- Agent는 변경한 테스트 파일과 메서드, assertion 근거 매핑과 완료 게이트 자체 점검 결과를 반환한다.
- 메인 흐름에서 assertion 근거와 완료 게이트를 다시 확인한다.

## 검증

프로젝트에서 제공하는 가장 좁은 검증부터 실행한다.

1. 대상 테스트 컴파일
2. 변경한 테스트 클래스 실행
3. 요청된 경우 관련 회귀 범위 실행

실패하면 이번 변경과 기존 실패를 구분한다. 검증을 수행할 수 없으면 명령, 실패 위치, 사용자 확인이 필요한 항목을 보고한다.

`references/test-strategy.md`에 정의된 환경별 검증 우회 순서를 적용한다.

## 완료 조건

- 요청 범위의 모든 노드가 완료 게이트를 통과했다.
- MainTest와 보조 문서를 만든 경우 서로 일치한다.
- 기존 테스트를 임의로 삭제하거나 다른 테스트로 대체하지 않았다.
- audit에 코드 근거와 검증 결과가 남았다.
- 생성한 Markdown 문서 끝에 `## 이력관리`가 있다.

## 이력관리

- 2026-07-23: `$ct-calltree-test` 명시 호출만 허용하고 legacy 호출 별칭을 제거했다.
- 2026-07-13: legacy CallTree와 호출 별칭, 제3 탐색 경로 처리, nodeId·legacy 임시 식별자·canonical callPath·완전 시그니처 target-call 선택, 입력 오류 일괄 확인, legacy benchmark 표현 호환과 commit 검증, contractVersion 2의 `nodeId + callPath + callNode` 행·중복 개수 검증, repository 계층, `nextNodeSequence` 기반 nodeId 안정성, external caller·wrapper 테스트 매핑, 모든 실제 negative·예외 경로와 예외 삼킴 의미 검증, legacy 적합성 차단과 확인 기반 standard-unit 전환, 병렬 Agent 인계·반환 계약, 기존 테스트 복제와 과도한 호출망 추적 차단 기준을 정리했다.
