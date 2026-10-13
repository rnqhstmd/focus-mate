# review 정리 모드 (1회차)

## 정리 대상
- [Important 동작불변] 테스트 헬퍼 중복 — SnapshotCodecTests.swift:25, StorageV2Tests.swift:191·208, AppFoundationTests.swift:10·360·376, AppSnapshotSectionsTests.swift:9, StorageV2Tests.swift:10

## 수행
- 신규 ios/FocusMateTests/StorageTestSupport.swift: `extension XCTestCase { static func stage(...); func assertStorageIssue(_:_:file:line:operation:); func withTemporaryFile(_:) }` — 실패 메시지에 기대값 포함(형식 통일), 임시 디렉토리 접두사는 `FocusMate-{클래스명}-`.
- 4개 테스트 파일의 private 사본 삭제(단언·케이스 변경 없음).

## 검증
- `python3 scripts/check-ios.py test` 단위 4파일: 62 pass / 0 fail (reports/cleanup-run.log). 전체 회귀는 2회차 Mechanical Gate.

## 문서 정리 (security MEDIUM, 동작 불변)
- prd.md FR-5 문구 정정, BR-4 전제 명시, design.md 후속 작업 인계에 영역 모르는 키 정책 추가.
