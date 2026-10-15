## 코드 맵: W04 승차권·승차 태그 (journey FR-11)

### 핵심 파일
- ios/FocusMate/AppModel.swift:5-16 → `Destination` enum(board/boarding/journey 없음), `path`, `save`/`persist`(실패 시 snapshot 불변·saveFailure), `currentPreparationDetails`·`confirmPreparation`·`consumePreparationRequest`(미호출), `currentCardStyle`(:281)
- ios/FocusMate/DestinationScreen.swift → 목적지별 화면 분기, 나머지는 제목 자리표시(`screen.<rawValue>`)
- ios/FocusMate/JourneySection.swift → `JourneySection { active: JourneySnapshot? }`, `JourneySnapshot` 빈 enum(진행 여정 형식 미정, non-null decode는 손상)
- ios/FocusMate/PreparationView.swift:175-186 → '승차권 보기'(`preparation.confirm`), 현재 화면 이동 없음
- ios/FocusMate/UITestBootstrap.swift → `--fm-ui-*` 인자, rawSeeds, `state(...)` 헬퍼(journey active null 고정), UITestFeedbackRecorder

### 참조 파일
- ios/FocusMate/AppSnapshot.swift → `updating(journey:)`, `validate`
- ios/FocusMate/SnapshotCodec.swift:38 → currentVersion 3, v1·v2 마이그레이션
- ios/FocusMate/PreparationDraft.swift:100,134 → `isComplete`, `PreparedJourneyDetails`
- ios/FocusMate/AppModel+JourneyStart.swift → `preparedJourney`, `proceedToPreparation`
- ios/FocusMate/CardIssuanceController.swift → sleep 주입, `holdDuration(reduceMotion:)`, 햅틱/낭독 주입
- ios/FocusMate/IssuanceFeedback.swift, IssuanceHapticPattern.swift → 햅틱·낭독 프로토콜, 패턴 값
- ios/FocusMate/PassFace.swift, PassIdentity.swift → `PassFace(style:)`, 카드 이름(번호 비표시)

### 설정
- scripts/check-ios.py → `build|test [파일경로...]`, FOCUSMATE_SIMULATOR_ID/FOCUSMATE_DERIVED_DATA
- docs/FLOWS.md:14-15,28-37,58-64 → 승차권·승차 태그·출발 안내 계약(출발 안내는 :36 2차 채택, 최신 렌더 DO8HO)
- designs/revised/pen-updates/{ticket-prepare-briefing,card-briefing}-2026-10-13/ → TUNX2·kxUUR·JmXmQ·Vts6F·DO8HO 시안
