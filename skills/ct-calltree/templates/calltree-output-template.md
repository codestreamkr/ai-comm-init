# {ClassName} 호출 흐름

## 문서 정보
- 대상 클래스: `{ClassName}`
- 소스: `{source-path}`
- 필터: `{filter-or-none}`
- 포함 메서드: `{method-list}`
- 작성 시각: `{timestamp}`
- 기준: 메서드 본문 기준으로 `[TC:✅]` 판정

## 흐름 요약
- `{entry-method-1}`
  `{summary}`

## 테스트 생성 계약
이 섹션은 `ct-calltree-test`가 읽는 전역 테스트 생성 메타데이터다.
사람이 읽을 때는 어디서 시작해서, 어느 단위로 묶고, 어떤 fixture 전략으로 테스트를 만들지 보면 된다.

- entryFlow: `{entry-flow}`
- completionUnit: `{call|bundle|flow}`
- mainTestClass: `{MainTestClass}`
- fixtureStrategy: `{none|shared-request|shared-helper}`
- notes:
  - `{turn-specific-note}`

## 테스트 관리 노드
| nodeId | callNode | layer | family | bundle | branchType | fixtureGroup | priority | mainTestGroup | notes |
|---|---|---|---|---|---|---|---|---|---|
| N01 | `{callNode}` | `{layer}` | `{family}` | `{bundle}` | `{branchType}` | `{fixtureGroup}` | `{priority}` | `{mainTestGroup}` | `{note}` |

## 메서드별 호출 트리

### 1. `{entry-method}`

```text
[TC:✅] {entry-method}()
├─ ...
```

## `[TC:✅]`로 본 메서드
- `{callNode}`
  `{why-target}`

## 비대상으로 둔 메서드
- `{callNode}`
  `{why-not-target}`

## 특이사항
- `{note}`
