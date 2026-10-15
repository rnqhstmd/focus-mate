## 코드 맵: W05 실제 분 타이머·일시정지 (journey FR-5 / AC-6)

### 핵심 파일
- ios/FocusMate/JourneySnapshot.swift → 진행 여정 모델(Phase awaitingDeparture/…, Progress.elapsedSeconds), 구조 검증, ISO8601 Codable, ActiveJourneyFactory
- ios/FocusMate/JourneyView.swift → 여행 화면. 출발 안내(DepartureBriefing) 뒤 `journey.placeholder` 자리 → W05가 실제 타이머로 교체
- ios/FocusMate/DepartureBriefingController.swift → 출발 안내 문장·'시작'(confirmDeparture) 컨트롤러, `DepartureConfirming`
- ios/FocusMate/AppModel+Boarding.swift → activeJourney·boardJourney·confirmDeparture·startTripFromMain(진행 여정 폐기)
- ios/FocusMate/AppModel.swift → Destination·path·confirmedPreparation·저장(persist) 경로·open 가드

### 참조 파일
- ios/FocusMate/JourneySection.swift → 저장 섹션 journey.active(0~1개) 디코드(try?)
- ios/FocusMate/SnapshotCodec.swift → app-state.json 버전 3 코덱, LegacyJourneySectionV2, dropInvalidActiveJourney
- ios/FocusMate/AppSnapshot.swift → 스냅샷 검증 이슈(invalidActiveJourney)
- ios/FocusMate/JourneyServices.swift → 화면 서비스 묶음(.live(), sleep, reduceMotion, haptics, announcer)
- ios/FocusMate/BoardingTagController.swift → 토큰·pendingSave 패턴과 scenePhase 처리 선례
- ios/FocusMate/UITestBootstrap.swift → UI 테스트 시드·인자(--fm-ui-*)·activeJourney 시드
- ios/FocusMate/RootView.swift → 메인·진단(test.*)·main.activeJourney 안내

### 설정
- scripts/check-ios.py → iOS 빌드·테스트 진입점 (test {files})
- ios/FocusMate.xcodeproj/project.pbxproj → 대상·테스트 파일 등록
- docs/FLOWS.md → 여행 focus 계약(일시정지·체크포인트·백그라운드 정지, 앱 밖 시간 미포함)
