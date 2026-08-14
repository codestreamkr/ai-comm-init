# ct-init-java

Java 프로젝트의 README 기준을 만든다.

## 근거 수집

- `README.md`, `AGENTS.md`
- `--migrate`에서는 기존 `.docs/core_*.md`
- `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle`
- Maven Wrapper, Gradle Wrapper, `.mvn/**`, `gradle/**`
- `src/main/java/**`, `src/test/java/**`, `src/main/resources/**`
- 실행 스크립트와 CI 설정

## Java 실행 환경 확인

- Java 대상 버전은 Maven Compiler Plugin의 `release`, `source`·`target`, Maven 속성 순서로 추출한다.
- Gradle은 toolchain, `sourceCompatibility`, `targetCompatibility` 순서로 추출한다.
- 실제 CLI JDK 경로는 기존 README의 `## 개발 환경`을 우선한다.
- 기존 README에 JDK 경로가 있으면 최종 README의 개발 환경 섹션에 포함한다.
- 경로가 없으면 프로젝트 스크립트, Toolchains, CI 설정, 프로젝트 인접 도구 경로 순서로 확인한다.
- 경로를 확인하지 못하면 경로를 추측하지 않는다.
- Java 대상 버전과 실제 CLI Java 버전이 다르면 README에 불일치 원인과 해결 기준을 기록한다.
- 재실행 시 기존 개발 환경 설정을 표준 README 구조에 맞게 배치하되 누락하지 않는다.

## README 표준 구조

````markdown
# {PROJECT_NAME}

{PROJECT_SUMMARY}

<!-- ct-init:readme:start -->
## 프로젝트 개요
## 기술 스택
## 개발 환경

빌드와 테스트에 사용하는 Java와 도구 기준이다.

- 프로젝트 Java 대상 버전: `{JAVA_VERSION}`
- JDK 경로: `{JAVA_HOME_OR_CHECK_REQUIRED}`
- 빌드 도구와 버전: `{BUILD_TOOL_VERSION}`
- 인코딩: `{ENCODING}`

### 실행 환경 확인

```powershell
{ENVIRONMENT_SETUP_COMMAND}
{BUILD_TOOL_VERSION_COMMAND}
```

- CLI Java version은 프로젝트 Java 대상 버전과 일치해야 한다.
- 일치하지 않으면 빌드, 테스트, 실행을 수행하지 않는다.

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
````

`## 개발 환경`은 표준 README에 포함한다. 재실행 시 기존 설정을 입력으로 사용해 최종 README의 해당 섹션에 반영한다.

## Java 섹션 작성 기준

- 빌드에는 기본 패키징 명령, Maven·Gradle profile, 산출물을 기록한다.
- 테스트에는 표준 테스트 명령과 테스트 skip 해제 조건을 기록한다.
- 로컬 실행에는 실행 명령, 필요한 profile, 포트 근거를 기록한다.
- 환경과 설정에는 설정 파일과 profile별 영향 범위를 기록한다.
- 변경 영향 확인에는 Java, JSP, SQL XML, 설정, CI 파일의 연결 확인 기준을 기록한다.
- 실제 파일에서 확인하지 못한 명령·버전·경로는 추정하지 않는다.
