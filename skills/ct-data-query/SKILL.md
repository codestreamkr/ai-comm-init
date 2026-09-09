---
name: ct-data-query
description: 사용자가 `$ct-data-query`를 명시적으로 호출하면 현재 데이터베이스 환경과 실행 근거로 SQL 성능 원인을 분석하고 개선안을 검증한다. 지원 작업은 `tune`이다.
---

# CT Data Query

정본은 현재 DB 환경, 스키마, 실행 계획 또는 측정이다. DBMS와 버전을 가정하지 않는다.

## 호출

- `$ct-data-query` 또는 `$ct-data-query ?`: 안내. 실행하지 않는다.
- `$ct-data-query tune ?`: `tune` 안내.
- `$ct-data-query <쿼리 또는 대상>` 또는 `$ct-data-query tune <쿼리 또는 대상>`: `tune`으로 실행.

`--`로 시작하면 지원하지 않는 옵션이다. `tune`만 있고 대상이 없으면 실행하지 않고 `tune` 안내를 한다.

## 작업

- `tune`: 병목 근거와 우선순위 있는 개선안. 앱 레이어 구조 변경은 `ct-code-spring`이다.
  - 예: `$ct-data-query OrderMapper.xml의 findOrders`

## 역할 규칙

- 확인하지 않은 DBMS, 버전, 인덱스, 통계를 전제로 쓰지 않는다.
- 실행 계획 또는 측정이 없는 개선은 추정으로 표시한다. 인덱스 제안도 같다.
- 수집하지 못한 조건은 한계로 남긴다.
