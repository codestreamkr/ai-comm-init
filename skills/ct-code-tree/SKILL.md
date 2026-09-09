---
name: ct-code-tree
description: 사용자가 `$ct-code-tree`를 명시적으로 호출하면 프로젝트 코드의 호출 흐름을 분석하고 전환 계획 문서 또는 테스트를 만든다. 지원 작업은 `analyze`, `transition`, `test`다.
---

# CT Code Tree

정본은 실제 코드의 호출과 데이터 흐름이다. `test`는 이 스킬이 정한 호출 흐름 문서를 소비한다.

## 호출

- `$ct-code-tree` 또는 `$ct-code-tree ?`: 안내. 실행하지 않는다.
- `$ct-code-tree <작업> ?`: 해당 작업 안내.
- `$ct-code-tree <작업> <대상>`: 실행.

첫 토큰이 `analyze`, `transition`, `test`가 아니면 안내만 한다. `--`로 시작하면 지원하지 않는 옵션이다. 작업만 있고 대상이 없으면 실행하지 않는다.

## 작업

- `analyze`: 진입점부터 의미 있는 호출과 데이터 흐름을 읽기 전용으로 추적한다. 기본 산출은 대화다. 문서 요청이 있을 때만 호출 흐름 문서를 만든다.
  - 예: `$ct-code-tree analyze OrderController.cancel`
- `transition`: 현재 구조와 목표 구조를 비교한 전환 계획 문서. 운영 코드는 수정하지 않는다. 기능 구현 계획은 `ct-plan-work impl`이다.
  - 예: `$ct-code-tree transition OrderService.cancel`
- `test`: 호출 흐름 문서와 운영 코드를 근거로 테스트를 만들거나 고치고 검증한다. 별도 요청이 없으면 운영 코드는 수정하지 않는다. 사용자 흐름 QA는 `ct-qa-flow`다.
  - 예: `$ct-code-tree test .docs/callTree-StMainViewController-storeMainBene.md`

선택한 작업의 기본 산출만 만든다. 도움말과 대상 없는 호출은 파일을 건드리지 않는다.

## 역할 규칙

- 확인되지 않은 버전, 패키지, 경로, 정책은 가정하지 않고 확인 필요로 분리한다.
- 프로젝트에서 확인되지 않는 호출을 트리에 넣지 않는다.
- 호출 흐름 문서는 아래 산출 규격을 따른다. 사용자 지정이 있으면 그것을 우선한다.

## 산출 규격

파일명은 `callTree-<진입점>-<대상>.md`다.

- `<진입점>`: 흐름을 시작하는 클래스, 화면 또는 주요 컴포넌트.
- `<대상>`: 분석·전환의 중심 메서드, 기능 또는 심볼. 괄호와 매개변수는 뺀다.
- 코드에서 확인한 대소문자를 유지한다. 파일명에 쓸 수 없는 문자는 `-`로 치환한다.
- 경로 지정이 없으면 프로젝트의 기존 호출 흐름 문서 디렉터리, 없으면 `.docs`.
- 같은 이름이 있고 같은 흐름이면 갱신한다. 다른 문서면 덮어쓰지 않는다.

예: `callTree-StMainViewController-storeMainBene.md`

문서는 아래 섹션 순서다. 해당 없는 섹션은 사유를 한 줄로 적고 남긴다.

| 섹션 | 내용 |
|---|---|
| `## 문서 정보` | 대상 클래스, 소스 경로, 필터, 포함 메서드, 작성 시각, 판정 기준, 포함·제외 범위 |
| `## 뷰 해석 경로` | view 이름이 실제 JSP로 해석되는 tiles 경로 |
| `## 흐름 요약` | 진입 메서드가 하는 일과 분기 |
| `## 메서드별 호출 트리` | `### 1. <메서드>` / `### 2. 뷰 렌더링` / `### 3. 화면 이후 서버 호출` |
| `## [TC:✅] 노드 요약` | 아래 노드 표 |
| ``## `[TC:✅]`로 본 메서드`` | 노드별 판정 근거 |
| `## 비대상으로 둔 메서드` | 제외 사유 |
| `## 특이사항` | 추적 중 확인한 사실 |
| `## 검증` | 수행한 검증과 하지 않은 검증 |
| `## 확인이 필요한 항목` | 미확인. 없으면 "없음" |

`문서 정보`의 필터는 메서드명이다. URL 매핑은 `매핑` 항목이다.

호출 트리는 ```` ```text ```` 안에 그린다.

- 글리프는 `├─`, `└─`, `│`. ASCII `|--`, `` `-- ``는 쓰지 않는다.
- 한 단계는 3칸: `├─ `, `└─ `, `│  `, `   `.
- 한 노드는 한 줄. `Class.method()`. 패키지와 매개변수는 뺀다.
- 판정 대상 앞에 `[TC:✅]`와 `[Nxx]`.
- 부가 설명은 같은 줄 뒤 두 칸과 괄호. 105자를 넘으면 트리 밖 산문.
- 리시버는 클래스명. `service.selectX()`가 아니라 `PopupMngServiceImpl.selectX()`.
- 메서드가 아닌 판정 단위는 한글 설명과 `[Nxx]`. 노드 표와 같은 문자열.

`[TC:✅]`는 메서드 본문 기준이다. 분기, 조립, 계산, 외부 연동, 예외 처리가 있으면 대상이다. DAO 단순 조회, 단순 위임, getter/setter, 모델 세팅만 있으면 비대상이다.

노드 표는 7컬럼이다.

```text
| nodeId | callNode | layer | family | bundle | branchType | priority |
```

- `nodeId`: `N01`부터 트리 등장 순. 같은 메서드가 여러 경로면 경로마다 한 행.
- `callNode`: 트리와 같은 `Class.method()`
- `layer`: `controller` / `service` / `helper` / `external` / `utility`
- `family`, `bundle`: 문서 안에서 일관되면 자유 문자열
- `branchType`: `always` / `applicable/skip` / `conditional` / `normal/exception` / `normal/skip` / `normal/early-return`
- `priority`: `critical` / `high` / `normal`

이 규격에 없는 필드나 계약을 만들지 않는다. 소비 도구가 실재할 때만 추가하고 그 도구 이름과 경로를 적는다.
