---
name: claude-to-codex
description: "사용자가 `클로드` 또는 `claude`를 직접 언급하며 Claude의 `agents/*.md`나 `skills/*/SKILL.md`를 가져오라고 할 때 사용한다. 스킬명 전체나 일부만 주어져도 관련 Claude 파일을 찾아 원문 그대로 가져오고, Codex 형식으로 변환한다."
---

# Claude To Codex

## 개요

Claude용 에이전트와 스킬 문서를 읽고, Codex에서 바로 쓸 수 있는 스킬 폴더로 재구성한다. 원문은 최대한 유지하되, Codex가 실제로 읽는 구조와 메타데이터만 맞게 바꾼다.

이 스킬은 특히 아래 작업에 맞다.
- 요청에 `클로드` 또는 `claude`가 직접 들어 있을 때
- `.claude/agents/*.md`를 `.codex/skills/<skill>/SKILL.md`로 옮길 때
- `.claude/skills/*/SKILL.md`를 Codex의 `references/*.md` 또는 별도 스킬로 나눌 때
- 스킬명 전체 또는 일부만 말해도 관련 Claude 파일을 추적해서 가져와야 할 때
- `agents/openai.yaml`까지 포함해 UI 메타데이터를 완성할 때
- 원문 내용은 유지하면서 Claude 전용 규칙만 걷어내고 싶을 때

## 트리거 기준

아래처럼 `클로드` 또는 `claude`를 직접 넣은 요청을 우선으로 본다.

- `클로드 에이전트 spring 가져와`
- `claude spring-security 가져와`
- `클로드 스킬 query-tuner 가져와`

반대로 `spring 가져와`, `security 가져와`처럼 Claude를 직접 말하지 않은 요청은 이 스킬의 기본 트리거로 보지 않는다. 그런 경우에는 문맥이 충분히 명확할 때만 보조적으로 해석한다.

## 이름으로 찾기

사용자가 스킬명을 정확히 다 주지 않아도 관련 파일을 먼저 찾는다.

- 전체 이름이 오면 그 이름과 정확히 일치하는 Claude 에이전트, 스킬을 찾는다.
- 일부 이름이 오면 `.claude/agents/*.md`, `.claude/skills/*/SKILL.md`에서 부분 일치 후보를 모두 찾는다.
- 찾은 후보 중 같은 주제를 공유하는 파일은 함께 가져온다.
- 예를 들어 `spring`만 말해도 `spring.md`, `spring-jpa/SKILL.md`, `spring-security/SKILL.md`를 같이 본다.
- 예를 들어 `security`만 말해도 `spring-security/SKILL.md`처럼 관련 주제 문서를 우선 찾는다.

후보가 여러 개면 가능한 한 모두 확인하되, 최종 반영은 사용자가 말한 맥락과 가장 가까운 묶음을 우선한다.

## 빠른 판단

먼저 소스가 어떤 형태인지 구분한다.

- **에이전트 1개 + 하위 스킬 여러 개**
  보통 Codex에선 **메인 스킬 1개 + `references/*.md`** 구조가 가장 안정적이다.
- **독립적인 Claude 스킬 1개**
  Codex에서도 **독립 스킬 1개**로 옮긴다.
- **에이전트 없이 스킬 문서만 여러 개**
  공통 페르소나가 없으면 각각 별도 Codex 스킬로 나눈다.
- **Claude 문서가 서로 강하게 의존**
  메인 스킬에 작업 원칙을 두고, 세부 전문 지식은 `references/`로 분리한다.

판단 기준이 애매하면 [references/claude-codex-mapping.md](C:/Users/P257212/.codex/skills/claude-to-codex/references/claude-codex-mapping.md)를 먼저 읽는다.

## 작업 순서

### 1. 소스 파일을 먼저 읽기

다음 파일을 우선 읽는다.

- `.claude/agents/*.md`
- `.claude/skills/*/SKILL.md`
- 이미 존재하는 `.codex/skills/<target>/` 폴더

이 단계에서 아래를 정리한다.
- 공통 페르소나가 어디에 있는지
- 전문 지식이 어떤 스킬 파일에 흩어져 있는지
- 사용자 입력이 전체 이름인지 일부 이름인지
- 부분 이름으로 찾은 관련 파일을 어디까지 함께 가져올지

### 2. 목표 구조를 먼저 정하기

구조를 먼저 정하고 나서 문장을 옮긴다.

기본 구조는 아래를 우선한다.

```text
.codex/skills/<skill-name>/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
    ├── <topic-1>.md
    └── <topic-2>.md
```

판단 기준:
- 공통 톤, 역할, 작업 원칙은 `SKILL.md`
- 세부 구현 패턴, 긴 예시, 도메인별 규칙은 `references/*.md`
- UI 표시용 메타데이터는 `agents/openai.yaml`

### 3. 내용 옮기기

원칙은 단순하다.

- 원문을 최대한 그대로 가져온다.
- 기존 Codex 문서와 섞어서 머지하지 않는다.
- Claude 원문을 기준 본문으로 두고, Codex에 안 맞는 구조만 변환한다.
- Codex 규칙에 맞지 않는 부분만 최소 수정한다.
- Claude 문서 안의 "하위 스킬" 표현은 Codex에선 `references/*.md` 또는 별도 스킬로 바꾼다.
- 번역투나 과한 문장은 다듬되, 원래 의도와 페르소나는 유지한다.

특히 아래를 먼저 본다.
- frontmatter에 `name`, `description` 외 다른 키가 있는지
- `tools:` 같은 Claude 전용 항목이 들어 있는지
- "현재 스킬", "준비 중인 스킬"처럼 Codex 구조와 안 맞는 설명이 있는지
- 파일 경로가 Claude 기준으로 박혀 있는지

### 4. `agents/openai.yaml` 작성하기

`agents/openai.yaml`은 사용자 UI와 암시적 호출에 직접 영향을 준다. 짧고 분명하게 쓴다.

필수 항목:
- `interface.display_name`
- `interface.short_description`
- `interface.default_prompt`
- `policy.allow_implicit_invocation`

기본 규칙:
- 모든 문자열은 큰따옴표로 감싼다.
- `default_prompt`는 반드시 `$skill-name`을 직접 언급한다.
- 아이콘, 브랜드 컬러는 실제 자산이 있거나 사용자가 요청한 경우만 넣는다.
- MCP 의존성이 실제로 필요할 때만 `dependencies.tools`를 추가한다.

세부 규칙은 [references/openai-yaml-guide.md](C:/Users/P257212/.codex/skills/claude-to-codex/references/openai-yaml-guide.md)를 따른다.

### 5. 점검하고 마무리하기

마지막에는 아래를 확인한다.

1. `SKILL.md` frontmatter가 `name`, `description`만 가지는가
2. `description`이 "무엇을 하고 언제 쓰는지"를 바로 설명하는가
3. `agents/openai.yaml`의 `default_prompt`가 `$claude-to-codex`처럼 스킬명을 직접 부르는가
4. 긴 전문 지식이 메인 문서에 과하게 들어가 있지 않은가
5. 기존 Codex 파일을 참고하더라도 본문이 Claude 원문 기반으로 유지됐는가

## 변환 원칙

- Claude 문서를 Codex에 맞춘다고 해서 캐릭터를 지우지 않는다.
- 다만 Codex가 실제로 읽지 않는 구조는 남기지 않는다.
- 기존 Codex 파일과 내용을 섞어 새 문장을 만들지 않는다.
- 기존 Codex 파일은 비교와 경로 확인용으로만 본다.
- 본문은 항상 Claude 원문을 기준으로 다시 쓴다.
- 메인 스킬은 짧게 유지하고, 긴 규칙은 `references/`로 내린다.
- 이미 있는 Codex 파일이 있어도 우선 Claude 원문을 가져오고, 필요한 Codex 변환만 반영한다.
- 검증 도구가 막히면 수동 점검 결과를 명시한다.

## 자주 하는 변환

### Claude `agents/*.md` → Codex `SKILL.md`

- 페르소나
- 역할 범위
- 작업 단계
- 출력 형식
- 금지 사항

이런 내용은 대부분 메인 `SKILL.md`로 들어간다.

### Claude `skills/*/SKILL.md` → Codex `references/*.md`

- JPA 패턴
- Security 패턴
- 쿼리 튜닝 세부 규칙
- 도메인별 긴 예시

이런 내용은 메인 스킬에 다 넣지 말고 참고 문서로 뺀다.

### Claude 메타정보 → Codex 메타정보

- Claude frontmatter의 `name`, `description`은 Codex `SKILL.md` frontmatter로 정리
- Claude frontmatter의 `tools`는 보통 제거
- Codex UI용 문구는 `agents/openai.yaml`로 새로 정리

## 선택 규칙

- 사용자가 `spring 전체 가져와`처럼 말하면 관련 Claude 파일을 묶음으로 찾는다.
- 사용자가 `spring-security만 가져와`처럼 말하면 그 항목을 우선 가져오되, 상위 에이전트 문맥이 필요하면 함께 확인한다.
- 사용자가 `security`, `jpa`처럼 일부 이름만 말하면 부분 일치 후보를 먼저 찾고 관련 주제 파일까지 같이 검토한다.
- 사용자가 "머지 말고 원문 그대로"를 요구하면 기존 Codex 표현은 재사용하지 않고, Claude 원문을 기준으로 다시 작성한다.

이 규칙은 기본적으로 사용자가 `클로드` 또는 `claude`를 함께 말한 상황을 전제로 적용한다.

## 참고 문서

- 매핑 규칙이 필요하면 [references/claude-codex-mapping.md](C:/Users/P257212/.codex/skills/claude-to-codex/references/claude-codex-mapping.md)
- `agents/openai.yaml` 규칙이 필요하면 [references/openai-yaml-guide.md](C:/Users/P257212/.codex/skills/claude-to-codex/references/openai-yaml-guide.md)
