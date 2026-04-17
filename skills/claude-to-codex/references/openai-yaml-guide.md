# `agents/openai.yaml` 작성 가이드

## 기본 형태

```yaml
interface:
  display_name: "사용자에게 보이는 이름"
  short_description: "짧고 분명한 한 줄 설명"
  default_prompt: "Use $skill-name to ..."
policy:
  allow_implicit_invocation: true
```

## 필드별 기준

### `display_name`

- UI에서 바로 읽히는 이름을 쓴다.
- 보통 2~20자 정도가 무난하다.
- 원문에 별칭이 있으면 그것을 살려도 된다.

예시:
- `"로드형"`
- `"Claude to Codex"`

### `short_description`

- 25~64자 정도의 짧은 설명이 좋다.
- 무엇을 하는지 바로 보여야 한다.
- 마케팅 문구보다 작업 내용을 적는다.

좋은 예:
- `"프로젝트 컨벤션을 맞춰 Spring 작업을 정리"`
- `"Claude 스킬과 에이전트를 Codex 형식으로 변환"`

나쁜 예:
- `"강력한 차세대 변환 도우미"`
- `"모든 걸 완벽하게 바꿔주는 스킬"`

### `default_prompt`

- 반드시 `$skill-name`을 직접 언급한다.
- 보통 한 문장으로 쓴다.
- 실제 사용자가 바로 눌러 쓸 수 있는 문장으로 쓴다.

좋은 예:
- `"Use $spring to inspect the project conventions first and handle this Spring task in the repository's existing style."`
- `"Use $claude-to-codex to convert these Claude agents or skills into Codex-compatible skills, references, and metadata."`

## 선택 항목

### `icon_small`, `icon_large`, `brand_color`

아래 조건이 아니면 넣지 않는다.
- 실제 asset 파일이 있다
- 사용자가 색상이나 아이콘을 지정했다

### `dependencies.tools`

실제로 특정 MCP가 필수일 때만 둔다.

예시:
- GitHub MCP 없이는 동작할 수 없는 스킬
- Figma MCP가 반드시 필요한 디자인 스킬

대부분의 문서 변환 스킬은 이 항목이 없어도 된다.

## 작성 규칙

- 모든 문자열은 큰따옴표로 감싼다.
- key는 따옴표 없이 쓴다.
- `policy.allow_implicit_invocation`은 특별한 이유가 없으면 `true`
- 인코딩이 깨지지 않게 UTF-8로 저장한다.

## 수동 점검 체크리스트

1. `default_prompt`에 `$skill-name`이 정확히 들어 있는가
2. 문자열이 모두 큰따옴표로 감싸졌는가
3. 설명이 추상적이지 않고 작업이 보이는가
4. asset 경로를 넣었다면 실제 파일이 존재하는가
5. 의존 도구를 적었다면 현재 환경에서 정말 필요한가
