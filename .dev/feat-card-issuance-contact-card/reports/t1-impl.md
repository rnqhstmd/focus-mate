# T1 IMPLEMENT (세션) — AC-13, AC-14(단위)

## 구현 내용
- ios/FocusMate/CardSection.swift: `CardSnapshot`을 값 없는 enum → `struct { id: String; issuedAt: Date }`. 두 키 필수, `issuedAt`은 `Date(_, strategy: .iso8601)` 파싱 실패 시 `DecodingError.dataCorrupted`(→ `.corrupt`). 인코딩은 `issuedAt.formatted(.iso8601)` 문자열 직접 기록. `static isValidID`(UTF-8 11바이트, `FM-` 접두, ASCII 숫자 8자리).
- ios/FocusMate/AppSnapshot.swift: `SnapshotValidationIssue`에 `multipleCards(Int)`, `cardWithoutIssuance`, `invalidCardID` 추가. `validate()` 끝에 카드 수 → 미발급 카드 → id 형식 순으로 검사. `currentCard`, `needsCardSupplement`, `issuingCard(_:)` 추가.

## GREEN 증거
`python3 scripts/check-ios.py test ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift` → Executed 50 tests, with 0 failures (CardStorage 10, SnapshotCodec 24, AppSnapshotSections 16). 첫 구현에서 통과.

## REFACTOR 내역
정리 없음 (변경 최소, 기존 패턴 그대로).

## self-review 결과
- 완전성: AC-13 바이트 고정·왕복, AC-14 a~f 분류·쓰기 차단 모두 통과. 카드 0개 발급 상태 유효.
- 품질: id 형식을 디코딩이 아닌 validate에 둬 설계 §1·§3 분류와 일치.
- 규율: 테스트 파일 미수정(해시 동일). 과잉 멤버 없음 — needsCardSupplement·currentCard·issuingCard·init(id:issuedAt:) 모두 테스트가 참조.
- 테스트: 기존 SnapshotCodecTests `[1]`/`[{}]` 계속 .corrupt.

## 우려사항
없음
