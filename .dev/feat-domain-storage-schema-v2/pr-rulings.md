## Rulings
- T1 컴파일 RED 인정 — 구조 태스크 RED를 미존재 심볼 컴파일 실패로 인정, GREEN 후 24케이스 실제 통과 (틀리면: 신규 타입을 빈 뼈대로 되돌려 assertion RED 재확인)
- T1 중간 회귀 수용 — T1~T3 사이 기존 v1 읽기 테스트 실패를 T3 완료까지 유지, Mechanical Gate에서 해소 확인 (틀리면: phase-review 전체 회귀가 검출)
- review 동작 불변 정리 1건 — 테스트 헬퍼 중복을 StorageTestSupport.swift로 통합 (틀리면: review-cleanup.md 목록대로 private 헬퍼 복원)
- security MEDIUM 4건 처리 — 문서 정정 3건(FR-5 문구, BR-4 전제, 설계 인계), 크기·경쟁 조건 1건 유예 (틀리면: trust-ledger 항목 기준 후속 작업에서 RED부터)
- review Minor 13건 유예 · MEDIUM 1건 정리 — 설계서 FR-5 문구 정정, Minor 유예 (틀리면: review-deferred.md 항목을 후속 작업에서 정리)

## Deferred
- [Minor] ios/FocusMateTests/StorageTestSupport.swift:6-38 — XCTestCase extension 범용 이름 노출
- [Minor] ios/FocusMateTests/StorageV2Tests.swift:176-182 — seed 와 AppFoundationTests 인라인 시드 중복
- [Minor] ios/FocusMateTests/StorageTestSupport.swift:20,24 — 빈 message 시 실패 문구 끝 공백
- [Minor] ios/FocusMate/SnapshotCodec.swift — validate catch 폴백 없음, `case 1` 매직 넘버
- [Minor] 원소 enum Equatable 합성, AppSnapshot updating… 6인자 호출 반복
- [Minor] 영역 보존 단언이 W00에서 항상 참 — W01 이후 실제 원소로 보강(인계)
- [Minor] 기타 테스트 가독성 4건(주석 불일치, 상수 단언, AC-3 읽기 바이트 단언, 영역 모르는 키 직접 검증 범위)
- [Minor] context/*/architecture.md, docs/PHASE-1-FOUNDATION.md "버전 1" 서술 갱신 판단
- [MEDIUM] 파일 크기 상한·save 확인→쓰기 경쟁 조건 — 첫 운영 저장 호출 작업·W13·Phase 6에서 재평가
