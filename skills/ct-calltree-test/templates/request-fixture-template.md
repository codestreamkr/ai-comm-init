# Request Fixture Template

목적:

- 같은 엔드포인트/컨트롤러 흐름에서 여러 call이 같은 입력 구조를 공유할 때
  공통 request fixture와 helper 패턴을 고정한다.

적용 조건:

1. 여러 테스트가 같은 header/body/payment/meta 구조를 공유할 때
2. call-site 분기가 입력 JSON/Map에 의해 결정될 때
3. `applyTrigger`, `isApplicable`, `executeIfApplicable` helper가 유효할 때
4. benchmark commit이 fixture를 포함하거나, 현재 흐름이 benchmark 수준 작업일 때

fixtureStrategy 해석:

- `shared-request`
  - 공통 request fixture를 먼저 만들고, helper는 꼭 필요한 최소 범위만 둔다
- `shared-helper`
  - 공통 request fixture와 `applyXTrigger`, `executeXIfApplicable` helper를 같이 설계한다
  - helper는 운영코드 분기 재현용으로만 쓰고, 테스트 전용 게이트를 추가하지 않는다

기본 파일:

- `src/test/resources/{domain}/{entrypoint}/base-request.json`

기본 helper:

```java
private boolean isTargetApplicable(Map<String, Object> reqJson) { ... }

private void applyTargetTrigger(Map<String, Object> reqJson) { ... }

private ReturnType executeTargetIfApplicable(Map<String, Object> reqJson) { ... }

private void applySecondaryTrigger(Map<String, Object> reqJson) { ... }

private ReturnType executeSecondaryIfApplicable(Map<String, Object> reqJson) { ... }
```

고정 규칙:

1. fixture는 "최소하지만 실제 분기를 재현 가능한 입력"
2. fixture를 쓰더라도 production endpoint 자체는 호출하지 않음
3. helper는 운영코드 분기만 재현하고, 임의 분기를 추가하지 않음
4. 같은 흐름 테스트가 늘어나면 fixture/helper를 우선 재사용
5. benchmark 수준 작업이면 fixture 없이 테스트마다 입력을 새로 만드는 방식을 피한다.
6. fixture 하나로 2개 이상 call family를 재현할 수 있게 설계한다.
7. `shared-helper` 전략이면 helper 이름도 실제 call family가 드러나게 유지한다.

오버로드 페어 규칙:

```java
@Test
public void target_Test() throws Exception {
    target_Test(TestResourceLoader.loadOrderCreateBase());
}

public void target_Test(Map<String, Object> reqJson) throws Exception { ... }
```

1. MainTest가 `reqJson`을 넘겨 호출하는 경우 위 페어를 필수로 생성한다.
2. 무파라미터 `@Test`는 파라미터 메서드로 위임한다.
