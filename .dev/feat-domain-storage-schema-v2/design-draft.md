## 설계 초안: 도메인 저장 구조 확장 (버전 1 → 2) [W00]

### 설계 규모
**중형**. 저장 계약(파일 버전, 디코딩 정책)이 바뀌고 후속 작업 W01~W13이 이 구조를 씁니다. 다만 수정 범위는 저장 계층(`AppSnapshot`, `LocalSnapshotStore`)과 신규 파일 4개에 한정되고 UI 변화는 없습니다.

### 배경 및 목적
- 현재 `app-state.json`은 버전 1이고 `cardIssued`, `initialStation`, `currentStation`만 담습니다. 손상, 미지원 버전, 읽기 실패가 있으면 원본을 보존하고 쓰기를 막습니다.
- 카드(W01·W02), 여정(W04·W05·W07), 기록(W08)이 같은 파일 구조를 동시에 바꾸면 충돌합니다. 그래서 구조 변경은 W00에서 한 번만 하고, 후속 작업은 자기 영역의 내용만 채웁니다.
- 버전 1 사용자의 데이터는 100% 보존되고 화면 변화도 없어야 합니다. 알 수 없는 파일은 어떤 경우에도 덮어쓰지 않습니다.

### 요구사항 및 수용 기준
- [Must] FR-1: 저장 파일은 버전 2 형식입니다. 기존 항목의 위치와 의미는 유지하고 카드, 여정, 기록 영역 3개를 추가합니다.
- [Must] FR-2: 초기 내용은 카드 빈 목록, 진행 중 여정 없음, 완료 기록 빈 목록입니다. 상세 항목은 후속 작업이 정합니다.
- [Must] FR-3: 버전 1 파일은 버전 2 상태로 변환해 씁니다. 읽기만 했으면 파일을 바꾸지 않습니다.
- [Must] FR-4: 이후 모든 저장은 버전 2로 기록하며, 세 영역과 기존 항목을 함께 유지합니다.
- [Must] FR-5: 버전 3 이상, 0 이하, 숫자가 아닌 값은 지원하지 않습니다. 파일이 없으면 첫 실행으로 보고 초기 상태로 시작합니다.
- [Must] FR-6: 변환이나 검증에 실패하면 원본을 보존하고 새 저장을 막습니다. 오류 구분은 기존 것(손상, 미지원 버전, 내용 불일치, 읽기 실패)을 그대로 씁니다.
- [Must] FR-7: 시작 화면 분기는 기존과 같고, 새 영역은 분기에 영향을 주지 않습니다.
- [Must] BR-1: 영역 안에 항목을 추가하는 것은 버전 변경 사유가 아닙니다.
- [Must] BR-2: 알 수 없거나 손상된 원본은 어떤 경로로도 덮어쓰지 않습니다.
- [Must] BR-3: 저장에 실패하면 메모리와 기존 파일을 유지하고 atomic write를 유지합니다.
- [Must] BR-4: 버전 1 백업 파일은 만들지 않습니다.
- [Must] BR-5: 버전 2 파일에서 영역 하나가 통째로 없으면 손상입니다. 영역 안의 항목 누락 처리는 후속 작업이 정합니다.
- AC-1~AC-5는 PRD(`/Users/bonseung/Documents/ChatGPT/new/.dev/feat-domain-storage-schema-v2/prd.md:57-77`)를 그대로 따릅니다. 각 AC를 담당하는 컴포넌트는 아래 "AC와 컴포넌트 매핑"에 정리했습니다.

### 변경 범위
- **영향 모듈**: iOS 앱 타깃의 저장 계층과 단위 테스트 타깃. 웹 프로토타입은 범위 밖입니다.
- **신규 생성 파일** (Xcode 프로젝트가 `PBXFileSystemSynchronizedRootGroup` 방식이라 `project.pbxproj`를 수정하지 않아도 자동으로 포함됩니다. `project.pbxproj:22-26`)
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/CardSection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/JourneySection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/RecordSection.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/SnapshotCodec.swift` (버전 판정, 버전 1 변환, 버전 2 인코딩과 디코딩을 하는 순수 함수)
- **수정 대상 파일**
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/LocalSnapshotStore.swift`
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/UITestBootstrap.swift` (1곳, 영역 전달)
  - `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppFoundationTests.swift` (테스트 추가만 하고 기존 단언은 바꾸지 않음)
- **수정하지 않는 파일**: `AppModel.swift`, `RootView.swift`, `FocusMateApp.swift`, `Phase1FlowTests.swift`, `StorageIssue`(`LocalSnapshotStore.swift:3-6`). 오류 분류는 PRD FR-6에 따라 그대로 둡니다.

### 적용 컨벤션
- **네이밍**: 타입은 UpperCamelCase이고 저장 모델 접미사는 `…Snapshot`입니다(`StationSnapshot`). 오류는 `…Issue` enum입니다(`StorageIssue`, `SnapshotValidationIssue`). 정적 기본값 이름은 `static let empty`(`AppSnapshot.swift:18`)입니다.
- **저장 모델**: `Codable, Equatable`인 값 타입 struct와 `let` 프로퍼티를 씁니다. nil인 optional도 키를 남기도록 `encodeNil`로 명시 인코딩합니다(`AppSnapshot.swift:37-45`).
- **I/O 격리**: `LocalSnapshotStore`의 생성자에서 `readData`, `createDirectory`, `writeData` 클로저를 주입합니다(`LocalSnapshotStore.swift:14-22`). 테스트는 이 클로저에 호출 횟수 카운터와 실패를 주입합니다.
- **오류 처리 순서**: 읽기 실패는 `unreadable`(없는 파일만 nil), 헤더 디코딩 실패는 `corrupt`, 지원하지 않는 버전은 `unsupportedVersion`입니다. 그다음 본문 디코딩 실패는 `corrupt`, `validate()` 실패는 `invalidState`입니다(`:27-42`). 저장은 후보 `validate()` → 기존 파일 `load()` 실패 시 `writeBlocked(issue)` → 인코딩, 디렉터리 생성, 쓰기 순서이고, 이 단계의 실패는 모두 `writeFailed`입니다(`:44-56`).
- **인코딩**: `JSONEncoder`에 `.sortedKeys`를 써서 바이트가 결정적입니다(`:50-51`). 쓰기는 `.atomic`입니다(`:17`).
- **테스트**: XCTest를 쓰고 `assertStorageIssue`, `withTemporaryFile` 헬퍼를 씁니다(`AppFoundationTests.swift:360-385`). 실행은 `python3 scripts/check-ios.py test [file]`입니다.
- **안전 경계**: `docs/PHASE-1-FOUNDATION.md:40-42, 50-54`를 지킵니다. 시험 seed는 DEBUG에서만 쓰고 운영 파일을 덮어쓰지 않습니다. 복구는 W13 범위입니다.

### 버전 2 파일 형식 (확정안)

`.sortedKeys`로 인코딩한 결과는 다음과 같습니다(AC-1 입력을 변환한 뒤 저장한 경우).
```
{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}
```
- 기존 3개 키는 `state` 바로 아래에서 위치와 의미가 그대로입니다(FR-1).
- 각 영역은 배열이 아니라 **객체**입니다. 후속 작업이 영역 단위 필드(예: W01의 선택 카드 ID)를 버전 변경 없이 추가할 수 있게 하려는 것입니다(BR-1).
- `journey.active`는 진행 여정이 없을 때 키를 생략하지 않고 명시적으로 `null`을 씁니다. 기존 정류장 패턴과 같고, AC-2의 "영역 키가 모두 있다"를 만족합니다.

### 디코딩 확장 정책 (BR-1, BR-5)

| 대상 | 정책 | 결과 |
|---|---|---|
| `state.cards`, `state.journey`, `state.records` 키 누락 | 필수 | `corrupt` (BR-5) |
| 영역 값이 null이거나 객체가 아님 (예: `"cards":[]`) | 형식 오류 | `corrupt` |
| W00 골격 키 `cards.items`, `records.items`, `journey.active` 누락 | 필수(W00이 항상 기록하는 키) | `corrupt` |
| `items` 원소가 JSON 객체가 아님 | 형식 오류 | `corrupt` |
| 영역 안이나 `items` 원소 안의 **모르는 키** | **무시**(tolerant reader) | 정상 읽기 |
| `state` 최상위의 모르는 키 | 무시(현행 버전 1 동작 유지) | 정상 읽기 |

- **모르는 키를 무시하는 근거**: `JSONDecoder`의 기본 동작이고 현재 버전 1 디코딩도 이렇게 동작합니다. 같은 버전 안에서 필드가 늘어도 이전 빌드가 손상으로 잘못 판단하지 않습니다.
- **알려진 대가**: W01 이후 빌드가 쓴 파일을 W00 빌드가 읽고 다시 저장하면 모르는 필드가 사라집니다. 이는 개발 중 빌드를 되돌렸을 때만 생기며, PRD에서 "이전 버전으로 되돌리기는 별도 대응 없음"으로 범위 밖입니다.
- **후속 작업 지침**(PRD상 결정 권한은 후속 작업에 있음): 새로 추가하는 필드는 `decodeIfPresent`와 기본값으로 **누락을 허용**하는 것을 권장합니다. W00이 쓴 버전 2 파일에는 그 필드가 없기 때문입니다. 필수로 만들면 기존 버전 2 파일이 `corrupt`가 되어 진행이 막힙니다.

### 상세 설계

1. **`ios/FocusMate/CardSection.swift`, `JourneySection.swift`, `RecordSection.swift` (신규)**: 영역 타입
   - 현재: 없음.
   - 변경: 영역마다 파일을 따로 둡니다. W01, W02, W08이 동시에 작업해도 **같은 파일을 고치지 않게** 하려는 분리입니다. 원소 타입은 필드가 없는 자리표시자로 두고, 실제 필드는 후속 작업이 채웁니다. `init(from:)`는 명시적으로 작성해 `decoder.container(keyedBy:)`를 호출합니다. 이렇게 하면 "객체가 아니면 형식 오류"가 합성 동작에 기대지 않고 보장됩니다. `JourneySection`은 `active` 키가 있는지 `contains`로 확인하고, nil일 때 `encodeNil`로 씁니다.
   - 시그니처:
     - `struct CardSnapshot: Codable, Equatable { }`
     - `struct CardSection: Codable, Equatable { let items: [CardSnapshot]; static let empty = CardSection(items: []) }`
     - `struct JourneySnapshot: Codable, Equatable { }`
     - `struct JourneySection: Codable, Equatable { let active: JourneySnapshot?; static let empty = JourneySection(active: nil) }`
     - `struct RecordSnapshot: Codable, Equatable { }`
     - `struct RecordSection: Codable, Equatable { let items: [RecordSnapshot]; static let empty = RecordSection(items: []) }`
   - 고려사항: Swift 6에서 내부(internal) 값 타입은 Sendable로 추론되므로 `static let empty`에 문제가 없습니다. W00에서는 영역 내용을 검증하지 않습니다(분기에 영향 없음, FR-7).

2. **`ios/FocusMate/AppSnapshot.swift`**: 상태에 영역 3개 추가
   - 현재: `cardIssued`, `initialStation`, `currentStation` 3개 필드입니다(`:14-18`). 인코딩은 직접 작성했고(`:37-45`) 디코딩은 합성입니다.
   - 변경: `let cards: CardSection`, `let journey: JourneySection`, `let records: RecordSection`을 추가합니다. 기본값이 있는 명시적 생성자를 둬서 기존 호출부를 바꾸지 않아도 컴파일되게 합니다(테스트 `AppFoundationTests.swift:10-19, 44-52, 145`, `UITestBootstrap.swift:32, 50, 60`). `CodingKeys`에 `cards`, `journey`, `records`를 추가하고 `encode(to:)`에서 세 영역을 항상 인코딩합니다. 영역 필드는 비옵셔널이므로 합성 디코딩에서 키가 없으면 `keyNotFound`가 나고, 이는 `corrupt`로 매핑됩니다. `.empty`는 영역이 모두 `.empty`입니다.
   - 시그니처: `init(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?, cards: CardSection = .empty, journey: JourneySection = .empty, records: RecordSection = .empty)`
   - `validate()`(`:20-29`)와 `launchRoute()`(`:31-35`)는 **바꾸지 않습니다**. 오류 순서와 분기도 그대로입니다(FR-7, AC-5).

3. **`ios/FocusMate/SnapshotCodec.swift` (신규)**: 버전 판정, 변환, 직렬화를 하는 순수 함수. **마이그레이션 함수는 여기에 둡니다.**
   - 현재: 같은 로직이 `LocalSnapshotStore.swift:24-25, 32-41, 50-52`에 I/O와 섞여 있습니다.
   - 변경: 상태가 없는 `enum SnapshotCodec` 네임스페이스로 분리합니다. I/O 없이 `Data` ↔ `AppSnapshot`만 다루므로 단위 테스트에서 바이트를 직접 넣어 검증할 수 있습니다.
     - `VersionHeader`(`version: Int`)를 디코딩하고, 실패하면 `corrupt`입니다. 빈 파일, `version` 없음, 숫자가 아닌 값이 여기에 해당합니다.
     - `switch version`: `1`이면 `LegacySnapshotV1`로 디코딩한 뒤 `migrateV1`을 거칩니다. `2`이면 `Envelope`로 디코딩합니다. 그 밖의 값(0 이하, 3 이상, 999)은 `unsupportedVersion(version)`입니다.
     - 본문 디코딩 실패는 `corrupt`입니다. 그다음 변환된 `AppSnapshot`에 `validate()`를 실행하고, 실패하면 `invalidState(issue)`입니다. 순서는 헤더 → 버전 → 구조 → 내용으로 현행과 같습니다. 버전 2에서 영역 누락과 내용 불일치가 함께 있으면 `corrupt`가 먼저 나옵니다.
     - `encode`는 `.sortedKeys`로 `Envelope(version: currentVersion, state:)`를 만듭니다.
   - 시그니처:
     - `enum SnapshotCodec`
     - `static let currentVersion = 2`
     - `static func decode(_ data: Data) throws -> AppSnapshot` (`StorageIssue`의 `.corrupt`, `.unsupportedVersion`, `.invalidState`만 던짐)
     - `static func encode(_ snapshot: AppSnapshot) throws -> Data`
     - `static func migrateV1(_ legacy: LegacySnapshotV1) -> AppSnapshot` (기존 3개 필드를 복사하고 영역은 `.empty`. 실패하지 않는 순수 함수)
     - `struct LegacySnapshotV1: Decodable { let cardIssued: Bool; let initialStation: StationSnapshot?; let currentStation: StationSnapshot? }`. 테스트에서 `migrateV1`을 직접 검증할 수 있도록 internal로 둡니다.
     - `private struct VersionHeader: Decodable`, `private struct EnvelopeV1: Decodable { version; state: LegacySnapshotV1 }`, `private struct Envelope: Codable { version; state: AppSnapshot }`
   - 고려사항: 변환은 **메모리에서만** 일어납니다. 쓰기 백(write-back)과 백업 파일은 만들지 않습니다(FR-3, BR-4). `LegacySnapshotV1`은 버전 1 계약을 고정해 둔 것이므로 이후 `AppSnapshot`이 바뀌어도 수정하지 않습니다.

4. **`ios/FocusMate/LocalSnapshotStore.swift`**: 코덱에 위임
   - 현재: `version == 1`만 허용하고(`:35`) 버전 1로 인코딩합니다(`:52`).
   - 변경: `load()`의 읽기와 파일 없음 처리(`:28-31`)는 그대로 두고, 이후 처리를 `SnapshotCodec.decode(data)` 한 번 호출로 바꿉니다. `save()`는 `validate` → `load()`로 차단 확인(`:45-48`) 순서를 유지하고, 인코딩만 `SnapshotCodec.encode(snapshot)`으로 바꿉니다. 이 호출은 기존 `do { … } catch { writeFailed }` 블록 안에 둡니다. `VersionHeader`와 `Envelope` 선언(`:24-25`)은 코덱으로 옮깁니다.
   - 시그니처: 공개 API(`init`, `load() throws -> AppSnapshot?`, `save(_:) throws`)는 바뀌지 않습니다.
   - 고려사항: 버전 1 파일에서 `save()`를 호출하면 내부 `load()`가 변환에 성공하므로 차단되지 않고 버전 2로 덮어씁니다. 이것이 의도한 업그레이드 경로입니다(정상 흐름 A). 쓰기 실패 시에는 atomic write라서 기존 파일이 그대로 남습니다(BR-3).

5. **`ios/FocusMate/UITestBootstrap.swift:50-51`**: 저장 실패 시나리오에서 영역 보존
   - 현재: `AppSnapshot(cardIssued:initialStation:currentStation:)`으로 새 후보를 만듭니다. 영역 기본값 때문에 영역이 비게 됩니다.
   - 변경: `cards: original.cards, journey: original.journey, records: original.records`를 함께 넘깁니다. W00에서는 영역이 늘 비어 있어 결과가 같지만, 후속 작업에서 seed에 카드가 생겨도 시나리오가 데이터를 지우지 않게 합니다.
   - seed `corrupt`, `unsupported`(`:34-37`)는 바꾸지 않습니다. 버전 999는 계속 미지원입니다(AC-5).

6. **`AppModel.swift`**: 변경 없음
   - `loadIfNeeded()`(`:27-40`)는 `store.load() ?? .empty`이므로 파일이 없으면 영역이 빈 초기 상태입니다(FR-5). 읽은 뒤 쓰지 않습니다(FR-3). `save()`(`:43-59`)는 실패 시 이전 `snapshot`과 `launchState`를 유지합니다(BR-3). 모두 현행 그대로 충족합니다.

### 기존 테스트 영향

**결론: 기존 단언을 바꿀 필요는 0건입니다.** 출력 바이트가 버전 1이라고 확인하는 기존 테스트가 없습니다.

| 위치 | 현재 기대 | 버전 2 이후 | 조치 |
|---|---|---|---|
| `AppFoundationTests.swift:20-22` `readyEnvelope` | 버전 1 fixture | 변환 입력으로 그대로 유효 | 유지. 이름 변경은 선택 사항이며 하지 않는 것을 권장합니다. |
| `:93-108`, `:110-139` (corrupt, 999) | `corrupt`, `unsupportedVersion(999)`, 바이트 보존 | 동일 | 유지 |
| `:168-178` 첫 저장 후 복원 | 다시 읽은 값이 `readySnapshot`과 같음 | 버전 2로 기록하고 왕복해도 같음(영역 기본값) | 유지 |
| `:239-263` 버전 1 읽기 후 탐색 | `snapshot == readySnapshot` | 변환 후 영역이 `.empty`라 같음 | 유지 |
| `:266-283`, `:286-313` 저장 실패와 재시도 | 쓰기 횟수, 상태, 경로만 확인 | 버전 1 읽기 후 버전 2 쓰기. 바이트는 확인하지 않음 | 유지 |
| `:212-236` | `snapshot == .empty` | `.empty`에 영역 포함 | 유지 |
| `Phase1FlowTests.swift:48-61, 128-143` | 바이트를 seed 시점과 **상대 비교** | `ready` seed가 버전 2로 기록됨 | 유지 |
| `Phase1FlowTests.swift:94-120` | `{broken`, `version 999` 바이트 그대로 | 동일 | 유지 |

**추가할 테스트** (`AppFoundationTests.swift`에 추가해 기존 헬퍼를 재사용합니다. 세부 테스트 설계는 test-architect 소관입니다.)
- AC-1: 실제 임시 파일에 버전 1 fixture를 둡니다. `load()` 결과의 필드와 영역 개수(0, nil, 0), `launchRoute() == .main`, 읽기 전후 파일 바이트가 같은지 확인합니다.
- AC-2: (a) 파일 없음과 (b) 버전 1 파일에서 각각 `save()`를 실행합니다. 이후 JSON 최상위 `version == 2`, `state`의 6개 키, 다시 읽은 값의 동일성, 두 번째 저장 바이트의 동일성을 확인합니다.
- AC-3: 버전 3, 999, 0, 빈 파일, `version` 없음, 버전 2에서 `records` 누락의 6가지입니다. `load()`의 오류, `save()`의 `writeBlocked(…)`, 디렉터리 생성과 쓰기 0회, 바이트 보존을 확인합니다.
- AC-4: (a) 버전 1 `cardIssued:false`에 정류장이 있으면 `invalidState(.inconsistentStage)`와 `writeBlocked(.invalidState(.inconsistentStage))`가 나야 합니다. (b) 버전 2 파일에 `writeData` 실패를 주입하면 `writeFailed`가 나고 바이트가 보존되어야 합니다.
- 코덱 단위 테스트(정책 고정용): 영역 형식 오류(`"cards":[]`), `items` 원소가 숫자, 영역 안의 모르는 키를 무시하고 정상 읽기, `migrateV1`의 필드 보존.

### AC와 컴포넌트 매핑

| AC | 담당 컴포넌트 |
|---|---|
| AC-1 | `SnapshotCodec.decode`의 버전 1 분기와 `migrateV1`, 영역 `.empty`, `AppSnapshot.launchRoute`, `LocalSnapshotStore.load`(쓰기 없음) |
| AC-2 | `SnapshotCodec.encode`(`currentVersion = 2`, `.sortedKeys`), `AppSnapshot.encode(to:)`, 영역 타입의 명시적 인코딩 |
| AC-3 | `SnapshotCodec.decode`의 헤더와 버전 분기, 영역 필수 디코딩, `LocalSnapshotStore.save`의 차단 단계 |
| AC-4 | `AppSnapshot.validate`(변환 후 적용), `LocalSnapshotStore.save`의 `writeFailed` 경로와 atomic write, `AppModel.save`의 롤백 |
| AC-5 | `AppSnapshot.launchRoute`(변경 없음), `UITestBootstrap` seed(변경 없음), 기존 테스트 전체 |

### 의존성 및 영향도
- **새 외부 의존성**: 없습니다(Foundation `JSONEncoder`, `JSONDecoder`만 사용).
- **영향**: `AppSnapshot`의 저장 형식이 바뀝니다. 생성자에 기본값을 두므로 기존 호출부는 컴파일 호환됩니다. `Equatable` 비교에 영역이 포함됩니다.
- **하위 호환**: 버전 1을 읽을 수 있습니다(변환). 버전 2 파일을 버전 1 앱에서 열면 미지원으로 보존되며, PRD상 대응하지 않습니다.
- **문서**: `docs/PHASE-1-FOUNDATION.md:10`은 Phase 1 당시 기록이므로 다시 쓰지 않습니다(`docs/README.md` 정책). 현재 상태 문서 갱신은 구현이 끝난 뒤 문서화 단계에서 판단합니다.

### 위험
1. **영역 초기화 위험**: 생성자의 영역 기본값 때문에 `AppSnapshot(cardIssued:…)`로 후보를 새로 만드는 호출부는 영역을 비웁니다. W00에서는 영역이 늘 비어 있어 영향이 없습니다. W01 이후에는 저장 후보를 만들 때 기존 영역을 넘기는지 리뷰에서 확인해야 합니다. 이번에 `UITestBootstrap.swift:50`은 미리 수정합니다.
2. **같은 버전 안에서 빌드를 되돌릴 때의 필드 손실**: 모르는 키 무시 정책의 대가입니다. 개발 중 빌드를 되돌리는 경우에만 생깁니다.
3. **숫자 경계 값**: `"version":"2"`처럼 숫자가 아닌 값은 `unsupportedVersion(Int)`에 담을 수 없어서 `corrupt`로 분류합니다(가정). 이 경우에도 읽지 않고 보존하는 결과는 FR-5를 만족합니다. `2.0`처럼 정수로 표현 가능한 실수를 `JSONDecoder`가 `Int`로 받는지는 Foundation 구현에 따릅니다. AC 범위 밖이라 별도로 처리하지 않습니다.
4. **atomic write 범위**: 실제 파일 교체 중 실패나 전원 장애는 Phase 1과 마찬가지로 검증하지 않습니다(`PHASE-1-FOUNDATION.md:11, 54`).

### 구현 순서
1. [Must] `CardSection.swift`, `JourneySection.swift`, `RecordSection.swift` 생성 (의존: 없음)
2. [Must] `AppSnapshot.swift`에 영역 필드, 생성자, `CodingKeys`, `encode` 추가 (의존: 1)
3. [Must] `SnapshotCodec.swift` 생성: 헤더, 버전 분기, `LegacySnapshotV1`, `migrateV1`, `encode`, `decode` (의존: 2)
4. [Must] `LocalSnapshotStore.swift`가 코덱에 위임하도록 변경하고 `Envelope`, `VersionHeader` 제거 (의존: 3)
5. [Must] `UITestBootstrap.swift:50` 영역 전달 (의존: 2)
6. [Must] `AppFoundationTests.swift`에 AC-1~AC-4와 코덱 정책 테스트 추가 (의존: 4). TDD로 진행하면 3, 4보다 먼저 작성해 RED를 확인합니다.
7. [Must] 전체 회귀 실행: `python3 scripts/check-ios.py test`, 단위와 UI 테스트 (의존: 4, 5, 6)

4와 5는 병렬로 진행할 수 있습니다.

### 탐색 추가 항목
- `ios/FocusMate/LocalSnapshotStore.swift:3-6` → `StorageIssue` 분류. 변경하지 않습니다.
- `ios/FocusMate/LocalSnapshotStore.swift:27-56` → 읽기, 판정, 쓰기 차단 순서. 코덱 위임 지점입니다.
- `ios/FocusMate/AppSnapshot.swift:14-45` → 상태 모델, 검증 순서, `encodeNil` 패턴.
- `ios/FocusMate/AppModel.swift:27-59` → 읽은 뒤 쓰지 않음, 저장 실패 시 롤백. 변경하지 않습니다.
- `ios/FocusMate/UITestBootstrap.swift:30-51` → seed와 저장 실패 시나리오의 후보 생성 지점.
- `ios/FocusMate/RootView.swift:41, 62` → 바이트 진단 노출과 `currentStation` 사용처. 영향 없습니다.
- `ios/FocusMateTests/AppFoundationTests.swift:20-24, 110-139, 239-313, 360-385` → fixture, 차단 테스트, 모델 테스트, 헬퍼.
- `ios/FocusMateUITests/Phase1FlowTests.swift:48-61, 94-143` → 바이트를 상대 비교하는 지점. 영향 없습니다.
- `ios/FocusMate.xcodeproj/project.pbxproj:22-26` → 동기화 그룹이므로 신규 파일 등록이 필요 없습니다.
- `.dev/plan.md:5-18, 37, 45` → W00 선행 근거와 W08·W13 구조 불변 조건.
- `docs/PHASE-1-FOUNDATION.md:10-11, 40-54` → 버전 1 계약과 안전, 복구 경계.
