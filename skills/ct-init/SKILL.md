---
name: ct-init
description: "저장소 초기화(init) 직후 프로젝트 언어와 런타임을 감지해 core_project.md, core_code_style.md, core_workflow.md 3개 문서를 재생성하고, AGENTS.md는 core 문서 참조만 유지하도록 정리한다. Java, Node.js/TypeScript, Python, Generic 프로젝트를 지원한다."
---

# CT Init

## 목적

프로젝트 기준 문서 3종을 언어별 표준에 맞게 만든다.

- 생성 대상:
  - `.docs/core_project.md`
  - `.docs/core_code_style.md`
  - `.docs/core_workflow.md`
- `AGENTS.md`는 라우팅 전용으로 유지한다.
- 상세 구조, 스타일, 실행 절차는 `core_*` 3종으로 분리한다.

## 사용 시점

저장소 초기 기준 문서가 필요할 때 사용한다.

- 새 저장소를 세팅한 직후
- `.docs` 문서가 없거나 초기 상태로 재생성해야 할 때
- `AGENTS.md`가 비대해져 상세를 `core_*` 문서로 분리하려고 할 때

## 실행 방식

먼저 프로젝트 유형을 확인한 뒤 reference를 하나만 읽는다.

- 스크립트를 실행하지 않는다.
- 파일 근거로 언어와 런타임을 판정한다.
- 판정한 reference의 생성 포맷에 따라 문서를 직접 작성한다.
- 언어별 reference를 여러 개 섞지 않는다.
- 판단 근거가 부족하면 `generic`을 사용하고 확인 필요 항목을 남긴다.

## 언어 감지 순서

파일 근거를 우선한다.

1. Java
   - `pom.xml`
   - `build.gradle`, `build.gradle.kts`, `settings.gradle`
   - `src/main/java/**`, `src/test/java/**`
2. Node.js/TypeScript
   - `package.json`
   - `tsconfig.json`
   - `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`
   - `src/**/*.ts`, `src/**/*.tsx`, `app/**`, `pages/**`
3. Python
   - `pyproject.toml`
   - `requirements.txt`, `poetry.lock`, `uv.lock`, `Pipfile`
   - `src/**/*.py`, `tests/**/*.py`
4. Generic
   - 위 기준으로 주 언어를 확정하기 어렵거나 혼합 저장소인 경우

## reference 선택

감지 결과에 맞는 reference만 읽는다.

- Java: `references/ct-init-java.md`
- Node.js/TypeScript: `references/ct-init-node.md`
- Python: `references/ct-init-python.md`
- Generic: `references/ct-init-generic.md`

## 혼합 저장소 기준

여러 언어가 함께 있으면 주 런타임을 먼저 판단한다.

- 우선 기준:
  - 배포 산출물을 만드는 빌드 파일
  - 실제 실행 엔트리포인트
  - 테스트와 CI의 기본 명령
  - `README.md` 또는 기존 `AGENTS.md`의 실행 설명
- 주 런타임이 명확하면 해당 reference를 사용한다.
- 주 런타임이 불명확하면 `generic`을 사용한다.
- 판단 근거와 제외한 후보를 `.docs/core_project.md`에 남긴다.

## 공통 생성 정책

생성 결과는 항상 최신 포맷을 기준으로 한다.

- 기본 동작은 재생성이다.
- 대상 파일이 이미 있으면 덮어쓴다.
- 기존 내용 보존을 위한 부분 병합은 하지 않는다.
- 확인 불가 항목은 추측하지 않고 `확인 필요`로 표기한다.
- 템플릿 플레이스홀더를 최종 문서에 남기지 않는다.
- 같은 정보가 둘 이상의 core 문서에 반복되면 안 된다.

## core 문서 메타 규칙

세 문서의 `문서 메타`는 같은 순서를 사용한다.

- `생성일`
- `목적`
- `문서 성격`
- `책임 범위(정본)`
- `포함 범위`
- `제외 범위`
- `연계 문서`
- `중복 방지 기준`

작성 기준:

- `책임 범위(정본)`은 이 주제의 최종 기준 문서를 명시한다.
- `중복 방지 기준`은 다른 core 문서로 보내야 하는 내용을 문장 단위로 적는다.
- 문서 간 중복이 생기면 책임 문서 한 곳에만 남긴다.

## core 문서 책임

세 문서의 책임을 분리한다.

- `core_project.md`
  - 프로젝트 목적, 아키텍처, 런타임, 코드 구조, 데이터 접근, 외부 연동, 변경 영향
- `core_code_style.md`
  - 네이밍, 파일/모듈 배치, 타입/모델 규칙, 오류 처리, 로깅, 테스트 작성 스타일
- `core_workflow.md`
  - 설치, 빌드, 테스트, 실행, 환경 변수, 배포, 장애 대응, 도구 버전

## 코드베이스 구조 규칙

구조 문서는 온보딩 기준으로 작성한다.

- `.docs/core_project.md`의 `코드베이스 구조`는 최소 3뎁스까지 표현한다.
- 기준은 저장소 루트 상대 경로다.
- 주요 디렉터리에는 역할 주석을 붙인다.
- 실제 구조가 3뎁스 미만이면 `최대 N뎁스` 사유를 한 줄로 남긴다.
- 실행 명령은 `core_project.md`에 쓰지 않고 `core_workflow.md`에만 쓴다.
- 테스트 섹션에는 테스트 위치와 대표 파일만 적고, 실행 명령은 `core_workflow.md`에만 쓴다.

## AGENTS 동기화 정책

`AGENTS.md`는 라우팅 전용으로 유지한다.

- `AGENTS.md` 상단에 `ct-init` 관리 블록을 유지한다.
- 관리 블록 범위:
  - `<!-- ct-init:core-docs:start -->`
  - `<!-- ct-init:core-docs:end -->`
- `AGENTS.md` 제목은 `# AGENTS.md (Project Routing Only)`로 유지한다.
- 상세 정책은 `AGENTS.md`에 추가하지 않는다.
- 규칙/절차 변경은 대상 core 문서를 수정하고 동기화 일자만 갱신한다.

## 공통 AGENTS 템플릿

아래 블록을 유지한다.

```markdown
# AGENTS.md (Project Routing Only)

<!-- ct-init:core-docs:start -->
## Core 문서 참조 (ct-init 관리)
- 프로젝트 구조/모듈 상세: `.docs/core_project.md`
- 코딩 스타일/네이밍 상세: `.docs/core_code_style.md`
- 빌드/테스트/운영 상세: `.docs/core_workflow.md`
- AGENTS.md는 라우팅 전용으로 유지하고, 상세 규칙은 위 문서에서 관리한다.
- 마지막 동기화: {GENERATED_DATE}
<!-- ct-init:core-docs:end -->

## 추가 라우팅
- 빌드/테스트/실행/환경 버전 판단이 필요한 작업은 먼저 `.docs/core_workflow.md`를 확인한다.

## 운영 원칙
- 본 문서에는 상세 정책을 추가하지 않는다.
- 규칙/절차 변경은 대상 문서를 수정하고 동기화 일자만 갱신한다.
```

## 출력

처리 결과를 짧게 요약한다.

- 감지한 프로젝트 유형
- 사용한 reference
- 생성 또는 재생성한 파일
- 확인 필요 항목
- 실행하지 못한 검증
