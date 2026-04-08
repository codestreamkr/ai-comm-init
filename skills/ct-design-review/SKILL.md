---
name: ct-design-review
description: 여러 전문가 관점으로 기능 또는 설계안을 검토하고, 핵심 쟁점, 전문가별 의견, 충돌 조율 결과, 최종 결론, 권장 구현 방향, 남은 이슈를 담은 Markdown 설계 검토 문서를 작성한다. 새로운 기능 제안, 요구사항 검토, 구현 전 설계 리뷰, API/UI/보안/QA 관점의 합의안 도출, 전문가 의견을 구조화해 문서로 남겨야 할 때 사용한다.
---

# ct-design-review

## 실행 원칙

- 사용자 요청을 바로 전문가 의견으로 흩트리지 말고, 먼저 공통 브리프를 짧게 정리하라.
- 기능 요약과 기능 성격 분류를 분리하라. 요약은 사실 정리이고, 성격 분류는 검토 전략 선택 근거다.
- 전문가 후보군은 고정하되 실제 호출 대상은 요청 성격에 따라 동적으로 선정하라.
- 독립 검토는 가능하면 병렬로 진행하되, 세션 정책상 서브에이전트 위임이 허용될 때만 병렬 에이전트를 사용하라.
- 서브에이전트 위임이 불가능하면 같은 단계 구조를 유지한 채 직접 전문가별 의견을 순차 작성하라.
- 후행 검토는 `필요 시`라고 쓰지 말고 명시적 트리거 규칙에 따라 추가하라.
- 최종 문서는 토론 로그가 아니라 의사결정 결과물로 작성하라.
- 문서 본문에는 이전 초안이나 수정 과정을 남기지 말고 최종안만 기록하라.
- 문서 마지막에는 반드시 `## 이력관리` 섹션을 두고 `- YYYY-MM-DD: 변경 내용 요약` 형식으로 마감하라.

## 준비 자료

- 전문가 선정과 후행 검토 규칙이 필요하면 [`references/selection-rules.md`](~/.codex/skills/ct-design-review/references/selection-rules.md)를 읽어라.
- 최종 문서 형식이 필요하면 [`references/document-template.md`](~/.codex/skills/ct-design-review/references/document-template.md)를 읽어라.
- 전문가 역할 정의는 필요한 파일만 골라 읽어라.
  - [`references/experts/product.md`](~/.codex/skills/ct-design-review/references/experts/product.md)
  - [`references/experts/domain.md`](~/.codex/skills/ct-design-review/references/experts/domain.md)
  - [`references/experts/backend.md`](~/.codex/skills/ct-design-review/references/experts/backend.md)
  - [`references/experts/frontend-ux.md`](~/.codex/skills/ct-design-review/references/experts/frontend-ux.md)
  - [`references/experts/qa.md`](~/.codex/skills/ct-design-review/references/experts/qa.md)
  - [`references/experts/security.md`](~/.codex/skills/ct-design-review/references/experts/security.md)
  - [`references/experts/sre.md`](~/.codex/skills/ct-design-review/references/experts/sre.md)
  - [`references/experts/tech-lead.md`](~/.codex/skills/ct-design-review/references/experts/tech-lead.md)

## 작업 순서

### 1. 프리패스

- 사용자 요청을 바탕으로 아래 항목을 먼저 확정하라.
  - 검토 대상
  - 요청 배경과 목표
  - 기능 요약
  - 기능 성격 분류
- 기능 성격 분류 결과를 근거로 1차 전문가와 후행 전문가 후보를 선정하라.
- 초기 핵심 쟁점을 3~7개로 정리하라.
- 사용자가 별도 쟁점을 준 경우에는 그대로 반영하고, 누락된 쟁점만 보완하라.

### 2. 1차 전문가 검토

- 기획, 도메인, 백엔드, 프론트엔드/UX처럼 독립 검토가 가능한 전문가를 먼저 투입하라.
- 1차 검토는 서로의 답변을 보지 않은 상태에서 작성하는 것을 우선하라.
- 각 전문가 의견은 아래 4개 항목으로 고정하라.
  - 판단
  - 근거
  - 우려사항
  - 후속 검토 필요 사항

### 3. 2차 후행 검토

- QA, 보안, SRE처럼 선행 의견이나 설계 초안이 있어야 검토 품질이 올라가는 역할은 후행 검토로 분리하라.
- 후행 검토 여부는 감으로 정하지 말고 [`references/selection-rules.md`](~/.codex/skills/ct-design-review/references/selection-rules.md)의 트리거 규칙을 따르라.
- 후행 전문가는 1차 의견과 핵심 쟁점을 검토한 뒤 추가 리스크와 검증 포인트를 보강하라.

### 4. 조정 및 결론

- 기술 리드 관점으로 의견 충돌 지점을 먼저 정리하라.
- 단순 다수결로 결론내리지 말고, 사용자 가치, 구현 현실성, 품질 리스크, 운영 영향을 함께 비교하라.
- 최종 결론에는 아래를 반드시 포함하라.
  - 채택안
  - 제외안 또는 보류안
  - 선택 이유
  - 남은 이슈

### 5. 문서 작성

- 최종 결과는 Markdown 문서로 저장하라.
- 사용자가 파일명을 지정하지 않으면 현재 작업 경로에 아래 우선순위로 저장하라.
  1. `{topic}_design_review.md`
  2. 제목을 안정적으로 슬러그화하기 어렵다면 `design_review.md`
- 파일 저장 후 터미널에는 `검토 대상`, `참여 전문가`, `최종 결론` 3개 항목만 요약해 출력하라.
- 섹션 순서는 반드시 아래를 따르라.
  1. 검토 대상
  2. 요청 배경과 목표
  3. 기능 요약
  4. 기능 성격 분류
  5. 참여 전문가
  6. 핵심 쟁점
  7. 전문가별 의견
  8. 충돌 지점과 조율 결과
  9. 최종 결론
  10. 권장 구현 방향
  11. 남은 이슈
  12. 다음 단계
  13. 이력관리

## 참여 전문가 작성 규칙

- `참여 전문가` 섹션에는 표를 사용하라.
- 최소 컬럼은 아래 4개를 유지하라.
  - 전문가
  - 역할 요약
  - 선정 근거
  - 검토 단계
- `검토 단계`는 `1차`, `후행`, `최종 조정` 중 하나로 적어라.

## 핵심 쟁점 작성 규칙

- 프리패스에서 도출한 쟁점과 검토 중 새로 드러난 쟁점을 함께 관리하라.
- 각 쟁점에는 가능하면 `초기` 또는 `추가` 표시를 붙여라.
- 쟁점은 질문형보다 판단이 필요한 문장형으로 정리하라.

## 종료 체크리스트

- 전문가 선정 근거가 기능 성격 분류와 연결되는가.
- 참여 전문가 표에 단계 구분이 보이는가.
- 핵심 쟁점이 초기/추가 구분을 반영하는가.
- 충돌 지점과 조율 결과가 단순 의견 요약이 아니라 실제 선택 근거를 담는가.
- `권장 구현 방향`이 MVP 범위, 제외 범위, 우선순위를 담는가.
- `남은 이슈`와 `다음 단계`가 분리되어 있는가.
- 터미널에 `검토 대상`, `참여 전문가`, `최종 결론` 요약이 출력됐는가.
- 문서 끝에 `## 이력관리`가 있는가.
