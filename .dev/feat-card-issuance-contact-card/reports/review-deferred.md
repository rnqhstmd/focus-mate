# Deferred (review — 최신 리뷰 정본)

## quality Minor (1회차 23건 중 해소 3건 제외 + 2회차 신규 2건)
- [Minor] CardSection.swift:25 — ISO 8601 소수초·오프셋 처리 불확실 (A11 → W13)
- [Minor] CardStorageTests.swift:118 — 11바이트 내 비ASCII 혼합 케이스 없음
- [Minor] CardStorageTests.swift:48-110 — a~f 입력 중복
- [Minor] CardStorageTests.swift:113,123 — 메서드명 testACn_ 컨벤션 아님
- [Minor] PassIdentity.swift:10-14 — 접두·길이 미검사 (validate가 막음)
- [Minor] PassFace.swift — 테두리 lineWidth 배율 미적용
- [Minor] PassFace — #Preview 없음, 폭 238/320 시각 확인 필요
- [Minor] PassFaceAssetTests/PassIdentityTests — 상수 change detector 단언
- [Minor] IssuanceFeedback.swift — stopped/reset 핸들러 엔진 동일성 미비교 (R2에서 auto shutdown으로 빈도 증가 — 확신 낮음)
- [Minor] IssuanceFeedback.swift — 핸들러 클로저 격리(Swift 6 전환 시 재검토)
- [Minor] IssuanceFeedback.swift:24 — engine.start() 동기 호출
- [Minor] IssuanceFeedback.swift:34 — 주석 "다시 켜진다"가 실제(새 엔진 생성)와 다름
- [Minor] CardIssuanceController.swift — private let의 @ObservationIgnored 중복
- [Minor] CardIssuanceController.swift:55-66 — 안내 두 건 연달아 발화, VoiceOver가 앞을 끊을 수 있음 (AC-19M 수동 확인 시 함께)
- [Minor] CardIssuanceView.swift:51,77 — focusTarget과 버튼 등장 같은 트랜잭션, 포커스 무시 가능 (AC-19M)
- [Minor] CardIssuanceView.swift:22 — cardOut phase 리셋 없음 (도달 불가)
- [Minor] CardIssuanceView — 동작 줄이기 첫 프레임 offset/마스크
- [Minor] CardIssuanceView.swift:54-70 — 카드 등장 시 무대 높이 점프
- [Minor] CardIssuanceView.swift:32,41 — accessibilityValue 중복 낭독 가능 (AC-19M)
- [Minor] CardIssuanceTestDoubles.swift:67-74 — SuspendingSleep 이중 sleep 시 hang
- [Minor] UITestBootstrap.swift:111-125 — 게이트 이중 wait 덮어쓰기, @Observable 불필요 (DEBUG)
- [Minor] CardStorageFlowTests.swift:19-30 — AC-10 cardEntry 순간 노출 미검출 (구조상 보장)
- [Minor] FocusMateApp.swift:30-32 — 컨트롤러 생성 중복 표현
- [Minor] 테스트 더블이 CardTestSupport·CardIssuanceTestDoubles 두 파일로 분리 (설계서 표 갱신 대상)

## security MEDIUM (유예/이관)
- [MEDIUM] BR-4 후속 화면 검증 → W04·W11 이관
- [MEDIUM] HarnessUITests 운영 저장소 사용 → 후속 테스트 하네스 정리
- [MEDIUM] issuedAt 관용성·범위 → A11, W13 이관
