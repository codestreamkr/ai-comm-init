# CallTree Contract Audit 템플릿

## 구성

- 입력 계약과 legacy fallback
- 노드 처리와 산출물 계획
- 코드 근거, assertion과 검증 결과

```markdown
# CallTree Contract Audit

이 문서에서 `testMode`, `mainTestClass`, `fixtureStrategy`, `mainTestGroup` 같은 값은 CallTree가 강제한 계약이 아니라, 이번 실행에서 테스트 스킬이 결정한 값이다.

## 입력 계약 확인

- callTree 문서: `{calltree-path}`
- contractVersion: `{2|legacy-unversioned}`
- contractMode: `{current|legacy-fallback}`
- testMode: `{standard-unit|legacy-main-test}`
- legacyCompatibility: `{compatible|incompatible-confirmed-standard-unit|not-applicable-explicit-standard-unit}`
- legacyCompatibility 근거: `{direct-construction-and-manual-setup|incompatibility-reason|explicit-standard-unit-reason}`
- mainTestClass: `{MainTestClass-or-none}`
- fixtureStrategy: `{fixture-strategy}`
- fixtureGroup: `{fixture-group-list-or-none}`
- mainTestGroup: `{main-test-group-list-or-none}`
- JUnit: `{4|5}`
- mocking: `{mocking-style}`
- contractValidation: `{passed|legacy-fallback}`
- rowValidation: `{nodeId-callPath-callNode-count-passed|legacy-fallback}`
- nextNodeSequence: `{positive-integer|legacy-none}`

## Legacy fallback

- 적용 여부: `{yes|no}`
- 대상 추출 기준: `{node-summary|legacy-node-summary|tree-tc-marker}`
- nodeId 기준: `{source-node-id|legacy-temporary-id}`
- 보완한 필드: `{field-list-or-none}`
- 범위 한계 또는 충돌: `{note-or-none}`

## 노드 처리 결과

| nodeId | callPath | callNode | layer | testOwner | bundle | family | branchType | priority | fixtureGroup | mainTestGroup | initialStatus | result |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `{nodeId}` | `{callPath}` | `{callNode}` | `{layer}` | `{testOwner}` | `{bundle}` | `{family}` | `{branchType}` | `{priority}` | `{fixtureGroup}` | `{mainTestGroup-or-none}` | `{reuse|supplement|new}` | `{done|pending}` |

`testOwner`는 `layer=external`이면 경계를 직접 소유한 저장소 내부 caller 또는 wrapper, 그 외에는 대상 운영 메서드를 소유한 클래스다.

## 산출물 계획

- UnitTest 대상 클래스:
  - `{class}`
- MainTest:
  - `{MainTestClass-or-none}`
- fixture:
  - `{fixture-path-or-none}`
- 보조 문서:
  - `{doc-path-or-none}`
- audit:
  - `{audit-path}`

## 적용한 원본 코드 조건
- [`{class}.java:{line}`]
  - `{external-condition-or-entry-guard}`
- [`{class}.java:{line}`]
  - `{internal-branch-or-post-processing}`

## 생성·갱신한 테스트 메서드

- `{UnitTestClass}#{testMethod}`
  - callPath: `{callPath}`
  - callNode: `{callNode}`
  - testOwner: `{testOwner}`
  - 의도: `{why-this-test-exists}`
- `{MainTestClass-or-none}#{testNN_method-or-none}`
  - callNode 또는 family: `{grouped-call-or-family}`

## assertion 근거 매핑
| testMethod | assertion 요약 | 근거 코드 |
|---|---|---|
| `{testMethod}` | `{assertion-summary}` | `{class}.java:{line}` |

## 검증 결과
- test-compile 또는 실행 명령:
  - `{command}`
- 결과:
  - `{passed|failed|skipped}`
- 메모:
  - `{compile-or-run-note}`

## 필요도 낮음 판단 메모
- 노드:
  - `{callNode-or-none}`
- 반영 위치:
  - `{javadoc-or-doc-path-or-none}`
- 메모:
  - `{note}`

## audit 메모

- 비어 있는 critical bundle:
  - `{bundle}`
- 이번 작업에서 닫은 family:
  - `{family-list}`
- CallTree와 실제 코드 충돌:
  - `{conflict-or-none}`

## 이력관리

- YYYY-MM-DD: CallTree 테스트 audit 작성 또는 갱신
```
## 이력관리

- 2026-07-13: 상단 구성과 계약 버전, `nodeId + callPath + callNode` 행·중복 검증 결과, `nextNodeSequence`, fallback nodeId 기준, layer·branchType·external testOwner, legacy 적합성, 테스트 전략과 산출물 경로 필드를 반영했다.
