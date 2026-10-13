## 코드 맵: W00 도메인 저장 구조 확장(버전 1→2)

### 핵심 파일
- ios/FocusMate/LocalSnapshotStore.swift:24 → `Envelope{version,state}` 인코딩·버전 헤더 판정(`version == 1`만 허용), 손상·미지원 시 원본 보존, 쓰기 전 기존 파일 load로 쓰기 차단
- ios/FocusMate/AppSnapshot.swift:14 → `AppSnapshot{cardIssued, initialStation, currentStation}`·`validate()`·`launchRoute()` (version 1 상태 모델)
- ios/FocusMate/AppModel.swift:17 → 로드·저장 오케스트레이션, `LaunchState`, 저장 실패 시 이전 snapshot 유지
- ios/FocusMateTests/AppFoundationTests.swift:5 → 저장소·스냅샷 단위 테스트(버전/손상/쓰기 차단/라운드트립) — v1 바이트 fixture `readyEnvelope`

### 참조 파일
- ios/FocusMate/UITestBootstrap.swift:24 → DEBUG 시험 경로·seed(`corrupt`, `version 999`) 주입
- ios/FocusMate/FocusMateApp.swift:16 → 운영 경로 Application Support/FocusMate/app-state.json
- ios/FocusMateUITests/Phase1FlowTests.swift → 진입·재실행 복원 UI 테스트
- docs/PHASE-1-FOUNDATION.md → version 1 저장 계약과 안전 경계
- .dev/plan.md → W00 의존 근거(카드·여정·기록 저장 섹션과 마이그레이션 선행)
- context/*/status.md → 도메인별 저장 요구사항(card FR-3, journey FR-11·13, records FR-5)

### 설정
- scripts/check-ios.py → iOS build/test 진입점 (`python3 scripts/check-ios.py test [file]`)
- .claude/config.json → projectTypes ios-swiftui·node
