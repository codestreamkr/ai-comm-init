# CallTree 테스트 패턴

이 문서는 테스트 이름, 분기, fixture와 검증 패턴을 정한다. 실행 순서와 완료 조건은 `SKILL.md`를 따른다.

## 조건 분류

### 외부 조건

호출자 분기가 대상 메서드 호출 자체를 막는 조건이다.

- 허용 이름: 대상 메서드가 실행되지 않은 경우의 `..._NoCall`
- 근거 위치: 대상 메서드를 호출하는 Controller, Service 또는 helper

### 내부 조건

대상 메서드에 진입한 뒤 하위 호출이나 부수효과를 생략하는 조건이다.

- 허용 이름: `NoServiceCall`, `Skip`, `NoSideEffect`
- 근거 위치: 대상 메서드 본문

## 테스트 이름

기존 프로젝트 명명 규칙을 우선한다. 별도 규칙이 없으면 아래 형식을 사용한다.

| 유형 | 형식 |
|---|---|
| 정상 | `{methodName}_Test` |
| 외부 조건 미충족 | `{methodName}_{reason}_NoCall` |
| 내부 호출 생략 | `{methodName}_{reason}_NoServiceCall` |
| 예외 결과 | `{methodName}_{exception}_{result}` |

실제 조건을 확인할 수 있으면 `NotApplicable` 같은 포괄 이름보다 구체적인 사유를 사용한다.

## 테스트 범위

각 노드는 아래 허용 경로 중 실제 코드에서 확인한 경로를 모두 검증한다.

- 정상 경로
- 호출자가 실제로 가진 미호출 경로
- 대상 메서드가 실제로 가진 내부 skip 또는 예외 경로
- 변경되는 상태, 전달값 또는 부수효과

`legacy-main-test` 모드의 정상·negative·예외 전체 경로 계약은 `references/test-strategy.md`를 따른다.

## Mock과 assertion

- 프로젝트의 기존 mocking 프레임워크와 초기화 방식을 따른다.
- 단순 위임은 호출 여부와 핵심 인자를 검증한다.
- mapping과 조립은 captor 또는 동등한 방식으로 전달값을 검증한다.
- 예외 삼킴은 테스트 이름, Javadoc 또는 로그에 의도된 처리임을 표시하고 반환값, 후속 호출, 상태 변화 또는 로그 중 관찰 가능한 결과를 검증한다.
- Controller 고유 private helper는 public 경계로 결과를 관찰할 수 없는 경우 `ReflectionTestUtils.invokeMethod()`로 검증할 수 있다.
- Controller 고유 로직은 해당 분기나 helper를 직접 검증하며 전체 엔드포인트 호출로 우회하지 않는다.
- `layer=external`은 외부 메서드 자체가 아니라 경계를 직접 소유한 저장소 내부 caller 또는 wrapper에서 호출 인자, 반환 처리와 실제 예외 경로를 검증한다.

## 로그

- `standard-unit`: 기존 프로젝트 테스트 로그 형식을 적용한다.
- `legacy-main-test`: 모든 `@Test`에 `[TAG][STEP]` 형식과 운영 메서드 호출 직전 `[➡️ CALL]` 로그를 적용한다.
- `legacy-main-test`: 분기 결과, 하위 호출 생략과 의도된 예외 처리 결과를 `[BRANCH]`, `[NO_SERVICE_CALL]`, `[EXPECTED_ERROR_LOG]`처럼 의미가 드러나는 단계 로그로 남긴다.
- 로그 필드는 프로젝트의 허용 목록과 마스킹 기준에서 선택한다.

## Fixture

테스트 모드에서 허용한 fixture 전략을 사용한다.

- 기본 위치: `src/test/resources/{domain}/{entrypoint}/base-request.json`
- `legacy-main-test`: legacy 적합성 게이트를 통과한 request JSON/Map 흐름의 모든 UnitTest 입력을 base request에서 파생한다.
- `standard-unit`: 같은 요청 골격을 여러 노드가 공유하거나 프로젝트 기존 테스트가 fixture를 사용할 때 공통 fixture를 사용한다.
- 테스트별 차이는 공통 fixture에서 필요한 값만 변경한다.
- helper는 실제 운영 분기를 재현하는 입력 변환과 호출 실행만 담당한다.

### Helper 검증

- negative 케이스도 `isApplicable=false` 확인만으로 끝내지 않고 `executeXIfApplicable` 같은 허용 helper를 실제 실행한다.
- helper가 `null`, 빈 컬렉션, `0` 같은 기본값을 반환하면 그 값이 운영 코드의 미호출·생략·기본값 의미와 일치하는지 assertion으로 확인한다.
- 외부 미호출은 대상 메서드가 호출되지 않았음을 검증하고, 내부 skip은 대상 메서드 진입 후 하위 호출·부수효과가 생략됐음을 구분해 검증한다.
- 기본값 assertion만으로 끝내지 않고 금지된 하위 호출이나 상태 변경이 없었는지도 실제 코드 계약에 따라 확인한다.
- 운영 메서드가 항상 호출되는 흐름에 helper가 임의의 호출 차단 조건을 추가하지 않는다.
- helper의 이름은 실제 call family와 실행 책임이 드러나게 작성한다.

### 예외 삼킴 검증

- 실제 catch 대상이 되는 의존성 예외를 mock에서 발생시킨다.
- 운영 코드가 예외를 삼키는 계약일 때만 호출이 예외를 전파하지 않는다고 검증한다.
- 반환 기본값, 입력·기존 상태 유지, 후속 호출, 보상 호출, 저장 생략 중 실제 코드에 있는 관찰 가능한 결과를 하나 이상 assertion으로 닫는다.
- 로그를 계약으로 검증할 수 있는 프로젝트에서는 의도된 error 로그를 확인한다. 로그 캡처 기반이 없으면 로그 확인만으로 테스트를 완료하지 않는다.
- catch 이후 금지되는 하위 호출이나 부수효과가 있으면 미발생을 함께 검증한다.

## 추적 완료 조건

아래가 모두 확인되면 노드의 소스 추적을 완료한다.

1. 대상 메서드 호출 여부를 검증할 수 있다.
2. 주요 전달값을 assertion으로 표현할 수 있다.
3. 실제 skip·예외 분기를 검증할 수 있다.
4. 최종 상태 변화 또는 부수효과를 확인할 수 있다.

## 이력관리

- 2026-07-13: 모드별 fixture 허용 기준, legacy 적합성 게이트, 실제 존재하는 모든 negative·예외 경로, negative helper 실행과 미호출·생략 반환 의미, legacy 분기·생략·예외 결과의 단계 로그, 예외 삼킴의 비전파·관찰 결과, Controller 직접 검증과 external caller·wrapper 검증 기준을 복원했다.
