# 여정 아키텍처

> 구성 확정 / 담당·규모 미확인. 현재 구조와 향후 개발을 구분합니다.

## 현재 시스템 구조

제품 상태·DOM·스타일은 [animation-preview.html](../../designs/final/animation-preview.html)에 함께 있다. 화면 모아보기는 `flow-viewer.js`와 빌드/캡처 스크립트로 구성한다. 별도 API 서버·도메인 서비스 레이어는 없다. Swift는 Phase 1 앱 기반(`ios/FocusMate`: 진입 분기·기본 화면 왕복)과 `app-state.json` 버전 2 저장(W00) 위에 이 도메인의 첫 네이티브 기능(W02)이 있다: 순수 규칙 `RouteData`(9개 순환 정류장·카탈로그 3건·버스 3종)·`JourneyPlanner`(후보·도착지·거리), 화면 상태 값 `StationSearchState`·`JourneyPlanDraft`, 저장·이동 `AppModel+JourneyStart`(최신 스냅샷 → `updatingStage` → `AppModel.save`), 화면 `InitialStationSearchView`·`TimeSelectionView`·`DestinationScreen`. 여정 선택(`JourneySelection`)은 실행 중 메모리에만 둔다. 이 context 폴더의 4개 도메인은 물리 코드 분리안이 아니다.

주요 현재 함수/경계: selectTime/currentTimeJourney, saveTag/renderPreparationTags, chooseSound/applySound 및 재생 수명, syncPreparation, completeFareTag, beginActiveJourney/checkpointJourney, show/tick, updateCamera.

저장·자산: `next-step-prototype-active-journey-v1`과 위치 저장 키. 저장 실패/손상은 현재 계약대로 안내한다.

연계: card가 소유하는 카드 ID/외형을 참조한다. journey는 태그·할 일·선택 소리와 재생 수명을 소유하고 preferences의 환경 선호/복구 안내를 적용한다. records에는 하차 접촉 성공만 완료를 전달한다.

## 향후 네이티브와 후순위

iOS 실제 분 타이머는 W05에서 구현됐다: `JourneyTimerController`(단조 시계 `JourneyClock`·틱 `JourneyTicker` 주입, 상태 running/paused/arrived)가 진도를 소유하고 `AppModel.saveJourneyProgress`로 저장한다(저장 형식 v4). MapKit 가상 코스는 W06에서 구현됐다: 순수 규칙 `JourneyCourse`(정류장 id별 실제 위치 근사 좌표, 서울 경계 상자, 정류장 사이 직선 닫힌 코스)·`JourneyCourseProgress`(`CourseJourney` 입력으로 진도 → 버스 위치·방향·다음/남은 정류장·남은 거리, 정수 초 산술)·`JourneyMapState`(따라가기/자유 탐색·테마·정류장 표시·시트·도구 활성 상태 머신과 `JourneyCameraPolicy`), 연결부 `JourneyMapController`(저장자·타이머 의존 없음 — 지도는 진도·저장을 바꾸지 않는다), 화면 `JourneyMapView`(SwiftUI `Map`, 실제 POI 숨김, 사용자 제스처는 카메라 바인딩 setter의 `positionedByUser`로 판정)·`JourneyMapThemeSheet`. 지도 상태는 저장하지 않고 여행 화면 수명 동안만 둔다. **도착지 일관성 규칙**: 저장된 `destinationStopID`가 출발 정류장·방향·분·버스로 계산한 도착지와 다르면 `CourseJourney.init?(journey:)`가 nil이고 여행 화면은 지도 없이 W05 배치로 보인다. W09 도착 안내도 같은 규칙을 따른다. 앱 생명주기(포기·이어가기)는 W07에서 구현됐다: `JourneyReach`가 도달 정류장 규칙(경과÷간격의 몫, 방향 유지)과 `AppSnapshot.endingActiveJourney`(현재 정류장 변경과 진행 여정 삭제를 한 스냅샷으로)를 맡아 포기·새 여정이 한 번의 저장이 된다. `AppModel+JourneyLifecycle`의 이어가기·새 여정 확정·포기는 `LifecycleActionResult`(done/rejected/saveFailed)를 반환하고, 포기는 `abandonJourney(timerPaused:)` 계약으로 컨트롤러의 일시정지 상태를 받아 모델이 BR-6을 강제한다(`JourneyAbandonController`/`JourneyAbandonBar`가 확인 창 상태를 가짐). 컨트롤러 autoStart는 '시작'을 직접 본 경우에 더해 이번 실행에서 이어가기 저장에 성공한 같은 여정(1회용 메모리 신호)도 포함한다. 이 저장들은 실패를 호출자가 직접 안내하는 `saveHandlingFailure`를 써서 일반 `saveFailure`를 남기지 않는다. 저장 형식은 v4 그대로다. 실제 GPS·버스 API·실시간 위치·기기 간 재개는 후순위. 상세 범위는 [MVP](../../docs/MVP.md)에 있다. 새로운 계층·파일·API를 이미 구현된 것으로 표시하지 않는다.

## 주제 문서

| 주제 | 설명 |
|---|---|
| [현재 상태](../../docs/CURRENT-STATE.md) | 최신 기능과 검증 시점 |
| [화면 계약](../../docs/FLOWS.md) | 성공·취소·오류·저장 |
| [현재 VM 검사](../../scripts/prototype-edge-qa.cjs) | mock DOM·수치·상태 검증, 실제 iPhone 검증과 구분 |


## 개발 단계 연결

[개발 단계](../../docs/DEVELOPMENT-PHASES.md)에 단계 구분과 범위를 연결합니다. 웹 구현은 위의 단일 HTML이고, iOS는 Phase 1 앱 기반·저장 버전 2와 W02(첫 출발지·시간 선택)까지 있습니다. 도메인의 구현 근거와 미반영 항목은 [status.md](status.md)에 기록합니다.
