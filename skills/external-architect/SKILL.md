---
name: external-architect
description: 외부 시스템 연동 구조를 절차형으로 분석하고 설계 문서를 완성하는 위임형 스킬. 사용자가 "호페형", "external-architect"를 직접 부르거나 결제, 인증, 메시징, 정산, 웹훅, 콜백, 벤더 API 연동처럼 외부 시스템 경계와 전환 설계가 핵심인 작업을 맡길 때 사용한다. 체크리스트, 구조 리포트, 설계 제안, developer/document 위임, 최종 문서 통합을 고정된 순서로 수행한다.
---

# external-architect

이 스킬은 위임형 전용 절차다.

## 실행 순서

1. [workflow/00-entry.md](workflow/00-entry.md)
2. [workflow/10-checklist.md](workflow/10-checklist.md)
3. 해당 벤더의 `ENTRY.md`
4. [workflow/20-report.md](workflow/20-report.md)
5. [workflow/30-proposal.md](workflow/30-proposal.md)
6. [workflow/40-delegate.md](workflow/40-delegate.md)
7. [workflow/50-finish.md](workflow/50-finish.md)

## 벤더 진입점

- 토스페이먼츠: [vendors/toss/ENTRY.md](vendors/toss/ENTRY.md)
- NHN KCP: [vendors/kcp/ENTRY.md](vendors/kcp/ENTRY.md)
- 카카오페이: [vendors/kakaopay/ENTRY.md](vendors/kakaopay/ENTRY.md)
- 네이버페이: [vendors/naverpay/ENTRY.md](vendors/naverpay/ENTRY.md)

## 반드시 할 일

- 첫 응답은 `workflow/10-checklist.md` 기준 체크리스트만 작성한다.
- 체크리스트 후 벤더를 정하고 해당 벤더의 `ENTRY.md`를 연다.
- 현재 구조 리포트를 작성한다.
- 적용 제안을 작성한다.
- 제안 후 `workflow/40-delegate.md` 기준으로 `developer`, `document`를 각각 위임한다.
- 두 위임 결과를 검수한 뒤 최종 문서 1개로 통합한다.

## 필수 산출물

- 체크리스트
- 현재 구조 리포트
- 적용 제안
- developer 산출물
- document 산출물
- 최종 문서 파일 1개

## 벤더가 불분명할 때

- 먼저 현재 구조를 보고 주 벤더를 판별한다.
- 둘 이상이 섞여 있으면 이번 요청의 주 대상 벤더를 하나 정해 진입하고, 나머지는 리포트의 비교 대상이나 공존 대상으로만 다룬다.
- 어떤 벤더도 특정되지 않으면 `workflow/20-report.md`의 공통 확인 항목으로 시작한다.

## 문서 작성 원칙

- 구조와 책임 경계를 먼저 쓴다.
- 벤더 원본 상태와 내부 도메인 상태를 분리해서 설명한다.
- 공식 문서로 확정되지 않는 내용은 `확인 필요`로 남긴다.
- 구현 코드 작성보다 분석, 설계, 문서 완성을 우선한다.

## 역할

- 메인 어시스턴트: 체크리스트, 리포트, 제안, 위임 실행, 결과 검수, 최종 문서 통합
- developer: 개발 가이드 작성, 저장 모델, API 계약, 상태 전이, 멱등 처리, 구현 순서, 테스트 포인트 구체화
- document: 최종 문서 보완, 구조 정리, 누락 보완, 표현 정리, 중복 제거, 이력관리 형식 정리

## 완료 기준

- developer 산출물이 있다.
- document 산출물이 있다.
- 최종 문서 파일 1개가 실제로 생성돼 있다.
- 최종 문서에 `확인 필요`가 있다.
- 최종 문서 끝에 `## 이력관리`가 있다.

## 금지

- 메인 어시스턴트가 `developer`, `document` 역할을 대신 수행하지 않는다.
- `developer` 또는 `document` 중 하나만 위임하고 끝내지 않는다.
- 위임 없이 최종 문서를 닫지 않는다.
