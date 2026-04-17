# Claude → Codex 매핑 규칙

## 기본 매핑

| Claude 쪽 | Codex 쪽 | 변환 원칙 |
|---|---|---|
| `.claude/agents/<name>.md` | `.codex/skills/<name>/SKILL.md` | 공통 페르소나와 작업 원칙을 메인 스킬로 옮긴다 |
| `.claude/skills/<topic>/SKILL.md` | `.codex/skills/<name>/references/<topic>.md` | 메인 스킬의 전문 참고 문서로 내린다 |
| Claude frontmatter `name` | Codex frontmatter `name` | 그대로 유지 가능 |
| Claude frontmatter `description` | Codex frontmatter `description` | "무엇을 하고 언제 쓰는지"가 보이게 다듬는다 |
| Claude frontmatter `tools` | 보통 제거 | 실제 MCP 의존성이 있을 때만 `agents/openai.yaml`의 `dependencies.tools`로 옮긴다 |
| Claude의 UI 성격 문구 | `agents/openai.yaml` | `display_name`, `short_description`, `default_prompt`로 재작성한다 |

## 이름 매칭 규칙

- 기본 전제는 사용자가 `클로드` 또는 `claude`를 직접 언급한 요청이다.
- 사용자가 스킬명을 정확히 주면 동일 이름의 Claude 에이전트와 스킬을 찾는다.
- 사용자가 일부 이름만 주면 파일명과 폴더명 기준으로 부분 일치 검색을 먼저 한다.
- 부분 일치 결과가 같은 주제군이면 함께 가져온다.
- 상위 에이전트와 하위 스킬 관계가 보이면 묶음으로 처리한다.

예시:
- `클로드 에이전트 spring 가져와` → `agents/spring.md` + `skills/spring-*`
- `spring` → `agents/spring.md` + `skills/spring-*`
- `security` → `skills/*security*`
- `query-tuner` → `agents/query-tuner.md` + `skills/query-tuner-*`

## 구조 선택 규칙

### 메인 스킬 1개로 묶는 경우

아래 조건이면 하나의 Codex 스킬로 묶는다.
- Claude 에이전트가 공통 페르소나를 갖고 있다
- 하위 스킬이 모두 그 에이전트의 전문 지식이다
- 사용자가 결국 한 이름으로 호출하길 원한다

예시:
- `spring.md` + `spring-jpa/SKILL.md` + `spring-security/SKILL.md`
- `query-tuner.md` + DB별 튜닝 스킬

### 별도 Codex 스킬로 나누는 경우

아래 조건이면 분리한다.
- 하위 스킬끼리 공통 페르소나가 거의 없다
- 단독 호출 가치가 크다
- 사용 맥락이 완전히 다르다

예시:
- 제품 기획 스킬과 쿼리 튜닝 스킬
- 프론트엔드 빌더와 문서 변환 스킬

## 문장 변환 규칙

- 원문 문장은 최대한 유지한다.
- 기존 Codex 문장과 섞어 머지하지 않는다.
- 최종 본문은 Claude 원문 기준으로 다시 세운다.
- 다만 Codex 구조를 설명하는 부분은 실제 파일 구조에 맞게 바꾼다.
- "스킬이 있다/없다"는 표현은 Codex에선 "참고 문서가 있다/없다"로 바꾸는 편이 자연스러울 수 있다.
- Claude 기준 경로는 Codex 기준 경로로 바꾼다.

## Codex에서 특히 바꿔야 하는 부분

### `SKILL.md` frontmatter

Codex는 아래 두 키만 쓰는 전제로 맞춘다.

```yaml
---
name: skill-name
description: 이 스킬이 무엇을 하고 언제 쓰는지
---
```

`tools`, `metadata` 같은 키가 Claude 문서에 있어도 메인 `SKILL.md`에는 그대로 두지 않는다.

### `references/` 활용

Codex는 메인 스킬이 너무 길어지면 효율이 떨어진다. 아래 내용은 `references/`로 내린다.
- 긴 규칙 표
- 버전별 차이
- 코드 예시 모음
- 진단 플로우
- 상세 안티패턴

### `agents/openai.yaml`

Codex는 UI 메타데이터를 별도 파일로 둔다. 그래서 Claude 쪽 설명문 일부는 `agents/openai.yaml`로 재배치해야 한다.

보통 이렇게 나눈다.
- 사용자가 보는 이름 → `display_name`
- 한 줄 요약 → `short_description`
- 호출 예시 한 문장 → `default_prompt`

## 변환 예시

### 예시 1. 단일 Claude 에이전트 + 하위 스킬

입력:
- `.claude/agents/spring.md`
- `.claude/skills/spring-jpa/SKILL.md`
- `.claude/skills/spring-security/SKILL.md`

출력:
- `.codex/skills/spring/SKILL.md`
- `.codex/skills/spring/references/spring-jpa.md`
- `.codex/skills/spring/references/spring-security.md`
- `.codex/skills/spring/agents/openai.yaml`

### 예시 2. Claude 에이전트 없이 독립 스킬만 존재

입력:
- `.claude/skills/docx/SKILL.md`

출력:
- `.codex/skills/docx/SKILL.md`
- `.codex/skills/docx/agents/openai.yaml`

필요하면 세부 가이드는 같은 스킬의 `references/`로 분리한다.

## 마지막 점검

- 기존 Codex 스킬과 이름이 충돌하지 않는가
- `default_prompt`가 실제 스킬명을 부르는가
- `short_description`이 너무 길거나 모호하지 않은가
- 원문의 어조를 잃지 않았는가
- 메인 스킬에 세부 문서가 과도하게 복붙되지 않았는가
- 기존 Codex 문서와 머지된 흔적 없이 Claude 원문 기반으로 정리됐는가
