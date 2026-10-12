# mall 주문 UI 테스트

## 입력과 화면

| 항목 | 경로·설정 |
| --- | --- |
| 작업 프로젝트 | `D:\projects\skmns\mall` |
| 환경파일 | `.env.payment-local` |
| 환경파일 예제 | `.env.payment-test.example` |
| 기본 주소 | `PAYMENT_TEST_BASE_URL` |
| `ultron` HTTPS 기본값 | `https://localhost:8081` |
| 상품 | `PAYMENT_TEST_PRODUCT_IDS` |
| 수단 | `PAYMENT_TEST_METHOD_IDS` |
| 수량 | `PAYMENT_TEST_QUANTITY` |
| 옵션 | `PAYMENT_TEST_PRODUCT_OPTIONS_JSON` |
| 인증 | `BRANDPAY_PAYMENT_NUMBER`, `NAVERPAY_PAYMENT_NUMBER` |
| 로그인 | `PAYMENT_TEST_LOGIN_MODE`, `PAYMENT_TEST_USERNAME`, `PAYMENT_TEST_PASSWORD` |
| 사용자 인증·실패 처리·수단 제외 정책 | `PAYMENT_TEST_MANUAL_AUTH`, `PAYMENT_TEST_AUTH_TIMEOUT_SECONDS`, `PAYMENT_TEST_CONTINUE_ON_FAILURE`, `PAYMENT_TEST_SKIP_UNAVAILABLE_METHOD` |
| 장바구니 | `/mypg/myBasket.bene` |
| 주문서 | `/mypg/orderMng.bene` |
| 완료 | `/mypg/orderMngResult.bene` |
| 상세 | `/mypg/myOrderDetailView.bene` |

1. 기본 주소는 `PAYMENT_TEST_BASE_URL`을 사용하라.
2. 사용자 인증·실패 처리·수단 제외 정책을 확인하라.
   등록된 테스트 비밀번호는 직접 사용할 수 있다. 앱 인증과 같은 별도 인증은 사용자에게 요청하라.
3. 상품 추가가 필요하면 실제 상품 상세의 옵션을 선택하라.
4. 장바구니의 대상 상품에서 `바로주문`으로 주문서를 열어라.
   실제 장바구니·상품 진입 흐름을 따라라. 주문서 URL만 직접 재사용하지 마라.

| sttlMeanId | 결제수단 |
| --- | --- |
| 50 | 신용·체크카드 |
| 51 | 토스페이 |
| 55 | 베네페이 |
| 59 | 네이버페이 |

## 확인 기준

- `.docs/pg_mall_order_payment.md`와 대상 수단의 `pg_mall_order_toss_payment.md`, `pg_mall_order_naver_payment.md`를 필요한 범위만 읽어라.
- 실제 주문서의 수단 노출과 금액을 우선하라.
  결제수단이 입력 radio와 label로 구성되면 표시 label을 클릭하라. 체크 상태를 확인하라.
- 55는 선택한 카드·계좌와 자동 선택된 프로모션을 확인하라.
  단일 프로모션의 수동 해제는 지원하지 않는다.
  마감된 프로모션으로 실패하면 사유를 기록하라. 테스트 중 프로모션 데이터를 임의 삭제하지 마라.
- 베네페이 테스트 공개키의 테스트 접두사와 네이버페이 `test*.pay.naver.com`처럼 실제 테스트 설정을 확인하라.
  키·인증 URL 전체를 리포트에 기록하지 마라.
- 비밀번호를 입력하기 전에 가상키패드의 현재 배치를 확인하라.
  확인한 배치에 따라 비밀번호를 입력하라. 숫자 위치를 고정하지 마라. 인증값을 로그에 남기지 마라.
- 배송비는 제주도와 같은 지역에 따라 달라질 수 있다.
  주문서의 최종금액을 기준으로 검증하라. 상품가격만 비교하지 마라.
- 상세 화면의 상품 수량·결제완료 상태·결제수단·금액을 대조하라.
  성공 주문을 임의 취소하지 마라.
