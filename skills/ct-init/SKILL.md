---
name: ct-init
description: "프로젝트 언어와 런타임을 감지해 사람용 `README.md`와 AI용 `AGENTS.md` 관리 블록을 생성·동기화한다. 기존 README의 개발 환경 설정을 보존하면서 프로젝트 기준을 보완해야 할 때, 사용자가 `$ct-init`을 명시적으로 호출한 경우에만 사용한다."
---

# CT Init

## 목적

사람용 프로젝트 정본과 AI 작업 시작 규칙을 만든다.

- 생성·갱신 대상:
  - `README.md`
  - `AGENTS.md`의 ct-init 관리 블록
- `README.md`는 프로젝트 정보와 개발·실행 기준의 최종 기준이다.
- `AGENTS.md`는 AI가 README를 먼저 읽고 작업별 기준을 적용하도록 안내한다.
- 기존 `.docs/core_*.md`는 `migrate`에서만 README 통합 입력으로 사용한다.
- 이 스킬은 README와 AGENTS 외 문서를 생성, 수정, 이동, 삭제하지 않는다.

## 실행 방식

프로젝트 유형을 확인한 뒤 하나의 언어별 reference를 읽는다.

- 스크립트를 실행하지 않는다.
- 파일 근거로 언어와 런타임을 판정한다.
- 판정한 reference의 README 생성 포맷을 적용한다.
- 언어별 reference를 여러 개 섞지 않는다.
- 판단 근거가 부족하면 `generic`을 사용하고 확인 필요 항목을 남긴다.

## 실행 모드

- `sync`: 기본 모드다. 기존 `README.md`와 현재 저장소 근거를 분석하고, 언어별 표준 구조를 반영한 최종 README를 생성한다. core 문서는 읽거나 반영하지 않는다.
- `migrate`: 사용자가 `$ct-init --migrate`를 명시한 경우 사용한다.
  - 기존 `README.md`와 `.docs/core_*.md`를 모두 분석해 README 표준 구조로 통합한다.
  - core 문서에서 반영한 내용과 확인 필요 항목을 결과에 보고한다.
  - 원본 core 문서는 삭제하거나 수정하지 않는다.
- `reset`: 사용자가 `$ct-init --reset` 또는 README 재생성을 명시한 경우에만 사용한다.
  - 실행 전에 기존 README 전체를 반영하지 않고 교체하는 요청인지 확인한다.
  - 확인되면 기존 README와 관리 마커 상태에 관계없이 파일 전체를 현재 저장소 근거와 언어별 표준 템플릿으로 교체한다.
  - 기존 README의 제목, 요약, 관리 블록 밖 본문, 개발 환경, 이력은 병합하지 않는다.

## 언어 감지 순서

1. Java: `pom.xml`, Gradle 파일, `src/main/java/**`
2. Node.js/TypeScript: `package.json`, `tsconfig.json`, lock 파일
3. Python: `pyproject.toml`, `requirements.txt`, lock 파일
4. Generic: 주 언어를 확정하기 어렵거나 혼합 저장소인 경우

## reference 선택

- Java: `references/ct-init-java.md`
- Node.js/TypeScript: `references/ct-init-node.md`
- Python: `references/ct-init-python.md`
- Generic: `references/ct-init-generic.md`

## README 생성·갱신 규칙

README는 사람용 정본이다.

- `README.md`가 없으면 언어별 표준 템플릿 전체를 생성한다.
- `README.md`가 있으면 기존 본문을 입력으로 먼저 분석한다.
- `migrate`에서는 `.docs/core_project.md`, `.docs/core_code_style.md`, `.docs/core_workflow.md`가 있으면 함께 읽는다.
- 기존 내용을 프로젝트 개요, 구조, 개발 환경, 빌드, 테스트, 실행, 설정, 변경 영향, 문제 해결 항목으로 분류한다.
- `migrate`에서는 core 문서의 구조·구현 규칙·실행 절차 정보도 같은 표준 섹션으로 분류한다.
- 분류한 기존 내용과 현재 저장소에서 확인한 근거를 사용해 언어별 표준 템플릿 구조의 최종 README를 생성한다.
- 기존 `## 개발 환경`의 JDK·SDK 경로, 환경 변수, Maven·패키지 매니저 설정, IDE 설정, 인증서, 프록시, 로컬 도구 설정은 최종 README에 반드시 포함한다.
- 템플릿에 없는 기존 개발 환경 항목도 누락하지 않는다.
- 기존의 유효한 빌드·테스트·실행·설정 정보는 해당 표준 섹션으로 옮겨 포함한다.
- `migrate`에서는 core 문서의 유효한 구조·코드 규칙·실행·운영 정보도 README의 해당 표준 섹션에 포함한다.
- 기존 내용과 현재 저장소 근거가 충돌하면 기존 정보를 임의로 삭제하지 않는다. 두 근거와 확인할 항목을 해당 섹션에 기록한다.
- `migrate`에서 README와 core 문서가 충돌하면 README를 우선하고, core 문서의 차이는 확인할 항목으로 남긴다.
- 확인하지 못한 값은 추측하지 않는다.
- 템플릿의 모든 플레이스홀더를 확인된 값 또는 `확인 필요`로 치환한다.
- README 본문은 표준 구조에 맞춰 재구성할 수 있다.
- README 본문은 최종 상태만 남기고 변경 이력은 맨 끝 `## 이력관리`에만 기록한다.

## README 관리 섹션

ct-init은 표준 README 구조를 관리한다.

- 관리 섹션 범위:
  - `<!-- ct-init:readme:start -->`
  - `<!-- ct-init:readme:end -->`
- `sync` 또는 `migrate`에서 기존 README에 관리 마커가 없으면 기존 본문을 분석한 뒤 파일 전체를 H1 제목, 프로젝트 요약, 표준 관리 섹션 순서로 재구성한다.
- `sync` 또는 `migrate`에서 기존 README에 정상 관리 마커 한 쌍이 있으면 관리 섹션만 교체하고, 관리 섹션 밖의 내용은 원문 그대로 보존한다.
- 표준 관리 섹션에는 `## 개발 환경`과 마지막 섹션인 `## 이력관리`를 포함한다.
- 표준 템플릿에 없는 기존 정보는 가장 적절한 표준 섹션에 포함한다. 적절한 섹션이 없으면 `## 추가 참고`에 포함한다.
- `reset`은 기존 README 전체 교체가 확인된 경우에만 파일 전체를 새로 생성한다.
- `sync` 또는 `migrate`에서 마커 중첩이나 범위를 안전하게 판정할 수 없으면 내용을 삭제하지 않고 중단한 뒤 위치를 보고한다.

## AGENTS 동기화 정책

AGENTS에는 AI 작업 시작 규칙만 둔다.

- 관리 블록 범위:
  - `<!-- ct-init:agent-guide:start -->`
  - `<!-- ct-init:agent-guide:end -->`
- 이전 버전의 `ct-init:core-docs` 시작·종료 마커는 레거시 관리 블록으로 인식한다.
- 관리 블록 밖의 제목과 사용자 규칙은 보존한다.
- 신·레거시 관리 블록이 모두 없으면 첫 H1 제목 다음에 추가하고 H1 제목이 없으면 파일 시작에 추가한다.
- 신 관리 블록이 없고 정상 레거시 관리 블록 한 쌍만 있으면 레거시 블록 위치에 신 관리 블록을 생성한다.
- 신·레거시 관리 블록이 함께 있으면 모든 관리 블록을 제거하고 첫 관리 블록 위치에 신 관리 블록 하나를 생성한다.
- 정상 한 쌍이면 마커 내부만 교체한다.
- 같은 종류의 완전한 관리 블록이 여러 개면 각 관리 블록만 제거하고 첫 위치에 하나를 생성한다.
- 신·레거시 고아 마커는 해당 줄만 제거한 뒤 첫 고아 마커 위치에 정상 블록을 생성한다.
- 마커 중첩이나 범위를 안전하게 판정할 수 없으면 내용을 삭제하지 않고 중단한다.

## AGENTS 관리 블록 템플릿

```markdown
<!-- ct-init:agent-guide:start -->
## 프로젝트 작업 시작 기준 (ct-init 관리)
- 프로젝트 정보와 개발·실행 기준의 정본은 `README.md`다.
- 프로젝트 작업을 시작하면 `README.md`를 먼저 읽는다.
- 빌드, 테스트, 실행, 환경 설정 변경 전에는 README의 관련 섹션을 다시 확인한다.
- 실행 명령은 README에 기록된 환경 설정과 명령을 적용한다.
- README 기준과 현재 환경이 다르면 실행하지 않고 차이와 영향을 보고한다.
- 마지막 동기화: {GENERATED_DATE}
<!-- ct-init:agent-guide:end -->
```

## 완료 조건

- README가 존재한다.
- README에 프로젝트 개요, 개발 환경, 빌드, 테스트, 실행 기준이 존재한다.
- 최초 생성이면 README가 선택한 언어 reference의 표준 구조를 따른다.
- `sync` 재실행이면 기존 README의 개발 환경 설정이 최종 README에 포함된다.
- `sync` 재실행이면 기존 README의 유효한 빌드·테스트·실행·설정 정보가 해당 표준 섹션에 포함된다.
- `migrate`에서 기존 core 문서가 있으면 유효한 프로젝트 정보가 README의 해당 표준 섹션에 포함된다.
- 기존 개발 환경 설정과 저장소 근거가 충돌하면 두 근거와 확인 항목이 최종 README에 남는다.
- AGENTS 관리 블록이 정확히 한 쌍이고 README 우선 규칙을 포함한다.
- AGENTS에 레거시 `ct-init:core-docs` 마커가 남아 있지 않다.
- AGENTS 관리 블록 밖의 내용은 변경하지 않는다.
- README와 AGENTS에 미치환 템플릿 플레이스홀더가 남아 있지 않다.
- 확인할 수 없는 값과 실행하지 못한 검증을 결과에 기록한다.

## 출력

- 감지한 프로젝트 유형과 근거
- 적용한 실행 모드와 reference
- 생성 또는 갱신한 README·AGENTS 영역
- 보존한 개발 환경 설정
- 새로 추가한 확인된 기준
- `migrate`에서 core 문서로부터 README에 반영한 항목
- 충돌 또는 확인 필요 항목
