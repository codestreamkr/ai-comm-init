# CallTree Test Patterns

이 문서는 `ct-calltree-test`의 세부 패턴 전용 reference다.
워크플로우, 완료 기준, benchmark 처리는 `SKILL.md`를 따르고, 이 문서는 이름/로그/helper/fixture/체크리스트만 다룬다.

## 1. 외부 조건 vs 내부 조건

### 외부 조건
- 호출자(controller, 상위 service, helper)의 분기에서 대상 메서드 호출 자체를 막는 조건
- 외부 조건이 false이면 대상 메서드는 실행되지 않는다
- 이 경우만 `..._NoCall` 이름을 쓴다

### 내부 조건
- 대상 메서드 본문에 진입한 뒤 내부 service/DAO/side effect 실행을 막는 조건
- 대상 메서드는 호출되므로 `NoCall`을 쓰지 않는다
- 내부에서 생략되는 내용을 이름에 드러낸다

## 2. 테스트 이름 상세 패턴

- 성공 기본 케이스: `xxx_Test()`
- 외부 조건 미충족: 이유가 분명하면 `NotApplicable_NoCall`보다 구체 이름을 선호
  - 예: `checkKCP_PaymentTypeMismatch_NoCall`
- 내부 하위 호출 미발생: `NoServiceCall`, `NoStockSideEffect`, `NoExtraLookup`
- 예외 삼킴: `insertHistory_InsertException_LogsErrorAndReturnsDto`
- 필요도 낮음 메모:
  `참고: 현재 운영코드 기준으로는 단순 조회/위임 성격이 강하지만, CallTree 기준 대상이므로 회귀 확인용으로 유지한다.`

피해야 할 이름:
- 실제 사유가 있는데도 무조건 `NotApplicable_NoCall`
- 운영코드에 없는 외부 조건을 helper에 추가한 이름
- 실제로는 메서드가 호출되는데 `NoCall`로 끝나는 이름

## 3. 로그 패턴

### 호출 직전
- production method 호출 직전에 반드시 `[➡️ CALL]`

```java
log.info("[DOMAIN_TEST][TARGET_METHOD][➡️ CALL] service.targetMethod(arg1={}, arg2={}) 호출 직전",
        arg1, arg2);
```

### 단계 로그
- 내부 로직이 있으면 단계 의미가 드러나는 로그를 남긴다
- 대표 태그: `[BASE_MAPPING]`, `[DTO_MAPPING]`, `[REQUEST_PARAM]`, `[SUM]`, `[NO_SERVICE_CALL]`, `[EXPECTED_ERROR_LOG]`

### negative 케이스
- helper 실행 후 미호출/내부 미호출 결과가 로그만으로도 드러나야 한다

## 4. helper / fixture 세부 패턴

### helper 규칙
1. helper는 실제 호출 구조를 재현하기 위한 최소 범위로만 만든다.
2. helper 안에 운영코드에 없는 외부 게이트를 새로 만들지 않는다.
3. negative 케이스도 가능하면 helper를 실제로 실행한다.
4. helper가 `null`, `emptyList`, `0` 등을 반환하는 경우 그 의미가 운영코드 분기와 맞아야 한다.

좋은 예:
- `executeLookupIfApplicable(req)`가 조건 미충족 시 `null`

나쁜 예:
- 운영 메서드는 항상 호출되는데 helper가 임의로 호출을 차단

### 시그니처 페어 규칙

MainTest가 `reqJson`을 넘겨 UnitTest 메서드를 호출하면 아래 페어를 필수로 유지한다.

```java
@Test
public void method_Test() throws Exception {
    method_Test(TestResourceLoader.loadOrderCreateBase());
}

public void method_Test(Map<String, Object> reqJson) throws Exception {
    // assert/verify
}
```

- `method_Test(Map<String, Object>)`만 있고 무파라미터 `@Test`가 없으면 미완성이다.
- 반대로 무파라미터 `@Test`만 있고 MainTest가 파라미터 호출하면 미완성이다.
- `_NoCall`, `_NoServiceCall`, `_Throws*` 케이스도 동일하게 페어를 맞춘다.

### 재탐색 정지 조건
아래가 확보되면 더 깊게 내려가지 않는다:
1. 대상 메서드 호출 여부를 검증할 수 있다.
2. 주요 파라미터 매핑을 assertion으로 표현할 수 있다.
3. 내부 skip/default/예외 branch를 테스트 이름과 검증으로 닫을 수 있다.
4. 최종 side effect 또는 후처리 결과가 확인된다.

## 5. 자주 틀리는 패턴

1. MainTest는 파라미터 호출인데 UnitTest 오버로드 페어가 없는 상태
2. `NotApplicable_NoCall` 남발
3. negative 케이스가 `applicable=false`만 보고 끝남
4. 예외 삼킴 테스트인데 error 로그가 의도된 것임이 이름/Javadoc/로그에 안 드러남
5. 같은 엔드포인트 흐름인데 fixture 없이 테스트마다 입력 구조를 흩어 씀
6. CallTree와 실제 코드가 충돌하는데 스킬이 독자적으로 대상을 제외하거나 추가

## 6. 최종 체크리스트

1. 외부 조건을 실제 호출자에서 찾았는가
2. 내부 조건을 대상 메서드 본문에서 찾았는가
3. negative 케이스가 helper 실행까지 포함하는가
4. 이름이 실제 사유를 드러내는가
5. `[➡️ CALL]` 로그가 production method 직전에 있는가
6. 내부 로직이 있으면 단계 로그가 있는가
7. 메인 테스트와 문서까지 동기화했는가
8. 필요도 낮음 판단이 있으면 테스트는 생성했고 메모도 남겼는가
9. 같은 흐름을 여러 테스트가 공유하면 fixture/helper가 정리됐는가
