# Service Log 컴포넌트

## 목적

`service-log`는 Service 메소드 실행 로그를 AOP로 남긴다.

- 생성 대상:
  - `annotation/ServiceLog.java`
  - `aop/ServiceLogAspect.java`
  - `helper/ServiceLogHelper.java`
- 수정 대상:
  - 사용자가 지정한 Service 구현체 메소드
  - 필요 시 빌드 파일의 AOP 의존성
- 적용 방식:
  - 대상 메소드에 `@ServiceLog` 선언
  - 메소드 내부 상세 로그는 `ServiceLogAspect.log(...)` 사용

## 선행 확인

작업 전에 필요한 파일을 확인한다.

- 빌드 파일:
  - `build.gradle`
  - `build.gradle.kts`
  - `pom.xml`
- 패키지 루트:
  - `@SpringBootApplication` 클래스 위치
- 기존 패키지:
  - `annotation`
  - `aop`
  - `helper`
  - `service`
  - `service.impl`
- 기존 구현:
  - `ServiceLog`
  - `ServiceLogAspect`
  - `ServiceLogHelper`
  - 기존 `@ServiceLog` 사용처
  - 기존 `ServiceLogAspect.log(...)` 사용처
- 버전 기준:
  - Java 버전
  - Spring Boot 버전
  - Spring Framework 버전
  - Lombok 사용 여부
  - AOP 의존성 선언 방식

## 입력 기준

대상 메소드는 명확해야 한다.

- 허용 입력:
  - 클래스명 + 메소드명
  - 전체 경로 + 메소드명
  - 여러 메소드 목록
- 예시:
  - `MemberServiceImpl.updateMember`
  - `kr.codestream.lawni.service.impl.MemberServiceImpl.updateMember`
- 대상 메소드가 없으면 한 번만 요청한다.

## 생성 규칙

파일은 기존 패키지 구조에 맞춰 만든다.

- 기존 `annotation`, `aop`, `helper` 패키지가 있으면 우선 사용한다.
- 기존 패키지가 없으면 컴포넌트 책임에 맞춰 필요한 패키지를 생성한다.
- 신규 패키지는 `@SpringBootApplication` 루트 패키지 하위에 둔다.
- 패키지 위치 판단이 애매하면 의심 항목으로 보고한다.

### 버전 호환 기준

생성 코드는 프로젝트 버전을 따른다.

- Java와 Spring 버전이 확인되면 해당 버전에서 권장되는 최신 문법과 API를 우선 사용한다.
- 하위 버전 호환 문법은 프로젝트 버전 판단이 불가능하거나 기존 코드가 명확히 보수적일 때만 사용한다.
- 최신 API를 쓰면 기존 코드 스타일과 충돌하는 경우 프로젝트 컨벤션을 우선하고 의심 항목으로 보고한다.
- Java 8 이상:
  - `ThreadLocal`, `Deque`, `ArrayDeque` 사용 가능
  - 프로젝트 Java 버전이 8로 확인되면 `var`, `record`, `List.of`, `Stream.toList`, `List.getFirst`, 텍스트 블록 사용 안 함
- Java 9 이상:
  - 기존 프로젝트가 이미 사용하는 경우에만 Java 9 이상 API를 사용한다.
- Java 17 이상:
  - 기존 코드 스타일과 맞으면 Java 17 이상에서 권장되는 문법과 표준 API를 사용할 수 있다.
- Java 21 이상:
  - 기존 코드 스타일과 맞으면 Java 21 기준으로 안정화된 최신 문법과 표준 API를 사용할 수 있다.
- Spring Boot 2.x:
  - Spring Framework 5 계열로 보고 `javax.*` 기반 기존 코드를 유지한다.
  - 이 컴포넌트는 기본 구현에서 `javax.*` import를 만들지 않는다.
- Spring Boot 3.x:
  - Spring Framework 6 계열로 보고 `jakarta.*` 기반 기존 코드를 유지한다.
  - 이 컴포넌트는 기본 구현에서 `jakarta.*` import를 만들지 않는다.
- Lombok 있음:
  - 기존 코드가 Lombok을 쓰면 `@Slf4j`를 사용할 수 있다.
- Lombok 없음:
  - `LoggerFactory.getLogger(...)`를 사용한다.

### ServiceLog

- 위치: `<root>.annotation.ServiceLog`
- 대상: `ElementType.METHOD`
- 보존: `RetentionPolicy.RUNTIME`
- 속성: 기본 생성 시 속성 없음

```java
package <root>.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface ServiceLog {
}
```

### ServiceLogAspect

- 위치: `<root>.aop.ServiceLogAspect`
- 어노테이션:
  - `@Aspect`
  - `@Component`
  - Lombok 사용 시 `@Slf4j`
- 포인트컷: `@Around("@annotation(serviceLog)")`
- 중첩 호출 보호:
  - `ThreadLocal<Deque<ServiceLogHelper>>`
  - `ThreadLocal.withInitial(...)` 사용 안 함
  - `@ServiceLog` 진입 시 스택이 없을 때만 생성
  - 시작 시 `push`
  - 종료 시 `pop`
  - 비어 있으면 `remove()`
- 공개 보조 메소드:
  - `log(String pattern, Object... args)`
  - `error(Throwable throwable, Object... args)`
- Java 8 호환 구현:
  - `new ThreadLocal<>()`
  - `new ArrayDeque<>()`
  - `push()`
  - `pop()`
  - `peek()`

### 중첩 로그 정책

하위 `@ServiceLog`는 별도 로그 단위로 분리한다.

- 최상위 메소드에만 `@ServiceLog`가 있으면 하나의 로그로 남긴다.
- 하위 메소드에도 `@ServiceLog`가 있으면 하위 메소드는 별도 로그로 남긴다.
- `ServiceLogAspect.log(...)`는 현재 실행 중인 가장 안쪽 `@ServiceLog`에 기록한다.
- 하나의 흐름으로 합치려면 하위 메소드에는 `@ServiceLog`를 선언하지 않는다.
- 같은 클래스 내부 호출은 Spring AOP 프록시를 타지 않으므로 하위 `@ServiceLog`가 동작하지 않는다.

### ServiceLogHelper

- 위치: `<root>.helper.ServiceLogHelper`
- 책임:
  - 로그 문자열 누적
  - 일반 로그 출력
  - 예외 로그 출력
  - 파라미터 포맷팅
  - 스택 트레이스 포맷팅
- 기본 출력:
  - 성공: `logger.info`
  - 실패: `logger.error`

## 의존성 규칙

AOP 의존성을 확인한다.

- Spring Boot Gradle:
  - `implementation 'org.springframework.boot:spring-boot-starter-aop'`
- Spring Boot Maven:
  - `spring-boot-starter-aop`
- Spring Framework Gradle:
  - `implementation 'org.springframework:spring-aop'`
  - `implementation 'org.aspectj:aspectjweaver'`
- Spring Framework Maven:
  - `org.springframework:spring-aop`
  - `org.aspectj:aspectjweaver`
- 이미 AspectJ 또는 AOP starter가 있으면 추가하지 않는다.
- 의존성이 없고 `@Aspect` 컴파일이 불가능하면 빌드 파일에 추가한다.
- Spring Boot 프로젝트는 starter를 우선 사용한다.
- Boot가 아닌 Spring 프로젝트는 `spring-aop`와 `aspectjweaver`를 함께 확인한다.
- 버전은 기존 의존성 관리에 맡긴다.
- 기존 의존성 관리가 없으면 명시 버전을 임의로 정하지 않고 사용자 확인 후 진행한다.

## 적용 규칙

대상 메소드에만 적용한다.

- `@Override`와 함께 쓰는 경우 기존 정렬 방식을 따른다.
- 트랜잭션 어노테이션이 있으면 기존 순서를 최대한 유지한다.
- 프로젝트에 정렬 기준이 없으면 아래 순서를 사용한다.

```java
@ServiceLog
@Override
@Transactional
public void targetMethod(...) {
    ...
}
```

## 상세 로그 규칙

메소드 내부 단계 로그는 필요한 경우에만 추가한다.

- 사용 형식:
  - `ServiceLogAspect.log("처리 내용: {}", value);`
  - `ServiceLogAspect.error(e);`
- 로그 메시지:
  - 처리 단계가 드러나는 짧은 문장
  - 민감 정보 제외
  - DTO 전체 출력은 기존 정책이 허용하는 경우에만 유지
- 컴포넌트 생성 후 로그 출력 대상은 스스로 1차 검토한다.
- 계정 정보, 요청 파라미터, DTO 전체 출력 여부를 확인한다.
- 민감정보 노출 가능성이 있으면 의심 항목으로 보고한다.
- 명확히 위험한 출력은 보완 대상으로 분류한다.
- `@ServiceLog` 밖에서 호출하면 로그를 남기지 않고 종료한다.
- `@ServiceLog` 밖 호출만으로 `ThreadLocal` 스택을 새로 만들지 않는다.

## 기존 구현 처리

이미 구현되어 있으면 중복 생성하지 않는다.

- `ServiceLog`가 있으면 대상 메소드 적용만 진행한다.
- `ServiceLogAspect`가 있으면 현재 포인트컷과 보조 메소드만 확인한다.
- `ServiceLogHelper`가 있으면 출력 방식과 예외 포맷만 확인한다.
- 기존 구현이 요구 기준과 크게 다르면 차이와 조치안을 먼저 안내한다.

## 검증 기준

가능한 범위에서 검증한다.

- 컴파일 검증:
  - Gradle: `./gradlew compileJava`
  - Maven: `./mvnw compile`
- 검색 검증:
  - `ServiceLog` 생성 위치
  - `ServiceLogAspect` 생성 위치
  - 대상 메소드의 `@ServiceLog`
  - `spring-boot-starter-aop` 의존성
- 테스트가 있으면 관련 테스트를 우선 실행한다.

## 결과 보고

최종 보고에는 필요한 정보만 남긴다.

- 생성 파일
- 수정 파일
- 적용 메소드
- 의존성 변경 여부
- 검증 명령과 결과
- 남은 확인 항목
