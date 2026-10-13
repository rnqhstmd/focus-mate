# 설계 초안 v1: 카드 발급과 공통 카드 뷰 (W01, FR-3) — architect

설계 규모: **대형**. 근거는 다음과 같다.
- 새 화면(발급 상태 머신)이 생긴다.
- 저장 원소 계약(CardSnapshot)이 바뀐다.
- 앱 시작 단계(보충 저장)가 생긴다.
- 화면 전환 구조(발급 완료 화면 유지)가 바뀐다.
- W04·W10·W11이 공통 카드 뷰와 이름·번호 출처를 재사용한다.

PRD: `prd.md` (AC-1~21, BR-1~8).

## 변경 범위

영향 모듈: `ios/FocusMate`, `ios/FocusMateTests`, `ios/FocusMateUITests`. 웹은 `npm test` 회귀만 확인한다.

Xcode 등록: 수정할 필요가 없다. `project.pbxproj:22-26`에서 세 타깃 모두 `PBXFileSystemSynchronizedRootGroup`이라 폴더에 넣은 파일과 xcassets가 자동으로 포함된다.
단, `scripts/check-ios.py:35-39`가 `-only-testing:<타깃>/<파일 stem>`을 쓰므로 **테스트 파일 이름과 XCTestCase 클래스 이름이 같아야 한다.**

### 신규 (앱)
| 경로 | 책임 |
|---|---|
| ios/FocusMate/CardSnapshotFactory.swift | ID 난수·시계 주입, CardSnapshot 생성 (BR-1) |
| ios/FocusMate/PassIdentity.swift | 이름·번호 표기 단일 출처 (FR-3-6) |
| ios/FocusMate/PassFace.swift | 공통 카드 뷰(pass-face), 비율 상수 (FR-3-5) |
| ios/FocusMate/IssuanceFeedback.swift | IssuanceHaptics·AccessibilityAnnouncing 프로토콜 + 시스템 구현 |
| ios/FocusMate/CardIssuanceController.swift | 발급 상태 머신, CardIssuing 포트, 연출 시간 계산 |
| ios/FocusMate/CardIssuanceView.swift | 발급 화면, 문구 상수 CardIssuanceCopy |
| ios/FocusMate/Assets.xcassets/PassDots.imageset | 서울 점묘(designs/final/assets/bus/ticket-dots.svg, viewBox 360×230) 복사, 벡터 보존 |

### 신규 (테스트)
| 경로 | 대상 AC |
|---|---|
| ios/FocusMateTests/CardStorageTests.swift | AC-13, AC-14(단위), BR-5 |
| ios/FocusMateTests/PassIdentityTests.swift | AC-15, BR-1(팩토리) |
| ios/FocusMateTests/CardIssuanceModelTests.swift | AC-8, AC-3/4/6 모델 로직 |
| ios/FocusMateTests/CardSupplementTests.swift | AC-9, AC-11, AC-12 |
| ios/FocusMateTests/CardIssuanceControllerTests.swift | AC-5(잠금), AC-17, AC-18, AC-19(안내·포커스 로직) |
| ios/FocusMateTests/CardTestSupport.swift | 가짜 햅틱·안내 기록기, SuspendingSleep, 메모리 저장소 헬퍼 (테스트 클래스 없음) |
| ios/FocusMateUITests/CardIssuanceFlowTests.swift | AC-1~7, AC-16, AC-19, AC-20 |
| ios/FocusMateUITests/CardStorageFlowTests.swift | AC-10, AC-14(UI) |
| ios/FocusMateUITests/UITestLaunchSupport.swift | 실행·진단 조회 헬퍼 |

### 수정
| 경로 | 변경 |
|---|---|
| CardSection.swift | CardSnapshot 원소 계약 정의 |
| AppSnapshot.swift | 검증 오류 종류 추가, validate에 BR-5 추가, 카드 편의 메서드 |
| AppModel.swift | persist 분리, issueCard·finishCardIssuance·start·supplementCardIfNeeded, presentedRoute |
| RootView.swift | presentedRoute 분기, CardIssuanceView 연결, DEBUG 진단 3개 추가 |
| FocusMateApp.swift | 컨트롤러·피드백 조립, model.start() |
| UITestBootstrap.swift | 시드 확장, 저장 모드, 발급 대기 시간·햅틱 지원 주입, 기록기 |

## 적용 컨벤션 (기존 코드에서 확인)

- **네이밍**:
  - 저장 원소는 `…Snapshot`, 섹션은 `…Section`이다.
  - 식별자는 `screen.<route>`, `<영역>.<이름>`, 진단용은 `test.<이름>`이다.
  - 테스트 메서드는 `testACn_한국어설명`이고, 메서드 위에 `// 깨짐 명명:` 주석을 단다.
- **불변 상태**: AppSnapshot의 전체 생성자는 private이다. 값은 `updating…` 메서드로만 바꾼다.
- **Codable**: 섹션마다 직접 `init(from:)`/`encode(to:)`를 쓴다. 키가 없으면 거부하고, 모르는 키는 무시한다. 출력은 `.sortedKeys`로 정렬한다.
- **오류 분류**: 디코딩 실패는 `.corrupt`, validate 실패는 `.invalidState(issue)`이고, 각각 화면 문구로 이어진다.
- **의존성 주입**: 생성자 인자에 기본값을 둔 클로저로 주입한다. 상태를 기록해야 하는 장치(햅틱·안내)만 프로토콜과 가짜 구현을 둔다.
- **모델**: `@MainActor @Observable final class`로 만들고 상태는 `private(set)`이다. 저장 결과는 `@discardableResult -> Bool`로 돌려준다.
- **빌드 환경**: iOS 17, Swift 5, `SWIFT_STRICT_CONCURRENCY = minimal`.

## 상세 설계

### 1. CardSection.swift — CardSnapshot 계약 (FR-3-2, BR-1, AC-13)

선언: `struct CardSnapshot: Codable, Equatable { let id: String; let issuedAt: Date }`.

디코딩 규칙:
- 두 키가 모두 있어야 한다. 누락이나 타입 오류는 `.corrupt`다.
- `issuedAt`은 `Date.ISO8601FormatStyle`로 파싱하고, 실패하면 `DecodingError.dataCorrupted`를 던진다. AC-14(c) "어제"가 `.corrupt`가 되는 경로다.
- **id 형식은 디코딩에서 검사하지 않는다.** validate에서 검사해야 AC-14(a)(b)가 `.invalidState`로 분류된다.

인코딩: `{"id":…,"issuedAt":"yyyy-MM-ddTHH:mm:ssZ"}`. 날짜를 직접 문자열로 만들어 encoder 설정과 상관없이 같은 바이트가 나오게 한다.

ID 검사: `static func isValidID(_:) -> Bool`. 길이 11, `FM-` 접두, ASCII 숫자 8개만 허용한다.

기존 테스트 영향: `SnapshotCodecTests:130-141`([1], [{}])과 `AppSnapshotSectionsTests:150-152`는 계속 `.corrupt`가 나므로 수정할 필요가 없다.

### 2. CardSnapshotFactory.swift — ID·시각 생성

선언: `struct CardSnapshotFactory { init(randomNumber: @escaping () -> UInt32 = { .random(in: 0..<100_000_000) }, now: @escaping () -> Date = Date.init); func make() -> CardSnapshot }`

- ID는 `FM-` 뒤에 0으로 채운 8자리 숫자다. 범위 밖 값은 `% 100_000_000`으로 접는다.
- `issuedAt`은 초 단위로 내린다. 그래야 AC-13의 저장 왕복과 바이트 동일성이 성립한다.
- 발급과 보충이 이 팩토리를 함께 쓴다.

### 3. AppSnapshot.swift — BR-5 검증

`SnapshotValidationIssue`에 다음을 추가한다: `multipleCards(Int)`, `cardWithoutIssuance`, `invalidCardID`.

검증 순서: 단계 → 정류장(기존) → 카드 수 > 1 → 카드가 있는데 미발급 → `isValidID`.
- `cardIssued == true`이고 카드가 없는 상태는 **유효**하다. 보충 대상이기 때문이다.

편의 멤버:
- `var currentCard: CardSnapshot?`
- `var needsCardSupplement: Bool` — `cardIssued && cards.items.isEmpty`
- `func issuingCard(_:) -> AppSnapshot` — cardIssued를 true로 바꾸고 카드 1장을 넣는다. 나머지 값은 유지한다.

AC-14 매핑 (`RootView.message(for:)`는 그대로 둔다):

| 시드 | 분류 | 표시 문구 |
|---|---|---|
| (a) id 짧음, (b) 접두 다름 | `.invalidState(.invalidCardID)` | "저장된 이용 상태를 확인할 수 없어요." |
| (d) 카드 2장 | `.invalidState(.multipleCards(2))` | (a)와 같음 |
| (e) 미발급인데 카드 1장, 정류장 null | `.invalidState(.cardWithoutIssuance)` | (a)와 같음 |
| (c) issuedAt "어제" | `.corrupt` | "저장된 데이터 형식을 읽을 수 없어요." |
| (f) 알 수 없는 기록 항목 | `.corrupt` | (c)와 같음 |

검증 위치가 한 곳이라 읽기(`SnapshotCodec.decode`), 저장 후보 검사(`LocalSnapshotStore.save`), `AppModel.save` 세 경로에 같은 규칙이 적용된다.
(e) 시드에 정류장이 있으면 `inconsistentStage`가 먼저 걸린다. 그래서 단위 테스트의 (e) 시드는 정류장을 null로 둔다.

### 4. PassIdentity.swift — 이름·번호 단일 출처

선언: `struct PassIdentity: Equatable { static let displayName = "집중동행카드"; let name; let numberText; init(card:); static func current(in: AppSnapshot?) -> PassIdentity? }`

- 번호 표기는 `"FM · " + 숫자[0..<4] + " " + 숫자[4..<8]` 형식이다.
- 카드가 없으면 nil을 돌려준다.
- 이 번호 표기를 쓰는 화면은 현재 없다.

### 5. PassFace.swift — 공통 카드 뷰

비율: ISO/IEC 7810 ID-1 **85.6 : 53.98 (≈1.586)**. 웹의 238×150 카드, 236×149 발급 카드와 같다. 웹 태그 영역 238×160은 위아래 6px 여백을 포함한 크기다.

크기:
- 기준 폭은 238pt다. `.aspectRatio(ratio, .fit)`로 배치 영역의 폭을 채운다.
- 내부 요소는 `폭 / 238` 배율로 조정한다(GeometryReader).
- 발급 화면에서는 `maxWidth: 320`이다. W04는 프레임만 넘겨 준다.

외형 (웹 animation-preview.html:283-311, 544 기준):

| 요소 | 값 |
|---|---|
| 배경 | #121416 |
| 테두리 | #51565a |
| 모서리 반경 | 폭 × 16/238 |
| 서울 점묘 | 오른쪽 정렬, 불투명도 0.85 |
| IC 칩 | 왼쪽 7.5%, 위 43%, 폭 12%, #c5b998 |
| 비접촉 표시 | SF Symbol `wave.3.right` |
| 텍스트 | "Focus Mate", displayName |
| 카드 번호 | 표시하지 않음 |

접근성:
- `.accessibilityElement(children: .ignore)` + `.accessibilityLabel(displayName)` + `.isImage`로 묶는다. AC-19의 "장식 요소 0개"를 만족한다.
- `card.face` 식별자는 호출하는 쪽이 붙인다. W04 화면에는 카드가 여러 장 나올 수 있기 때문이다.

인자: `init()`는 인자가 없다. 외형 입력은 W10에서 기본값 인자로 추가하므로 호출부를 고칠 필요가 없다.

카드 위 글자는 Dynamic Type이 아니라 카드 크기를 따른다 (질문 Q4).

### 6. AppModel.swift — 발급·보충·완료 화면 유지

현재는 save가 성공하면 launchState가 곧바로 `.initialStationEntry`가 되어 화면이 즉시 넘어간다.

1. **`private func persist(_:) -> StorageIssue?`**
   - 기존 save 본문을 옮긴 것이다.
   - save는 persist를 부른 뒤 saveFailure를 설정한다. 동작은 같고 `AppFoundationTests:259-306`이 그대로 통과한다.
2. **`issueCard() -> Bool`**
   - 다음 세 조건을 모두 만족할 때만 진행하고, 아니면 아무것도 쓰지 않고 false를 돌려준다(BR-2·3): `.ready(.cardEntry)`, snapshot 있음, `!cardIssued`.
   - `persist(snapshot.issuingCard(factory.make()))`를 호출한다.
   - 실패하면 **saveFailure를 설정하지 않는다**(AC-7). snapshot과 launchState도 그대로 둔다(BR-6).
   - 성공하면 `isHoldingIssuedCard = true`로 바꾸고 true를 돌려준다.
3. **완료 화면 유지**
   - `launchRoute`는 순수 함수로 그대로 둔다.
   - `presentedRoute`를 새로 둔다. `isHoldingIssuedCard`이면 `.cardEntry`, 아니면 launchState를 따른다.
   - `finishCardIssuance()`가 이 플래그를 내린다(AC-4).
   - 플래그는 메모리에만 있으므로 재실행하면 `.initialStationEntry`로 시작한다(AC-6, A3).
4. **`start()` = `loadIfNeeded()` + `supplementCardIfNeeded()`**
   - `loadIfNeeded`와 `LocalSnapshotStore.load`는 바꾸지 않는다. 그래서 "읽기는 쓰지 않는다"(`StorageV2Tests:41-56`)와 `AppFoundationTests:232-256`(`writeCalls == 0`), `:279-306`(`== 2`)이 유지된다.
   - `supplementCardIfNeeded`: `.ready`이고 `needsCardSupplement`이면 `snapshot.updating(cards: [factory.make()])`를 `store.save`로 **직접** 저장한다. 경로·path는 다시 계산하지 않는다.
     - 성공하면 snapshot을 교체한다.
     - 실패하면 snapshot을 그대로 두고 `supplementFailure`에 기록한다. saveFailure는 건드리지 않는다(Q2).
   - 햅틱, 안내, 화면 변화는 없다.
   - 멱등이다. 같은 인스턴스는 `hasLoaded`로 막히고, 새 인스턴스는 이미 카드가 있어 대상이 아니다.

시그니처:
- `init(store:cardFactory: = .init())`
- `start()`, `supplementCardIfNeeded()`, `@discardableResult issueCard() -> Bool`, `finishCardIssuance()`
- `var presentedRoute: LaunchRoute?` (`.ready`가 아니면 nil)
- `private(set) var supplementFailure: StorageIssue?`
- `extension AppModel: CardIssuing {}`

open/goBack은 바꾸지 않는다.

### 7. IssuanceFeedback.swift — 햅틱·안내 포트

프로토콜:
- `@MainActor protocol IssuanceHaptics: AnyObject { var isSupported: Bool { get }; func playIssued() }`
- `@MainActor protocol AccessibilityAnnouncing: AnyObject { func announce(_:) }`

시스템 구현:
- `SystemIssuanceHaptics`
  - 지원 판단은 `CHHapticEngine.capabilitiesForHardware().supportsHaptics`로 한다.
  - 재생은 `UINotificationFeedbackGenerator().notificationOccurred(.success)` 1회다.
- `SystemAccessibilityAnnouncer`: `UIAccessibility.post(.announcement, …)`를 호출한다.

### 8. CardIssuanceController.swift — 1회 발급·연타 잠금 상태 머신

```
ready ──issue──▶ issuing ──issueCard()=false──▶ failed ──issue──▶ issuing …
                   └─issueCard()=true─▶ (holdDuration 대기, 동작 줄이기면 생략) ─▶ issued ──proceed──▶ (모델이 화면 전환)
```

`issue(reduceMotion:) async -> Bool` 동작 순서:
1. phase가 ready나 failed가 아니면 즉시 false를 돌려준다. 이 검사는 첫 suspension보다 먼저, MainActor에서 실행된다. 그래서 연타해도 한 번만 통과한다(AC-5).
2. `.issuing`으로 바꾸고 "카드를 발급하고 있어요."를 안내한다.
3. `issuer.issueCard()`를 호출한다. 동기 저장이다.
   - false면 `.failed`로 바꾸고 실패 안내를 하고 false를 돌려준다. 햅틱은 0회다.
4. holdDuration이 0보다 크면 `await sleep(holdDuration)`.
5. `.issued`로 바꾼다. 지원 기기면 `playIssued()`를 1회 호출한다(동작 줄이기와 무관). 완료를 안내하고 `focusTarget = .continueButton`으로 둔다.

연출 시간:
- `static func holdDuration(reduceMotion:standard:)`: 동작 줄이기면 `.zero`, 아니면 standard다.
- `CardIssuanceTiming.standard = .milliseconds(900)`.
- AC-18은 가짜 sleep이 받은 Duration 목록으로 검증한다. (a)는 `[0 < d ≤ 0.9s]`, (b)는 호출 없음.

`proceed()`: `.issued`일 때만 `issuer.finishCardIssuance()`를 호출한다.

선언:
- `@MainActor protocol CardIssuing: AnyObject { func issueCard() -> Bool; func finishCardIssuance() }`
- `@MainActor @Observable final class CardIssuanceController`
  - `enum Phase { ready, issuing, failed, issued }`
  - `enum FocusTarget { continueButton }`
  - `private(set) phase`, `focusTarget`
  - `init(issuer:haptics:announcer:standardDuration: = .standard, sleep: = { try? await Task.sleep(for: $0) })`
  - `issue(reduceMotion:)`, `proceed()`, `var holdDuration`

동작 줄이기에서는 두 안내가 연달아 나간다. 컨트롤러는 앱 수명 동안 하나만 둔다.

### 9. CardIssuanceView.swift — 발급 화면

구성:
- 위쪽은 ScrollView다. 제목, 설명, 카드 무대(슬롯과 카드 또는 빈자리), 힌트, 오류 순서다.
- 버튼은 `.safeAreaInset(edge: .bottom)`에 고정한다. 최소 높이 44pt이고 줄바꿈을 허용한다. XXXL에서도 스크롤 없이 누를 수 있다(AC-20).
- 컨테이너에 `.accessibilityElement(children: .contain).accessibilityIdentifier("screen.cardEntry")`를 붙인다.

| phase | `card.title` (accessibilityValue = 제목) | `card.face` | 버튼 | 기타 |
|---|---|---|---|---|
| ready | "집중동행카드를 발급받아볼까요?" | 없음 | `card.issueButton` "집중동행카드 발급받기" 활성 | |
| issuing | 발급 전 문구 유지 | 슬롯에서 나오는 카드 | `card.issueButton` "카드를 발급하고 있어요" `.disabled` | |
| failed | 발급 전 문구 | 없음 | `card.issueButton` "다시 발급받기" 활성 | `card.issueError` "카드를 발급하지 못했어요. 다시 시도해 주세요." |
| issued | "카드가 발급됐어요. 이제, 어디에서 출발할까요?" | 있음 | `card.continueButton` "출발지 선택하기" | issueButton 없음 |

- 설명과 힌트는 PRD 디자인 스펙을 따른다. 발급 중 전용 문구는 만들지 않는다.
- 동작 줄이기: `@Environment(\.accessibilityReduceMotion)` 값을 `Task { await controller.issue(reduceMotion:) }`에 넘긴다. 로직 쪽은 Environment에 의존하지 않는다.
- 연출: 카드가 위에서 내려온다. offset −42→0, 위쪽 마스크 98%→0, `timingCurve(0.16,1,0.3,1)`, 길이는 holdDuration이다. 동작 줄이기면 애니메이션 없이 바로 보인다.
- 포커스: `@AccessibilityFocusState`를 `onChange(of: focusTarget)`로 동기화한다.
- 글자는 시스템 텍스트 스타일(`.title.bold()`, `.body`, `.footnote`)을 쓴다.

### 10. RootView.swift

- `.ready` 상태에서는 `switch model.presentedRoute`로 화면을 고른다. `.cardEntry`면 `CardIssuanceView(controller: issuance)`를 보여준다.
- DEBUG 진단 요소를 추가한다. testRecorder가 있을 때만 만든다.
  - `test.hapticCount`: playCount
  - `test.announcements`: 안내 문구를 `"\n"`으로 이은 값
  - `test.issuanceFocus`: `"card.continueButton"` 또는 `"none"`
- AC-16은 `test.*` 요소를 검사에서 제외한다.
- 생성자: `RootView(model:issuance:testBootstrap:testRecorder:testSetupError:)`. DEBUG 인자는 `#if DEBUG` 안에 둔다.

### 11. FocusMateApp.swift

- init에서 model과 `@State issuance`를 조립한다.
- DEBUG에서 부트스트랩이 있으면 `bootstrap.makeFeedbackRecorder()`와 `issueDelay ?? .standard`를 쓰고, 없으면 시스템 구현을 쓴다.
- `start()`가 `loadIfNeeded()` 대신 `model.start()`를 호출한다.
- unavailable 저장소의 catch 분기에서도 컨트롤러를 만든다.

### 12. UITestBootstrap.swift — 시드·주입 확장

현재 `fail` 시나리오는 `.ready(.main)`이 아니면 throw한다. 그래서 카드 화면에서는 저장 실패를 재현할 수 없다.

시드:
- `cardOnly`와 `ready`에 고정 카드(`FM-20261013`, `2026-10-13T09:00:00Z`)를 넣는다 (Q3).
- `issuedWithoutCard`를 새로 둔다. readySnapshot에서 카드만 뺀 것이다(성수→서울숲, AC-10).
- AC-14 원본 바이트 시드 6종을 둔다: `invalidCardShortId`, `invalidCardPrefix`, `invalidCardIssuedAt`, `duplicateCards`, `cardWithoutIssuance`(정류장 null), `undefinedRecord`.
  - 기존 `corrupt`/`unsupported`와 함께 `static let rawSeeds: [String: String]`으로 묶는다.
  - UI 테스트는 base64로 비교한다.

인자:
- `--fm-ui-save`
  - `fail`: 기존 그대로.
  - **`failWrites`**: 모든 쓰기가 실패하는 저장소만 쓰고, 시나리오는 적용하지 않는다(AC-7).
- `--fm-ui-issue-delay <초>`: 0보다 크고 10 이하. 범위 밖이면 `invalidArguments`. 지정하지 않으면 0.9초.
- `--fm-ui-haptics supported|unsupported`: 기본값은 supported.
- 동작 줄이기 인자는 두지 않는다. 시뮬레이터 기본값은 꺼짐이고, 켜짐 경우는 단위 테스트 AC-18이 맡는다.

기록기: `@MainActor @Observable final class UITestFeedbackRecorder: IssuanceHaptics, AccessibilityAnnouncing` (DEBUG 전용).
- `isSupported`, `playCount`, `announcements`를 가진다.
- 안내는 시스템 announcer에도 그대로 넘긴다.
- `@MainActor func makeFeedbackRecorder()`로 만든다.

시그니처:
- `saveMode: SaveMode { normal, failAfterLaunch, failWrites }`
- `issueDelay: Duration?`
- `hapticsSupported: Bool`

### 13. CardTestSupport.swift

- `FakeIssuanceHaptics(isSupported:)`: playCount와 재생 시점의 카드 수(`cardCountsAtPlay`)를 기록한다.
- `RecordingAnnouncer`: 안내 문구를 `messages`에 모은다.
- `SuspendingSleep`: Duration을 기록하고, `resume()`을 부를 때까지 멈춘다.
- `memoryStore(initial: Data?, failWrites: (Int) -> Bool)`: LocalSnapshotStore 클로저 주입용이다. 바이트와 쓰기 횟수를 관리한다.
- 고정 팩토리: `randomNumber: { 1_234_567 }`이면 `FM-01234567`이 나온다.

## 의존성 및 영향도

- **새 라이브러리**: 없다. CoreHaptics와 UIKit을 import한다.
- **리소스**: Assets.xcassets를 새로 둔다. 자동 포함되므로 pbxproj는 수정하지 않는다.
- **SnapshotValidationIssue**: case가 늘어나지만 이를 switch하는 곳은 없다.
- **CardSnapshot**: enum에서 struct로 바뀐다. 원소가 빈 기존 바이트는 그대로 디코딩된다.
- **FocusMateApp**: `start()`를 호출하도록 바뀐다. `loadIfNeeded`의 의미는 그대로다.
- **cardOnly/ready 시드**: 카드가 추가되지만 Phase1FlowTests의 단언과 충돌하지 않는다.
- **RootView**: 인자가 늘어난다. 호출부는 한 곳뿐이다.
- **하위 호환**: v1 파일과 카드 없는 v2 파일은 열린 뒤 카드만 보충된다. W01이 저장한 파일을 이전 앱이 열면 `.corrupt`로 보존된다(A2).

### 기존 구조와의 차이 (context/card/architecture.md, glossary.md 대비)

| 항목 | 웹 | iOS |
|---|---|---|
| 저장 위치 | 별도 키 `next-step-prototype-pass-v1` | `app-state.json` v2 `state.cards.items[]`. glossary의 issuedPass가 CardSnapshot에 해당 |
| ID 형식 | NS-/FM- 허용 | FM-만 허용. NS-는 BR-5 오류로 원본 보존 |
| 보충 조건 | onboarded·기록·진행 여정 | `cardIssued && 카드 없음`. 별도 시작 단계에서 수행하고 실패하면 다음 실행에 재시도 |
| 저장 실패 | 계속 사용 가능 | 진행 차단 |
| 햅틱 | 앱 동작 줄이기 설정이면 생략, 2회 | 지원 기기에서 1회. 시스템 동작 줄이기는 연출에만 적용 |
| 번호 표기 | 카드 위에 표시 | PassIdentity가 형식만 제공하고 표시하지 않음 |
| 완료 화면 | 재실행 시 복원 | 출발지 선택으로 이동 |

- pass-face: architecture.md에 "SwiftUI 공통 카드 뷰는 예정"으로 적힌 부분을 PassFace로 구현한다.
- glossary.md:12의 승차 LCD 정의는 "이름과 체크"로 고쳐야 한다(구현 후 동기화).

## 구현 순서 (RGR 태스크)

1. **CardSnapshot 계약 + BR-5**
   - 파일: CardSection, AppSnapshot
   - 테스트: CardStorageTests
   - AC: AC-13, AC-14(단위 a~f)
2. **팩토리 + PassIdentity**
   - 테스트: PassIdentityTests
   - AC: AC-15, BR-1(접기, 초 내림)
   - 의존: 1
3. **AppModel 발급·완료 화면 유지**
   - 테스트: CardIssuanceModelTests
   - AC: AC-8, AC-3/4/6 모델 단위, 실패 시 `saveFailure == nil`
   - 의존: 1, 2
4. **시작 단계 보충**
   - 테스트: CardSupplementTests
   - AC: AC-9, AC-11, AC-12
   - 의존: 3
5. **피드백 포트 + 상태 머신**
   - 테스트: CardIssuanceControllerTests
   - AC: AC-5, AC-17, AC-18, AC-19 로직
   - 의존: 3
6. **PassFace + Assets**
   - 검증: `check-ios.py build`만 하고, UI 단언은 8번에서 한다
   - 의존: 2
7. **조립·UI 부트스트랩**
   - 파일: UITestBootstrap, FocusMateApp, RootView
   - 테스트: Phase1FlowTests 회귀
   - 의존: 4, 5
8. **발급 화면 + UI 흐름**
   - 테스트: CardIssuanceFlowTests
   - AC: AC-1~7, 16, 19, 20 (XXXL은 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`)
   - 의존: 5, 6, 7
9. **보충·손상 데이터 UI**
   - 테스트: CardStorageFlowTests
   - AC: AC-10, AC-14(UI)
   - 의존: 7, 8
10. **전체 회귀**
    - `python3 scripts/check-ios.py test`, `npm test`
    - AC: AC-21

병렬로 할 수 있는 것: 3번 이후 4번과 5번, 2번 이후 6번.

## architect 질문 (사용자 확인 대상)

- **Q1** AC-5 UI 테스트의 발급 중 대기 시간
  - (a) 0.9초로 쓰고 흔들리면 늘린다 (권장)
  - (b) UI 테스트만 3.0초로 둔다
- **Q2** 보충 저장 실패를 화면에 표시할지
  - (a) supplementFailure에만 기록한다 (권장)
  - (b) 기존 saveFailure 문구로 표시한다
- **Q3** cardOnly/ready 시드에 카드를 넣을지
  - (a) 고정 카드를 넣고, 카드 없는 경우는 issuedWithoutCard 시드로 다룬다 (권장)
  - (b) 기존 그대로 둔다
- **Q4** 카드 위 글자에 Dynamic Type을 적용할지
  - (a) 카드 폭에 비례하게 한다 (권장)
  - (b) Dynamic Type을 적용하되 상한을 둔다
- **Q5** 발급 햅틱 시점
  - (a) 연출이 끝나 완료 상태가 될 때 (권장)
  - (b) 저장에 성공한 직후
