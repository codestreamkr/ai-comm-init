# ct-init-generic

주 언어를 확정하기 어렵거나 혼합 저장소일 때 core 문서 3종을 생성한다.

## 사용 기준

아래 상황이면 이 reference를 사용한다.

- Java, Node.js/TypeScript, Python 중 하나로 확정할 근거가 부족하다.
- 여러 언어가 있고 주 런타임을 판단하기 어렵다.
- 문서, 설정, 스크립트, prompt, wiki, data, infra 중심 저장소다.
- 생성 산출물이 코드 실행보다 문서/설정/데이터 관리에 가깝다.

## 근거 수집 순서

문서는 실제 파일을 근거로 작성한다.

1. `AGENTS.md`, `README.md`
2. 루트 디렉터리 구조
3. 주요 설정 파일
4. 실행 스크립트:
   - `*.sh`
   - `*.ps1`
   - `Makefile`
   - `justfile`
   - `Taskfile.yml`
5. CI 설정:
   - `.github/workflows/**`
   - `.gitlab-ci.yml`
6. 문서와 템플릿:
   - `docs/**`
   - `templates/**`
   - `skills/**`
   - `prompts/**`
7. 데이터와 샘플:
   - `data/**`
   - `examples/**`
   - `fixtures/**`

## 저장소 유형 판정

주 목적을 먼저 확정한다.

- 문서 저장소:
  - Markdown, docs, wiki가 중심
- 설정/부트스트랩 저장소:
  - install script, template, dotfile이 중심
- skill/prompt 저장소:
  - `SKILL.md`, `agents/openai.yaml`, `references/**`가 중심
- data 저장소:
  - CSV, JSON, YAML, parquet, assets가 중심
- infra 저장소:
  - Terraform, Helm, Kubernetes, Docker, CI 설정이 중심
- 혼합 저장소:
  - 위 목적이 둘 이상이고 주 산출물이 명확하지 않음

판정 실패 시 `확인 필요`로 표시한다.

## 언어/도구 후보 기록

Generic은 판단 근거를 숨기지 않는다.

- 감지된 언어:
  - Java 후보
  - Node.js/TypeScript 후보
  - Python 후보
  - 기타 후보
- 제외한 이유:
  - 실행 엔트리포인트 없음
  - 빌드 산출물 없음
  - 테스트/CI 근거 없음
  - 문서/설정 중심이 더 강함
- 후속 전환 조건:
  - 특정 언어 reference로 바꿀 수 있는 조건

## 명령 추출 기준

명령은 파일에 있는 것만 쓴다.

우선순위:

1. `README.md`
2. `AGENTS.md`
3. `Makefile`
4. `justfile`
5. `Taskfile.yml`
6. `package.json scripts`
7. shell/PowerShell 스크립트
8. CI workflow

근거가 없으면 명령을 추정하지 않는다.

## 산출물 기준

저장소가 무엇을 만들어내는지 먼저 적는다.

- 문서 산출물:
  - Markdown
  - HTML/PDF
  - wiki
- 설정 산출물:
  - generated config
  - dotfile
  - installer
- 데이터 산출물:
  - CSV/JSON/YAML
  - report
  - transformed dataset
- 코드 산출물:
  - script output
  - package
  - binary
  - container image
- 산출물이 없으면 `운영 규칙/참조 저장소`로 표기한다.

## core_project.md 생성 포맷

```markdown
# {PROJECT_NAME} 프로젝트

## 문서 메타
- 생성일: {GENERATED_DATE}
- 목적: 저장소의 목적, 산출물, 구조, 변경 영향 범위를 설명한다.
- 문서 성격: 구조/운영 개요 문서
- 책임 범위(정본): 저장소 목적, 디렉터리 구조, 산출물, 주요 도구, 변경 영향의 최종 기준
- 포함 범위: 저장소 유형, 주요 산출물, 디렉터리 구조, 도구/스크립트, 외부 의존성, 변경 체크포인트
- 제외 범위: 실행 명령 상세, 세부 작성 규칙
- 연계 문서: `.project/core_code_style.md`, `.project/core_workflow.md`
- 중복 방지 기준:
  - 실행/검증 명령은 `.project/core_workflow.md`에만 기록한다.
  - 문서/설정/스크립트 작성 규칙은 `.project/core_code_style.md`에만 기록한다.
  - 본 문서에는 구조와 산출물 중심으로 기록한다.
- 근거 소스: {EVIDENCE_SOURCES}

## 프로젝트 개요

### 목적
{PROJECT_PURPOSE}

### 저장소 유형
{REPOSITORY_KIND}

### 주요 산출물
{MAIN_OUTPUTS}

### 비대상/제약
{NON_GOALS_OR_CONSTRAINTS}

## 감지 결과
| 후보 | 근거 | 판정 |
|---|---|---|
| {CANDIDATE} | {EVIDENCE} | {DECISION} |

## 코드/문서 구조 (ASCII Tree, 최소 3뎁스)
```text
{PROJECT_STRUCTURE_TREE}
```

## 영역 맵
| 영역 | 주요 경로 | 핵심 파일 | 입력 | 출력 | 설명 |
|---|---|---|---|---|---|
| {AREA} | {PATHS} | {CORE_FILES} | {INPUTS} | {OUTPUTS} | {DESCRIPTION} |

## 도구와 자동화
| 도구 | 설정/스크립트 | 역할 | 실패 시 영향 |
|---|---|---|---|
| {TOOL} | {CONFIG_OR_SCRIPT} | {ROLE} | {FAILURE_IMPACT} |

## 외부 의존성
| 대상 | 방식 | 위치 | 비고 |
|---|---|---|---|
| {DEPENDENCY} | {METHOD} | {LOCATION} | {NOTES} |

## 변경 시 체크리스트
1. 산출물 경로와 소비자가 바뀌는지 확인한다.
2. 문서/설정/스크립트 중복이 생기지 않는지 확인한다.
3. 자동화나 설치 절차 영향 범위를 확인한다.
```

## core_code_style.md 생성 포맷

```markdown
# {PROJECT_NAME} 작성 규칙

## 문서 메타
- 생성일: {GENERATED_DATE}
- 목적: 저장소의 문서, 설정, 스크립트 작성 기준을 정리한다.
- 문서 성격: 작성 규칙 문서
- 책임 범위(정본): 파일명, 문서 구조, 설정 형식, 스크립트 스타일, 데이터 형식의 최종 기준
- 포함 범위: Markdown, YAML/JSON/TOML, shell/PowerShell, 템플릿, 데이터 파일 작성 기준
- 제외 범위: 실행 절차, 저장소 전체 구조 설명
- 연계 문서: `.project/core_project.md`, `.project/core_workflow.md`
- 중복 방지 기준:
  - 구조와 산출물 설명은 `.project/core_project.md`에만 기록한다.
  - 실행 명령과 검증 절차는 `.project/core_workflow.md`에만 기록한다.

## 파일/디렉터리 네이밍
{FILE_NAMING_RULES}

## Markdown 문서 작성 기준
{MARKDOWN_RULES}

## 설정 파일 작성 기준
{CONFIG_RULES}

## 스크립트 작성 기준
{SCRIPT_RULES}

## 데이터/템플릿 작성 기준
{DATA_TEMPLATE_RULES}

## 이력관리 기준
{HISTORY_RULES}

## 검토 체크리스트
1. 같은 정보가 여러 문서에 중복되지 않았는가?
2. 설정 파일의 근거와 소비자가 명확한가?
3. 스크립트가 실패 조건과 입력값을 명확히 다루는가?
4. 생성 산출물과 원본 템플릿이 구분되는가?
```

## core_workflow.md 생성 포맷

```markdown
# {PROJECT_NAME} 운영 워크플로우

## 문서 메타
- 생성일: {GENERATED_DATE}
- 목적: 저장소의 초기 설정, 실행, 검증, 배포 또는 산출물 생성 절차를 정리한다.
- 문서 성격: 실행/운영 절차 문서
- 책임 범위(정본): 명령, 도구 버전, 검증, 생성 산출물, 실패 대응의 최종 기준
- 포함 범위: 초기 설정, 주요 명령, 검증 절차, 자동화, 배포/산출물, 장애 대응
- 제외 범위: 구조 설명, 작성 스타일
- 연계 문서: `.project/core_project.md`, `.project/core_code_style.md`
- 중복 방지 기준:
  - 구조와 산출물 설명은 `.project/core_project.md`에만 기록한다.
  - 작성 규칙은 `.project/core_code_style.md`에만 기록한다.

## 도구 버전
| 도구 | 버전 | 근거 | 확인 필요 |
|---|---|---|---|
| {TOOL} | {VERSION} | {SOURCE} | {NEEDS_CHECK} |

## 초기 설정
```bash
{SETUP_COMMANDS}
```

## 주요 명령
| 목적 | 명령 | 근거 |
|---|---|---|
| {PURPOSE} | `{COMMAND}` | {SOURCE} |

## 검증 절차
```bash
{VERIFY_COMMANDS}
```

## 생성 산출물
| 산출물 | 생성 방법 | 소비자/용도 |
|---|---|---|
| {OUTPUT} | {HOW_TO_CREATE} | {CONSUMER_OR_PURPOSE} |

## 자동화/CI
{CI_AUTOMATION}

## 실패 대응 기준
{FAILURE_RESPONSE}
```

## 확인 필요 처리

확실한 근거가 없으면 일반 명령을 만들지 않는다.

- 주 언어 불명: 감지 후보와 제외 이유 기록
- 실행 명령 불명: `확인 필요`
- 산출물 불명: 저장소 목적과 주요 파일 기준으로 후보만 기록
- CI와 README 명령 충돌: 양쪽 근거와 확인 필요 항목 기록
