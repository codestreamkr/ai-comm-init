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
4. `sh`와 `ps1`을 같은 책임으로 생성하거나 갱신한다.
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

## 명령 기준

각 환경 스크립트는 `up`과 `down`을 기본 명령으로 제공한다.

- `up`: env를 로드하고 의존 서비스를 실행한 뒤 서버 애플리케이션을 foreground로 실행한다.
- `down`: Docker 의존 서비스와 Docker 기반 실행 요소를 종료한다.

아무 명령도 받지 않으면 사용법을 안내하고 종료한다.

- 기본 명령 목록을 출력한다.
- 예시 실행 명령을 출력한다.
- 현재 스크립트가 참조하는 env 파일을 안내한다.
- 앱 서버나 Docker 서비스를 자동 실행하지 않는다.

`app` 명령은 기본으로 만들지 않는다.

- `up`이 앱 서버 foreground 실행을 포함한다.
- 앱만 따로 실행해야 하는 요구가 명확할 때만 `app` 또는 `run`을 추가한다.

선택 명령은 필요할 때만 만든다.

- `status`: Docker 서비스 상태와 포트 상태를 확인한다.
- `logs`: Docker 의존 서비스 로그를 확인한다.
- `check`: env, Docker, 런타임, 앱 실행 명령을 점검한다.

## 서버 실행 기준

서버 애플리케이션은 foreground로 실행한다.

- `nohup`, `&`, `Start-Job`, `Start-Process`로 서버를 background 실행하지 않는다.
- 앱 로그는 현재 터미널에 출력한다.
- 스크립트 종료는 앱 프로세스 종료와 연결한다.
- Docker 의존 서비스만 `docker compose up -d`로 background 실행할 수 있다.
- 앱 자체가 Docker 서비스이면 사용자가 명시하지 않는 한 foreground로 실행한다.

## Docker 의존 서비스 기준

사용자가 명시한 서비스만 구성한다.

- PostgreSQL
- Redis
- MySQL
- MariaDB
- MongoDB
- Elasticsearch
- Kafka
- RabbitMQ

상태 저장 서비스는 named volume을 사용한다.

- 로컬 기본 포트는 env로 분리한다.
- 비밀값은 실제 값으로 만들지 않는다.
- 운영용 Compose는 사용자가 명시한 경우에만 만든다.
- `prod` 스크립트는 로컬 Docker 의존 서비스를 자동 실행하지 않는다.

## 세부 생성 기준

구체적인 파일 작성 규칙은 `workflow/script-generation.md`를 따른다.

## 완료 조건

작업 완료 전에 아래를 확인한다.

- `local`, `dev`, `prod`의 책임이 분리되어 있다.
- `.sh`와 `.ps1`이 같은 명령 책임을 제공한다.
- `up`은 앱 서버를 foreground로 실행한다.
- `down`은 Docker 의존 서비스를 종료한다.
- env 예시 파일에는 필요한 키만 포함되어 있다.
- 실제 비밀값은 포함되어 있지 않다.
- 가능한 범위에서 문법 검증을 수행했다.

## 이력관리

- 2026-07-08: 요청 범위 우선 생성 기준을 추가했다.
