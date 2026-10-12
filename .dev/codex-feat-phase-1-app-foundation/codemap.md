# 코드 맵: Phase 1 앱 기반

2026-10-13. 아래 native 소스는 Phase 1 구현이며, 기존 웹 시안 전체의 이식을 의미하지 않는다.

## 네이티브 기반
- ios/FocusMate/FocusMateApp.swift → 단일 AppModel 생성, 첫 로드, DEBUG 시험 경로 분리
- ios/FocusMate/AppSnapshot.swift → 카드 발급·최초/현재 정류장 값, 유효 단계, 최초 진입 분기
- ios/FocusMate/LocalSnapshotStore.swift → 버전 JSON 읽기·원자 저장, 오류 분류와 원본 보호
- ios/FocusMate/AppModel.swift → load once, 성공 시 상태 확정, 기본 화면 경로와 실패 안내
- ios/FocusMate/RootView.swift → 진입 3종, 메인과 기본 목적지, 오류 표시
- ios/FocusMate/UITestBootstrap.swift → DEBUG UUID 경로·seed·실패 주입, Release 제외
- ios/FocusMateTests/AppFoundationTests.swift → 값·파일·모델 경계 단위 회귀 14건
- ios/FocusMateUITests/Phase1FlowTests.swift → 실제 실행·재실행 UI 회귀 10건
- ios/FocusMate.xcodeproj → iOS17 최소, 공유 스킴, 앱·Unit·UI target
- scripts/check-ios.py → 설치 Simulator 선택, focused/전체 build와 test

## 기존 제품·웹 참조
- designs/final/animation-preview.html → 승인 웹 시안과 프로토타입
- scripts/prototype-edge-qa.cjs → 웹 VM 회귀
- docs/DEVELOPMENT-PHASES.md, docs/FLOWS.md, docs/CURRENT-STATE.md, docs/MVP.md → 제품 범위·연결·제한
- docs/PHASE-1-FOUNDATION.md → 이번 기반 검증과 후속 구현 경계
- context/README.md, context/glossary.md → 4개 도메인·공통 용어

## 검사 설정
- .claude/config.json → standard, node와 ios-swiftui 검사 명령
- package.json → 웹 build/test; Python3 실행
- .gitignore → native/web 빌드·사용자 캐시 제외
