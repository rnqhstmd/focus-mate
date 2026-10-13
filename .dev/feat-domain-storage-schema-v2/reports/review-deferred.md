# Deferred (review 2회차 기준 정본)

## review 2회차 Minor (3)
- [Minor] ios/FocusMateTests/StorageTestSupport.swift:6-38 — XCTestCase extension 범용 이름(stage/withTemporaryFile) 노출, 전용 프로토콜로 범위 축소 고려
- [Minor] StorageV2Tests.swift:176-182 seed 와 AppFoundationTests.swift:111-115 인라인 시드 중복
- [Minor] StorageTestSupport.swift:20,24 — 빈 message 시 실패 문구 끝 공백

## review 1회차 Minor (10, 유예 유지)
- SnapshotCodec.swift validate catch가 SnapshotValidationIssue만 처리(계약 주석/폴백 catch 고려)
- SnapshotCodec.swift `case 1` 매직 넘버 → 이름 있는 상수
- 원소 enum Equatable 합성(설계는 직접 작성)
- AppSnapshot updating… 4곳 6인자 호출 반복
- 영역 보존 단언 W00에서 항상 참 / updating(journey:)·(records:) 타 영역 보존 테스트 없음 (W01 인계)
- 영역 모르는 키 무시 직접 검증은 CardSection만 (코덱 수준은 3영역 커버)
- AppSnapshotSectionsTests.swift:41 깨짐 주석과 검출력 불일치
- testCurrentVersionIsTwo 저가치 상수 단언
- StorageV2Tests AC-3 읽기 테스트 바이트 보존 단언 없음(저장 테스트가 커버)
- [검증 필요] context/*/architecture.md, docs/PHASE-1-FOUNDATION.md "버전 1" 서술 갱신 판단 (문서화 단계)

## security
- [MEDIUM 유예] 파일 크기 상한·save 확인→쓰기 경쟁 조건 — 첫 운영 저장 호출 작업(묶음 2)·W13·Phase 6에서 재평가
