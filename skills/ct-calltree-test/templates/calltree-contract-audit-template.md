# CallTree Contract Audit

이 문서에서 `mainTestClass`, `fixtureStrategy`, `mainTestGroup` 같은 값은
CallTree가 강제한 계약이 아니라, 이번 실행에서 테스트 스킬이 결정한 값이다.

## 입력 계약 확인
- callTree 문서: `{calltree-path}`
- entryFlow: `{entry-flow}`
- completionUnit: `{completion-unit}`
- mainTestClass: `{MainTestClass}`
- fixtureStrategy: `{fixture-strategy}`

## bundle 우선순위
| bundle | family | priority | mainTestGroup | status | notes |
|---|---|---|---|---|---|
| `{bundle}` | `{family}` | `{priority}` | `{mainTestGroup}` | `{pending|done}` | `{note}` |

## 산출물 계획
- UnitTest 대상 클래스:
  - `{class}`
- MainTest:
  - `{MainTestClass}`
- fixture:
  - `{fixture-path-or-none}`
- 보조 문서:
  - `{doc-path}`

## 적용한 원본 코드 조건
- [`{class}.java:{line}`]
  - `{external-condition-or-entry-guard}`
- [`{class}.java:{line}`]
  - `{internal-branch-or-post-processing}`

## 생성·갱신한 테스트 메서드
- `{UnitTestClass}#{testMethod}`
  - callNode: `{callNode}`
  - 의도: `{why-this-test-exists}`
- `{MainTestClass}#{testNN_method}`
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
- 현재 generation에서 닫은 family:
  - `{family-list}`
- 다음 generation 후보:
  - `{bundle-list}`
