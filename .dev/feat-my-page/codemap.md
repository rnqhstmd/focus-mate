## 코드 맵: W11 마이페이지 (card FR-5)

### 핵심 파일
- ios/FocusMate/DestinationScreen.swift → 메인 위 목적지 화면. .profile은 현재 제목만 있는 자리표시
- ios/FocusMate/RecordSection.swift:38 → 완료 기록 섹션. dailySummary(on:)(:86)만 있고 누적 집계 없음
- ios/FocusMate/AppModel.swift → 저장·경로(path)·open(destination). Destination.profile 제목 "마이페이지"
- ios/FocusMate/PassFace.swift:5 → 공통 카드 뷰(발급·승하차·마이페이지 공유)
- ios/FocusMate/PassIdentity.swift:16 → 카드 이름 단일 출처 current(in:)

### 참조 파일
- ios/FocusMate/AppSnapshot.swift:54 → currentCard, records 섹션 접근
- ios/FocusMate/AppModel+JourneyStart.swift:43 → Destination.mainMenu / mainMenuTarget
- ios/FocusMate/RootView.swift → 메인 메뉴, DEBUG 진단(test.snapshot 등)
- ios/FocusMate/UITestBootstrap.swift → UI 테스트 시드(--fm-ui-seed)
- ios/FocusMateTests/RecordSectionTests.swift → 기록 섹션 단위 테스트 스타일
- ios/FocusMateUITests/Phase1FlowTests.swift → 메인 메뉴 왕복 UI 테스트
- designs/prototype/index.html → 웹 마이페이지(#profile, renderProfile, formatTime)

### 설정
- .claude/config.json → ios-swiftui test/focusedTest(python3 scripts/check-ios.py)
- scripts/check-ios.py → iOS 빌드·테스트 실행기
