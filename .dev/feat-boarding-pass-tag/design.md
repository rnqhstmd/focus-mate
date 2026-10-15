## 설계 초안: 승차권 · 승차 태그 · 출발 안내 (W04, journey FR-11) — 2회차 최종

### 설계 규모
대형. 신규 화면 3개(승차권, 승차 태그, 여행/출발 안내)와 진행 여정 저장 형식을 새로 만들고, 메인·준비·저장소·UI 테스트 부트스트랩까지 연동한다.

### 배경 및 목적
- 준비 화면의 '승차권 보기'(`preparation.confirm`)는 지금 `confirmPreparation()`만 호출하고 화면을 이동하지 않는다(`ios/FocusMate/PreparationView.swift:175-187`). 승차권, 승차 태그, 여행 화면은 없다.
- `JourneySnapshot`은 빈 enum이어서 `journey.active`가 null이 아니면 손상으로 처리된다(`ios/FocusMate/JourneySection.swift:4-9`).
- 메인 `open.preparation`(현재 라벨 '여행 준비')은 시간 선택으로만 이동한다(`ios/FocusMate/RootView.swift:160-163`, `ios/FocusMate/AppModel+JourneyStart.swift:42-47`). 진행 중인 여정 안내는 없다.
- 이번 목표 흐름: 준비 확정 → 승차권 → 승차 태그 → 접촉 성공 시 진행 여정 1회 저장 → 여행 화면(출발 안내) → '시작'으로 출발 확인.
  - 어떤 이탈이 있어도 저장이 유실·중복되지 않는다.
  - 재실행하면 메인에서 진행 중인 여정을 알린다.

### 요구사항 및 수용 기준
`.dev/feat-boarding-pass-tag/prd.md`(확정판)를 그대로 따른다.
- [Must] FR-1~FR-14, BR-1~BR-6, BR-8, BR-9
- [Should] FR-15, FR-16, BR-7, QE-1~3
- AC-1~AC-28. 태스크별 AC 대응은 "구현 순서" 표에 있다.

사용자 결정(2회차 반영):
- Q1: 메인 버튼 글자를 '여행 시작하기'로 바꾼다. 식별자 `open.preparation`은 유지한다.
- Q2: '시작'을 누른 뒤에는 빈 '여행' 임시 화면을 보여 주고, 왼쪽 위 뒤로가기로 메인에 간다. 출발 안내 중에는 뒤로가기를 숨긴다.

### 변경 범위

**영향 모듈**
- 저장: AppSnapshot, JourneySection, SnapshotCodec
- 내비게이션: AppModel, Destination, DestinationScreen
- 준비: PreparationView
- 메인: RootView
- 카드 표시: PassFace 재사용
- 피드백: IssuanceHaptics, AccessibilityAnnouncing 재사용
- UI 테스트 부트스트랩, 문서

**신규 파일** (프로젝트가 `PBXFileSystemSynchronizedRootGroup`을 쓰므로 pbxproj 수정은 필요 없다, `ios/FocusMate.xcodeproj/project.pbxproj:22-26`)
- `ios/FocusMate/JourneySnapshot.swift`
- `ios/FocusMate/AppModel+Boarding.swift`
- `ios/FocusMate/BoardingRules.swift`
- `ios/FocusMate/BoardingPassContent.swift`
- `ios/FocusMate/BoardingTagController.swift`
- `ios/FocusMate/DepartureBriefingController.swift`
- `ios/FocusMate/BoardingPassView.swift`
- `ios/FocusMate/BoardingTagView.swift`
- `ios/FocusMate/JourneyView.swift`
- `ios/FocusMate/JourneyServices.swift`
- `ios/FocusMate/Assets.xcassets/TicketDots.imageset/`: `designs/assets/next-stop/ticket/ticket-seoul-dots.png`를 복사한다(파일 존재 확인함).
- `ios/FocusMate/Assets.xcassets/BoardMap.imageset/`: 정적 지도 배경. 후보는 `designs/assets/next-stop/revised/board-image-0.png`이고, 구현 때 시안 TUNX2와 대조해 확정한다. 맞지 않으면 어두운 그라데이션으로 대체한다.
- 단위 테스트:
  - `ios/FocusMateTests/JourneySnapshotTests.swift`
  - `ios/FocusMateTests/JourneySnapshotStorageTests.swift`
  - `ios/FocusMateTests/BoardingRulesTests.swift`
  - `ios/FocusMateTests/BoardingPassContentTests.swift`
  - `ios/FocusMateTests/BoardingModelTests.swift`
  - `ios/FocusMateTests/BoardingTagControllerTests.swift`
  - `ios/FocusMateTests/DepartureBriefingControllerTests.swift`
  - `ios/FocusMateTests/BoardingTestDoubles.swift`
- UI 테스트:
  - `ios/FocusMateUITests/BoardingFlowUITests.swift`
  - `ios/FocusMateUITests/BoardingTagUITests.swift`
  - `ios/FocusMateUITests/ActiveJourneyMainUITests.swift`
  - `ios/FocusMateUITests/BoardingLargeTextUITests.swift`

**수정 파일**
- `ios/FocusMate/JourneySection.swift`: 빈 enum 제거
- `ios/FocusMate/AppSnapshot.swift`: 검증 이슈와 validate 확장
- `ios/FocusMate/SnapshotCodec.swift`: v2 journey 계약 고정
- `ios/FocusMate/PreparationDraft.swift`: `PreparationTagIcon`, `PreparationTagColor`, `JourneySound`에 Codable 추가
- `ios/FocusMate/AppModel.swift`: Destination 3종, open 가드, factory 주입
- `ios/FocusMate/AppModel+JourneyStart.swift`: `mainMenuTitle` 추가, 주석 수정
- `ios/FocusMate/DestinationScreen.swift`
- `ios/FocusMate/PreparationView.swift`
- `ios/FocusMate/RootView.swift`
- `ios/FocusMate/FocusMateApp.swift`
- `ios/FocusMate/IssuanceHapticPattern.swift`
- `ios/FocusMate/UITestBootstrap.swift`
- 테스트:
  - `ios/FocusMateUITests/UITestLaunchSupport.swift`
  - `ios/FocusMateUITests/PreparationEditorUITests.swift`
  - `ios/FocusMateUITests/PreparationFlowUITests.swift`
  - `ios/FocusMateUITests/Phase1FlowTests.swift`
  - `ios/FocusMateTests/SnapshotCodecTests.swift`(주석)
  - `ios/FocusMateTests/CardCustomizationAppModelTests.swift`(주석)
- 문서:
  - `docs/FLOWS.md`
  - `docs/CURRENT-STATE.md`
  - `.dev/plan.md`(W05 인계)

### 적용 컨벤션
- 네이밍
  - 화면 식별자는 `screen.<rawValue>`, 요소 식별자는 `<화면>.<요소>`, 테스트 진단은 `test.<이름>`.
  - 테스트 메서드는 "깨짐:" 주석과 AC 접두를 붙인다(`ios/FocusMateUITests/PreparationEditorUITests.swift:9-10`).
- 저장
  - 최신 `snapshot` → `updating…` → `AppModel.save` 순서로 저장한다. 실패하면 snapshot은 그대로 두고 `saveFailure`만 바꾼다(`ios/FocusMate/AppModel.swift:184-206`).
  - 기능별로 `AppModel+기능.swift` 확장을 둔다.
- 컨트롤러
  - `@MainActor @Observable final class` 형태로 만들고, 의존성은 `@ObservationIgnored`로 주입한다(sleep, 햅틱, 낭독).
  - 포커스는 `focusTarget` 값으로 노출한다(`ios/FocusMate/CardIssuanceController.swift:19-69`, `ios/FocusMate/CardIssuanceView.swift:51`).
- 생성기: 시계와 ID를 주입하고 날짜는 초 단위로 내린다(`ios/FocusMate/CardSnapshotFactory.swift:4-19`). 날짜는 ISO8601 문자열로 직접 인코딩한다(`ios/FocusMate/CardSection.swift:24-41`).
- 화면 배치: 하단 고정 CTA는 `safeAreaInset(edge: .bottom)`을 쓴다(`ios/FocusMate/CardIssuanceView.swift:47`). 큰 글자에서는 스크롤 영역과 고정 영역을 분리한다(`ios/FocusMate/TimeSelectionView.swift:11-37`).
- 툴바 식별자: 툴바 Text에 식별자를 두지 않는다. W11에서 툴바 래퍼로 식별자가 복사되는 문제가 있었다(`.dev/feat-my-page/reports/t5-impl.md:12`).
- DEBUG 진단: `font(.system(size: 1))` + `.clear` + `allowsHitTesting(false)`(`ios/FocusMate/RootView.swift:214-230`). 테스트용 버튼은 불투명 44pt 영역에 투명 글자로 만든다(`ios/FocusMate/RootView.swift:87-97`).
- 프로젝트 루트에는 CLAUDE.md가 없다. 관례는 기존 코드와 `.dev/plan.md:52-64`에서 학습했다.

### 상세 설계

#### A. 진행 여정 저장 형식

1. **`ios/FocusMate/JourneySnapshot.swift`(신규) + `JourneySection.swift`(수정)**: 빈 enum을 실제 값으로 바꾼다.
   - 현재: 빈 enum이라 decode가 항상 throw한다(`JourneySection.swift:4-9`). `JourneySection`은 `active` 키를 필수로 요구하고 null은 허용한다(`:16-28`).
   - 변경:
     - 사용자가 고른 입력만 저장한다. `stops`, 거리, 정류장 이름처럼 다시 계산할 수 있는 값은 저장하지 않는다.
     - 태그는 메모리 초안에만 있으므로(`PreparationDraft.swift:93-133`) 태그 정의(id, 이름, 아이콘, 색) 전체를 복사해 저장한다.
     - `JourneySection`의 decode/encode 코드는 그대로 둔다. 키가 없으면 손상, null이면 nil, 객체면 신규 struct로 읽힌다. `{}`나 `"x"`는 필수 키·타입 오류로 계속 실패한다(`ios/FocusMateTests/AppSnapshotSectionsTests.swift:166-186` 유지).
   - 시그니처:
     - `struct JourneySnapshot: Codable, Equatable`
       - `enum Phase: String, Codable { case awaitingDeparture, departed }`
       - `struct Tag: Codable, Equatable { let id: String; let name: String; let icon: PreparationTagIcon; let color: PreparationTagColor }`
       - `struct Progress: Codable, Equatable { let elapsedSeconds: Int; static let start }`
       - 필드: `id`, `cardID`, `originStopID: String`, `direction: Int`, `minutes: Int`, `busID: String`, `destinationStopID: String`, `tag: Tag`, `task: String`, `sound: JourneySound`, `boardedAt: Date`(ISO8601 문자열로 인코딩), `phase: Phase`, `progress: Progress`
       - `static func boarding(details: PreparedJourneyDetails, cardID: String, id: String, boardedAt: Date) -> JourneySnapshot`: 도착 정류장 id는 `RouteStops.all[wrap(origin.index + direction*stops)].id`로 이 시점에 1회만 확정한다.
       - `func confirmingDeparture() -> JourneySnapshot`: phase만 `.departed`로 바꾼다.
       - 표시용 조회(실패해도 동작): `var originName: String?`, `var destinationName: String?`, `var bus: BusLine?`. 카탈로그에서 찾지 못하면 nil을 돌려주고, 쓰는 쪽은 대체 문구("정류장 정보 없음")를 쓴다.
       - `func validate(currentCardID: String?) throws`. 실패 시 `ActiveJourneyValidationIssue`를 던진다.
     - `enum ActiveJourneyValidationIssue: Error, Equatable { case emptyField(String), cardMismatch, invalidDirection(Int), invalidMinutes(Int), invalidTask, invalidTag, invalidProgress }`
     - `struct ActiveJourneyFactory { init(makeID: @escaping () -> String = { UUID().uuidString }, now: @escaping () -> Date = Date.init); func make(details:cardID:) -> JourneySnapshot }`. `boardedAt`은 초 단위로 내린다.
   - 검증은 구조만 본다. 카탈로그 대조는 하지 않는다.
     - `id`, `cardID`, `originStopID`, `busID`, `destinationStopID`, `tag.id`가 빈 문자열이 아니어야 한다.
     - `direction`은 ±1이어야 한다.
     - `minutes > 0`이어야 한다.
     - `task`는 trim한 값과 같고, 비어 있지 않고, UTF-16 80 이하여야 한다(`PreparationDraft.swift:106-116`과 같은 규칙).
     - `tag.name`은 trim 후 비어 있지 않고 UTF-16 20 이하여야 한다(`PreparationDraft.swift:118-121`).
     - `elapsedSeconds ≥ 0`이어야 한다. phase가 `.awaitingDeparture`이면 0이어야 한다(BR-5를 저장 단에서 보장).
     - `cardID == currentCardID`여야 한다.
   - 계약 주석(파일 상단에 남긴다): "정류장·버스 id는 W04 시점 `RouteStops`/`BusLine` 카탈로그 기준 값이다. 카탈로그가 바뀌어도 저장은 유효하며, 이름·정류장 수·거리는 조회 실패 시 nil로 처리한다."
   - 확장 여지(W05): 진도·체크포인트를 `Progress`나 새 필드로 확장한다. 새 필수 필드를 추가할 때는 currentVersion을 4로 올린다. W04 앱은 모르는 키를 무시한 채 다시 저장해서 그 키를 떨어뜨리기 때문이다(`ios/FocusMateTests/SnapshotCodecTests.swift:144-151`).

2. **`ios/FocusMate/AppSnapshot.swift`**
   - 현재: 정류장, 카드, 기록만 검증한다(`:63-81`). `launchRoute`는 cardIssued와 currentStation만 본다(`:83-87`).
   - 변경:
     - `SnapshotValidationIssue`에 `case invalidActiveJourney(ActiveJourneyValidationIssue)`를 추가한다(`:10-15`).
     - validate 끝에서 `active`가 있으면 먼저 `currentStation != nil`인지 본다. 아니면 `.inconsistentStage`.
     - 이어서 `try active.validate(currentCardID: currentCard?.id)`를 호출하고, 실패를 위 case로 감싼다.
   - `launchRoute`는 바꾸지 않는다. 그래서 진행 여정을 저장해도 `.main`이 유지되고, `persist`의 경로 초기화(`ios/FocusMate/AppModel.swift:201`)가 일어나지 않는다. 이 점은 단위 테스트로 고정한다.
   - 고려사항: `LocalSnapshotStore.save`도 validate를 호출한다(`ios/FocusMate/LocalSnapshotStore.swift:104-107`). 잘못된 후보는 파일에 쓰기 전에 `invalidState`로 거절된다.

3. **`ios/FocusMate/SnapshotCodec.swift`**: v2 계약을 고정한다.
   - 현재: `LegacySnapshotV2.journey: JourneySection`(`:26-34`)이고, `migrateV2`가 이 값을 그대로 넘긴다(`:70-77`).
   - 변경:
     - `struct LegacyJourneySectionV2: Decodable`를 추가한다. `active` 키가 필수이고 null만 허용하며, 그 외 값은 `.corrupt`로 처리한다.
     - `migrateV2`는 `.updating(journey: .empty)`를 쓴다.
   - 버전 정책: `currentVersion = 3`을 유지한다.
     - 근거 1: W04는 새 필드를 추가하는 것이 아니다. v3가 처음부터 예약해 둔 nullable 객체 `journey.active`의 내용을 정의하는 것이다.
     - 근거 2: 이전 v3 앱은 null이 아닌 active를 손상으로 보고 읽기와 쓰기를 모두 막는다(writeBlocked, `ios/FocusMate/LocalSnapshotStore.swift:108-109`). 정리하려면 사용자 확인과 원본 백업을 거쳐야 하므로 조용한 유실이 없다.
     - 근거 3: active가 null인 기존 파일은 바이트가 그대로다.
     - W05와의 관계: W05가 새 필수 필드를 추가할 때 4로 올린다(A-1의 확장 여지 참고).
   - v3 계약 정리: "active는 null 또는 JourneySnapshot 객체, 최대 1건". 이 내용을 문서 갱신 항목(T9)에 넣는다.

4. **`ios/FocusMate/PreparationDraft.swift`**: `PreparationTagIcon`(`:3`), `PreparationTagColor`(`:24`), `JourneySound`(`:63`)에 `Codable` 채택만 추가한다. 저장값은 raw String이다. 모르는 raw 값은 decode 실패, 곧 손상으로 처리된다.

#### B. 내비게이션과 모델

5. **`ios/FocusMate/AppModel.swift`**
   - 현재: Destination은 `preparation, records, settings, profile, time`이다(`:5-16`). `open()`은 `.ready(.main)`에서만 append한다(`:250-253`).
   - 변경:
     - `case board, boarding, journey`를 추가한다. title은 각각 "승차권", "승차 태그", "여행".
     - `open()`에 가드를 둔다. `.board`와 `.boarding`은 `confirmedPreparation != nil`일 때만 append한다(BR-1 "어떤 경로로도").
     - `.journey`는 `open`으로 열지 않는다. `finishBoardingTransition`의 경로 교체로만 들어간다. 그래서 open 가드는 두지 않고, `open(.journey)`는 일반 append와 같다. 다만 호출부가 없다.
     - init에 `journeyFactory: ActiveJourneyFactory = .init()`를 추가한다. 기본값이 있어 기존 호출부는 바뀌지 않는다.

6. **`ios/FocusMate/AppModel+JourneyStart.swift`**
   - `Destination.mainMenuTitle`을 추가한다. `.preparation`은 "여행 시작하기", 나머지는 `title`. `title`("여행 준비")은 화면 제목 의미로 남겨 둔다.
   - `:45` 주석을 갱신한다.

7. **`ios/FocusMate/AppModel+Boarding.swift`(신규)**
   - `var activeJourney: JourneySnapshot? { snapshot?.journey.active }`
   - `@discardableResult func showBoardingPass() -> Bool`
     - `confirmPreparation()`이 true이고 `path.last != .board`일 때만 `open(.board)`를 호출한다. 연타해도 1회만 쌓인다(`proceedToPreparation` 관례, `AppModel+JourneyStart.swift:35-39`).
     - 미완성이면 false를 반환하고 이동하지 않는다.
     - `consumePreparationRequest`는 쓰지 않는다. 데이터 출처는 `confirmedPreparation` 하나다.
   - `@discardableResult func openBoarding() -> Bool`: `path.last == .board`이고 `confirmedPreparation != nil`일 때 `open(.boarding)`. 쓰기는 0회다(AC-4).
   - `func boardJourney() -> Bool`(`JourneyBoarding` 준수)
     - 전제: `.ready(.main)`, `snapshot`, `currentCard`, 호출 시점의 `confirmedPreparation`이 모두 있어야 한다.
     - `save(snapshot.updating(journey: JourneySection(active: journeyFactory.make(...))))`로 기존 active를 교체한다. 저장 건수는 최대 1건이다(BR-8).
     - 실패하면 snapshot은 그대로이고 `saveFailure`가 남는다. 이 값은 메인의 공용 문구 `storage.saveFailure`에도 쓰인다(`RootView.swift:28-31`).
   - `func finishBoardingTransition()`
     - `path.last == .boarding`이고 `activeJourney != nil`일 때만 `path = [.journey]`로 바꾼다(AC-13). 뒤로가기는 메인으로 간다.
     - 뷰가 `withTransaction(disablesAnimations)` 안에서 호출한다.
   - `@discardableResult func confirmDeparture() -> Bool`(`DepartureConfirming` 준수): `.awaitingDeparture`이면 저장한다. 이미 `.departed`이면 쓰지 않고 true를 반환한다.
   - `@discardableResult func startTripFromMain() -> Bool`
     - active가 없으면 `open(.time)`만 한다(쓰기 0).
     - active가 있으면 `save(…updating(journey: .empty))`를 한다. 성공하면 `open(.time)`, 실패하면 이동하지 않는다. 메인의 `storage.saveFailure`가 보이고 진행 여정 안내도 남는다.
     - 근거: 사용자가 정리된 줄 알고 새 여행을 시작했는데 저장소에는 이전 여정이 남는 불일치를 막는다. snapshot 불변 + 실패 안내라는 기존 관례와도 맞는다.
   - records는 모든 경로에서 건드리지 않는다(BR-9).

#### C. 승차 태그 상태 기계

8. **`ios/FocusMate/BoardingRules.swift`(신규, 순수 규칙)**
   - `struct BoardingGeometry`
     - 상수: `tagAreaSize = 238×160`, `threshold = 0.30`, `maxHorizontal = 26`, `maxDown = 20`, `tapSlop = 8`, `activationMargin = 8`
     - 카드 폭 상수: `cardWidth = 268`. 근거는 시안 kxUUR의 2x 렌더다. 카드 안쪽 폭은 약 537px, 단말기는 546px(274pt), 태그 영역은 473×317px(238×160pt)이다. 카드 높이는 `PassFace.aspectRatio`로 계산하며 약 168pt다.
     - `func clampedOffset(_ t: CGSize, cardRest: CGRect, tagArea: CGRect) -> CGSize`: x는 ±26, y는 `[tagArea.minY - cardRest.minY, +20]` 범위로 자른다.
     - `func overlapRatio(card: CGRect, tagArea: CGRect) -> CGFloat`: 교집합 면적 ÷ 태그 영역 면적(BR-7).
     - `func isContact(card:tagArea:) -> Bool`: 겹침 비율 ≥ 0.30.
     - `func isTap(_ t: CGSize) -> Bool`: 이동 거리 < 8.
     - `func activationOffset(cardRest: CGRect, tagArea: CGRect) -> CGSize`
       - 카드 크기와 무관하게 임계를 넘도록 계산한다. 필요한 겹침 높이 `h = threshold × tagArea면적 ÷ min(card폭, tag폭) + activationMargin`.
       - 카드 위쪽을 `tagArea.maxY - h`에 두는 offset을 돌려준다. x는 카드와 태그 영역의 중심을 맞춘다.
       - 결과적으로 카드는 태그 영역 아래쪽 가장자리에 걸치면서 겹침 비율이 0.30 이상이다(FR-7).
   - `struct BoardingTiming`
     - 값: `contact = 300ms`, `hold = 1400ms`, `fade = 450ms`, `terminalEntrance = 0.12s`, `cardEntrance = 0.38s`
     - `func contact(reduceMotion:)`, `func fade(reduceMotion:)`: 동작 줄이기면 0. hold는 항상 유지한다.
   - `enum BoardingClock { static func text(for: Date, timeZone: TimeZone = .current) -> String }`: `HH:mm`, en_US_POSIX.

9. **`ios/FocusMate/BoardingTagController.swift`(신규)**
   - 프로토콜: `@MainActor protocol JourneyBoarding: AnyObject { func boardJourney() -> Bool }`
   - `@MainActor @Observable final class BoardingTagController`
     - `enum Phase: Equatable { case ready, dragging, contacting, held, fading, finished, failed, abandoned }`
     - 노출 상태: `phase`, `cardOffset`, `showsTapHint`, `tapBounceCount`, `showsSaveFailure`, `var isRecognized`(contacting, held, fading, finished, abandoned일 때 true), `var lcd: LCDState`(`.ready` 또는 `.recognized`)
     - 테스트 대기용:
       - `@ObservationIgnored private(set) var pendingSave: Task<Void, Never>?`
       - `@ObservationIgnored private(set) var pendingTransition: Task<Void, Never>?`
       - 테스트는 `await controller.pendingSave?.value`, `await controller.pendingTransition?.value`로 결정적으로 기다린다.
     - 내부 토큰:
       - `recognitionID`(저장용): 인식할 때마다 증가한다.
       - `transitionToken`(전환용): 인식할 때와 취소할 때 증가한다.
       - `transitionCancelled: Bool`, `resetWhenSettled: Bool`
     - `init(boarder: JourneyBoarding, haptics: IssuanceHaptics, announcer: AccessibilityAnnouncing, geometry: BoardingGeometry = .init(), timing: BoardingTiming = .standard, sleep: @escaping (Duration) async -> Void, holdSleep: ((Duration) async -> Void)? = nil, onFinished: @escaping () -> Void)`
     - `func updateLayout(cardRest: CGRect, tagArea: CGRect)`
     - `func dragChanged(translation: CGSize, reduceMotion: Bool)`
     - `func dragEnded(translation: CGSize, reduceMotion: Bool)`
     - `func activate(reduceMotion: Bool)`
     - `func cancelPendingTransition()`
     - `func returnToForeground()`
   - 전이 규칙:
     - `dragChanged`
       - `ready` 또는 `failed`에서 이동이 tapSlop을 넘으면 `dragging`이 되고 힌트를 숨긴다.
       - `dragging`이면 `cardOffset`을 clamp하고, `isContact`이면 바로 `recognize()`한다. 손을 떼기 전에 인식된다(AC-6).
       - 그 밖의 phase에서는 무시한다(AC-12).
     - `dragEnded`
       - 절대 인식하지 않는다(불변식).
       - tapSlop을 넘은 적이 없으면 `tapBounceCount += 1`, `showsTapHint = true`(AC-9).
       - `dragging`이면 offset을 `.zero`로 돌리고 `ready`(AC-7).
       - 인식 이후 phase에서는 무시하고 카드는 그 자리에 둔다.
     - `activate`: `ready` 또는 `failed`에서만 동작한다. offset을 `activationOffset`으로 두고 `recognize()`(AC-10).
     - `recognize()`
       - `recognitionID += 1`, `transitionToken += 1`, `transitionCancelled = false`, `phase = .contacting`.
       - 동작 줄이기가 꺼져 있고 지원 기기면 `haptics.play(.boardingContact)`.
       - contact가 0이면 `commit(id)`를 바로 실행하고, 아니면 `pendingSave = Task { await sleep(contact); commit(id) }`.
     - `commit(id)`: `recognitionID == id`이고 `phase == .contacting`일 때만 `boarder.boardJourney()`를 호출한다. 저장은 전환 취소와 무관하게 예약대로 수행한다.
       - 성공:
         - 낭독 "집중동행카드 인식됨, 승차했습니다" 1회. 화면이 사라졌어도 낭독한다.
         - `transitionCancelled`이면 `phase = resetWhenSettled ? .ready(offset .zero) : .abandoned`이고 hold를 예약하지 않는다.
         - 아니면 `phase = .held`, `pendingTransition = Task { holdSleep ?? sleep(hold) → token 확인 → .fading → (fade가 0보다 크면 sleep) → token 확인 → phase = .finished → onFinished() }`. `.finished`를 설정한 뒤에 `onFinished`를 호출하는 순서를 테스트로 고정한다.
       - 실패:
         - `phase = .failed`, offset `.zero`, `showsSaveFailure = true`, 낭독 "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요."
         - 화면이 이미 사라졌다면 `model.saveFailure`가 메인의 공용 실패 문구로 보인다. 별도 처리는 필요 없다.
     - `cancelPendingTransition()`: 화면이 사라졌거나 `scenePhase == .background`일 때 호출한다.
       - 공통: `transitionToken += 1`.
       - `contacting`이면 `transitionCancelled = true`만 설정한다. 저장은 300ms 뒤 예정대로 수행된다.
       - `held` 또는 `fading`이면 `abandoned`(AC-14, AC-15).
       - `dragging`이면 offset `.zero`, `ready`(AC-16).
       - 나머지 phase는 그대로 둔다.
     - `returnToForeground()`: `scenePhase`가 background에서 `.active`로 돌아올 때 호출한다.
       - `abandoned`이면 `ready`로 되돌린다. offset `.zero`, LCD '승차 준비', 힌트와 실패 표시는 숨긴다.
       - `contacting`이고 `transitionCancelled`이면 `resetWhenSettled = true`로 둔다.
       - 저장된 진행 여정은 유지된다. 이후 다시 태그하면 교체 저장되고(BR-8) 뒤로가기도 할 수 있다.
       - AC-12의 "추가 접촉 무시"는 같은 인식 주기(held, fading) 안에서의 규칙이다. 복귀 후 다시 태그하는 것은 새 인식이며 교체 1건이 된다.
   - 햅틱과 낭독은 기존 프로토콜을 재사용한다(`ios/FocusMate/IssuanceFeedback.swift:4-13`). 패턴은 `IssuanceHapticPattern.boardingContact`를 추가한다. 0.12초 약한 연속 진동과 transient 1회다(`ios/FocusMate/IssuanceHapticPattern.swift:24-33` 형식).

#### D. 출발 안내

10. **`ios/FocusMate/DepartureBriefingController.swift`(신규)**
    - 프로토콜: `@MainActor protocol DepartureConfirming: AnyObject { func confirmDeparture() -> Bool }`
    - `@MainActor @Observable final class DepartureBriefingController`
      - `static let sentences = ["문을 닫습니다", "자리에 앉아주세요", "버스 출발합니다"]`, `static let interval: Duration = .milliseconds(1700)`
      - 노출 상태: `visibleIndex`, `showsAll`, `showsStart`, `focusTarget: FocusTarget?`(`.startButton`), `isConfirmed`, `showsSaveFailure`
      - `init(confirmer: DepartureConfirming, interval: Duration = interval, sleep: @escaping (Duration) async -> Void)`
      - `func begin(reduceMotion: Bool) async`
        - token을 증가시킨다.
        - 동작 줄이기면 `showsAll`과 `showsStart`를 즉시 켠다(AC-18).
        - 아니면 0 → sleep → 1 → sleep → 2 순서로 진행하고 마지막에 `showsStart`를 켠다. 단계마다 token을 확인한다.
        - `showsStart`가 켜지면 `focusTarget = .startButton`.
      - `func reset()`: token 증가, index 0, `showsStart = false`.
      - `func confirm() -> Bool`: `showsStart`일 때만 동작한다. 실패하면 `showsSaveFailure`이고 버튼은 남는다.
    - 일시정지 조작, 진도, 남은 시간은 화면에 없다. 그래서 AC-19와 BR-5가 구조적으로 보장된다.

#### E. 화면

11. **`ios/FocusMate/BoardingPassContent.swift`(신규, 순수)**: `init(details: PreparedJourneyDetails, now: Date, timeZone: TimeZone)`
    - 필드: `originName`, `destinationName`, `stopsText`("12개"), `distanceText`(`JourneyPlanner.distanceText` 재사용), `boardingText = "지금"`, `dateText`(`yyyy/MM/dd`), `tagName`, `task`, `stationFontSize`, `routeAccessibilityLabel`
    - `stationFontSize`: 두 이름 중 긴 쪽 글자 수가 4 이하면 28, 6 이하면 24, 9 이하면 20, 그 외 17(`designs/final/animation-preview.html:823`).
    - `routeAccessibilityLabel`: "{출발}에서 {도착}까지, {kind} {number}번 버스, {minutes}분 여행". 버스 번호와 분은 이 라벨에만 넣는다(AC-3).

12. **`ios/FocusMate/BoardingPassView.swift`(신규, 시안 TUNX2)**
    - 배경: `BoardMap` 이미지 또는 그라데이션, `accessibilityHidden`.
    - 본문: `ScrollView` 안에 티켓 카드를 둔다. 배경 질감은 `TicketDots`, 노치만 남긴다. 칸 구조는 "라벨 위 / 값 아래", 좌우 2열이다.
    - CTA: '버스에 탑승하기 →'를 `safeAreaInset(edge: .bottom)`로 고정한다(AC-23).
    - 식별자:
      - 컨테이너 `screen.board`(`.contain`)
      - 값 `board.origin`, `board.destination`, `board.stops`, `board.distance`, `board.boarding`, `board.date`, `board.tag`, `board.task`
      - `board.route`(`.ignore`, `routeAccessibilityLabel`)
      - 버튼 `board.boardBus`
    - 데이터는 `model.confirmedPreparation` 하나에서 읽는다. nil이면 "준비를 다시 확인해주세요"를 보이고 버튼을 숨긴다.
    - 제목은 빈 문자열이고 시스템 back을 쓴다. 식별자는 본문에만 둔다.

13. **`ios/FocusMate/BoardingTagView.swift`(신규, 시안 kxUUR, JmXmQ, Vts6F)**
    - 구성:
      - 단말기: 폭 274. LCD에는 'Focus Mate', `TimelineView(.everyMinute)` + `BoardingClock`, 상태('승차 준비' 또는 '집중동행카드' + 체크).
      - 태그 영역 238×160(`boarding.tagArea`).
      - 위쪽 화살표.
      - 점선 테두리 안의 카드: `PassFace(style: model.currentCardStyle)`, `frame(width: 268)`.
    - 좌표: `.coordinateSpace(name: "boarding")`와 GeometryReader로 측정해 `updateLayout`에 넘긴다.
    - 제스처: `PassFace`는 `allowsHitTesting(false)`다(`ios/FocusMate/PassFace.swift:17`). 그래서 카드를 감싼 래퍼에 `contentShape(Rectangle())`과 `DragGesture(minimumDistance: 0, coordinateSpace: .named("boarding"))`를 붙인다. `onChanged`는 `dragChanged`, `onEnded`는 `dragEnded`.
    - 접근성:
      - 카드 래퍼 `boarding.card`: `.ignore`, 라벨 "집중동행카드", `.isButton`, 힌트 "카드를 여기에 대면 승차해요. 눌러서 태그하기", `accessibilityAction { activate }`. VoiceOver 활성화와 Full Keyboard Access의 Enter/Space가 이 경로를 탄다.
      - 낭독 전용 머리 요소 `boarding.title`: 1pt `Color.clear`, 라벨 "승차 태그, {출발 정류장}, 승차 단계. 카드를 위로 밀어 단말기에 대주세요". 제목, 정류장, 단계, 하단 안내를 모두 담는다.
      - 단말기 `boarding.terminal`: 라벨 "Focus Mate 승차 단말기, {HH:mm}, {승차 준비 또는 집중동행카드 인식됨}". 상표를 포함한다.
      - LCD 값 `boarding.lcdStatus`: value는 '승차 준비' 또는 '집중동행카드'.
      - 카드 번호는 어디에도 쓰지 않는다(BR-4).
    - 화면에 보이는 문구: 터치 안내 `boarding.tapHint`, 저장 실패 `boarding.saveFailure`.
    - 연출(표현 레이어, T6에 포함):
      - 진입: 단말기 0.12s, 카드 0.38s(아래에서 위로), 올림 안내 2회, 점선 테두리 깜빡임.
      - contacting: 300ms 접촉 이동.
      - fading: 450ms opacity.
      - 터치: 살짝 튀기.
      - 동작 줄이기면 모두 생략한다(AC-22, FR-16). 판정은 리뷰로 하고, 테스트는 햅틱 0과 sleep 요청 목록으로 대신한다.
    - 생명주기:
      - `@State private var isVisible`: `onAppear`에서 true, `onDisappear`에서 false로 두고 `cancelPendingTransition()`을 호출한다.
      - `.onChange(of: scenePhase)`: `.background`이면 `cancelPendingTransition()`, `.active`이면 `returnToForeground()`. `.inactive`는 무시한다.
      - `onFinished`: `isVisible && scenePhase == .active`일 때만 `withTransaction(disablesAnimations) { model.finishBoardingTransition() }`.
    - 글꼴: LCD와 카드는 `dynamicTypeSize(.large)`로 고정한다(PassFace 관례). 안내 문구는 `...accessibility3`까지 허용한다.

14. **`ios/FocusMate/JourneyView.swift`(신규, 시안 DO8HO)**
    - `.awaitingDeparture`일 때: 출발 안내.
      - 어두운 그라데이션, 버스 아이콘, 같은 자리에 문장 1개(`journey.briefingSentence`, value는 현재 문장). 동작 줄이기면 세 문장을 세로로 모두 보인다.
      - '시작'(`journey.start`): `@AccessibilityFocusState`를 `focusTarget`과 연결한다.
      - `ScrollView` + `frame(minHeight:)`로 가운데 정렬한다(AC-23).
      - `navigationBarBackButtonHidden(true)`, `toolbar(.hidden, for: .navigationBar)`.
      - 노선, 버스, 정류장 정보는 표시하지 않는다.
    - `.departed`일 때: 임시 화면 `screen.journey`, 제목 "여행"만. 왼쪽 위 기본 뒤로가기로 메인에 간다(Q2). 남은 시간과 진도는 없다.
    - 생명주기: `.task { await begin }`. `scenePhase == .background`이면 `reset()`, `.active`로 돌아오면 다시 `begin`해서 처음부터 보여 준다.
    - 출발 확인 저장 실패: `journey.saveFailure`.

15. **`ios/FocusMate/DestinationScreen.swift`**
    - 현재: profile만 공통 체인 밖에서 그린다(`:10-35`).
    - 변경: `.board`, `.boarding`, `.journey`도 체인 밖에서 그린다(자체 여백, 빈 제목). `services: JourneyServices` 프로퍼티를 추가한다. 각 View가 컨트롤러를 `@State`로 소유하며, 진입할 때마다 새로 만든다.

16. **`ios/FocusMate/JourneyServices.swift`(신규)**
    - `struct JourneyServices { haptics: IssuanceHaptics; announcer: AccessibilityAnnouncing; sleep: (Duration) async -> Void; boardingHoldSleep: ((Duration) async -> Void)?; forcedReduceMotion: Bool; makeBoarder: @MainActor (AppModel) -> JourneyBoarding }`
    - 운영 기본값: `CoreHapticsIssuancePlayer`, `SystemAccessibilityAnnouncer`, `Task.sleep`, hold 없음, `false`, `{ $0 }`.
    - 화면이 쓰는 동작 줄이기 값은 `시스템 accessibilityReduceMotion || forcedReduceMotion`이다. 기존 `test.reduceMotion` 진단의 의미(시스템 값)는 바꾸지 않는다.
    - `FocusMateApp`에서 조립한다(`ios/FocusMate/FocusMateApp.swift:15-44`, `:66-69`).

17. **`ios/FocusMate/PreparationView.swift`**
    - 버튼 동작을 `:178`의 `model.confirmPreparation()`에서 `model.showBoardingPass()`로 바꾼다. 비활성 조건(`:185`)은 그대로 둔다.
    - `test.preparedPreparation` 진단(`:190-209`)을 RootView 전역 진단으로 옮긴다.

18. **`ios/FocusMate/RootView.swift`**
    - `.main` 분기(`:150-163`)를 `ScrollView`로 감싼다.
    - active가 있으면 정류장 아래, 메뉴 위에 안내 `main.activeJourney`(`.combine`)를 넣는다. 문구: "진행 중인 여정이 있어요" / "여행 시작하기를 누르면 이 여정은 기록 없이 정리돼요". 기존 secondary 텍스트 표현을 따른다.
    - 메뉴 라벨은 `destination.mainMenuTitle`. `.preparation`의 동작은 `model.startTripFromMain()`이다.
    - DEBUG 추가: `test.preparedPreparation`(이동해 옴), `test.releaseBoardingHold` 버튼(기존 `test.releaseIssuance`와 같은 trailing VStack).

#### F. UI 테스트 지원

19. **`ios/FocusMate/UITestBootstrap.swift`**
    - 시드(`:94`, `:96-109`): v3 `LocalSnapshotStore.save`로 만든다.
      - `"activeJourney"`: `readySnapshot.issuingCard(fixedCard)` + active(seoulForest, -1, 60분, busID "2014", destinationStopID "seongsuDong", 태그 reading, 할 일 "시드 여정", bus, `.awaitingDeparture`, 진도 0, 고정 id와 boardedAt).
    - 인자 확장:
      - `--fm-ui-save`(`:42-44`): `fail`과 `fail-once-boarding`을 허용한다.
        - `fail-once-boarding`은 `UITestBoardingSaveFailure`(`UITestCardSaveFailure`의 arm/consume 패턴, `:234-245`)를 쓴다.
        - `JourneyServices.makeBoarder`가 `ArmingBoarder(base: model, failure:)`를 돌려준다. 이 래퍼는 `boardJourney` 직전에만 arm한다. `writeData`는 consume에 성공하면 throw한다.
        - `applySaveScenario`는 `fail`에서만 동작한다.
      - `--fm-ui-boarding-hold manual`: 신규 `UITestHoldGate`를 쓴다.
        - 다중 대기자 대기열을 지원한다. `wait`는 continuation을 배열에 추가하고, `release()`는 현재 대기 중인 continuation을 모두 resume한다.
        - `releasedEarly` 플래그는 없다. 테스트는 phase가 `held`인 것을 확인한 뒤 해제한다.
      - `--fm-ui-reduce-motion on`: `forcedReduceMotion = true`.
      - `--fm-ui-route boarding`
        - 시드 `ready`에서만 허용한다.
        - `start()` 뒤에 `journeyPlan.setMinutes(60)` → `choose(busID: "2014")` → `preparation.chooseTag("reading")` → `setTask("라우트 할 일")` → `confirmPreparation()` → `path = [.time, .preparation, .board, .boarding]` 순서로 상태를 만든다.
        - 저장은 하지 않는다. U1과 U3에서는 쓰지 않는다.
    - 진단은 꼭 필요한 것만 둔다.
      - `test.boarding`(BoardingTagView DEBUG): `{"phase","offsetY","showsTapHint"}`
      - `test.briefing`(JourneyView DEBUG): `{"index","showsAll","showsStart","focus"}`
      - `test.activateBoardingCard`: 숨은 버튼. `accessibilityAction`과 같은 `controller.activate` 경로를 탄다.
      - `test.releaseBoardingHold`
      - `test.preparedPreparation`(이동)
      - 쓰기 카운터는 두지 않는다. 저장 횟수 불변(AC-12)은 `test.persistedBytes`와 `test.snapshot`의 `journey.active.id` 불변으로 단언한다.
    - 햅틱과 낭독은 기존 `UITestFeedbackRecorder`를 주입해 쓴다(`:204-214`, `test.hapticCount`, `test.announcements`).
    - 시각 HH:mm와 날짜는 UI에서 정규식으로만 본다. 고정값 검증은 단위 테스트가 맡는다.
    - **`ios/FocusMateUITests/UITestLaunchSupport.swift:13-29`**: `launch`에 `boardingHold:`, `reduceMotion:`, `route:` 편의 인자를 추가한다.

20. **문서**(T9)
    - `docs/FLOWS.md:14-15`: board/boarding 행의 저장 열을 갱신하고, `:62`가 폐기됐다는 메모를 단다. 계약 문서 정리 자체는 별도 건이므로 메모만 남긴다.
    - `docs/CURRENT-STATE.md`의 저장 절: v3 `journey.active`는 null 또는 객체, 최대 1건, 메인 '여행 시작하기'에서 자동 폐기.
    - `.dev/plan.md` W05 인계: 새 필수 필드를 추가하면 v4로 올린다. 카탈로그 조회는 실패 시에도 동작해야 한다(graceful).

### 의존성 및 영향도
- 새 외부 의존성은 없다. iOS 17.0과 Swift 5 기준이다(`project.pbxproj:54-55`).
- 저장소 영향
  - active가 null인 v1/v2/v3 파일은 영향이 없다.
  - v3의 active가 처음으로 실제 값을 가진다.
  - v2 파일은 계속 null만 허용한다.
- `.dev/plan.md:63` W04 인계("카탈로그 밖 정류장 id", "실행 중 현재 정류장 변경 시 선택 무효화"): W04는 현재 정류장을 바꾸지 않는다. 카탈로그 밖 정류장이면 `journeyOrigin`이 nil이라 시간 선택 단계에서 이미 막힌다. 따라서 변경 없이 인계 문서만 갱신한다.
- 같은 실행 안의 `journeyPlan`과 `preparation` 초안은 승차 뒤에도 유지된다(기존 왕복 유지 동작).

**기존 테스트 영향**
- 메인 라벨 변경('여행 준비' → '여행 시작하기'). 아래는 모두 식별자 `open.preparation`으로 찾도록 바꾼다.
  - `ios/FocusMateUITests/PreparationFlowUITests.swift:67`, `:82`, `:107`, `:135`
  - `ios/FocusMateUITests/Phase1FlowTests.swift:50`
  - `ios/FocusMateUITests/PreparationEditorUITests.swift:240`
- `ios/FocusMateUITests/PreparationEditorUITests.swift`: 확정하면 승차권으로 이동하므로 진단을 RootView로 옮긴다.
  - 진단 이동만으로 유지되는 테스트: AC9(`:90-93`), AC14-16(`:139-140`), AC19(`:152-153`), AC20(`:168-169`), AC24-25(`:202-204`), AC23(`:215-216`).
  - `testAC4_AC12`(`:39-54`)는 흐름을 바꾼다. 확정 → `screen.board` → 뒤로 → 수정 → 다시 확정 → `screen.board`. active null 단언은 유지한다.
- `ios/FocusMateUITests/PreparationFlowUITests.swift:33-45`: 기존 비활성 단언을 유지하고 AC-2 확장(U2)을 더한다.
- `ios/FocusMateTests/AppFoundationTests.swift:205-229`(main 밖에서 open 무시), `:232~`(메인 왕복 무쓰기): 유지된다. `startTripFromMain`은 active가 없으면 쓰지 않는다.
- `ios/FocusMateTests/SnapshotCodecTests.swift:130-141`, `ios/FocusMateTests/AppSnapshotSectionsTests.swift:166-186`: 유지된다. v2의 "미정의 원소" 주석만 "v2는 null만 허용"으로 고친다.
- `ios/FocusMateTests/CardCustomizationAppModelTests.swift:174`: 주석만 갱신한다.
- 메인을 ScrollView로 감싸므로 `Phase1FlowTests`, `LargeTextUITests`, `ProfileUITests`의 메인 요소 탐색을 회귀로 실행한다.

**하위 호환성**: v3를 유지한다(상세 설계 A-3).

#### 기존 구조와의 차이
- **경로 통째 교체**: 지금까지는 append/removeLast와 `path = [.time]`(`ios/FocusMate/AppModel+JourneyStart.swift:29`)만 썼다. 이번에는 `path = [.journey]`로 경로를 통째로 바꾸고, 뷰가 보이는 동안에만 수행한다.
- **컨트롤러 내부 Task와 토큰 2종**: `CardIssuanceController`는 async 메서드였다. 승차 태그는 동기 제스처 콜백에서 시작하므로 컨트롤러가 내부 Task를 소유한다. 저장(recognitionID)과 전환(transitionToken)을 분리해, 전환 취소가 저장을 막지 않게 한다. Task 핸들은 테스트에 노출한다.
- **동작 줄이기 시 햅틱**: 발급은 동작 줄이기와 무관하게 진동한다(`ios/FocusMate/CardIssuanceController.swift:61-62`). 승차는 PRD FR-16에 따라 진동을 생략한다.
- **동작 줄이기 강제 주입**: 기존 화면은 시스템 값만 읽었다. UI 테스트를 위해 `forcedReduceMotion`을 OR로 합친다. 기존 진단의 의미는 그대로다.
- **v2 journey 전용 DTO**: `LegacyCardV2DTO` 관례를 따른다(`ios/FocusMate/SnapshotCodec.swift:10-24`).
- **준비 확정 진단 위치**: 화면 국소 진단에서 RootView 전역 진단으로 옮긴다.
- **메인 버튼 라벨**: `Destination.title`과 분리한 `mainMenuTitle`을 쓴다.

### 구현 순서
태스크는 AC 묶음 단위다. 같은 파일을 고치는 태스크끼리는 의존을 둔다. T1, T2, T5는 서로 병렬로 진행할 수 있다. T3과 T4는 각각 T1, T2 뒤에 병렬로 진행할 수 있다.

| # | 우선 | 태스크 | 대상 AC | 신규/수정 파일 | 테스트 파일 | 의존 |
|---|---|---|---|---|---|---|
| T1 | Must | 진행 여정 저장 형식 | AC-11(내용), AC-19(저장 단), AC-24(근거), BR-5, BR-8 | 신규 `JourneySnapshot.swift` / 수정 `JourneySection.swift`, `AppSnapshot.swift`, `SnapshotCodec.swift`, `PreparationDraft.swift` | `JourneySnapshotTests`(생성, 출발 확인, 검증 위반별, 팩토리 초 내림), `JourneySnapshotStorageTests`(왕복, v3 객체, v2 null만, `{}`/"x" 손상, 위반 시 invalidState와 바이트 불변, null 파일 재저장 동일), `SnapshotCodecTests` 주석 | 없음 |
| T2 | Must | 순수 규칙 | AC-3(값), AC-5(HH:mm), AC-6·7·9·10(계산), **AC-8(주 검증)**, AC-22(타이밍), BR-7 | 신규 `BoardingRules.swift`, `BoardingPassContent.swift` / 수정 `IssuanceHapticPattern.swift` | `BoardingRulesTests`(29.9/30/30.1%, clamp ±100→±26·위쪽·+100→+20, tap 7.9/8.0, 카드 폭 268·238·300에서 activationOffset의 isContact가 true, 동작 줄이기 0, Clock UTC/Asia/Seoul), `BoardingPassContentTests`(값, 글꼴 경계, 라벨에 번호·분 포함, 화면 필드에는 없음) | 없음 |
| T3 | Must | 모델·내비게이션·메인 동작 | AC-1, 2, 4, 11(1건), 13(경로), 20(모델), 21(기존 active 불변·실패 시 불변), 25, 26(경로), 27, BR-9 | 신규 `AppModel+Boarding.swift` / 수정 `AppModel.swift`, `AppModel+JourneyStart.swift` | `BoardingModelTests`(showBoardingPass 연타 1회, 미완성 false, board/boarding open 가드, openBoarding 쓰기 0, boardJourney A→B 교체 1건, 저장 후 path 불변, 실패 시 snapshot 불변과 saveFailure, finishBoardingTransition `[.journey]`와 `path.last != .boarding`이면 무시, confirmDeparture 멱등, startTripFromMain 무쓰기/폐기→time/폐기 실패 시 path 불변, records 불변, `mainMenuTitle`) | T1 |
| T4 | Must | 승차 태그 컨트롤러 | AC-6, 7, 8(연결), 9, 10, 11, 12, 13, 14, 15, 16, 21, 22 | 신규 `BoardingTagController.swift` | `BoardingTagControllerTests`(아래 목록), `BoardingTestDoubles`(`FakeJourneyBoarder(results:)`, `QueuedSleep`) | T2 |
| T5 | Must | 출발 안내 컨트롤러 | AC-17(순서·시작·포커스 값), 18, 19(호출 없음), 20 | 신규 `DepartureBriefingController.swift` | `DepartureBriefingControllerTests`(순서, 각 시점 showsStart/focus, 동작 줄이기 sleep 0, reset 뒤 이전 sleep resume 무효(`QueuedSleep`), confirm 전 false, 실패 유지 후 재시도 성공) | 없음 |
| T6 | Must | 화면·연출·연결 | AC-1~5, 9, 13, 17, 18, 20, 22(표현), 23, 24, 26~28 | 신규 `JourneyServices.swift`, `BoardingPassView.swift`, `BoardingTagView.swift`, `JourneyView.swift`, `TicketDots`/`BoardMap` 자산 / 수정 `DestinationScreen.swift`, `PreparationView.swift`, `RootView.swift`, `FocusMateApp.swift` | 표현은 리뷰, 동작은 T8의 UI 테스트 | T3, T4, T5 |
| T7 | Must | UI 테스트 부트스트랩 | 전제(AC-10, 15, 21, 22, 24 시드) | 수정 `UITestBootstrap.swift`(activeJourney 시드, fail-once-boarding, `UITestHoldGate`, reduce-motion, route boarding), `UITestLaunchSupport.swift` | 인자 파싱은 기존 관례가 있으면 확장 | T1, T6(`JourneyServices`) |
| T8 | Must | UI 테스트 U1~U11 + 기존 테스트 수정 | 아래 표 | 수정 `PreparationEditorUITests.swift`, `PreparationFlowUITests.swift`, `Phase1FlowTests.swift` | 신규 `BoardingFlowUITests`, `BoardingTagUITests`, `ActiveJourneyMainUITests`, `BoardingLargeTextUITests` | T6, T7 |
| T9 | Should | 문서 갱신 | FR-15(임시 동작 명시) | 수정 `docs/FLOWS.md`, `docs/CURRENT-STATE.md`, `.dev/plan.md` | 없음 | T8 |

**T4 단위 테스트 목록** (`SuspendingSleep`(contact·fade), 별도 hold용 sleep, `FakeIssuanceHaptics`, `RecordingAnnouncer` 재사용 — `ios/FocusMateTests/CardIssuanceTestDoubles.swift:11-91`)
- AC-6: `dragChanged`만으로 contacting, 햅틱 1, offset이 clamp 값이다.
- **불변식**: `dragChanged`(작은 이동) → `dragEnded`(임계를 넘는 이동)는 인식하지 않고 원위치로 돌아간다. 이 불변식이 있으므로 UI 테스트에서 끌고 놓은 뒤 햅틱 1과 LCD '집중동행카드'가 보이면, 인식이 `dragChanged` 경로(손 떼기 전)로 연결됐다는 증거가 된다.
- AC-8: `dragChanged` 순서에 따른 `cardOffset` clamp 연결.
- AC-11: 요청 `[300ms]` → resume → `await pendingSave?.value` → calls 1, held, `onFinished` 0.
- AC-12: held에서 drag, activate, dragEnded를 보내도 calls, 햅틱, 낭독이 불변이다.
- AC-13: hold resume → fading → fade resume → `await pendingTransition?.value` → `onFinished` 1회. 콜백 안에서 `phase == .finished`.
- 취소:
  - (1) contacting 중 cancel → contact resume → `await pendingSave` → calls 1, 낭독 1, abandoned, hold 요청 없음, `pendingTransition == nil`.
  - (2) held 중 cancel → hold resume → `await pendingTransition` → `onFinished` 0.
  - (3) fading 중 cancel → `onFinished` 0.
  - (4) dragging 중 cancel → `.zero`, ready, calls 0.
  - (5) abandoned에서 drag와 activate 무시.
- 복귀: abandoned에서 `returnToForeground` → ready, offset `.zero`, LCD ready. 다시 activate하면 calls 2(교체). contacting 중 cancel → `returnToForeground` → 저장 성공 뒤 바로 ready.
- **실패 케이스**: `results [false, true]`
  - 1회차: failed, `showsSaveFailure`, `.zero`, 실패 낭독, 성공 낭독 0.
  - 재시도: held.
  - contacting 중 cancel 뒤 저장 실패: failed, 실패 낭독, hold 없음.
- AC-22: 동작 줄이기에서 햅틱 0, 요청에 300과 450 없음, 1400 있음, 낭독 즉시.
- AC-9: tapSlop 미만 `dragEnded` → `tapBounceCount` 1, 힌트, calls 0.
- AC-10: activate → `activationOffset`, 낭독 "집중동행카드 인식됨, 승차했습니다" 1회.

**T8 UI 테스트 배분** (testability.md U1~U11)

| # | 파일 | AC | 진입 / 핵심 단언 |
|---|---|---|---|
| U1 | BoardingFlowUITests | 1, 3, 4, 5, 26 | 실제 흐름(시드 ready). 확정 → `screen.board`, 항목 값 → `board.route` 라벨에 번호·분이 있고 staticTexts 전체에는 0건 → 탑승 → 태그 화면 요소(LCD 정규식, 카드), 낭독 라벨(title·terminal) → 뒤로 → 뒤로 → `screen.preparation`, `persistedBytes` 불변, active null |
| U2 | PreparationFlowUITests 확장 | 2 | 미완성에서 `preparation.confirm` 비활성, 탭해도 `screen.board` 없음 |
| U3 | BoardingFlowUITests | 14, 25, 28 | 실제 흐름 + hold manual. A 인식 → held 확인 → 뒤로(전환 취소) → 해제 → `screen.journey` 없음, active A → 준비 수정 → B 인식 → active 1건이고 task가 B → 메인까지 뒤로 → `main.activeJourney` |
| U4 | BoardingTagUITests | 6, 11, 12, 13, 17, 19, 20 | route boarding + hold manual. 끌어서 인식 → 햅틱 1, LCD '집중동행카드', `offsetY < 0` → active 1건, `screen.boarding` 유지 → 재끌기·activate 후 `persistedBytes`와 active.id 불변, 햅틱·낭독 수 불변 → 해제 → `screen.journey` 안내 → 최종 '버스 출발합니다', `journey.start` hittable, `test.briefing.focus == "start"`, 노선·버스·정류장 문자열 0건 → 시작 전 phase awaiting, 진도 0 → 시작 → departed, 진도 0, `screen.journey` → 뒤로 → 메인 |
| U5 | BoardingTagUITests | 7, 9, 16 | route boarding. 짧은 끌기 → 햅틱 0, '승차 준비', `offsetY == 0` → 터치 → `boarding.tapHint` → 숨김·복귀 → 전환 없음, active null |
| U6 | BoardingTagUITests | 10 | route boarding. `test.activateBoardingCard` → LCD, 낭독 1회, active 1건 |
| U7 | BoardingTagUITests | 15 | route boarding + hold manual. **먼저 `press(.home)`으로 scenePhase가 background로 전환되는지 확인하는 스파이크를 T8 초기에 수행한다(저장소 최초 도입).** 인식 → held → `press(.home)` → `app.activate()` → `test.boarding.phase == "ready"`, LCD '승차 준비' → 해제 → `screen.journey` 없음, active.id 불변 |
| U8 | BoardingTagUITests | 21 | 시드 ready + route boarding + `--fm-ui-save fail-once-boarding`. 1회차: `boarding.saveFailure`, LCD '승차 준비', `persistedBytes` 불변, active null → 다시 끌기 → active 1건 → 전환. 기존 active가 불변인지는 T3 단위 테스트가 맡는다. |
| U9 | BoardingTagUITests | 22, 18 | route boarding + reduce-motion on + hold manual. 인식 → 햅틱 0, LCD, `screen.journey` 없음 → 해제 → 세 문장 동시, `journey.start` |
| U10 | ActiveJourneyMainUITests | 24, 27 + 폐기 실패 | 시드 activeJourney → relaunch → 메인, `main.activeJourney`, 자동 이동 없음, active 1건 → `open.preparation` → active null, `screen.time`, records 0. 별도 실행: activeJourney + `--fm-ui-save fail` → 탭 → 메인 유지, `storage.saveFailure`, 안내 유지 |
| U11 | BoardingLargeTextUITests | 23 | XXXL + reduce-motion on, 시드 activeJourney. `open.preparation` hittable → 폐기 → 시간 → 준비 → `board.boardBus` hittable → 태그 → `test.activateBoardingCard` → `journey.start` hittable |

- AC-8은 UI 테스트를 두지 않는다. T2의 `clampedOffset`과 T4의 연결 테스트가 주 검증이다. 손을 떼면 원위치로 돌아가고, 위로 끌면 그 전에 인식되기 때문이다.
- AC-17의 실제 VoiceOver 포커스 이동과 AC-10의 실제 VoiceOver·Full Keyboard Access 활성화는 원리상 자동 검증이 안 된다. 신뢰 기록에 남기고 W14 실기기에서 확인한다.

### 탐색 추가 항목
- `ios/FocusMate/AppModel.swift:5-16` → Destination. `:32-70` → 준비 확정·요청 소비. `:184-206` → save/persist. `:201` → route 변경 시에만 path 초기화. `:250-257` → open/goBack 가드
- `ios/FocusMate/AppModel+JourneyStart.swift:35-47` → 연타 가드 관례, mainMenu, mainMenuTarget
- `ios/FocusMate/AppSnapshot.swift:10-15`, `:63-87` → 검증 이슈, validate, launchRoute
- `ios/FocusMate/JourneySection.swift:4-28` → 빈 enum, active 필수·null 규칙
- `ios/FocusMate/SnapshotCodec.swift:10-34`, `:38`, `:70-77` → v2 DTO 관례, 버전 3, migrateV2
- `ios/FocusMate/LocalSnapshotStore.swift:104-115` → save 시 validate, 보호 파일 쓰기 차단
- `ios/FocusMate/CardSection.swift:24-41`, `ios/FocusMate/CardSnapshotFactory.swift:4-19` → ISO8601 직접 인코딩, 주입형 생성기
- `ios/FocusMate/PreparationDraft.swift:3-35`, `:63-92`, `:93-142` → 태그·소리 enum, 완성 조건, PreparedJourneyDetails
- `ios/FocusMate/RouteData.swift:10-37`, `:77-88`, `ios/FocusMate/JourneyPlanner.swift:25-40`, `ios/FocusMate/JourneyPlanDraft.swift:4-11` → 카탈로그, 거리, 여정 선택
- `ios/FocusMate/RootView.swift:28-31`(메인 공용 저장 실패 문구), `:87-97`(테스트 버튼), `:150-163`(메인), `:214-230`(진단)
- `ios/FocusMate/DestinationScreen.swift:10-35` → 목적지 분기
- `ios/FocusMate/PreparationView.swift:175-187`, `:190-209`, `:401` → 확정 버튼, 확정 진단, scenePhase 관례
- `ios/FocusMate/CardIssuanceController.swift:19-69`, `ios/FocusMate/CardIssuanceView.swift:47-51` → 주입형 컨트롤러, focusTarget, 하단 고정 CTA
- `ios/FocusMate/IssuanceFeedback.swift:4-13`, `ios/FocusMate/IssuanceHapticPattern.swift:24-33` → 햅틱·낭독 프로토콜, 패턴
- `ios/FocusMate/PassFace.swift:4-18` → `allowsHitTesting(false)`(래퍼에 제스처 필요), aspectRatio
- `ios/FocusMate/PassIdentity.swift:5` → 카드 이름
- `ios/FocusMate/TimeSelectionView.swift:11-37` → 큰 글자 고정 영역
- `ios/FocusMate/FocusMateApp.swift:15-44`, `:66-91` → 의존성 조립, start 순서(prepare → start → applySaveScenario, 여기에 route 적용 추가)
- `ios/FocusMate/UITestBootstrap.swift:40-55`, `:94-145`, `:204-214`, `:217-232`, `:234-245` → 인자, 시드, 실패 저장소, 기록기, 기존 게이트(releasedEarly), fail-once 원형
- `ios/FocusMateTests/CardIssuanceTestDoubles.swift:11-91` → 재사용 대역. SuspendingSleep은 단일 슬롯이라 QueuedSleep을 신설한다.
- `ios/FocusMateTests/SnapshotCodecTests.swift:115-151`, `ios/FocusMateTests/AppSnapshotSectionsTests.swift:166-186` → journey 골격 계약, 모르는 키 무시
- `ios/FocusMateTests/AppFoundationTests.swift:205-229` → allCases open 무시
- `ios/FocusMateUITests/PreparationEditorUITests.swift:36-56`, `:238-245`, `:289-297` → 확정 뒤 같은 화면에서 진단을 읽는 테스트, '여행 준비' 탐색
- `ios/FocusMateUITests/PreparationFlowUITests.swift:67`, `:82`, `:107`, `:135`, `ios/FocusMateUITests/Phase1FlowTests.swift:50` → '여행 준비' 라벨 탐색(식별자로 교체)
- `ios/FocusMateUITests/UITestLaunchSupport.swift:13-37` → 실행 하네스, relaunch
- `ios/FocusMate.xcodeproj/project.pbxproj:22-26`, `:54-55` → 동기화 그룹, iOS 17.0
- `designs/revised/pen-updates/card-briefing-2026-10-13/kxUUR.png` → 카드 폭 약 268pt, 단말기 274, 태그 영역 238×160(2x 측정)
- `designs/final/animation-preview.html:823` → 정류장 글꼴 크기 규칙
- `designs/assets/next-stop/ticket/ticket-seoul-dots.png`, `designs/assets/next-stop/revised/board-image-0.png` → 승차권 질감, 지도 배경 후보
- `docs/FLOWS.md:14-15`, `:28-37`, `:54-64`, `docs/CURRENT-STATE.md:65` → 계약과 저장 상태 문서(갱신 대상)
- `.dev/feat-boarding-pass-tag/testability.md` → C1~C9 전략, U1~U11 배분, 필수 보완 1~4

---

## 확인이 필요한 사항

추가 확인 사항 없음. 설계가 완료되었습니다.

---

## Testability 평가 (test-architect)

평가 근거로 읽은 파일은 설계서, PRD 수용 기준(AC-1~28), 코드 맵, frontend-testing.md(§2 레이어 분류, §4 셀렉터 규약)입니다. 실제 코드도 대조했습니다: `CardIssuanceController.swift`, `CardIssuanceTestDoubles.swift`, `UITestBootstrap.swift`, `UITestLaunchSupport.swift`, `LocalSnapshotStore.swift:104`.

러너 상태: XCTest 단위 테스트(`ios/FocusMateTests`)와 XCUITest(`ios/FocusMateUITests`)가 이미 있습니다. 실행 명령은 `python3 scripts/check-ios.py test <파일경로>`입니다. 동작 레이어 가운데 러너가 없는 곳은 없습니다.

결론: 7.5점으로 PASS이며, 아래 조건 6개를 붙입니다. 이 중 2건은 설계서가 제시한 검증 방법이 그대로는 성립하지 않는 결함입니다.
- AC-8: 손을 뗀 뒤에 위치를 읽는 방식이라, 그 시점이면 카드가 이미 원위치로 돌아가 있습니다.
- AC-21: 설계서가 고른 시드(진행 여정 보유)로는 승차 태그 화면까지 갈 수 없습니다.

---

### 컴포넌트별 테스트 전략

#### C1. JourneySnapshot / JourneySection / AppSnapshot.validate / SnapshotCodec (T1)
- **레이어**: 동작(상태·데이터 로직). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - JourneySnapshotTests: `boarding(details:cardID:id:boardedAt:)`가 위치·방향·시간·진도 0·할 일·태그·소리를 담고 phase가 `awaitingDeparture`인지 확인. `confirmingDeparture()`는 phase만 바꾸고 진도는 0 그대로인지 확인.
  - `ActiveJourneyValidationIssue`의 경우별 위반 테스트 10개.
  - `ActiveJourneyFactory`에 고정 `makeID`·`now`를 주입하고 초 단위 내림을 확인.
- **통합 테스트**
  - JourneySnapshotStorageTests: 실제 `LocalSnapshotStore`에 임시 파일 URL을 써서 다음을 확인.
    - 왕복 저장·읽기
    - v3 active 객체 읽기
    - v2는 null만 허용(`LegacyJourneySectionV2`)
    - `{}`·`"x"` 손상
    - 검증 위반 후보는 `invalidState`로 거절되고 파일 바이트가 변하지 않음
    - active가 null인 기존 파일은 다시 저장해도 바이트가 같음
- **모의 대상**: 없음(파일 시스템은 임시 디렉터리). 시계와 ID는 팩토리 주입.
- **격리 전략**: 값 타입과 순수 검증 함수라 완전히 격리됩니다.
- **AC 매핑**: AC-11(저장 내용), AC-19·BR-5(저장 단에서 awaiting이면 진도 0), AC-24(재실행 읽기의 근거), BR-8(필드가 단일 값)

#### C2. BoardingGeometry / BoardingTiming / BoardingClock (T2, 순수)
- **레이어**: 동작(순수 유틸). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - `overlapRatio`: 경계값 29.9%, 30%, 30.1%
  - `clampedOffset`: x=±100은 ±26으로, y가 태그 위쪽을 넘으면 `tagArea.minY - cardRest.minY`로, y=+100은 +20으로 잘리는지
  - `isTap`: 7.9와 8.0
  - `activationOffset`: 결과 위치에서 `isContact == true`이고 카드 위쪽이 태그 영역 아래쪽 가장자리 안에 있는지
  - `BoardingTiming.contact/fade(reduceMotion: true) == .zero`, hold는 1400 유지
  - `BoardingClock.text`: 고정 Date와 TimeZone(UTC, Asia/Seoul)으로 "HH:mm" 24시간 표기
- **통합 테스트**: 불필요
- **모의 대상**: 없음
- **격리 전략**: 입력이 CGRect·CGSize 값뿐입니다.
- **AC 매핑**: AC-5(HH:mm 포맷), AC-6·AC-7·AC-9 판정 계산, **AC-8 범위 제한의 주 검증 지점**, AC-10(활성 위치), AC-22(타이밍 0), BR-7

#### C3. BoardingPassContent (T2, 순수)
- **레이어**: 동작(포맷터). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - 출발·도착 이름, "12개", 거리 문자열, "지금", 날짜 `yyyy/MM/dd`(고정 now와 TimeZone)
  - 글꼴 크기 4/6/9자 경계(28/24/20/17)
  - `routeAccessibilityLabel`에 버스 번호와 분이 들어 있는지
  - 버스 번호·분이 화면용 필드(`stopsText`, `distanceText` 등)에는 들어 있지 않은지
- **통합 테스트**: 불필요
- **모의 대상**: 없음(`RouteStops`·`BusLine` 실제 카탈로그 사용)
- **격리 전략**: 순수 init입니다.
- **AC 매핑**: AC-3(값과 낭독 전용 정보). 글꼴 크기는 표현 쪽 경계이지만 규칙이 결정적이라 단위 테스트로 둬도 무방합니다.

#### C4. AppModel 확장: Destination 가드, AppModel+Boarding (T3)
- **레이어**: 동작(라우팅·가드와 상태 로직). 적합도 높음
- **러너**: XCTest
- **단위 테스트(BoardingModelTests)**
  - 진입과 가드
    - `showBoardingPass` 연타 시 path에 `.board`가 1회만 쌓임
    - 미완성이면 false, path 불변
    - `open(.board/.boarding)`은 `confirmedPreparation == nil`이면 무시, `open(.journey)`는 active가 nil이면 무시
    - `openBoarding`은 쓰기 0회
  - 승차 저장
    - `boardJourney`가 기존 active A를 B로 교체해 1건 유지
    - 저장 성공 후 `persist`가 path를 비우지 않음(launchRoute는 `.main` 유지)
    - 실패 시 snapshot 불변이고 `saveFailure`가 남음
  - 전환과 출발 확인
    - `finishBoardingTransition`은 `path == [.journey]`
    - `path.last != .boarding`이면 무시
    - `confirmDeparture`는 멱등이고 이미 `departed`면 쓰기 0
  - 메인에서 새 여행
    - `startTripFromMain`: active가 없으면 쓰기 0, 있으면 폐기 후 `.time`, 폐기 실패면 path 불변
  - records는 모든 경로에서 불변
- **통합 테스트**: 실제 `LocalSnapshotStore`(임시 파일)에 쓰기 횟수를 세는 `writeData` 클로저를 주입. 실패 시나리오는 `writeData`가 throw하도록 만듭니다(`LocalSnapshotStore`가 이미 클로저 주입을 지원하므로 새 모의 계층이 필요 없음).
- **모의 대상**: 파일 쓰기(`writeData` 클로저), `ActiveJourneyFactory`(고정 ID와 시계)
- **격리 전략**: `journeyFactory`를 기본값이 있는 init 인자로 받아 기존 호출부에 영향이 없습니다. 프로토콜 `JourneyBoarding`·`DepartureConfirming` 덕분에 컨트롤러 테스트가 AppModel 없이 돌아갑니다.
- **AC 매핑**: AC-1, AC-2(모델 단 "어떤 경로로도"), AC-4, AC-11(1건), AC-13(경로), AC-20(모델), AC-21(기존 active 불변. **이 AC의 "기존 진행 여정 포함 불변"은 여기서만 검증 가능**, 아래 지적 3 참고), AC-25, AC-26(경로), AC-27, BR-9

#### C5. BoardingTagController (T4) — 핵심 비동기 상태 기계
- **레이어**: 동작(상태 기계). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - 대역: `SuspendingSleep`(contact·fade용 1개, `holdSleep`용 1개를 따로 두어 단계를 구분), `FakeIssuanceHaptics`, `RecordingAnnouncer`, 신규 `FakeJourneyBoarder(results: [Bool], calls)`
  - **AC-6 놓기 전 인식**
    - `dragChanged`만 호출해도(`dragEnded` 없음) phase가 contacting, 햅틱 1, cardOffset이 clamp된 값
    - **불변식 테스트를 추가할 것**: `dragChanged(작은 이동)` 뒤 `dragEnded(임계를 넘는 이동)`를 보내면 인식하지 않고 원위치. 이 테스트가 있어야 UI 테스트의 "햅틱 1"이 "손 떼기 전 경로(dragChanged)로 인식됐다"는 증거가 됩니다(아래 AC-6 항목).
  - **AC-11 300ms 뒤 1회 저장**: 인식 → contact 수면 확인(`requested == [300ms]`) → `resume()` → `boarder.calls == 1`이고 phase는 held, hold 수면에서 멈춤, `onFinished` 미호출.
  - **AC-12 중복 무시**: held에서 `dragChanged`·`activate`·`dragEnded`를 보내도 calls, 햅틱, 낭독이 그대로.
  - **AC-13 전환**: hold `resume` → fading → fade `resume` → finished이고 `onFinished` 1회.
  - **세대 token 테스트(AC-14·15·16)**
    1. contacting 중 `cancelPendingTransition()` → 동기 저장으로 calls 1, phase abandoned → 남은 contact 수면 `resume` → **calls 여전히 1**(늦은 commit은 token이 달라 무효)
    2. held 중 취소 → hold `resume` → fading으로 가지 않고 `onFinished` 0
    3. fading 중 취소 → fade `resume` → `onFinished` 0
    4. dragging 중 취소 → offset `.zero`, ready, calls 0, 예약 Task 없음
    5. abandoned에서 `activate`·`drag`는 무시
  - **AC-21 저장 실패**: `results [false, true]`이면 첫 시도는 failed, `showsSaveFailure`, offset `.zero`, 실패 낭독. 다시 `activate`하면 성공해 held.
  - **AC-22 동작 줄이기**: 햅틱 0, `requested`에 300·450 없음, hold 1400은 요청됨, 낭독은 즉시.
  - **AC-9 터치**: tapSlop 미만의 `dragEnded` → `tapBounceCount` 1, `showsTapHint`, calls 0.
  - **AC-10 활성화**: `activate` → offset이 `activationOffset`이고 낭독 "집중동행카드 인식됨, 승차했습니다"가 1회.
- **통합 테스트**: 화면에서 `DragGesture` 연결은 C9 UI 테스트로.
- **모의 대상**: sleep(SuspendingSleep), 햅틱, 낭독, `JourneyBoarding`
- **격리 전략**: 생성자 주입으로 완전히 분리됩니다. 시간은 수면 주입으로 결정적입니다.
- **[필수 보완 1] 내부 Task 대기 수단이 없음**
  - 상황: 설계는 컨트롤러가 내부에서 `Task {}`를 시작합니다. token이 달라 Task가 다음 수면 없이 끝나는 경우, 테스트는 그 Task가 끝났는지 결정적으로 알 수 없습니다. `untilSuspended()`는 다음 수면이 있을 때만 쓸 수 있습니다. 그래서 위 1~3번 같은 "늦은 전환이 일어나지 않음"은 `Task.yield()`를 몇 번 돌리는 식의 비결정적 테스트가 됩니다.
  - 권고: `@ObservationIgnored private(set) var pendingTransition: Task<Void, Never>?`를 두고, 테스트가 `@testable`로 `await controller.pendingTransition?.value`를 기다리게 합니다. 이 형태를 설계 시그니처에 명시해야 합니다.
- **AC 매핑**: AC-6, 7, 8(cardOffset clamp 연결), 9, 10, 11, 12, 13, 14, 15, 16, 21, 22

#### C6. DepartureBriefingController (T5)
- **레이어**: 동작(상태 기계). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - `begin(reduceMotion: false)`를 `Task`로 시작: index 0 → 수면(1700) → `resume` → 1 → `resume` → 2이고 `showsStart`, `focusTarget == .startButton`. 각 시점에 `showsStart == false`, `focusTarget == nil` 확인.
  - `begin(reduceMotion: true)`: 수면 요청 0, `showsAll`, `showsStart`.
  - `reset()` 뒤 index 0, `showsStart` false. 이전 begin의 수면을 `resume`해도 index가 바뀌지 않음(token).
  - `confirm()`: `showsStart` 전에는 false이고 confirmer 호출 0. 실패하면 `showsSaveFailure`이고 `showsStart` 유지, 재시도 성공.
  - AC-19: 시작을 누르지 않고 마지막 단계까지 진행해도 confirmer 호출 0. 저장 진도 불변은 C1·C4가 담당.
- **[보완 2] SuspendingSleep 대기 슬롯이 1개뿐**
  - 상황: reset 뒤 다시 begin하는 시나리오에서는 수면 두 개가 동시에 걸립니다. 현재 `SuspendingSleep`은 continuation을 한 칸에만 담아 이전 것을 덮어쓰고, 덮인 continuation은 누수 경고를 냅니다.
  - 권고: `BoardingTestDoubles.swift`에 대기열형 `QueuedSleep`(대기 목록과 `resume(at:)`)을 두거나, 이 시나리오 테스트에서만 begin마다 sleep 인스턴스를 분리합니다.
- **모의 대상**: sleep, `DepartureConfirming`(FakeDepartureConfirmer)
- **격리 전략**: 생성자 주입입니다. 일시정지 조작과 남은 시간이 화면에 없다는 점은 구조로 보장됩니다.
- **AC 매핑**: AC-17(순서·시작·포커스 값), AC-18, AC-19(호출 없음), AC-20(confirm 경로)

#### C7. JourneyServices / FocusMateApp 조립 / UITestBootstrap 확장 (T6·T7)
- **레이어**: 동작(조립과 테스트 하네스). 단위 테스트 대상이 아니라 UI 테스트의 전제 조건입니다.
- **러너**: XCUITest(간접)
- **단위 테스트**: `UITestBootstrap` 인자 파싱(`--fm-ui-boarding-hold manual`, `--fm-ui-reduce-motion on`, 잘못된 값이면 `invalidArguments`)은 기존 관례가 있으면 확장합니다(선택).
- **통합 테스트**: 모든 UI 테스트가 이 조립을 통과합니다.
- **모의 대상**: `UITestFeedbackRecorder`(햅틱·낭독), `UITestIssuanceGate`(hold), `UITestWriteCounter`, `forcedReduceMotion`
- **격리 전략**: DEBUG 인자로만 켜집니다.
- **[필수 보완 3] AC-21 UI 시나리오의 전제가 성립하지 않음**
  - 상황: 설계는 "`--fm-ui-save fail`과 `activeJourney` 시드면 기존 저장 불변을 확인할 수 있다"고 적었습니다. 하지만 active 여정이 있는 메인에서 '여행 준비'를 누르면 `startTripFromMain`이 폐기 쓰기를 하고, 이 쓰기가 실패하면 이동하지 않습니다(설계 6번). 따라서 이 조합으로는 승차 태그 화면에 도달할 수 없습니다. 게다가 전체 실패 설정이라 AC-21의 "다시 태그할 수 있다(성공)"도 보일 수 없습니다.
  - 권고: 다음 중 하나로 정합니다.
    - (a) `--fm-ui-save fail-once-boarding` 신설. `UITestCardSaveFailure`처럼 승차 저장 직전에만 arm됩니다. 시드는 `ready`. 1회차는 실패(화면 유지, 안내, `persistedBytes` 불변), 2회차는 성공해 writeCount 1.
    - (b) UI는 시드 `ready`와 전체 실패로 "전환 없음·안내·바이트 불변"만 보고, "기존 active 불변"과 "재시도 성공"은 C4·C5 단위 테스트에 맡긴다고 설계서에 명시합니다.
    - (a)를 권장합니다.
- **AC 매핑**: AC-10(`test.activateBoardingCard`), AC-12(`test.writeCount`), AC-15·AC-22(hold 게이트, 동작 줄이기 강제), AC-24 시드

#### C8. BoardingPassView / JourneyView / RootView 메인 안내 / PreparationView 연결 / DestinationScreen (T6)
- **레이어**: 화면 조립(동작 부분만 대상). 지도 배경, TicketDots, 그라데이션, 버스 아이콘, 진입 연출, 점선 깜빡임, 접촉 이동·페이드 애니메이션, 정류장 글꼴 적용, "같은 자리" 배치는 **표현이라 범위 밖**(리뷰나 시안 대조).
- **러너**: XCUITest
- **단위 테스트**: 없음(로직은 C3·C4·C6로 이동됨)
- **통합 테스트**: 아래 UI 배분 참고
- **모의 대상**: 시드, 실패 저장소, 게이트, 기록기
- **격리 전략**: 데이터 출처가 `model.confirmedPreparation` 하나라 화면 쪽 분기가 적습니다.
- **셀렉터 규약(§4)**
  - 대체로 준수합니다. 설계가 `screen.*`, `board.*`, `boarding.*`, `journey.*`, `main.activeJourney` 식별자를 쓰고, 버튼은 라벨이나 식별자로 찾습니다. 프로젝트 관례(식별자 우선)와 일치합니다.
  - "보이지 않음" 단언은 `exists == false`가 아니라 다음처럼 둡니다.
    - 낭독 전용 요소는 hittable이 아니거나 화면에 보이는 텍스트 노드가 없음
    - 버스 번호·분은 `staticTexts` 라벨 전체에서 해당 문자열이 0건이고, `board.route` 라벨에는 포함됨
  - 색이나 크기를 단언하지 않습니다.
- **AC 매핑**: AC-1~5, 9, 17, 18, 20, 23, 24, 26~28 화면 동작

#### C9. BoardingTagView (T6) — 제스처·생명주기 연결
- **레이어**: 컴포넌트 동작(연결). 연출은 표현
- **러너**: XCUITest
- **통합 테스트**: 아래 "주요 AC의 XCUITest 결정적 검증 방법" 참고
- **AC 매핑**: AC-5~10, 12~16, 21, 22

---

### 주요 AC의 XCUITest 결정적 검증 방법

- **AC-6(놓기 전 인식)**
  - XCUITest는 손을 대고 있는 도중에 단언할 수 없습니다(`press(forDuration:thenDragTo:)`는 동기 호출이라 끝난 뒤에야 검사 가능).
  - 설계대로 "놓기 전"은 C5 단위 테스트가 보장합니다. 여기에 C5의 **불변식 "dragEnded는 절대 인식하지 않음"** 단위 테스트를 더하면, UI에서 끌고 놓은 뒤 햅틱 1과 LCD '집중동행카드'가 관찰되는 것만으로 화면이 `dragChanged` 경로로 연결됐다는 결정적 증거가 됩니다. onEnded에만 연결했다면 인식이 일어날 수 없기 때문입니다.
  - "카드는 그 자리에 머문다"는 놓은 뒤 `test.boarding.offsetY < 0`(원위치 아님)으로 단언합니다.
- **AC-8(범위)** — **[필수 보완 4] 설계서 방식이 성립하지 않음**
  - 상황: 설계는 "과도하게 끈 뒤 `test.boarding` offset으로 단언"한다고 적었습니다. 하지만 미인식 상태에서 손을 떼면 C5 규칙상 offset이 `.zero`로 돌아갑니다(AC-7). 놓은 뒤에는 clamp 흔적이 없습니다. 위쪽으로 넘치게 끌면 그 전에 30%에서 인식되므로 위쪽 한계도 UI에서 관찰할 수 없습니다.
  - 권고
    - 주 검증은 C2(`clampedOffset`)와 C5(`dragChanged` 순서 → `cardOffset`) 단위 테스트로 지정합니다.
    - UI가 필요하면 `test.boarding`에 `peakX`·`peakDown`(이번 끌기 중 관찰한 |x| 최댓값과 아래쪽 최댓값, 새 끌기에서 초기화)을 추가합니다. 좌우 100 끌기 → `peakX ≤ 26`, 아래 100 끌기 → `peakDown ≤ 20`. 위쪽 한계는 단위 테스트에만 둡니다.
- **AC-15(앱 숨김)**
  - 순서: `--fm-ui-boarding-hold manual`로 실행 → 끌어서 인식 → `test.writeCount == 1`이고 held 확인 → `XCUIDevice.shared.press(.home)` → `app.activate()` → `test.releaseBoardingHold` 탭.
  - 판정: 시간 경과에 기대는 부정 단언 대신 **양성 상태 `test.boarding.phase == "abandoned"`**를 기다려 단언합니다. 이어서 `screen.boarding`이 있고, `screen.journey`는 짧은 대기 뒤에도 없으며, writeCount 1입니다.
  - 이 저장소에는 아직 `press(.home)`을 쓰는 UI 테스트가 없습니다(검색 0건). 첫 도입이므로 시뮬레이터에서 scenePhase가 background로 넘어가는지 T8 초기에 한 번 확인해야 합니다.
  - contacting 중(300ms 창) 숨김은 UI로 다루지 않고 C5 단위 테스트로만 검증합니다.
- **AC-17(포커스)**
  - XCUITest는 VoiceOver 포커스를 읽을 수 없습니다. `test.briefing.focus == "start"`는 컨트롤러의 `focusTarget` 값일 뿐이고, `@AccessibilityFocusState` 연결 자체는 검증되지 않습니다.
  - 남는 위험을 명시합니다: 연결은 코드 리뷰와 W14 실기기 VoiceOver 확인으로 처리합니다(신뢰 기록에 남김).
  - 문장 순서는 C6 단위 테스트가 주 검증입니다. UI는 실제 1.7초 간격에서 첫 문장을 놓칠 수 있으므로(경쟁 상태) 최종 상태만 단언합니다: `briefingSentence` 값이 '버스 출발합니다', `journey.start`가 hittable, 노선·버스·정류장 문자열 0건, 일시정지 요소 0건.
  - 순서까지 UI로 보려면 `--fm-ui-briefing-step manual` 게이트(`UITestIssuanceGate` 재사용)를 선택적으로 둡니다. 비용 대비 효과가 낮아 필수는 아닙니다.
- **AC-22(동작 줄이기)**
  - 순서: `--fm-ui-reduce-motion on`과 hold 게이트로 실행 → 인식 → `test.hapticCount == 0`, LCD '집중동행카드', `screen.journey` 없음(게이트가 hold를 붙잡고 있어 유지 시간이 보존됨을 양성으로 확인) → 해제 → `screen.journey` 등장.
  - "접촉 이동·페이드 생략"은 C5에서 sleep 요청 목록으로 검증합니다.
  - "진입 연출·점선 깜빡임 없음"은 표현이라 범위 밖(리뷰)입니다.
- **AC-23(큰 글자)**
  - 기존 관례 인자 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`을 씁니다.
  - 테스트 1개로 연결합니다. activeJourney 시드 메인에서 `open.preparation`이 hittable이고 frame이 창 안에 있음 → 탭(폐기) → 시간 선택 → 준비 → `board.boardBus` hittable → 승차 태그 → `test.activateBoardingCard` → 출발 안내 `journey.start` hittable.
  - 동작 줄이기 강제를 함께 켜서 시간을 줄입니다.

### 비동기 sleep 주입과 세대 token의 단위 테스트 방법(요약)
1. contact·fade용 `SuspendingSleep`과 `holdSleep`용 `SuspendingSleep`을 따로 주입해 단계를 구분합니다.
2. 각 단계는 `await sleep.untilSuspended()`로 정지점에 도달했는지 확인한 뒤 상태를 단언하고 `resume()`합니다.
3. 취소 시나리오는 `cancelPendingTransition()` → `resume()` → **`await controller.pendingTransition?.value`**(필수 보완 1) → `boarder.calls`와 `onFinished` 호출 횟수를 단언합니다.
4. token 경쟁(contacting 중 취소 → 동기 commit → 늦은 commit 무효)은 calls가 정확히 1인지로 고정합니다.
5. 출발 안내의 reset·begin 재시작은 대기열형 sleep 대역(보완 2)으로 검증합니다.

### 단위/UI 배분(UI 테스트 과다 방지)
AC마다 UI 테스트를 하나씩 만들면 25개가 넘고, 대부분이 시간 선택 → 준비 흐름을 반복 통과합니다. 단위 테스트가 판정을 맡고 UI는 연결과 흐름만 맡는다는 원칙으로 **UI 테스트 11개**를 권장합니다.

| # | 파일 | 묶는 AC |
|---|---|---|
| U1 | BoardingFlowUITests | AC-1, 3, 4, 5, 26 (확정 → 승차권 항목 → 탑승 → 태그 화면 요소 → 뒤로 → 뒤로 → 준비, writeCount 0) |
| U2 | BoardingFlowUITests | AC-2 (기존 비활성 단언에 "승차권 보기 탭 후 `screen.board` 없음" 추가, 기존 테스트 확장으로 대체 가능) |
| U3 | BoardingFlowUITests | AC-14, 25, 28 (A 인식·hold 중 뒤로 → abandoned·1건 → 준비 수정 → B 인식 → `persistedBytes` 내용이 B → 메인까지 뒤로 → `main.activeJourney`) |
| U4 | BoardingTagUITests | AC-6, 11, 12, 13 → 이어서 AC-17, 19, 20 (끌기 인식 → hold 중 writeCount 1·태그 화면 → 재끌기·활성화로 불변 → 해제 → 여행 → 최종 안내 → 시작 → departed·진도 0, 뒤로가기는 메인) |
| U5 | BoardingTagUITests | AC-7, 9, 16, (8 peak 진단을 쓸 경우) (짧은 끌기 → 원위치 → 터치 → 안내 → 숨김·복귀 → writeCount 0·전환 없음) |
| U6 | BoardingTagUITests | AC-10 (`test.activateBoardingCard` → 낭독 1회·writeCount 1) |
| U7 | BoardingTagUITests | AC-15 |
| U8 | BoardingTagUITests | AC-21 (보완 3 방식) |
| U9 | BoardingTagUITests | AC-22 → 이어서 AC-18 |
| U10 | ActiveJourneyMainUITests | AC-24, 27 (시드 → relaunch → 안내·자동 이동 없음 → 여행 준비 → active 0·시간 선택·records 0) + 폐기 실패(save fail) 1건 |
| U11 | LargeText 계열 | AC-23 |

- **[권고 5] 비용 절감용 진입 인자**: 승차 태그 화면 진입 UI 테스트가 7개 이상이고 각각 준비 흐름을 통과하므로, DEBUG 인자 `--fm-ui-route boarding`을 검토합니다. 부트스트랩이 `journeyPlan`과 준비 초안을 채우고 `confirmPreparation`을 호출한 뒤 `[.time, .preparation, .board, .boarding]`를 쌓습니다. U1·U3은 실제 흐름을 유지하고 나머지만 이 인자를 씁니다. 필수는 아닙니다.
- **[권고 6] 기존 진단과 세는 기준 통일**: `test.writeCount`는 `modelStore.writeData` 성공만 셉니다. 시드 쓰기는 별도 store라 포함되지 않습니다. AC 단언은 "증가량 0 또는 1"로 쓰도록 테스트 명명 규칙에 남깁니다.

---

### Testability Score: 7.5/10 (동작 컴포넌트 기준)

- **강점**
  - 모든 동작 로직이 순수 규칙(C2·C3), 프로토콜 주입 컨트롤러(C5·C6), 기본값 있는 팩토리 주입 모델(C4)로 떨어져 있습니다.
  - 시간은 전부 주입 가능합니다.
  - 저장 실패는 기존 `writeData` 클로저로 격리됩니다.
  - 기존 대역(`SuspendingSleep`, `FakeIssuanceHaptics`, `RecordingAnnouncer`)과 UI 하네스(게이트, 기록기, `persistedBytes`, `relaunch`)를 그대로 재사용합니다.
- **감점**
  - 내부 Task를 기다릴 수단이 없음(필수 보완 1)
  - AC-8 UI 검증 방식이 성립하지 않음(필수 보완 4)
  - AC-21 UI 전제가 도달 불가(필수 보완 3)
  - AC-17 포커스 연결과 AC-10 실제 VoiceOver는 원리상 자동 검증 불가(남는 위험)
  - 출발 안내 재시작 대역의 슬롯 한계(보완 2)

### 판정: PASS (조건부)

- 7점 이상이므로 재설계는 필요 없습니다. 다만 red-green-refactor에 들어가기 전에, architect가 아래 4건을 설계서에 반영하는 경미한 수정을 권고합니다.
  1. `BoardingTagController`에 `pendingTransition: Task<Void, Never>?`(테스트에서 await 가능)를 명시
  2. C5 불변식 테스트 "dragEnded는 인식하지 않음"을 T4 목록에 추가하고, AC-6 UI 근거를 이 불변식으로 기술
  3. AC-21 UI 시나리오를 `fail-once-boarding` 인자(권장)나 "UI는 ready 시드 + 단위 테스트 분담"으로 수정하고, "activeJourney 시드면 불변 확인 가능" 문장 삭제
  4. AC-8의 주 검증을 C2·C5 단위 테스트로 지정하고, UI는 `peakX`·`peakDown` 진단을 쓰거나 생략
- 나머지(보완 2, 권고 5·6, AC-15·AC-22를 양성 상태 `abandoned`·게이트로 판정하는 방식)는 T4·T7·T8 구현 지침으로 넘기면 됩니다.
- 남는 위험(신뢰 기록 대상): AC-17의 실제 접근성 포커스 이동, AC-10의 실제 VoiceOver·Full Keyboard Access 활성화. 둘 다 W14 실기기에서 확인합니다.

---

### 탐색 추가 항목
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateTests/CardIssuanceTestDoubles.swift:60-91`: `SuspendingSleep`은 continuation을 한 칸에만 담습니다(보완 2의 근거).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/UITestBootstrap.swift:125-127`: `writeData`에서 실패를 주입하는 지점. `:139-145`의 `applySaveScenario`는 메인에서 정류장 저장 실패를 1회 일으킵니다(AC-21 시드 설계 시 고려). `:216-232`: `UITestIssuanceGate`의 `releasedEarly` 처리(hold 게이트 재사용 시 해제 순서 경쟁이 없음). `:234-245`: `UITestCardSaveFailure`의 arm/consume 패턴(보완 3의 fail-once 원형).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/UITestLaunchSupport.swift:13-37`: `launch`(hold 인자는 `--fm-ui-issue-hold` 고정이라 `boardingHold`·`reduceMotion` 인자 추가 필요), `relaunch`(시드 없이 같은 testID로 재실행, AC-24에 그대로 사용 가능).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/LocalSnapshotStore.swift:104-109`: save 시 validate 뒤 load 재확인. 단위 테스트에서 `writeData` 클로저로 실패와 횟수를 주입할 수 있습니다.
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/CardIssuanceController.swift:51-69`: 기존 컨트롤러는 async 메서드라 테스트가 Task 핸들을 쥘 수 있었습니다. 신규 승차 태그 컨트롤러는 내부 Task라서 이 이점이 사라집니다(필수 보완 1의 근거).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/LargeTextUITests.swift:77`, `CardIssuanceFlowTests.swift:9`: XXXL 실행 인자 관례(AC-23).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/` 전체: `XCUIDevice.shared.press(.home)`·`app.activate()` 사용 예가 0건이라, AC-15·AC-16은 이 저장소에서 처음 도입하는 방식입니다.

> 2회차 반영: 필수 보완 1~4(pendingSave/pendingTransition 노출, dragEnded 불변식, fail-once-boarding, AC-8 단위 주 검증), QueuedSleep, --fm-ui-route boarding 채택. design-critic MUST-ADDRESS 3건 반영(구조 검증 축소, 저장/전환 token 분리, background만 숨김+복귀 시 ready).
