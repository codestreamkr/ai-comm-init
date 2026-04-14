# Spring Data JPA 쿼리 패턴

## 쿼리 패턴 우선순위

1. Query Methods - 단순 조회
2. QueryDSL - 동적 + 복잡 쿼리, 의존성이 있을 때만
3. `@Query` - 벌크 연산, 네이티브 쿼리, 정적인 복잡 쿼리

단순한 걸 복잡한 방법으로 풀지 않는다. Query Method로 되는 걸 QueryDSL로 짜면 유지보수만 어려워진다.

## Entity 기본 가이드

스킬 범위는 쿼리 패턴이지만, Entity 작성 시 최소한의 판단 기준은 여기서 제공한다.

### ID 전략

| 전략 | 사용 기준 |
| --- | --- |
| `IDENTITY` | MySQL, MariaDB 기본. 단순하고 검증됨 |
| `SEQUENCE` | PostgreSQL, Oracle 기본. 배치 INSERT에 유리 |
| `TABLE` | 쓰지 않는다 |
| `UUID` | 분산 환경, URL 노출 시 |

프로젝트에 기존 전략이 있으면 그대로 따른다.

### 연관관계 기본 원칙

- 양방향보다 단방향을 먼저 고려한다.
- `@ManyToOne`을 기본으로 보고 `@OneToMany`는 진짜 필요할 때만 쓴다.
- 양방향이면 연관관계 편의 메서드를 반드시 작성한다.
- `CascadeType.ALL`은 부모-자식 생명주기가 완전히 같을 때만 쓴다.

### Auditing

- 프로젝트에 `BaseEntity`가 있으면 상속한다.
- 없으면 `createdAt`, `updatedAt` 정도만 `@CreatedDate`, `@LastModifiedDate`로 관리한다.

### Soft Delete

- 프로젝트에 기존 패턴이 있으면 따른다.
- 없으면 별도 제안하지 않는다. 요청이 있을 때만 검토한다.

연관관계 상세 설계, 상속 전략, Embeddable, 락 전략은 이 문서 범위 밖이다. 필요하면 별도 판단이 필요하다고 명시한다.

## Query Methods

### 사용 기준

- 조건 2~3개 이하의 단순 조회
- 메서드 이름만으로 의도가 명확할 때

### 네이밍 규칙

| 목적 | 패턴 | 예시 |
| --- | --- | --- |
| 단건 조회 | `findBy...` | `findByEmail(String email)` |
| 목록 조회 | `findAllBy...` | `findAllByStatus(Status status)` |
| 존재 확인 | `existsBy...` | `existsByEmail(String email)` |
| 건수 | `countBy...` | `countByStatus(Status status)` |
| 삭제 | `deleteBy...` | `deleteByExpiredAtBefore(LocalDateTime date)` |

### 한계선

- 조건 3개 이상이면 메서드 이름이 너무 길어진다. `@Query` 또는 QueryDSL로 전환한다.
- 동적 조건이 필요하면 QueryDSL을 검토한다.
- `OR` 조건이 복잡하면 `@Query`를 검토한다.

## QueryDSL 패턴

의존성이 있을 때만 사용한다.

```java
public interface OrderRepositoryCustom {
    Page<OrderDto> searchOrders(OrderSearchCondition condition, Pageable pageable);
}

public class OrderRepositoryImpl implements OrderRepositoryCustom {

    private final JPAQueryFactory queryFactory;

    @Override
    public Page<OrderDto> searchOrders(OrderSearchCondition condition, Pageable pageable) {
        List<OrderDto> content = queryFactory
            .select(new QOrderDto(
                order.id,
                order.orderNumber,
                order.status,
                order.createdAt
            ))
            .from(order)
            .where(
                statusEq(condition.getStatus()),
                createdAtBetween(condition.getStartDate(), condition.getEndDate())
            )
            .offset(pageable.getOffset())
            .limit(pageable.getPageSize())
            .orderBy(order.createdAt.desc())
            .fetch();

        JPAQuery<Long> countQuery = queryFactory
            .select(order.count())
            .from(order)
            .where(
                statusEq(condition.getStatus()),
                createdAtBetween(condition.getStartDate(), condition.getEndDate())
            );

        return PageableExecutionUtils.getPage(content, pageable, countQuery::fetchOne);
    }

    private BooleanExpression statusEq(OrderStatus status) {
        return status != null ? order.status.eq(status) : null;
    }

    private BooleanExpression createdAtBetween(LocalDate start, LocalDate end) {
        if (start == null && end == null) return null;
        if (start != null && end != null) {
            return order.createdAt.between(
                start.atStartOfDay(), end.plusDays(1).atStartOfDay());
        }
        if (start != null) return order.createdAt.goe(start.atStartOfDay());
        return order.createdAt.lt(end.plusDays(1).atStartOfDay());
    }
}
```

### 동적 조건 패턴

- `BooleanExpression` 메서드로 분리하고 `null` 반환 시 조건을 무시한다.
- `where()`에 `null`이 들어가면 자동 무시되는 QueryDSL 특성을 활용한다.

### Projection

- `@QueryProjection` + DTO 생성자: 컴파일 타임 체크 가능
- `Projections.constructor()`: DTO에 QueryDSL 의존성을 남기고 싶지 않을 때

## `@Query` (JPQL / Native)

### 사용 기준

- 벌크 연산
- 네이티브 쿼리가 필요한 경우
- Query Method로 표현하기 어려운 단일 정적 쿼리

### 벌크 연산

```java
@Modifying(clearAutomatically = true)
@Query("UPDATE Order o SET o.status = :status WHERE o.createdAt < :date")
int bulkUpdateStatus(@Param("status") OrderStatus status,
                     @Param("date") LocalDateTime date);
```

- `clearAutomatically = true`: 벌크 연산 후 영속성 컨텍스트를 자동 초기화한다.
- 벌크 연산은 영속성 컨텍스트를 무시하고 DB에 직접 실행된다는 점을 항상 주의한다.

### 네이티브 쿼리

```java
@Query(value = "SELECT * FROM orders WHERE MATCH(description) AGAINST(:keyword)",
       nativeQuery = true)
List<Order> fullTextSearch(@Param("keyword") String keyword);
```

- 네이티브 쿼리는 DB 종속성을 만든다. 진짜 필요한 경우에만 사용한다.

## N+1 감지 및 해결

### N+1이 발생하는 상황

- `@OneToMany`, `@ManyToMany`의 LAZY 로딩 컬렉션을 루프에서 접근
- `@ManyToOne`도 여러 엔티티를 조회하면서 연관 엔티티를 각각 로딩

### 해결 우선순위

1. fetch join

```java
@Query("SELECT o FROM Order o JOIN FETCH o.orderItems WHERE o.id = :id")
Optional<Order> findByIdWithItems(@Param("id") Long id);
```

2. `@EntityGraph`

```java
@EntityGraph(attributePaths = {"orderItems", "orderItems.product"})
Optional<Order> findById(Long id);
```

3. `default_batch_fetch_size`

```yaml
spring:
  jpa:
    properties:
      hibernate:
        default_batch_fetch_size: 100
```

### 주의사항

- fetch join + 페이징은 컬렉션 기준 메모리 페이징 경고가 날 수 있다.
- 컬렉션 fetch join은 1개만 가능하다. 여러 개가 필요하면 쿼리를 분리하거나 배치 페치로 푼다.

## 페이징과 정렬

### Page vs Slice

| 항목 | `Page` | `Slice` |
| --- | --- | --- |
| 전체 건수 조회 | O | X |
| 다음 페이지 존재 여부 | O | O |
| 적합한 UI | 페이지 번호 네비게이션 | 더보기, 무한 스크롤 |

### 카운트 쿼리 최적화

```java
@Query(value = "SELECT o FROM Order o JOIN o.member m WHERE m.status = :status",
       countQuery = "SELECT COUNT(o) FROM Order o JOIN o.member m WHERE m.status = :status")
Page<Order> findByMemberStatus(@Param("status") MemberStatus status, Pageable pageable);
```

- 복잡한 조회 쿼리에서는 `countQuery`를 별도로 두고 불필요한 JOIN을 제거한다.

### 정렬

- 단순 정렬: `Pageable`의 `Sort` 사용
- 복잡한 정렬: `@Query` 또는 QueryDSL에 직접 명시

## Projection

### Interface Projection

```java
public interface OrderSummary {
    Long getId();
    String getOrderNumber();
    OrderStatus getStatus();
}

List<OrderSummary> findAllByStatus(OrderStatus status);
```

- 필요한 컬럼만 조회하므로 성능에 유리하다.
- 중첩 Projection은 N+1을 유발할 수 있으니 주의한다.

### DTO Projection

```java
@Query("SELECT new com.example.dto.OrderDto(o.id, o.orderNumber, o.status) " +
       "FROM Order o WHERE o.status = :status")
List<OrderDto> findOrderDtoByStatus(@Param("status") OrderStatus status);
```

- 패키지 경로 전체를 써야 하는 불편함은 있지만 타입은 명확하다.

### 선택 기준

- 단순 읽기 전용: Interface Projection
- 복잡한 변환이나 계산이 필요함: DTO Projection 또는 QueryDSL Projection

## 안티패턴

### OSIV와 LazyInitializationException

- OSIV가 꺼져 있으면 트랜잭션 밖에서 LAZY 로딩 시 예외가 난다.
- 서비스 레이어에서 필요한 데이터를 모두 로딩하고 DTO로 변환한 뒤 반환한다.

### `save()` 오용

- 이미 영속 상태인 엔티티에 `save()`를 다시 호출하면 불필요한 `merge`가 발생할 수 있다.
- 변경 감지를 우선 활용한다.

### `findAll()` 후 필터링

- 전체를 가져온 뒤 Java에서 필터링하면 DB를 제대로 쓰지 않는 것이다.
- `WHERE` 조건을 쿼리에 넣는다.

### 양방향 연관관계 무한 루프

- `toString()`, JSON 직렬화에서 순환 참조가 발생할 수 있다.
- DTO로 변환한 뒤 반환한다. Entity를 직접 API 응답으로 내보내지 않는다.
