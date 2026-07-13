---
name: ct-script-run
description: 프로젝트 언어와 실행 방식을 감지해 macOS/Linux용 sh, Windows용 ps1 시작 스크립트, env 예시 파일, 요청된 Docker 의존 서비스 구성을 만든다. 사용자가 `$ct-script-run`, `ct-script-run`, local/dev/prod 실행 스크립트 생성, scripts/local.sh 생성, PowerShell 실행 스크립트 생성, Docker Compose로 PostgreSQL/Redis 같은 로컬 의존 서비스 구성을 요청할 때 사용한다.
---

# ct-script-run

## 목적

프로젝트를 바로 실행할 수 있도록 환경별 시작 스크립트와 env 예시를 만든다.

## 기본 절차

1. 프로젝트 실행 방식을 확인한다.
2. 기존 스크립트와 Docker 구성을 확인한다.
3. 환경별 스크립트 책임을 정한다.
4. 요청 범위에 `sh`와 `ps1`이 함께 포함되면 같은 책임으로 생성하거나 갱신한다.
5. env 예시 파일을 생성하거나 갱신한다.
6. 요청된 Docker 의존 서비스를 Compose에 반영한다.
7. 가능한 검증을 수행하고 실행 명령을 보고한다.

## 먼저 확인할 파일

실행 기준은 저장소에 있는 파일을 우선한다.

- 프로젝트 문서: `.docs/core_workflow.md`, `AGENTS.md`
- 공통 실행: `Makefile`, `Dockerfile`, `compose.yaml`, `docker-compose.yml`
- Node.js: `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`
- Java/Spring: `pom.xml`, `build.gradle`, `gradlew`, `mvnw`
- Python: `pyproject.toml`, `requirements.txt`, `uv.lock`, `Pipfile`

## 실행 명령 정합성

스크립트 명령은 실행 가능한 프로젝트 설정을 기준으로 확정한다.

- 우선 근거:
  1. 기존 환경별 실행 스크립트, launcher와 Makefile target
  2. 빌드 파일, package script, wrapper와 lockfile
  3. `.docs/core_workflow.md`와 README
- 기존 launcher나 Makefile 명령이 빌드 설정에 존재하는 task·script·산출물과 연결되면 해당 launcher 명령을 유지한다.
- 기존 launcher가 삭제된 task나 존재하지 않는 산출물을 호출하면 빌드 설정으로 실행 명령을 바로잡고 차이를 보고한다.
- 선택한 명령을 `.docs/core_workflow.md`의 설치·빌드·테스트·실행 명령과 대조한다.
- 문서와 실행 가능한 설정이 다르면 설정을 기준으로 스크립트를 만들고 차이를 보고한다.
- `core_workflow.md` 수정은 사용자가 문서 갱신까지 요청한 경우에만 수행한다.

## 미정의 언어 처리

정의된 언어가 아니거나 언어를 확정할 수 없으면 Generic 모드로 처리한다.

- 기존 실행 스크립트와 문서에서 앱 실행 명령을 찾는다.
- 실행 명령이 명확하면 해당 명령으로 `sh`와 `ps1`을 만든다.
- 실행 명령이 불명확하면 앱 실행 명령만 사용자에게 짧게 묻는다.
- Docker 의존 서비스와 env 예시는 앱 실행 명령과 독립적으로 만들 수 있다.
- 확정되지 않은 앱 실행 명령을 placeholder로 넣지 않는다.

## 생성 대상

사용자 요청 범위를 우선한다.

- 특정 파일만 요청받으면 해당 파일과 직접 필요한 보조 파일만 만든다.
- 특정 환경만 요청받으면 해당 환경의 `.sh`와 `.ps1`만 같은 책임으로 맞춘다.
- OS가 명시되면 해당 OS 스크립트만 만들고, 반대 OS 스크립트는 요청이 있을 때 추가한다.
- 범위가 명확하지 않고 실행 스크립트 세트 생성을 요청받으면 기본 파일을 환경별로 만든다.

기본 파일은 범위가 없을 때 만든다.

- `scripts/local.sh`
- `scripts/local.ps1`
- `scripts/dev.sh`
- `scripts/dev.ps1`
- `scripts/prod.sh`
- `scripts/prod.ps1`
- `.env.example`

필요할 때만 환경별 env 예시를 추가한다.

- `.env.local.example`
- `.env.dev.example`
- `.env.prod.example`

Docker 의존 서비스를 요청받으면 기존 Compose 파일을 갱신하거나 새 Compose 파일을 만든다.

- `compose.yaml`
- `docker-compose.yml`

## 핵심 실행 계약

생성 파일은 같은 실행 계약을 따른다.

- 기본 명령은 `up`, `down`이다.
- `up`은 앱 서버를 foreground로 실행한다.
- Docker로 앱을 실행해도 앱 서비스에는 detached 옵션을 사용하지 않고 로그를 현재 터미널에 연결한다.
- Docker 앱 서비스의 종료 코드를 스크립트 결과로 전달할 때 `docker compose up --exit-code-from <app-service> <app-service>` 형식을 사용한다.
- 스크립트의 종료 상태와 중단 신호는 앱 프로세스 또는 앱 컨테이너의 lifecycle과 연결한다.
- 빈 인자는 사용법과 env 경로만 출력한다.
- Docker 의존 서비스는 사용자가 요청한 서비스만 구성한다.
- 상태 저장 서비스는 named volume을 사용한다.
- 실제 비밀값은 env 예시에 넣지 않는다.
- `prod`는 로컬 Docker 의존 서비스를 자동 실행하지 않는다.

## 세부 생성 기준

구체적인 파일 작성 규칙은 `workflow/script-generation.md`를 따른다.

## 완료 조건

작업 완료 전에 아래를 확인한다.

- 사용자가 요청한 파일, 환경, OS만 생성·수정했다.
- 여러 환경이 범위에 포함되면 각 환경의 책임이 분리되어 있다.
- `.sh`와 `.ps1`이 함께 범위에 포함되면 같은 명령 책임을 제공한다.
- OS가 하나만 지정되면 해당 OS 스크립트만 완료 대상으로 판정한다.
- 앱 실행 스크립트의 `up`은 서버를 foreground로 실행한다.
- Docker 구성이 범위에 포함되면 `down` 종료 대상이 요청 서비스로 제한된다.
- env 예시에는 범위에 필요한 키만 있고 실제 비밀값은 없다.
- 선택한 실행 명령을 프로젝트 설정과 `core_workflow.md`에 대조했다.
- 요청 범위의 파일에 가능한 문법·구성 검증을 수행했다.

## 이력관리

- 2026-07-13: 세부 생성 기준을 workflow 정본으로 모으고 요청 범위 기반 완료 조건, launcher·Makefile·빌드 설정의 실행 명령 우선순위와 Docker 앱 foreground·종료 코드 lifecycle 기준을 추가했다.
- 2026-07-08: 요청 범위 우선 생성 기준을 추가했다.
