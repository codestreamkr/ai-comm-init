# JWT Auth 컴포넌트

## 구성

- 선행 확인과 입력 계약
- 인증·토큰·의존성·설정 규칙
- 기존 구현, 보안 검토와 검증

## 목적

`jwt-auth`는 Spring Security 기반 JWT 인증 흐름을 구성한다.

- 생성 대상:
  - `context/AccountContext.java`
  - `config/JwtAuthFilter.java`
  - `util/CustomJwtUtil.java` 또는 기존 JWT 유틸 클래스
- 수정 대상:
  - `config/SecurityConfig.java`
  - `service/JwtTokenService.java`와 구현체가 필요한 경우
  - `application*.yml` 또는 설정 프로퍼티가 필요한 경우
  - 필요 시 빌드 파일의 Security/JJWT 의존성
- 적용 방식:
  - JWT 검증 후 `AccountContext`에 사용자 정보를 설정한다.
  - `SecurityContextHolder`에는 인증 객체와 권한을 설정한다.
  - 요청 처리가 끝나면 `AccountContext.clear()`로 ThreadLocal을 정리한다.
  - 기본 생성은 Access Token 인증만 처리한다.
  - Refresh Token은 DB 또는 Redis 저장소 정책이 확인된 경우에만 별도 확장으로 다룬다.

## 선행 확인

작업 전에 필요한 파일을 확인한다.

- 빌드 파일:
  - `build.gradle`
  - `build.gradle.kts`
  - `pom.xml`
- 패키지 루트:
  - `@SpringBootApplication` 클래스 위치
- 기존 패키지:
  - `config`
  - `context`
  - `util`
  - `service`
  - `service.impl`
  - `exception`
  - `model`
- 기존 구현:
  - `AccountContext`
  - `JwtAuthFilter`
  - `SecurityConfig`
  - `CustomJwtUtil`, `JwtUtil`, `TokenProvider`
  - `JwtTokenService`
  - 기존 인증/인가 URL 정책
  - 기존 예외 응답 모델
- 버전 기준:
  - Java 버전
  - Spring Boot 버전
  - Spring Security 버전
  - jjwt 또는 JWT 라이브러리 버전
  - Lombok 사용 여부

## 입력 기준

인증 정책은 명확해야 한다.

- 허용 입력:
  - 보호할 URL 패턴
  - 공개 URL 패턴
  - Role 매핑 규칙
  - Access Token 전달 방식
  - JWT claim 필드
- 예시:
  - `Bearer 헤더 기반 access token 인증`
  - `쿠키 WSAT 기반 access token 인증`
  - `/admin/**`는 `ADMIN`, 나머지는 인증 필요
- 기존 `SecurityConfig`가 있으면 기존 URL 정책을 보존하고 필터 연결에 필요한 차이만 반영한다.
- 신규 `SecurityConfig`는 공개 URL을 화이트리스트로 명시하고 그 외 요청은 인증을 기본으로 한다.
- 공개 URL을 코드와 요청에서 확정할 수 없으면 한 번 확인한 뒤 생성한다.

## 생성 규칙

파일은 기존 패키지 구조에 맞춰 만든다.

- 기존 `config`, `context`, `util`, `service` 패키지가 있으면 우선 사용한다.
- 기존 패키지가 없으면 컴포넌트 책임에 맞춰 필요한 패키지를 생성한다.
- 신규 패키지는 `@SpringBootApplication` 루트 패키지 하위에 둔다.
- 패키지 위치 판단이 애매하면 의심 항목으로 보고한다.

### 버전 호환 기준

생성 코드는 프로젝트 버전을 따른다.

- Java와 Spring 버전이 확인되면 해당 버전에서 권장되는 최신 문법과 API를 우선 사용한다.
- 하위 버전 호환 문법은 프로젝트 버전 판단이 불가능하거나 기존 코드가 명확히 보수적일 때만 사용한다.
- 최신 API를 쓰면 기존 코드 스타일과 충돌하는 경우 프로젝트 컨벤션을 우선하고 의심 항목으로 보고한다.
- 버전별 API 차이가 있으면 생성 코드에 해당 버전 문법을 직접 반영한다.
- 서로 다른 버전의 문법을 한 파일에 섞지 않는다.
- 버전 판단이 불가능하면 Java 8, Spring Boot 2.x, Spring Security 5, jjwt 0.11 이하 기준으로 보수적으로 작성하고 의심 항목으로 보고한다.
- 공식 지원이 종료된 버전이나 오래된 보안 라이브러리가 확인되면 생성은 가능하지만 업그레이드 필요 항목으로 보고한다.
- Java 8:
  - `var`, `record`, `List.of`, `Set.of`, `Stream.toList`, 텍스트 블록을 사용하지 않는다.
  - `List`와 `Set`은 `Arrays.asList`, `Collections.unmodifiableList`, `new HashSet<>()` 등으로 작성한다.
- Java 11:
  - 기존 코드 스타일과 맞으면 지역 변수 `var`를 사용할 수 있다.
  - `List.of`, `Set.of`는 사용할 수 있지만 기존 코드가 Java 8 스타일이면 프로젝트 컨벤션을 우선한다.
- Java 17 이상:
  - 기존 코드 스타일과 맞으면 Java 17 이상에서 권장되는 문법과 표준 API를 사용할 수 있다.
  - 단순 응답 DTO는 기존 컨벤션과 맞을 때 `record`를 사용할 수 있다.
- Java 21 이상:
  - 기존 코드 스타일과 맞으면 Java 21 기준으로 안정화된 최신 문법과 표준 API를 사용할 수 있다.
  - 가상 스레드는 인증 필터, ThreadLocal 기반 `AccountContext`, SecurityContext 전파 영향이 명확할 때만 언급한다.
- Spring Boot 3.x:
  - Spring Security 6 계열 기준으로 `SecurityFilterChain` Bean 방식을 사용한다.
  - `WebSecurityConfigurerAdapter`를 만들지 않는다.
  - Servlet API는 `jakarta.servlet.*`를 사용한다.
  - `authorizeHttpRequests`, `requestMatchers`, lambda DSL을 우선 사용한다.
  - 메소드 보안이 필요하면 `@EnableMethodSecurity`를 사용한다.
- Spring Boot 2.x:
  - Spring Security 5 계열 기준으로 작성한다.
  - Servlet API는 `javax.servlet.*`를 사용한다.
  - 기존 프로젝트가 `SecurityFilterChain` Bean 방식을 쓰면 그 방식을 유지한다.
  - 기존 프로젝트가 `WebSecurityConfigurerAdapter`를 쓰면 같은 방식을 유지한다.
  - URL 매칭은 기존 코드에 따라 `antMatchers` 또는 `requestMatchers`를 선택한다.
  - 메소드 보안이 필요하면 기존 방식에 따라 `@EnableGlobalMethodSecurity(prePostEnabled = true)`를 사용한다.
- Spring Security 6:
  - `authorizeHttpRequests`와 `requestMatchers`를 사용한다.
  - `SecurityFilterChain` Bean을 기본으로 한다.
  - `WebSecurityConfigurerAdapter`, `authorizeRequests`, `antMatchers`를 새로 만들지 않는다.
- Spring Security 5:
  - 기존 코드가 `authorizeRequests`와 `antMatchers`를 쓰면 유지한다.
  - Boot 2.7처럼 `SecurityFilterChain` Bean 방식이 가능한 프로젝트는 기존 방식에 맞춘다.
  - `WebSecurityConfigurerAdapter` 신규 도입은 기존 프로젝트가 같은 방식을 쓸 때만 허용한다.
- jjwt 0.12 이상:
  - `Jwts.parser().verifyWith(secretKey).build().parseSignedClaims(token)` 방식을 우선 사용한다.
  - `Jwts.builder().claims(...).subject(...).issuedAt(...).expiration(...).signWith(secretKey)` 방식을 우선 사용한다.
- jjwt 0.11 이하:
  - `Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token).getBody()` 계열 API를 사용한다.
  - 빌더는 `setClaims`, `setSubject`, `setIssuedAt`, `setExpiration`, `signWith` 계열 기존 API를 사용한다.
- jjwt 버전이 없고 다른 JWT 라이브러리를 쓰는 경우:
  - 기존 라이브러리 기준으로 작성한다.
  - jjwt 의존성 추가는 사용자 확인 후 진행한다.
- Lombok 있음:
  - 기존 코드가 Lombok을 쓰면 `@RequiredArgsConstructor`, `@Slf4j`를 사용할 수 있다.
- Lombok 없음:
  - 생성자 직접 작성과 `LoggerFactory.getLogger(...)`를 사용한다.

### 버전별 생성 매핑

버전 조합에 따라 생성 코드를 다르게 만든다.

| 기준 | Boot 3 / Security 6 / jjwt 0.12+ | Boot 2 / Security 5 / jjwt 0.11 이하 |
|---|---|---|
| Servlet import | `jakarta.servlet.*` | `javax.servlet.*` |
| Security 설정 | `SecurityFilterChain` Bean | 기존 방식 우선, 필요 시 `WebSecurityConfigurerAdapter` |
| URL 인가 | `authorizeHttpRequests`, `requestMatchers` | `authorizeRequests`, `antMatchers` 또는 기존 방식 |
| 메소드 보안 | `@EnableMethodSecurity` | `@EnableGlobalMethodSecurity(prePostEnabled = true)` |
| JWT 파싱 | `Jwts.parser().verifyWith(...).build().parseSignedClaims(...)` | `Jwts.parserBuilder().setSigningKey(...).build().parseClaimsJws(...)` |
| JWT 빌더 | `claims`, `subject`, `issuedAt`, `expiration` | `setClaims`, `setSubject`, `setIssuedAt`, `setExpiration` |
| 컬렉션 팩토리 | Java 버전에 따라 `List.of`, `Set.of` 가능 | Java 8이면 `Arrays.asList`, `new HashSet<>()` |

### AccountContext

- 위치: `<root>.context.AccountContext`
- 책임:
  - 현재 요청의 인증 사용자 정보를 ThreadLocal로 보관
  - JWT claim 기반 사용자 정보 설정
  - 사용자 ID, username, role 등 자주 쓰는 필드 조회
  - 요청 종료 시 ThreadLocal 제거
- 필수 규칙:
  - `ThreadLocal`은 `private static final`로 둔다.
  - 필터 `finally` 블록에서 반드시 `clear()`를 호출한다.
  - `getId()`, `getRole()` 같은 조회 메소드는 인증 정보가 없을 때 `null` 또는 프로젝트 예외 정책을 따른다.
  - `isAdmin()` 같은 권한 보조 메소드는 NPE가 나지 않게 작성한다.
- Claim 변환:
  - 숫자 claim은 `Number`, `String`, `Long` 입력을 모두 고려한다.
  - claim 키는 기존 토큰 생성 규칙을 우선한다.

### JwtAuthFilter

- 위치: `<root>.config.JwtAuthFilter`
- 기반 클래스:
  - Spring Web MVC: `OncePerRequestFilter`
- 책임:
  - 요청에서 Access Token 추출
  - 토큰 검증
  - 만료 토큰 처리
  - `AccountContext` 설정
  - `SecurityContextHolder` 인증 설정
  - 인증 실패 응답 작성
  - 요청 종료 시 `AccountContext.clear()`
- 필수 규칙:
  - 토큰이 없으면 다음 필터로 넘긴다.
  - 토큰이 있으면 검증 후 인증 컨텍스트를 설정한다.
  - 인증 실패 응답은 프로젝트 공통 응답 모델을 우선 사용한다.
  - `SecurityContextHolder.clearContext()`가 필요한 실패 경로를 확인한다.
  - 신규 생성 코드에는 JWT 원문, refresh token 원문, secret, password 로그를 만들지 않는다.
  - 기존 코드에 JWT 원문, refresh token 원문, secret, password 로그가 있으면 자동 수정하지 않고 보안 의심 항목으로 보고한다.
- 권한 설정:
  - role claim이 있으면 `ROLE_` prefix 중복 여부를 확인한다.
  - Spring Security에는 `SimpleGrantedAuthority` 또는 기존 권한 모델을 사용한다.
  - 인증 principal은 기존 프로젝트 관례에 맞춰 `memberId`, username, 또는 별도 principal 객체 중 하나를 선택한다.

### CustomJwtUtil

- 위치: `<root>.util.CustomJwtUtil` 또는 기존 JWT 유틸 위치
- 책임:
  - Access Token 생성
  - Claims 추출
  - 토큰 유효성 검증
  - 만료 여부 확인
  - 쿠키 기반 Access Token 인증을 쓰는 경우 쿠키 생성/삭제
- 필수 규칙:
  - secret은 설정 값에서 주입받는다.
  - 신규 생성 코드에는 secret 원문 또는 일부 로그를 만들지 않는다.
  - 신규 생성 코드에는 만료된 토큰 로그에 token 원문을 남기지 않는다.
  - 기존 코드에 secret 또는 token 원문 로그가 있으면 자동 수정하지 않고 보안 의심 항목으로 보고한다.
  - 토큰 생성 claim에는 필요한 식별자만 넣는다.
  - 개인정보 claim은 프로젝트 요구가 있을 때만 포함한다.
- 추천 claim:
  - `id`
  - `username`
  - `role`
  - 필요 시 `memberCode`
- 의심 claim:
  - `email`
  - `name`
  - 주소, 전화번호, 외부 서비스 사용자 식별자

### SecurityConfig

- 위치: `<root>.config.SecurityConfig`
- 책임:
  - `SecurityFilterChain` 구성
  - CSRF, CORS, session policy 설정
  - 공개 URL과 보호 URL 정책 설정
  - 인증 실패와 접근 거부 응답 설정
  - `JwtAuthFilter` 등록
- Spring Boot 3.x 기본 규칙:
  - `SessionCreationPolicy.STATELESS`
  - `csrf(AbstractHttpConfigurer::disable)`
  - `httpBasic(AbstractHttpConfigurer::disable)`
  - `formLogin(AbstractHttpConfigurer::disable)`
  - `addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)`
- URL 정책:
  - 공개 URL은 화이트리스트로 명시한다.
  - 신규 구성은 공개 URL 뒤에 `anyRequest().authenticated()`를 적용한다.
  - Role 정책이 주어지면 해당 URL에 `hasRole(...)` 또는 프로젝트의 기존 권한 표현을 적용한다.
  - 기존 프로젝트가 공개 API 중심이어도 전체 허용을 새 기본값으로 만들지 않는다.
  - 기존 전체 허용 정책은 자동으로 넓히거나 축소하지 않고 의도와 보호 대상을 보안 의심 항목으로 보고한다.

## 토큰 전달 규칙

토큰 전달 방식은 프로젝트 기준을 따른다.

- Access Token:
  - `Authorization: Bearer <token>` 헤더를 우선 지원한다.
  - 쿠키 기반 인증을 쓰는 프로젝트는 기존 쿠키명을 유지한다.
- Refresh Token:
  - 기본 생성 대상에서 제외한다.
  - DB 또는 Redis 저장소 정책이 확인된 경우에만 별도 확장으로 다룬다.
  - refresh token을 받는 신규 컨트롤러 엔드포인트를 만들지 않는다.
  - 기존 코드가 refresh token을 외부 입력으로 받으면 보안 의심 항목으로 보고한다.
  - refresh token 원문을 로그에 남기지 않는다.
- 자동 갱신:
  - 기본 생성 대상에서 제외한다.
  - 기존 자동 갱신 흐름이 있으면 수정하지 않고 저장소 검증 방식만 확인한다.

## 의존성 규칙

JWT 인증에 필요한 의존성을 확인한다.

- Spring Boot Gradle:
  - `implementation 'org.springframework.boot:spring-boot-starter-security'`
  - `implementation 'io.jsonwebtoken:jjwt-api:<version>'`
  - `runtimeOnly 'io.jsonwebtoken:jjwt-impl:<version>'`
  - `runtimeOnly 'io.jsonwebtoken:jjwt-jackson:<version>'`
- Spring Boot Maven:
  - `spring-boot-starter-security`
  - `jjwt-api`
  - `jjwt-impl`
  - `jjwt-jackson`
- 이미 Security/JJWT 의존성이 있으면 추가하지 않는다.
- JWT 라이브러리가 다르면 기존 라이브러리 기준으로 구현한다.
- Spring Boot 프로젝트는 Boot 의존성 관리를 우선 사용한다.
- JJWT 버전은 기존 선언이 있으면 맞춘다.
- 기존 JWT 라이브러리 버전이 없으면 최신 버전을 임의로 고정하지 않고 사용자 확인 후 진행한다.

## 설정 규칙

설정 값은 외부 주입을 기본으로 한다.

- 필수 설정:
  - `jwt.secret`
  - `jwt.access-token-expiration`
- 선택 설정:
  - access token cookie name
  - cookie secure/sameSite/path
- 보안 기준:
  - 신규 생성 시 secret은 `application*.yml`에 평문으로 추가하지 않는다.
  - 로컬 개발용 값이 필요하면 placeholder 또는 환경변수 예시만 둔다.
  - 운영 값은 환경변수, Secret, 암호화 설정으로 주입한다.
  - 기존 설정 파일에 secret 평문이 있으면 자동 수정하지 않고 보안 의심 항목으로 보고한다.

## 기존 구현 처리

이미 구현되어 있으면 중복 생성하지 않는다.

- 기능이 없으면 신규 생성한다.
- 기능 일부만 있으면 기존 구현을 보존하고 부족한 구성만 추가한다.
- `AccountContext`가 있으면 ThreadLocal 정리와 claim 매핑만 확인한다.
- `JwtAuthFilter`가 있으면 토큰 추출, 검증, 인증 설정, 실패 응답, `finally` 정리만 확인한다.
- `CustomJwtUtil`이 있으면 secret 처리, claim 구성, 토큰 원문 로그 여부만 확인한다.
- `SecurityConfig`가 있으면 기존 URL 권한 정책을 보존하고 필터 등록 위치와 필요한 연결 차이만 확인한다.
- 기존 구현이 요구 기준과 크게 다르면 자동 수정하지 않고 차이와 조치안을 먼저 안내한다.

## 보안 1차 검토 기준

생성 후 보안 정책을 스스로 1차 검토한다.

- JWT 원문 로그 출력 여부
- refresh token 원문 로그 출력 여부
- secret, password, API key 로그 출력 여부
- claim에 포함된 개인정보 범위
- `AccountContext.clear()` 누락 여부
- `SecurityContextHolder` 정리 필요 여부
- 공개 URL과 보호 URL 범위
- 신규 구성의 공개 URL 화이트리스트와 `anyRequest().authenticated()` 적용 여부
- 기존 `anyRequest().permitAll()` 사용 의도와 보호 정책 필요 여부
- CORS `allowedOrigins`, `allowCredentials` 조합
- Cookie `httpOnly`, `secure`, `sameSite` 설정
- refresh token을 외부 입력으로 받는 엔드포인트 여부
- refresh token 저장소가 DB인지 Redis인지 불명확한 상태에서 자동 갱신을 구현했는지 여부
- 설정 파일의 secret 평문 여부
- 인증 실패 응답에 내부 예외 메시지 노출 여부

## 생성 완료 게이트

- 신규 `SecurityConfig`의 공개 URL 화이트리스트가 코드 또는 사용자 입력으로 확정되어 있다.
- 공개 URL을 확정할 수 없으면 파일을 생성하지 않고 필요한 URL 패턴을 한 번 확인한다.
- 공개 URL 뒤의 기본 정책이 `anyRequest().authenticated()`로 구성되어 있다.
- 기존 `SecurityConfig`를 수정한 경우 기존 URL 정책을 임의로 넓히거나 축소하지 않았다.

## 검증 기준

가능한 범위에서 검증한다.

- 컴파일 검증:
  - Gradle: `./gradlew compileJava`
  - Maven: `./mvnw compile`
- 검색 검증:
  - `AccountContext` 생성 위치
  - `JwtAuthFilter` 생성 위치
  - `SecurityConfig` 필터 등록
  - `SecurityFilterChain` 사용 여부
  - `spring-boot-starter-security` 의존성
  - JWT 라이브러리 의존성
  - 토큰 원문 로그 출력 여부
- 테스트가 있으면 관련 테스트를 우선 실행한다.
- 테스트가 없으면 최소한 인증 필터 단위 테스트 또는 컨텍스트 로딩 테스트 후보를 보고한다.

## 결과 보고

최종 보고에는 필요한 정보만 남긴다.

- 생성 파일
- 수정 파일
- 인증 정책
- 토큰 전달 방식
- claim 필드
- 의존성 변경 여부
- 검증 명령과 결과
- 보안 의심 항목
- 남은 확인 항목

## 이력관리

- 2026-07-13: 신규 SecurityConfig의 공개 URL 화이트리스트와 기본 인증 정책, 공개 URL 미확정 시 생성 차단, 기존 구성 보존 기준과 컴포넌트 문서 구성을 추가했다.
