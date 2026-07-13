# Main Test Template

이 템플릿은 legacy 적합성 게이트를 통과한 `testMode=legacy-main-test`에만 적용한다. 기존 MainTest가 있으면 같은 구조와 JUnit 버전을 유지하고, 없으면 대상 엔트리포인트 기준 MainTest를 신규 생성한다. 사용자가 `--standard-unit`을 명시했거나 적합성 확인 중이면 적용하지 않는다.

목적:

- CallTree 대상 메서드들을 순서대로 실행하는 `*MainTest.java` 기본 구조를 고정한다.
- 신규 생성에서는 이 템플릿만으로 MainTest를 구성할 수 있어야 한다.
- benchmark 입력이 있으면 현재 CallTree에 있는 의미 있는 묶음을 기준으로 MainTest를 구성한다.

기본 구조:

```java
/**
 * 현재 반영 범위: {family1}, {family2}, {family3}
 * 현재 CallTree에서 확인한 bundle과 family를 빠짐없이 반영한다.
 */
{test-order-annotation}
public class {MainTestClass} {

    private Map<String, Object> reqJson;

    {before-each-annotation}
    public void setUp() throws Exception {
        reqJson = TestResourceLoader.load{FixtureName}Base();
    }

    @Test
    public void test01_{shortCallName}() throws Exception {
        {UnitTestClass} ut = new {UnitTestClass}();
        ut.setUp();
        ut.{testMethod1}(reqJson);

        {UnitTestClass} ut2 = new {UnitTestClass}();
        ut2.setUp();
        ut2.{testMethod2}(reqJson);
    }

    @Test
    public void test02_{anotherCallFamily}() throws Exception {
        {UnitTestClass2} ut = new {UnitTestClass2}();
        ut.setUp();
        ut.{testMethod3}(reqJson);

        {UnitTestClass2} ut2 = new {UnitTestClass2}();
        ut2.setUp();
        ut2.{testMethod4}(reqJson);
    }
}
```

JUnit별 placeholder는 아래 값으로 치환한다.

| 구분 | JUnit 4 | JUnit 5 |
|---|---|---|
| `{test-order-annotation}` | `@FixMethodOrder(MethodSorters.NAME_ASCENDING)` | `@TestMethodOrder(MethodOrderer.MethodName.class)` |
| `{before-each-annotation}` | `@Before` | `@BeforeEach` |
| 테스트 annotation | `org.junit.Test` | `org.junit.jupiter.api.Test` |

프로젝트가 이미 사용하는 assertion과 import를 유지한다. JUnit 4와 JUnit 5 API를 한 클래스에서 혼용하지 않는다. UnitTest가 runner, extension, Spring context, Rule, parameter resolver 또는 컨테이너 lifecycle을 필요로 하면 이 템플릿으로 직접 생성하지 않고 파일 수정 전에 `--standard-unit` 선택을 확인한다.

`{MainTestClass}`에는 `references/test-strategy.md`에서 확정한 `mainTestClass` 값을 사용한다. lifecycle, UnitTest `setUp()` 또는 테스트 메서드가 checked exception을 선언해도 컴파일되도록 MainTest의 `setUp()`과 `testNN_*()`는 `throws Exception`을 유지한다.

고정 규칙:

1. 선택한 JUnit 버전의 메서드명 순서 annotation 사용
2. `test01_...`, `test02_...` 형태 사용
3. 번호는 작업 순서가 아니라 CallTree 순서 기준
4. 각 `testNN_*`에서 UnitTest 인스턴스를 만들고 `setUp()` 후 테스트 메서드를 직접 호출한다.
5. partial 상태면 클래스 Javadoc에 현재 반영 범위를 명시
6. benchmark commit은 묶음 구조를 참고하는 입력이며 현재 CallTree에 없는 `testNN_*`를 추가하는 근거로 사용하지 않는다.
7. 각 `testNN_*`는 call 하나만이 아니라 branch family 또는 call family 묶음을 대표하도록 잡는다.
8. MainTest가 `reqJson`을 넘겨 호출하는 UnitTest 메서드는 `xxx()` + `xxx(Map<String,Object>)` 오버로드 페어를 갖춰야 한다.
9. UnitTest는 직접 생성과 접근 가능한 `setUp()` 수동 호출만으로 필요한 상태를 완성할 수 있어야 한다.
10. request JSON/Map과 base request 근거가 없는 Service, batch, message 흐름에는 적용하지 않는다.

## 이력관리

- 2026-07-13: MainTest 기본 구조와 legacy 적합성 게이트, 확인 기반 standard-unit 전환, `{MainTestClass}` placeholder, 클래스 선언 앞 partial Javadoc, checked exception 전파, benchmark의 묶음 참고 범위, 직접 생성·수동 초기화 가능한 JUnit 4·5 테스트의 lifecycle 및 순서 annotation 기준을 정합화했다.
