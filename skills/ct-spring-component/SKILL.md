---
name: ct-spring-component
description: 사용자가 `ct-spring-component service-log`처럼 Spring 컴포넌트 이름까지 명시해 호출할 때만 사용한다. 미리 정의된 Spring 컴포넌트 묶음을 프로젝트 컨벤션에 맞춰 추가하고 적용 지점까지 반영한다.
---

# CT Spring Component

## 목적

이 스킬은 Spring 프로젝트에 정해진 컴포넌트 묶음을 추가한다.

- 호출 형식: `ct-spring-component <component-name>`
- 현재 허용 컴포넌트: `service-log`, `jwt-auth`, `exception-handler`, `api-response`
- 자동 문맥 호출은 사용하지 않는다.
- 컴포넌트별 상세 규칙은 `components/<component-name>.md`를 따른다.

## 호출 기준

명시 호출만 처리한다.

- 허용 호출:
  - `ct-spring-component`
  - `$ct-spring-component`
  - `ct-spring-component <component-name>`
  - `$ct-spring-component <component-name>`
- 허용 component-name: `service-log`, `jwt-auth`, `exception-handler`, `api-response`
- 컴포넌트 이름 없이 호출하면 목록만 출력하고 중단한다.
- 명령어 없이 자연어만 있는 요청은 처리하지 않는다.

## 실행 전 확인

컴포넌트 작업 전에 저장소 상태와 프로젝트 기준을 확인한다.

- `AGENTS.md`
- `.0_my/core_project.md`
- `.0_my/core_code_style.md`
- `.0_my/core_workflow.md`
- `build.gradle`, `build.gradle.kts`, `pom.xml`
- `src/main/java` 패키지 구조
- 기존 `annotation`, `aop`, `helper`, `service` 패키지
- 동일 컴포넌트 기존 구현 여부
- Java 버전
- Spring Boot 또는 Spring Framework 버전
- Gradle 또는 Maven 의존성 관리 방식

## 공통 절차

정해진 순서로 처리한다.

1. 호출에서 컴포넌트 이름을 추출한다.
2. 컴포넌트 이름이 없으면 허용 컴포넌트 목록과 용도만 안내하고 중단한다.
3. `components/<component-name>.md`가 있는지 확인한다.
4. 컴포넌트 문서가 없으면 허용 컴포넌트 목록만 안내하고 중단한다.
5. 컴포넌트 문서를 읽고 생성 파일, 수정 파일, 적용 지점, 검증 기준을 확인한다.
6. 프로젝트 기준 파일과 패키지 구조를 확인한다.
7. Java와 Spring 버전을 확인하고 컴포넌트 문서의 버전 기준을 적용한다.
8. 기존 구현이 있으면 중복 생성하지 않고 보완 또는 적용만 수행한다.
9. 대상 메소드가 요청에 없으면 대상 클래스와 메소드 목록을 한 번만 요청한다.
10. 필요한 파일을 생성 또는 수정한다.
11. 빌드 파일 의존성, import, 어노테이션 적용 위치를 확인한다.
12. 가능한 검증 명령을 실행하고 결과를 보고한다.

## 컴포넌트 목록 출력

컴포넌트 이름 없이 호출하면 목록만 보여준다.

- `service-log`: Service 메소드 실행 로그를 AOP로 남긴다.
- `jwt-auth`: Access Token 기반 JWT 인증 흐름을 구성한다.
- `exception-handler`: REST API 공통 예외 응답 흐름을 구성한다.
- `api-response`: REST API 공통 응답 래퍼와 페이징 응답 구조를 구성한다.

출력 예시:

```text
사용 가능한 Spring 컴포넌트입니다.

- service-log: Service 메소드 실행 로그 AOP
- jwt-auth: Access Token 기반 JWT 인증
- exception-handler: 공통 예외 응답 처리
- api-response: 공통 API 응답/페이징 응답

사용 예시:
- ct-spring-component service-log
- ct-spring-component jwt-auth
```

## 적용 원칙

프로젝트 컨벤션을 우선한다.

- 패키지 루트는 `@SpringBootApplication` 위치와 기존 패키지 구조로 판단한다.
- 기존 패키지가 있으면 같은 이름의 패키지를 우선 사용한다.
- 기존 패키지가 없으면 컴포넌트 책임에 맞는 패키지를 스스로 판단해 생성한다.
- 신규 패키지는 `@SpringBootApplication` 루트 패키지 하위에 둔다.
- 패키지 위치 판단이 애매하면 의심 항목으로 보고한다.
- Lombok 사용 여부는 빌드 파일과 기존 코드로 판단한다.
- Java 문법과 API는 프로젝트의 Java 버전에 맞춘다.
- Spring 관련 import와 의존성은 프로젝트의 Spring Boot 또는 Spring Framework 버전에 맞춘다.
- Java와 Spring 버전이 확인되면 해당 버전에서 권장되는 최신 문법과 API를 우선 사용한다.
- 하위 버전 호환 문법은 프로젝트 버전 판단이 불가능하거나 기존 코드가 명확히 보수적일 때만 사용한다.
- 최신 API를 쓰면 기존 코드 스타일과 충돌하는 경우 프로젝트 컨벤션을 우선하고 의심 항목으로 보고한다.
- 이미 존재하는 클래스는 덮어쓰지 않고 현재 구현을 읽은 뒤 필요한 차이만 반영한다.
- 어노테이션은 구현체 메소드에 적용하는 것을 기본으로 한다.
- 인터페이스 메소드 적용은 기존 프로젝트가 그 방식을 쓰는 경우에만 따른다.

## 버전 판단

버전은 빌드 파일에서 먼저 확인한다.

- Gradle:
  - `java.toolchain.languageVersion`
  - `sourceCompatibility`
  - `targetCompatibility`
  - `org.springframework.boot` 플러그인 버전
- Maven:
  - `java.version`
  - `maven.compiler.source`
  - `maven.compiler.target`
  - `spring-boot-starter-parent` 버전
  - `spring-boot.version` 속성
- 빌드 파일에서 확인되지 않으면 기존 소스의 문법과 import를 기준으로 보수적으로 판단한다.
- 버전 판단이 불가능하면 Java 8 호환 문법을 기본으로 사용하고, 의존성 변경은 사용자 확인 후 진행한다.

## 출력 형식

작업 결과는 짧게 보고한다.

- 확인한 기준 파일
- 생성 파일
- 수정 파일
- 어노테이션 적용 메소드
- 검증 결과
- 미적용 항목과 사유

## 스킬 검토 원칙

스킬 자체를 검토할 때는 기존 도구를 우선 사용한다.

- 스킬 검토를 위해 검증용 `*.py` 파일을 새로 만들지 않는다.
- 기존 스킬 검증 스크립트가 있으면 사용할 수 있다.
- 기존 검증 스크립트가 의존성 문제로 실패하면 실패 사유를 보고하고 중단한다.
- 스킬 검토를 위해 Python 패키지를 설치하거나 새 스크립트를 만들지 않는다.
- 컴포넌트 적용 후 코드 검증은 프로젝트의 빌드 도구, 테스트 명령, `rg` 검색 결과를 우선한다.
- 컴포넌트 적용 후 로그 출력 대상은 스스로 1차 검토한다.
- 계정 정보, 요청 파라미터, DTO 전체 출력 여부를 확인한다.
- 민감정보 노출 가능성이 있으면 의심 항목으로 보고한다.
- 명확히 위험한 로그 출력은 보완 대상으로 분류한다.

## 금지

반드시 막아야 할 항목만 제한한다.

- 컴포넌트 문서가 없는 이름을 추정해서 만들지 않는다.
- 대상 메소드가 불명확한데 임의로 어노테이션을 붙이지 않는다.
- 기존 클래스가 있는데 동일 목적 클래스를 중복 생성하지 않는다.
- 프로젝트 빌드 도구가 확인되지 않았는데 의존성을 임의로 추가하지 않는다.
- 민감 정보가 포함될 수 있는 값을 로그에 추가 수집하지 않는다.
