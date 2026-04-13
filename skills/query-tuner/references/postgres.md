# PostgreSQL Tuning Reference

`query-tuner`가 PostgreSQL로 판단했을 때만 이 문서를 읽는다.

## 필수 조회 쿼리

### 실행 계획

```sql
EXPLAIN (ANALYZE, BUFFERS)
<튜닝 대상 쿼리>;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
<튜닝 대상 쿼리>;

BEGIN;
EXPLAIN (ANALYZE, BUFFERS) UPDATE ...;
ROLLBACK;
```

### 인덱스 현황

```sql
SELECT indexname,
       indexdef,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM   pg_indexes
LEFT   JOIN pg_class
       ON pg_class.relname = indexname
WHERE  tablename = '테이블명';

SELECT indexrelid::regclass AS index_name,
       idx_scan,
       idx_tup_read,
       idx_tup_fetch
FROM   pg_stat_user_indexes
WHERE  relid = '테이블명'::regclass
ORDER  BY idx_scan;
```

### 카디널리티

```sql
SELECT attname AS column_name,
       n_distinct,
       correlation,
       null_frac,
       most_common_vals,
       most_common_freqs
FROM   pg_stats
WHERE  tablename = '테이블명'
ORDER  BY attname;
```

## 선택 조회 쿼리

### 통계 최신성

```sql
SELECT relname,
       n_live_tup,
       n_dead_tup,
       last_analyze,
       last_autoanalyze,
       last_vacuum,
       last_autovacuum
FROM   pg_stat_user_tables
WHERE  relname = '테이블명';

ANALYZE 테이블명;
VACUUM ANALYZE 테이블명;
```

### 데이터 규모

```sql
SELECT reltuples::bigint AS estimated_rows,
       pg_size_pretty(pg_total_relation_size(oid)) AS total_size
FROM   pg_class
WHERE  relname = '테이블명';

SELECT COUNT(*) FROM 테이블명;
```

## EXPLAIN 해석 기준

- `Seq Scan`: 풀스캔이네. 인덱스보다 이게 더 싸다고 본 이유를 찾아야 하네.
- `Index Scan`: 인덱스 후 힙 접근이 있군. 랜덤 I/O가 병목인지 봐야지.
- `Index Only Scan`: 좋은 신호지만 visibility map 상태도 영향이 있다.
- `Bitmap Index Scan`: 여러 조건을 조합하거나 많은 행을 읽을 때 자주 보인다.
- `actual time`, `rows`, `loops`, `Buffers`를 같이 봐야 원인이 보인다.
- 예상 rows와 actual rows가 크게 다르면 통계나 데이터 쏠림 쪽이 먼저다.

## 인덱스 전략

- 부분 인덱스는 PostgreSQL에서 특히 강력하다.
- 표현식 인덱스로 함수 조건을 직접 커버할 수 있다.
- `correlation`이 낮으면 Index Scan 비용이 과소평가되지 않는지 본다.
- JSONB나 배열은 GIN, 범위형이나 공간형은 GiST를 먼저 검토한다.

```sql
CREATE INDEX idx_orders_status_date
ON orders(status, order_date);

CREATE INDEX idx_orders_active
ON orders(order_date)
WHERE status = 'ACTIVE';

CREATE INDEX idx_orders_year
ON orders(EXTRACT(YEAR FROM order_date));

CREATE INDEX idx_meta_gin
ON orders USING GIN(metadata);

CREATE INDEX CONCURRENTLY idx_orders_status
ON orders(status);
```

## 리라이팅과 세션 제어

PostgreSQL은 힌트보다 세션 설정으로 플래너 판단을 비교하는 편이다.

```sql
SET enable_nestloop = OFF;
SET enable_seqscan = OFF;
SET work_mem = '256MB';

RESET enable_nestloop;
RESET enable_seqscan;
RESET work_mem;
```

- 이 설정은 원인 확인용이다. 영구 설정으로 바로 권하지 않는다.
- `NOT IN`은 `NOT EXISTS`나 `LEFT JOIN ... IS NULL`로 바꿔보는 게 안전할 때가 많다.
- 대용량 `OFFSET` 페이징은 keyset 페이징으로 바꾸는 편이 낫다.

## 플래너 포인트

- SSD인데 `random_page_cost`가 기본값 4.0이면 인덱스 스캔을 과소평가할 수 있다.
- `effective_cache_size`와 `work_mem`이 현실과 동떨어지면 비용 계산이 흔들린다.
- 짧은 OLTP 쿼리는 JIT 이득보다 컴파일 오버헤드가 더 클 수 있다.
- Prepared Statement가 generic plan으로 넘어가면서 느려지는 경우도 있다.

```sql
SHOW random_page_cost;
SHOW effective_cache_size;
SHOW work_mem;
SHOW jit;

SET jit = off;
SET plan_cache_mode = force_custom_plan;
```

## 통계 포인트

- `default_statistics_target`가 너무 낮으면 쏠림을 잘 못 잡는다.
- 특정 컬럼만 통계 타깃을 높이는 방식이 실무에서 유용하다.
- dead tuple이 많으면 통계보다 먼저 VACUUM 쪽이 원인일 수 있다.

```sql
ALTER TABLE orders
ALTER COLUMN status
SET STATISTICS 1000;

ANALYZE orders;
```

## 답변 시 유의점

- `EXPLAIN (ANALYZE, BUFFERS)`가 없으면 추정 기반 판단임을 분명히 적는다.
- 인덱스 제안 전 `ANALYZE`, `VACUUM`, 비용 파라미터, generic plan 가능성을 같이 본다.
- `CREATE INDEX CONCURRENTLY`는 트랜잭션 블록 밖에서 실행해야 한다는 점을 같이 적는다.
