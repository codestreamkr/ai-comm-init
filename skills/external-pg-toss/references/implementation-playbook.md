# 토스 구현 플레이북

## 목차

- 기본 산출물
- 추천 파일 구조
- 코드 템플릿
- 웹훅 처리 원칙
- 기능별 확장 포인트
- 테스트 우선순위

## 기본 산출물

토스 연동 작업은 아래 코드 결과를 우선한다.

1. 내부 결제 포트
2. 토스 구현체와 HTTP 클라이언트
3. 요청·응답 DTO
4. 상태 변환기
5. 오류 코드 매퍼
6. 웹훅 진입점과 멱등성 처리
7. 테스트

## 추천 파일 구조

```text
payment/
  application/
    PaymentGateway.java
    PaymentQueryGateway.java
  domain/
    PaymentStatus.java
    PaymentMethod.java
  infrastructure/
    toss/
      TossPaymentGateway.java
      TossPaymentClient.java
      TossConfirmRequest.java
      TossCancelRequest.java
      TossPaymentResponse.java
      TossErrorMapper.java
      TossStatusTranslator.java
      TossWebhookController.java
      TossWebhookService.java
      TossWebhookSignatureVerifier.java
```

## 코드 템플릿

### 1. 내부 포트

```java
public interface PaymentGateway {
    PaymentApproveResult confirm(PaymentConfirmCommand command);
    PaymentCancelResult cancel(PaymentCancelCommand command);
    PaymentDetailsResult getPayment(String paymentKey);
}
```

### 2. 토스 구현체

```java
@Component
@RequiredArgsConstructor
public class TossPaymentGateway implements PaymentGateway {

    private final TossPaymentClient tossPaymentClient;
    private final TossStatusTranslator tossStatusTranslator;
    private final TossErrorMapper tossErrorMapper;

    @Override
    public PaymentApproveResult confirm(PaymentConfirmCommand command) {
        try {
            TossPaymentResponse response = tossPaymentClient.confirm(
                    new TossConfirmRequest(
                            command.paymentKey(),
                            command.orderId(),
                            command.amount()
                    )
            );
            return PaymentApproveResult.from(
                    response.paymentKey(),
                    tossStatusTranslator.translate(response.status()),
                    response.approvedAt()
            );
        } catch (TossApiException exception) {
            throw tossErrorMapper.toDomainException(exception);
        }
    }

    @Override
    public PaymentCancelResult cancel(PaymentCancelCommand command) {
        try {
            TossPaymentResponse response = tossPaymentClient.cancel(
                    command.paymentKey(),
                    new TossCancelRequest(command.cancelReason(), command.cancelAmount())
            );
            return PaymentCancelResult.from(
                    response.paymentKey(),
                    tossStatusTranslator.translate(response.status()),
                    response.cancels()
            );
        } catch (TossApiException exception) {
            throw tossErrorMapper.toDomainException(exception);
        }
    }

    @Override
    public PaymentDetailsResult getPayment(String paymentKey) {
        TossPaymentResponse response = tossPaymentClient.getPayment(paymentKey);
        return PaymentDetailsResult.from(
                response.paymentKey(),
                tossStatusTranslator.translate(response.status()),
                response.method()
        );
    }
}
```

### 3. 상태 변환기

```java
@Component
public class TossStatusTranslator {

    public PaymentStatus translate(String tossStatus) {
        return switch (tossStatus) {
            case "READY", "IN_PROGRESS" -> PaymentStatus.PENDING;
            case "DONE" -> PaymentStatus.APPROVED;
            case "CANCELED", "PARTIAL_CANCELED" -> PaymentStatus.CANCELED;
            case "ABORTED", "EXPIRED" -> PaymentStatus.FAILED;
            default -> throw new IllegalArgumentException("Unsupported Toss status: " + tossStatus);
        };
    }
}
```

### 4. 오류 매퍼

```java
@Component
public class TossErrorMapper {

    public RuntimeException toDomainException(TossApiException exception) {
        return switch (exception.code()) {
            case "PAYMENT_NOT_FOUND" -> new PaymentNotFoundException(exception.message());
            case "ALREADY_PROCESSED_PAYMENT" -> new DuplicatePaymentException(exception.message());
            case "INVALID_AUTHORIZE_AUTH" -> new PaymentAuthException(exception.message());
            default -> new ExternalPgException("TOSS", exception.code(), exception.message(), exception);
        };
    }
}
```

### 5. 웹훅 컨트롤러

```java
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/payments/toss/webhooks")
public class TossWebhookController {

    private final TossWebhookSignatureVerifier signatureVerifier;
    private final TossWebhookService tossWebhookService;

    @PostMapping
    public ResponseEntity<Void> handle(
            @RequestHeader("Toss-Signature") String signature,
            @RequestBody String rawBody
    ) {
        signatureVerifier.verify(signature, rawBody);
        tossWebhookService.process(rawBody);
        return ResponseEntity.ok().build();
    }
}
```

### 6. 웹훅 서비스

```java
@Service
@RequiredArgsConstructor
public class TossWebhookService {

    private final ObjectMapper objectMapper;
    private final ProcessedWebhookRepository processedWebhookRepository;
    private final PaymentWebhookHandler paymentWebhookHandler;

    @Transactional
    public void process(String rawBody) {
        TossWebhookEvent event = read(rawBody);

        if (processedWebhookRepository.existsByEventId(event.eventId())) {
            return;
        }

        paymentWebhookHandler.handle(event);
        processedWebhookRepository.save(new ProcessedWebhook(event.eventId()));
    }

    private TossWebhookEvent read(String rawBody) {
        try {
            return objectMapper.readValue(rawBody, TossWebhookEvent.class);
        } catch (JsonProcessingException exception) {
            throw new InvalidWebhookPayloadException(exception);
        }
    }
}
```

## 웹훅 처리 원칙

- 서명 검증은 컨트롤러 진입 직후에 수행한다.
- 중복 방지는 `eventId` 또는 토스가 보장하는 고유 식별자를 쓴다.
- 웹훅 성공 응답 전에 외부 API 재호출을 남발하지 않는다.
- 상태 반영 실패 시 재처리 가능하도록 예외를 삼키지 않는다.

## 기능별 확장 포인트

### 빌링

- `BillingKeyGateway`, `TossBillingClient`, `TossBillingErrorMapper`를 별도 파일로 둔다.
- 일회성 결제와 빌링키 발급 흐름을 같은 서비스에 섞지 않는다.

### 가상계좌

- 입금 대기, 입금 완료, 만료 상태를 일반 카드 승인 상태와 분리한다.
- 계좌 정보와 만료 시각은 도메인 모델에 명시적으로 둔다.

### 에스크로

- 배송 시작, 구매 확정, 에스크로 해제 같은 후속 이벤트를 일반 결제 승인 코드에 섞지 않는다.
- 주문 서비스와 결제 서비스의 책임 경계를 먼저 정리한다.

## 테스트 우선순위

1. 승인 성공·실패 매핑
2. 취소와 부분취소 매핑
3. 웹훅 중복 수신
4. 서명 검증 실패
5. 가상계좌 입금 완료 반영
6. 내부 상태와 토스 상태 불일치 시 보정 로직
