---
name: ct-calltree-test
description: Generate Java unit tests from CallTree markdown documents by reading [TC:✅] nodes and determining test strategy locally from code and existing tests. Use when Codex needs to turn a CallTree document into Java unit tests without treating ct-calltree as a prerequisite contract provider.
---

# Java CallTree 기반 테스트 생성

CallTree 문서(`ct-calltree` 산출물)와 실제 운영코드를 함께 읽고 `[TC:✅]` 호출 노드를 검증하는 Java 단위 테스트를 만든다.
속도보다 정확도를 우선한다.

이 스킬은 `ct-calltree`에 종속되지 않는다.
CallTree 문서에 담긴 `family`, `bundle`, `branchType`, `priority`는 분석 중 수집된 참고 데이터로 사용하고,
테스트 전략(`mainTestClass`, `fixtureStrategy`, `fixtureGroup`, `mainTestGroup`)은 이 스킬이 자체 규칙으로 결정한다.

## 추가 참조

- `references/calltree-test-patterns.md`
  - 테스트 이름, 로그, helper/fixture 세부 패턴, 자주 틀리는 패턴, 최종 체크리스트
- `templates/`
  - `main-test-template.java.md` — MainTest 코드 뼈대
  - `main-test-doc-template.md` — MainTest 보조 문서 뼈대
  - `request-fixture-template.md` — shared fixture 뼈대
  - `calltree-contract-audit-template.md` — 최종 audit 보고 형식

템플릿은 뼈대만 제공한다. 테스트 입력값, mock, assertion, 분기 범위는 반드시 운영코드 분석으로 채운다.

## 입력 형식

- `$ct-calltree-test $calltree-main.md`
- `$ct-calltree-test $calltree-main.md targetService.targetMethod()`

### 입력 해석
1. 첫 번째 인자는 CallTree markdown 파일명 또는 경로다.
2. 파일명이면 우선 `.0_my/call-trees/`에서 찾고, 없으면 저장소 전체에서 찾는다.
3. 두 번째 인자(`target-call`)가 있으면 해당 호출만 대상으로 한다.
4. `target-call`이 없으면 `[TC:✅]` 전체를 대상으로 한다.

## 핵심 원칙

1. 테스트 로직은 반드시 실제 소스 코드에서 추출한다. 조건식, 예외 흐름, 기대값을 추측으로 만들지 않는다.
2. 검증 포인트마다 근거 코드(클래스/메서드/라인)를 확인한다.
3. `[TC:✅]` 대상 선정 책임은 `ct-calltree`에 있고, 이 스킬은 선정된 대상을 정확히 테스트로 구현한다.
4. 운영코드상 테스트 필요도가 낮아 보여도 `[TC:✅]` 대상이면 테스트를 생성한다. 필요도 낮음 판단은 Javadoc이나 보조 문서에 메모로 남긴다.
5. 기존 저장소 테스트를 복제하지 않는다. 저장소 코드는 패키지/의존성/타입 적응 용도로만 참고한다.
6. CallTree의 3depth 트리는 범위 안내용이다. 대상 노드에 대해서는 실제 소스를 다시 열어 assertion이 닫히는 지점까지 추적한다.
7. 전체 파일의 full call graph를 다시 그리지 않는다. 대상 call 또는 bundle에 필요한 범위까지만 추적한다.
8. 테스트 메서드는 대상 운영 클래스에 대응하는 `*UnitTest.java`에만 존재한다. 같은 메서드를 다른 파일에 중복 생성하지 않는다. 기존 UnitTest에 이미 전용 메서드가 있으면 새로 만들지 않고 MainTest에서 참조한다.
9. Controller 테스트 계층 규칙:
   - 단순 위임: Controller가 조건 분기·변환·후처리 없이 `service.method()` 호출만 하는 `[TC:✅]` 노드는 `*ControllerUnitTest`를 만들지 않는다. `*ServiceUnitTest`에 작성하고, MainTest도 `ServiceUnitTest`를 직접 참조한다.
   - Controller 고유 로직 존재: Controller에 호출 조건 분기, private helper, 예외 보상 등 고유 로직이 있으면 `*ControllerUnitTest`를 생성한다. 단, 엔드포인트 메서드 전체를 호출하지 않는다. Controller 고유 로직 지점만 직접 테스트한다.

## 테스트 명명 규칙

| 케이스 | 패턴 | 예시 |
|--------|------|------|
| 정상 호출 | `{methodName}_Test` | `checkProductStock_Test` |
| 외부 조건 미충족 | `{methodName}_{사유}_NoCall` | `checkPayment_PaymentTypeMismatch_NoCall` |
| 내부 하위 호출 생략 | `{methodName}_{사유}_NoServiceCall` | `sendReceipt_NoReceiptCondition_NoServiceCall` |
| 예외 삼킴 | `{methodName}_{예외}_{결과}` | `insertHistory_InsertException_LogsErrorAndReturnsDto` |

구체적 사유가 있으면 `NotApplicable_NoCall`보다 구체 이름을 선호한다.
세부 이름 패턴은 `references/calltree-test-patterns.md`를 따른다.

## 테스트 쌍 구조

각 `[TC:✅]` 노드마다 최소 아래 쌍을 기본 생성한다:
- `{methodName}_Test` — 정상 호출 검증
- `{methodName}_{사유}_NoCall` — 외부 조건 false로 호출 안 됨 검증

내부 분기가 있으면 `_NoServiceCall`, `_Skip` 등 추가 케이스를 만든다.

### `_NoCall` vs `_Throws*` 판단 흐름

```text
호출자(controller/상위 service)에 if/조건분기가 있어
대상 메서드 자체가 불리지 않는 경우가 존재하는가?
  ├─ YES → `_NoCall` 케이스 필수 생성
  └─ NO  → `_NoCall` 생략 가능

대상 메서드 내부에서 예외를 던지는 분기가 있는가?
  ├─ YES → `_Throws*` 케이스 생성
  └─ NO  → 생략

둘 다 존재하면 `_NoCall` + `_Throws*` 모두 생성한다.
```

- 외부 조건 유무는 반드시 호출자 코드에서 확인한다. CallTree만 보고 판단하지 않는다.
- 외부 조건이 없어서 `_NoCall`을 생략할 때는, 내부 분기 케이스(`_Throws*`, `_NoServiceCall`, `_Skip` 등)가 반드시 1개 이상 있어야 한다.

## 시그니처 페어 규칙

MainTest가 `reqJson`을 넘겨 UnitTest 메서드를 호출하는 흐름에서는 아래 페어를 필수로 만든다.

```java
@Test
public void targetMethod_Test() throws Exception {
    targetMethod_Test(TestResourceLoader.loadOrderCreateBase());
}

public void targetMethod_Test(Map<String, Object> reqJson) throws Exception {
    // 실제 검증 로직
}
```

- 이 규칙은 `_Test`, `_NoCall`, `_NoServiceCall`, `_Throws*` 케이스 모두에 동일 적용한다.

## Mock 초기화 패턴

```java
@Before
public void setUp() {
    targetService = new TargetServiceImpl();
    dependency = mock(DependencyClass.class);
    ReflectionTestUtils.setField(targetService, "dependency", dependency);
}
```

- `@Before`에서 대상 서비스를 `new`로 생성, 의존성은 `mock()` + `ReflectionTestUtils.setField()`로 주입한다.
- Spring context(`@Autowired`)는 사용하지 않는다.

## Shared Fixture 규칙

### 적용 조건
- 여러 테스트가 같은 header/body/payment/meta 구조를 공유할 때
- call-site 분기가 입력 JSON/Map에 의해 결정될 때
- 같은 `fixtureGroup`에 노드가 2개 이상이면 shared fixture 기본 적용

### fixtureStrategy 해석
- `shared-request`: 공통 request fixture를 먼저 만들고, helper는 꼭 필요한 최소 범위만 둔다.
- `shared-helper`: 공통 request fixture와 `applyXTrigger`, `executeXIfApplicable` helper를 함께 설계한다. helper는 운영코드 분기 재현용으로만 쓰고, 테스트 전용 게이트를 추가하지 않는다.

### 기본 파일
- `src/test/resources/{domain}/{entrypoint}/base-request.json`
- UnitTest는 반드시 base-request.json을 로드하여 입력을 구성한다. `new VO() + setter` 하드코딩 금지.
- 테스트별 조건 변경은 Map에서 값을 덮어쓴 뒤 VO로 변환하는 방식으로 처리한다.

### 기본 helper 패턴

```java
private boolean isTargetApplicable(Map<String, Object> reqJson) { ... }

private void applyTargetTrigger(Map<String, Object> reqJson) { ... }

private ReturnType executeTargetIfApplicable(Map<String, Object> reqJson) { ... }

private void applySecondaryTrigger(Map<String, Object> reqJson) { ... }

private ReturnType executeSecondaryIfApplicable(Map<String, Object> reqJson) { ... }
```

### helper 규칙
1. helper는 실제 호출 구조를 재현하기 위한 최소 범위로만 만든다.
2. helper 안에 운영코드에 없는 외부 게이트를 새로 만들지 않는다.
3. negative 케이스도 가능하면 helper를 실제로 실행한다.
4. helper가 `null`, `emptyList`, `0` 등을 반환하는 경우 그 의미가 운영코드 분기와 맞아야 한다.
5. `shared-helper` 전략이면 helper 이름도 실제 call family가 드러나게 유지한다.
6. fixture 하나로 2개 이상 call family를 재현할 수 있게 설계한다.

## 로그 패턴

- `[TAG][STEP]` 형식을 사용한다.
- production method 호출 직전에 `[➡️ CALL]` 로그를 반드시 남긴다.
- negative 케이스에서도 미호출/생략 결과가 로그로 드러나야 한다.
- 내부 로직이 있으면 단계 의미가 드러나는 로그를 남긴다.
- 모든 `@Test` 메서드에 적용한다. UnitTest, Controller 직접 호출, `ReflectionTestUtils.invokeMethod` 모두 동일하다.

## 노드 완료 게이트

노드 1개의 처리가 끝났다고 보려면 아래 항목을 모두 통과해야 한다.

1. 독립 테스트 존재: 해당 노드 전용의 `@Test` 메서드가 `*UnitTest.java`에 존재하는가
2. 테스트 쌍 완성: `_Test` + negative 케이스가 모두 존재하는가
3. 시그니처 페어 완성: MainTest가 파라미터 호출을 사용하면 페어가 존재하는가
4. 소스 근거 확인: 각 assertion에 대응하는 운영코드 위치(클래스:라인)를 특정할 수 있는가
5. assertion 닫힘: 호출 여부, 파라미터 매핑, 분기 결과, side effect 중 해당되는 것이 모두 검증되었는가
6. 로그 패턴 적용: 모든 `@Test`에 `[TAG][STEP]` 로그가 있는가
7. 명명 규칙 준수: 메서드 이름이 테스트 명명 규칙에 맞는가
8. ArgumentCaptor 판단: mapping/조립 계열이면 캡처 기반 검증, 단순 위임이면 매처 허용. 애매하면 캡처 사용
9. fixture 사용 확인: shared fixture가 존재하는 흐름이면 base-request.json에서 파생되었는가

## 테스트 전략 결정 규칙

CallTree 문서에는 분석 결과와 테스트 보조 데이터만 있고, 테스트 전략은 이 스킬이 아래 규칙으로 결정한다.
각 규칙에는 우선순위가 있으며, 충돌 시 상위 규칙이 이긴다.

### 1. mainTestClass

1. 기존 `*MainTest.java`가 있으면 그 파일을 우선 사용한다.
2. 없으면 엔트리포인트 메서드의 소속 클래스 기준으로 `{RootClassName}MainTest`를 만든다.
3. Controller가 단순 위임이어도 MainTest 이름은 엔트리포인트 기준으로 유지한다.
4. 후보가 둘 이상이면 기존 Javadoc, `testNN_*` 구성, 호출 대상 일치율이 가장 높은 파일을 택한다.

### 2. fixtureStrategy

1. 기존 `base-request.json`이 있으면 `shared-request`로 본다.
2. 노드 2개 이상이 같은 요청 JSON 골격을 공유하면 `shared-request`.
3. VO/Map 공통 빌더나 helper 메서드 재사용만 필요하면 `shared-helper`.
4. 노드마다 입력 구조가 실질적으로 다르면 `none`.

### 3. fixtureGroup

1. 기본값은 `bundle`과 동일하게 시작한다.
2. 같은 bundle 안에서도 입력 구조가 다르면 그룹을 분리한다.
3. 다른 bundle이어도 같은 request fixture를 그대로 공유하면 같은 그룹으로 묶는다.

### 4. mainTestGroup

1. 같은 `bundle`은 같은 `testNN_*` 묶음으로 둔다.
2. 한 bundle 안에 성격이 완전히 다른 노드가 섞이면 `family` 기준으로 분리한다.
3. 새 그룹 번호는 기존 MainTest의 마지막 `testNN_*` 다음 번호를 쓴다.

## 기본 워크플로우

### Phase 0: 대상 목록 생성

1. CallTree에서 아래 섹션을 제목 기준으로 찾아 읽는다:
   - `[TC:✅] 노드 요약` → 대상 노드 목록과 분석 속성 확인
   - `메서드별 호출 트리` → 호출 흐름 파악
   - `특이사항` → 분석 시 발견된 주의 사항 확인
2. `[TC:✅] 노드 요약`이 없으면 트리의 `[TC:✅]` 표기를 기준으로 fallback 진행하되, 범위 판단이 약해질 수 있음을 짧게 알린다.
3. 테스트 전략 결정 규칙에 따라 `mainTestClass`, `fixtureStrategy`, `fixtureGroup`, `mainTestGroup`을 결정한다.
4. 기존 테스트/관련 소스/문서 위치를 병렬 수집한다.
5. 기존 MainTest를 찾고, 있으면 그 파일을 우선 갱신 대상으로 삼는다.
6. 대상 목록을 생성한다:
   - `[TC:✅]` 전체 노드를 나열한다.
   - Controller 단순 위임 여부를 확인해 대응 UnitTest를 정한다.
   - `reuse`, `supplement`, `new` 상태를 판정한다.
   - `new`/`supplement` 노드에만 순번(M01, M02, ...)을 부여한다.
7. 같은 `fixtureGroup`에 노드가 2개 이상이면 shared fixture를 기본 적용한다.

### Phase 1: 노드별 처리

대상 목록 순서대로 아래를 반복한다.

1. 운영코드를 읽고 외부 조건, 내부 분기, 후처리, 예외 처리, 필요한 추가 추적 범위를 확정한다.
2. 테스트 대상 호출 방식을 정한다.
3. 테스트 코드를 작성한다.
4. 노드 완료 게이트를 점검한다.
5. 완료 보고 후 다음 노드로 이동한다.

### Phase 2: 마무리

1. MainTest를 `mainTestGroup` 기준으로 생성/갱신한다.
2. 보조 문서를 `.0_my/call-trees/{MainTestClass}_YYYYMMDD_HHMMSS.md`에 생성/갱신한다.
3. 가능한 범위에서 `test-compile` 또는 실제 실행 검증을 수행한다.

## 처리 전략

### 기본 모드

기본 동작은 노드 1개를 온전히 닫고, 완료 보고 후 즉시 다음 노드로 이동하는 방식이다.

### 병렬 모드: `--parallel`

사용자가 명시적으로 `--parallel`을 지정했을 때만 병렬 처리한다.

- Agent 1개 = 노드 1개
- shared fixture와 MainTest는 메인 흐름에서만 생성/수정
- 각 Agent는 담당 노드의 테스트 코드, 메서드 목록, assertion-근거 매핑, 게이트 점검 결과를 반환
- 메인 흐름에서 게이트 통과 여부와 누락 노드를 검수

## 재탐색 정지 조건

아래가 모두 확보되면 더 깊게 내려가지 않는다.

1. 대상 메서드 호출 여부를 검증할 수 있다.
2. 주요 파라미터 매핑을 assertion으로 표현할 수 있다.
3. 내부 skip/default/예외 branch를 테스트 이름과 검증으로 닫을 수 있다.
4. 최종 side effect 또는 후처리 결과가 확인된다.

## benchmark commit 처리

사용자가 `git > <commit>` 또는 비슷한 benchmark 기준을 주면:

1. `git show --stat`, `git show --name-only`로 benchmark commit의 산출물 구조를 확인한다.
2. benchmark commit이 포함하는 산출물 층위(fixture, UnitTest, MainTest, 보조 문서)에 맞춘다.
3. benchmark commit이 없으면 기본 완료 단위(call 1개)를 유지한다.

## 메인 실행기와 보조 문서

1. 테스트 생성 시 해당 흐름의 `*MainTest.java`도 함께 생성하거나 갱신한다.
2. 각 `testNN_*`는 call 하나만이 아니라 branch family 또는 call family 묶음을 대표하도록 잡는다.
3. partial 상태면 클래스 Javadoc과 보조 문서에 현재 반영 범위를 남긴다.
4. 보조 문서에는 CallTree의 `bundle`, `priority`와 테스트 스킬이 결정한 `mainTestGroup` 기준을 같이 드러낸다.
5. 코드 뼈대와 문서 뼈대는 `templates/`를 참조한다.

## Contract Audit 보고

최종 audit에 적는 `mainTestClass`, `fixtureStrategy`, `mainTestGroup` 등은
CallTree가 고정해서 넘긴 계약이 아니라, 이 스킬이 이번 실행에서 결정한 값이다.
보고 형식은 `templates/calltree-contract-audit-template.md`를 따른다.

## 완료 기준

1. 모든 노드가 노드 완료 게이트를 통과했을 때 전체 완료다.
2. MainTest는 partial이어도 되지만, 현재 반영 범위가 바로 실행 가능해야 한다.
3. 테스트 파일만 추가한 상태를 완료로 보지 않는다. MainTest, 보조 문서까지 함께 맞아야 한다.
4. 기존 파일을 수정한 경우, 해당 파일이 git staging에 포함되었는지 확인하고 누락 시 경고한다.

## 실패 대응

1. 파일 읽기나 코드 검색이 가능하면 사용자 확인 없이 직접 수행한다.
2. 빌드/테스트 실패 시 우회한다:
   - PowerShell 인자 이슈 → `mvn.cmd`
   - 인코딩 이슈 → UTF-8 옵션
   - 실행 스킵 → `test-compile`로 최소 검증
3. 우회 경로가 남아 있으면 멈추지 않는다. 정말 불가능할 때만 사용자 검증으로 전환한다.

## 금지 항목

1. Controller 엔드포인트를 직접 호출해 우회 검증하는 방식
2. 코드 근거 없이 mocking/stubbing을 과도하게 추가하는 방식
3. CallTree만 보고 실제 코드 확인 없이 테스트를 생성하는 방식
4. 기존 테스트를 임의 삭제하거나 대체하는 방식
5. 운영코드에는 없는 외부 조건을 테스트 helper에 추가하는 방식
6. CallTree와 실제 코드가 충돌할 때 독자적으로 대상을 제외하거나 추가하는 방식
7. `@Test` 메서드에서 `[TAG][STEP]` 로그를 생략하는 방식
8. 같은 테스트 메서드를 여러 UnitTest 파일에 중복 생성하는 방식
9. 동일 엔트리포인트에 기존 MainTest가 있는데 이름이 다르다는 이유만으로 신규 MainTest를 생성하는 방식
10. Controller가 Service에 단순 위임하는 노드에 대해 `*ControllerUnitTest`를 생성하는 방식
