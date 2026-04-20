# KCP 역공학 가이드

## 목차

- 첫 탐색 키워드
- 인벤토리 표준
- 포트 추출 순서
- 코드 템플릿
- 회귀 위험 체크

## 첫 탐색 키워드

아래 키워드로 시작한다.

```text
kcp
pg
payment
approve
approval
cancel
billing
escrow
noti
webhook
site_cd
ordr_idxx
res_cd
res_msg
```

설정 파일에서는 아래도 함께 본다.

- 상점 ID
- callback URL
- return URL
- 가맹점 키
- 모듈 경로

## 인벤토리 표준

최소한 아래 표를 만든다.

| 파일 | 역할 | 입력 | 출력 | KCP 의존성 | Toss 전환 시 조치 |
|---|---|---|---|---|---|
| `KcpController` | 결제 승인 진입점 | orderId, amount | 승인 결과 | 높음 | 포트 뒤로 이동 |
| `KcpService` | 승인·취소 orchestration | command | domain result | 중간 | 공통 서비스로 승격 가능 |
| `KcpStatusMapper` | 상태 변환 | res_cd | internal status | 높음 | 벤더별 유지 |

## 포트 추출 순서

1. 응답 코드 변환부를 찾는다.
2. 승인, 취소, 조회, 웹훅 처리를 각각 분리한다.
3. 외부 요청 조립 코드를 도메인 서비스에서 떼어낸다.
4. 벤더 특화 DTO를 인프라 계층으로 내린다.
5. 공통 포트를 먼저 만든 뒤 KCP 구현체를 붙인다.

## 코드 템플릿

### 1. KCP 구현을 감싸는 포트

```java
public interface PaymentGateway {
    PaymentApproveResult confirm(PaymentConfirmCommand command);
    PaymentCancelResult cancel(PaymentCancelCommand command);
}
```

### 2. 현행 KCP 구현체

```java
@Component
@RequiredArgsConstructor
public class KcpPaymentGateway implements PaymentGateway {

    private final KcpApprovalClient kcpApprovalClient;
    private final KcpCancelClient kcpCancelClient;
    private final KcpStatusTranslator kcpStatusTranslator;
    private final KcpErrorMapper kcpErrorMapper;

    @Override
    public PaymentApproveResult confirm(PaymentConfirmCommand command) {
        try {
            KcpApprovalResponse response = kcpApprovalClient.approve(command);
            return PaymentApproveResult.from(
                    response.transactionId(),
                    kcpStatusTranslator.translate(response.resCd()),
                    response.approvedAt()
            );
        } catch (KcpApiException exception) {
            throw kcpErrorMapper.toDomainException(exception);
        }
    }

    @Override
    public PaymentCancelResult cancel(PaymentCancelCommand command) {
        try {
            KcpCancelResponse response = kcpCancelClient.cancel(command);
            return PaymentCancelResult.from(
                    response.transactionId(),
                    kcpStatusTranslator.translate(response.resCd())
            );
        } catch (KcpApiException exception) {
            throw kcpErrorMapper.toDomainException(exception);
        }
    }
}
```

### 3. 상태 변환기

```java
@Component
public class KcpStatusTranslator {

    public PaymentStatus translate(String resCd) {
        return switch (resCd) {
            case "0000" -> PaymentStatus.APPROVED;
            case "9502", "9562" -> PaymentStatus.CANCELED;
            default -> PaymentStatus.FAILED;
        };
    }
}
```

## 회귀 위험 체크

- 승인 API와 화면 리다이렉트 흐름이 같이 묶여 있는가
- 배치가 KCP 거래번호를 직접 읽는가
- 관리자 화면이 KCP 응답 코드를 그대로 표시하는가
- 부분취소 금액 계산 로직이 KCP 응답 구조에 묶여 있는가
- 비동기 통지 실패 시 수동 재처리 절차가 있는가
