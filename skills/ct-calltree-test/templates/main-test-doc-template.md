# Main Test Doc Template

목적:

- `*MainTest.java`를 새 세션에서도 즉시 이해할 수 있게 설명 문서를 고정 포맷으로 만든다.

기본 섹션:

1. 문서 정보
2. 개요
3. 공통 실행 흐름
4. 흐름 트리
5. 단계별 해석

기본 골격:

```md
# {MainTestClass} 흐름 정리

## 문서 정보
- 대상 테스트:
  `{relative-path-to-main-test}`
- 관련 운영 코드:
  `{relative-path-to-controller-or-service}`
- 관련 엔드포인트:
  `{entrypoint-or-flow}`
- 작성 시각:
  `{timestamp}`

## 개요
이 클래스는 `{entryMethod}` 컨트롤러를 통째로 호출하는 통합 테스트가 아니라,
{흐름} 오케스트레이션에서 핵심 호출 노드를 번호 순서로 묶어 실행하는
메인 테스트 오케스트레이터다.

- `@FixMethodOrder(MethodSorters.NAME_ASCENDING)`으로
  `test01`부터 `testNN`까지 순차 실행한다.
- 각 `testNN_*` 메서드는 대응 UnitTest를 직접 생성하고
  `setUp()` 후 `_Test(reqJson)`/negative 케이스를 순서대로 호출한다.
- MainTest가 호출하는 UnitTest 메서드는 `xxx(Map<String,Object>)`와 무파라미터 `@Test` 페어를 함께 유지한다.

## 공통 실행 흐름
```text
{MainTestClass}
└─ testNN_*()
   ├─ reqJson fixture 준비(@Before)
   ├─ UnitTest 인스턴스 생성
   ├─ setUp() 호출
   ├─ _Test(reqJson) 호출
   └─ negative 케이스(reqJson) 호출
```

## 흐름 트리
```text
{MainTestClass}
├─ 1. {그룹명}
│  ├─ test01_{methodName} -> {service}.{method}()
│  │  ├─ {UnitTestClass}#{methodName}_Test
│  │  │  └─ {정상 케이스 검증 의도}
│  │  └─ {UnitTestClass}#{methodName}_{사유}_{Throws*|NoCall}
│  │     └─ {예외/미호출 케이스 검증 의도}
│  └─ test02_{methodName} -> {service}.{method}()
│     ├─ ...
│     └─ ...
├─ 2. {그룹명}
│  └─ ...
└─ N. {그룹명}
   └─ ...
```

## 단계별 해석
### 1. MainTest 역할
### 2. 유지된 커버리지
### 3. 별도 점검 필요 항목
### 4. 권장 보강 시나리오
```

고정 규칙:

1. 메인 테스트 현재 반영 범위가 partial이면 그 사실을 문서에도 표시
2. 각 `testNN_*`는 `callNode -> 하위 테스트 메서드 -> 검증 의도`까지 적는다
3. 메인 테스트 번호 순서는 CallTree 순서를 따른다
4. CallTree의 `bundle`, `priority`와 테스트 스킬이 결정한 `mainTestGroup` 기준을 문서에도 드러낸다
5. 흐름 트리에서 각 testNN 하위에 UnitTest 메서드명과 검증 의도를 한 줄씩 기재한다
6. 단계별 해석의 "유지된 커버리지"는 흐름 트리의 그룹 단위로 커버 범위를 요약한다
7. "별도 점검 필요 항목"은 현재 MainTest가 커버하지 못하는 영역을 명시한다
8. "권장 보강 시나리오"는 추가 테스트로 고정 회귀에 포함할 만한 구체적 조건을 나열한다
