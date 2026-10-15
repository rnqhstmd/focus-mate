## 코드 맵: W09 하차 태그·요약·기록·분석 + 마이페이지 큰 글자 버그

### 핵심 파일
- ios/FocusMate/RecordSection.swift → RecordSnapshot·RecordCompletionInput·RecordSection(recordingCompletion, updatingMemo, dailySummary, lifetimeSummary, sortedNewestFirst) — W08 완료·메모 저장 모델
- ios/FocusMate/AppModel.swift:233 → recordCompletion(_:outcome:) / saveRecordMemo(_:forJourneyID:) 저장 API, Route .records
- ios/FocusMate/AppModel+JourneyLifecycle.swift → resume/abandon/confirmNewJourney, endingActiveJourney 재사용 지점
- ios/FocusMate/JourneyView.swift / JourneyTimerView.swift → 타이머·도착(journey.arrived) 화면, 하차 진입 연결 지점
- ios/FocusMate/BoardingTagController.swift / BoardingTagView.swift → 승차 태그 제스처·LCD — 하차 재사용 후보

### 참조 파일
- ios/FocusMate/AppSnapshot.swift → endingActiveJourney(at:), updating(records:)
- ios/FocusMate/JourneyReach.swift → reachedStation(도착이면 저장 도착지)
- ios/FocusMate/ActiveJourneyCardContent.swift → Kind.arrived (하차 진입으로 전환 예정)
- ios/FocusMate/JourneyLiveActivitySync.swift / JourneyLiveActivityCleanup.swift → W15 Live Activity, 하차 시 종료 확인
- ios/FocusMate/AppModel+Profile.swift → 마이페이지 통계(기록 저장 시 자동 증가)
- ios/FocusMate/RootView.swift → 라우팅·records 목적지(현재 빈 화면)
- ios/FocusMateUITests/ProfileUITests.swift:276,301 → testAC20 최대 글자 크기 실패 2건(기존 결함)

### 설정
- scripts/check-ios.py → build/test focused 실행 (FOCUSMATE_SIMULATOR_ID)
- context/journey/status.md, context/records/status.md → FR-12/AC-14, FR-6/AC-7 원장
- docs/FLOWS.md → 화면 계약(하차 LCD는 카드 이름)
