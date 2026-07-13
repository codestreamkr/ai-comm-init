# 기술 스택별 책임 매핑

## 선택 기준

기능 진입점, 호출 흐름과 실제 변경 파일을 근거로 영향 런타임별 variant를 선택한다.

- Java/Spring: `pom.xml`, `build.gradle*`, `src/main/java/**`
- Node.js/TypeScript: `package.json`, `tsconfig.json`, `src/**/*.ts`, `src/**/*.js`
- Python: `pyproject.toml`, `requirements.txt`, `src/**/*.py`, `app/**/*.py`
- Generic/Other: 위 세 variant로 확정할 수 없는 Go, Rust, C#, Ruby와 기타 런타임
- 혼합 저장소는 진입점 런타임만 고르지 않고 실제 변경 대상이 있는 모든 런타임의 variant를 선택한다.
- 호출만 하고 변경하지 않는 런타임은 연계 경계로 기록하고 variant 구현 범위에는 포함하지 않는다.
- 아래 명칭보다 저장소의 실제 계층명과 파일명을 우선한다.

## Java/Spring/MyBatis·JPA

Java 계열은 프레임워크와 데이터 접근 방식을 구분해 조사한다.

- 요청 진입점: `Controller`, message listener, batch entry
- 애플리케이션 처리: `Service`, use case, transaction boundary
- 저장 경계: `DAO`, `Mapper`, `Repository`
- 데이터 모델: `VO`, `DTO`, `record`, entity, projection
- 조회·저장 정의: Mapper XML, annotation SQL, JPA query, QueryDSL, native SQL
- 주요 정합성: JSON 필드 ↔ DTO·VO ↔ 조회 컬럼·entity 필드 ↔ Service 조립

## Node.js/TypeScript

Node.js 계열은 프레임워크보다 요청·처리·저장 책임을 기준으로 조사한다.

- 요청 진입점: route, controller, handler, resolver, consumer
- 애플리케이션 처리: service, use case, application module
- 저장 경계: repository, data-access module, client adapter
- 데이터 모델: type, interface, DTO, schema, validation model
- 조회·저장 정의: ORM model·query, query builder, raw SQL, external client request
- 주요 정합성: response field ↔ type·schema ↔ query result ↔ service assembly

## Python

Python 계열은 웹 프레임워크와 데이터 모델 도구의 실제 구성을 기준으로 조사한다.

- 요청 진입점: router, view, endpoint, command, consumer, task
- 애플리케이션 처리: service, use case, application function
- 저장 경계: repository, CRUD module, gateway, client adapter
- 데이터 모델: Pydantic model, dataclass, serializer, schema, ORM model
- 조회·저장 정의: ORM query, query builder, raw SQL, external client request
- 주요 정합성: response field ↔ schema·serializer ↔ query result ↔ service assembly

## Generic/Other

기타 언어는 프레임워크 명칭을 추정하지 않고 저장소의 실제 책임 경계를 사용한다.

- 요청 진입점: route, handler, command, consumer, job 등 실제 진입 파일과 함수
- 애플리케이션 처리: use case, service, application module 또는 동등한 처리 책임
- 저장 경계: repository, gateway, adapter, data-access 또는 동등한 영속성 책임
- 데이터 모델: request, response, entity, schema, type 또는 동등한 데이터 계약
- 조회·저장 정의: ORM, query builder, raw query, 외부 client 호출 또는 파일 저장
- 주요 정합성: 입력 계약 ↔ 처리 모델 ↔ 저장·외부 경계 ↔ 출력 계약
- 런타임 이름을 확정할 수 없어도 실제 파일과 호출 관계가 확인되면 Generic/Other를 선택하고 실제 함수·모듈명을 기록한다.
- 실제 변경 파일과 호출 관계를 확정할 수 없으면 질문으로 구현 범위를 확정한다.

## variant별 최소 구체화

선택한 각 variant의 개발 가이드에는 확인된 구현 수단을 구체적으로 적는다.

- Java/MyBatis: Mapper namespace와 SQL ID, parameter/result 모델, 조회·저장 필드와 SQL 초안
- Java/JPA: Repository 메서드 또는 query, entity·projection 필드, transaction 경계
- Node.js/TypeScript: route·handler, type·schema, ORM/query/client 호출과 service 조립
- Python: router·view·task, schema·serializer, ORM/query/client 호출과 application 처리
- Generic/Other: 실제 진입 함수, 처리 모듈, 저장·외부 경계, 데이터 계약과 검증 명령

## 문서 반영 기준

선택한 모든 variant의 실제 코드 명칭으로 문서를 작성한다.

- 기능 흐름에 존재하는 책임만 구현 범위에 포함한다.
- 저장 경계가 있으면 데이터 원천부터 응답까지 필드 전달을 연결한다.
- 외부 API가 데이터 원천이면 저장 경계 대신 client adapter와 외부 계약을 기록한다.
- 이름이 다른 동등 계층은 저장소 명칭을 유지하고 공통 책임을 괄호로 덧붙인다.
- 런타임을 넘는 호출은 호출 방향, 전달 계약, 실패 전파와 각 런타임의 수정 대상을 연결해 기록한다.

## 이력관리

- 2026-07-13: Java/Spring/MyBatis·JPA, Node.js/TypeScript, Python, Generic/Other의 책임 매핑과 혼합 저장소의 영향 런타임별 variant 선택·구체화 기준을 추가했다.
