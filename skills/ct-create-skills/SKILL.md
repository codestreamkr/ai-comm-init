---
name: ct-create-skills
description: 새 스킬 생성, 초안, 템플릿, 기존 스킬 패턴 복제나 개선을 요청할 때 사용한다. 사용자가 `$ct-create-skills`, `ct-create-skills`, CT 방식 적용을 명시하거나 스킬명·호출명·목적을 바탕으로 스킬을 만들려는 경우 CT wrapper에서 초안과 파일 반영 권한을 구분한 뒤 시스템 `skill-creator` 절차로 연결한다.
---

# CT Create Skills

스킬 작업의 진입 경로와 권한을 먼저 확정하고 실제 구조·검증 기준은 시스템 `skill-creator`를 따른다.

## 요청 라우팅

요청 표현에 따라 담당 절차를 확정한다.

| 요청 | 담당 절차 | 권한 판정 |
|---|---|---|
| `$ct-create-skills`, `ct-create-skills`, CT 방식 적용 요청 | 이 스킬의 CT wrapper 후 시스템 `skill-creator` | `작업 권한` 기준 |
| 일반적인 새 스킬 생성·초안·템플릿 요청 | 기존 호출 호환을 위해 CT wrapper 후 시스템 `skill-creator` | `작업 권한` 기준 |
| 기존 스킬 패턴 복제·개선 요청 | 이 스킬의 CT wrapper 후 시스템 `skill-creator` | `작업 권한` 기준 |

- 시스템 `skill-creator`가 직접 선택된 일반 요청도 이 wrapper의 `작업 권한` 기준을 먼저 적용한다.
- CT wrapper는 최소 입력 수집, CT 패턴 판단, 권한 확인만 담당한다.
- 실제 생성 구조, 파일 작성, `agents/openai.yaml`, 검증은 시스템 `skill-creator` 절차를 따른다.

## 작업 권한

초안과 파일 반영을 구분한다.

- 초안: `초안`, `설계`, `템플릿`, `준비`, `문의`, `검토`, `제안`, `설명` 요청은 대화에 구조와 내용을 제시한다.
- 반영: 명시적 파일 반영 동사와 적용 대상을 모두 확인한 뒤 허용된 경로에 파일을 생성하거나 수정한다.
  - 파일 반영 동사: `생성해줘`, `만들어줘`, `추가해줘`, `저장해줘`, `수정해줘`, `반영해줘`, `적용해줘`, `개선해줘`
  - 적용 대상: 파일·디렉터리 경로, 파일명, 스킬명·보조 리소스명처럼 식별 가능한 대상, 또는 직전 대화에서 확정한 초안·제안·변경안
  - 예: `새 audit 스킬을 생성해줘`, `skills/foo에 추가해줘`, `이 내용을 SKILL.md에 저장해줘`, `검토안을 파일에 반영해줘`, `제안대로 개선해줘`
- `문의`, `검토`, `제안`, `설명` 표현이 있으면 `생성`, `수정` 같은 명사나 서술만으로 반영 권한을 부여하지 않는다.
  - 예: `생성 규칙을 검토해줘`, `SKILL.md 수정안을 제안해줘`, `수정이 필요한지 알려줘`는 초안으로 처리한다.
- 초안 표현과 반영 표현이 함께 있으면 명시적 파일 반영 동사와 적용 대상이 모두 있을 때만 반영한다.
- 권한 표현이 없으면 초안으로 처리한다.
- 초안 검토 중 반영 요청을 받으면 확정된 내용만 파일에 적용한다.

## 첫 응답

CT wrapper 요청에서 스킬명, 호출명, 목적이 아직 주어지지 않았다면 파일을 만들지 않고 아래 형식만 안내한다.

```text
스킬을 바로 만들지 않고 먼저 초안 생성에 필요한 최소 정보만 받습니다.
아래 형식으로 답해 주세요.

1. 스킬명:
2. 호출명:
3. 목적:
```

세 항목이 모두 있으면 추가 안내 없이 다음 단계로 진행한다. 누락된 항목이 있으면 해당 항목만 한 번 묻는다.

## 입력 해석

- 스킬명: 디렉터리명, frontmatter `name`, 기본 `$스킬명` 호출에 사용
- 호출명: description에 포함할 추가 자연어 트리거
- 목적: 적용 범위, 제외 범위, 입력, 출력, 실행 흐름 판단에 사용

목적에서 아래를 추출한다.

- 스킬 성격: 분석, 설계, 구현, 검토, 문서, 위임
- 반복 실행 절차와 고정 검증 필요 여부
- 필요한 reusable resource와 CT 확장 구조
- 최종 산출물과 완료 조건

구조가 크게 달라지는 미결정 사항이 있을 때만 질문을 하나 한다.

## 구조 선택 기준

목적에 해당하는 구조만 선택한다.

| 목적 또는 반복 작업 | 허용 구조 | 역할 |
|---|---|---|
| 상세 판단 기준, 스키마, 정책 | `references/*.md` | 필요할 때 읽는 지식 정본 |
| 반복되는 결정적 실행 | `scripts/*` | 실행 가능한 자동화 |
| 출력에 복사·가공할 파일 | `assets/*` | 템플릿과 리소스 |
| 순서가 고정된 긴 절차 | `references/workflows/*.md` | 단계별 실행 흐름 정본 |
| 역할 위임과 병렬 작업 | `references/roles/*.md` | 역할별 작업 계약 |
| 벤더별 외부 연동 차이 | `references/vendors/{vendor}.md` | 벤더 계약과 예외 |
| 허용 목록으로 선택하는 동적 컴포넌트 | `components/<component-name>.md` | 컴포넌트별 실행 계약 |

`agents/`에는 UI 메타데이터인 `agents/openai.yaml`만 둔다. 실행 지식은 `references/`, 결정적 자동화는 `scripts/`, 출력에 사용하는 원본은 `assets/`에 둔다.

## 동적 컴포넌트 허용 목록

동적 컴포넌트는 아래 형식으로만 연결한다.

- 동적 경로 표기: `components/<component-name>.md`
- 허용 목록 제목: `## 컴포넌트 목록 출력`
- 허용 항목 형식: ``- `<component-name>`: 설명``
- 컴포넌트 이름: 소문자 영문, 숫자와 하이픈으로 작성한다.
- 허용 항목마다 `components/<component-name>.md`의 실제 이름에 해당하는 파일을 하나 둔다.
- `components/*.md` 파일마다 허용 목록 항목을 하나 둔다.

목적 문장의 신호를 아래처럼 해석한다.

| 신호 | 기본 판단 |
|---|---|
| 분석, 설계, 구조, 전환 | 분석·설계형 절차 |
| 순서, 단계, 체크리스트 | `references/workflows/` 후보 |
| 위임, 조수, 병렬, 통합 | `references/roles/` 후보 |
| 결제, 인증, webhook, 외부 API | `references/vendors/` 후보 |
| 리뷰, 감사, 점검 | 검토 결과와 완료 게이트 |
| 문서, 가이드, 정리 | 문서 산출물과 템플릿 |

## 작업 절차

1. 사용 가능한 스킬 목록에 등록된 source locator로 시스템 `skill-creator`의 `SKILL.md`를 처음부터 끝까지 읽는다.
2. `agents/openai.yaml`을 만들거나 수정할 때 같은 source locator의 `references` 디렉터리에 있는 `openai_yaml.md`를 읽는다.
3. 기존 스킬이면 현재 파일과 보조 리소스를 먼저 확인한다.
4. 기존 CT 스킬을 수정하면 `references/ct-skill-regression-checklist.md`로 변경 전 기능 계약을 고정한다.
5. 반영 권한이 있는 새 스킬이면 `skill-creator`의 초기화 절차를 사용한다.
6. `SKILL.md`에는 핵심 실행 절차만 남긴다.
7. 구조 선택 기준에서 확정한 표준 resource만 초안에 포함한다.
8. 반영 권한이 있으면 확정된 파일만 생성하거나 수정한다.
9. 모든 보조 파일을 `SKILL.md`에서 읽는 조건과 함께 직접 연결한다.
10. `agents/openai.yaml`의 표시 정보와 호출 정책을 본문에 맞춘다.
11. CT 스킬 반영 작업이면 먼저 `scripts/validate_ct_skills_test.rb`를 실행하고, 이어서 `scripts/validate_ct_skills.rb`, `scripts/validate_ct_skills.rb --against HEAD`, Git 반영 준비 후 `scripts/validate_ct_skills.rb --tracked`와 실제 사용 예시로 검증한다. 계약 변경을 실패로 처리해야 하는 자동화에서는 `scripts/validate_ct_skills.rb --against <ref> --fail-on-contract-change`를 사용한다.

## 검증 안전 기준

현재 저장소와 스킬에 이미 있는 검증 수단을 우선한다.

- 제공된 검증 스크립트, 프로젝트 빌드·테스트 명령, 언어 런타임의 기본 구문 검사를 순서대로 사용한다.
- 검증만을 위한 임시 스크립트 생성과 패키지 설치는 기본 수행 범위에 포함하지 않는다.
- 검증 도구의 의존성이 부족하면 설치 없이 사용할 수 있는 기본 도구로 구문, YAML, 경로, 참조 관계를 확인한다.
- 대체 검증으로 확인하지 못한 항목은 실행하지 못한 명령, 부족한 의존성, 확인한 대체 항목을 결과에 기록한다.
- fenced code의 예시 경로는 보조 리소스 참조에서 제외한다.
- 스킬이 생성할 `scripts/`, `assets/` 출력 경로는 bundled resource 참조와 구분한다.

## 기본 산출물 구성

- `SKILL.md`
- `agents/openai.yaml`
- 목적상 필요한 reusable resource만 추가

`display_name`은 별도 요구가 없으면 스킬명과 같게 쓴다. `default_prompt`에는 `$스킬명`을 포함한다.

## 초안 출력

초안은 아래 순서로 제시한다.

1. 입력 요약
2. 자동 판단 결과
3. 생성할 파일 구조
4. `SKILL.md`
5. `agents/openai.yaml`
6. 선택한 보조 파일
7. 확인 필요 항목

## 완료 조건

- 스킬명, 호출명, 목적이 description과 실행 절차에 반영됐다.
- frontmatter에는 `name`, `description`만 있다.
- 각 설명의 정본 위치가 `SKILL.md` 또는 하나의 reference로 확정됐다.
- 모든 reference가 `SKILL.md`에서 직접 연결된다.
- 모든 script와 asset이 `SKILL.md` 또는 `agents/openai.yaml`에서 직접 연결된다.
- 동적 컴포넌트 허용 목록과 `components/*.md`가 서로 일치한다.
- 이력 항목은 날짜별 한 줄로 병합되어 있다.
- 선택한 workflow, role, vendor reference의 읽기 조건이 `SKILL.md`에 있다.
- `agents/openai.yaml`이 현재 스킬 내용과 맞는다.
- 기존 검증 도구를 우선 사용하고 미실행 항목과 대체 검증 결과를 기록했다.
- 반영 작업이면 검증 결과를, 초안 작업이면 검증 미실행과 남은 확인 항목을 보고했다.

## 이력관리

- 2026-07-13: 기존 자연어 호출 호환과 시스템 skill-creator 역할 분리·source locator 기준 참조, 명시적 반영 동사와 적용 대상을 함께 확인하는 작업 권한, 표준 resource 구조, 동적 컴포넌트 표기와 허용 목록, Git ref 대비 전체 계약·UI 메타데이터 변경 검사, 참조·Git 추적·agents 구조 검증 순서를 정리했다.
