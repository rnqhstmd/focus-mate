# 프로젝트 컨텍스트

> 수정일: 2026-10-16. 도메인 4개는 사용자 확인으로 확정했습니다. 현재 구현과 시스템 표면 후속 계획을 구분하며 담당자와 사용자 규모는 ❓로 보존합니다.

Focus Mate의 도메인 지식·구현 경계·용어를 정리합니다. 웹 프로토타입과 SwiftUI 네이티브 구현이 있으며 여정·기록 등 실제 기능이 단계별로 들어갔습니다. 아래 4개는 코드 모듈이나 서비스 분리가 아닌 제품 관점의 권장 경계입니다. 기존 문서의 내용을 재정의하지 않고 연결합니다.

## 도메인

사용자가 4개 도메인 구성을 확인했습니다.

| 도메인 | 설명 | 상세 |
|---|---|---|
| journey | 여정·준비·승하차·지도·복원 | [여정](journey/README.md) |
| card | 발급·카드 정체성·꾸미기 | [카드](card/README.md) |
| records | 완료 기록·메모·분석 | [기록](records/README.md) |
| preferences | 동작 줄이기·환경·복구 | [환경설정](preferences/README.md) |

## 도메인 문서

- [journey](journey/README.md): 여정 선택·준비·승하차·지도/타이머·중단 복원
- [card](card/README.md): 집중동행카드 발급·정체성·꾸미기
- [records](records/README.md): 완료 기록·선택 메모·잔디·분석
- [preferences](preferences/README.md): 동작 줄이기·환경 제한·복구 설정

공통 담당 PM/PO ❓, 개발 리드 ❓, 예상 사용자 수·사용 빈도·출시 목표 ❓입니다. git 사용자 이름을 제품 담당자로 사용하지 않았습니다. 각 status.md는 FR/NFR·AC·구현 근거를 갖는 요구사항 원장이며 웹·iOS 범위를 구분합니다. 원장의 상태는 제품의 전체 완성률이나 실기기 검증 통과율을 나타내지 않습니다.

## 근거와 공통 자료

- [공통 용어](glossary.md)
- [현재 상태](../docs/CURRENT-STATE.md) · [MVP 범위](../docs/MVP.md) · [화면·저장 계약](../docs/FLOWS.md)
- [실행·작업 안내](../README.md) · [현재 HTML](../designs/final/animation-preview.html)
- 현재 레포: [rnqhstmd/next-step](https://github.com/rnqhstmd/next-step), `git remote get-url origin` 직접 확인

브라우저 검증과 이후 VM/Pen 검증은 [현재 상태](../docs/CURRENT-STATE.md)의 시점을 구분합니다. 네이티브에는 실제 분 타이머·MapKit 코스·Live Activity·하차·기록이 구현됐습니다. 홈 위젯과 네이티브 분석은 아직 대기이며 클라우드는 범위 밖입니다. 도메인 구성은 확인됐으며 담당 정보는 아직 확정하지 않았습니다.


## 개발 진행

- [개발 단계와 완료 기준](../docs/DEVELOPMENT-PHASES.md)
- 요구사항 원장: [여정](journey/status.md) · [카드](card/status.md) · [기록](records/status.md) · [환경설정](preferences/status.md)
- 작업 계획: [.dev/plan.md](../.dev/plan.md) — Phase 2~6을 W 작업과 의존 관계로 나눈 실행 순서

기반 검증은 [Phase 1 검증](../docs/PHASE-1-FOUNDATION.md), 이후 기능별 상태는 각 요구사항 원장과 작업 계획을 참고합니다. 후속 시스템 표면은 **W17 Live Activity 디자인**, **W18 집중 유도·분석 홈 위젯**으로 묶었고 기존 **W09b에 앱·위젯 공용 집계**를 보강했습니다. [승인된 상세 계획](../.dev/system-surfaces-plan/plan.md)에 내부 단계·의존·검증 경계를 기록했습니다. 기존 완료/진행 작업의 상태는 이번 계획 갱신에서 동기화하지 않았습니다.

웹 VM 통과와 Pen 렌더 확인을 실제 iPhone 검증으로 치환하지 않습니다. 최소 iOS 17은 작업 기준이며 출시 버전은 미정입니다. App Group 식별자·서명 담당자는 ❓이며 설정 단계에서 확인합니다. 일정·담당·배포 환경이 결정되기 전에는 완료 날짜를 예측해 기록하지 않습니다.
