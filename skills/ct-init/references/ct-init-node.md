# ct-init-node

Node.js 또는 TypeScript 프로젝트의 README 기준을 만든다.

## 근거 수집

- `README.md`, `AGENTS.md`, `package.json`, lock 파일, `tsconfig.json`
- `--migrate`에서는 기존 `.docs/core_*.md`
- Node 버전 파일(`.nvmrc`, `.node-version`, `package.json engines`)
- `src/**`, `test/**`, `tests/**`, `app/**`, `pages/**`
- 실행 스크립트, Dockerfile, CI 설정

## 실행 환경 확인

- Node와 패키지 매니저 버전은 설정 파일과 기존 README에서 확인한다.
- 기존 README의 개발 환경 설정은 표준 README의 개발 환경 섹션에 반영한다.
- `package.json` scripts와 CI 명령을 근거로 빌드·테스트·실행 명령을 작성한다.
- 확인하지 못한 버전·명령·환경 변수는 추측하지 않는다.

## README 표준 구조

```markdown
# {PROJECT_NAME}

{PROJECT_SUMMARY}

<!-- ct-init:readme:start -->
## 프로젝트 개요
## 기술 스택
## 개발 환경

- Node.js: `{NODE_VERSION_OR_CHECK_REQUIRED}`
- 패키지 매니저: `{PACKAGE_MANAGER_AND_VERSION}`
- 환경 변수와 로컬 도구 설정은 이 섹션에서 관리한다.

## 프로젝트 구조
## 빌드
## 테스트
## 로컬 실행
## 환경과 설정
## 변경 영향 확인
## 문제 해결
## 이력관리
- {GENERATED_DATE}: ct-init으로 README 생성 또는 갱신
<!-- ct-init:readme:end -->
```

`## 개발 환경`은 표준 README에 포함하며 재실행 시 기존 설정을 누락하지 않는다.
