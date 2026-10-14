# 설계 초안: 마이페이지 (card FR-5), 시안 EPnQQ 대응 (2회차)

### 설계 규모
**중형.** 기존 자리표시 화면 1개를 실제 화면으로 바꿉니다. 그 밖에 records 집계 API 1개, 목적지 1개, UI 테스트 시드 1개를 추가합니다. 운영 파일은 신규 3개, 수정 4개입니다. PassFace와 RootView는 이번에 손대지 않습니다.

### 배경 및 목적
- 메인의 `open.profile`은 지금 제목만 있는 자리표시(`screen.profile`)로 이동합니다(`DestinationScreen.swift:14-19`).
- 기록은 하루 요약(`RecordSection.swift:86-91`)만 있고 누적 집계가 없습니다.
- 목표
  - 시안의 요소 순서와 문구를 맞춥니다.
  - 카드는 공통 PassFace와 PassIdentity를 씁니다.
  - 통계는 records 집계만 읽습니다.
  - 화면은 읽기 전용입니다.
  - W10(카드 꾸미기)과 합칠 때의 절차를 정해 둡니다.

### 요구사항 및 수용 기준
- PRD(`/Users/bonseung/Documents/ChatGPT/new-w11/.dev/feat-my-page/prd.md`)를 그대로 따릅니다.
  - [Must] FR-5, FR-5.1~5.10, BR-1~7
  - [Should] FR-5.11, QE-1, QE-2
  - AC-1~AC-33
- 이번 회차 결정으로 다음을 재정의하거나 이연합니다(근거는 아래 "AC 매핑").
  - **AC-5**: 지금 PassFace로는 성립하지 않습니다. 이번에는 `profile.card` 존재, 라벨 "집중동행카드", `FM-` 미포함만 검증합니다. 카드 안 문구 "나를 위한 시간, 한 장으로."와 칩·비접촉 식별자는 W10 합류 후 검증합니다(trust-ledger에 판정 기록).
  - **AC-14**: "CardSnapshot에 집계 관련 필드(count, minutes, summary, journeys, total 등)가 없다"로 다시 정의합니다. 필드 개수는 단언하지 않습니다. W10이 `style` 필드를 추가하기 때문입니다.
  - **AC-29, AC-31**: 단위 테스트 연쇄로만 검증하고, 실제 앱에서는 도달할 수 없다는 근거를 기록합니다.

---

### 코드 탐색으로 확인한 핵심 제약

1. **유효하지 않은 기록이 있는 상태에는 실제 앱에서 도달할 수 없습니다.**
   - 읽을 때: `SnapshotCodec.decode`가 `state.validate()`를 부르고(`SnapshotCodec.swift:31`), 이 검증이 records까지 확인합니다(`AppSnapshot.swift:74-75`). 실패하면 `AppModel.loadSnapshot`이 `.failed(...)`로 끝나 저장 오류 화면으로 갑니다(`AppModel.swift:131-132`).
   - 쓸 때: `persist`는 `launchRoute()`를 거치고(`AppModel.swift:152`), `LocalSnapshotStore.save`도 검증합니다(`LocalSnapshotStore.swift:93`).
   - 따라서 FR-5.10 실패 경로는 방어 코드입니다. AC-29~31은 단위 연쇄로 검증합니다. "records 실패 → `ProfileStats.from` → `.unavailable` → `ProfileStatsDisplay` '-'" 순서입니다.
2. **W10 실측** (`/Users/bonseung/.codex/worktrees/w10-card-customization/new`)
   - 카드 꾸미기는 목적지 push가 아니라 다음 구조입니다.
     - `RootView`의 `@State customization`, `showsCustomization`
     - `.fullScreenCover`(`RootView.swift:39-60`)
     - 메인 버튼 `open.cardCustomization`이 `model.beginCardCustomization()`을 호출(`RootView.swift:147-153`, `AppModel.swift:216-220`)
   - `Destination.cardStudio`는 W10에 없습니다.
   - W10은 PassFace를 `PassFace(style:)`로 다시 작성했습니다. 메인에서 `PassFace(style: model.currentCardStyle)`로 쓰고(`RootView.swift:147`), `currentCardStyle`은 `AppModel.swift:235`에 있습니다. `CardSnapshot`에는 `style` 필드가 추가됐습니다(`CardSection.swift:7`).
   - W10은 `DestinationScreen`과 `Destination` enum을 바꾸지 않습니다. 실제로 충돌할 수 있는 곳은 `RootView`와 `UITestBootstrap`입니다.
3. **지금 PassFace는 시안과 다릅니다.** "나를 위한 시간, 한 장으로." 문구가 없고 이름이 좌하단에 있습니다(`PassFace.swift:36-53`). 사용자 결정에 따라 이번에는 수정하지 않습니다. 시안과의 차이는 W10 합류 때 해소됩니다.
4. **이번 변경으로 깨지는 기존 테스트가 있습니다.** `Phase1FlowTests.swift:161-185`는 마이페이지 화면의 버튼이 내비게이션 버튼 1개뿐이라고 단언합니다. 새 화면에는 행 버튼 2개가 생기므로 수정해야 합니다. `Phase1FlowTests.swift:43-70`과 `PreparationFlowUITests.swift:102-117`은 "완료"가 들어간 **버튼** 수만 셉니다. "완료한 여정"은 버튼이 아닌 정적 텍스트라서 영향이 없습니다.
5. **새 파일은 자동으로 프로젝트에 포함됩니다.** `PBXFileSystemSynchronizedRootGroup` 구조(`project.pbxproj:23-25`)라 프로젝트 파일 수정이 필요 없습니다.

---

### 변경 범위
- 영향 모듈: records(`RecordSection`), 내비게이션(`Destination`, `DestinationScreen`), 마이페이지(신규), DEBUG 시드(`UITestBootstrap`)

**신규 (운영 3)**
- `ios/FocusMate/ProfileTimeText.swift`: 화면용, 접근성용 시간 표기 순수 함수
- `ios/FocusMate/AppModel+Profile.swift`: `ProfileMenuItem`, `ProfileStats`(`from(_:)` 포함), `profileStats`, `openFromProfile(_:)`
- `ios/FocusMate/ProfileView.swift`: `ProfileCopy`, `ProfileStatsDisplay`, `ProfileView`. 판독 스파이크가 실패할 때만 DEBUG 진단 overlay를 추가합니다.

**수정 (운영 4)**
- `ios/FocusMate/RecordSection.swift`: `RecordLifetimeSummary`, `lifetimeSummary()` 추가
- `ios/FocusMate/AppModel.swift`: `case cardStudio`(별도 행), 제목 "카드 꾸미기" 추가
- `ios/FocusMate/DestinationScreen.swift`: `.profile` 분기를 `ProfileView`로 연결
- `ios/FocusMate/UITestBootstrap.swift`(DEBUG): `rawSeeds`에 `profileRecords` 1항목 추가

**수정하지 않음 (명시)**
- `PassFace.swift`, `RootView.swift`, `FocusMateApp.swift`

**테스트 (신규 4, 수정 2)**
- 신규
  - `ios/FocusMateTests/RecordLifetimeSummaryTests.swift`
  - `ios/FocusMateTests/ProfileTimeTextTests.swift`
  - `ios/FocusMateTests/ProfileModelTests.swift`
  - `ios/FocusMateUITests/ProfileUITests.swift`
- 수정
  - `ios/FocusMateUITests/Phase1FlowTests.swift`(161-185)
  - `ios/FocusMateTests/JourneyStartModelTests.swift`(237 근처 1줄)

### 적용 컨벤션
CLAUDE.md는 없습니다. 아래는 기존 코드에서 확인한 관례입니다.
- **네이밍**
  - 기능별 모델 확장은 `AppModel+기능.swift`(`AppModel+JourneyStart.swift`)로 둡니다.
  - 화면 문구 상수는 `enum XxxCopy`(`CardIssuanceView.swift:3-15`)로 모읍니다.
  - 식별자는 `screen.{rawValue}`, `{화면}.{요소}`, 진단용은 `test.*` 형식입니다.
- **모델**
  - `@MainActor @Observable AppModel`입니다. 읽기 값은 확장의 계산 프로퍼티로 둡니다(`AppModel+JourneyStart.swift:5-20`).
  - 화면 이동은 `open(_:)`이 `path.append`합니다(`AppModel.swift:204-207`).
  - 중복 탭은 `path.last` 비교로 막습니다(`AppModel+JourneyStart.swift:37`).
- **records**: `try validate()` 후 계산하고, 실패는 throw로 알립니다(`RecordSection.swift:86-91`).
- **큰 글자 상한**: 화면 제목은 `.dynamicTypeSize(...DynamicTypeSize.accessibility1)`을 씁니다(`TimeSelectionView.swift:15-17`).
- **DEBUG 진단**: 1pt 투명 Text overlay를 씁니다(`DestinationScreen.swift:24-31`).
- **테스트**
  - 메서드 이름은 `testAC{n}_한국어설명`, 위에 `// 깨짐 명명:` 주석을 답니다(`RecordSectionTests.swift:9-10`).
  - UI 테스트는 `FocusMateUIHarness`(`UITestLaunchSupport.swift`)를 씁니다.
  - XXXL은 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` 인자로 켭니다(`LargeTextUITests.swift:77`).

---

### 상세 설계

#### 1. `ios/FocusMate/RecordSection.swift`: 누적 집계 (FR-5.1, BR-3, BR-4, FR-5.10)
- **현재**: `dailySummary(on:)`만 있습니다.
- **변경**
  - `lifetimeSummary()`를 추가합니다. `try validate()`로 전체 기록을 먼저 검증합니다.
  - 기록 하나라도 실패하면 그대로 throw합니다. 일부만 합산하지 않습니다(AC-30).
  - 통과하면 같은 `items`에서 `count`와 minutes 합계를 계산합니다(BR-4).
  - 예시, 진행 중, 포기 여정은 저장 단계에서 이미 빠지므로(`RecordSection.swift:53`) 따로 걸러낼 필요가 없습니다(BR-3).
- **시그니처**
  - `struct RecordLifetimeSummary: Equatable { let count: Int; let minutes: Int }`
  - `func lifetimeSummary() throws -> RecordLifetimeSummary`
- **고려사항**: 기존 `dailySummary`, 기록 저장, 메모 저장 API는 바꾸지 않습니다.

#### 2. `ios/FocusMate/ProfileTimeText.swift` (신규): 시간 표기 (BR-1, BR-2, BR-7)
- **규칙**
  - M < 60이면 `"\(M) min"` / `"\(M)분"`
  - 나머지 R == 0이면 `"\(H) h"` / `"\(H)시간"`
  - 그 외는 `"\(H) h \(R) min"` / `"\(H)시간 \(R)분"`
- 문자열 보간만 씁니다. 로캘이나 NumberFormatter를 쓰지 않으므로 천 단위 구분 기호가 생기지 않습니다.
- **시그니처**: `enum ProfileTimeText { static func display(minutes: Int) -> String; static func spoken(minutes: Int) -> String }`
- **고려사항**
  - 음수는 유효한 기록에서 나올 수 없으므로 정의하지 않습니다(가정).
  - 마이페이지 전용입니다. 다른 화면의 "분" 표기는 바꾸지 않습니다.

#### 3. `ios/FocusMate/AppModel.swift`: 목적지 `cardStudio` 자리표시 (FR-5.8)
- **현재**: `case preparation, records, settings, profile, time`(5행)과 title switch(8-14행)
- **변경**
  - 6행 다음에 `case cardStudio`를 **별도 행**으로 추가합니다.
  - title switch 끝에 `case .cardStudio: "카드 꾸미기"`를 추가합니다.
  - W10은 이 enum을 바꾸지 않습니다. W10의 `AppModel.swift` 변경은 212행 이후 확장에 추가하는 것이라 이번 변경과 겹치지 않습니다.
- **영향**
  - `Destination.mainMenu`(`AppModel+JourneyStart.swift:43`)는 그대로 4개입니다(AC-28).
  - `AppFoundationTests.swift:220`의 `allCases` 루프는 영향이 없습니다.

#### 4. `ios/FocusMate/AppModel+Profile.swift` (신규): 마이페이지 읽기, 이동 API
- **`ProfileStats.from(_:)`** (순수 매핑)
  - 입력이 `nil`이면 `.unavailable`입니다.
  - 그 외에는 `try records.lifetimeSummary()`를 시도해 성공하면 `.loaded`, throw하면 `.unavailable`입니다.
  - 저장소에 접근하지 않습니다. AC-31의 단위 근거가 이 점입니다.
- **`AppModel.profileStats`**
  - `ProfileStats.from(snapshot?.records)`에 위임만 하는 계산 프로퍼티입니다.
  - `@Observable`이 snapshot 변경을 추적하므로 기록이 추가되면 다음 렌더링에 반영됩니다(AC-17).
- **`openFromProfile(_:)`**
  - `path.last == .profile`일 때만 `open(item.destination)`을 호출합니다. 연타하면 한 번만 쌓입니다.
  - 결과 경로는 `[.profile, .cardStudio]` 또는 `[.profile, .settings]`이고, 시스템 뒤로 동작으로 마이페이지에 돌아옵니다(AC-25, AC-27).
- **시그니처**
  - `enum ProfileMenuItem { case customize, settings; var destination: Destination }`
    - customize는 `.cardStudio`, settings는 `.settings`로 연결됩니다.
  - `enum ProfileStats: Equatable { case loaded(RecordLifetimeSummary), unavailable; static func from(_ records: RecordSection?) -> ProfileStats }`
  - `extension AppModel { var profileStats: ProfileStats { get }; @discardableResult func openFromProfile(_ item: ProfileMenuItem) -> Bool }`
- **고려사항**
  - `CardSnapshot`에는 아무것도 추가하지 않습니다(AC-14).
  - 파일 머리 주석에 W10 합류 절차(아래 "W10 합류 절차")의 요약과 경로를 적습니다.

#### 5. `ios/FocusMate/ProfileView.swift` (신규): 마이페이지 화면
**구성 타입**
- **`enum ProfileCopy`**
  - headline "내 시간에, 내 취향을.", subhead "한 장으로 함께하는 나만의 여정"
  - cardTagline "모든 몰입 여정에 함께"
  - journeysLabel "완료한 여정", timeLabel "함께한 시간"
  - statsError "기록을 불러오지 못했어요", unavailableValue "-"
  - 카드 이름은 `PassIdentity.displayName`을 씁니다. 행 이름은 `Destination.cardStudio.title`과 `Destination.settings.title`을 씁니다.
- **`struct ProfileStatsDisplay: Equatable`** (순수 매핑, 단위 테스트 대상)
  - `init(_ stats: ProfileStats)`
  - 프로퍼티: `journeysText`, `timeText`, `journeysAccessibilityLabel`, `timeAccessibilityLabel`, `errorMessage: String?`
  - `.loaded(c, m)`일 때
    - 화면 값: `"\(c)"`, `ProfileTimeText.display(m)`
    - 접근성 라벨: `"완료한 여정, \(c)회"`, `"함께한 시간, \(spoken(m))"`
    - errorMessage: nil
  - `.unavailable`일 때
    - 화면 값: `"-"`, `"-"`
    - 접근성 라벨: 항목 이름만, 즉 `"완료한 여정"`, `"함께한 시간"`(사용자 결정)
    - errorMessage: `ProfileCopy.statsError`
- **`@MainActor struct ProfileView: View`**
  - 프로퍼티: `let model: AppModel`, `let onCustomize: () -> Void`
  - `onCustomize`를 주입받는 이유: W10 합류 때 "카드 꾸미기" 진입 방식이 push에서 fullScreenCover 세션으로 바뀝니다. 이렇게 하면 ProfileView 본문은 바꾸지 않고 주입하는 쪽만 고치면 됩니다.

**뷰 구조** (위에서 아래 순서, 하단 고정 요소 없음. W02 교훈 반영)
```
ScrollView {
  VStack(alignment: .leading, spacing: 0) {
    headline · subhead · PassFace() · cardName · cardTagline · Divider
    customizeRow · stats(+statsError) · Divider · settingsRow
  }.padding(.horizontal, 24).padding(.vertical, 32)
}
.background(ProfileLayout.background.ignoresSafeArea())
.navigationBarTitleDisplayMode(.inline)
.toolbarRole(.editor)            // 뒤로 버튼은 chevron만 (이전 제목 "Focus Mate" 숨김)
.toolbar { ToolbarItem(placement: .topBarLeading) { 제목 Text } }
```
- **제목**
  - `Text(Destination.profile.title).font(.title2.bold()).dynamicTypeSize(...DynamicTypeSize.accessibility1)`
  - `.accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.profile")`
  - 글자 크기 상한은 `TimeSelectionView.swift:15-17`의 선례를 따릅니다. 내비게이션 바 높이가 고정이라 상한이 없으면 큰 글자에서 잘리고 뒤로 버튼 영역을 압박하기 때문입니다.
  - `navigationTitle`은 설정하지 않습니다. 가운데에 제목이 한 번 더 나오는 것을 막기 위해서입니다.
- **카드**
  - `PassFace().frame(maxWidth: .infinity).accessibilityIdentifier("profile.card")`
  - 라벨 "집중동행카드"는 PassFace가 직접 붙입니다(`PassFace.swift:19`).
- **카드 라벨**
  - `Text(PassIdentity.displayName)`에 `profile.cardName`
  - `Text(ProfileCopy.cardTagline)`에 `profile.cardTagline`
- **행** (private `ProfileMenuRow(systemImage:title:identifier:action:)`)
  - `Button` + `.buttonStyle(.plain)`
  - label 구성: `HStack(spacing: 16) { Image.frame(width: 24); Text(title); Spacer(minLength: 8); Image("chevron.right").foregroundStyle(.secondary) }`
  - `.padding(.vertical, 20).frame(minHeight: 44).contentShape(Rectangle())`
  - 아이콘은 `.accessibilityHidden(true)`, 버튼은 `.accessibilityLabel(title)`(AC-23)
  - 액션: customize는 `onCustomize()`, settings는 `model.openFromProfile(.settings)`
- **통계** (private `ProfileStatView`)
  - `VStack(alignment: .leading, spacing: 8) { Text(value).accessibilityIdentifier("\(id).value"); Text(label) }`
  - `.accessibilityElement(children: .ignore).accessibilityLabel(a11yLabel).accessibilityIdentifier(id)`. VoiceOver에서 한 요소로 읽힙니다(AC-18).
  - 배치: `@Environment(\.dynamicTypeSize)`가 `isAccessibilitySize`이면 `AnyLayout(VStackLayout(alignment: .leading, spacing: 24))`, 아니면 `AnyLayout(HStackLayout(alignment: .top, spacing: 16))`입니다. 각 칸은 `.frame(maxWidth: .infinity, alignment: .leading)`입니다.
  - 세로 배치에서도 여정이 위, 시간이 아래라서 AC-2 순서가 유지됩니다.
  - 실패 안내: `errorMessage`가 있을 때만 `Text(...).font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("profile.statsError")`를 통계 아래 12pt에 둡니다(AC-32).
- **애니메이션**: `withAnimation`, `.animation`, `.transition`을 쓰지 않고 `accessibilityReduceMotion`도 읽지 않습니다(AC-21).
- **쓰기 없음**: `save`, `supplementCardIfNeeded`, `recordCompletion`을 호출하지 않습니다(FR-5.4).
- **스파이크 실패 시 대체안** (T5 첫 단계 결과에 따라 결정)
  - `profile.stat.*.value` 하위 노드가 XCUITest에 노출되지 않으면 DEBUG 진단을 추가합니다.
  - 형태: `#if DEBUG .overlay(alignment: .bottomLeading) { Text("통계 진단").accessibilityValue(json).accessibilityIdentifier("test.profileStats").font(.system(size: 1)).foregroundStyle(.clear).allowsHitTesting(false) }`
  - json 예: `{"journeys":"3","time":"1 h 5 min"}`
  - `DestinationScreen.swift:24-31`과 같은 패턴입니다. `allowsHitTesting(false)`를 붙여 행 탭을 가로채지 않게 합니다.

#### 6. `ios/FocusMate/DestinationScreen.swift`: 분기 연결
- **현재**: Group 전체에 `.padding(24)`, `.navigationTitle`, `.inline`이 걸려 있습니다(22-23행).
- **변경**
  - `body` 맨 앞에서 분기합니다: `if destination == .profile { ProfileView(model: model, onCustomize: { model.openFromProfile(.customize) }) } else { 기존 Group 체인 그대로 }`
  - `.cardStudio`는 기존 default 분기를 그대로 탑니다. 그래서 `Text("카드 꾸미기")` + `screen.cardStudio` 자리표시가 자동으로 나옵니다(AC-24, AC-33).
- **W10 충돌**: W10은 이 파일을 바꾸지 않으므로 충돌이 없습니다.

#### 7. `ios/FocusMate/UITestBootstrap.swift` (DEBUG): 기록 시드
- **변경**: `rawSeeds`(122-132행)에 `"profileRecords"` 1항목을 추가합니다.
  - 생성: `state(cards: #"{"id":"FM-12345678","issuedAt":"2026-10-13T09:00:00Z"}"#, records: …)`
  - 기록 3건
    - id: `journey-a`, `journey-b`, `journey-c`
    - minutes: 25, 25, 15
    - completedAt: `2026-10-13T03:00:00Z`, `02:00`, `01:00`
    - date: `2026-10-13`
    - 나머지 필드: bus "버스2014", tag "독서", tagColor "#12ABef", task "책 한 챕터 읽기", sound "빗소리", from "성수역", to "서울숲 입구", memo ""
  - 시드 이름은 `seeds` 집합에 `rawSeeds.keys`로 자동 포함됩니다(36행).
  - 시드 주석에 다음을 적습니다: "v2 형식이다. W10 합류 후에는 v3 migrate(카드 style 기본값)를 거쳐 decode된다."
- **W10 충돌**: W10도 이 파일을 수정합니다. 이번 변경은 딕셔너리에 항목 1개를 추가하는 것으로 한정해 충돌 범위를 줄입니다.

---

### 데이터 흐름
```
저장 파일 ─(SnapshotCodec.decode: 전체 검증)→ AppModel.snapshot
  └ snapshot.records ─→ ProfileStats.from(records)  [순수]
        └ RecordSection.lifetimeSummary()  (validate → count / sum)
  AppModel.profileStats = ProfileStats.from(snapshot?.records)   ← 쓰기 없음
        └ ProfileStatsDisplay(stats) ─ ProfileTimeText.display / spoken
              └ ProfileView: 값 Text · 접근성 라벨 · statsError
카드: PassFace() (라벨 = PassIdentity.displayName) · profile.cardName = PassIdentity.displayName
이동: 설정 행 → openFromProfile(.settings) → path.append
      꾸미기 행 → onCustomize() → (현재) openFromProfile(.customize) → .cardStudio 자리표시
뒤로: 시스템 back → NavigationStack이 path.removeLast
```

### W10 합류 절차 (FR-5.11 재기술: 리스크와 절차)
지금은 "카드 꾸미기" 행이 `cardStudio` 자리표시로 push합니다. W10은 fullScreenCover 세션 방식입니다. 따라서 **이 브랜치(W11)와 W10 중 두 번째로 머지하는 쪽**이 아래를 한 커밋으로 수행합니다. 어느 쪽이 먼저 머지되든 같은 절차입니다.

1. **RootView**: W10의 메인 버튼 액션(`RootView.swift:148-153`)을 `private func startCardCustomization()`으로 추출합니다. `.navigationDestination`에서 `DestinationScreen(destination:model:onCardCustomization: startCardCustomization)`처럼 넘깁니다.
2. **DestinationScreen**: `onCardCustomization: () -> Void` 프로퍼티를 추가합니다. `.profile` 분기에서 `ProfileView(model:onCustomize: onCardCustomization)`으로 넘깁니다. ProfileView 본문은 바꾸지 않습니다.
3. **cardStudio 자리표시 제거**
   - `Destination.cardStudio`와 title case를 삭제합니다.
   - `ProfileMenuItem.customize`를 삭제합니다. `openFromProfile`은 settings 전용으로 축소합니다.
4. **카드 외형**: ProfileView의 `PassFace()`를 `PassFace(style: model.currentCardStyle)`로 바꿉니다.
5. **테스트 갱신**
   - AC-24, AC-25, AC-33 UI·단위 테스트를 W10 진입 검증으로 교체합니다. 기준은 W10 꾸미기 화면 식별자의 출현과 닫은 뒤 `screen.profile` 복귀입니다.
   - 이연했던 AC-5 전체(내부 문구, 칩·비접촉 식별자)를 W10 PassFace 기준으로 검증하고 trust-ledger 판정을 갱신합니다. 식별자 부여 방식은 W10 PassFace 구조에 맞춰 그때 정합니다.
   - `profileRecords` 시드가 v3 migrate 후에도 decode되는지 단위 테스트를 다시 실행합니다.
6. **회귀**
   - `ProfileUITests`, `Phase1FlowTests`, `CardIssuanceFlowTests`, W10 꾸미기 UI 테스트를 전부 실행합니다.

**리스크**
- **XXXL에서 메인 진입**: W10 합류 후 메인에 PassFace(최대 354pt 폭)와 "카드 꾸미기" 버튼이 추가돼 화면이 길어집니다(`RootView.swift:147-153`). 메인은 ScrollView가 아니므로 XXXL에서 `open.profile`이 화면 밖으로 밀려 AC-20 진입 전제가 깨질 수 있습니다. 이 경우 메인 스크롤화를 별도 과제로 보고합니다(이번 범위 밖).
- **메인 진입점 중복**: 합류 후 메인 `open.cardCustomization`과 마이페이지 `profile.customize`가 같은 세션을 엽니다. 같은 `startCardCustomization()`을 쓰므로 동작은 일관됩니다.

---

### 디자인 스펙 구현 매핑 (시안 804px 폭을 402pt로 환산)

| 요소 | SwiftUI 구현 |
|---|---|
| 배경 | `ProfileLayout.background = Color(red: 0x0F/255, green: 0x10/255, blue: 0x12/255)`, `.ignoresSafeArea()`. 앱은 이미 `.preferredColorScheme(.dark)`(`RootView.swift:32`) |
| 좌우 여백 | `ProfileLayout.horizontal = 24`(시안 48px). 카드도 같은 여백으로 화면 폭에 맞춤 |
| 뒤로 | 시스템 back. `.toolbarRole(.editor)`로 chevron만 표시 |
| 화면 제목 | 툴바 leading, `.title2.bold()`, 상한 `accessibility1` |
| 큰 제목 | `.title2.bold()`, 내비게이션 바 아래 32pt |
| 보조 문구 | `.subheadline`, `.secondary`, 큰 제목과 8pt 간격 |
| 카드 | 현재 `PassFace()`. 비율 85.6:53.98(시안과 일치), 면 `#121416`, 테두리 `#51565A`, 오른쪽 점묘. 보조 문구와 32pt 간격. **카드 안 배치와 문구는 시안과 다르며 W10 합류 때 해소(리뷰 시 예외 표기)** |
| 카드 이름 / 부제 | `.title3.bold()` / `.subheadline` + `.secondary`. 카드와 16pt, 둘 사이 4pt 간격 |
| 구분선 | `Divider()`(hairline), 부제와 28pt 간격 |
| 행 | SF Symbols `pencil`, `slider.horizontal.3` + `Text(.body)` + `chevron.right`(`.secondary`). 아이콘 24pt 프레임, 글자와 16pt 간격, 위아래 20pt |
| 통계 값 | `.title.bold()`(28pt), `.lineLimit(1)`, `.minimumScaleFactor(0.6)` |
| 통계 라벨 | `.subheadline`, `.secondary`, 값과 8pt 간격 |
| 통계 배치 | 2열 `HStackLayout(spacing: 16)`(각 칸 maxWidth .infinity). 접근성 크기에서는 `VStackLayout` |
| 통계 위아래 | 행 아래 40pt, 다음 구분선 위 32pt |
| 실패 안내 | 통계 아래 12pt, `.subheadline`, `.secondary` |
| 하단 | 아래 padding 32pt. ScrollView가 safe area를 지켜 홈 인디케이터 영역이 비어 있음 |
| 애니메이션 | 없음 |

`ProfileLayout`은 `background`와 `horizontal` 두 상수만 둡니다. 나머지 간격은 위 표의 값을 VStack과 padding에 직접 씁니다.

---

### AC → 구성요소 / 테스트 매핑

| AC | 구성요소 | 검증 계층 | 테스트 방법 |
|---|---|---|---|
| 1 | ProfileView 제목 | UI | `screen.profile` 라벨이 "마이페이지" (seed ready) |
| 2 | 화면 순서 | UI | 식별자 10개의 frame을 `(round(minY), minX)`로 정렬. minY 차이 1pt 이내면 같은 행으로 보고 minX로 비교 |
| 3, 4 | ProfileCopy | UI, 단위 | 라벨 비교, 상수 비교 |
| 5 (축소) | PassFace 바깥 요소 | UI | `profile.card` 존재, label에 "집중동행카드" 포함, `FM-` 미포함. **내부 문구와 칩·비접촉은 W10 합류 후로 이연(trust-ledger)** |
| 6 | 전체 텍스트 | UI | seed profileRecords. `try app.snapshot()` 트리를 재귀 순회하며 label과 value를 수집하되 identifier가 `test.`로 시작하는 노드(`test.snapshot`에 카드 id 포함)는 제외. `FM-` 없음 |
| 7 | PassIdentity.displayName | 단위, UI | 단위: `PassIdentity.current(in:)?.name == PassIdentity.displayName`. UI: `profile.cardName`이 "집중동행카드" (발급 쪽은 기존 `CardIssuanceFlowTests:196`) |
| 8 | ProfileStatsDisplay | 단위, UI | `.loaded(0,0)`이면 "0", "0 min". UI(ready)에서 `profile.stat.*.value`(또는 대체안 `test.profileStats`), `profile.statsError` 없음 |
| 9 | lifetimeSummary, Display | 단위, UI | seed profileRecords에서 "3", "1 h 5 min" |
| 10, 11 | ProfileTimeText | 단위 | 7개 값 표 |
| 12 | lifetimeSummary | 단위 | 건수 N, 분 S, 두 번 호출해도 같은 결과 |
| 13 | 예시 기록 제외 | 단위 | RecordSection 수준, AppModel 수준(`recordCompletion(isExample: true)` 전후 `profileStats` 같음) |
| 14 (재정의) | ProfileStats, CardSnapshot | 단위 | `Mirror(CardSnapshot)` 라벨 중 `count/minutes/summary/journeys/total`을 포함하는 것이 없음(대소문자 무시). `model.profileStats == ProfileStats.from(model.snapshot?.records)` |
| 15 | 읽기 전용 | UI, 단위 | UI: `test.persistedBytes`를 열기 전, `XCTWaiter` 3초 후, 뒤로 간 후 비교. 단위: `open(.profile)` 후 `profileStats` 읽기에서 writeCalls 0 (`AppFoundationTests:232` 패턴) |
| 16 | 시스템 back | UI | 뒤로 버튼을 탭하면 `screen.profile` 없음, `open.profile` 존재, isHittable |
| 17 | profileStats 관찰 | 단위 | 임시 파일 AppModel(`RecordStorageTests:14-20` 패턴)에서 recordCompletion 25분 후 `.loaded(1,25)`. UI에서는 기록 추가 경로가 없음(W09 후속) |
| 18 | ProfileStatView 접근성 | UI(라벨), 수동(VoiceOver) | 라벨이 "완료한 여정, 3회", "함께한 시간, 1시간 5분" |
| 19 | PassFace 라벨 | UI | `profile.card.label`에 "집중동행카드" 포함, `FM-` 미포함 |
| 20 | ScrollView, AnyLayout | UI | 아래 "XXXL 검증 절차" |
| 21 | 애니메이션 없음 | 정적 확인, 수동 | 시뮬레이터에서 동작 줄이기를 실행 인자로 확실히 켤 수 없음. ProfileView에 `withAnimation/.animation/.transition/accessibilityReduceMotion` 0건을 리뷰 체크로 grep. 실기기 수동 확인 |
| 22 | display 포매터 | UI, 단위 | 값 텍스트에 "분", "시간" 없음, "min", "h" 있음 |
| 23 | ProfileMenuRow | UI | `profile.customize` 라벨 "카드 꾸미기", `profile.settings` 라벨 "설정". 둘 다 `buttons` 쿼리에 있고 isHittable |
| 24, 25 | onCustomize → cardStudio | 단위, UI | 단위: path `[.profile, .cardStudio]`. UI: `screen.cardStudio` 출현, 뒤로 가면 `screen.profile` (합류 때 교체) |
| 26, 27 | openFromProfile(.settings) | 단위, UI | 같은 방식, `screen.settings` |
| 28 | mainMenu | 단위 | `JourneyStartModelTests:237`에 `!mainMenu.contains(.cardStudio)` 추가 |
| 29 | 실패 표시 | 단위 연쇄 | 기록 1건 minutes 0인 RecordSection으로 `ProfileStats.from`이 `.unavailable`, Display가 "-"/"-", errorMessage "기록을 불러오지 못했어요", 접근성 라벨 "완료한 여정"/"함께한 시간". 카드는 ProfileView 구조상 통계 분기 밖이라 영향 없음(코드 리뷰 근거). 실제 앱 도달 불가 근거는 trust-ledger에 기록 |
| 30 | 전체 거부 | 단위 | 5건 중 1건이 유효하지 않으면 `lifetimeSummary()`가 `invalidMinutes(0)` throw, `ProfileStats.from`이 `.unavailable` |
| 31 | 읽기 전용(실패) | 단위, 근거 기록 | `ProfileStats.from`이 저장소에 접근하지 않는 순수 함수임을 시그니처로 보장. 유효하지 않은 기록은 decode·save 단계에서 차단돼 도달 불가(`SnapshotCodec.swift:31`, `LocalSnapshotStore.swift:93`, `AppModel.swift:152`) |
| 32 | statsError 조건부 | UI, 단위 | ready와 profileRecords 모두 `profile.statsError` 없음 |
| 33 | Destination.cardStudio | 단위, UI | `rawValue == "cardStudio"`, `title == "카드 꾸미기"`, `screen.cardStudio` (합류 때 제거) |

**시드 검증 (단위)**: `ProfileModelTests`에서 `SnapshotCodec.decode(Data(UITestBootstrap.rawSeeds["profileRecords"]!.utf8))`가 성공해야 합니다. 이어서 `currentCard?.id == "FM-12345678"`, `records.lifetimeSummary() == (3, 65)`를 확인합니다. Debug 빌드에서 `@testable import`로 접근합니다.

### XXXL 검증 절차 (AC-20, W02 교훈)
1. seed ready와 XXXL 인자로 실행하고 `test.dynamicTypeSize == "accessibility5"`를 확인합니다.
2. `open.profile`이 isHittable이면 탭합니다. 아니면 전제 실패로 기록합니다(메인은 스크롤이 없음, 리스크 참조).
3. 대상(`profile.card`, `profile.customize`, `profile.stat.journeys`, `profile.stat.time`, `profile.settings`)마다 다음을 확인합니다.
   - `reach()`(최대 3회 swipeUp/swipeDown)로 이동합니다.
   - isHittable만 믿지 않습니다. `frame.minY >= navigationBars.firstMatch.frame.maxY`이고 `frame.maxY <= app.windows.firstMatch.frame.maxY`인지, 즉 가시 영역 안에 **완전히** 들어오는지 단언합니다.
4. 두 행은 탭한 결과로 판정합니다. `screen.cardStudio`, `screen.settings`가 나타나는지 확인하고, 뒤로 가면 `screen.profile`이 다시 보여야 합니다.
5. 뒤로 버튼 식별: `navigationBars.firstMatch.buttons.firstMatch`를 씁니다. 그 identifier가 `screen.profile`이 아닌지(툴바 제목이 버튼으로 노출되지 않았는지), 내비게이션 바 안에서 가장 왼쪽(minX 최소)인지 단언한 뒤 탭합니다.
6. RootView 하단 좌측 DEBUG 진단 overlay(`RootView.swift:42-57`)가 행 탭을 가로챌 가능성이 있습니다. 1pt 글자라 가능성은 낮습니다. 이번에는 RootView를 수정하지 않습니다. 탭 판정이 실패하는 경우에만 `.allowsHitTesting(false)` 추가를 별도 과제로 올립니다(W10 충돌 지점이라 최소화).

### 구현 순서 (태스크 = AC 묶음 1건)

1. **[Must] T1 records 누적 집계**: AC-12, AC-13(섹션), AC-30(섹션) (의존: 없음)
   - 운영 파일 1개: `RecordSection.swift`
   - 테스트: `RecordLifetimeSummaryTests.swift`
2. **[Must] T2 시간 표기 포매터**: AC-10, AC-11, AC-22(단위) (의존: 없음)
   - 운영 파일 1개: `ProfileTimeText.swift`
   - 테스트: `ProfileTimeTextTests.swift`
3. **[Must] T3 UI 기록 시드**: AC-6, 9, 18, 22의 UI 전제 (의존: 없음)
   - 운영 파일 1개(DEBUG): `UITestBootstrap.swift`
   - 테스트: `ProfileModelTests.swift`(시드 decode). 기록 합계는 `items`로 직접 계산하므로 T1에 의존하지 않습니다.
4. **[Must] T4 목적지 cardStudio와 마이페이지 모델 API**: AC-13(모델), 14, 17, 24~27(모델), 28, 29(모델 연쇄), 30(모델), 31(단위 근거), 33 (의존: 1, 3)
   - 운영 파일 2개: `AppModel.swift`, `AppModel+Profile.swift`
   - 테스트: `ProfileModelTests.swift`, `JourneyStartModelTests.swift`(1줄)
   - T3과 같은 테스트 파일을 쓰므로 의존을 둡니다.
5. **[Must] T5 마이페이지 화면**: AC-1~4, 5(축소), 6~9, 15, 16, 18~21, 23~27(UI), 29(Display), 32 (의존: 2, 4)
   - 운영 파일 2개: `ProfileView.swift`, `DestinationScreen.swift`
   - **첫 단계 스파이크**: 하위 노드 `profile.stat.journeys.value`가 XCUITest에서 조회되는지 확인합니다. 조회되지 않으면 ProfileView에 DEBUG `test.profileStats` overlay를 추가합니다(운영 파일 수는 같음).
   - 테스트: `ProfileModelTests`(Display 케이스), `ProfileUITests.swift`
   - `Phase1FlowTests.swift:161-185`를 수정합니다. 목록에서 profile을 빼고, profile 버튼 구성(뒤로 + `profile.customize` + `profile.settings`)은 `ProfileUITests`에서 단언합니다.
6. **[Should] T6 W10 합류 절차 기록**: FR-5.11 (의존: 5)
   - 운영 파일 0개(주석만)
   - `AppModel+Profile.swift` 머리 주석에 합류 절차 1~6을 요약합니다.
   - AC-5 이연과 AC-29·31 근거를 trust-ledger 판정 기록에 남깁니다.

T1, T2, T3은 병렬로 진행할 수 있습니다.

### 의존성 및 영향도
- **새 외부 의존성**: 없습니다. iOS 17 API(`AnyLayout`, `toolbarRole`, `ToolbarItem(.topBarLeading)`)만 씁니다.
- **기존 구조와 다른 점**
  - 목적지 화면이 바깥 padding과 제목 체인 없이 독립 구성되는 첫 사례입니다.
  - 제목을 `navigationTitle` 대신 leading toolbar Text로 둡니다(시안의 좌측 정렬).
  - 화면이 이동 동작을 클로저(`onCustomize`)로 주입받습니다. 합류 때 주입하는 쪽만 바꾸기 위한 확장 지점입니다.
- **기존 테스트 영향**
  - `Phase1FlowTests:161-185`는 수정이 필요합니다.
  - `Phase1FlowTests:43-70`, `PreparationFlowUITests:102-117`은 그대로 통과할 것으로 예상합니다. 뒤로 가기에 `navigationBars.buttons.firstMatch`를 쓰는데, T5 스파이크에서 툴바 제목이 버튼으로 노출되지 않는지 함께 확인합니다.
  - 발급 화면은 PassFace를 수정하지 않으므로 영향이 없습니다.
- **하위 호환**: 저장 스키마 변경이 없습니다. `Destination` case 추가는 메모리 값이라 저장과 무관합니다.
- **W10 충돌 (실측 기준)**
  - `DestinationScreen.swift`, `Destination` enum: W10이 바꾸지 않으므로 충돌이 없습니다.
  - `AppModel.swift`: W10은 파일 끝에 확장을 추가하고, 이번 변경은 enum 행을 추가합니다. 위치가 달라 충돌이 없습니다.
  - `PassFace.swift`, `RootView.swift`: 이번에 수정하지 않습니다. 충돌을 피하는 것이 목적입니다.
  - `UITestBootstrap.swift`: 양쪽 모두 수정합니다. 이번 변경은 `rawSeeds` 항목 1개 추가로 한정합니다.
  - 합류 시점의 의미 변화는 위 "W10 합류 절차"를 따릅니다.

### 탐색 추가 항목
- `ios/FocusMate/TimeSelectionView.swift:15-17, 33` → 큰 글자 상한 선례(제목 accessibility1, 버튼 accessibility2)
- `ios/FocusMate/SnapshotCodec.swift:31` → decode 시 전체 검증(유효하지 않은 기록이면 시작 실패)
- `ios/FocusMate/AppSnapshot.swift:62-82` → `validate()`의 records 검증, `launchRoute()`
- `ios/FocusMate/LocalSnapshotStore.swift:92-102` → 저장 전 검증
- `ios/FocusMate/UITestBootstrap.swift:36, 116-132` → `seeds`/`rawSeeds`/`state()` 헬퍼(시드 추가 위치)
- `ios/FocusMate/RootView.swift:42-57` → DEBUG 진단 overlay(하단 좌측, 히트 테스트 리스크)
- `ios/FocusMateUITests/CardIssuanceFlowTests.swift:194-197` → hidden 하위 노드 노출 관찰(스파이크 근거)
- `ios/FocusMateUITests/Phase1FlowTests.swift:161-185` → 마이페이지 버튼 수 단언(수정 대상)
- `ios/FocusMateUITests/LargeTextUITests.swift:72-91` → XXXL 인자와 `reach()`
- `ios/FocusMateTests/RecordStorageTests.swift:14-20` → 임시 파일 AppModel 패턴(AC-17)
- `ios/FocusMateTests/AppFoundationTests.swift:232-256` → 쓰기 0 단언 패턴(AC-15, AC-31)
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMate/RootView.swift:7-8, 39-60, 147-153` → W10 fullScreenCover 세션, 메인 `PassFace(style:)`, `open.cardCustomization`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMate/AppModel.swift:215-235` → `beginCardCustomization()`, `currentCardStyle`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMate/CardSection.swift:7` → `CardSnapshot.style` 추가(AC-14 재정의 근거)

---

---

## Testability 평가 (test-architect)

> 평가는 1회차 초안 기준이며, 2회차는 이 평가의 보완(D-1 ProfileStats.from 추출, 시드 decode 테스트, XXXL 가시 영역·탭 결과 판정, 뒤로 버튼 식별)과 사용자 결정(PassFace 미수정, DEBUG 실패 주입 제거)을 반영했다. 제거된 컴포넌트(PassFace partIdentifierPrefix, profileStatsOverride)의 평가 항목은 해당 없음.


평가 대상: `/Users/bonseung/Documents/ChatGPT/new-w11/.dev/feat-my-page/design-draft.md`
대조한 코드: `PassFace.swift`, `RootView.swift`, `AppModel.swift`, `RecordSection.swift`, `UITestBootstrap.swift`, `CardIssuanceFlowTests.swift:194-197`, `LargeTextUITests.swift`

**테스트 러너는 있습니다.** 단위 테스트는 XCTest(`FocusMateTests`), UI 테스트는 XCUITest(`FocusMateUITests`)이고 둘 다 `scripts/check-ios.py test <ClassName...>`로 돌립니다. 스크립트가 실제로 있는지 확인했습니다. 새 파일은 폴더 동기화 그룹이라 따로 등록할 필요가 없습니다. 추가로 만들 하네스는 없습니다.

---

### 컴포넌트별 테스트 전략

#### 1. RecordSection.lifetimeSummary / RecordLifetimeSummary
- **레이어**: 동작 (상태·데이터 로직, 규약 §2 "높음")
- **러너**: XCTest `RecordLifetimeSummaryTests`
- **단위 테스트**: `RecordSection(items:)`를 바로 만듭니다(memberwise, 검증 없이 생성됨). 확인할 것은 세 가지입니다.
  - N건과 합 S를 맞게 계산하는지, 두 번 호출해도 같은지(AC-12)
  - 5건 중 1건이 `minutes: 0`이면 `invalidMinutes(0)`을 throw하는지(AC-30)
  - `recordingCompletion(isExample: true)` 전후 집계가 같은지(AC-13 섹션 수준)
- **통합 테스트**: 필요 없습니다.
- **모의 대상**: 없습니다. 순수 값 타입입니다.
- **격리 전략**: 기존 `dailySummary`와 별도 타입·별도 메서드라 기존 API에 영향이 없습니다.
- **AC 매핑**: AC-12, AC-13(섹션), AC-30(섹션)
- **소점수**: 10

#### 2. ProfileTimeText (display / spoken)
- **레이어**: 동작 (순수 포매터, "높음")
- **러너**: XCTest `ProfileTimeTextTests`
- **단위 테스트**: AC-10과 AC-11의 7개 값을 표로 묶어 하나의 테스트로 돌립니다. AC-22(분·시간 미포함)는 display 결과에 "분"과 "시간"이 없는지 단언합니다.
- **통합 테스트**: 필요 없습니다.
- **모의 대상**: 없습니다. 로캘이나 Formatter를 쓰지 않아 실행 환경에 따라 결과가 달라지지 않습니다.
- **격리 전략**: 정적 함수만 있습니다.
- **AC 매핑**: AC-10, AC-11, AC-22(단위)
- **소점수**: 10

#### 3. Destination.cardStudio / Destination.mainMenu
- **레이어**: 동작 (라우팅, "높음")
- **러너**: XCTest(`ProfileModelTests`, `JourneyStartModelTests:237`에 1줄 추가)
- **단위 테스트**:
  - `rawValue == "cardStudio"`, `title == "카드 꾸미기"`인지
  - `mainMenu`가 4개 그대로이고 `.cardStudio`를 포함하지 않는지
- **통합 테스트**: UI에서 `screen.cardStudio`가 나오는지 확인합니다(AC-24, AC-33 UI 쪽).
- **모의 대상**: 없습니다.
- **격리 전략**: enum case를 별도 행으로 추가합니다.
- **AC 매핑**: AC-28, AC-33
- **소점수**: 10

#### 4. AppModel.profileStats / ProfileStats
- **레이어**: 동작 (상태 셀렉터)
- **러너**: XCTest `ProfileModelTests`
- **단위 테스트**:
  - 임시 파일 store로 AppModel을 띄우고(`RecordStorageTests:14-20` 패턴) `recordCompletion(..., outcome: .alighted)` 25분을 넣으면 `.loaded(1,25)`(AC-17)
  - `recordCompletion(..., isExample: true)` 전후 `profileStats`가 같은지(AC-13 모델)
  - spy store로 `open(.profile)` 후 `profileStats`를 읽어도 `writeCalls == 0`인지(AC-15 단위, `AppFoundationTests:207-225` 패턴)
  - `Mirror(CardSnapshot)` 프로퍼티가 `["id","issuedAt"]`뿐인지(AC-14)
- **통합 테스트**: UI의 ready 시드와 profileRecords 시드로 검증합니다.
- **모의 대상**: `LocalSnapshotStore`의 `writeData` 클로저 spy. 이미 쓰고 있는 패턴입니다.
- **격리 전략**: 결함이 하나 있습니다.
  - `AppModel.snapshot`은 `private(set)`이고(`AppModel.swift:21`), 검증하는 codec으로만 채워집니다. 그래서 단위 테스트에서도 유효하지 않은 records를 AppModel에 넣을 수 없습니다.
  - 그 결과 `profileStats`의 "throw하면 `.unavailable`" 분기는 어느 테스트도 실행하지 못합니다.
  - 설계서 AC-30 행의 "`profileStats == .unavailable`(RecordSection 수준)"은 그대로는 작성할 수 없는 단언입니다.
- **AC 매핑**: AC-13(모델), AC-14, AC-15(단위), AC-17, AC-30(모델)
- **소점수**: 7. 아래 보완 1을 반영하면 10입니다.

#### 5. AppModel.openFromProfile / ProfileMenuItem
- **레이어**: 동작 (라우팅·가드)
- **러너**: XCTest `ProfileModelTests`
- **단위 테스트**:
  - main ready 상태에서 `open(.profile)` 후 `openFromProfile(.customize)`를 하면 path가 `[.profile, .cardStudio]`인지
  - 두 번 연속 호출해도 한 번만 쌓이는지(반환 false)
  - `path.last != .profile`이면 무시되는지
  - settings도 같은 방식으로 확인
  - `ProfileMenuItem.customize.destination == .cardStudio`(FR-5.11 경계)
- **통합 테스트**: UI에서 행을 탭해 목적지 식별자가 나오는지, 뒤로 가면 `screen.profile`로 돌아오는지(AC-24~27)
- **모의 대상**: 없습니다. `open`의 `launchState == .ready(.main)` 가드 때문에 카드와 정류장이 있는 ready 스냅샷 fixture가 필요합니다.
- **격리 전략**: 마이페이지는 `Destination` 값만 압니다. W10이 화면을 바꿔도 테스트에는 영향이 없습니다.
- **AC 매핑**: AC-24~27(모델)
- **소점수**: 9

#### 6. ProfileStatsDisplay
- **레이어**: 동작 (표시 모델 순수 매핑)
- **러너**: XCTest `ProfileModelTests`
- **단위 테스트**:
  - `.loaded(0,0)`이면 "0"/"0 min"이고 errorMessage가 nil인지(AC-8)
  - `.loaded(3,65)`이면 "3"/"1 h 5 min"과 접근성 라벨 "완료한 여정, 3회"/"함께한 시간, 1시간 5분"인지(AC-9, AC-18 라벨)
  - `.unavailable`이면 "-"/"-"와 statsError 문구인지(AC-29, AC-30 표시 쪽)
- **통합 테스트**: UI 값 판독으로 확인합니다(아래 7번).
- **모의 대상**: 없습니다.
- **격리 전략**: 입력이 `ProfileStats` 값 하나뿐이라 model과 무관하게 테스트됩니다. 질문 4의 실패 라벨은 결정되면 이 테스트에 고정합니다.
- **AC 매핑**: AC-8, AC-9, AC-18(라벨), AC-29, AC-30, AC-32(조건부 nil)
- **소점수**: 10

#### 7. ProfileView (조건부 렌더, 접근성 계약, 이동, 큰 글자 도달)
- **레이어**: 동작 (컴포넌트 동작과 화면 조립, "중간~낮음") + 표현(`ProfileLayout`, 색·여백·폰트는 범위 밖)
- **러너**: XCUITest `ProfileUITests`, `FocusMateUIHarness`
- **단위 테스트**: SwiftUI 마운트 러너(ViewInspector 등)가 없습니다. 판단 로직은 이미 6번으로 빠져 있으니 단위 대상에서 제외하는 것이 맞습니다.
- **통합(E2E) 테스트**:
  - ready 시드: AC-1~4, AC-8, AC-16, AC-23~27, AC-32
  - profileRecords 시드: AC-6, AC-9, AC-18, AC-22
  - `--fm-ui-profile-stats fail`: AC-29, AC-31
  - XXXL 실행 인자: AC-20
  - AC-15·31은 `test.persistedBytes` 전후 비교
- **모의 대상**: 집계 실패 상태는 DEBUG environment `profileStatsOverride`로 주입합니다. 실제 흐름으로는 도달할 수 없으므로 정당한 주입입니다.
- **격리 전략**:
  - 셀렉터는 접근성 식별자와 라벨을 씁니다. 프로젝트 관례이며 규약 §4의 data-testid에 해당합니다.
  - AC-2의 위치 정렬은 규약 §3에서 금지하는 "구조·순서 스냅샷"이 아닙니다. AC가 순서 자체를 계약으로 정했기 때문에 허용됩니다. 다만 같은 minY 비교에는 1pt 허용 오차를 두어야 합니다.
- **AC 매핑**: AC-1~4, AC-6, AC-8, AC-9, AC-15, AC-16, AC-18, AC-20, AC-22~27, AC-29, AC-31, AC-32
- **소점수**: 7. 위험 요소는 "평가 요청 항목"에 정리했습니다.

#### 8. PassFace (partIdentifierPrefix, 접근성 라벨, 문구 상수)
- **레이어**: 혼합
  - 동작: 바깥 라벨 "집중동행카드", `FM-` 미포함, 부품 식별자 존재
  - 표현: 이름 재배치, 문구 위치·크기·색. 범위 밖이며 시안 대조 리뷰로 확인합니다.
- **러너**: XCUITest(`ProfileUITests`, 회귀용 `CardIssuanceFlowTests`), XCTest(`PassFaceAssetTests`, 상수 확인)
- **단위 테스트**: `PassFace.brandText`, `purposeText` 상수 값만 확인합니다. 배치는 검증하지 않습니다.
- **통합 테스트**:
  - `profile.card.label`에 "집중동행카드"가 들어 있고 `FM-`이 없는지(AC-19)
  - `profile.card` 하위 staticText 라벨 집합과 `profile.card.contactless`/`.chip`이 있는지(AC-5)
- **모의 대상**: 없습니다.
- **격리 전략**: prefix 기본값이 nil이라 발급 화면의 식별자는 그대로입니다. 그래도 회귀 테스트로 `CardIssuanceFlowTests`를 함께 돌려야 합니다.
- **AC 매핑**: AC-5, AC-19, AC-7(UI 쪽)
- **소점수**: 7. 아래 위험 A를 참고하세요.

#### 9. UITestBootstrap (profileRecords 시드, `--fm-ui-profile-stats`) / RootView DEBUG 주입
- **레이어**: 테스트 인프라(동작)
- **러너**: XCTest로 직접 테스트할 수 있습니다. `UITestBootstrap.init?(arguments:applicationSupport:)`가 인자 배열과 URL을 받기 때문입니다(`UITestBootstrap.swift:14`).
- **단위 테스트**:
  - `"fail"`이면 `profileStatsOverride == .unavailable`
  - 그 외 값이면 `SetupIssue.invalidArguments` throw
  - profileRecords 시드 원본이 `SnapshotCodec.decode`를 통과하는지. 시드가 검증에 걸리면 앱이 저장 오류 화면으로 가서 UI 테스트 전체가 엉뚱한 이유로 실패하므로, 이 테스트를 먼저 두는 것을 권장합니다.
- **통합 테스트**: UI 실패 시나리오에서 함께 검증됩니다.
- **모의 대상**: 임시 applicationSupport 디렉터리
- **격리 전략**: `#if DEBUG`로 막혀 있어 RELEASE에는 영향이 없습니다. environment는 NavigationStack 바깥에 걸리므로 `navigationDestination` 화면까지 전달됩니다.
- **AC 매핑**: AC-6, AC-9, AC-18, AC-22, AC-29, AC-31의 전제
- **소점수**: 9

#### 10. DestinationScreen `.profile` 분기
- **레이어**: 동작(라우팅). 분기 자체는 단순합니다.
- **러너**: XCUITest(AC-1, AC-24의 자리표시)
- **AC 매핑**: AC-1, AC-24, AC-33(UI)
- **소점수**: 9
- **회귀**: `Phase1FlowTests:161-185`(버튼 수 단언)는 수정이 필요합니다. 설계서에 반영되어 있습니다.

#### 표현 레이어 (점수 대상 아님)
- 대상: `ProfileLayout` 간격 상수, 배경색, 폰트 크기, `minimumScaleFactor`, PassFace 외형 재배치, 구분선과 chevron 색
- 검증 수단: 사람의 시안 대조 리뷰(trust-ledger)
- 테스트에서 이 값들을 단언하지 않아야 합니다. 규약 §3과 §4의 게이트 함수 기준입니다.

---

### 평가 요청 항목

#### A. `accessibilityElement(children: .ignore)` 아래 하위 노드가 보인다는 가정의 위험 (위험도: 높음)
- **근거가 다른 메커니즘입니다.** `CardIssuanceFlowTests.swift:197`이 관찰한 것은 PassFace의 `.overlay { artwork.accessibilityHidden(true) }` 구조입니다. 통계 칸은 `VStack ... .accessibilityElement(children: .ignore)` 구조라서 같은 결과가 나온다는 보장이 없습니다.
- `PassFace.swift:13-14` 주석에는 "GeometryReader 쪽 children: .ignore는 내부 장식을 숨기지 못해"라고 적혀 있습니다. 다시 말해 이 프로젝트에서 `.ignore`의 노출 동작은 이미 한 번 예상과 다르게 나왔습니다.
- PassFace 내부의 `profile.card.contactless`와 `.chip`도 hidden 하위 트리 안에 붙는 식별자입니다. 하위 노드가 보이더라도 식별자까지 전달되는지는 따로 확인해야 합니다.
- **RED가 틀린 이유로 실패할 수 있습니다.** 노드가 조회되지 않으면 RED는 "기능 미구현"이 아니라 "하네스가 읽지 못함" 때문에 실패합니다. GREEN 이후에도 계속 빨간 상태로 남습니다.
- **권고**
  1. T5 RED보다 먼저, 판독만 확인하는 스파이크 1건을 돌려 노드마다 노출 여부를 확정합니다. 대상은 `profile.stat.journeys.value`, `profile.card.contactless`, `profile.card.chip`, 카드 하위 staticText입니다.
  2. 판독 헬퍼는 "노드 미노출"을 별도 메시지로 실패시켜, 단언 실패와 구분되게 합니다.
  3. 미노출이면 질문 3 (b)의 DEBUG 진단 `test.profileStats`로 바꿉니다. 이 경우 UI는 간접 검증이 되지만, 6번 `ProfileStatsDisplay` 단위 테스트가 값 생성을 직접 보증하므로 연쇄 검증은 유지됩니다.
  4. AC-5의 칩·비접촉 식별자가 노출되지 않으면 해당 부분은 trust-ledger로 내리고 그 결정을 기록합니다. 이 결정은 오케스트레이터나 사용자가 합니다.
- **AC-18의 "한 요소로 읽힌다"는 XCUITest로 증명할 수 없습니다.** 197행 관찰대로 숨긴 하위 노드도 트리에 나오므로, 트리만 보고는 "한 요소"를 판정할 수 없습니다. 자동 테스트는 라벨만 확인하고, 묶음 여부는 수동 VoiceOver로 확인합니다. 설계서의 trust-ledger 배정이 맞습니다.

#### B. XXXL 탭 정확도 (W02의 isHittable 오탐) (위험도: 중간)
- 설계서는 "하단 고정 요소가 없으니 W02 문제가 생기지 않는다"고 봤습니다. 하지만 가려지는 위치가 하단에서 상단으로 옮겨갈 뿐입니다.
  - `reach()`(최대 3회 swipeUp) 후 대상 행이 내비게이션 바 아래에 일부 걸칠 수 있습니다. 이때 `isHittable`가 true여도 탭이 바 쪽으로 빗나갈 수 있습니다.
  - `RootView`의 DEBUG overlay(`bottomLeading`, 1pt 투명 Text 4~6줄)에는 `allowsHitTesting(false)`가 없습니다. 면적이 작아 위험은 낮지만, 하단 좌측에 온 행을 가릴 수 있는 요소입니다.
- 큰 글자에서는 leading `ToolbarItem`의 `.title2.bold()` 제목이 크게 커집니다. 그래서 다음 두 가지 위험이 있습니다.
  - (1) 뒤로 chevron을 가리거나 밀어낼 수 있습니다.
  - (2) 제목이 `navigationBars.buttons`에 잡히면 `buttons.firstMatch`가 뒤로 버튼이 아니라 제목을 탭할 수 있습니다. 설계서도 이 부분을 "확인 필요"로 적어 두었습니다.
- **권고**
  1. AC-20 헬퍼를 강화합니다. `reach()` 후 `isHittable`에 더해, 대상 frame이 "창 frame에서 navigationBar frame을 뺀 영역" 안에 완전히 들어오는지도 단언합니다.
  2. 탭이 필요한 단언(AC-24·26, XXXL 뒤로 가기)은 탭 결과로 판정합니다. 즉 목적지 식별자가 나타나는지로 확인하고, `isHittable`만 믿지 않습니다.
  3. 뒤로 가기 헬퍼는 내비게이션 바 버튼 수와 라벨을 먼저 확인한 뒤 고릅니다. 실패할 때를 대비해 왼쪽 가장자리 스와이프 경로를 대안으로 둡니다.
  4. 툴바 제목에 `TimeSelectionView`처럼 `.dynamicTypeSize(...accessibility2)` 상한을 둘지는 설계 쪽에서 결정할 사항입니다. 이 결정은 architect에게 전달하는 권고입니다.
- 메인 화면은 ScrollView가 아니라서 XXXL에서 `open.profile`에 닿는다는 전제가 깨질 수 있습니다. 설계서는 이를 범위 밖 별도 보고로 처리했고, 타당합니다. 다만 그 경우 AC-20 테스트는 진입 단계에서 실패합니다. 실패 메시지가 원인을 구분해 보여 주도록 해야 합니다.

#### C. 시뮬레이터의 동작 줄이기와 VoiceOver 자동화 한계 (위험도: 낮음, 범위 확정 필요)
- **동작 줄이기**: 이 시뮬레이터에서 자동으로 켤 수단이 없습니다.
  - 시뮬레이터 실행 인자로 확실하게 켤 방법이 없고, `simctl ui`도 지원하지 않습니다.
  - `EnvironmentValues.accessibilityReduceMotion`은 읽기 전용이라 DEBUG 주입도 불가능합니다.
  - 다만 설계는 이 값을 아예 읽지 않고 애니메이션도 없어서, 같은 트리가 나오는 것이 구조상 보장됩니다.
  - 따라서 AC-21은 "정적 grep 확인과 실기기 수동 확인"으로 trust-ledger에 올리는 것이 맞습니다. 설계 결함이 아니므로 감점하지 않았습니다. 권고는 grep 확인을 리뷰 체크리스트에 고정 항목으로 넣는 것입니다.
- **VoiceOver**: XCUITest로 VoiceOver를 구동하거나 읽는 순서를 검증할 수 없습니다.
  - 자동으로 확인할 수 있는 것은 라벨 문자열(AC-18, AC-19)과 버튼 특성(AC-23)까지입니다. 읽기 순서, 한 요소 여부, 장식 비노출(QE-1)은 수동입니다.
  - 선택 보완으로 `XCUIApplication.performAccessibilityAudit(for: [.dynamicType, .hitRegion])`를 XXXL 시나리오에 붙일 수 있습니다. 다만 `.textClipped`는 `minimumScaleFactor` 때문에 오탐이 날 수 있으니 빼야 합니다.

#### D. 그 밖의 testability 보완 (재설계는 아니고 설계 보강)
1. **[필수] AC-30 모델 분기를 테스트할 수 있게 만듭니다.**
   - throw를 `.unavailable`로 바꾸는 매핑을 순수 함수로 빼 주세요. 예: `static func ProfileStats.from(_ records: RecordSection?) -> ProfileStats`
   - `AppModel.profileStats`는 이 함수에 위임만 합니다.
   - 그러면 "유효하지 않은 records → `.unavailable` → '-'" 연쇄가 모두 단위 테스트로 검증됩니다. 지금 구조에서는 `private(set) snapshot` 때문에 이 분기를 아무 테스트도 실행하지 못합니다.
2. **[권장] AC-6 수집은 `app.snapshot()` 트리 순회로 바꿉니다.**
   - 지금 방식은 `descendants(.any).allElementsBoundByIndex`로 한 요소씩 조회합니다.
   - 트리 순회는 한 번에 일관된 시점의 트리를 읽으므로 빠르고 안정적입니다. 숨긴 하위 노드까지 포함되므로 검사 범위도 더 넓습니다.
   - `test.` 접두 식별자 제외는 설계서대로 유지합니다.
3. **[권장] profileRecords 시드가 검증을 통과하는지 단위 테스트를 둡니다.** 9번 항목에서 설명했습니다.
4. **[권장] AC-2 정렬은 `(round(minY), minX)` 기준에 1pt 허용 오차를 둡니다.**

---

### Testability Score: 8/10 (동작 컴포넌트 기준)

- 순수 로직 층(1, 2, 3, 6)은 모두 10입니다. 의존성이 없고 AC 값이 표로 고정되어 있습니다.
- 모델 층(4, 5)에는 이미 쓰고 있는 store spy와 임시 파일 패턴이 있습니다. 감점 요인은 `.unavailable` 분기를 테스트할 수 없다는 점 하나이고, 보완 D-1로 해결됩니다.
- UI 층(7, 8)의 위험은 하위 노드 판독(A)과 XXXL 탭·뒤로 가기(B)입니다. 둘 다 스파이크와 헬퍼 보강으로 대응할 수 있고, DEBUG 진단이라는 대안도 설계에 이미 들어 있습니다.
- 자동화할 수 없는 항목(AC-18의 묶음 여부, AC-21, QE-1)은 플랫폼 한계입니다. trust-ledger 배정이 명시되어 있어 감점하지 않았습니다.

### 판정

**TESTABILITY PASS (8/10)**: 설계를 확정하고 red-green-refactor에 진입할 수 있습니다. 재설계는 필요 없습니다. 아래 조건은 진입 전이나 해당 태스크 첫 단계에서 처리해야 합니다.

1. **T4 진입 전 (architect 반영 권고)**: D-1의 `ProfileStats.from(_:)` 순수 매핑 추출. 이것이 없으면 AC-30의 모델 수준 테스트를 작성할 수 없습니다.
2. **T5 첫 단계**: A의 판독 스파이크로 노드마다 노출 여부를 확정하고, 그 결과로 질문 3의 (a)/(b)를 정합니다. 그 다음에 RED 테스트를 작성합니다.
3. **T5 UI 헬퍼**: B의 세 가지를 반영합니다. frame이 보이는 영역 안에 있는지 확인, 탭은 결과로 판정, 뒤로 가기 버튼을 명확히 식별합니다. 툴바 제목의 dynamicType 상한은 architect가 결정합니다.
4. **trust-ledger 확정**: AC-18의 "한 요소" 여부, AC-21, QE-1, AC-5의 칩·비접촉(미노출일 때)은 수동 확인으로 기록합니다.
5. **회귀 실행 대상**: `CardIssuanceFlowTests`, `PassFaceAssetTests`, `Phase1FlowTests`(수정 후), `PreparationFlowUITests`, `JourneyStartModelTests`

### 탐색 추가 항목
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/AppModel.swift:21`: `private(set) var snapshot`. 단위 테스트에서 유효하지 않은 records를 주입할 수 없다는 근거(D-1)
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/AppModel.swift:163-176`: `recordCompletion(_:outcome:isExample:timeZone:)` 실제 시그니처. AC-13과 AC-17 단위 테스트는 `outcome: .alighted`와 `timeZone`이 있어야 함
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/AppModel.swift:204-207`: `open`의 `.ready(.main)` 가드. 모델 테스트 fixture에 카드와 정류장이 있는 ready 상태가 필요함
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/RecordSection.swift:38-49`: memberwise `RecordSection(items:)`로 유효하지 않은 섹션을 바로 만들 수 있음(AC-30 섹션 단위)
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/PassFace.swift:13-20`: 노출 메커니즘이 hidden overlay이고, `.ignore`가 장식을 숨기지 못했다는 주석. 위험 A의 근거
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/RootView.swift:42-57`: DEBUG overlay(`bottomLeading`, `allowsHitTesting` 미지정)와 `test.dynamicTypeSize`. NavigationStack 바깥이라 마이페이지에서도 조회 가능
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/UITestBootstrap.swift:12-31`: `init?(arguments:applicationSupport:)`가 인자를 검증. 새 인자를 단위 테스트할 수 있는 지점
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMate/TimeSelectionView.swift:17-33`: `.dynamicTypeSize(...accessibility1/2)` 상한 선례. 툴바 제목 상한 권고의 근거
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMateUITests/LargeTextUITests.swift:84-91`: `reach()`가 isHittable만 판정함. 보이는 영역 확인을 추가할 위치
- `/Users/bonseung/Documents/ChatGPT/new-w11/ios/FocusMateTests/AppFoundationTests.swift:207-254`: `writeCalls` spy 패턴(AC-15 단위)