# 코드 맵: W13 저장 오류 복구

## 핵심 파일
- ios/FocusMate/LocalSnapshotStore.swift → 로드·원본 보존 쓰기 차단
- ios/FocusMate/AppModel.swift → 시작 상태·저장 실패
- ios/FocusMate/RootView.swift → 저장 오류 화면
- ios/FocusMate/SnapshotCodec.swift → 버전·손상·내용 검증
- ios/FocusMate/UITestBootstrap.swift → DEBUG 전용 오류 시드

## 참조 파일
- context/preferences/status.md → FR-4 / AC-6
- docs/PHASE-1-FOUNDATION.md → 복구·운영 저장 안전 경계
- .dev/feat-domain-storage-schema-v2/design.md → W00 복구 인계
- ios/FocusMateTests/StorageV2Tests.swift → 저장 v2 회귀
- ios/FocusMateTests/AppFoundationTests.swift → 시작·저장 상태 회귀
- ios/FocusMateUITests/Phase1FlowTests.swift → 화면·파일 보존 검증
- .dev/plan.md → W13 의존·파일 구조 불변

- ios/FocusMate/FocusMateApp.swift:48 → 시작·DEBUG prepare 통합 경계
- ios/FocusMate.xcodeproj/project.pbxproj:24 → 파일 시스템 동기화 테스트 등록

## 설정
- .claude/config.json → node 및 iOS 검증 명령
- package.json → 웹 회귀
- scripts/check-ios.py → iOS 빌드·선택 테스트
