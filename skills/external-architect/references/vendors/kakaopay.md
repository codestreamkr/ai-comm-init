# KakaoPay 레퍼런스

카카오페이 온라인 결제를 직접 연동할 때 보는 설계 기준이다. 공개 개발자센터 기준으로는 `결제 준비(ready) -> 카카오페이 화면 이동 -> approval_url 리다이렉트 -> 승인(approve) -> 취소/주문조회` 흐름이 핵심이다.

## 벤더 성격 요약

- 리다이렉트 기반 흐름이 강하다.
- `ready`와 `approve`가 명확히 분리되어 있다.
- 결제 준비 성공은 실제 결제 완료가 아니다.
- 공개 문서만 보면 웹훅보다 `approval_url`과 서버 승인 호출이 핵심 채널이다.

## 인증과 기본 기술 조건

- 신 API는 `open-api.kakaopay.com` 도메인을 사용한다.
- 서버 호출 헤더는 `Authorization: SECRET_KEY {발급 키}` 형식이다.
- 공개 포럼 기준 Secret Key는 대문자와 숫자를 포함한 40자 형식이다.
- 구 API의 `admin_key`와 신 API의 `secret_key`를 혼용하면 오류가 난다.

## 핵심 식별자

- `tid`: 카카오페이 거래 식별자. `ready` 성공 응답에서 받는다.
- `partner_order_id`: 가맹점 주문번호. 정보성 필드이며 공개 포럼 기준 중복 검증을 하지 않는다.
- `partner_user_id`: 가맹점 사용자 식별자
- `pg_token`: 사용자가 결제 인증을 마친 뒤 `approval_url`로 전달되는 일회성 승인 토큰

설계상 `tid`는 반드시 서버에 저장해야 한다. `approval_url`에는 `tid`가 같이 오지 않기 때문에, `partner_order_id` 등 우리 쪽 식별자로 `tid`를 복원할 수 있어야 한다.

## 기본 연동 흐름

### 1. 결제 준비

- 서버에서 `ready` API를 호출한다.
- 이때 `approval_url`, `fail_url`, `cancel_url`을 함께 보낸다.
- 응답으로 `tid`와 `next_redirect_*_url` 계열 값을 받는다.

### 2. 사용자 인증

- 클라이언트를 `next_redirect_pc_url`, `next_redirect_mobile_url`, 앱용 URL 등 적절한 URL로 보낸다.
- 이 단계는 카카오페이 화면에서 이루어진다.

### 3. approval_url 리다이렉트

- 인증이 끝나면 가맹점이 보낸 `approval_url`로 리다이렉트된다.
- 공개 포럼 기준 이 리다이렉트는 `pg_token` 전달과 결제 인증 결과 통지를 위한 것이며, 카카오페이가 그 뒤 추가 서버 처리를 해주지 않는다.

### 4. 서버 승인

- 가맹점 서버가 `approve` API를 호출해 최종 승인한다.
- 공개 포럼 기준 `ready` 이후 15분 안에 승인되지 않으면 해당 거래는 실패 처리된다.
- 승인 성공 전까지는 실제 결제 완료로 보면 안 된다.

## 취소와 조회

- 결제 완료 후에는 결제 취소 API로 취소 요청을 한다.
- 공개 문서 기준 `ready` 성공 상태는 실제 결제가 아니므로 취소가 필요 없다.
- 주문 조회 API로 후속 상태를 확인할 수 있다.

## 웹훅/비동기 처리 관점

- 공개 개발자센터와 포럼 기준으로 온라인 결제의 핵심 완료 채널은 웹훅이 아니라 `approval_url + approve` 흐름이다.
- 공개 문서에서 토스/KCP처럼 일반 결제용 웹훅 채널이 전면에 드러나지 않는다.
- 따라서 결제 완료 확정은 `approve` 성공 응답을 기준으로 하고, 보강이 필요하면 주문 조회 API를 재호출하는 쪽으로 설계하는 것이 현실적이다.

이 부분은 공개 문서 기준 판단이다. 계약 제품이나 비공개 가이드에 별도 노티 체계가 있는지는 추가 확인이 필요하다.

## 멱등성과 중복 방지

- 공개 자료에서 네이버페이나 토스처럼 멱등 헤더 지원이 전면에 드러나지 않는다.
- 따라서 우리 시스템이 `tid` 기준 승인/취소 중복 방지를 책임져야 한다.
- 최소 기준은 `partner_order_id -> tid` 매핑 저장, `approve` 재호출 방지, `cancel` 중복 요청 방지다.

## 도메인/플랫폼 설정 포인트

- `approval_url`, `fail_url`, `cancel_url`은 등록된 사이트 도메인 기준 검증을 받는다.
- 포럼 사례 기준 등록된 도메인이 없으면 URL 검증 오류가 발생한다.
- 앱 복귀나 커스텀 스킴은 플랫폼별 차이가 있으므로 웹/앱 흐름을 분리해서 본다.

## 운영 포인트

- `approval_url`에 도달했다고 바로 완료 처리하지 말고 반드시 서버 `approve` 성공까지 확인한다.
- `pg_token`은 일회성 승인 토큰이므로 장기 저장용 식별자로 보지 않는다.
- `partner_order_id`는 중복 검증 필드가 아니므로 주문번호 유일성은 가맹점이 스스로 보장해야 한다.
- 오류 분석이 필요할 때는 `tid`와 가맹점 정보를 함께 남겨야 지원 속도가 올라간다.

## 이관 관점 체크포인트

- 웹훅 중심 PG에서 넘어오면 완료 확정 기준이 달라진다. 카카오페이는 리다이렉트 후 서버 승인 호출이 핵심이다.
- `approval_url`만 구현하고 `approve`를 빼먹으면 결제 완료가 확정되지 않는다.
- 공존 기간에는 `vendor=kakaopay`, `tid`, `partner_order_id`를 함께 남겨야 취소와 조회 라우팅이 가능하다.
- 프론트 리다이렉트와 백엔드 승인 경계를 명확히 나누지 않으면 결제 완료 화면은 떴는데 실제 승인되지 않은 상태가 생길 수 있다.

## 확인 필요

- 공개 문서만으로는 온라인 결제 전용 일반 웹훅 채널이 분명하지 않다. 필요하면 카카오페이 제휴 문서나 지원 채널로 추가 확인이 필요하다.
- 부분 취소와 수단별 상세 제약은 실제 계약 상품과 API 레퍼런스 버전에 따라 다시 확인해야 한다.

## 공식 레퍼런스

- 온라인 결제 시작하기: https://developers.kakaopay.com/docs/payment/online/online-getting-started
- 단건 결제 문서 진입점: https://developers.kakaopay.com/docs/payment/online/single-payment
- 결제 취소 문서 진입점: https://developers.kakaopay.com/docs/payment/online/cancellation
- 참고하기 진입점: https://developers.kakaopay.com/docs/payment/online/reference
- 공개 포럼: approval_url/approve 흐름 설명 https://developers.kakaopay.com/forum/t/api/1308
- 공개 포럼: Secret Key 형식 안내 https://developers.kakaopay.com/forum/t/api/957

## 이력관리
- 2026-04-21: 카카오페이 온라인 결제 직접 연동용 벤더 레퍼런스 초안 추가
