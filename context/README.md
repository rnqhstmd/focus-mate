# 프로젝트 컨텍스트

> 수정일: 2026-10-12. 도메인 4개는 사용자 확인으로 확정했습니다. 현재 구현·개발 단계 구분을 보강했으며 담당자와 사용자 규모는 ❓로 보존합니다.

Focus Mate의 도메인 지식·구현 경계·용어를 정리합니다. 현재는 단일 HTML/JavaScript 웹 프로토타입이며 아래 4개는 코드 모듈이나 서비스 분리가 아닌 제품 관점의 권장 경계입니다. 기존 문서의 내용을 재정의하지 않고 연결합니다.

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

공통 담당 PM/PO ❓, 개발 리드 ❓, 예상 사용자 수·사용 빈도·출시 목표 ❓입니다. git 사용자 이름을 제품 담당자로 사용하지 않았습니다. 각 status.md는 FR/NFR·AC·구현 근거를 갖는 요구사항 원장입니다. 웹 반영 15개 행과 iOS 미반영 9개 행을 구분하며, 제품의 전체 완성률이나 실기기 검증 통과율을 나타내지 않습니다.

## 근거와 공통 자료

- [공통 용어](glossary.md)
- [현재 상태](../docs/CURRENT-STATE.md) · [MVP 범위](../docs/MVP.md) · [화면·저장 계약](../docs/FLOWS.md)
- [실행·작업 안내](../README.md) · [현재 HTML](../designs/final/animation-preview.html)
- 현재 레포: [rnqhstmd/next-step](https://github.com/rnqhstmd/next-step), `git remote get-url origin` 직접 확인

브라우저 검증과 이후 VM/Pen 검증은 [현재 상태](../docs/CURRENT-STATE.md)의 시점을 구분합니다. 네이티브 SwiftUI·MapKit·실제 분 타이머·클라우드는 현재 구현으로 간주하지 않습니다. 도메인 구성은 확인됐으며 담당 정보는 아직 확정하지 않았습니다.


## 개발 진행

- [개발 단계와 완료 기준](../docs/DEVELOPMENT-PHASES.md)
- 요구사항 원장: [여정](journey/status.md) · [카드](card/status.md) · [기록](records/status.md) · [환경설정](preferences/status.md)

현재 Swift 소스·Xcode 프로젝트가 없어 네이티브 단계는 미착수입니다. 웹 VM 통과와 Pen 렌더 확인을 실제 iPhone 검증으로 치환하지 않습니다. 일정·담당·최소 iOS 버전·배포 환경이 결정되기 전에는 완료 날짜를 예측해 기록하지 않습니다.
