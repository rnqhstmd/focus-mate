# 여정 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 별도 API 서버·도메인 서비스 레이어는 없다. Swift는 Phase 1 앱 기반(`ios/FocusMate`: 진입 분기·기본 화면 왕복)과 `app-state.json` 버전 2 저장(W00) 위에 이 도메인의 첫 네이티브 기능(W02)이 있다: 순수 규칙 `RouteData`(9개 순환 정류장·카탈로그 3건·버스 3종)·`JourneyPlanner`(후보·도착지·거리), 화면 상태 값 `StationSearchState`·`JourneyPlanDraft`, 저장·이동 `AppModel+JourneyStart`(최신 스냅샷 → `updatingStage` → `AppModel.save`), 화면 `InitialStationSearchView`·`TimeSelectionView`·`DestinationScreen`. 여정 선택(`JourneySelection`)은 실행 중 메모리에만 둔다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

주요 현재 함수/경계: selectTime/currentTimeJourney, saveTag/renderPreparationTags, chooseSound/applySound 및 재생 수명, syncPreparation, completeFareTag, beginActiveJourney/checkpointJourney, show/tick, updateCamera.

저장·자산: `next-step-prototype-active-journey-v1`과 위치 저장 키. 저장 실패/손상은 현재 계약대로 안내한다.

연계: card가 소유하는 카드 ID/외형을 참조한다. journey는 태그·할 일·선택 소리와 재생 수명을 소유하고 preferences의 환경 선호/복구 안내를 적용한다. records에는 하차 접촉 성공만 완료를 전달한다.

## 향후 네이티브와 후순위

iOS 실제 분 타이머는 W05에서 구현됐다: `JourneyTimerController`(단조 시계 `JourneyClock`·틱 `JourneyTicker` 주입, 상태 running/paused/arrived)가 진도를 소유하고 `AppModel.saveJourneyProgress`로 저장한다(저장 형식 v4). 앱 생명주기(포기·이어가기)와 MapKit 기본 지도/앱 내 가상 코스는 iOS MVP 예정(W07·W06). 실제 GPS·버스 API·실시간 위치·기기 간 재개는 후순위. 상세 범위는 [MVP](../../docs/MVP.md)에 있다. 새로운 계층·파일·API를 이미 구현된 것으로 표시하지 않는다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 웹 구현은 위의 단일 HTML이고, iOS는 Phase 1 앱 기반·저장 버전 2와 W02(첫 출발지·시간 선택)까지 있습니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
