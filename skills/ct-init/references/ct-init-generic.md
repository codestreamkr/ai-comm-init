# ct-init-generic

주 언어를 확정할 수 없는 프로젝트의 README 기준을 만든다.

## 근거 수집

- `README.md`, `AGENTS.md`, 루트 구조, 주요 설정 파일
- `--migrate`에서는 기존 `.docs/core_*.md`
- 실행 스크립트, CI 설정, Dockerfile, 문서와 템플릿

## 작성 기준

- 저장소 목적, 주요 산출물, 실제로 확인한 명령과 도구만 README에 기록한다.
- 기존 README의 개발 환경 설정은 표준 README의 개발 환경 섹션에 반영한다.
- 명령, 버전, 산출물을 확인하지 못하면 추측하지 않고 확인 필요로 남긴다.

## README 표준 구조

```markdown
# {PROJECT_NAME}

{PROJECT_SUMMARY}

<!-- ct-init:readme:start -->
## 프로젝트 개요
## 개발 환경

- 필요한 도구와 버전: `{CONFIRMED_TOOLS_OR_CHECK_REQUIRED}`
- 로컬 환경 설정은 이 섹션에서 관리한다.

## 주요 산출물
## 프로젝트 구조
## 빌드 또는 생성
## 검증
## 실행 또는 사용 방법
## 환경과 설정
## 변경 영향 확인
## 문제 해결
## 이력관리
- {GENERATED_DATE}: ct-init으로 README 생성 또는 갱신
<!-- ct-init:readme:end -->
```

`## 개발 환경`은 표준 README에 포함하며 재실행 시 기존 설정을 누락하지 않는다.
