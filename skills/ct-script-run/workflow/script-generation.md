# 스크립트 생성 기준

## 구성

- 요청 범위와 프로젝트 감지
- 환경별 실행 명령과 OS별 스크립트
- env와 Docker Compose
- 검증과 결과 보고

## 기준

프로젝트의 실제 실행 방식을 기준으로 스크립트를 만든다.

## 0. 요청 범위

사용자가 요청한 파일과 환경을 우선한다.

- `scripts/local.sh`처럼 특정 파일을 요청하면 그 파일과 직접 필요한 env 예시만 만든다.
- `local`만 요청하면 `scripts/local.sh`, `scripts/local.ps1`을 같은 책임으로 맞춘다.
- `sh` 또는 `ps1`만 요청하면 해당 OS 스크립트만 만든다.
- Docker 의존 서비스만 요청하면 Compose와 env 예시만 만들고 앱 실행 스크립트는 만들지 않는다.
- 범위가 없고 실행 스크립트 세트를 요청하면 `local`, `dev`, `prod`를 기본 범위로 삼는다.

## 1. 프로젝트 감지

아래 파일을 우선 확인한다.

- Node.js: `package.json`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`
- Java/Spring: `pom.xml`, `build.gradle`, `gradlew`, `mvnw`
- Python: `pyproject.toml`, `requirements.txt`, `uv.lock`, `Pipfile`
- Docker: `Dockerfile`, `docker-compose.yml`, `compose.yaml`
- 공통: `Makefile`, `.env.example`, `.docs/core_workflow.md`, `AGENTS.md`

### core_workflow 명령 대조

실행 명령은 프로젝트 설정과 문서가 일치하는지 확인한 뒤 선택한다.

1. 기존 환경별 `scripts/*`, launcher와 `Makefile` target에서 프로젝트가 사용 중인 실행 진입점을 찾는다.
2. 빌드 파일, package script, wrapper와 lockfile에서 해당 진입점이 호출하는 task·script·산출물이 유효한지 확인한다.
3. `.docs/core_workflow.md`와 README의 명령을 대조한다.
4. 기존 launcher가 유효하면 launcher 명령을 유지하고, 삭제된 task나 존재하지 않는 산출물을 호출하면 빌드 설정으로 바로잡는다.
5. 실행 진입점과 설정 또는 문서가 충돌하면 선택 근거와 차이를 결과에 기록한다.
6. 문서 갱신 요청이 없으면 `core_workflow.md`는 변경하지 않는다.

## 2. 미정의 언어 처리

정의된 언어가 아니거나 언어를 확정할 수 없으면 Generic 모드로 처리한다.

### 실행 명령 탐색

기존 단서를 우선한다.

- `Makefile`
- `Dockerfile`
- `compose.yaml`
- `docker-compose.yml`
- `scripts/*`
- README의 실행 명령

### Generic 생성 기준

실행 명령을 확정할 수 있으면 같은 기준으로 스크립트를 만든다.

- `up`
- `down`
- `.sh`
- `.ps1`
- env 예시
- 요청된 Docker 의존 서비스

### 실행 명령이 불명확한 경우

앱 실행 명령이 불명확하면 사용자에게 필요한 값만 묻는다.

- Docker 의존 서비스와 env 예시는 만들 수 있다.
- 서버 foreground 실행 명령은 placeholder로 만들지 않는다.
- `TODO` 명령을 넣은 실행 스크립트는 만들지 않는다.
- Dockerfile만 있고 실행 명령이 없으면 `docker build`나 `docker run`을 임의로 만들지 않는다.
- README 실행 명령은 참고하되 실제 파일과 충돌하면 파일 기준을 우선한다.

### Makefile 후보

`Makefile`이 있으면 아래 target을 우선 후보로 본다.

- `run`
- `dev`
- `start`
- `serve`

## 3. 환경별 역할

### `local`

로컬 개발자가 바로 실행하는 기본 환경이다.

- 로컬 env 예시를 기준으로 실행한다.
- Docker 의존 서비스를 요청받은 경우 `up`에서 먼저 실행한다.
- 서버 애플리케이션은 foreground로 실행한다.
- DB 마이그레이션은 기존 프로젝트 관례가 있을 때만 포함한다.

### `dev`

개발 환경 실행 또는 개발 배포 기준이다.

- dev env 값을 사용한다.
- 빌드가 필요한 프로젝트는 빌드 후 실행한다.
- Docker 기반 개발 환경이 이미 있으면 기존 구성을 우선한다.
- 의존 서비스 자동 실행은 요청이 있거나 기존 관례가 있을 때만 포함한다.

### `prod`

운영 실행 기준이다.

- prod env 값을 사용한다.
- 운영 빌드 또는 운영 실행 명령을 사용한다.
- 로컬 Docker 의존 서비스를 자동 실행하지 않는다.
- destructive 명령은 포함하지 않는다.
- 마이그레이션 자동 실행은 기존 운영 관례가 있을 때만 포함한다.

## 3-1. 실행 명령 선택

런타임별 기존 관례를 우선한다.

### 공통 기준

- 기존 환경별 `scripts/*`, launcher와 `Makefile` target을 실행 진입점으로 우선 확인한다.
- 빌드 파일, package script, wrapper와 lockfile로 진입점의 유효성을 확인한다.
- launcher가 유효하면 기존 명령을 유지하고, 유효하지 않으면 빌드 설정에 존재하는 명령을 선택한다.
- README와 `.docs/core_workflow.md`는 선택한 명령과 정합성을 대조한다.
- package script, Gradle task, Maven goal이 여러 개 있으면 환경 역할에 맞는 명령을 선택한다.
- 실행 명령이 불명확하면 임의로 조합하지 않고 필요한 값만 사용자에게 묻는다.

### Node.js

패키지 매니저는 lockfile 기준으로 선택한다.

- `pnpm-lock.yaml`: `pnpm`
- `yarn.lock`: `yarn`
- `package-lock.json`: `npm`
- lockfile이 없고 `packageManager` 필드가 있으면 해당 값을 사용한다.
- 둘 다 없으면 기존 문서나 스크립트의 명령을 우선하고, 없으면 `npm`을 기본 후보로 둔다.

환경별 package script는 아래 순서로 고른다.

- `local`: `dev`, `start`
- `dev`: `dev`, `build` 후 `start`
- `prod`: `build` 후 `start`, `start`

### Java/Spring

wrapper가 있으면 wrapper를 우선한다.

- Gradle: `./gradlew`, 없으면 `gradle`
- Maven: `./mvnw`, 없으면 `mvn`

환경별 실행 명령은 아래 순서로 고른다.

- `local`: `bootRun`, `run`, `spring-boot:run`
- `dev`: 빌드가 필요하면 `build` 또는 `package` 후 실행
- `prod`: 빌드 산출물 실행 또는 기존 운영 실행 명령

빌드 산출물 실행은 산출물 경로가 명확할 때만 사용한다.

- Gradle: `build/libs/*.jar`
- Maven: `target/*.jar`
- 산출물이 여러 개면 기존 문서나 build 설정으로 실행 대상을 확인한다.
- 실행 대상이 불명확하면 `java -jar` 명령을 임의로 만들지 않는다.

## 4. 명령

각 스크립트는 기본적으로 `up`, `down`만 제공한다.

### 빈 인자

아무 명령도 받지 않으면 사용법을 출력하고 종료한다.

- 기본 명령 목록을 보여준다.
- 예시 실행 명령을 보여준다.
- 필요한 env 파일 경로를 보여준다.
- 앱 서버나 Docker 서비스를 실행하지 않는다.

예시:

```text
Usage: ./scripts/local.sh <command>

Commands:
  up    Start dependencies and run the application in foreground.
  down  Stop Docker dependencies.

Examples:
  ./scripts/local.sh up
  ./scripts/local.sh down

Env:
  .env.local
```

### `up`

실행 전체를 담당한다.

- env 파일 로드
- Docker 의존 서비스 실행
- 필요 시 서비스 준비 대기
- 앱 서버 foreground 실행

### 앱 프로세스 lifecycle

앱 로그와 종료 상태는 스크립트를 실행한 터미널에 연결한다.

- 호스트에서 앱을 실행하면 마지막 foreground 프로세스로 실행하고 종료 코드를 그대로 반환한다.
- Docker 앱 서비스는 `docker compose up --exit-code-from <app-service> <app-service>`로 foreground 실행하고 선택한 앱 서비스의 종료 코드를 스크립트 결과로 전달한다.
- Docker 의존 서비스만 앱 실행 전에 detached로 시작할 수 있다.
- 중단 신호가 들어오면 앱 프로세스 또는 앱 컨테이너가 함께 종료되도록 구성한다.
- `--exit-code-from`이 시작한 의존 서비스의 종료·정리 범위는 해당 환경의 `down` 책임과 일치시킨다.
- 앱 로그는 별도 파일이나 background job으로 보내지 않고 현재 터미널에 출력한다.

예시:

```sh
docker compose up -d postgresql redis
npm run dev
```

### `down`

Docker 기반 실행 요소를 정리한다.

- Docker 의존 서비스 종료
- 앱이 Docker 서비스로 실행된 경우 앱 서비스 종료
- named volume 유지
- DB 초기화, 캐시 삭제, volume 삭제 제외

예시:

```sh
docker compose stop postgresql redis
docker compose rm -f postgresql redis
```

### 선택 명령

아래 명령은 필요할 때만 추가한다.

- `status`: Docker 서비스 상태와 포트 상태 확인
- `logs`: Docker 의존 서비스 로그 확인
- `check`: env, Docker, 런타임, 앱 실행 명령 점검
- `app` 또는 `run`: 앱만 따로 실행해야 하는 요구가 명확할 때 추가

## 5. `.sh` 작성 기준

macOS/Linux 기준으로 작성한다.

```sh
#!/usr/bin/env bash
set -euo pipefail
```

- 스크립트 위치 기준으로 프로젝트 루트를 계산한다.
- env 파일이 없으면 어떤 example 파일을 복사해야 하는지 안내한다.
- env 로드는 `KEY=VALUE` 줄만 파싱해 export한다.
- 주석, 빈 줄, 잘못된 키 이름은 건너뛴다.
- env 파일을 shell 스크립트로 실행하지 않는다.
- 서버 실행은 foreground 명령으로 끝난다.
- 서버 실행에 `nohup` 또는 `&` background 실행을 사용하지 않는다.
- Docker 앱 실행에 `-d` 또는 `--detach`를 사용하지 않는다.
- `chmod +x scripts/*.sh`를 적용한다.

### `.sh` 필수 구성

반복되는 골격은 같은 순서로 둔다.

- shebang과 strict mode
- 프로젝트 루트 계산
- env 파일 경로 결정
- usage 출력 함수
- env 로드 함수
- Docker Compose 실행 함수
- 명령 dispatch
- foreground 앱 실행

## 6. `.ps1` 작성 기준

Windows PowerShell 5.1 이상과 PowerShell 7을 기준으로 작성한다.

```powershell
$ErrorActionPreference = "Stop"
```

- 스크립트 위치 기준으로 프로젝트 루트를 계산한다.
- env 파일이 없으면 어떤 example 파일을 복사해야 하는지 안내한다.
- env 파일은 주석과 빈 줄을 건너뛰고 process 환경변수로 로드한다.
- 서버 실행은 foreground 명령으로 끝난다.
- `Start-Job`, `Start-Process`는 서버 실행에 사용하지 않는다.
- Docker 앱 실행에 `-d` 또는 `--detach`를 사용하지 않는다.

### `.ps1` 필수 구성

반복되는 골격은 `.sh`와 같은 책임으로 둔다.

- `$ErrorActionPreference = "Stop"`
- 프로젝트 루트 계산
- env 파일 경로 결정
- usage 출력 함수
- env 로드 함수
- Docker Compose 실행 함수
- 명령 dispatch
- foreground 앱 실행

## 7. env 예시 생성 기준

기본 파일은 `.env.example`이다.

- 실제 비밀값은 넣지 않는다.
- 값은 빈 값 또는 명확한 placeholder로 둔다.
- 로컬에서 안전한 값만 기본값으로 둔다.
- 환경별 차이가 명확하면 `.env.local.example`, `.env.dev.example`, `.env.prod.example`을 추가한다.

Docker 의존 서비스를 추가할 때는 필요한 키만 포함한다.

- PostgreSQL: `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`
- Redis: `REDIS_HOST`, `REDIS_PORT`, 필요 시 `REDIS_PASSWORD`
- MySQL/MariaDB: DB명, 사용자, 비밀번호, 포트
- MongoDB: 사용자, 비밀번호, DB명, 포트
- Kafka/RabbitMQ/Elasticsearch: 프로젝트 연결에 필요한 최소 키

### env 값 기준

로컬 실행에 필요한 값은 안전한 기본값을 둔다.

- 로컬 DB 사용자, DB명, 포트는 Compose와 맞는 기본값을 둔다.
- 로컬 DB 비밀번호는 예시용 값을 둔다.
- 외부 서비스 토큰, API 키, 운영 비밀번호는 빈 값으로 둔다.
- 운영 env 예시에는 실제 값이나 예시용 비밀번호를 넣지 않는다.
- Compose에서 필수인 값은 로컬 env 예시에서 비워 두지 않는다.

## 8. Docker Compose 기준

기존 Compose 파일이 있으면 기존 구조를 우선한다.

- 새 파일보다 기존 파일 갱신을 우선한다.
- 서비스명은 명확한 소문자 이름을 사용한다.
- 상태 저장 서비스는 named volume을 사용한다.
- 포트는 env 치환으로 둔다.
- healthcheck는 앱 실행 전에 준비 대기가 필요한 경우에만 추가한다.
- 운영용 설정은 사용자가 명시한 경우에만 만든다.

### 종료 기준

생성한 의존 서비스만 종료한다.

- 새 Compose 파일이 의존 서비스 전용이면 `docker compose down`을 사용할 수 있다.
- 기존 Compose 파일에 서비스를 추가한 경우 `docker compose stop <service...>`와 `docker compose rm -f <service...>`를 우선한다.
- 기존 앱 서비스, 프록시, 관측 도구는 사용자가 요청한 경우에만 종료 대상에 포함한다.
- named volume은 유지한다.

예시:

```yaml
services:
  postgresql:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgresql_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "${REDIS_PORT:-6379}:6379"
    volumes:
      - redis_data:/data

volumes:
  postgresql_data:
  redis_data:
```

## 9. 검증

가능한 검증만 수행한다.

- `bash -n scripts/local.sh`
- `bash -n scripts/dev.sh`
- `bash -n scripts/prod.sh`
- PowerShell이 있으면 `pwsh -NoProfile -Command { ... }` 형태의 파싱 검증
- `docker compose config`
- 프로젝트별 dry-run 또는 help 명령

## 10. 보고

작업 후 아래 항목만 보고한다.

- 생성/수정한 파일
- 각 환경의 실행 명령
- Docker 의존 서비스 구성 여부
- 수행한 검증
- 사용자가 채워야 할 env 키
- 프로젝트 설정과 `core_workflow.md`의 명령 차이

## 이력관리

- 2026-07-13: launcher·Makefile·빌드 설정의 실행 명령 우선순위, core_workflow 대조 절차, Docker 앱 foreground 로그·종료 코드 전달과 background 실행 차단 기준을 정리했다.
- 2026-07-08: 요청 범위, env 값, Compose 종료 기준, 실행 명령 선택, 스크립트 필수 구성을 추가했다.
