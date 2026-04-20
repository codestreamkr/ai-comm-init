# Toss 전환 매핑 템플릿

## 목차

- 매핑 원칙
- 기능 매핑 표
- 상태·오류 변환 표
- 전환 순서

## 매핑 원칙

- KCP API 이름을 그대로 토스 API 이름으로 바꾸지 않는다.
- 내부 도메인 명령과 결과를 먼저 고정한다.
- 프론트 스크립트, 서버 승인, 웹훅을 각각 다른 경계로 본다.

## 기능 매핑 표

| 내부 기능 | 현재 KCP 방식 | 목표 Toss 방식 | 공통 포트 | 비고 |
|---|---|---|---|---|
| 결제 승인 | KCP 승인 API 호출 | `confirm` 호출 | `PaymentGateway.confirm` | orderId, amount 일치 필요 |
| 결제 취소 | 취소 API | `cancel` 호출 | `PaymentGateway.cancel` | 부분취소 정책 검토 |
| 결제 조회 | 조회 API 또는 DB | 결제 조회 API | `PaymentQueryGateway.getPayment` | 화면 동기화용 |
| 웹훅 | KCP 통지 | Toss webhook | `PgWebhookHandler` | 서명 검증 방식 다름 |
| 빌링 | KCP 빌링 모듈 | billingKey 발급·재결제 | `BillingKeyGateway` | 저장 정책 점검 |

## 상태·오류 변환 표

| 내부 상태 | KCP 값 | Toss 값 | 비고 |
|---|---|---|---|
| `PENDING` | 인증 완료 대기 | `READY`, `IN_PROGRESS` | 프론트와 서버 확정 구간 |
| `APPROVED` | `0000` 성공 | `DONE` | 승인 완료 |
| `CANCELED` | 취소 성공 코드 | `CANCELED`, `PARTIAL_CANCELED` | 부분취소 분리 가능 |
| `FAILED` | 오류 코드 | `ABORTED`, `EXPIRED` 등 | 운영 메시지 분리 |

## 전환 순서

1. KCP 포트화
2. Toss 구현 추가
3. 상태·오류 매퍼 분리
4. 웹훅 경로와 처리기 분리
5. 기능 플래그 또는 설정 기반 라우팅
6. 단계적 전환과 운영 검증
