# Oracle Tuning Reference

`ct-query-tuner`가 Oracle로 판단했을 때만 이 문서를 읽는다.

## 필수 조회 쿼리

### 실행 계획

```sql
EXPLAIN PLAN FOR
<튜닝 대상 쿼리>;

SELECT *
FROM   TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'ALLSTATS LAST'));

SET AUTOTRACE ON EXPLAIN STATISTICS;
<튜닝 대상 쿼리>;
SET AUTOTRACE OFF;
```

### 인덱스 현황

```sql
SELECT i.index_name,
       i.index_type,
       i.uniqueness,
       c.column_name,
       c.column_position,
       c.descend
FROM   user_indexes i
JOIN   user_ind_columns c
       ON i.index_name = c.index_name
WHERE  i.table_name = UPPER('테이블명')
ORDER  BY i.index_name, c.column_position;
```

### 카디널리티

```sql
SELECT column_name,
       num_distinct,
       num_nulls,
       density,
       low_value,
       high_value
FROM   user_tab_col_statistics
WHERE  table_name = UPPER('테이블명')
ORDER  BY num_distinct DESC;
```

## 선택 조회 쿼리

### 통계 최신성

```sql
SELECT table_name,
       num_rows,
       last_analyzed,
       sample_size
FROM   user_tables
WHERE  table_name = UPPER('테이블명');

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, '테이블명', CASCADE => TRUE);
```

### 데이터 규모

```sql
SELECT table_name, num_rows
FROM   user_tables
WHERE  table_name IN ('테이블명1', '테이블명2');
```

## 실행 계획 해석 기준

- `TABLE ACCESS FULL`: 풀스캔이네. 선택도와 멀티블록 읽기 이득을 같이 봐야 하네.
- `INDEX RANGE SCAN`: 범위 스캔이군. 후속 테이블 접근 비용을 같이 봐야지.
- `INDEX FULL SCAN`: 인덱스만 훑는 게 정말 이득인지 확인해야 하네.
- `NESTED LOOPS`: 소량 outer일 때 유리하네.
- `HASH JOIN`: 대량 조인일 때 낫지만 메모리 부족이면 금방 무너진다.
- `CARDINALITY`와 실제 rows 차이가 크면 통계 문제를 먼저 의심한다.

## 인덱스 전략

- 선택도 높은 컬럼을 우선 본다.
- 복합 인덱스는 `=` 조건 뒤에 범위 조건을 두는 편이 일반적이다.
- WHERE와 ORDER BY를 같이 만족시키는지 늘 같이 본다.
- Bitmap 인덱스는 DW 성격에서만 조심스럽게 권한다. OLTP에선 DML 비용이 크다.

```sql
CREATE INDEX idx_orders_status_date
ON orders(status, order_date);

CREATE INDEX idx_orders_upper_name
ON orders(UPPER(customer_name));

CREATE BITMAP INDEX idx_orders_status
ON orders(status);
```

## 힌트와 제어

힌트는 왜 CBO가 스스로 좋은 선택을 못 하는지 설명한 뒤에만 제안한다.

```sql
SELECT /*+ INDEX(o idx_orders_status_date) */
       o.*
FROM   orders o
WHERE  o.status = 'COMPLETE';

SELECT /*+ USE_NL(o d) */ ...
SELECT /*+ USE_HASH(o d) */ ...
SELECT /*+ PARALLEL(o 4) */ ...
```

## 옵티마이저 포인트

- Oracle은 CBO가 중심이다. 통계가 틀리면 나머지 판단도 같이 흔들린다.
- Bind Variable Peeking 때문에 첫 바인드 값이 이후 플랜을 오염시킬 수 있다.
- Adaptive Cursor Sharing이 있더라도 첫 플랜이 충분히 나쁠 수 있다.
- 반복적으로 좋은 플랜을 유지해야 하면 SQL Plan Baseline을 검토한다.

## 통계와 확장 통계

- 데이터 쏠림이 있는 컬럼은 히스토그램이 중요하다.
- 다중 컬럼 상관관계는 확장 통계 없이는 잘못 추정되기 쉽다.
- 통계 갱신만으로 해결되는 문제를 인덱스로 덮지 않는다.

```sql
EXEC DBMS_STATS.GATHER_TABLE_STATS(
  USER,
  '테이블명',
  METHOD_OPT => 'FOR COLUMNS SIZE AUTO 컬럼명'
);

SELECT DBMS_STATS.CREATE_EXTENDED_STATS(USER, 'orders', '(city, zipcode)')
FROM   dual;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'orders');
```

## Oracle에서 자주 짚는 함정

- `OR` 조건에서 OR-Expansion이 기대만큼 안 될 수 있다.
- 함수 적용 컬럼은 Function-Based Index 없이는 인덱스를 못 탈 수 있다.
- `NOT IN`은 `NULL` 때문에 오판하기 쉬우니 `NOT EXISTS` 검토가 먼저다.
- 바인드 변수 편차가 큰 컬럼은 peeking 영향 여부를 꼭 본다.

## 답변 시 유의점

- `ALLSTATS LAST` 같은 실제 실행 통계가 없으면 확정 표현을 줄인다.
- 인덱스 제안 전 통계 갱신, 히스토그램, 확장 통계 가능성을 먼저 적는다.
- 힌트는 임시 우회인지 장기 운영안인지 구분해서 제시한다.
