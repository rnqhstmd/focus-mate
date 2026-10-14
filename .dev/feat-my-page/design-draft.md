# 설계 초안: 마이페이지 (card FR-5) — 시안 EPnQQ 대응

### 설계 규모
**중형.** 기존 자리표시 화면 1개를 실제 화면으로 바꾸고, records 집계 API 1개, 목적지 1개, 공통 카드 뷰 1곳 수정, DEBUG 테스트 진입점 1개를 추가합니다. 운영 파일은 신규 3개, 수정 6개입니다.

### 배경 및 목적
- 메인의 `open.profile`은 지금 제목만 있는 자리표시(`screen.profile`)로 이동합니다(`DestinationScreen.swift:14-19`).
- 기록은 하루 요약(`RecordSection.swift:86-91`)만 있고 누적 집계가 없습니다.
- 목표
  - 시안의 요소, 순서, 문구를 1:1로 맞춥니다.
  - 카드는 PassFace와 PassIdentity를 써서 다른 화면과 같게 보입니다.
  - 통계는 records 집계만 읽습니다.
  - 마이페이지는 읽기 전용입니다.
  - 목적지 이름 `cardStudio`를 W10이 이어받을 경계로 둡니다.

### 요구사항 및 수용 기준
PRD(`/Users/bonseung/Documents/ChatGPT/new-w11/.dev/feat-my-page/prd.md`)를 그대로 따릅니다.
- [Must] FR-5, FR-5.1~5.10, BR-1~7
- [Should] FR-5.11, QE-1, QE-2
- AC-1~AC-33. 각 AC가 어느 구성요소와 테스트로 검증되는지는 아래 "AC 매핑"에 정리했습니다.

---

### 코드 탐색으로 확인한 핵심 제약

1. **유효하지 않은 기록이 있으면 앱 시작 단계에서 막힙니다.** 그래서 마이페이지의 집계 실패 상태는 실제 앱 흐름으로는 도달할 수 없습니다.
   - `SnapshotCodec.decode`가 `state.validate()`를 호출합니다(`SnapshotCodec.swift:31`). 이 검증에 records 검증이 포함됩니다(`AppSnapshot.swift:74-75`).
   - 그 결과 `AppModel.loadSnapshot`이 `.failed(.invalidState(.invalidRecords))`로 끝나고(`AppModel.swift:131-132`), 저장 오류 화면으로 갑니다.
   - 저장 경로도 막혀 있습니다. `persist`는 `launchRoute()`를 거치고(`AppModel.swift:152`), `LocalSnapshotStore.save`도 검증합니다(`LocalSnapshotStore.swift:93`). 메모리의 `model.snapshot`에 유효하지 않은 기록이 들어갈 길이 없습니다.
   - 결론: FR-5.10의 실패 경로는 방어용 코드입니다. AC-29~31은 단위 테스트(records, 표시 모델)를 기본으로 검증합니다. UI 테스트에서는 DEBUG 전용 주입 인자(`--fm-ui-profile-stats fail`)로 실패 상태를 강제해 렌더링과 저장 바이트 불변을 확인합니다(질문 2).
2. **PassFace가 시안과 다릅니다.** 지금 PassFace에는 "나를 위한 시간, 한 장으로." 문구가 없습니다. 이름도 좌하단에 19×scale 크기로 그려집니다(`PassFace.swift:51-53`).
   - 시안 EPnQQ와 승하차 시안 AdtS5(같은 폴더)는 모두 "칩 오른쪽에 이름, 그 아래 문구" 배치입니다. 웹 프로토타입의 공통 `.pass-face`에도 `pass-purpose` 문구가 있습니다(`designs/prototype/index.html:600`).
   - 따라서 최신 공통 카드 외형은 이 배치입니다. 공통으로 고치면 발급 화면 카드도 같이 바뀝니다(질문 1).
3. **PassFace의 접근성은 카드 전체를 한 요소로 읽힙니다.** 라벨은 "집중동행카드", 내부 그림은 `accessibilityHidden` 처리돼 있습니다(`PassFace.swift:13-20`).
   - 기존 테스트 주석에 "iOS 27 XCUITest는 accessibilityHidden 하위 요소도 자동화 트리에 노출한다"는 관찰이 남아 있습니다(`CardIssuanceFlowTests.swift:197`).
   - AC-5(카드 내부 문구와 부품 식별자)와 통계 값 판독(AC-8, AC-9)은 이 관찰에 기대어 설계했습니다(질문 3).
4. **이번 변경으로 깨지는 기존 테스트가 있습니다.**
   - `Phase1FlowTests.swift:161-185`는 마이페이지에서 `app.buttons.count == 내비게이션 버튼 수(1)`를 단언합니다. 새 화면에는 버튼 2개(`profile.customize`, `profile.settings`)가 생기므로 이 테스트를 고쳐야 합니다.
   - `Phase1FlowTests.swift:43-70`, `PreparationFlowUITests.swift:102-117`은 "완료"가 들어간 **버튼** 수와 뒤로 가기만 확인합니다. "완료한 여정"은 버튼이 아닌 정적 텍스트라 영향이 없습니다.
5. **Xcode 프로젝트 파일은 고치지 않아도 됩니다.** `PBXFileSystemSynchronizedRootGroup`(`project.pbxproj:23-25`)이라 새 파일은 폴더에 두기만 하면 자동으로 포함됩니다.

---

### 변경 범위
- 영향 모듈: records(`RecordSection`), 내비게이션(`Destination`, `DestinationScreen`), card(`PassFace`), 마이페이지(신규), DEBUG 테스트 부트스트랩

**신규 생성 (운영 3)**
- `ios/FocusMate/ProfileTimeText.swift`: 화면용·접근성용 시간 표기 순수 함수
- `ios/FocusMate/AppModel+Profile.swift`: `ProfileMenuItem`, `ProfileStats`, `profileStats`, `openFromProfile(_:)`
- `ios/FocusMate/ProfileView.swift`: `ProfileCopy`, `ProfileLayout`, `ProfileStatsDisplay`, `ProfileView`, DEBUG `ProfileStatsOverrideKey`

**수정 (운영 6)**
- `ios/FocusMate/RecordSection.swift`: `RecordLifetimeSummary`, `lifetimeSummary()` 추가
- `ios/FocusMate/AppModel.swift`: `case cardStudio`, 제목 "카드 꾸미기"
- `ios/FocusMate/DestinationScreen.swift`: `.profile` 분기를 `ProfileView`로 연결
- `ios/FocusMate/PassFace.swift`: 문구 추가, 이름 재배치, 부품 식별자 접두어 파라미터
- `ios/FocusMate/UITestBootstrap.swift`(DEBUG): 기록 시드, `--fm-ui-profile-stats` 인자
- `ios/FocusMate/RootView.swift`(DEBUG 블록만): 집계 결과 덮어쓰기 값을 environment로 주입

**테스트 (신규 4, 수정 1)**
- 신규
  - `ios/FocusMateTests/RecordLifetimeSummaryTests.swift`
  - `ios/FocusMateTests/ProfileTimeTextTests.swift`
  - `ios/FocusMateTests/ProfileModelTests.swift`
  - `ios/FocusMateUITests/ProfileUITests.swift`
- 수정
  - `ios/FocusMateUITests/Phase1FlowTests.swift`(161-185)

### 적용 컨벤션
CLAUDE.md는 없습니다. 아래는 기존 코드에서 확인한 관례입니다.
- **네이밍**
  - 타입은 UpperCamel, 기능별 모델 확장은 `AppModel+기능.swift`(`AppModel+JourneyStart.swift`)입니다.
  - 화면 문구 상수는 `enum XxxCopy`(`CardIssuanceView.swift:3-15`)로 둡니다.
  - 식별자는 `screen.{rawValue}`, `{화면}.{요소}`, 진단은 `test.*`입니다.
- **모델**
  - `@MainActor @Observable AppModel`입니다. 읽기 값은 확장의 계산 프로퍼티로 둡니다(`journeyOrigin` 등, `AppModel+JourneyStart.swift:5-20`).
  - 이동은 `open(_:)`이 `path.append`하고(`AppModel.swift:204-207`), 중복 탭은 `path.last` 비교로 막습니다(`AppModel+JourneyStart.swift:37`).
- **records**
  - 집계는 `try validate()` 후 계산하고 `throws`로 실패를 알립니다(`dailySummary`, `RecordSection.swift:86-91`).
- **뷰**
  - 정적 문구 단언은 `XCUIElement.label`로 합니다. 값 단언이 필요하면 `.accessibilityValue`를 씁니다(`RootView.swift:125`).
  - DEBUG 진단은 1pt 투명 Text overlay 패턴입니다(`DestinationScreen.swift:24-31`).
- **테스트**
  - 메서드 이름은 `testAC{n}_한국어설명`, 바로 위에 `// 깨짐 명명:` 주석을 답니다(`RecordSectionTests.swift:9-10`).
  - UI 테스트는 `FocusMateUIHarness`(`UITestLaunchSupport.swift`)를 씁니다.
  - 큰 글자 실행 인자는 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`입니다(`LargeTextUITests.swift:77`).

---

### 상세 설계

#### 1. `ios/FocusMate/RecordSection.swift`: 누적 집계 (FR-5.1, BR-3, BR-4, FR-5.10)
- **현재**: `dailySummary(on:)`만 있습니다. 검증에 실패하면 throw합니다.
- **변경**
  - `dailySummary`와 같은 방식으로 `lifetimeSummary()`를 추가합니다.
  - 먼저 `try validate()`로 전체를 검증합니다. 하나라도 유효하지 않으면 그대로 throw하므로 일부만 합산하는 경우가 생기지 않습니다(AC-30).
  - 통과하면 `items.count`와 `items` minutes 합계를 같은 배열에서 계산합니다(BR-4).
  - 예시, 진행 중, 포기한 여정은 `recordingCompletion`이 아예 저장하지 않으므로(`RecordSection.swift:53`) 따로 걸러낼 필요가 없습니다(BR-3).
- **시그니처**
  - `struct RecordLifetimeSummary: Equatable { let count: Int; let minutes: Int }`
  - `func lifetimeSummary() throws -> RecordLifetimeSummary`
- **고려사항**: 기존 `RecordDaySummary`와 의미가 달라 타입을 따로 둡니다. 기존 API는 바꾸지 않습니다.

#### 2. `ios/FocusMate/ProfileTimeText.swift` (신규): 시간 표기 (BR-1, BR-2, BR-7)
- 상태 없는 순수 함수만 둡니다.
  - M < 60: `"\(M) min"` / `"\(M)분"`
  - R == 0: `"\(H) h"` / `"\(H)시간"`
  - 그 외: `"\(H) h \(R) min"` / `"\(H)시간 \(R)분"`
- 문자열 보간만 쓰고 `NumberFormatter`나 로캘 형식은 쓰지 않습니다. 그래서 천 단위 구분 기호가 붙지 않습니다.
- **시그니처**
  - `enum ProfileTimeText { static func display(minutes: Int) -> String; static func spoken(minutes: Int) -> String }`
- **고려사항**
  - 음수는 유효한 기록에서 나올 수 없으므로 정의하지 않습니다(가정).
  - 마이페이지 전용입니다. 다른 화면의 "분" 표기는 건드리지 않습니다(BR-7).

#### 3. `ios/FocusMate/AppModel.swift`: 목적지 `cardStudio` (FR-5.8, FR-5.11)
- **현재**: `case preparation, records, settings, profile, time`(5행)과 title switch(8-14행)
- **변경**
  - **기존 행은 고치지 않고** 6행 다음에 `case cardStudio`를 별도 행으로 추가합니다.
  - title switch 끝에 `case .cardStudio: "카드 꾸미기"`를 추가합니다.
  - W10 브랜치가 같은 줄을 똑같이 추가하면 git이 충돌 없이 합칩니다.
- **영향**
  - `Destination.mainMenu`(`AppModel+JourneyStart.swift:43`)는 그대로 4개입니다(AC-28).
  - `AppFoundationTests.swift:220`의 `allCases` 루프는 main이 아닐 때 open이 무시되는지를 보는 테스트라 영향이 없습니다.

#### 4. `ios/FocusMate/AppModel+Profile.swift` (신규): 마이페이지 읽기·이동 API (FR-5.1, FR-5.4, FR-5.8, FR-5.9)
- **`profileStats`**
  - `snapshot?.records`의 `lifetimeSummary()` 결과를 `ProfileStats`로 감쌉니다.
  - throw하거나 snapshot이 nil이면 `.unavailable`을 돌려줍니다.
  - 쓰기와 캐시가 없는 계산 프로퍼티입니다. `@Observable`이 snapshot 변경을 추적하므로 기록이 추가되면 다시 열었을 때 바로 반영됩니다(AC-17).
  - 카드 모델(`CardSnapshot`)에는 아무것도 추가하지 않습니다(AC-14).
- **`openFromProfile(_:)`**
  - `path.last == .profile`일 때만 `open(item.destination)`을 호출합니다. 연타해도 한 번만 쌓입니다(기존 `proceedToPreparation` 관례).
  - 결과 경로는 `[.profile, .cardStudio]` 또는 `[.profile, .settings]`입니다. 시스템 뒤로 동작이 마지막 항목만 빼므로 마이페이지로 돌아옵니다(AC-25, AC-27).
- **시그니처**
  - `enum ProfileMenuItem: CaseIterable { case customize, settings; var destination: Destination }`
    - customize는 `.cardStudio`, settings는 `.settings`입니다.
  - `enum ProfileStats: Equatable { case loaded(RecordLifetimeSummary), unavailable }`
  - `extension AppModel { var profileStats: ProfileStats { get }; @discardableResult func openFromProfile(_ item: ProfileMenuItem) -> Bool }`
- **FR-5.11 경계**
  - 마이페이지는 `ProfileMenuItem.customize.destination == .cardStudio`만 압니다.
  - W10은 `DestinationScreen`에서 `.cardStudio` 분기만 실제 화면으로 바꾸면 됩니다. 마이페이지 코드는 수정할 필요가 없습니다.

#### 5. `ios/FocusMate/PassFace.swift`: 공통 카드 갱신과 부품 식별자 (FR-5.2, AC-5, AC-19)
- **현재**
  - `init()` 파라미터가 없습니다.
  - artwork에는 브랜드, 비접촉 표시(`wave.3.right`), 칩, 좌하단 이름이 있고 문구는 없습니다.
  - 바깥 요소 라벨은 `PassIdentity.displayName`입니다.
- **변경** (시안 EPnQQ와 AdtS5 공통 배치 기준. 기준 폭 238, `scale` 체계는 그대로)
  - **문구 추가**: `Text(PassFace.purposeText)` = "나를 위한 시간, 한 장으로."
    - `.system(size: 6.5 * scale, weight: .regular)`, 회색 `#d3d6d8`(프로토타입 `--card-ink`)
    - 위치: x = 58·scale, y = 0.62·h
  - **이름 이동**: 좌하단에서 칩 오른쪽으로 옮깁니다.
    - x = 58·scale, y = 0.40·h, `.system(size: 12 * scale, weight: .bold)`
  - **그대로 두는 것**: 칩(0.075w, 0.43h, 0.12w×0.15h)은 시안 측정값과 일치하므로 유지합니다. 브랜드, 비접촉 표시, 점묘, 테두리도 유지합니다.
  - **부품 식별자**: `init(partIdentifierPrefix: String? = nil)`를 추가합니다.
    - 값이 있으면 비접촉 이미지에 `"\(prefix).contactless"`, 칩에 `"\(prefix).chip"`을 붙입니다.
    - 칩은 Shape라 접근성 노드가 생기지 않으므로 `.accessibilityElement()`와 `.accessibilityAddTraits(.isImage)`를 함께 붙입니다.
    - 바깥 artwork의 `accessibilityHidden(true)`는 유지하므로 VoiceOver 노출은 바뀌지 않습니다.
  - 브랜드와 문구는 `static let brandText = "Focus Mate"`, `static let purposeText`로 상수화합니다.
- **시그니처**: `init(partIdentifierPrefix: String? = nil)`
- **고려사항**
  - 발급 화면은 `PassFace()` 그대로라 식별자 변화가 없습니다.
  - 발급 테스트는 `card.face` 존재와 `face.label == "집중동행카드"`만 단언합니다(`CardIssuanceFlowTests.swift:57,194-196`). 깨지지 않습니다.
  - 발급 화면의 카드 **외형**은 시안 기준으로 함께 바뀝니다(질문 1).
  - 번호는 계속 그리지 않습니다(BR-5).

#### 6. `ios/FocusMate/ProfileView.swift` (신규): 마이페이지 화면
**구성 타입**
- `enum ProfileCopy`
  - headline "내 시간에, 내 취향을.", subhead "한 장으로 함께하는 나만의 여정"
  - cardTagline "모든 몰입 여정에 함께"
  - journeysLabel "완료한 여정", timeLabel "함께한 시간"
  - statsError "기록을 불러오지 못했어요", unavailableValue "-"
  - 카드 이름은 `PassIdentity.displayName`을 씁니다. 행 이름은 `Destination.cardStudio.title`, `Destination.settings.title`을 씁니다(단일 출처).
- `struct ProfileStatsDisplay: Equatable` (순수 매핑, 단위 테스트 대상)
  - `init(_ stats: ProfileStats)`
  - 프로퍼티: `journeysText`, `timeText`, `journeysAccessibilityLabel`, `timeAccessibilityLabel`, `errorMessage: String?`
  - `.loaded(c, m)`일 때
    - 화면: `"\(c)"`, `ProfileTimeText.display(m)`
    - 접근성: `"완료한 여정, \(c)회"`, `"함께한 시간, \(ProfileTimeText.spoken(m))"`
    - errorMessage: nil
  - `.unavailable`일 때
    - 화면: `"-"`, `"-"`
    - 접근성: 질문 4
    - errorMessage: `ProfileCopy.statsError`
- `@MainActor struct ProfileView: View { let model: AppModel }`
  - 읽기 전용이라 `@Bindable`이 필요 없습니다.
- DEBUG 전용: `ProfileStatsOverrideKey: EnvironmentKey`(`ProfileStats?`, 기본 nil), `EnvironmentValues.profileStatsOverride`
  - `body`에서 `let stats = override ?? model.profileStats`를 씁니다. RELEASE에서는 `model.profileStats`만 씁니다.

**뷰 구조** (위에서 아래, 하단 고정 요소 없음. W02 교훈 반영)
```
ScrollView(.vertical) {
  VStack(alignment: .leading, spacing: 0) {
    headline · subhead · PassFace · cardName · cardTagline · Divider
    customizeRow · stats(+statsError) · Divider · settingsRow
  }.padding(.horizontal, 24).padding(.top, 32).padding(.bottom, 32)
}
.background(ProfileLayout.background.ignoresSafeArea())
.toolbarRole(.editor)                       // 뒤로 버튼에 chevron만 표시(시안), 이전 제목 "Focus Mate" 숨김
.navigationBarTitleDisplayMode(.inline)
.toolbar { ToolbarItem(placement: .topBarLeading) { 제목 Text } }   // chevron 오른쪽 좌측 정렬 제목
```
- **화면 제목**
  - `Text(Destination.profile.title)`, `.font(.title2.bold())`, `.accessibilityAddTraits(.isHeader)`, `.accessibilityIdentifier("screen.profile")`
  - `navigationTitle`은 설정하지 않습니다. 가운데에 제목이 한 번 더 나오는 것을 막기 위해서입니다.
- **카드**
  - `PassFace(partIdentifierPrefix: "profile.card").frame(maxWidth: .infinity).accessibilityIdentifier("profile.card")`
  - 라벨은 PassFace가 이미 "집중동행카드"로 붙입니다(AC-19).
- **행** (private `ProfileMenuRow(systemImage:title:identifier:action:)`)
  - `Button(action:)` + `.buttonStyle(.plain)`을 씁니다.
  - label: `HStack(spacing: 16) { Image(systemName:).frame(width: 24); Text(title); Spacer(minLength: 8); Image(systemName: "chevron.right").foregroundStyle(.secondary) }`
  - `.padding(.vertical, 20)`, `.frame(minHeight: 44)`, `.contentShape(Rectangle())`
  - 아이콘 2개는 `.accessibilityHidden(true)`, 버튼은 `.accessibilityLabel(title)`과 identifier를 붙입니다(AC-23).
  - 액션: `model.openFromProfile(.customize)`, `.settings`
- **통계** (private `ProfileStatView`)
  - 구조: `VStack(alignment: .leading, spacing: 8) { Text(value).accessibilityIdentifier("\(id).value"); Text(label) }`
  - 접근성: `.accessibilityElement(children: .ignore)`, `.accessibilityLabel(a11yLabel)`, `.accessibilityIdentifier(id)`. 한 요소로 읽힙니다(AC-18).
  - 배치: `@Environment(\.dynamicTypeSize)`의 `isAccessibilitySize`가 참이면 `AnyLayout(VStackLayout(alignment: .leading, spacing: 24))`, 아니면 `AnyLayout(HStackLayout(alignment: .top, spacing: 16))`입니다.
    - 각 칸은 `.frame(maxWidth: .infinity, alignment: .leading)`입니다.
    - `ViewThatFits` 대신 `AnyLayout`을 쓰는 이유: 어느 배치가 나올지 확정적이고, 배치가 바뀌어도 뷰 identity가 유지되며, 세로 배치에서도 여정이 위·시간이 아래라 AC-2 순서가 그대로 지켜집니다.
  - 실패 안내: `if let errorMessage { Text(...).font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("profile.statsError") }`를 통계 바로 아래에 둡니다. 정상일 때는 요소 자체가 없습니다(AC-32).
- **애니메이션**: `withAnimation`, `.transition`, `.animation`을 쓰지 않고 `accessibilityReduceMotion`도 읽지 않습니다. 동작 줄이기와 무관하게 같은 트리가 나옵니다(AC-21).
- **쓰기 없음**: `model.save`, `supplementCardIfNeeded`, `recordCompletion`을 호출하지 않습니다(FR-5.4).

#### 7. `ios/FocusMate/DestinationScreen.swift`: 분기 연결
- **현재**: Group 전체에 `.padding(24)`, `.navigationTitle`, `.inline`이 걸려 있습니다(22-23행).
- **변경**
  - `body` 맨 앞에서 `if destination == .profile { ProfileView(model: model) } else { 기존 Group 체인 그대로 }`로 나눕니다.
  - 이렇게 해야 ProfileView에 바깥 padding과 가운데 제목이 붙지 않습니다.
  - `.cardStudio`는 기존 default 분기를 그대로 탑니다. 그래서 `Text("카드 꾸미기").accessibilityIdentifier("screen.cardStudio")` 자리표시가 자동으로 나옵니다(AC-24, AC-33). 별도 코드가 필요 없습니다.
- **W10 경계**: W10은 `else` 쪽에 `.cardStudio` 분기를 추가하면 됩니다. 이번 변경과 겹치는 줄은 `body` 첫 줄 하나입니다.

#### 8. `ios/FocusMate/UITestBootstrap.swift` (DEBUG): 시드와 실패 주입
- **현재**: 원본 바이트 시드는 `rawSeeds`(122-132행)와 `state(issued:cards:records:stations:)` 헬퍼(118-120행)로 만듭니다.
- **변경**
  - **시드 `profileRecords` 추가**
    - `state(cards: #"{"id":"FM-12345678","issuedAt":"2026-10-13T09:00:00Z"}"#, records: …)`
    - 기록 3건: id `journey-a/b/c`, minutes 25/25/15, completedAt `2026-10-13T03:00:00Z`/`02:00`/`01:00`(최신순), date `2026-10-13`
    - 나머지 필드는 `RecordSectionTests.input()` 값을 재사용합니다(bus "버스2014", tag "독서", tagColor "#12ABef", task, sound, from, to, memo "").
    - 카드 번호를 PRD AC-6의 `FM-12345678`로 둬서 AC-6, AC-9, AC-18, AC-22를 시드 하나로 검증합니다. `seeds` 집합에는 `rawSeeds.keys`로 자동 포함됩니다.
  - **인자 `--fm-ui-profile-stats` 추가**: 허용값은 `"fail"` 하나입니다. 그 외 값은 `SetupIssue.invalidArguments`입니다.
    - `var profileStatsOverride: ProfileStats? { profileStatsScenario == "fail" ? .unavailable : nil }`
- **시그니처**: `let profileStatsScenario: String?`, `var profileStatsOverride: ProfileStats?`

#### 9. `ios/FocusMate/RootView.swift` (DEBUG 블록만)
- `NavigationStack` 뒤에 `#if DEBUG .environment(\.profileStatsOverride, testBootstrap?.profileStatsOverride) #endif`를 한 줄 추가합니다.
- NavigationStack 아래의 `navigationDestination` 화면까지 environment가 전달됩니다.
- RELEASE 빌드에는 영향이 없습니다.

---

### 데이터 흐름
```
저장 파일 ─(SnapshotCodec.decode: 전체 검증)→ AppModel.snapshot
  └ snapshot.records ─ RecordSection.lifetimeSummary() (validate → count/sum)
       └ AppModel.profileStats : ProfileStats (.loaded | .unavailable)   ← 읽기 전용, 쓰기 없음
            └ [DEBUG] Environment.profileStatsOverride 가 있으면 대체
                 └ ProfileStatsDisplay(stats) ─ ProfileTimeText.display/spoken
                      └ ProfileView: 값 Text / 접근성 라벨 / statsError
카드: PassIdentity.displayName → PassFace(라벨·이름) + profile.cardName  (CardSnapshot에는 집계 없음)
이동: ProfileView 행 탭 → AppModel.openFromProfile(item) → open(dest) → path.append → DestinationScreen
뒤로: 시스템 back → NavigationStack이 path.removeLast
```

### 디자인 스펙 구현 매핑 (시안 804×1748px @2x를 402pt 폭으로 환산)

| 요소 | SwiftUI 구현 |
|---|---|
| 배경 | `ProfileLayout.background = Color(red: 0x0F/255, green: 0x10/255, blue: 0x12/255)`, `.ignoresSafeArea()`. 앱 전체는 이미 `.preferredColorScheme(.dark)`(`RootView.swift:32`) |
| 좌우 여백 | 24pt (시안 48px). 카드도 같은 여백으로 화면 폭에 맞춤 |
| 뒤로 | 시스템 back. `.toolbarRole(.editor)`로 chevron만 표시 |
| 화면 제목 "마이페이지" | `ToolbarItem(.topBarLeading)`, `.font(.title2.bold())`(약 22pt), 흰색 |
| 큰 제목 | `.font(.title2.bold())`, `.padding(.top, 32)`(내비게이션 바에서 약 32pt) |
| 보조 문구 | `.font(.subheadline)`, `.foregroundStyle(.secondary)`, 큰 제목과 8pt 간격 |
| 카드 | `PassFace` 폭 353pt(시안 706px), 비율 85.6:53.98(시안 1.59와 일치). 면 `#121416`, 1pt 테두리 `#51565A`, 오른쪽 `PassDots` 점묘. 보조 문구와 32pt 간격 |
| 카드 이름 | `.font(.title3.bold())`(20pt), 카드와 16pt 간격 |
| 카드 부제 | `.font(.subheadline)`, `.secondary`, 이름과 4pt 간격 |
| 구분선 | `Divider()`(hairline), 부제와 28pt 간격 |
| 카드 꾸미기 행 | SF Symbol `pencil` + `Text(.body)` + `chevron.right`(`.secondary`). 아이콘 프레임 24pt, 아이콘과 글자 간격 16pt, 행 위아래 padding 20pt |
| 통계 값 | `.font(.title.bold())`(28pt, 시안 숫자 높이 약 20pt), `.lineLimit(1)`, `.minimumScaleFactor(0.6)`("100 h 5 min"이 절반 폭에 들어가도록) |
| 통계 라벨 | `.font(.subheadline)`, `.secondary`, 값과 8pt 간격 |
| 통계 배치 | 2열 `HStackLayout(spacing: 16)`, 각 칸 `maxWidth: .infinity`(오른쪽 열이 시안 x=213pt에서 시작). 접근성 크기에서는 `VStackLayout` |
| 통계 위아래 간격 | 행 아래 40pt, 다음 구분선 위 32pt |
| 설정 행 | SF Symbol `slider.horizontal.3` + "설정" + `chevron.right`, 카드 꾸미기 행과 같은 스타일 |
| 실패 안내 | 통계 바로 아래 12pt, `.subheadline`, `.secondary` |
| 하단 | `.padding(.bottom, 32)`. ScrollView가 safe area를 지켜 홈 인디케이터 영역이 비어 있음 |
| 애니메이션 | 없음 |

`ProfileLayout`에 간격 상수(`horizontal 24`, `top 32`, `headlineGap 8`, `cardTop 32`, `cardLabelTop 16`, `taglineGap 4`, `dividerTop 28`, `rowVertical 20`, `statsTop 40`, `statGap 8`, `statsBottom 32`, `iconWidth 24`, `iconGap 16`)를 모아 둡니다. 시안 대조 리뷰에서 숫자만 고치면 됩니다.

---

### AC → 구성요소 / 테스트 매핑

| AC | 구성요소 | 검증 계층 | 테스트 |
|---|---|---|---|
| 1 | ProfileView 제목 | UI | ProfileUITests `testAC1` (seed ready) |
| 2 | ProfileView 순서 | UI | 각 식별자 `frame.minY` 정렬. **같은 y면 minX로 정렬**(2열 통계) |
| 3, 4 | ProfileCopy | UI 라벨, 단위(상수) | ProfileUITests, ProfileModelTests |
| 5 | PassFace 부품 식별자와 문구 | UI(iOS 27 하위 노출 전제), 단위(상수) | `profile.card`의 `descendants(.staticText)` 라벨 집합과 `profile.card.contactless/.chip` 존재 확인 |
| 6 | PassIdentity, PassFace | UI | seed profileRecords. 모든 요소의 label과 value를 수집하되 `test.` 접두 식별자(`test.snapshot`에 카드 id가 들어 있음)는 제외하고 `FM-` 없음 확인 |
| 7 | PassIdentity.displayName | 단위, UI | 단위: `PassIdentity.current(in:)?.name == ProfileView 이름 출처`. UI: `profile.cardName` == "집중동행카드" (발급 쪽은 기존 `CardIssuanceFlowTests:196`) |
| 8 | ProfileStatsDisplay | 단위, UI | 단위: `.loaded(0,0)`이면 "0"/"0 min". UI(ready): `profile.stat.*.value` 라벨, `profile.statsError` 없음 |
| 9 | lifetimeSummary, Display | 단위, UI | seed profileRecords: "3", "1 h 5 min" |
| 10, 11 | ProfileTimeText | 단위 | ProfileTimeTextTests (7개 값 표) |
| 12 | RecordSection.lifetimeSummary | 단위 | N건, 합 S, 두 번 호출해도 같음 |
| 13 | recordingCompletion과 집계 | 단위 | RecordSection 수준과 AppModel 수준(`recordCompletion(isExample: true)` 전후 `profileStats` 같음) |
| 14 | AppModel+Profile, CardSnapshot | 단위 | `Mirror(CardSnapshot)` 프로퍼티가 `["id","issuedAt"]`뿐이고, `profileStats == .loaded(records.lifetimeSummary())` |
| 15 | 읽기 전용 | UI, 단위 | UI: `test.persistedBytes`를 열기 전·3초 머문 후·뒤로 간 후 비교. 단위: AppModel `open(.profile)` 후 `profileStats` 읽어도 writeCalls 0 (`AppFoundationTests:232` 패턴) |
| 16 | 시스템 back | UI | `navigationBars.buttons.firstMatch.tap()`, `open.profile.isHittable` |
| 17 | profileStats 관찰 | 단위 | 임시 파일 AppModel(`RecordStorageTests:14-20` 패턴)에서 recordCompletion 25분 후 `.loaded(1,25)`. UI에서는 기록 추가 경로가 없음(W09 후속) |
| 18 | ProfileStatView 접근성 | UI(라벨), 수동(VoiceOver 실제 읽기) | 라벨 "완료한 여정, 3회", "함께한 시간, 1시간 5분" |
| 19 | PassFace 라벨 | UI | `profile.card.label`에 "집중동행카드" 포함, `FM-` 미포함 |
| 20 | ScrollView, AnyLayout | UI | XXXL 인자, `test.dynamicTypeSize == accessibility5`, `reach()`(최대 3회 swipeUp) 후 5개 요소 isHittable, 뒤로 가능 |
| 21 | 애니메이션 없음 | 정적 확인과 수동 | 시뮬레이터에서 동작 줄이기를 실행 인자로 확실히 켤 수 없음. 리뷰 체크로 ProfileView에 `withAnimation`/`.animation`/`.transition`/`accessibilityReduceMotion`이 없는지 grep. 실제 기기 수동 확인 |
| 22 | ProfileTimeText.display | UI, 단위 | 값 텍스트에 "분"/"시간" 없음, "min"/"h" 있음 |
| 23 | ProfileMenuRow | UI | `.buttons["profile.customize"]` 라벨 "카드 꾸미기", isHittable |
| 24, 25 | openFromProfile(.customize), cardStudio | 단위, UI | 단위: path `[.profile, .cardStudio]`. UI: `screen.cardStudio` 라벨 "카드 꾸미기", 뒤로 가면 `screen.profile` |
| 26, 27 | openFromProfile(.settings) | 단위, UI | 위와 같은 방식 |
| 28 | Destination.mainMenu | 단위 | 기존 `JourneyStartModelTests:237`에 `!mainMenu.contains(.cardStudio)` 추가 |
| 29 | Display(.unavailable), statsError | 단위, UI(DEBUG 주입) | 단위: 값 "-", errorMessage. UI: `--fm-ui-profile-stats fail`로 card와 cardName 정상, 값 "-", 안내 문구 |
| 30 | lifetimeSummary 전체 거부 | 단위 | 5건 중 1건 minutes 0이면 `invalidMinutes(0)` throw, `profileStats == .unavailable`(RecordSection 수준) |
| 31 | 읽기 전용(실패) | UI(DEBUG 주입) | 실패 주입 상태에서 `test.persistedBytes` 전후 비교 |
| 32 | statsError 조건부 | UI, 단위 | ready와 profileRecords 모두 `profile.statsError` 없음 |
| 33 | Destination.cardStudio | 단위 | `rawValue == "cardStudio"`, `title == "카드 꾸미기"`. UI에서 `screen.cardStudio` |

**AC-30에서 "마이페이지는 '-'를 표시한다"는 부분**은 실제 앱 흐름으로 도달할 수 없습니다(제약 1). 그래서 "records 실패이면 `ProfileStats.unavailable`이고, 그러면 표시 모델 값이 '-'"라는 단위 테스트 연쇄로 검증합니다. 이 판단 근거는 테스트 주석에 남깁니다.

### 구현 순서 (태스크 = AC 묶음 1건)

1. **[Must] T1 records 누적 집계**: AC-12, 13(섹션), 30(섹션) (의존: 없음)
   - 운영 1: `RecordSection.swift`
   - 테스트: `RecordLifetimeSummaryTests.swift`
2. **[Must] T2 시간 표기 포매터**: AC-10, 11, 22(단위) (의존: 없음)
   - 운영 1: `ProfileTimeText.swift`
   - 테스트: `ProfileTimeTextTests.swift`
3. **[Must] T3 공통 카드 갱신과 부품 식별자**: AC-5(카드 측), 19(라벨 유지) (의존: 없음)
   - 운영 1: `PassFace.swift`
   - 회귀: 기존 `CardIssuanceFlowTests`, `PassFaceAssetTests`
4. **[Must] T4 목적지 cardStudio와 마이페이지 모델 API**: AC-13(모델), 14, 17, 24~27(모델), 28, 30(모델), 33 (의존: 1)
   - 운영 2: `AppModel.swift`, `AppModel+Profile.swift`
   - 테스트: `ProfileModelTests.swift`, `JourneyStartModelTests.swift`(1줄)
5. **[Must] T5 마이페이지 화면**: AC-1~4, 5(UI), 6~9, 15, 16, 18, 20, 21, 23~27(UI), 32 (의존: 2, 3, 4)
   - 운영 2: `ProfileView.swift`, `DestinationScreen.swift`
   - 테스트
     - `ProfileModelTests`에 `ProfileStatsDisplay` 단위 케이스 추가
     - `ProfileUITests.swift`(ready 시드 시나리오)
     - `Phase1FlowTests.swift:161-185` 수정: 목록에서 profile을 빼고, profile은 `ProfileUITests`에서 "내비게이션 버튼 + profile.customize + profile.settings" 구성으로 따로 단언
6. **[Must] T6 UI 시드와 집계 실패 주입**: AC-6, 9, 18, 22(UI), 29, 31 (의존: 5)
   - 운영 2(DEBUG): `UITestBootstrap.swift`, `RootView.swift`
   - 테스트: `ProfileUITests.swift`(profileRecords 시드, `--fm-ui-profile-stats fail`)
7. **[Should] T7 W10 경계 문서화**: FR-5.11 (의존: 4, 5)
   - 운영 0
   - `AppModel+Profile.swift` 헤더 주석과 `DestinationScreen` `.cardStudio` 분기 위치 주석에 경계를 적습니다.
   - 필요하면 T4·T5 안에서 함께 처리합니다.

T1, T2, T3은 병렬로 진행할 수 있습니다. T4는 T1만 끝나면 시작할 수 있습니다.

### 의존성 및 영향도
- **새 외부 의존성**: 없습니다. SwiftUI와 Observation만 씁니다(iOS 17 API: `AnyLayout`, `toolbarRole`, `ToolbarItem(.topBarLeading)`).
- **기존 구조와 다른 점**
  - 목적지 화면이 바깥 padding과 제목 체인을 쓰지 않는 첫 사례입니다. `TimeSelectionView`는 Group 체인 안에 있습니다.
  - 제목을 `navigationTitle` 대신 leading toolbar Text로 둡니다. 시안처럼 chevron 오른쪽에 좌측 정렬하기 위해서입니다.
  - 테스트 주입 방식이 새로 생깁니다. 기존은 bootstrap이 store를 바꿔 끼우는 방식이고, 이번에는 DEBUG environment로 표시 상태를 덮어씁니다. 실제 앱에서 도달할 수 없는 실패 상태를 렌더링하려면 필요합니다.
- **기존 테스트 영향**
  - `Phase1FlowTests:161-185`는 수정이 필요합니다.
  - `Phase1FlowTests:43-70`, `PreparationFlowUITests:102-117`은 그대로 통과할 것으로 예상합니다. 단, 뒤로 가기에 `navigationBars.buttons.firstMatch`를 씁니다. leading toolbar Text가 버튼으로 노출되면 영향이 생길 수 있으니, T5에서 `navigationBars.buttons.count`를 먼저 확인합니다.
- **발급 화면 영향**
  - PassFace 외형이 바뀝니다(이름 위치와 크기, 문구 추가). 식별자와 라벨은 그대로입니다.
- **하위 호환**
  - 저장 스키마 변경이 없습니다. 0건 기록도 정상입니다.
  - `Destination`에 case를 추가하지만 저장되지 않는 메모리 값이라 영향이 없습니다.
- **W10(codex/feat-card-customization) 충돌 경계**
  - `AppModel.swift`: 별도 행에 `case cardStudio`와 title 1줄만 추가합니다. W10도 같은 이름과 같은 제목이면 git이 깔끔하게 합칩니다.
  - `DestinationScreen.swift`: 마이페이지 쪽은 `.profile` 분기 한 줄만 추가합니다. W10은 `.cardStudio` 분기만 추가합니다.
  - `PassFace.swift`: **충돌 위험이 가장 큽니다.** W10이 사용자 그림(custom art)을 넣으려고 PassFace를 고칠 가능성이 높습니다. 이번 변경은 artwork의 이름·문구 Text 블록과 `init` 파라미터로 한정합니다. 합칠 때는 `partIdentifierPrefix`와 `purposeText`를 유지해 달라고 W10에 전달해야 합니다.
  - `ProfileView`와 `AppModel+Profile`은 W10이 건드릴 이유가 없습니다. W10이 합류해도 마이페이지는 수정 없이 동작합니다(FR-5.11).

### 테스트 가능성 고려
- **판독 위치**: 통계 값과 카드 내부 문구는 "접근성 한 요소로 묶은 컨테이너의 하위 노드"에서 읽습니다. 이 방식은 iOS 27 XCUITest가 하위 노드를 노출한다는 기존 관찰(`CardIssuanceFlowTests.swift:197`)에 기댑니다.
  - T5 첫 단계에서 `profile.stat.journeys.value`가 실제로 조회되는지 먼저 확인합니다.
  - 조회되지 않으면 DEBUG 진단 `test.profileStats`(값: `{"journeys":"3","time":"1 h 5 min"}`, `DestinationScreen.swift:24-31` 패턴)로 바꿉니다(질문 3).
- **큰 글자(AC-20)**: 메인 화면(`RootView` main 분기)은 ScrollView가 아닙니다. XXXL에서 `open.profile`이 화면 안에 있어야 진입할 수 있습니다. 버튼 4개 기준으로는 화면 안에 들어올 것으로 예상하지만, 실패하면 메인 쪽 문제로 따로 보고합니다(이번 범위 밖).
- **XXXL 탭 정확도**: 하단 고정 요소가 없으므로 W02의 "가려진 버튼 중앙 탭" 문제는 생기지 않습니다. 행에 `.contentShape(Rectangle())`과 `minHeight 44`를 줍니다.
- **AC-2 판정**: 2열 통계는 minY가 같으므로 `(minY, minX)`로 정렬합니다. 접근성 크기에서는 세로 배치라 minY만으로 순서가 정해집니다.
- **AC-15 대기**: 3초 대기는 `XCTWaiter().wait(for: [XCTestExpectation()], timeout: 3)`으로 합니다.
- **수동 확인(trust-ledger)**: AC-18의 VoiceOver 실제 읽기 순서와 장식 비노출, AC-21의 동작 줄이기 실기기 확인, 디자인 스펙 시각 대조.

### 탐색 추가 항목
- `ios/FocusMate/SnapshotCodec.swift:31` → 읽을 때 전체 검증. 유효하지 않은 기록이 있으면 시작이 실패한다는 근거
- `ios/FocusMate/AppSnapshot.swift:62-82` → `validate()`가 records까지 검증하고, `launchRoute()`가 이를 호출
- `ios/FocusMate/LocalSnapshotStore.swift:92-102` → 저장 전 검증(유효하지 않은 snapshot은 저장 불가)
- `ios/FocusMate/CardSection.swift:4-36` → `CardSnapshot`은 id와 issuedAt만 가짐(AC-14 근거)
- `ios/FocusMate/CardIssuanceView.swift:3-15, 54-70` → Copy enum 패턴, `PassFace()` + `card.face` 사용처
- `ios/FocusMateUITests/CardIssuanceFlowTests.swift:194-197` → hidden 하위 노드가 XCUITest에 노출된다는 관찰과 발급 카드 라벨 단언
- `ios/FocusMateUITests/Phase1FlowTests.swift:161-185` → 마이페이지 버튼 수 단언(수정 대상)
- `ios/FocusMateUITests/PreparationFlowUITests.swift:102-117` → 목적지 왕복(영향 없음)
- `ios/FocusMateUITests/LargeTextUITests.swift:72-91` → XXXL 실행 인자와 `reach()` 패턴
- `ios/FocusMateUITests/UITestLaunchSupport.swift:6-57` → `FocusMateUIHarness`(`extraArguments` 지원)
- `ios/FocusMateTests/AppFoundationTests.swift:205-256` → open, 쓰기 없음 단위 패턴, `allCases` 루프
- `ios/FocusMateTests/RecordStorageTests.swift:14-20` → 임시 파일 AppModel과 recordCompletion 패턴
- `ios/FocusMateTests/JourneyStartModelTests.swift:237` → mainMenu 단언(AC-28 보강 위치)
- `ios/FocusMateTests/PassIdentityTests.swift` → PassIdentity 단위 테스트(AC-7 보강 위치)
- `ios/FocusMate.xcodeproj/project.pbxproj:22-26` → 동기화 그룹(새 파일 자동 포함)
- `designs/prototype/index.html:600, 787, 965` → 공통 `pass-face`의 `pass-purpose` 문구, `formatTime`, `renderProfile`
- `designs/revised/pen-updates/card-briefing-2026-10-13/AdtS5.png` → 승하차 시안도 같은 카드 배치(칩 오른쪽 이름과 문구)

---

## 확인이 필요한 사항

1. PassFace를 시안 배치(칩 오른쪽 이름, 그 아래 "나를 위한 시간, 한 장으로.")로 공통 갱신할까요?
   - 맥락: 지금 PassFace는 이름이 좌하단에 크게 있고 문구가 없습니다(`PassFace.swift:51-53`). 마이페이지(EPnQQ)와 승하차(AdtS5) 시안, 프로토타입 공통 카드는 모두 새 배치입니다. 공통으로 고치면 발급 화면 카드 외형도 바뀝니다. 발급 테스트는 라벨과 존재만 보므로 깨지지 않습니다. W10이 PassFace를 고칠 가능성이 있어 충돌 위험도 있습니다.
   - 유형: 선택
   - 선택지:
     - (a) 공통 갱신 (권장): 모든 화면이 같은 최신 카드가 되어 FR-5.2 취지에 맞습니다. 발급 화면 외형이 바뀌고, W10과 PassFace 병합 조율이 필요합니다.
     - (b) 문구만 추가하고 배치는 유지: 변경이 가장 작고 W10 충돌도 작습니다. 대신 마이페이지 카드가 시안과 다르게 보입니다(이름 위치와 크기).
     - (c) PassFace에 마이페이지 전용 배치 옵션 추가: 발급 화면은 그대로입니다. 카드 외형이 화면마다 달라져 "같은 카드" 원칙이 약해집니다.
     - (d) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다

2. 집계 실패(AC-29, AC-31)를 UI 테스트로 확인하기 위해 DEBUG 전용 주입 인자를 추가할까요?
   - 맥락: 유효하지 않은 기록이 있으면 앱 시작 시 저장 오류 화면으로 가므로(`SnapshotCodec.swift:31`) 실제 흐름으로는 마이페이지 실패 상태에 갈 수 없습니다.
   - 유형: 선택
   - 선택지:
     - (a) 단위 테스트와 DEBUG 주입 인자 `--fm-ui-profile-stats fail` 둘 다 (권장): 실패 화면의 실제 렌더링과 저장 바이트 불변(AC-31)까지 UI로 확인합니다. DEBUG environment 키 1개와 `RootView` DEBUG 1줄이 늘어납니다.
     - (b) 단위 테스트만: 운영과 DEBUG 코드가 늘지 않습니다. 실패 화면 렌더링과 AC-31 바이트 비교는 "도달 불가 경로"로 문서화하고 표시 모델 단위 검증으로 대신합니다.
     - (c) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다

3. 통계 값 텍스트("3", "1 h 5 min")와 카드 내부 문구를 UI 테스트에서 어떻게 읽을까요?
   - 맥락: AC-18 때문에 각 통계는 한 접근성 요소(라벨 "완료한 여정, 3회")로 묶습니다. 그래서 값 텍스트는 그 하위 노드입니다. 카드 내부도 같은 구조입니다. iOS 27 XCUITest가 하위 노드를 노출한다는 기존 관찰(`CardIssuanceFlowTests.swift:197`)이 있지만, OS 버전에 따라 달라질 수 있습니다.
   - 유형: 선택
   - 선택지:
     - (a) 하위 식별자(`profile.stat.*.value`, `profile.card.contactless/.chip`)로 직접 조회하고, 조회되지 않으면 DEBUG 진단으로 전환 (권장): 화면에 실제로 그려진 노드를 검증합니다. T5 첫 단계에서 노출 여부를 먼저 확인합니다.
     - (b) 처음부터 DEBUG 진단 `test.profileStats`만 사용: OS 변화에 강합니다. 다만 그려진 Text가 아니라 표시 모델 값을 보는 간접 검증입니다.
     - (c) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다

4. 집계 실패일 때 통계 두 칸의 접근성 라벨은 무엇으로 할까요?
   - 맥락: PRD는 실패 시 화면 값 "-"와 안내 문구만 정했고, VoiceOver 라벨은 정하지 않았습니다. "-"를 그대로 넣으면 "대시"처럼 읽힐 수 있습니다.
   - 유형: 선택
   - 선택지:
     - (a) 라벨만 읽기: "완료한 여정", "함께한 시간" (권장). 바로 다음 요소인 `profile.statsError` "기록을 불러오지 못했어요"가 이유를 알려 주므로 중복 없이 이해됩니다.
     - (b) 값 위치에 상태 표기: "완료한 여정, 불러오지 못함" 등. 요소 하나만 들어도 상태를 알 수 있지만 안내 문구와 내용이 겹칩니다.
     - (c) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다