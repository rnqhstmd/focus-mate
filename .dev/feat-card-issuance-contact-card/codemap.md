## 코드 맵: W01 [P2] 카드 발급·접촉 카드 (card FR-3)

### 핵심 파일
- ios/FocusMate/CardSection.swift:1 → 카드 저장 섹션. W00이 원소(CardSnapshot) 계약을 비워둠 — W01이 정의할 자리
- ios/FocusMate/AppSnapshot.swift:14 → 앱 상태 스냅샷(cardIssued·stations·cards·journey·records), launchRoute(.cardEntry 분기), validate
- ios/FocusMate/AppModel.swift:18 → 상태 로드/저장(save), 화면 이동(open/goBack)
- ios/FocusMate/RootView.swift:54 → .cardEntry 화면(현재 "집중동행카드" 텍스트 자리표시)
- ios/FocusMate/SnapshotCodec.swift → app-state.json 버전 2 인코딩/디코딩·마이그레이션

### 참조 파일
- ios/FocusMate/LocalSnapshotStore.swift → 로컬 파일 저장소
- ios/FocusMate/UITestBootstrap.swift → UI 테스트용 초기 상태 주입
- ios/FocusMateTests/StorageV2Tests.swift → 버전 2 저장 테스트(스타일 참고)
- ios/FocusMateTests/AppSnapshotSectionsTests.swift → 섹션 테스트
- ios/FocusMateTests/AppFoundationTests.swift → 진입 분기·저장 실패 테스트
- ios/FocusMateUITests/Phase1FlowTests.swift → UI 흐름 테스트
- docs/FLOWS.md:7 → 카드 발급 화면 계약(issue), 카드 표시 규칙(:38)

### 설정
- .claude/config.json → ios-swiftui 테스트: python3 scripts/check-ios.py test
- scripts/check-ios.py → iOS 빌드·테스트 실행기
- context/card/ → 도메인 컨텍스트(glossary·architecture·status)

### 탐색 추가 (requirements)
- designs/final/animation-preview.html:1009-1016 → 웹 카드 ID 규칙·생성·불러오기·표기·문구·햅틱·발급 흐름
- ios/FocusMate/AppSnapshot.swift:52/63 → validate(BR-5 추가 대상)·launchRoute(발급 완료 화면 유지 영향)
- ios/FocusMate/AppModel.swift:43 → save 성공/실패와 저장 직후 화면 전환
- ios/FocusMate/SnapshotCodec.swift:42 → v1→v2 변환
- ios/FocusMate/UITestBootstrap.swift:32 → UI 테스트 시드(카드 화면용 저장 실패 시드 확장 필요)
- ios/FocusMateTests/StorageV2Tests.swift:25 → 읽기는 쓰지 않는다는 보장
- ios/FocusMateUITests/Phase1FlowTests.swift:13 → 첫 실행·cardOnly 시드 테스트
