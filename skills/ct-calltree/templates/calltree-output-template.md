# CallTree 출력 템플릿

아래 구조로 CallTree 문서를 작성한다.

```markdown
# {ClassName} 호출 흐름

## 문서 정보

- 대상 클래스: `{ClassName}`
- 소스: `{source-path}`
- 필터: `{filter-or-none}`
- 포함 메서드: `{method-list}`
- 작성 시각: `{timestamp}`
- contractVersion: `2`
- nextNodeSequence: `{next-node-sequence}`
- 기준: 메서드 본문 기준으로 `[TC:✅]` 판정

## 흐름 요약

- `{entry-method-1}`
  `{summary}`

## 메서드별 호출 트리

### 1. `{entry-method}`

    {tc-marker}{node-id-marker}{canonical-call-node}
    |-- ...

## [TC:✅] 노드 요약

이 표는 `ct-calltree-test`가 대상 노드와 처리 순서를 판단할 때 사용하는 입력 계약이다.

| nodeId | callPath | callNode | layer | family | bundle | branchType | priority |
|---|---|---|---|---|---|---|---|
| N01 | `{callPath}` | `{callNode}` | `{layer}` | `{family}` | `{bundle}` | `{branchType}` | `{priority}` |

## `[TC:✅]`로 본 메서드

- `[N01] {callNode}`
  - callPath: `{callPath}`
  - 근거: `{why-target}`

## 비대상으로 둔 메서드

- `{callNode}`
  `{why-not-target}`

## 특이사항

- `{note}`

## 이력관리

- YYYY-MM-DD: CallTree 작성 또는 갱신
```

`{tc-marker}`는 최종 테스트 대상이면 `[TC:✅] `, 비대상이면 빈 문자열로 치환한다. `{node-id-marker}`는 대상이면 `[N01] `처럼 같은 요약 행의 `nodeId`, 비대상이면 빈 문자열로 치환한다. 루트와 하위 호출에 같은 기준을 적용하며 비대상 표시에 `O`, `X`를 사용하지 않는다.

`family`와 `bundle`은 메서드명 대신 각각 호출의 업무 역할과 함께 검증할 업무 단위로 작성한다.

트리의 모든 메서드 노드와 요약의 `callNode`는 `com.example.Receiver.method(java.lang.String,int)` 형식의 canonical 완전 시그니처로 작성한다. receiver와 참조형은 패키지 포함 클래스명, primitive는 Java 키워드, generic은 erasure 타입, varargs는 배열, nested class는 canonical name의 `.` 표기를 사용한다. annotation, modifier, 파라미터명과 불필요한 공백은 제거하고 트리 본문과 노드 요약에 같은 값을 적는다.

`callPath`는 루트부터 대상까지 canonical `callNode`를 ` -> `로 연결한다. 동일한 `callNode`가 다른 경로에 나타나면 별도 행과 별도 `nodeId`를 부여하며, 트리의 `[TC:✅] [nodeId] callNode`와 요약의 `nodeId`, `callPath`, `callNode` 행을 일대일로 맞춘다.

기존 문서를 갱신할 때 같은 `callPath`와 `callNode`의 `nodeId`를 유지한다. 신규 노드는 `nextNodeSequence`를 사용한 뒤 값을 1 증가시키고, 노드를 삭제해도 이 값을 낮추지 않는다.

`nextNodeSequence`가 현재 노드의 최대 번호보다 작거나 같으면 최대 번호의 다음 값으로 올린다. 필드가 없는 기존 문서는 노드를 제거하기 전에 기존 문서의 모든 `nodeId`를 확인해 초기값을 정한다.

갱신 문서는 현재 소스 기준으로 필수 섹션 전체를 다시 작성한다. 기존 본문을 부분 수정하지 않으며 삭제되거나 분석 범위에서 빠진 메서드와 노드는 최종 트리와 노드 요약에서 제거한다.

## 서식 기준

- A4 세로 인쇄 기준으로 가로 폭을 정한다.
- 설명과 트리의 한 줄은 70~80자 안쪽으로 나눈다.
- 표는 노드 요약처럼 필드 비교가 필요한 경우에만 사용하고 열 수를 최소화한다.
- 호출 흐름과 계층은 표보다 ASCII 트리, 번호 목록, 짧은 목록을 우선한다.
- 문장은 짧고 자연스러운 한국어로 작성한다.

## 이력관리

- 2026-07-13: 루트 강제 TC 표기를 제거하고 계약 버전, repository 역할, canonical 완전 시그니처 `callNode`, 안정적인 `callPath`, 트리의 `nodeId` 표기, `nextNodeSequence` 기반 nodeId 안정성, 기존 문서 전체 재구성, A4 세로·줄 길이·표 최소화·ASCII 우선 서식 기준을 추가했다.
