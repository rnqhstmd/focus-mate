# 설계: 도메인 저장 구조 확장 (버전 1 → 2) [W00]: 도메인 저장 구조 확장 (버전 1 → 2) [W00]

**2회차 변경 요약**
- (MUST-1) 원소 타입을 **값이 없는 enum**(`enum CardSnapshot {}` 등)으로 바꿨습니다. `init(from:)`가 항상 오류를 던지도록 직접 작성하므로 툴체인과 상관없이 동작합니다. W00 빌드에서는 원소가 하나라도 있으면 `corrupt`입니다. 원소 형식과 원소 안 항목 누락의 처리는 후속 작업이 이 타입을 바꾸면서 정합니다(BR-5).
- (MUST-1) 바이트 결정성(AC-2)은 가정으로 두지 않고 **고정 바이트(golden) 테스트**로 검증합니다. 빈 상태와 AC-1 변환 결과 두 가지를 정확한 문자열과 비교합니다.
- (MUST-2) `AppSnapshot`의 전체 생성자는 **private**으로 바꾸고 영역 기본값을 없앴습니다. 대신 `.empty`와 한 부분만 바꾸는 갱신 함수(`updatingStage`, `updating(cards:)`, `updating(journey:)`, `updating(records:)`)를 제공합니다. 운영 코드 3곳과 테스트 4곳은 호출 형태만 바꾸고 단언 의미는 그대로입니다.
- 정책 표, 테스트 목록, AC 매핑을 위 결정에 맞게 다시 맞췄습니다. "후속 작업 인계" 절을 새로 만들었습니다.
- 바로잡은 사실: 프로젝트 설정은 `SWIFT_VERSION = 5.0`, `SWIFT_STRICT_CONCURRENCY = minimal`입니다(`project.pbxproj:54-55`). 1회차의 "Swift 6" 서술은 틀렸습니다.

### 설계 규모
**중형**: 저장 계약(파일 버전, 디코딩 정책, 상태 생성 방식)이 바뀌고 W01~W13이 이 구조를 씁니다. 다만 수정 범위는 저장 계층과 신규 파일 4개이고 UI 변화는 없습니다.

### 배경 및 목적
- 현재 `app-state.json`은 버전 1이고 `cardIssued`, `initialStation`, `currentStation`만 담습니다. 손상, 미지원 버전, 읽기 실패가 있으면 원본을 보존하고 쓰기를 막습니다.
- 카드(W01·W02), 여정(W04·W05·W07), 기록(W08)이 같은 파일 구조를 동시에 바꾸면 충돌합니다. 그래서 구조 변경은 W00에서 한 번만 하고, 후속 작업은 자기 영역의 내용만 채웁니다.
- 버전 1 사용자의 데이터는 100% 보존되고 화면 변화도 없어야 합니다. 알 수 없는 파일은 어떤 경우에도 덮어쓰지 않습니다.

### 요구사항 및 수용 기준
- [Must] FR-1: 저장 파일은 버전 2 형식을 갖는다. 기존 항목(발급 여부, 최초 정류장, 현재 정류장) 위치와 의미는 그대로 두고, 카드·여정·기록 영역 세 개를 추가한다.
- [Must] FR-2: 새 영역의 초기 내용은 카드 없음(빈 목록), 진행 중 여정 없음, 완료 기록 없음(빈 목록)이다. 상세 항목은 후속 작업이 정한다.
- [Must] FR-3: 버전 1 파일을 읽으면 버전 2 상태로 변환해 사용한다. 기존 항목은 그대로 유지하고 새 영역은 초기 내용으로 채운다. 읽기만 한 경우에는 파일을 바꾸지 않는다.
- [Must] FR-4: 이후 모든 저장은 버전 2로 기록한다. 저장 시 세 영역의 내용과 기존 항목이 함께 유지된다.
- [Must] FR-5: 지원하지 않는 버전은 읽지 않는다. 대상은 3 이상, 0 이하, 숫자가 아닌 값이다. 파일이 없으면 첫 실행으로 보고 초기 상태로 시작한다.
- [Must] FR-6: 변환이나 검증에 실패하면 원본을 보존하고 새 저장을 막는다. 오류 종류는 현재 구분(손상, 미지원 버전, 내용 불일치, 읽기 실패)을 그대로 쓴다.
- [Must] FR-7: 시작 화면 분기는 기존과 같다. 새 영역의 내용은 분기에 영향을 주지 않는다.
- [Must] BR-1: 영역 안에 항목을 추가하는 것은 버전 변경 사유가 아니다.
- [Must] BR-2: 알 수 없거나 손상된 원본은 어떤 경로로도 초기 상태로 덮어쓰지 않는다.
- [Must] BR-3: 저장 실패 시 직전 메모리 상태와 기존 파일을 유지한다. atomic write를 유지한다.
- [Must] BR-4: 버전 1 백업 파일을 만들지 않는다.
- [Must] BR-5: 버전 2 파일에서 영역 하나가 통째로 없으면 손상이다. 영역 안의 항목 누락 처리는 해당 후속 작업이 정한다.
- AC-1~AC-5는 PRD(`/Users/bonseung/Documents/ChatGPT/new/.dev/feat-domain-storage-schema-v2/prd.md:57-77`)를 그대로 따릅니다. 담당 컴포넌트는 "AC와 컴포넌트 매핑"에 정리했습니다.

### 변경 범위
- **영향 모듈**: iOS 앱 타깃의 저장 계층과 단위 테스트 타깃입니다. 웹 프로토타입은 범위 밖입니다.
- **신규 생성 파일**: 동기화 그룹 방식이라 `project.pbxproj`를 고치지 않아도 자동으로 포함됩니다(`project.pbxproj:22-26`).
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/CardSection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/JourneySection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/RecordSection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/SnapshotCodec.swift`
- **수정 대상 파일**
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/LocalSnapshotStore.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/UITestBootstrap.swift` (3곳, 호출 형태만 변경)
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppFoundationTests.swift` (호출 형태 4곳 변경, 테스트 추가)
- **수정하지 않는 파일**: `AppModel.swift`, `RootView.swift`, `FocusMateApp.swift`, `Phase1FlowTests.swift`, `StorageIssue`(`LocalSnapshotStore.swift:3-6`).
- **파일 분리를 유지하는 근거**
  - 영역 3파일: W01·W02, W04·W05·W07, W08이 병렬로 원소 타입을 바꿀 때 서로 다른 파일만 고치게 합니다.
  - `SnapshotCodec`: I/O 없이 바이트를 직접 넣어 정책을 고정 테스트할 수 있습니다. 버전 1 계약도 한곳에 묶어 둡니다.

### 적용 컨벤션
- **네이밍**
  - 타입은 UpperCamelCase이고 저장 모델 접미사는 `…Snapshot`입니다(`AppSnapshot.swift:3, 14`).
  - 오류는 `…Issue` enum입니다(`AppSnapshot.swift:10`, `LocalSnapshotStore.swift:3`).
  - 기본값 이름은 `static let empty`입니다(`AppSnapshot.swift:18`).
  - 복사 후 일부만 바꾸는 함수는 Swift API 가이드의 비변경(non-mutating) 명명인 `updating…`을 씁니다.
- **저장 모델**: `Codable, Equatable`인 값 타입 struct와 `let` 프로퍼티를 씁니다. nil인 optional도 키를 남기도록 `encodeNil`로 씁니다(`AppSnapshot.swift:37-45`).
- **I/O 격리**: `LocalSnapshotStore` 생성자에서 `readData`, `createDirectory`, `writeData` 클로저를 주입합니다(`LocalSnapshotStore.swift:14-22`).
- **오류 순서**
  - 읽기: 읽기 실패는 `unreadable`(파일 없음만 nil) → 헤더 실패는 `corrupt` → 버전 불일치는 `unsupportedVersion` → 본문 실패는 `corrupt` → `validate()` 실패는 `invalidState`입니다(`:27-42`).
  - 저장: `validate()` → `load()` 실패 시 `writeBlocked` → 인코딩, 디렉터리 생성, 쓰기 순서이고, 이 마지막 단계의 실패는 모두 `writeFailed`입니다(`:44-56`).
- **인코딩**: `.sortedKeys`(`:50-51`)와 `.atomic`(`:17`)을 씁니다.
- **언어 설정**: `SWIFT_VERSION = 5.0`, `SWIFT_STRICT_CONCURRENCY = minimal`입니다(`project.pbxproj:54-55`).
- **테스트**: XCTest와 `assertStorageIssue`, `withTemporaryFile` 헬퍼를 씁니다(`AppFoundationTests.swift:360-385`). 실행은 `python3 scripts/check-ios.py test [file]`입니다.
- **안전 경계**: `docs/PHASE-1-FOUNDATION.md:40-42, 50-54`를 지킵니다.

### 버전 2 파일 형식 (확정안, golden 테스트로 고정)

G1. 빈 상태(`AppSnapshot.empty`)를 인코딩한 결과입니다.
```
{"state":{"cardIssued":false,"cards":{"items":[]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":2}
```
G2. AC-1 입력을 변환한 뒤 인코딩한 결과입니다.
```
{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}
```
- 기존 3개 키는 `state` 바로 아래에서 위치와 의미가 그대로입니다(FR-1).
- 영역은 **객체**입니다. 후속 작업이 영역 단위 필드를 버전 변경 없이 추가할 수 있습니다(BR-1).
- `journey.active`는 진행 여정이 없을 때도 `null`로 명시합니다.
- **결정성 검증**: 위 두 문자열과의 정확한 비교를 단위 테스트로 고정합니다. Foundation의 키 정렬이나 이스케이프 방식이 바뀌면 이 테스트가 실패해서 바로 드러납니다. W00 빌드에서 영역은 항상 비어 있으므로 위 두 경우가 W00이 만들 수 있는 출력의 대표값입니다.

### 디코딩 정책 (W00 빌드 기준)

| 대상 | 정책 | 결과 | 보장 방식 |
|---|---|---|---|
| `version` 누락, null, 숫자가 아님(`"2"`), 빈 파일 | 헤더 형식 오류 | `corrupt` | `VersionHeader.version: Int` 디코딩 실패 |
| `version` 0 이하, 3 이상 | 미지원 | `unsupportedVersion(n)` | 코덱 `switch` |
| `state.cards`, `.journey`, `.records` 키 누락 | 필수(BR-5) | `corrupt` | `AppSnapshot`의 비옵셔널 필드라 `keyNotFound` |
| 영역 값이 null이거나 객체가 아님 | 형식 오류 | `corrupt` | 영역 `init(from:)`이 `decoder.container(keyedBy:)`를 명시적으로 호출 |
| 골격 키 `cards.items`, `records.items`, `journey.active` 누락 | 필수(FR-2가 정한 자리) | `corrupt` | `items`는 `decode`, `active`는 `contains` 확인 후 `decodeNil` |
| `items`가 배열이 아니거나 null | 형식 오류 | `corrupt` | `[Element]` 디코딩 실패 |
| `items` 원소가 하나라도 있음(객체, 숫자 무관), `active`가 null이 아님 | **W00은 원소 계약을 정의하지 않음** | `corrupt` | 원소 타입은 값이 없는 enum이고 `init(from:)`가 항상 throw |
| 영역 안의 모르는 키 | 무시 | 정상 | 영역 `init(from:)`가 알려진 키만 읽음 |
| `state` 최상위의 모르는 키 | 무시(현행 유지) | 정상 | 합성 디코딩 |

- **원소 정책을 위임하는 방식**: W00은 원소의 필드, 형식, 누락 처리를 정하지 않습니다(BR-5).
  - W00 빌드는 원소를 해석할 수 없습니다. 그래서 원소가 하나라도 있으면 버리지 않고 `corrupt`로 보존하며, 쓰기도 막습니다(BR-2 쪽으로 안전하게 실패).
  - 후속 작업이 원소 타입 선언을 struct로 바꾸면 이 표의 원소 행을 그 작업의 정책이 대체합니다.
- **툴체인과 무관하게 보장하는 범위**: 필드가 없는 struct의 합성 Codable에는 기대지 않습니다. 영역 3개와 원소 3개의 `init(from:)`와 `encode(to:)`, 그리고 원소의 `==`는 모두 직접 작성합니다.
- **모르는 키를 무시하는 근거**: `JSONDecoder`의 기본 동작이고 현재 버전 1도 이렇게 읽습니다. 같은 버전 안에서 영역 필드가 늘어나도 이전 빌드가 손상으로 잘못 판단하지 않습니다.

### 상세 설계

1. **`ios/FocusMate/CardSection.swift`, `JourneySection.swift`, `RecordSection.swift` (신규)**: 영역 골격과 원소 자리표시자
   - 현재: 없음.
   - 변경
     - 원소 타입은 **값이 없는 enum**입니다. 이 타입의 값은 만들 수 없으므로 W00에서 영역은 항상 비어 있습니다.
       - `init(from:)`는 `DecodingError.dataCorrupted`를 throw합니다.
       - `encode(to:)`와 `==`는 `switch self {}`로 구현합니다.
     - 영역 struct는 `init(from:)`에서 `container(keyedBy:)`를 직접 호출합니다. 그런 다음 골격 키만 읽고 모르는 키는 무시합니다.
     - `JourneySection`은 다음 순서로 읽습니다.
       - `contains(.active)`가 거짓이면 `keyNotFound`를 throw합니다.
       - `decodeNil(forKey:)`가 참이면 nil입니다.
       - 그 밖에는 `decode(JourneySnapshot.self, …)`를 호출하고, 여기서 항상 실패합니다.
     - 인코딩은 `items`를 항상 쓰고, `active`가 nil이면 `encodeNil`로 씁니다.
   - 시그니처
     - `enum CardSnapshot: Codable, Equatable {}`. `init(from:)`, `encode(to:)`, `static func ==`는 직접 작성합니다. `JourneySnapshot`, `RecordSnapshot`도 같은 형태입니다.
     - `struct CardSection: Codable, Equatable { let items: [CardSnapshot]; static let empty: CardSection }`
     - `struct JourneySection: Codable, Equatable { let active: JourneySnapshot?; static let empty: JourneySection }`
     - `struct RecordSection: Codable, Equatable { let items: [RecordSnapshot]; static let empty: RecordSection }`
   - 고려사항: W00에서는 영역 내용을 검증하지 않습니다(FR-7). 후속 작업은 자기 파일의 원소 enum을 struct로 바꾸고, 원소의 `init(from:)` 정책을 스스로 정합니다.

2. **`ios/FocusMate/AppSnapshot.swift`**: 영역 3개 추가, 전체 생성자 봉인
   - 현재
     - 필드는 3개입니다(`:15-17`).
     - 합성 memberwise 생성자가 internal이라 어디서나 상태 전체를 다시 만들 수 있습니다(`:18`, 테스트, `UITestBootstrap`).
     - 인코딩은 직접 작성했고(`:37-45`) 디코딩은 합성입니다.
   - 변경
     - 필드를 추가합니다: `let cards: CardSection`, `let journey: JourneySection`, `let records: RecordSection`.
     - 6개 인자를 받는 생성자를 **`private`**으로 선언하고 기본값을 두지 않습니다. 이 선언 때문에 암시적 memberwise 생성자는 만들어지지 않습니다. 따라서 타입 밖에서는 "영역을 빈 값으로 다시 만들어 넘기는" 경로가 컴파일 단계에서 막힙니다(FR-4).
     - 타입 밖에서 상태를 만드는 방법은 세 가지뿐입니다: `.empty`, 기존 값에서 시작하는 `updating…`, 디코딩.
     - `CodingKeys`에 영역 3개를 추가하고, `encode(to:)`에서 영역 3개를 항상 인코딩합니다. 디코딩은 합성을 유지합니다. 비옵셔널 영역의 키가 없으면 `keyNotFound`이고, 이는 `corrupt`로 연결됩니다.
   - 시그니처
     - `private init(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?, cards: CardSection, journey: JourneySection, records: RecordSection)`
     - `static let empty` (영역 모두 `.empty`)
     - `func updatingStage(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?) -> AppSnapshot` (영역은 원본 유지)
     - `func updating(cards: CardSection) -> AppSnapshot`, `func updating(journey: JourneySection) -> AppSnapshot`, `func updating(records: RecordSection) -> AppSnapshot` (나머지는 원본 유지)
   - `validate()`(`:20-29`)와 `launchRoute()`(`:31-35`)는 **바꾸지 않습니다**. `updating…`도 검증하지 않는 순수 복사입니다. 검증은 기존대로 저장과 읽기 시점에 합니다.
   - 고려사항: 영역별 갱신 함수 3개를 W00에서 미리 두므로, 후속 작업은 원소 타입 파일만 고치면 됩니다. 병렬 작업이 `AppSnapshot.swift`를 같이 고치는 일을 줄입니다.

3. **`ios/FocusMate/SnapshotCodec.swift` (신규)**: 버전 판정, 변환, 직렬화를 하는 순수 함수
   - 현재: 같은 로직이 `LocalSnapshotStore.swift:24-25, 32-41, 50-52`에 I/O와 섞여 있습니다.
   - 변경: 상태 없는 `enum SnapshotCodec`로 분리합니다.
     - `VersionHeader`를 디코딩하고, 실패하면 `corrupt`입니다.
     - `switch version`
       - `1`: `EnvelopeV1`로 디코딩한 뒤 `migrateV1`을 거칩니다.
       - `2`: `Envelope`로 디코딩합니다.
       - 그 밖: `unsupportedVersion(version)`입니다.
     - 본문 디코딩 실패는 `corrupt`, 이어서 `validate()` 실패는 `invalidState`입니다. 순서는 헤더 → 버전 → 구조 → 내용으로 현행과 같습니다.
     - `encode`는 `.sortedKeys`로 `Envelope(version: currentVersion, state:)`를 만듭니다.
   - 시그니처
     - `static let currentVersion = 2`
     - `static func decode(_ data: Data) throws -> AppSnapshot` (`.corrupt`, `.unsupportedVersion`, `.invalidState`만 던짐)
     - `static func encode(_ snapshot: AppSnapshot) throws -> Data`
     - `static func migrateV1(_ legacy: LegacySnapshotV1) -> AppSnapshot`: `AppSnapshot.empty.updatingStage(…)`로 구현합니다. 그래서 "영역은 초기 내용, 기존 3개 항목은 복사"라는 FR-3의 의미가 코드에 그대로 드러납니다.
     - `struct LegacySnapshotV1: Decodable { let cardIssued: Bool; let initialStation: StationSnapshot?; let currentStation: StationSnapshot? }` (internal, 버전 1 계약 고정)
     - `private struct VersionHeader`, `private struct EnvelopeV1`, `private struct Envelope`
   - 고려사항: 변환은 메모리에서만 일어납니다. 쓰기 백과 백업 파일은 만들지 않습니다(FR-3, BR-4).

4. **`ios/FocusMate/LocalSnapshotStore.swift`**: 코덱에 위임
   - 현재: `version == 1`만 허용하고(`:35`) 버전 1로 인코딩합니다(`:52`).
   - 변경
     - `load()`의 읽기와 파일 없음 처리(`:28-31`)는 그대로 둡니다. 그 뒤 처리는 `SnapshotCodec.decode(data)` 한 번으로 바꿉니다.
     - `save()`의 `validate` → `load()` 차단 순서(`:45-48`)는 유지합니다. 인코딩만 `SnapshotCodec.encode`로 바꾸고, 이 호출은 기존 `writeFailed` 블록 안에 둡니다.
     - `:24-25`의 선언은 삭제합니다.
   - 공개 API는 바뀌지 않습니다.
   - 고려사항
     - 버전 1 파일에서 `save()`하면 내부 `load()`가 변환에 성공하므로 버전 2로 덮어씁니다(정상 흐름 A).
     - 쓰기 실패 시에는 atomic write라 기존 파일이 남습니다(BR-3).

5. **`ios/FocusMate/UITestBootstrap.swift`**: 호출 형태 변경 (동작 동일)
   - `:32` → `AppSnapshot.empty.updatingStage(cardIssued: true, initialStation: nil, currentStation: nil)`
   - `:50-51` → `original.updatingStage(cardIssued: original.cardIssued, initialStation: original.initialStation, currentStation: StationSnapshot(id: "ttukseom", …))`. 이제 영역은 구조상 원본 그대로 유지됩니다.
   - `:60-62` → `.empty.updatingStage(…)`, 값은 그대로입니다.
   - seed `corrupt`, `unsupported`(`:34-37`)는 바꾸지 않습니다.

6. **`AppModel.swift`**: 변경 없음
   - `loadIfNeeded()`(`:27-40`)는 `store.load() ?? .empty`이므로 파일이 없으면 영역이 빈 초기 상태입니다(FR-5).
   - `save(_:)`(`:43-59`)는 실패 시 이전 상태를 유지합니다(BR-3).
   - 운영 코드에서 `AppModel.save`를 부르는 곳은 아직 없습니다. 부르는 곳은 `UITestBootstrap.swift:50`뿐입니다.

### 기존 테스트 변경 목록

**단언 변경은 0건입니다. 바뀌는 것은 호출 형태 4곳뿐입니다.** 테스트 파일에 `private static func stage(_ issued: Bool, _ initial: StationSnapshot?, _ current: StationSnapshot?) -> AppSnapshot`(내부적으로 `.empty.updatingStage`)를 두고 아래 생성 지점을 바꿉니다.

| 위치 | 변경 내용 | 단언 의미 |
|---|---|---|
| `AppFoundationTests.swift:10-14` `readySnapshot` | 생성자 → `stage(true, initialStation, currentStation)` | 불변 |
| `:15-19` `cardOnlySnapshot` | → `stage(true, nil, nil)` | 불변 |
| `:44-52` 검증 위반 9건 | 각 `AppSnapshot(…)` → `stage(…)`, 인자 순서와 값 동일 | 불변 |
| `:145-149` `invalid` | → `stage(true, StationSnapshot(id: " ", …), currentStation)` | 불변 |

**바꾸지 않는 테스트**

| 위치 | 이유 |
|---|---|
| `:20-22` `readyEnvelope` (버전 1) | 변환 입력으로 그대로 유효합니다 |
| `:93-139` (corrupt, 999) | 분류와 바이트 보존이 같습니다 |
| `:168-178`, `:239-263`, `:212-236` | 비교 대상의 영역이 `.empty`라 같습니다 |
| `:266-313` | 쓰기 횟수와 상태만 확인합니다 |
| `Phase1FlowTests.swift:48-61, 128-143` | seed 시점 바이트와 상대 비교합니다 |
| `Phase1FlowTests.swift:94-120` | `{broken`, 999 바이트가 그대로입니다 |

### 추가할 테스트

`AppFoundationTests.swift`에 추가합니다. 세부 테스트 설계는 test-architect 소관입니다.

**코덱 단위 테스트** (`SnapshotCodec`, I/O 없음)
- C1 golden: `encode(.empty)` == G1, `encode(decode(AC-1 바이트))` == G2 (AC-2 결정성)
- C2 왕복: `decode(encode(x)) == x`, 두 번 인코딩한 바이트가 같음
- C3 헤더
  - `corrupt`: 빈 Data, `{}`, `{"version":null}`, `{"version":"2"}`
  - `unsupportedVersion`: 0, -1, 3, 999
- C4 영역 누락: 각 영역 3개를 하나씩 뺀 경우 → `corrupt`
- C5 영역 형식: `"cards":[]`, `"cards":null`, `"journey":"x"`, `"records":1` → `corrupt`
- C6 골격 키
  - `"cards":{}`, `"journey":{}`, `"records":{}` → `corrupt`
  - `"items":null`, `"items":{}` → `corrupt`
- C7 원소 미정의: `"items":[1]`, `"items":[{}]`(cards와 records 각각), `"active":"x"`, `"active":{}` → `corrupt` (MUST-1 고정)
- C8 관용 읽기: 영역 안과 `state` 최상위의 모르는 키 → 정상, 키가 없는 경우와 같은 값
- C9 순서
  - 버전 1 `cardIssued:false`에 정류장이 있음 → `invalidState(.inconsistentStage)`
  - 버전 2에서 영역 누락과 불일치가 함께 있음 → `corrupt`
- C10 `migrateV1`: 3개 필드 보존, 영역 == `.empty`

**AppSnapshot 테스트**
- S1 `updatingStage`: 단계 필드만 바뀌고 영역은 원본과 같습니다.
- S2 `updating(cards:)`, `updating(journey:)`, `updating(records:)`: 나머지 필드는 원본과 같습니다.
- W00에서는 영역이 늘 비어 있으므로 보존 검증은 후속 작업이 실제 원소로 다시 해야 합니다(인계 항목).

**저장소 AC 테스트**
- AC-1: 임시 파일에 PRD 원문 바이트를 둡니다. `load()` 결과 필드, 영역 개수 0, nil, 0, `launchRoute() == .main`, 읽기 전후 바이트 동일, 쓰기 0회를 확인합니다.
- AC-2: (a) 파일 없음, (b) 버전 1 파일에서 각각 `save()`합니다.
  - `JSONSerialization`으로 `version == 2`와 `state` 6개 키를 확인합니다.
  - 다시 읽은 값이 같고, 다시 저장한 바이트가 같은지 확인합니다.
  - (b)는 바이트가 G2와 같아야 합니다.
- AC-3: 버전 3, 999, 0, 빈 파일, `version` 없음, 버전 2에서 `records` 누락의 6가지에 `"version":"2"`를 더합니다. `load()` 오류, `save()`의 `writeBlocked(…)`, 디렉터리 생성과 쓰기 0회, 바이트 보존을 확인합니다.
- AC-4
  - (a) 버전 1 불일치 파일: `invalidState`와 `writeBlocked(.invalidState(.inconsistentStage))`, 바이트 보존
  - (b) 버전 2 파일에 `writeData` 실패 주입: `writeFailed`, 바이트 보존

### AC와 컴포넌트 매핑

| AC | 담당 컴포넌트 | 검증 테스트 |
|---|---|---|
| AC-1 | `SnapshotCodec.decode` 버전 1 분기, `migrateV1`(`.empty.updatingStage`), `AppSnapshot.launchRoute`, `LocalSnapshotStore.load` | AC-1, C10 |
| AC-2 | `SnapshotCodec.encode`(`currentVersion`, `.sortedKeys`), `AppSnapshot.encode(to:)`, 영역의 직접 작성 인코딩 | AC-2, C1, C2 |
| AC-3 | `SnapshotCodec.decode`의 헤더와 버전 분기, 영역과 골격 필수 디코딩, 원소 미정의 throw, `LocalSnapshotStore.save` 차단 | AC-3, C3~C7 |
| AC-4 | `AppSnapshot.validate`(변환 후 적용), `save`의 `writeFailed`와 atomic write, `AppModel.save` 롤백 | AC-4, C9, 기존 `:266-313` |
| AC-5 | `launchRoute`(변경 없음), `UITestBootstrap` seed, 기존 테스트 전체 | 기존 단위·UI 테스트 |
| FR-4 구조 보장 | private 전체 생성자, `updating…` | S1, S2, 컴파일 |

### 의존성 및 영향도
- **새 외부 의존성**: 없습니다. Foundation `JSONEncoder`와 `JSONDecoder`만 씁니다.
- **영향**
  - `AppSnapshot(cardIssued:initialStation:currentStation:)` 호출은 컴파일 오류가 납니다. 의도한 변경이며, 해당 지점은 운영 코드 3곳(`UITestBootstrap.swift:32, 50, 60`)과 테스트 4곳입니다. `ios/` 전체를 Grep해서 확인했습니다.
  - `Equatable` 비교에 영역이 포함됩니다.
- **하위 호환**: 버전 1은 변환해서 읽습니다. 버전 2 파일은 버전 1 앱에서 미지원으로 보존되며, PRD상 대응하지 않습니다.
- **문서**: `docs/PHASE-1-FOUNDATION.md:10`은 Phase 1 당시 기록이므로 다시 쓰지 않습니다. 현재 상태 문서는 구현 후 문서화 단계에서 판단합니다.

### 위험
1. **원소 타입 교체 시 정책 공백**: 후속 작업이 원소 enum을 struct로 바꾸면서 `init(from:)` 정책(필수 필드, 형식)을 정하지 않으면 합성 동작에 기대게 됩니다. 인계 항목으로 명시합니다.
2. **골격 키 엄격 판정**: `items`나 `active`가 없으면 `corrupt`입니다. W00이 항상 쓰는 키라서 정상 파일에서는 생기지 않습니다.
3. **atomic write 범위**: 파일 교체 중 장애는 Phase 1과 마찬가지로 검증하지 않습니다(`PHASE-1-FOUNDATION.md:11, 54`).

### 후속 작업 인계
- **저장 갱신 경로(묶음 2의 첫 작업이 결정)**: `AppModel.save(_:)`(`AppModel.swift:43`)는 후보 전체로 교체합니다. 후속 작업은 `model.snapshot`에서 `updating…`으로 후보를 만들어야 합니다. `AppModel`에 갱신 함수(예: 변환 클로저를 받는 저장)를 둘지는 운영 코드에서 처음 저장을 호출하는 작업이 정합니다.
- **W01·W02**
  - `CardSnapshot`을 struct로 바꾸고 원소 디코딩 정책(필수 필드, 누락, 형식)을 직접 작성합니다.
  - `cardIssued: true`이면서 `cards.items: []`인 상태는 버전 1에서 변환한 사용자의 **정상 상태**입니다. 이를 불일치로 판정하면 안 됩니다.
  - 새 영역 필드는 `decodeIfPresent`와 기본값을 권장합니다. W00이 쓴 파일에는 그 필드가 없습니다.
- **W04·W05·W07**: 위와 같은 방식으로 `JourneySnapshot`을 정의합니다. `active`의 null 처리는 유지합니다.
- **W08**: 위와 같은 방식으로 `RecordSnapshot`을 정의합니다. 파일 구조는 바꾸지 않습니다.
- **공통**: S1과 S2의 영역 보존 검증을 실제 원소가 든 상태로 다시 추가합니다.
- **W13**
  - `"version":"2"`처럼 숫자가 아닌 버전은 W00에서 `corrupt`로 분류됩니다. `StorageIssue.unsupportedVersion(Int)`에 담을 수 없고, FR-6이 오류 구분을 바꾸지 말라고 하기 때문입니다.
  - 따라서 `corrupt`에는 "미래 형식일 수 있는 파일"이 섞여 있습니다. W13이 `corrupt`를 "정리해도 되는 파일"로 다룰 때 사용자 확인 없이 지우면 안 됩니다. 필요하면 W13이 분류를 세분화합니다.
- **같은 버전 안에서 빌드를 되돌릴 때**
  - W00 빌드로 되돌리면 원소가 든 파일은 `corrupt`로 보존되므로 손실이 없습니다.
  - W01 이후 빌드끼리 되돌리면 모르는 키 무시 정책 때문에 필드나 원소 정체성이 사라질 수 있습니다. 개발 기기에서만 생기는 상황을 전제로 합니다.

### 구현 순서
1. [Must] 영역 3파일 생성: 값 없는 원소 enum과 직접 작성한 Codable (의존: 없음)
2. [Must] `AppSnapshot.swift`: 영역 필드, private 전체 생성자, `updating…` 함수, `CodingKeys`, `encode` (의존: 1)
3. [Must] `SnapshotCodec.swift`: 헤더, 버전 분기, `LegacySnapshotV1`, `migrateV1`, `encode`, `decode` (의존: 2)
4. [Must] `LocalSnapshotStore.swift`: 코덱에 위임하고 `:24-25` 삭제 (의존: 3)
5. [Must] `UITestBootstrap.swift:32, 50-51, 60-62`: 호출 형태 변경 (의존: 2)
6. [Must] `AppFoundationTests.swift`: `stage` 헬퍼, 호출 형태 4곳 변경, C1~C10, S1~S2, AC-1~AC-4 추가 (의존: 2). TDD로 진행하면 3, 4보다 먼저 써서 RED를 확인합니다.
7. [Must] 전체 회귀: `python3 scripts/check-ios.py test`로 단위와 UI 테스트를 실행합니다 (의존: 4, 5, 6)

3과 5는 서로 독립이라 병렬로 진행할 수 있습니다. 5와 6도 서로 다른 파일이라 병렬로 진행할 수 있습니다.
