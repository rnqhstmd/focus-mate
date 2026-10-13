# 코드 맵: W08 완료·메모 저장 모델
## 핵심 파일
- ios/FocusMate/RecordSection.swift → W00의 빈 기록 섹션
- ios/FocusMate/AppSnapshot.swift → v2 스냅샷 및 섹션 교체
- ios/FocusMate/LocalSnapshotStore.swift → 원자적 로컬 저장 및 복원
- ios/FocusMate/SnapshotCodec.swift → 저장 데이터 버전 및 검증
- ios/FocusMate/AppModel.swift → 앱 상태 및 저장 실패 처리
## 참조 파일
- context/records/status.md → FR-5 및 NFR-1
- context/records/glossary.md → 완료·메모·집계 용어
- context/records/architecture.md → records 경계
- designs/final/animation-preview.html → recordJourney/loadRecords/persistRecords/메모 계약
- ios/FocusMateTests/StorageV2Tests.swift → 기존 저장소 회귀
- ios/FocusMateTests/StorageTestSupport.swift → 실제 임시 파일 저장 지원
## 설정
- .claude/config.json → 테스트/빌드 명령
- scripts/check-ios.py → Simulator 검증 진입점
- ios/FocusMate.xcodeproj/project.pbxproj → 빌드 대상
