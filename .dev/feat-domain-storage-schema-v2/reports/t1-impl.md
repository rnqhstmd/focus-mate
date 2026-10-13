# T1 IMPLEMENT — 영역 타입·AppSnapshot 구조 (세션 직접)

## 구현 내용
- 신규 `ios/FocusMate/CardSection.swift`, `JourneySection.swift`, `RecordSection.swift`
  - 원소 `CardSnapshot`/`JourneySnapshot`/`RecordSnapshot`: 값 없는 enum. `init(from:)`는 항상 `DecodingError.dataCorrupted`, `encode(to:)`는 `switch self {}`. Equatable은 합성(케이스 없음).
  - 영역 struct: `init(from:)`/`encode(to:)`를 extension에 두어 memberwise 생성자 유지(`static let empty`). keyed container 필수, 골격 키(`items`/`active`) 필수, 모르는 키 무시. `JourneySection`은 `contains(.active)` 확인 후 `decodeNil`, nil이면 `encodeNil`.
- `ios/FocusMate/AppSnapshot.swift`: `cards`/`journey`/`records` 필드, 6인자 `private init`, `.empty`, `updatingStage(...)`, `updating(cards:)`, `updating(journey:)`, `updating(records:)`, `CodingKeys`·`encode(to:)`에 영역 3개 추가. `validate()`·`launchRoute()` 변경 없음.
- `ios/FocusMate/UITestBootstrap.swift`: `AppSnapshot(...)` 호출 3곳을 `.empty.updatingStage(...)`·`original.updatingStage(...)`로 변경(값 동일).

## GREEN 증거
- focused: `python3 scripts/check-ios.py test ios/FocusMateTests/AppSnapshotSectionsTests.swift ios/FocusMateTests/AppFoundationTests.swift`
- `AppSnapshotSectionsTests`: Executed 24 tests, 0 failures — **24 pass / 0 fail** (T1 RED 집합 전부 통과)
- 로그: reports/t1-impl-run.log

## REFACTOR 내역
- 정리 없음 (중복된 `AppSnapshot(...)` 6인자 호출 4곳은 설계 시그니처 그대로라 유지).

## self-review 결과
- 완전성: RED 24 케이스 모두 통과. 설계 인터페이스 시그니처와 일치.
- 품질: 원소 enum의 디코딩 실패 메시지에 미정의 사유 명시.
- 규율: 테스트 파일 무수정(해시 `137a8b6…`, `ca8b624…` 기준선 일치). 추가 기능 없음.
- 테스트: T1 집합 밖 영향은 아래 우려사항.

## 우려사항
- **예상된 중간 회귀**: 기존 `AppFoundationTests` 중 버전 1 파일을 읽는 테스트 14건 중 일부(17 assertion)가 `corrupt`로 실패한다. 원인: `LocalSnapshotStore`가 v1 `state`를 `AppSnapshot` 합성 디코딩으로 읽는데, 이제 영역 키가 필수라 v1 본문이 `keyNotFound` → `corrupt`가 된다. v1→v2 변환은 설계상 T2(`SnapshotCodec`)·T3(저장소 위임) 범위이며 T3 완료 시 복구되어야 한다. T1의 focused 집합(AppSnapshotSectionsTests)에는 해당하지 않음. 전체 회귀는 사이클 경계(phase-review Step 0)에서 확인.
