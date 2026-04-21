# toss vendor-facts

## 핵심 식별자

- `paymentKey`: 승인, 조회, 취소의 핵심 식별자
- `orderId`: 가맹점 주문번호
- `transactionKey`: 가상계좌 거래 식별자
- `secret`: 가상계좌 웹훅 검증 값

## 상태와 채널

- `READY`: 인증 대기
- `IN_PROGRESS`: 승인 대기
- `DONE`: 완료
- `EXPIRED`: 인증 또는 승인 시간 초과
- 일반 결제: 승인 API 성공이 1차 기준
- 가상계좌: `DEPOSIT_CALLBACK` 보강 필요
- 일부 해외 간편결제: `PAYMENT_STATUS_CHANGED` 기반 비동기 확정

## 멱등과 운영 포인트

- Basic 인증 사용
- `Idempotency-Key` 헤더 지원
- 가상계좌는 `DONE`에서 `WAITING_FOR_DEPOSIT`로 되돌아갈 수 있음
- 웹훅은 최대 7회 재전송될 수 있음
- `PAYMENT_STATUS_CHANGED`와 `DEPOSIT_CALLBACK`를 함께 등록하면 중복 이벤트가 올 수 있음

## 공식 레퍼런스

- https://docs.tosspayments.com/en/api-guide
- https://docs.tosspayments.com/en/webhooks
- https://docs.tosspayments.com/reference/using-api/webhook-events
- https://docs.tosspayments.com/reference/using-api/authorization
- https://docs.tosspayments.com/reference/using-api/api-keys

