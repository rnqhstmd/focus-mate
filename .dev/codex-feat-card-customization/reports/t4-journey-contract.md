# T4 여정 보존 계약 확정

판정: NEEDS_CONTEXT 해소. 현재 구현에는 비어 있지 않은 저장 여정을 만들 수 있는 유효한 값 또는 JSON이 없다. 신규 setter·저장 여정 타입·mock seam을 추가하지 않는다. 초안 #6의 최신 정류장·기록 변경 후 카드 저장 시험은 유효하며, 저장 여정은 `active == nil` 보존까지만 주장한다. 이 문서는 소스 읽기에 의한 계약 확인이며 빌드·시험·RED 증거가 아니다.

## 확인한 기존 계약

- `ios/FocusMate/JourneySection.swift:4`: `JourneySnapshot`은 case가 없는 enum이다. decoder는 모든 입력에 `DecodingError.dataCorrupted`를 던진다. 생성 가능한 nonempty 값이 없다.
- `JourneySection.init(active: JourneySnapshot?)`, `JourneySection.empty`의 유일하게 표현 가능한 값은 nil이다. 정확한 저장 JSON은 `{"active":null}`이다. `active` 키 누락은 구조 오류이며 객체·문자열 등 non-null 값도 구조 오류다.
- `SnapshotCodec.decode(_ data: Data) throws -> AppSnapshot`은 이 decoding 오류를 `StorageIssue.corrupt`로 분류한다. nonempty 원본은 정상 변환하거나 unknown 데이터로 round-trip하지 않는다. store/AppModel의 기존 오류·원본 보존 경계를 따른다.
- `AppSnapshot.updating(journey: JourneySection) -> AppSnapshot`은 존재하지만 새로운 nonempty 값을 공급할 수 없다. empty를 다시 넣는 조작은 값 변화가 아니므로 stale snapshot 검출 시험의 변경 증거로 쓰지 않는다.

## 최신 snapshot 변경용 기존 API

아래는 모두 internal이며 `@testable import FocusMate`로 호출할 수 있다.

```swift
AppModel.init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init())
AppModel.loadIfNeeded()
AppModel.save(_ candidate: AppSnapshot) -> Bool
AppModel.saveRecordMemo(_ memo: String, forJourneyID id: String) -> Bool
AppSnapshot.updatingStage(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?) -> AppSnapshot
```

`drafts/CardCustomizationAppModelTests.swift` #6의 순서를 유지한다: 실제 저장 파일 load → beginCardCustomization → 현재 snapshot.updatingStage를 model.save → saveRecordMemo → controller 색 변경·save → 새 LocalSnapshotStore로 load. `snapshot` setter는 필요 없다.

이미 초안에 있는 독립 v2 fixture의 기록 `journey-001`을 그대로 사용한다. 기대 리터럴은 initialStation `(seongsu, 성수, 1)`, 변경 currentStation `(seongsu, 성수역, -1)`, 기록 수 1·id `journey-001`·minutes 25·memo `진입 후 메모`, journey.active nil, 카드 ID `FM-01234567`, issuedAt `2026-10-13T09:00:00Z`이다. 변경 전 원본 메모는 `첫 메모`이므로 stale snapshot 재사용을 실제로 검출한다. 최신 전체 records equality와 리터럴 필드 검사를 함께 유지한다.

## 메모리 여정 선택과 저장 여정 구분

`ios/FocusMate/AppModel+JourneyStart.swift`의 `preparedJourney: JourneySelection?`는 snapshot.journey가 아니라 현재 정류장과 `journeyPlan`에서 계산한다. `JourneyPlanDraft`는 메모리에만 존재한다. 이는 비어 있지 않은 저장 여정 fixture를 대신하지 않는다.

필요한 별도 회귀 시험은 기존 API로 작성할 수 있다. 편집 진입 후 currentStation을 `(seongsu, 성수, 1)`로 model.save하고 다음을 호출한다.

```swift
model.journeyPlan.setMinutes(60)
model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
```

choose의 반환값은 true다. 카드 저장 전후 `preparedJourney` 기대값은 `JourneySelection(origin: StopPosition(index: 0, direction: 1), minutes: 60, busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12)`이다. 이는 같은 실행의 메모리 선택 보존 검사다. 재실행 복원 대상으로 확장하지 않는다. 기존 `JourneyStartModelTests.swift:133`에 같은 리터럴 계약이 있다.

## RED 작성자 조치

초안 #6의 NEEDS_CONTEXT 주석은 ‘현재 저장 여정 계약은 active nil만 표현 가능하여 nil 보존을 검증한다’로 바꿀 수 있다. nonempty 저장 여정 시험 부재는 W10 구현 차단 사유가 아니다. 미래 W03/W04가 저장 여정 schema를 정의할 때 nonempty 갱신 보존 시험을 확장한다. 현재 unknown active 데이터를 읽고 보존하는 새 Codable 정책을 발명하지 않는다.

## 조사 범위와 한계

보고서·draft·JourneySection·AppModel·AppModel+JourneyStart·JourneyPlanDraft·기존 JourneyStartModelTests·StorageV2Tests를 읽었다. 최초 전달 경로 `draft/`는 없고 실제 경로는 `drafts/`임을 확인해 수정했다. 소스·시험 파일 수정, build/test, agent 실행은 하지 않았다.
