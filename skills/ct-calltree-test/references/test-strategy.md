# CallTree 테스트 전략

이 문서는 테스트 모드, MainTest, fixture, 처리 목록과 검증 우선순위를 정한다.

## 구성

- 테스트 모드와 프레임워크
- MainTest와 fixture 결정
- 노드 처리 목록과 테스트 케이스 계약
- Controller 노드 매핑과 benchmark 입력
- 검증 우선순위와 필수 차단

## 테스트 모드

아래 모드 중 하나를 선택한다.

| 모드 | 선택 조건 | 기본 산출물 |
|---|---|---|
| `legacy-main-test` | `--standard-unit` 미지정이고 legacy 적합성 게이트 통과 | UnitTest, fixture, MainTest, 보조 문서, audit |
| `standard-unit` | 사용자가 `--standard-unit`을 명시 | UnitTest, 필요한 fixture, audit |

기본 후보는 `legacy-main-test`다. 파일 수정 전에 legacy 적합성 게이트를 먼저 적용하고, 부적합하면 사용자에게 근거를 보여준 뒤 `--standard-unit` 선택을 확인한다.

- legacy 적합성 게이트를 통과한 뒤 기존 MainTest가 있으면 같은 파일을 사용한다.
- 게이트 통과 뒤 MainTest 파일은 없지만 대응 보조 문서가 기존 MainTest 클래스와 흐름을 특정하면 기존 파일의 실제 위치를 추가 탐색한다.
- legacy 적합성 게이트를 통과한 뒤 기존 MainTest를 찾지 못하면 `mainTestClass`를 `{RootClassName}MainTest`로 정하고 `{MainTestClass}` placeholder에 그 값을 사용해 신규 생성한다.
- `standard-unit`에서는 기존 MainTest와 보조 문서를 삭제하거나 대체하지 않고 audit에 미변경 사실을 기록한다.
- CallTree의 `contractVersion`은 입력 해석에만 사용하고 테스트 모드는 사용자 옵션과 legacy 적합성 게이트로 별도 판정한다.
- 모드 우선순위는 `명시적 --standard-unit → 적합성 통과 legacy-main-test → 사용자 확인 후 standard-unit`이다.
- benchmark commit과 기존 MainTest 존재 여부는 선택된 모드를 바꾸지 않는다.

## Legacy 적합성 게이트

파일을 수정하기 전에 아래 조건을 모두 확인한다.

- 각 UnitTest를 직접 생성할 수 있다.
- 접근 가능한 `setUp()`을 수동 호출해 테스트 상태를 완성할 수 있다.
- 테스트 실행에 JUnit runner·extension, Spring context, Rule, parameter resolver 또는 컨테이너 lifecycle이 필요하지 않다.
- 대상 흐름이 request JSON/Map에서 시작하고 재사용할 수 있는 base request를 만들 실제 코드 근거가 있다.

아래 흐름은 request JSON/Map 근거가 별도로 확인되지 않으면 `legacy-incompatible`다.

- Service 직접 진입
- batch와 scheduler 진입
- MQ·message consumer 진입

`legacy-incompatible`이면 테스트 코드, fixture, MainTest와 Markdown 산출물을 수정하지 않는다. 부적합 조건을 한 번에 보고하고 `--standard-unit` 선택을 확인한다. 사용자가 선택하면 `standard-unit`으로 확정하고, 선택하지 않으면 작업을 중단한다.

## 테스트 프레임워크

| 확인 결과 | 적용 기준 |
|---|---|
| JUnit 5 | Jupiter annotation, extension, assertion, 순서 정책 |
| JUnit 4 | 기존 runner, `@Before`, `MethodSorters`, assertion |
| Mockito 사용 | 기존 extension·runner 또는 직접 mock 초기화 |
| Spring context 불필요 | 대상 객체 직접 생성과 mock 주입 |
| Spring context 필요 | 프로젝트 기존 Spring 테스트 계층 |

MainTest 템플릿도 선택한 JUnit 버전의 lifecycle과 순서 annotation을 사용한다. JUnit 4와 JUnit 5 API를 한 클래스에서 혼용하지 않는다. runner·extension·Spring context·Rule·parameter resolver가 필요한 UnitTest는 MainTest에서 직접 생성하지 않고 legacy 적합성 게이트에서 차단한다.

## MainTest 결정

### `mainTestClass`

`standard-unit`에서는 `none`으로 둔다. legacy 적합성 게이트를 통과한 `legacy-main-test`에서는 우선순위대로 선택한다.

1. 대상 엔트리포인트와 연결된 기존 `*MainTest.java`
2. 클래스 Javadoc, `testNN_*`, 호출 대상 일치율이 가장 높은 기존 파일
3. `{RootClassName}MainTest`를 값으로 갖는 `{MainTestClass}`

기존 파일명과 계산한 이름이 다르면 기존 파일을 갱신 대상으로 확정하고 차이를 보고한다.

### `mainTestGroup`

`standard-unit`에서는 `none`으로 둔다. `legacy-main-test`에서는 아래 기준을 적용한다.

| 조건 | 그룹 기준 |
|---|---|
| 같은 `bundle` | 같은 `testNN_*` 묶음 |
| bundle 안에 서로 다른 역할 존재 | `family`별 분리 |
| 신규 그룹 | 기존 마지막 번호 다음 번호 |

정렬 우선순위는 `bundle → family → CallTree 순서`다.

## Fixture 결정

### `fixtureStrategy`

| 값 | 허용 조건 |
|---|---|
| `shared-request` | `legacy-main-test`, 또는 `standard-unit`에서 기존 base request가 있거나 같은 JSON 골격을 2개 이상 노드가 공유 |
| `shared-helper` | `legacy-main-test`, 또는 `standard-unit`에서 공통 request와 실제 분기 재현 helper를 함께 사용 |
| `none` | `standard-unit`이고 프로젝트 기존 테스트가 노드별 입력 생성을 사용하는 경우 |

`legacy-main-test`는 request JSON/Map 근거가 확인된 흐름에서만 사용하고 모든 UnitTest 입력을 `base-request.json`에서 파생한다. `new VO() + setter` 방식으로 전체 입력을 직접 구성하지 않는다. 입력 구조가 다르면 fixtureGroup을 나누고 각 그룹의 base request를 둔다.

`standard-unit`의 우선순위는 `기존 fixture → 입력 구조 공유도 → helper 필요성 → 프로젝트 기존 입력 생성 관례`다.

### `fixtureGroup`

1. 기본값은 `bundle`과 같은 값으로 시작한다.
2. 같은 bundle에서 입력 구조가 다르면 별도 그룹을 사용한다.
3. 다른 bundle이 같은 request fixture를 공유하면 같은 그룹을 사용한다.

동일 입력 구조는 하나의 base request에서 필요한 값만 변경해 모든 노드 입력을 만들 수 있는 상태다.

## 노드 처리 목록

| 상태 | 판정 기준 | 처리 |
|---|---|---|
| `reuse` | 전용 테스트가 완료 게이트 충족 | 기존 테스트 참조 |
| `supplement` | 전용 테스트가 있으나 게이트 일부 미충족 | 기존 테스트 보강 |
| `new` | 전용 테스트 없음 | 신규 테스트 생성 |

- `supplement`, `new` 노드에 `M01`, `M02` 순번을 부여한다.
- 같은 UnitTest 파일의 노드는 연속 순번으로 배치한다.
- 목록 필드: `nodeId`, `callPath`, `callNode`, 대상 클래스, `testOwner`, `bundle`, `branchType`, `priority`, UnitTest, 상태, 처리 순번
- `priority=normal`이거나 구현상 필요도가 낮아 보여도 `[TC:✅]` 노드는 목록에서 제외하지 않는다. 테스트를 구현하고 낮은 필요도 판단 근거를 Javadoc 또는 audit에 남긴다.

## 테스트 케이스 계약

### `standard-unit`

실제 코드에서 확인한 경로를 허용한다.

- 정상 경로
- 호출자의 외부 조건으로 발생하는 미호출 경로
- 대상 메서드 내부의 skip·기본값·예외 경로
- 상태 변화와 부수효과 경로

### `legacy-main-test`

각 `[TC:✅]` 노드는 실제 코드에 존재하는 아래 경로를 모두 구성한다.

1. 정상 `{methodName}_Test`
2. 모든 외부 조건 미충족 경로의 `{reason}_NoCall`
3. 모든 내부 skip·기본값 경로
4. 모든 실제 예외 경로

MainTest가 `reqJson`을 전달하면 각 케이스에 아래 signature pair를 둔다.

```java
@Test
public void target_Test() throws Exception {
    target_Test(TestResourceLoader.loadBase());
}

public void target_Test(Map<String, Object> reqJson) throws Exception {
    // source-based assertions
}
```

## 산출물 경로

- UnitTest와 fixture: 프로젝트의 기존 테스트 소스·리소스 구조
- MainTest: 기존 파일을 갱신하거나 프로젝트 테스트 소스 구조에 신규 생성
- MainTest 보조 문서:
  - `.docs/call-trees/`, `.0_my/call-trees/`, 저장소 전체 순서로 같은 클래스·흐름의 기존 문서를 찾는다.
  - 기존 문서가 한 곳에 있으면 해당 경로를 갱신한다.
  - 두 경로에 모두 있으면 `.docs/call-trees/` 문서를 갱신하고 legacy 중복 경로를 audit에 기록한다.
  - 앞선 두 경로에는 없고 저장소 전체 탐색 구간에 하나만 있으면 해당 기존 경로를 갱신한다.
  - 저장소 전체 탐색 구간에 후보가 여러 개면 보조 문서를 수정하지 않고 후보 경로를 보고한다.
  - 신규 문서는 `.docs/call-trees/{MainTestClass}_YYYYMMDD_HHMMSS.md`
- audit:
  - 같은 이름의 기존 audit를 `.docs/call-trees/`, `.0_my/call-trees/`, 저장소 전체 순서로 찾고 처음 결과가 나온 탐색 구간의 단일 경로를 갱신한다.
  - 저장소 전체 탐색 구간에 후보가 여러 개면 audit을 수정하지 않고 후보 경로를 보고한다.
  - 기존 audit가 없으면 `.docs/call-trees/{CallTreeBaseName}-test-audit.md`에 작성한다.

신규 Markdown 산출물은 `.docs/call-trees/`에 작성한다. 명시 경로가 입력되면 그 파일을 먼저 사용하고, 동일 문서를 새 경로에 중복 생성하지 않는다.

## Controller 노드 매핑

| Controller 동작 | 테스트 위치 | 호출 방식 |
|---|---|---|
| Service 단순 위임 | ServiceUnitTest | Service public 메서드 직접 호출 |
| 호출 조건 분기 | ControllerUnitTest | 조건별 Service 호출 여부 검증 |
| 파라미터 변환·후처리 | ControllerUnitTest | 변환 결과와 반환 결과 검증 |
| private helper 고유 로직 | ControllerUnitTest | 필요 시 `ReflectionTestUtils.invokeMethod()` |
| 예외 보상 | ControllerUnitTest | 예외 재현 후 보상 호출 검증 |

## External 노드 매핑

`layer=external`은 외부 라이브러리나 벤더 메서드 자체를 단위 테스트하지 않는다.

- `testOwner`: 외부 경계를 직접 호출하는 저장소 내부 caller 또는 wrapper
- 테스트 위치: `testOwner`의 UnitTest
- 정상 검증: 외부 호출 여부, canonical 인자, 반환값 처리와 상태·후처리
- 예외 검증: 운영 코드에 존재하는 timeout, 오류 변환, 예외 삼킴, 보상과 재시도 경로
- audit: 원래 `nodeId`, `callPath`, `callNode`와 선택한 `testOwner`를 함께 기록

## Benchmark 입력

사용자가 `--benchmark <commit>` 또는 legacy 표현인 `git > <commit>`, `git <commit> 기준`, `<commit> 수준만큼`, `해당 커밋 수준만큼 <commit>`을 주면 legacy 표현을 `--benchmark`로 정규화한 뒤 아래를 적용한다. `해당 커밋 수준만큼`만 입력된 경우에는 같은 요청에서 commit이 하나로 확정될 때만 적용한다.

1. `git show --stat`, `git show --name-only`로 산출물을 확인한다.
2. 선택된 테스트 모드가 허용하는 산출물만 참고한다. `standard-unit`에서는 commit의 MainTest와 보조 문서를 생성 대상으로 가져오지 않는다.
3. commit의 `bundle`, `family`와 파일 구성을 참고하되 현재 CallTree에 없는 대상과 테스트 케이스를 추가하지 않는다.
4. commit의 테스트 프레임워크와 현재 프로젝트가 다르면 현재 프로젝트 방식을 우선하고 차이를 기록한다.

## 검증 우선순위

1. 대상 테스트 컴파일
2. 변경한 테스트 클래스 실행
3. 요청된 관련 회귀 범위 실행

환경별 허용 우회:

| 문제 | 우회 |
|---|---|
| PowerShell Maven 인자 처리 | `mvn.cmd` |
| 인코딩 실패 | 프로젝트가 허용한 UTF-8 옵션 |
| 테스트 실행 환경 부재 | `test-compile` 또는 동등한 테스트 컴파일 |

기존 파일을 수정한 작업에서는 read-only git 상태 확인으로 staging 포함 여부와 누락을 보고한다.

## 필수 차단

- 실제 코드 근거가 없는 조건, stub, assertion 생성
- 운영 코드에 없는 테스트 전용 게이트 생성
- 기존 테스트의 임의 삭제·대체 또는 같은 테스트의 다중 파일 중복
- 사용자 확인 없는 CallTree 대상 추가·제외
- 민감정보와 전체 요청 객체 로그 출력

## 이력관리

- 2026-07-13: MainTest 기본 산출물과 `{MainTestClass}` placeholder, 직접 생성·수동 초기화 및 request JSON/Map 기반 legacy 적합성 게이트, 확인 기반 `standard-unit` 전환, 모드별 fixture 허용값, 모든 실제 negative·예외 경로, external caller·wrapper 테스트 매핑, canonical callPath 처리 목록, legacy benchmark 적용 범위, JUnit 4·5 선택 기준, 낮은 필요도 TC, 기존 테스트 대체와 사용자 확인 없는 대상 변경 차단, `.docs`·`.0_my`·제3 탐색 경로의 기존 문서 갱신 계약을 보강했다.
