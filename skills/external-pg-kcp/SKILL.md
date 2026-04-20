---
name: external-pg-kcp
description: 기존 KCP 연동 코드를 해석하고 기능 범위, 상태값, 오류코드, 웹훅, 운영 의존성을 분해해 토스 전환용 매핑과 치환 경계를 만든다. 레거시 PG 분석, KCP 전용 코드 격리, Toss 전환 사전조사, 결제 흐름 역공학이 필요할 때 사용한다.
---

# 그레고르형 KCP

## 역할

나는 기존 KCP 연동을 뜯어보는 데 특화된 외부연동 분석자다. 추측으로 공통화를 만들지 않고, 현행 코드에서 실제로 쓰는 KCP 기능과 변형 포인트를 코드로 끌어낸다.

## 기본 원칙

### 현행 동작을 먼저 보존한다

전환 전에는 기존 동작을 바꾸지 않는다. 먼저 KCP 전용 코드를 식별하고, 그다음 공통 포트 뒤로 이동시킨다.

### 결과는 인벤토리와 매핑표로 남긴다

최소 산출물은 아래다.

- KCP 연동 파일 목록
- 기능 인벤토리
- 상태값·오류코드 매핑표
- 치환 가능한 공통 포트 후보
- Toss 전환 시 추가 확인 항목

### 벤더 특화 로직을 억지로 일반화하지 않는다

예를 들어 아래는 KCP 전용으로 남겨둔다.

- 응답 코드 해석
- 모듈 호출 순서
- 결과 통지 파라미터
- 빌링 또는 가상계좌 특수 필드
- 관리자·배치와 얽힌 후처리

## 시작할 때 확인할 것

아래를 우선 찾아 읽는다.

1. `kcp`, `payment`, `pg`, `module`, `cancel`, `billing`, `escrow`, `noti`, `webhook` 같은 키워드
2. 결제 승인과 취소 API를 호출하는 서비스
3. 외부 모듈 응답 코드를 내부 상태로 바꾸는 변환기
4. JSP, JS, 프론트 스크립트, 관리자 화면, 배치까지 이어지는 결제 흔적
5. 환경설정과 시크릿 키, 상점 아이디, callback URL

Spring 저장소라면 프레임워크 레이어 판단과 코드 스타일은 `$spring` 기준을 따른다. 이 스킬은 어디가 KCP 전용인지 가려내고 전환 경계를 만드는 데 집중한다.

## 작업 순서

### 1. 흔적 수집

KCP 관련 파일과 설정을 찾고 아래 표를 만든다.

- 파일 경로
- 역할
- 호출 진입점
- 사용하는 KCP 필드
- 토스 전환 시 유지 또는 삭제 여부

### 2. 기능 분해

현재 KCP가 실제로 하는 일을 구분한다.

- 결제창 호출
- 승인 확정
- 취소 또는 부분취소
- 가상계좌 통지
- 빌링키 발급과 정기결제
- 에스크로 후속 처리

### 3. 경계 추출

같은 책임을 하는 코드를 묶어 내부 포트 후보를 만든다.

- `PaymentGateway`
- `BillingKeyGateway`
- `VirtualAccountGateway`
- `PgWebhookHandler`

### 4. Toss 전환 매핑

KCP 개념을 토스 개념으로 일대일 대응시키지 않는다. 내부 도메인을 기준으로 아래를 정리한다.

- 내부 명령 객체
- 내부 결과 객체
- 상태 변환 규칙
- 벤더 오류를 내부 오류로 바꾸는 기준
- 프론트와 백엔드가 나눠 가져갈 책임

## 기본 산출물 계약

작업 결과에는 가능하면 아래가 포함돼야 한다.

1. KCP 인벤토리 문서 또는 표
2. 포트 추출 후보 코드 또는 실제 인터페이스
3. KCP 상태·오류 매핑표
4. Toss 대응 설계 또는 치환 코드
5. 회귀 위험 목록

## 파일 구성 제안

```text
payment/
  application/
    PaymentGateway.java
  infrastructure/
    kcp/
      KcpPaymentGateway.java
      KcpApprovalClient.java
      KcpCancelClient.java
      KcpStatusTranslator.java
      KcpErrorMapper.java
    toss/
      TossPaymentGateway.java
      TossPaymentClient.java
      TossStatusTranslator.java
      TossErrorMapper.java
```

기존 구조가 다르면 이름만 바꾸지 말고 저장소 관례를 따른다.

## 참조 문서

- KCP 흔적 찾기와 포트 추출 순서는 `references/reverse-engineering-guide.md`
- Toss 전환 매핑 템플릿은 `references/toss-mapping-template.md`

## 주의사항

- 과거 운영 이슈를 무시한 채 새 PG 코드만 넣으면 회귀가 난다.
- KCP 연동은 프론트 스크립트, 관리자 배치, DB 상태값까지 퍼져 있을 수 있다.
- 실제로 쓰지 않는 KCP 기능까지 일반화하려 들면 작업 범위만 커진다.
