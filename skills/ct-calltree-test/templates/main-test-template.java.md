# Main Test Template

목적:

- CallTree 대상 메서드들을 순서대로 실행하는 `*MainTest.java` 기본 구조를 고정한다.
- 저장소에 기존 메인 테스트가 없더라도 이 템플릿만으로 생성 가능해야 한다.
- benchmark 수준 작업에서는 call 1개용 메인 테스트가 아니라 "의미 있는 묶음"용 메인 테스트를 강제한다.

기본 구조:

```java
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
public class {FlowName}MethodMainTest {

    private Map<String, Object> reqJson;

    @Before
    public void setUp() {
        reqJson = TestResourceLoader.load{FixtureName}Base();
    }

    /**
     * 현재 반영 범위: {family1}, {family2}, {family3}
     * benchmark 수준 작업이면 최소 4개 이상의 testNN_* 묶음을 둔다.
     */

    @Test
    public void test01_{shortCallName}() {
        {UnitTestClass} ut = new {UnitTestClass}();
        ut.setUp();
        ut.{testMethod1}(reqJson);

        {UnitTestClass} ut2 = new {UnitTestClass}();
        ut2.setUp();
        ut2.{testMethod2}(reqJson);
    }

    @Test
    public void test02_{anotherCallFamily}() {
        {UnitTestClass2} ut = new {UnitTestClass2}();
        ut.setUp();
        ut.{testMethod3}(reqJson);

        {UnitTestClass2} ut2 = new {UnitTestClass2}();
        ut2.setUp();
        ut2.{testMethod4}(reqJson);
    }
}
```

고정 규칙:

1. `@FixMethodOrder(MethodSorters.NAME_ASCENDING)` 사용
2. `test01_...`, `test02_...` 형태 사용
3. 번호는 작업 순서가 아니라 CallTree 순서 기준
4. 각 `testNN_*`에서 UnitTest 인스턴스를 만들고 `setUp()` 후 테스트 메서드를 직접 호출한다.
5. partial 상태면 클래스 Javadoc에 현재 반영 범위를 명시
6. benchmark 수준 작업이면 최소 4개 이상의 `testNN_*`를 목표로 한다.
7. 각 `testNN_*`는 call 하나만이 아니라 branch family 또는 call family 묶음을 대표하도록 잡는다.
8. MainTest가 `reqJson`을 넘겨 호출하는 UnitTest 메서드는 `xxx()` + `xxx(Map<String,Object>)` 오버로드 페어를 갖춰야 한다.
