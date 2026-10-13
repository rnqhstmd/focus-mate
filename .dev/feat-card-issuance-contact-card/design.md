# 설계: 카드 발급과 공통 카드 뷰 (W01, FR-3) — 확정 (2회차)

- 설계 규모: 대형
- PRD: `prd.md` (AC-1~21, BR-1~8)
- 프로젝트 루트: `/Users/bonseung/projects/focus-mate/next-step-w01`

## 확정 결정

- AC-5 테스트: 발급 중 상태를 DEBUG 전용 수동 해제 게이트로 붙잡아 둔다. 실행 인자는 `--fm-ui-issue-hold manual`, 해제 버튼은 `test.releaseIssuance`다. 슬롯 애니메이션 길이(0.86초 고정)는 hold 시간과 분리한다.
- 보충 저장이 실패해도 화면에 표시하지 않는다. `supplementFailure`에만 기록한다.
- 시드:
  - `cardOnly`, `ready`에 고정 카드를 넣는다. ID는 `FM-20261013`, `issuedAt`은 `2026-10-13T09:00:00Z`다.
  - 시드 `issuedWithoutCard`를 추가한다.
- 카드 위 글자는 카드 크기에 비례한다. Dynamic Type은 화면 문구와 버튼에만 적용한다.
- 햅틱:
  - CoreHaptics로 그라데이션 패턴을 만든다. 0.9초 동안 세기가 약→강으로 커지고, 끝에 탭이 1번 있다.
  - 저장에 성공하면 연출 시작과 함께 1회 재생한다. 동작 줄이기와 상관없이 재생한다.
  - 지원 여부 판단과 재생은 모두 CoreHaptics로 한다. 실패해도 오류를 내지 않는다.
- 테스트 인자 정리:
  - `--fm-ui-issue-delay`, `--fm-ui-haptics`, `failWrites`/`SaveMode`는 만들지 않는다.
  - 저장 실패는 `--fm-ui-save fail` 하나로 처리한다. 이 인자는 `.cardEntry`에서도 허용한다.

## 변경 범위

### Xcode·실행기
- Xcode 프로젝트 등록은 필요 없다. 세 타깃 모두 `PBXFileSystemSynchronizedRootGroup`이라 `.swift`와 `Assets.xcassets`가 자동으로 포함된다 (`project.pbxproj:22-26, 39-42`).
- `check-ios.py`의 파일 인자는 `ios/FocusMateTests/X.swift`처럼 상위 폴더를 포함한 경로로 준다. 파일 stem과 XCTestCase 클래스명은 같아야 한다.

### 신규 (앱)

| 경로 | 책임 |
|---|---|
| ios/FocusMate/CardSnapshotFactory.swift | ID 난수와 시계를 주입받아 CardSnapshot을 만든다 |
| ios/FocusMate/PassIdentity.swift | 이름·번호 표기의 단일 출처 |
| ios/FocusMate/PassFace.swift | 공통 카드 뷰, 비율 상수 |
| ios/FocusMate/IssuanceHapticPattern.swift | 발급 진동 패턴(순수 값) + CHHapticPattern 변환 |
| ios/FocusMate/IssuanceFeedback.swift | IssuanceHaptics·AccessibilityAnnouncing 프로토콜, CoreHapticsIssuancePlayer, SystemAccessibilityAnnouncer |
| ios/FocusMate/CardIssuanceController.swift | 발급 상태 머신, CardIssuing 포트, CardIssuanceTiming |
| ios/FocusMate/CardIssuanceView.swift | 발급 화면, CardIssuanceCopy |
| ios/FocusMate/Assets.xcassets/{Contents.json, PassDots.imageset/{Contents.json, ticket-dots.svg}} | 서울 점묘. designs/final/assets/bus/ticket-dots.svg를 복사하고 preserves-vector-representation을 켠다 |

### 신규 (테스트)

| 경로 | 대상 |
|---|---|
| ios/FocusMateTests/CardStorageTests.swift | AC-13, AC-14(단위), BR-5 |
| ios/FocusMateTests/PassIdentityTests.swift | AC-15, BR-1 |
| ios/FocusMateTests/CardIssuanceModelTests.swift | AC-8, 완료 화면 유지(AC-3/4/6 모델) |
| ios/FocusMateTests/CardSupplementTests.swift | AC-9, AC-11, AC-12, 보충 멱등 |
| ios/FocusMateTests/IssuanceHapticPatternTests.swift | AC-17 패턴 구조, CHHapticPattern 변환 |
| ios/FocusMateTests/CardIssuanceControllerTests.swift | AC-5(잠금), AC-17, AC-18, AC-19 로직 |
| ios/FocusMateTests/PassFaceAssetTests.swift | 에셋 존재, 이름 출처 |
| ios/FocusMateTests/CardTestSupport.swift | 가짜 객체 모음 (테스트 클래스 없음) |
| ios/FocusMateUITests/UITestLaunchSupport.swift | `struct FocusMateUIHarness` (테스트 클래스 없음) |
| ios/FocusMateUITests/CardIssuanceFlowTests.swift | AC-1~7, AC-16, AC-19, AC-20 |
| ios/FocusMateUITests/CardStorageFlowTests.swift | AC-10, AC-14(UI) |

### 수정

| 경로 | 변경 |
|---|---|
| CardSection.swift | CardSnapshot 계약. 주석(:3) 갱신 |
| AppSnapshot.swift | 검증 오류 3종, validate에 BR-5 추가, 카드 편의 멤버 |
| AppModel.swift | persist 분리, issueCard/finishCardIssuance/presentedRoute, start/supplementCardIfNeeded |
| RootView.swift | presentedRoute 분기, 발급 화면, DEBUG 진단 |
| FocusMateApp.swift | 컨트롤러·피드백·게이트 조립, model.start() |
| UITestBootstrap.swift | 시드, fail 의미 정리, issue-hold manual, 기록기·게이트 |
| ios/FocusMateTests/SnapshotCodecTests.swift | :129-130 이름을 `testV2MalformedOrUndefinedElementsAreCorrupt`로 바꾸고, 주석을 "카드 원소의 필수 키가 없거나 여정·기록이 미정의 원소면 .corrupt"로 바꾼다 |

## 컨벤션 (기존 코드 기준)

- 이름:
  - 저장 단위는 `…Snapshot`, 묶음은 `…Section`이다.
  - 접근성 식별자는 `screen.<route>`, `<영역>.<이름>` 형식이고, 진단용은 `test.<이름>`이다.
  - 테스트는 `testACn_한국어설명` 형식으로 짓고 `// 깨짐 명명:` 주석을 붙인다.
- AppSnapshot의 전체 생성자는 private이다. 값은 `updating…`으로만 바꾼다.
- Codable은 섹션마다 직접 구현한다. 키가 없으면 거부하고, 모르는 키는 무시하고, `.sortedKeys`로 쓴다.
- 오류: 디코딩 실패는 `.corrupt`, validate 실패는 `.invalidState`다. 화면 문구는 RootView.message(for:)가 정한다.
- 의존성 주입은 기본값이 있는 클로저로 한다. 기록이 필요한 장치(햅틱·안내)만 프로토콜과 가짜 객체로 둔다.
- 모델은 `@MainActor @Observable final class`로 만들고, 상태는 `private(set)`, 저장 결과는 `@discardableResult -> Bool`로 돌려준다.
- iOS 17, Swift 5, strict concurrency minimal.

## 상세 설계

### 1. CardSection.swift — CardSnapshot
- 선언: `struct CardSnapshot: Codable, Equatable { let id: String; let issuedAt: Date }`
- 키 두 개(`id`, `issuedAt`)는 필수다. 없거나 타입이 맞지 않으면 `.corrupt`로 처리한다.
- `issuedAt`은 `Date.ISO8601FormatStyle`로 파싱한다. 파싱에 실패하면 `DecodingError.dataCorrupted`를 던져 `.corrupt`가 된다 (AC-14 c).
- **id 형식은 디코딩에서 검사하지 않는다.** validate에서 검사해야 AC-14 a/b가 `.invalidState`로 분류된다.
- 인코딩 결과는 `{"id":…,"issuedAt":"yyyy-MM-ddTHH:mm:ssZ"}`다. 날짜 문자열을 직접 만들어 인코더의 날짜 전략에 영향받지 않게 한다.
- `static func isValidID(_ id: String) -> Bool`: 길이 11, `FM-` 접두, ASCII 0-9 8자리.

### 2. CardSnapshotFactory.swift
- 선언: `struct CardSnapshotFactory { init(randomNumber: @escaping () -> UInt32 = { .random(in: 0..<100_000_000) }, now: @escaping () -> Date = Date.init); func make() -> CardSnapshot }`
- ID는 `FM-` 뒤에 0으로 채운 8자리 숫자를 붙인다. 범위를 넘는 값은 `% 100_000_000`으로 접는다.
- `issuedAt`은 초 단위로 내린다.
- 발급과 보충이 이 팩토리를 함께 쓴다.

### 3. AppSnapshot.swift — BR-5
- `SnapshotValidationIssue`에 `multipleCards(Int)`, `cardWithoutIssuance`, `invalidCardID`를 추가한다.
- 검증 순서: 단계 → 정류장 → 카드 수 > 1 → 카드가 있는데 미발급 → isValidID.
- `cardIssued == true`이고 카드가 없는 상태는 **유효**하다 (보충 대상).
- AC-14 매핑:

| 경우 | 분류 | 문구 |
|---|---|---|
| (a) `FM-1234`, (b) `NS-12345678` | `.invalidState(.invalidCardID)` | "저장된 이용 상태를 확인할 수 없어요." |
| (d) 카드 2장 | `.multipleCards(2)` | 같음 |
| (e) 미발급+카드 1장, 정류장 null | `.cardWithoutIssuance` | 같음 |
| (c) issuedAt "어제" | `.corrupt` | "저장된 데이터 형식을 읽을 수 없어요." |
| (f) `records.items`에 `{"kind":"x"}` | `.corrupt` | 같음 |

- 편의 멤버: `var currentCard: CardSnapshot?`, `var needsCardSupplement: Bool` (= `cardIssued && cards.items.isEmpty`), `func issuingCard(_:) -> AppSnapshot` (cardIssued를 true로 바꾸고 카드 1장을 넣는다. 나머지는 유지).
- 검증 로직이 한 곳에 있으므로 읽기(SnapshotCodec.decode), 저장 후보(LocalSnapshotStore.save), AppModel.save 모두 같은 규칙을 따른다.

### 4. PassIdentity.swift
- 선언: `struct PassIdentity: Equatable { static let displayName = "집중동행카드"; let name: String; let numberText: String; init(card:); static func current(in: AppSnapshot?) -> PassIdentity? }`
- 번호 표기: `"FM · " + 숫자[0..<4] + " " + 숫자[4..<8]`.
- 카드가 없으면 nil이다.
- 현재 어떤 화면도 번호 표기를 쓰지 않는다.

### 5. PassFace.swift
- 비율은 ISO/IEC 7810 ID-1인 85.6 : 53.98(≈1.586)이다. 기준 폭은 238pt이고 `.aspectRatio(.fit)`로 배치한다.
- 내부 요소와 글자는 `폭 / 238` 배율로 키운다. Dynamic Type은 적용하지 않는다. 발급 화면에서는 `maxWidth: 320`이다.
- 외형:

| 요소 | 값 |
|---|---|
| 배경 | `#121416` |
| 테두리 | `#51565a` |
| 모서리 반경 | 폭 × 16/238 |
| IC 칩 | 왼쪽 7.5%, 위 43%, 폭 12%, `#c5b998` |
| 비접촉 표시 | `wave.3.right` |
| 글자 | "Focus Mate" + displayName. 번호는 넣지 않는다 |

- 점묘 배경 SVG는 360×230(1.565)라 카드 비율과 다르다. 늘리지 않고 카드 폭의 78%로 비율을 유지한다. 세로는 가운데, 가로는 오른쪽 정렬에 폭의 12%만큼 바깥으로 밀고, 카드 모양으로 clip한다. 불투명도는 0.85다.
- 접근성: `.accessibilityElement(children: .ignore)`, `.accessibilityLabel(displayName)`, `.isImage`. `card.face` 식별자는 호출하는 쪽이 붙인다.
- 선언: `struct PassFace: View { static let aspectRatio: CGFloat; static let referenceWidth: CGFloat = 238; static let dotsAssetName = "PassDots"; init() }`

### 6. AppModel.swift

#### persist
- 선언: `private func persist(_:) -> StorageIssue?`
- 기존 save 본문을 그대로 옮긴다: 경로 계산 → store.save → snapshot·launchState 교체 → 경로가 바뀌면 `path = []`.
- persist는 saveFailure를 건드리지 않는다. save가 persist 결과를 받아 saveFailure를 nil 또는 issue로 설정한다. 동작은 기존과 같다.

#### issueCard() -> Bool
- 진행 조건: `.ready(.cardEntry)`, snapshot 있음, `!cardIssued`. 하나라도 어긋나면 쓰지 않고 false를 돌려준다.
- `persist(snapshot.issuingCard(cardFactory.make()))`를 호출한다.
- 성공하면:
  - snapshot에 카드가 들어간다.
  - `launchState = .ready(.initialStationEntry)`, `path = []`.
  - `isHoldingIssuedCard = true`. saveFailure는 그대로 둔다.
- 실패하면 snapshot, launchState, path, saveFailure를 모두 바꾸지 않는다 (AC-7, BR-6).

#### 표시 경로 규칙
- **어떤 화면을 그릴지는 `presentedRoute`로만 판단한다.** launchState는 `.loading`/`.failed` 판단과 모델 내부 guard에만 쓴다.
- `presentedRoute`:
  - `.ready`가 아니면 nil.
  - `isHoldingIssuedCard`이면 `.cardEntry`.
  - 그 밖에는 launchState의 경로.
- `finishCardIssuance()`가 플래그를 내린다. 플래그는 메모리에만 있으므로 재실행하면 `.initialStationEntry`로 시작한다 (AC-6, A3).

#### start()와 보충
- `start()`는 `loadIfNeeded()`를 한 다음 `supplementCardIfNeeded()`를 한다.
- load와 loadIfNeeded는 바꾸지 않는다. 그래서 "읽기는 쓰지 않는다"(StorageV2Tests:41-56)와 AppFoundationTests:232-256·279-306은 그대로 통과한다.
- `supplementCardIfNeeded()`:
  - `!hasAttemptedSupplement`, `.ready`, `needsCardSupplement`가 모두 참일 때만 실행한다.
  - 플래그를 먼저 세운다.
  - `store.save(snapshot.updating(cards: CardSection(items: [cardFactory.make()])))`를 호출한다. launchState와 path는 바꾸지 않는다.
  - 성공하면 snapshot을 교체한다.
  - 실패하면 `supplementFailure = issue`만 기록한다. 화면 표시와 saveFailure는 바꾸지 않는다.
- 멱등 근거:
  - 같은 프로세스: loadIfNeeded는 hasLoaded가 막는다. 보충은 성공 뒤에는 needsCardSupplement가 false라서, 실패 뒤에는 hasAttemptedSupplement 때문에 다시 실행되지 않는다.
  - 새 프로세스: 카드가 있으면 보충 대상이 아니다. 실패했던 경우에만 다시 시도한다.

#### 시그니처
- `init(store:cardFactory: = .init())`
- `start()`, `supplementCardIfNeeded()`, `@discardableResult issueCard() -> Bool`, `finishCardIssuance()`
- `var presentedRoute: LaunchRoute?`
- `private(set) var supplementFailure: StorageIssue?`
- `extension AppModel: CardIssuing {}`

### 7. IssuanceHapticPattern.swift + IssuanceFeedback.swift

#### 패턴 (순수 값)
- 연속 진동: 0초에 시작, 0.9초 동안, sharpness 0.3, intensity 1.0.
- 세기 곡선 `hapticIntensityControl`: (0.0, 0.15) → (0.45, 0.45) → (0.9, 1.0).
- 끝 탭 `hapticTransient` 1개: 시간 0.9, intensity 1.0, sharpness 0.9.
- `duration = max(연속 진동 끝, 마지막 탭) = 0.9`이고, `CardIssuanceTiming.hapticDuration`과 같다.
- 선언: `struct IssuanceHapticPattern: Equatable { struct CurvePoint { time: TimeInterval; intensity: Float }; struct Tap { time; intensity; sharpness }; let continuousDuration; continuousSharpness; intensityCurve: [CurvePoint]; taps: [Tap]; var duration; static let issuance; func makeCHHapticPattern() throws -> CHHapticPattern }`

#### CoreHapticsIssuancePlayer
- `isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics`
- `play`:
  - 엔진은 처음 쓸 때 만들고 붙잡아 둔다.
  - `try? start` → `makePlayer` → `start(atTime: CHHapticTimeImmediate)` 순서로 재생한다.
  - stopped/reset handler에서 엔진을 nil로 만든다.
  - 실패는 모두 조용히 무시한다. UIFeedbackGenerator는 쓰지 않는다.

#### 안내와 프로토콜
- SystemAccessibilityAnnouncer: `UIAccessibility.post(.announcement, argument:)`.
- `@MainActor protocol IssuanceHaptics: AnyObject { var isSupported: Bool { get }; func play(_ pattern: IssuanceHapticPattern) }`
- `@MainActor protocol AccessibilityAnnouncing: AnyObject { func announce(_ message: String) }`

### 8. CardIssuanceController.swift

```
ready ─issue─▶ issuing ─issueCard()=false─▶ failed ─issue─▶ issuing …
                  └─true─▶ [햅틱 패턴 1회] ─▶ (hold>0이면 sleep) ─▶ issued ─proceed─▶ 모델 플래그 해제
```

#### `issue(reduceMotion:) async -> Bool`
1. phase가 ready나 failed가 아니면 false를 돌려준다. 이 검사는 첫 suspension 전에, MainActor에서 한다. 그래서 연타는 직렬화된다.
2. `.issuing`으로 바꾸고 안내 "카드를 발급하고 있어요."를 낸다.
3. `issuer.issueCard()`를 동기로 호출한다.
   - false면: `.failed`로 바꾸고 "카드를 발급하지 못했어요. 다시 시도해 주세요."를 안내한다. 햅틱은 0회이고 false를 돌려준다.
4. `isSupported`이면 `haptics.play(.issuance)`를 1회 호출한다. 연출 시작과 같은 시점이고, 동작 줄이기와 상관없다.
5. hold는 `holdDuration(reduceMotion:standard:)`로 정한다. 0보다 크면 `await sleep(hold)`.
6. `.issued`로 바꾸고 "카드가 발급됐어요. 출발지를 선택해보세요."를 안내한다. `focusTarget = .continueButton`으로 두고 true를 돌려준다.

#### 타이밍 (CardIssuanceTiming)

| 이름 | 값 | 의미 |
|---|---|---|
| standardHold | `.milliseconds(900)` | FR-3-9 상한 |
| slotAnimation | 0.86 | 화면 연출 길이. hold와 분리한 고정값 |
| hapticDuration | 0.9 | 진동 패턴 길이 |

동작 줄이기가 켜져 있으면 hold는 0(sleep을 호출하지 않음)이고 애니메이션도 없다.

#### proceed()
- `.issued`일 때만 `issuer.finishCardIssuance()`를 호출한다. 호출 뒤에도 phase는 `.issued`로 남는다.
- 디스크에 cardIssued가 저장된 뒤에는 presentedRoute가 다시 `.cardEntry`로 돌아갈 경로가 없다. 이 불변식은 단위 테스트로 고정한다.

#### 선언
- `@MainActor protocol CardIssuing: AnyObject { func issueCard() -> Bool; func finishCardIssuance() }`
- `@MainActor @Observable final class CardIssuanceController`
  - `enum Phase { ready, issuing, failed, issued }`
  - `enum FocusTarget { continueButton }`
  - `private(set) var phase`, `private(set) var focusTarget`
  - `init(issuer:haptics:announcer:standardDuration: = CardIssuanceTiming.standardHold, sleep: = { try? await Task.sleep(for: $0) })`
  - `issue(reduceMotion:)`, `proceed()`, `static func holdDuration(reduceMotion:standard:) -> Duration`

### 9. CardIssuanceView.swift

#### 구성
- ScrollView 안에 제목, 설명, 카드 무대(슬롯 + PassFace 또는 빈자리), 힌트, `card.issueError`를 둔다.
- 버튼은 `.safeAreaInset(edge: .bottom)`에 고정한다. 최소 높이 44pt이고 줄바꿈을 허용한다.
- 컨테이너: `.accessibilityElement(children: .contain).accessibilityIdentifier("screen.cardEntry")`.
- **내비게이션 제목 "Focus Mate"는 숨기지 않는다.** HarnessUITests가 이 제목에 의존한다.

#### 상태별 표시

| phase | `card.title` (value) | `card.face` | 버튼 | 기타 |
|---|---|---|---|---|
| ready | "집중동행카드를 발급받아볼까요?" | 없음 | `card.issueButton` "집중동행카드 발급받기", 활성 | |
| issuing | 발급 전 문구 | 슬롯 연출 중인 카드 | `card.issueButton` "카드를 발급하고 있어요", disabled | |
| failed | 발급 전 문구 | 없음 | `card.issueButton` "다시 발급받기", 활성 | `card.issueError` value "카드를 발급하지 못했어요. 다시 시도해 주세요." |
| issued | "카드가 발급됐어요. 이제, 어디에서 출발할까요?" | 있음 (라벨 "집중동행카드") | `card.continueButton` "출발지 선택하기" | issueButton 없음 |

#### 문구와 동작
- 설명·힌트 문구는 PRD 디자인 스펙을 따르고 `CardIssuanceCopy`에 상수로 둔다. 안내 3종도 상수로 둔다.
- 동작 줄이기: `@Environment(\.accessibilityReduceMotion)` 값을 `Task { await controller.issue(reduceMotion:) }`로 넘긴다.
- 연출: `withAnimation(.timingCurve(0.16,1,0.3,1, duration: slotAnimation))`으로 offset을 −42에서 0으로, 위쪽 마스크를 98%에서 0으로 바꾼다. 길이는 hold와 상관없다. 동작 줄이기가 켜져 있으면 애니메이션 없이 바로 보여준다.
- 포커스: `@AccessibilityFocusState`를 `onChange(of: focusTarget)`로 맞춘다. 수동으로 확인한다.

### 10. RootView.swift
- 분기:
  - `.loading`과 `.failed`는 launchState로 판단한다.
  - `.ready`는 **presentedRoute로만** 판단한다. `.cardEntry`이면 `CardIssuanceView`를 보여준다.
- DEBUG 진단 (부트스트랩이 있을 때만):

| 식별자 | 내용 |
|---|---|
| `test.hapticCount` | 진동 재생 횟수 |
| `test.announcements` | 안내 문구를 `"\n"`으로 이은 값 |
| `test.dynamicTypeSize` | `String(describing: dynamicTypeSize)` |
| `test.releaseIssuance` | manual 모드에서만 보이는 버튼. topTrailing, 44×44, opacity 0.02. 누르면 `gate.release()` |

- AC-16 검사는 `test.*`를 제외한다. 해제 버튼은 manual 모드에서만 보이므로 Phase1 테스트의 버튼 수 단언에는 영향이 없다.
- 선언: `RootView(model:issuance:)` + DEBUG용 `testBootstrap:testRecorder:testGate:testSetupError:`

### 11. FocusMateApp.swift
- init에서 model과 `@State issuance`를 조립한다.
- DEBUG에서 부트스트랩이 있으면:
  - recorder(haptics와 announcer 역할)를 쓴다.
  - manual 모드이면 sleep 자리에 `gate.wait`를 넣는다.
- 부트스트랩이 없으면 CoreHapticsIssuancePlayer와 SystemAccessibilityAnnouncer를 쓴다.
- catch 분기도 같은 방식으로 만든다.
- 시작할 때 `model.start()`를 호출한다.

### 12. UITestBootstrap.swift

#### 시드
- `cardOnly`, `ready`: 고정 카드를 넣는다.
- `issuedWithoutCard`: readySnapshot(성수→서울숲)에서 카드만 없는 상태.
- AC-14 원본 바이트 시드:
  - `invalidCardShortId`(a)
  - `invalidCardPrefix`(b)
  - `invalidCardIssuedAt`(c)
  - `duplicateCards`(d)
  - `cardWithoutIssuance`(e, 정류장 null)
  - `undefinedRecord`(f)
- 위 시드는 corrupt/unsupported와 함께 `static let rawSeeds: [String: String]`에 둔다.
- **UI 테스트는 같은 JSON 리터럴을 테스트 쪽에 따로 두고, 그것으로 base64 기대값을 만든다.**

#### 실행 인자
- `--fm-ui-save fail`: 모든 쓰기가 실패하는 저장소를 쓴다. applySaveScenario는 경로별로 다르게 처리한다.
  - `.ready(.main)`: 기존 시나리오.
  - `.ready(.cardEntry)`: 아무것도 하지 않는다.
  - 그 밖: `invalidSaveState`.
- `--fm-ui-issue-hold manual`: 다른 값이면 invalidArguments다. 지정하지 않으면 운영 hold를 쓴다.
- 햅틱 지원 여부를 바꾸는 인자는 없다. 기록기는 항상 `isSupported = true`다.

#### 기록기와 게이트 (DEBUG, MainActor)
- `UITestFeedbackRecorder: IssuanceHaptics, AccessibilityAnnouncing` (@Observable): `playCount`, `patterns`, `announcements`를 기록한다. 안내는 시스템 announcer에도 넘긴다.
- `UITestIssuanceGate` (@Observable):
  - `wait(_:) async`는 continuation을 저장한다.
  - `release()`는 continuation을 한 번만 resume한다. 대기 중이 아닐 때 호출하면 다음 wait를 바로 통과시킨다.

#### 선언
- `let issueHold: IssueHold` (`enum IssueHold { case standard, manual }`)
- `@MainActor func makeFeedbackRecorder() -> UITestFeedbackRecorder`
- `@MainActor func makeGate() -> UITestIssuanceGate?`

### 13. 테스트 지원

#### CardTestSupport.swift
- `FakeIssuanceHaptics(isSupported:)`: 재생한 `patterns`와 재생 시점의 카드 수 `cardCountsAtPlay`를 기록한다.
- `RecordingAnnouncer`: 안내 문구를 `messages`에 기록한다.
- `SuspendingSleep` (@MainActor):
  - `requested`: 요청된 Duration 목록.
  - `sleep(_:)`: Duration을 기록하고 continuation을 저장한다.
  - **`untilSuspended() async`**: sleep에 들어갈 때까지 기다린다.
  - `resume()`: 한 번만 resume하고 nil로 지운다. continuation이 없을 때 부르면 XCTFail.
- `SequenceRandom([UInt32])`: AC-8용. 예: 11_111_111, 22_222_222.
- `memoryStore(initial: Data?, writeFails: (Int) -> Bool) -> (LocalSnapshotStore, bytes: () -> Data?, writeCount: () -> Int)`

#### UITestLaunchSupport.swift
- `struct FocusMateUIHarness`:
  - `launch(seed:save:hold:extraArguments:)`, `relaunch()`
  - `element(_:)`, `diagnostic(_:)`, `snapshot()`
- Phase1FlowTests는 수정하지 않는다. 두 헬퍼를 합치는 일은 후속 작업이다.

## 의존성 및 영향도

- 새 라이브러리는 없다. CoreHaptics와 UIKit을 쓴다. 에셋 누락은 PassFaceAssetTests가 `UIImage(named:) != nil`로 잡는다.
- 기존 코드에 대한 영향:
  - SnapshotValidationIssue를 switch하는 곳이 없어서 case를 추가해도 깨지지 않는다.
  - CardSnapshot이 enum에서 struct로 바뀐다. 카드 원소가 없는 기존 바이트는 그대로 디코딩된다.
  - `fail` 시나리오가 `.cardEntry`까지 허용하도록 넓어진다.
  - cardOnly/ready 시드에 카드가 들어가도 Phase1 단언과 충돌하지 않는다.
- HarnessUITests (운영 저장소, 제목 "Focus Mate"):
  - 발급 화면도 제목을 유지하므로 통과한다.
  - PassFace 안의 "Focus Mate" 글자는 접근성에 노출되지 않아 중복으로 잡히지 않는다.
  - 시뮬레이터 운영 파일에 따라 보충 쓰기가 일어날 수 있다. 의도된 동작이다.
- 하위 호환:
  - v1 파일과 카드 없는 v2 파일은 정상으로 열고 카드만 보충한다.
  - W01 이후 파일을 이전 앱이 열면 `.corrupt`로 보존한다 (A2).
- 이관:
  - **W04**: 보충이 계속 실패한 사용자는 "발급됨·카드 없음" 상태이고 PassIdentity.current가 nil이다. 승차 차단 규칙이 이 경우를 다뤄야 한다.
  - **W10**: PassFace에 외형 인자를 기본값과 함께 추가할 때, W04/W11 호출부가 기본 외형을 의도한 것인지 다시 확인한다.

### 기존 구조와의 차이

| 항목 | 웹 | iOS (W01) |
|---|---|---|
| 저장 위치 | 별도 키 `next-step-prototype-pass-v1` | `app-state.json` v2 `state.cards.items[]`. issuedPass가 CardSnapshot에 해당 |
| ID 접두 | NS-/FM- | FM-만. NS-는 BR-5 오류로 원본을 보존 |
| 보충 조건 | onboarded·기록·진행 여정 | `cardIssued && 카드 없음`. 별도 시작 단계, 실패해도 조용히 넘기고 다음 실행에서 재시도 |
| 저장 실패 | 계속 사용 | 진행 차단 |
| 햅틱 | 앱 동작 줄이기 설정 시 생략, 2회 | CoreHaptics 그라데이션 1회, 동작 줄이기와 무관 |
| 연출 | 100ms / 900ms | hold 0.9초 + 애니메이션 0.86초 고정. 동작 줄이기 시 hold 0, 애니메이션 없음 |
| 카드 번호 | 카드 위에 표시 | 표시하지 않음 |
| pass-face | DOM | PassFace |
| 완료 화면 | 재실행 시 복원 | 출발지 선택으로 이동 |
| 승차 LCD 정의 | glossary "이름/ID" | "이름과 체크" (문서 정정 대상) |

## 구현 순서 (RGR 태스크)

명령: `python3 scripts/check-ios.py test <경로...>`

1. **CardSnapshot 계약 + BR-5**
   - 파일: CardSection, AppSnapshot, SnapshotCodecTests(이름·주석)
   - focused: `ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift`
   - 검증: AC-13, AC-14(단위 a~f). StorageIssue 종류가 정확한지, 쓰기가 차단되고 바이트가 보존되는지.
2. **팩토리 + PassIdentity**
   - focused: `ios/FocusMateTests/PassIdentityTests.swift`
   - 검증: AC-15, BR-1 (1_234_567 → `FM-01234567`, 범위 접기, 초 내림).
   - 선행: 1
3. **AppModel 발급·완료 화면 유지**
   - focused: `ios/FocusMateTests/CardIssuanceModelTests.swift ios/FocusMateTests/AppFoundationTests.swift`
   - 검증:
     - AC-8: 순차 난수로 첫 시도 false·카드 0, 두 번째 true·카드 1, 파일 id는 FM-22222222.
     - 실패 시 saveFailure는 nil.
     - 성공 시 상태와 presentedRoute.
     - finish 뒤 `.initialStationEntry`, 새 인스턴스에서도 같은 id.
     - presentedRoute가 다시 `.cardEntry`가 되지 않는다는 불변식.
   - 선행: 1, 2
4. **시작 단계 보충**
   - focused: `ios/FocusMateTests/CardSupplementTests.swift ios/FocusMateTests/StorageV2Tests.swift`
   - 검증:
     - AC-9: 새 인스턴스로 두 번 실행해도 id와 바이트가 같다.
     - AC-11: `supplementFailure == .writeFailed`, saveFailure nil, `.main`, 바이트 같음.
     - AC-12.
     - 같은 인스턴스에서 start()를 두 번 불러도 쓰기는 1회.
   - 선행: 3
5. **발급 진동 패턴 + CoreHaptics 어댑터**
   - focused: `ios/FocusMateTests/IssuanceHapticPatternTests.swift`
   - 검증: AC-17 패턴 구조(곡선 처음 < 끝, 탭 1개, duration == 0.9 == hapticDuration), `makeCHHapticPattern`이 throw하지 않음.
   - 선행: 없음
6. **발급 상태 머신**
   - 파일: CardIssuanceController, CardTestSupport
   - focused: `ios/FocusMateTests/CardIssuanceControllerTests.swift`
   - 검증:
     - AC-5: untilSuspended 동안 `.issuing`이고 재호출은 false, 저장은 1회.
     - AC-17: (a) 1회, `cardCountsAtPlay == [1]`, 패턴은 `.issuance` / (b) 0회, 카드 1장 / 실패 시 0회.
     - AC-18: (a) 기본 생성자(sleep만 주입)로 `requested == [d]`, 0 < d ≤ 0.9초, 햅틱 1회 / (b) requested 없음, 즉시 `.issued`, 햅틱 1회.
     - AC-19 로직: 안내 순서와 focusTarget.
     - proceed 가드.
   - 선행: 3, 5
7. **PassFace + 에셋**
   - focused: `ios/FocusMateTests/PassFaceAssetTests.swift`
   - 검증: 에셋 존재, 이름 출처.
   - 선행: 2
8. **조립·UI 부트스트랩**
   - 파일: UITestBootstrap, FocusMateApp, RootView(presentedRoute 분기·진단·해제 버튼), UITestLaunchSupport
   - focused 회귀: `ios/FocusMateUITests/Phase1FlowTests.swift ios/FocusMateUITests/HarnessUITests.swift`
   - 선행: 4, 6
9. **발급 화면 + UI 흐름**
   - 파일: CardIssuanceView
   - focused: `ios/FocusMateUITests/CardIssuanceFlowTests.swift`
   - 검증:
     - AC-1~4, 6, 16.
     - AC-5: hold manual → 탭 → 존재·라벨·비활성 확인 → 탭 ×2(매번 존재 확인 후) → `test.releaseIssuance` → 결과 확인.
     - AC-7 (save fail): hapticCount "0", saveFailure 없음.
     - AC-19: face 라벨, 하위 요소 0개, 안내 2종.
     - AC-20: 먼저 `test.dynamicTypeSize == "accessibility5"`를 확인한 뒤 isHittable과 탭 결과를 본다.
   - **수동 확인**:
     - VoiceOver에서 완료 후 포커스가 "출발지 선택하기"로 가는지.
     - 실기기에서 "점점 세게 → 끝에 뚝" 진동이 나는지.
     - 진동 미지원 기기에서 오류가 없는지.
   - 선행: 6, 7, 8
10. **보충·손상 데이터 UI**
    - focused: `ios/FocusMateUITests/CardStorageFlowTests.swift`
    - 검증: AC-10, AC-14(UI, 테스트 쪽 리터럴로 만든 base64와 비교).
    - 선행: 8
11. **전체 회귀**
    - `python3 scripts/check-ios.py test`, `npm test`
    - 검증: AC-21.

병렬 가능: 1과 5는 처음부터, 3 이후 4와 6, 2 이후 7, 8 이후 9와 10.

---

## Testability 평가 (test-architect)

**Testability Score: 8/10 ✅ TESTABILITY PASS** (1회차 설계 기준). 2회차에서 필수·권고 6건을 모두 반영했다.

### 러너
- iOS: `scripts/check-ios.py`. 파일 인자에 상위 폴더 이름이 들어 있어야 한다.
- 웹: `npm test` (`node --test scripts/design-baseline.test.cjs && node scripts/prototype-edge-qa.cjs`)

### 컴포넌트별 전략

| 컴포넌트 | 레이어 | 러너 / 테스트 | 격리 | AC |
|---|---|---|---|---|
| CardSnapshot + BR-5 | 동작 (순수) | CardStorageTests | 바이트 리터럴. 경계 길이 10/12, 전각 숫자, 숫자 외 문자 | AC-13, AC-14 |
| CardSnapshotFactory | 동작 | PassIdentityTests | 난수·시계 클로저 고정 | BR-1 |
| PassIdentity | 동작 (순수) | PassIdentityTests | 없음 | AC-15 |
| AppModel 발급·보충·라우팅 | 동작 | CardIssuanceModelTests, CardSupplementTests, AppFoundationTests 회귀 | memoryStore(read/write 클로저) + 실제 LocalSnapshotStore·SnapshotCodec, 팩토리 주입 | AC-3/4/6(모델), 7(모델), 8, 9, 11, 12 |
| IssuanceHapticPattern | 동작 (순수 값) | IssuanceHapticPatternTests | 없음 | AC-17 패턴 |
| CardIssuanceController | 동작 (핵심) | CardIssuanceControllerTests (@MainActor) | CardIssuing·IssuanceHaptics·AccessibilityAnnouncing 가짜 객체, SuspendingSleep. reduceMotion은 인자로 받음 | AC-5, 17, 18, 19(로직) |
| CoreHapticsIssuancePlayer / SystemAccessibilityAnnouncer | OS 어댑터 | 빌드·리뷰 + 수동 실기기 | 프로토콜 뒤로 격리 | — |
| UITestBootstrap·기록기·게이트·RootView 진단 | 동작 (하네스) | UI 흐름 전체 | 테스트별 UUID 저장소 | UI AC 전제 |
| CardIssuanceView | 동작 (조건부 렌더·잠금·접근성) / 연출은 표현 | CardIssuanceFlowTests (XCUITest) | 식별자 셀렉터, `test.*` 진단 | AC-1~7, 16, 19, 20 |
| 보충·손상 UI | 동작 (E2E) | CardStorageFlowTests | 시드 + 테스트 쪽 리터럴 | AC-10, AC-14(UI) |
| PassFace 외형, 슬롯 연출, PassDots | 표현 — 검증 대상 아님 (접근성 계약만 AC-19에서, 에셋 존재만 PassFaceAssetTests에서 확인) | — | — | — |

### 주의사항 (red-writer·구현용)
- 연타 직렬화: phase 가드가 첫 await보다 앞에 있으므로 결정적이다. `untilSuspended()`로 sleep 진입을 기다린 뒤 재호출한다.
- AC-8은 순차 난수를 쓴다. 고정 난수를 쓰면 아무 결함도 잡지 못한다.
- AC-18 (a)는 standardDuration을 주입하지 않는다. 그래야 0.9초 상한 상수 자체를 검증한다.
- AC-16은 `test.*`를 제외한 요소의 label/value를 순회한다. value가 String이 아닐 수 있으므로 `as? String`으로 거른다.
- AC-14(UI) 기대 바이트는 UI 테스트 쪽 리터럴로 만든다. UI 테스트 타깃은 앱 모듈을 import할 수 없다.
- AC-19 포커스 바인딩과 실제 VoiceOver 낭독은 자동으로 검증할 수 없다. 수동 확인으로 남기고 trust-ledger에 기록한다.
- AC-9의 "햅틱 0회"는 AppModel이 햅틱에 의존하지 않으므로 구조적으로 보장된다. UI의 AC-10 `test.hapticCount == "0"`이 실제 검증을 맡는다.
