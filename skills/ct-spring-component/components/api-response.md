# API Response 컴포넌트

## 구성

- 선행 확인과 생성 계약
- 응답·상태 코드·페이징 규칙
- 기존 구현 처리와 검증

## 목적

`api-response`는 REST API 공통 응답 래퍼와 페이징 응답 구조를 구성한다.

- 생성 대상:
  - `model/ApiResponse.java`
  - `model/PageResponse.java`
- 수정 대상:
  - `exception/GlobalExceptionHandler.java`
  - Security 401/403 응답 처리부
  - Controller 응답 생성 패턴
- 적용 방식:
  - 성공/실패 응답의 공통 필드를 통일한다.
  - 실제 HTTP status와 body의 status 값을 맞춘다.
  - 페이징 응답은 Spring Data `Page<T>` 또는 기존 페이징 모델에서 생성한다.

## 선행 확인

작업 전에 필요한 파일을 확인한다.

- 빌드 파일:
  - `build.gradle`
  - `build.gradle.kts`
  - `pom.xml`
- 패키지 루트:
  - `@SpringBootApplication` 클래스 위치
- 기존 패키지:
  - `model`
  - `exception`
  - `controller`
  - `config`
- 기존 구현:
  - `ApiResponse`
  - `PageResponse`
  - `ErrorResponse`
  - `ProblemDetail`
  - `GlobalExceptionHandler`
  - Controller `ResponseEntity<ApiResponse<...>>` 사용처
- 버전 기준:
  - Java 버전
  - Spring Boot 버전
  - Spring Framework 버전
  - Spring Data 사용 여부
  - Lombok 사용 여부

## 생성 규칙

파일은 기존 패키지 구조에 맞춰 만든다.

- 기존 `model` 패키지가 있으면 우선 사용한다.
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
  - 기존 공통 응답이 없으면 `ProblemDetail` 사용 여부를 검토할 수 있다.
  - 기존 프로젝트가 자체 `ApiResponse`를 쓰면 그 구조를 우선한다.
- Spring Boot 2.x:
  - 기존 자체 응답 모델을 우선한다.
- Java 17 이상:
  - 기존 코드 스타일과 맞으면 불변 응답 DTO에 `record`를 사용할 수 있다.
- Java 21 이상:
  - 기존 코드 스타일과 맞으면 Java 21 기준으로 안정화된 최신 문법과 표준 API를 사용할 수 있다.
- Lombok 있음:
  - 기존 코드가 Lombok을 쓰면 `@Getter`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`를 사용할 수 있다.
- Lombok 없음:
  - 생성자, getter, static factory를 직접 작성한다.

## ApiResponse 필드 규칙

공통 응답 필드는 프로젝트 기준을 따른다.

- 허용 기본 필드:
  - `status`
  - `message`
  - `data`
  - `errorCode`
  - `httpStatus`
  - `timestamp`
- 기존 프로젝트가 더 단순한 필드를 쓰면 기존 구조를 우선한다.
- 신규 생성이면 성공/실패를 구분할 수 있는 최소 필드를 둔다.
- `timestamp`:
  - 기존 코드가 `LocalDateTime`을 쓰면 유지할 수 있다.
  - 신규 생성이고 시간대 명확성이 필요하면 `OffsetDateTime`을 검토한다.
- null 필드:
  - 기존 Jackson 정책을 따른다.
  - 신규 생성이면 `@JsonInclude(JsonInclude.Include.NON_NULL)`을 사용할 수 있다.

## 상태 코드 규칙

HTTP status와 body status는 일치해야 한다.

- 성공 응답:
  - 조회 성공: `200 OK`
  - 생성 성공: `201 Created`를 사용할 수 있다.
  - 본문 없는 성공: `204 No Content`를 사용할 수 있다.
  - 기존 프로젝트가 모두 `200 OK`를 쓰면 유지하되 의심 항목으로 보고한다.
- 실패 응답:
  - 에러 응답을 `ResponseEntity.ok(...)`로 감싸지 않는다.
  - body의 `httpStatus`와 `ResponseEntity` status를 맞춘다.
  - Security 401/403 응답도 같은 포맷을 우선한다.
- 예외:
  - 외부 콜백이 프로토콜상 항상 `200 OK`를 요구하면 예외로 허용하고 결과 보고에 남긴다.

## Factory 메소드 규칙

정적 생성 메소드는 응답 의미를 분명히 한다.

- 허용 후보:
  - `success(data)`
  - `success(message, data)`
  - `successMessage(message)`
  - `created(message, data)`
  - `noContent(message)`
  - `error(message, httpStatus)`
  - `error(errorCode, message, httpStatus)`
  - `error(CustomException)`
- `error(CustomException)`에서 unchecked generic cast가 발생하면 의심 항목으로 보고한다.
- 신규 생성이면 generic cast 없이 data 타입을 명시하거나 `Object data`로 제한한다.

## PageResponse 규칙

페이징 응답은 페이지 기준을 명확히 한다.

- Spring Data `Page<T>`에서 생성할 수 있어야 한다.
- 허용 기본 필드:
  - `content`
  - `page`
  - `size`
  - `totalPages`
  - `totalElements`
  - `first`
  - `last`
  - `empty`
- 페이지 번호:
  - 프로젝트가 1-base를 쓰면 `page.getNumber() + 1`을 사용하고 문서화한다.
  - 프로젝트가 0-base를 쓰면 `page.getNumber()`를 유지한다.
  - 설정과 코드가 다르면 의심 항목으로 보고한다.
- 정렬 정보가 필요하면 기존 API 응답 기준에 맞춰 추가한다.

## 예외 케이스

공통 응답 래퍼를 쓰지 않을 수 있는 응답을 허용한다.

- 파일 다운로드
- 스트리밍 응답
- 외부 서비스 콜백 응답
- 헬스체크
- 정적 리소스
- 프로토콜상 특정 body/status가 필요한 API

## 기존 구현 처리

이미 구현되어 있으면 중복 생성하지 않는다.

- `ApiResponse`가 있으면 필드, factory 메소드, status 정합성, generic cast 여부를 확인한다.
- `PageResponse`가 있으면 페이지 번호 기준, Spring Data `Page<T>` 변환, 필드명을 확인한다.
- Controller가 `ResponseEntity<ApiResponse<...>>`를 많이 쓰면 기존 패턴을 유지한다.
- 에러 응답이 `ResponseEntity.ok(...)`로 감싸져 있으면 보완 대상으로 보고한다.
- 기존 구현이 요구 기준과 크게 다르면 자동 수정하지 않고 차이와 조치안을 먼저 안내한다.

## 검증 기준

가능한 범위에서 검증한다.

- 컴파일 검증:
  - Gradle: `./gradlew compileJava`
  - Maven: `./mvnw compile`
- 검색 검증:
  - `ApiResponse` 생성 위치
  - `PageResponse` 생성 위치
  - `ResponseEntity.ok(ApiResponse.error(...))` 사용처
  - `ApiResponse.error(CustomException)` generic cast 여부
  - `PageResponse` 0-base/1-base 기준
  - Security 401/403 응답 포맷
- 테스트가 있으면 관련 Controller 테스트를 우선 실행한다.

## 결과 보고

최종 보고에는 필요한 정보만 남긴다.

- 생성 파일
- 수정 파일
- 응답 필드
- 성공/실패 status 기준
- 페이징 기준
- 검증 명령과 결과
- 의심 항목
- 남은 확인 항목

## 이력관리

- 2026-07-13: 컴포넌트 문서 구성과 이력관리 기준을 추가했다.
