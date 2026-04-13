# MySQL Tuning Reference

`query-tuner`가 MySQL 또는 MariaDB로 판단했을 때만 이 문서를 읽는다.

## 필수 조회 쿼리

### 실행 계획

```sql
EXPLAIN
<튜닝 대상 쿼리>;

EXPLAIN ANALYZE
<튜닝 대상 쿼리>;

EXPLAIN FORMAT=JSON
<튜닝 대상 쿼리>;
```

### 인덱스 현황

```sql
SHOW INDEX FROM 테이블명;

SELECT index_name,
       seq_in_index,
       column_name,
       non_unique,
       cardinality,
       index_type
FROM   information_schema.STATISTICS
WHERE  table_schema = DATABASE()
  AND  table_name = '테이블명'
ORDER  BY index_name, seq_in_index;
```

### 카디널리티

```sql
SELECT COUNT(DISTINCT column_name) AS cardinality
FROM   테이블명;

SELECT column_name, cardinality
FROM   information_schema.STATISTICS
WHERE  table_name = '테이블명'
  AND  seq_in_index = 1;
```

## 선택 조회 쿼리

### 통계 최신성

```sql
SELECT table_name,
       table_rows,
       data_length,
       index_length,
       update_time
FROM   information_schema.TABLES
WHERE  table_schema = DATABASE()
  AND  table_name = '테이블명';

ANALYZE TABLE 테이블명;
```

### 데이터 규모

```sql
SELECT table_rows
FROM   information_schema.TABLES
WHERE  table_name = '테이블명';

SELECT COUNT(*) FROM 테이블명;
```

## EXPLAIN 해석 기준

- `type = ALL`: 풀스캔이네. 인덱스 또는 리라이팅 검토가 필요하네.
- `type = index`: 인덱스 풀스캔이군. 커버링 여부와 비용을 같이 봐야 하네.
- `type = range`, `ref`, `eq_ref`, `const`: 상대적으로 양호하네.
- `key = NULL`: 인덱스를 못 썼다는 뜻이지.
- `rows`: 예상 스캔 행 수다. 실제 처리 행 수와 차이를 같이 보게.
- `Extra = Using filesort`: 인덱스로 정렬을 못 없앴네.
- `Extra = Using temporary`: 임시 테이블 비용이 있군.
- `Extra = Using index`: 커버링 인덱스라 힙 접근이 줄었네.

## 인덱스 전략

- 복합 인덱스는 보통 `=` 조건, `IN`, 범위 조건 순으로 설계한다.
- 카디널리티 낮은 컬럼은 선두에 두기보다 후행 컬럼으로 미는 편이 낫다.
- `SELECT *`가 필요 없으면 커버링 인덱스 검토가 쉬워진다.
- 긴 문자열은 Prefix Index를 검토할 수 있지만 선택도 손실을 같이 본다.

```sql
ALTER TABLE orders
ADD INDEX idx_status_date (status, order_date);

ALTER TABLE orders
ADD INDEX idx_covering (status, order_date, amount);

ALTER TABLE users
ADD INDEX idx_email_prefix (email(20));

ALTER TABLE orders
ADD INDEX idx_status_date_online (status, order_date),
ALGORITHM=INPLACE,
LOCK=NONE;
```

## 자주 보는 리라이팅

- `NOT IN`은 `LEFT JOIN ... IS NULL` 또는 `NOT EXISTS`로 바꾸는 편이 안전할 때가 많다.
- `OR` 조건은 `UNION ALL`로 쪼개면 인덱스를 더 잘 탈 수 있네.
- 큰 `OFFSET` 페이징은 커서 기반 페이징이 낫다.
- `SELECT *`는 필요한 컬럼만 남겨야 판단이 쉬워진다.

## 옵티마이저 포인트

- 통계가 부정확하면 비용 모델 전체가 흔들린다.
- `optimizer_trace`로 왜 그 플랜을 택했는지 볼 수 있다.
- 조인 수가 많으면 완전 탐색 대신 greedy search로 내려가므로 예상 밖 플랜이 나올 수 있다.
- `hash_join`, `index_condition_pushdown`, `mrr`, `batched_key_access` 상태도 확인 가치가 있다.

```sql
SET optimizer_trace = "enabled=on";
<대상 쿼리>;
SELECT * FROM information_schema.OPTIMIZER_TRACE;
SET optimizer_trace = "enabled=off";

SELECT @@optimizer_switch;
```

## 통계와 히스토그램

- InnoDB 영구 통계 표본 수가 너무 작으면 오판이 늘어난다.
- 데이터 쏠림이 크면 히스토그램이 먼저다.
- 인덱스 추가보다 `ANALYZE TABLE`이 먼저일 때가 적지 않네.

```sql
SHOW VARIABLES LIKE 'innodb_stats_persistent_sample_pages';
SHOW VARIABLES LIKE 'innodb_stats_auto_recalc';

ANALYZE TABLE orders
UPDATE HISTOGRAM ON status, priority
WITH 100 BUCKETS;

SELECT *
FROM   information_schema.COLUMN_STATISTICS
WHERE  table_name = 'orders';
```

## 답변 시 유의점

- `EXPLAIN ANALYZE`가 없으면 추정 기반 판단임을 분명히 적는다.
- 예상 rows와 실제 rows 차이가 크면 통계 문제를 먼저 언급한다.
- 인덱스를 제안할 때는 쓰기 비용과 운영 영향까지 같이 적는다.
