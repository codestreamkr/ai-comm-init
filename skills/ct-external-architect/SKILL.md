---
name: ct-external-architect
description: 외부 시스템 연동 구조를 분석하고 설계 문서로 정리한다. 사용자가 `$ct-external-architect`를 명시적으로 호출한 경우에만 사용한다.
---

# ct-external-architect

이 스킬은 위임형 전용 절차다.

## 목적

- `호페형`은 외부 시스템 연동 구조를 분석하고 설계문서로 정리하는 스킬이다.

## 실행 순서

1. [workflow/00-entry.md](workflow/00-entry.md)
2. [workflow/10-checklist.md](workflow/10-checklist.md)
3. 해당 벤더의 `ENTRY.md`
4. [workflow/20-report.md](workflow/20-report.md)
5. [workflow/30-proposal.md](workflow/30-proposal.md)
6. [workflow/40-delegate.md](workflow/40-delegate.md)
7. [workflow/50-finish.md](workflow/50-finish.md)

## 전역 규칙

- 실행 세부 규칙은 `workflow/*.md`를 따른다.
- 벤더별 세부 기준은 해당 `vendors/*/ENTRY.md`를 따른다.
- 웹훅, 상태값, 헤더명, 수치, 지원 범위는 공식 문서 확인 후에만 단정한다.

## 벤더 진입점

- 토스페이먼츠: [vendors/toss/ENTRY.md](vendors/toss/ENTRY.md)
- NHN KCP: [vendors/kcp/ENTRY.md](vendors/kcp/ENTRY.md)
- 카카오페이: [vendors/kakaopay/ENTRY.md](vendors/kakaopay/ENTRY.md)
- 네이버페이: [vendors/naverpay/ENTRY.md](vendors/naverpay/ENTRY.md)

## 벤더가 불분명할 때

- 먼저 현재 구조를 보고 주 벤더를 판별한다.
- 둘 이상이 섞여 있으면 이번 요청의 주 대상 벤더를 하나 정해 진입하고, 나머지는 리포트의 비교 대상이나 공존 대상으로만 다룬다.
- 어떤 벤더도 특정되지 않으면 `workflow/20-report.md`의 공통 확인 항목으로 시작한다.

## 문서 원칙

- 구조와 책임 경계를 먼저 쓴다.
- 벤더 원본 상태와 내부 도메인 상태를 분리해서 설명한다.
- 공식 문서로 확정되지 않는 내용은 `확인 필요`로 남긴다.

## 역할

- 메인 어시스턴트: 실행 순서 관리, 결과 검수, 최종 문서 통합
- developer: 개발 가이드 작성, 저장 모델, API 계약, 상태 전이, 멱등 처리, 구현 순서, 테스트 포인트 구체화
- document: 최종 문서 보완, 구조 정리, 누락 보완, 표현 정리, 중복 제거, 이력관리 형식 정리

## 완료 기준

- 완료 기준은 `workflow/50-finish.md`를 따른다.

## 금지

- 근거 없이 벤더, 상태값, 전환 순서, 운영 정책을 확정하지 않는다.
