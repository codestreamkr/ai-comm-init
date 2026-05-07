# Exception Handler 컴포넌트

## 목적

`exception-handler`는 Spring MVC/REST API의 공통 예외 응답 흐름을 구성한다.

- 생성 대상:
  - `exception/GlobalExceptionHandler.java`
  - `exception/CustomException.java`
  - `exception/CustomErrorCodeEnum.java` 또는 기존 ErrorCode 타입
- 수정 대상:
  - `model/ApiResponse.java` 또는 기존 공통 응답 모델
  - Security 401/403 응답 처리부가 있는 경우
  - Controller 개별 `try-catch`가 공통 예외 처리와 중복되는 경우
- 적용 방식:
  - 매핑된 비즈니스 예외는 프로젝트 ErrorCode 기준으로 응답한다.
  - 검증/바인딩 예외는 공통 validation 오류 응답으로 변환한다.
  - 미매핑 5xx 예외는 내부 메시지를 응답에 노출하지 않는다.
  - 실제 예외 메시지와 stack trace는 서버 로그에만 남긴다.

## 선행 확인

작업 전에 필요한 파일을 확인한다.

- 빌드 파일:
  - `build.gradle`
  - `build.gradle.kts`
  - `pom.xml`
- 패키지 루트:
  - `@SpringBootApplication` 클래스 위치
- 기존 패키지:
  - `exception`
  - `model`
  - `controller`
  - `config`
- 기존 구현:
  - `GlobalExceptionHandler`
  - `CustomException`
  - `CustomErrorCodeEnum`, `ErrorCode`
  - `ApiResponse`, `ErrorResponse`, `ProblemDetail`
  - Security `authenticationEntryPoint`, `accessDeniedHandler`
  - Controller 개별 `try-catch`
- 버전 기준:
  - Java 버전
  - Spring Boot 버전
  - Spring Framework 버전
  - Validation 패키지 기준
  - Lombok 사용 여부

## 생성 규칙

파일은 기존 패키지 구조에 맞춰 만든다.

- 기존 `exception`, `model` 패키지가 있으면 우선 사용한다.
- 기존 패키지가 없으면 컴포넌트 책임에 맞춰 필요한 패키지를 생성한다.
- 신규 패키지는 `@SpringBootApplication` 루트 패키지 하위에 둔다.
- 패키지 위치 판단이 애매하면 의심 항목으로 보고한다.
- 기능이 없으면 신규 생성한다.
- 기능 일부만 있으면 기존 구현을 보존하고 부족한 구성만 추가한다.

### 버전 호환 기준

생성 코드는 프로젝트 버전을 따른다.

- Java와 Spring 버전이 확인되면 해당 버전에서 권장되는 최신 문법과 API를 우선 사용한다.
- 하위 버전 호환 문법은 프로젝트 버전 판단이 불가능하거나 기존 코드가 명확히 보수적일 때만 사용한다.
- Spring Boot 3.x:
  - `jakarta.validation.*` 기준으로 작성한다.
  - REST API 전용이면 `@RestControllerAdvice`를 우선 사용한다.
  - `ProblemDetail`은 기존 프로젝트 응답 포맷이 없을 때만 검토한다.
- Spring Boot 2.x:
  - 기존 코드가 `javax.validation.*` 기반이면 유지한다.
  - 기존 `@ControllerAdvice`/`@RestControllerAdvice` 사용 방식을 우선한다.
- Java 17 이상:
  - 기존 코드 스타일과 맞으면 field error DTO에 `record`를 사용할 수 있다.
- Java 21 이상:
  - 기존 코드 스타일과 맞으면 Java 21 기준으로 안정화된 최신 문법과 표준 API를 사용할 수 있다.
- Lombok 있음:
  - 기존 코드가 Lombok을 쓰면 `@Getter`, `@Slf4j`, `@RequiredArgsConstructor`를 사용할 수 있다.
- Lombok 없음:
  - 생성자와 getter를 직접 작성하고 `LoggerFactory.getLogger(...)`를 사용한다.

## 예외 매핑 규칙

클라이언트 응답 메시지는 명시된 매핑 기준을 따른다.

- 매핑된 `CustomException`:
  - 예외가 가진 ErrorCode의 HTTP 상태를 사용한다.
  - 예외가 사용자 노출용 detail message를 명시하면 그 메시지를 사용할 수 있다.
  - detail message가 내부 구현 정보를 담을 수 있으면 ErrorCode 기본 메시지를 사용한다.
- 미매핑 5xx 예외:
  - `e.getMessage()`를 클라이언트 응답에 사용하지 않는다.
  - 공통 ErrorCode의 기본 메시지를 사용한다.
  - 예: `INTERNAL_SERVER_ERROR` -> `"서버 내부 오류가 발생했습니다."`
- 예외 원문 메시지:
  - 서버 로그에만 남긴다.
  - 클라이언트 응답에는 내부 SQL, 파일 경로, 토큰, 설정값, stack trace를 포함하지 않는다.
- 도메인별로 노출 가능한 5xx 메시지가 필요하면 ErrorCode enum에 명시적으로 추가한다.

## 처리 대상 예외

프로젝트에 필요한 예외를 우선 처리한다.

- 필수 후보:
  - `CustomException`
  - `MethodArgumentNotValidException`
  - `IllegalArgumentException`
  - `MethodArgumentTypeMismatchException`
  - `Exception`
- 추가 검토 후보:
  - `BindException`
  - `ConstraintViolationException`
  - `HttpMessageNotReadableException`
  - `NoHandlerFoundException`
  - `AccessDeniedException`
  - `AuthenticationException`
- Security 401/403은 Security 설정에서 직접 처리하는 경우가 있으므로 기존 흐름과 응답 포맷을 대조한다.

## Validation 응답 규칙

검증 오류는 클라이언트가 바로 사용할 수 있게 정리한다.

- 필드 오류는 필드명과 메시지를 포함한다.
- rejected value는 개인정보 가능성이 있으므로 기본 응답에서 제외한다.
- 여러 필드 오류가 있으면 모두 반환한다.
- 같은 필드에 오류가 여러 개 있으면 기존 프로젝트 정책에 따라 첫 오류 또는 목록 응답을 선택한다.
- `Map<String, String>`을 기존 프로젝트가 쓰면 유지할 수 있다.
- 신규 생성이면 field error DTO 또는 `Map<String, String>` 중 더 단순한 구조를 선택한다.

## 로그 규칙

오류 책임에 따라 로그 레벨을 나눈다.

- 4xx 계열:
  - 기본은 `warn` 또는 메시지 중심 로그를 사용한다.
  - validation 오류마다 stack trace를 남기지 않는다.
- 5xx 계열:
  - `error` 로그와 stack trace를 남긴다.
  - 내부 메시지는 로그에만 남긴다.
- 민감정보:
  - token, password, secret, API key, 주민번호, 전화번호, 주소, 이메일 원문은 로그에 남기지 않는다.

## 기존 구현 처리

이미 구현되어 있으면 중복 생성하지 않는다.

- `GlobalExceptionHandler`가 있으면 처리 예외 범위, 응답 포맷, 로그 레벨, 5xx 메시지 노출 여부를 확인한다.
- `CustomException`이 있으면 ErrorCode 보관, detail message, data 보관 방식만 확인한다.
- ErrorCode enum이 있으면 HTTP status, code, 기본 메시지 구성을 확인한다.
- `ApiResponse`가 있으면 에러 응답 생성 방식만 확인한다.
- 기존 구현이 요구 기준과 크게 다르면 자동 수정하지 않고 차이와 조치안을 먼저 안내한다.

## 검증 기준

가능한 범위에서 검증한다.

- 컴파일 검증:
  - Gradle: `./gradlew compileJava`
  - Maven: `./mvnw compile`
- 검색 검증:
  - `GlobalExceptionHandler` 생성 위치
  - `@RestControllerAdvice` 또는 기존 Advice 방식
  - `Exception.class` 처리에서 `e.getMessage()` 응답 노출 여부
  - validation 예외 처리 여부
  - Security 401/403 응답 포맷 정합성
  - Controller 개별 `try-catch` 중복 여부
- 테스트가 있으면 관련 Controller/Exception 테스트를 우선 실행한다.

## 결과 보고

최종 보고에는 필요한 정보만 남긴다.

- 생성 파일
- 수정 파일
- 처리 예외 목록
- 5xx 응답 메시지 매핑 기준
- validation 응답 구조
- 검증 명령과 결과
- 의심 항목
- 남은 확인 항목
