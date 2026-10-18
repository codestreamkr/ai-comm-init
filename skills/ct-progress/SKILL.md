---
name: ct-progress
description: 사용자가 `$ct-progress`를 호출하거나 다른 ct 스킬이 진행 표시를 요청하면 사용한다. ct 스킬의 실행 단계, 수행 주체, 상태, 토큰, ADR 후보를 프로세스 맵에 실시간으로 표시한다. 모든 런타임에서 Node.js와 브라우저만으로 동작한다.
argument-hint: "<맵 열기·정리 요청>"
disable-model-invocation: true
---

# CT Progress

ct 스킬이 지금 어느 단계에서 무엇을 하는지 프로세스 맵에 실시간으로 보여 준다.

- 맵 표시는 기본 동작이다. 사용자가 요청하지 않아도 ct 스킬은 항상 맵을 갱신한다.
- 맵 데이터는 OS 임시 폴더에만 둔다. 저장소에는 파일을 남기지 않는다.
- 영구 기록은 [ct-journal](../ct-journal/SKILL.md)이 담당한다.

## 호출

- 다른 ct 스킬은 이 파일을 상대 링크로 읽고 아래 지침을 따른다.
- `$ct-progress`: 역할, 필요한 입력, 대표 예제를 안내한다. 실행하지 않는다.
- `$ct-progress <요청>`: 맵 열기 또는 맵 데이터 정리를 실행한다.

예: `$ct-progress 맵 열어줘`

## 맵 열기

- 실행 흐름의 첫 스킬이 맵 서버를 연다.
- 열기 전에 상태를 확인한다. 명령: `node <skill-dir>/scripts/map.js status [--port N]`

| 종료 코드 | 상태 | 처리 |
|---|---|---|
| 0 | 맵 서버가 실행 중이다. | 다시 열지 않는다. 출력된 주소를 쓴다. |
| 1 | 맵 서버가 꺼져 있다. | 서버를 연다. |
| 2 | 다른 프로그램이 그 포트를 쓴다. | 다른 포트(`--port N`)로 상태를 다시 확인하고 연다. |
| 3 | 다른 버전의 맵 서버가 실행 중이다. | `node <skill-dir>/scripts/map.js stop [--port N]`으로 끄고 서버를 다시 연다. `stop`이 실패하면 그 포트를 쓰는 프로세스를 종료한다. |

- 실행 흐름의 첫 스킬: `ct-plan`, 또는 단독으로 실행한 `ct-analyze`, `ct-apply`, `ct-verify`, `ct-debrief`
- 서버는 셸에서 백그라운드로 실행한다. 명령: `node <skill-dir>/scripts/map.js serve [--port N]`
- 서버 하나가 모든 저장소의 맵을 보여 준다. 화면은 가장 최근에 갱신된 저장소를 자동으로 따라간다.
- 프로젝트에 런타임 전용 설정 파일을 만들지 않는다. 예: `.claude/launch.json`
- 브라우저는 실행 흐름을 시작할 때 한 번 연다. 서버가 이미 실행 중이어도 연다. 내장 브라우저에 맵 탭이 이미 있으면 그 탭을 쓴다.
- 브라우저는 주소(기본 `http://127.0.0.1:4319`)로 연다. 아래 순서로 시도한다.
  1. 런타임 내장 브라우저가 주소 열기를 지원하면 그 브라우저로 연다.
  2. 기본 브라우저로 연다. macOS `open <주소>`, Windows `start <주소>`, Linux `xdg-open <주소>`
  3. 둘 다 안 되면 주소만 사용자에게 알린다.
- Node.js가 없으면 맵 표시를 건너뛴다. 사용자에게 한 번 알린다. 다른 작업은 계속한다.

## 맵 데이터 정리

- 새 실행 흐름을 시작할 때 이전 맵 데이터를 지운다. 명령: `node <skill-dir>/scripts/map.js clear <저장소>`
- 끝난 흐름은 다음 흐름이 시작될 때까지 맵에 남긴다.
- 지우기 전에 맵의 미확정 ADR 후보가 `ct-journal` 지침으로 `candidates.md`에 반영되었는지 확인한다.

## 이벤트 보내기

- 메인 에이전트가 직접 보낸다. 서브에이전트에 맡기지 않는다.
- 명령: `node <skill-dir>/scripts/map.js emit <저장소> '<이벤트 JSON>'`
- 다른 명령과 `&&`로 묶어 한 번에 실행해도 된다.
- Windows PowerShell 5.1은 외부 프로그램 인자 안의 큰따옴표를 지운다. 이때는 JSON을 표준 입력으로 보낸다: `'<이벤트 JSON>' | node <skill-dir>/scripts/map.js emit <저장소> -`
- 키는 짧게 유지한다. 필요 없는 필드는 보내지 않는다.

| 시점 | 이벤트 |
|---|---|
| 스킬 시작 | `{"run":"apply-1","skill":"ct-apply","title":"주문 취소","model":"claude-opus-5-5","usage":{"file":"<사용량 기록>","kind":"message"},"steps":[{"id":"a1","name":"취소 상태 전이"},{"id":"v1","name":"테스트 실행","agent":"claude-haiku-5-5","after":["a1"]},{"id":"d1","name":"이해 확인","user":true,"after":["v1"]}]}` |
| 단계 상태 변경 | `{"run":"apply-1","step":"a1","s":"start"}` |
| 단계 완료 | `{"run":"apply-1","step":"a1","s":"done"}` |
| 서브에이전트 단계 완료 | `{"run":"apply-1","step":"v1","s":"done","usage":{"file":"<서브에이전트 사용량 기록>","kind":"message"}}` |
| 사용자 응답 대기 | `{"run":"apply-1","step":"d1","s":"wait","ask":"질문 내용"}` |
| 단계 추가 | `{"run":"apply-1","add":{"id":"f1","name":"부분 환불 수정","after":["v1"]}}` |
| 선행 단계 변경 | `{"run":"apply-1","add":{"id":"d1","after":["f1"]}}` |
| ADR 후보 | `{"run":"plan-1","adr":{"id":"c1","title":"결정","why":"사용자 답변","from":"ct-plan · 선택 + 이유"}}` |
| ADR 상태 변경 | `{"run":"apply-1","adr":{"id":"c1","s":"ok"}}` |

- `run`은 `<스킬 약칭>-<순번>`으로 만든다. 예: `plan-1`, `apply-1`
- `steps`에는 그 실행에서 실제로 할 일만 쓴다. 고정 목록을 쓰지 않는다.
- `s` 값: `start`, `done`, `fail`, `wait`, `skip`
- `after`는 선행 단계 id 목록이다. 같은 선행 단계를 가진 단계는 병렬로 표시된다.
- `agent`에는 버전을 포함한 서브에이전트 모델 이름을 쓴다. 예: `claude-haiku-5-5`
- 사용자가 하는 단계는 `"user":true`로 표시한다.
- 응답 대기 이벤트는 사용자에게 질문하기 전에 보낸다.
- ADR 상태 값: `cand`(후보, 기본값), `ok`(확정), `drop`(폐기)

## 모델과 토큰

### 모델

- 모델 이름은 에이전트가 직접 보낸다. `map.js`는 모델을 추측하지 않는다.
- 메인 모델은 실행 시작 이벤트의 `model`에 버전을 포함해 쓴다. 예: `claude-opus-5-5`
- 메인 모델이 실행 중에 바뀌면 그 뒤 단계의 완료 이벤트에 `m`을 넣는다.
- 서브에이전트 모델은 단계의 `agent`에 쓴다.

### 토큰

- 토큰은 새 입력과 출력의 합이다. 캐시에서 다시 읽은 입력은 제외한다.
- 메인 단계 토큰은 누적 사용량의 차이다: 완료 시각의 누적 - 시작 시각의 누적. 메인은 한 번에 한 단계만 한다.
- 서브에이전트는 별도 세션이다. 그 세션의 사용량을 따로 계산한다.
- `map.js`는 맵 서버가 응답할 때 계산한다. 세션 기록 반영이 늦으면 다음 화면 갱신 때 값이 나타난다.
- 계산에 쓸 사용량 기록은 에이전트가 특정해 `usage`로 보낸다. `map.js`는 런타임 이름이 아니라 기록 형식(`kind`)으로 계산한다.

| `kind` | 기록 형식 | 누적 사용량 |
|---|---|---|
| `message` | 줄마다 `timestamp`와 `message.usage`가 있다 | 그 시각까지 메시지별 `input_tokens` + `cache_creation_input_tokens` + `output_tokens`의 합 |
| `total` | 줄마다 `timestamp`와 `payload.info.total_token_usage`가 있다 | 그 시각까지 마지막 값의 `input_tokens` - `cached_input_tokens` + `output_tokens` |

- `total` 기록에 응답 항목(`response_item`)이 있으면 사용량을 직전 모델 응답의 시각에 연결한다.
- 집계가 도구 완료 뒤에 기록되어도 해당 응답이 속한 단계에 반영한다. 응답 항목이 없으면 집계 시각을 쓴다.

### 사용량 기록 특정

실행 흐름의 첫 스킬이 실행 시작 이벤트를 보내기 전에 한 번 한다.

1. 자기 모델 이름을 확인한다.
2. 환경 변수로 런타임을 확인한다.
3. 아래 표에서 그 런타임의 메인 기록을 찾는다. 파일이 정확히 하나일 때만 `usage`로 보낸다.
4. 서브에이전트 단계가 끝나면 서브에이전트 기록을 찾아 완료 이벤트의 `usage`로 보낸다. 런타임 결과에 사용량이 있으면 `tok`을 직접 보내도 된다.

| 런타임 | 확인 | 메인 기록 (`kind`) | 서브에이전트 기록 (`kind`) |
|---|---|---|---|
| Claude Code | `CLAUDE_CODE_SESSION_ID` | `~/.claude/projects/*/<CLAUDE_CODE_SESSION_ID>.jsonl` (`message`) | `<메인 기록에서 .jsonl을 뺀 폴더>/subagents/agent-<agentId>.jsonl` (`message`). `agentId`는 Agent 도구 결과에 있다 |
| Codex | `CODEX_THREAD_ID` | `${CODEX_HOME:-~/.codex}/sessions/**/rollout-*-<CODEX_THREAD_ID>.jsonl` (`total`) | 첫 줄 `session_meta`의 `source.subagent.thread_spawn`에서 `parent_thread_id`가 자기 thread id이고 `agent_path`가 `spawn_agent` 결과의 `task_name`인 rollout 파일 (`total`) |

- 표에 없는 런타임은 같은 원칙으로 추론한다: 자기 세션 id로 시각과 사용량이 있는 기록 하나를 특정한다. 형식이 위 `kind`와 맞을 때만 보낸다.
- 기록을 하나로 특정하지 못하면 `usage`를 보내지 않는다. 추측하지 않는다. 이때 토큰은 비어 있다.

## 완료

- 맵 열기: 맵 주소와 여는 데 쓴 방법을 보고한다.
- 맵 데이터 정리: 정리한 저장소를 보고한다.
- Node.js가 없거나 브라우저를 열지 못했으면 그 사실을 보고한다.
