## 설계 초안: 승차권 · 승차 태그 · 출발 안내 (W04, journey FR-11)

### 설계 규모
대형. 신규 화면 3개(승차권·승차 태그·여행/출발 안내), 진행 여정 저장 형식 신설, 메인·준비·저장소·UI 테스트 부트스트랩까지 바뀐다.

### 배경 및 목적
- 지금은 준비 화면의 '승차권 보기'(`preparation.confirm`)가 `confirmPreparation()`만 호출하고 화면을 옮기지 않는다(`ios/FocusMate/PreparationView.swift:175-187`). 승차권·승차 태그·여행 화면은 없다.
- `JourneySnapshot`은 빈 enum이라 `journey.active`가 null이 아니면 손상으로 처리된다(`ios/FocusMate/JourneySection.swift:4-9`).
- 메인 `open.preparation`은 시간 선택으로만 이동한다(`ios/FocusMate/RootView.swift:160-163`, `ios/FocusMate/AppModel+JourneyStart.swift:42-47`). 진행 중인 여정 안내는 없다.
- 목표: 준비 확정 → 승차권 → 승차 태그 → 접촉 성공 시 진행 여정 1회 저장 → 여행 화면(출발 안내) → '시작'으로 출발 확인. 이탈해도 저장이 사라지거나 중복되지 않고, 재실행하면 메인에서 진행 중인 여정을 알린다.

### 요구사항 및 수용 기준
`.dev/feat-boarding-pass-tag/prd.md` 원문을 그대로 따른다.
- [Must] FR-1~FR-14, BR-1~BR-6, BR-8, BR-9
- [Should] FR-15, FR-16, BR-7, QE-1~3
- AC-1~AC-28 전부. AC와 태스크의 대응은 "구현 순서"에 있다.

### 변경 범위

**영향 모듈**: 저장(AppSnapshot/JourneySection/SnapshotCodec), 내비게이션(AppModel/Destination/DestinationScreen), 준비(PreparationView), 메인(RootView), 카드 표시(PassFace 재사용), 피드백(IssuanceHaptics/AccessibilityAnnouncing 재사용), UI 테스트 부트스트랩.

**신규 파일** (`PBXFileSystemSynchronizedRootGroup` 구조라 pbxproj는 고치지 않는다. `project.pbxproj:22-26`)
- `ios/FocusMate/JourneySnapshot.swift`: 진행 여정 저장 값, 검증, 생성 팩토리
- `ios/FocusMate/AppModel+Boarding.swift`: 승차권 진입, 승차 저장, 여행 전환, 출발 확인, 메인 폐기
- `ios/FocusMate/BoardingRules.swift`: 순수 규칙(`BoardingGeometry`, `BoardingTiming`, `BoardingClock`)
- `ios/FocusMate/BoardingPassContent.swift`: 승차권 표시 값(순수)
- `ios/FocusMate/BoardingTagController.swift`: 승차 태그 상태 기계와 `JourneyBoarding` 프로토콜
- `ios/FocusMate/DepartureBriefingController.swift`: 출발 안내 상태와 `DepartureConfirming` 프로토콜
- `ios/FocusMate/BoardingPassView.swift`: 승차권 화면
- `ios/FocusMate/BoardingTagView.swift`: 승차 태그 화면(단말기, 태그 영역, 카드)
- `ios/FocusMate/JourneyView.swift`: 여행 자리표시와 출발 안내 화면
- `ios/FocusMate/JourneyServices.swift`: 화면에 넘기는 주입 묶음(햅틱, 낭독, sleep, 동작 줄이기 강제값)
- `ios/FocusMate/Assets.xcassets/TicketDots.imageset/`: `designs/assets/next-stop/ticket/ticket-seoul-dots.png` 복사(파일 있음 확인)
- `ios/FocusMate/Assets.xcassets/BoardMap.imageset/`: 승차권 정적 지도 배경. 후보는 `designs/assets/next-stop/revised/board-image-0.png`이고 구현 단계에서 그림을 보고 확정한다. 맞지 않으면 어두운 그라데이션으로 대체한다.
- 단위 테스트: `FocusMateTests/JourneySnapshotTests.swift`, `JourneySnapshotStorageTests.swift`, `BoardingRulesTests.swift`, `BoardingPassContentTests.swift`, `BoardingTagControllerTests.swift`, `DepartureBriefingControllerTests.swift`, `BoardingModelTests.swift`, `BoardingTestDoubles.swift`
- UI 테스트: `FocusMateUITests/BoardingFlowUITests.swift`, `BoardingTagUITests.swift`, `DepartureBriefingUITests.swift`, `ActiveJourneyMainUITests.swift`

**수정 파일**
- `ios/FocusMate/JourneySection.swift`: 빈 enum을 없애고 `active: JourneySnapshot?`가 신규 struct를 가리키게 함
- `ios/FocusMate/AppSnapshot.swift`: `SnapshotValidationIssue.invalidActiveJourney`, validate 확장
- `ios/FocusMate/SnapshotCodec.swift`: v2 journey 계약 고정(`LegacyJourneySectionV2`)
- `ios/FocusMate/PreparationDraft.swift`: `PreparationTagIcon`, `PreparationTagColor`, `JourneySound`에 `Codable` 추가(String raw라 동작은 같음)
- `ios/FocusMate/AppModel.swift`: `Destination`에 `board/boarding/journey` 추가, `open()`에 진입 가드, init에 `journeyFactory` 주입(기본값 있음)
- `ios/FocusMate/DestinationScreen.swift`: 신규 3개 목적지 분기, `services` 전달
- `ios/FocusMate/PreparationView.swift`: '승차권 보기' 동작 변경, 준비 확정 진단을 RootView로 이동
- `ios/FocusMate/RootView.swift`: 메인 진행 여정 안내, 메인 ScrollView, '여행 준비' 동작 교체, 진단·게이트 추가
- `ios/FocusMate/FocusMateApp.swift`: `JourneyServices` 조립
- `ios/FocusMate/IssuanceHapticPattern.swift`: `.boardingContact` 패턴 추가
- `ios/FocusMate/UITestBootstrap.swift`: 시드, 게이트, 동작 줄이기 강제, 쓰기 횟수
- 기존 테스트: `FocusMateUITests/PreparationEditorUITests.swift`, `FocusMateUITests/UITestLaunchSupport.swift`, `FocusMateTests/SnapshotCodecTests.swift`(주석과 케이스 확인)

### 적용 컨벤션
- 네이밍: 타입은 UpperCamel, 화면 식별자는 `screen.<rawValue>`, 요소 식별자는 `<화면>.<요소>`(예: `preparation.confirm`), 테스트 진단은 `test.<이름>`. 테스트 메서드는 "깨짐:" 주석과 AC 번호 접두를 쓴다(`PreparationEditorUITests.swift:9-10`).
- 저장: 최신 `snapshot` → `updating…` → `AppModel.save`. 실패하면 snapshot은 그대로 두고 `saveFailure`를 남긴다(`AppModel.swift:184-206`). 기능별로 `AppModel+기능.swift` 확장을 둔다(`AppModel+JourneyStart.swift:4`).
- 컨트롤러: `@MainActor @Observable final class`에 의존성은 `@ObservationIgnored`로 두고 sleep, 햅틱, 낭독을 주입한다(`CardIssuanceController.swift:19-45`). 포커스 요청은 `focusTarget` 값으로 내보내고 뷰가 `@AccessibilityFocusState`에 반영한다(`CardIssuanceView.swift:51`).
- 생성기: 시계와 난수를 주입하고 날짜는 초 단위로 내림한다(`CardSnapshotFactory.swift:4-19`). 날짜는 ISO8601 문자열로 직접 인코딩한다(`CardSection.swift:24-41`).
- 화면: 하단 고정 CTA는 `safeAreaInset(edge: .bottom)`(`CardIssuanceView.swift:47`), 큰 글자에서는 스크롤 영역과 고정 영역을 분리한다(`TimeSelectionView.swift:11-37`). 앱 생명주기는 `scenePhase != .active`로 판정한다(`PreparationView.swift:401`).
- DEBUG 진단은 `font(.system(size: 1))`, `.clear`, `allowsHitTesting(false)` 오버레이로 둔다(`RootView.swift:214-230`). 테스트용 터치 버튼은 불투명 44pt 영역에 투명 글자로 만든다(`RootView.swift:87-97`).
- CLAUDE.md는 프로젝트 루트에 없다. 위 내용은 기존 코드와 `.dev/plan.md:52-64` 인계 메모에서 정리했다.

### 상세 설계

#### 1. 진행 여정 저장 형식

1. **`ios/FocusMate/JourneySnapshot.swift`(신규)와 `JourneySection.swift`(수정)**: 빈 enum을 실제 값으로 바꾼다.
   - 현재: `JourneySnapshot`은 decode하면 항상 throw하는 빈 enum이다(`JourneySection.swift:4-9`). `JourneySection`은 `active` 키를 필수로, null을 허용한다(`:16-28`).
   - 변경: `JourneySnapshot`을 `struct, Codable, Equatable`로 정의한다. 진행 여정의 위치·방향·시간·진도·할 일·태그·소리를 "승차 시점 스냅샷"으로 저장한다. 사용자 태그는 메모리 초안에만 있으므로(`PreparationDraft.swift:93-133`) 태그 정의 전체(id·이름·아이콘·색)를 복사해 둔다. 정류장 이름과 거리는 저장하지 않는다. 이름은 `RouteStops`(`RouteData.swift:10-37`)에서, 거리는 `JourneyPlanner.distanceText(stops:)`(`JourneyPlanner.swift:34-40`)에서 다시 계산할 수 있기 때문이다. 대신 정류장 id·방향·정류장 수·도착 정류장 id를 저장해 W05/W09가 재계산 없이 쓰게 한다. 버스 번호는 `busID`로 `BusLine.all`에서 찾는다.
   - 시그니처:
     - `struct JourneySnapshot { enum Phase: String, Codable { case awaitingDeparture, departed }`
     - `struct Tag: Codable, Equatable { id: String; name: String; icon: PreparationTagIcon; color: PreparationTagColor }`
     - `struct Progress: Codable, Equatable { elapsedSeconds: Int; static let start }`
     - 필드: `id: String`, `cardID: String`, `originStopID: String`, `direction: Int`, `minutes: Int`, `busID: String`, `stops: Int`, `destinationStopID: String`, `tag: Tag`, `task: String`, `sound: JourneySound`, `boardedAt: Date`, `phase: Phase`, `progress: Progress }`
     - `static func boarding(details: PreparedJourneyDetails, cardID: String, id: String, boardedAt: Date) -> JourneySnapshot`
     - `func confirmingDeparture() -> JourneySnapshot`
     - `var originName / destinationName / bus: BusLine? / distanceText` (파생 값)
     - `func validate(currentCardID: String?) throws`, 실패 시 `ActiveJourneyValidationIssue`
     - `enum ActiveJourneyValidationIssue: Error, Equatable { case emptyID, cardMismatch, unknownStop(String), invalidDirection(Int), invalidMinutes(Int), unknownBus(String), inconsistentRoute, invalidTask, invalidTag, invalidProgress }`
     - `struct ActiveJourneyFactory { init(makeID: @escaping () -> String = { UUID().uuidString }, now: @escaping () -> Date = Date.init); func make(details:cardID:) -> JourneySnapshot }`. `boardedAt`은 초 단위로 내림한다(`CardSnapshotFactory.swift:16-17`과 같은 이유).
   - JSON 형태(키 정렬): `journey.active = {"boardedAt":"…Z","busID":"2014","cardID":"FM-…","destinationStopID":"seongsuDong","direction":-1,"id":"…","minutes":60,"originStopID":"seoulForest","phase":"awaitingDeparture","progress":{"elapsedSeconds":0},"sound":"bus","stops":12,"tag":{"color":"sand","icon":"reading","id":"reading","name":"독서"},"task":"책 읽기"}`
   - validate 규칙과 근거:
     - `cardID == currentCard.id`: 카드가 승차를 식별한다. 보충 전 상태처럼 카드가 없으면 `cardMismatch`다.
     - origin과 destination이 `RouteStops`에 있어야 하고 방향은 ±1이다.
     - `minutes`는 `JourneyPlanner.minuteRange` 안이어야 한다. 버스가 존재하고, `minutes % minutesPerStop == 0`, `stops == minutes / minutesPerStop`, `destinationStopID == RouteStops.all[wrap(originIndex + direction*stops)].id`가 모두 맞아야 한다. 위반하면 `inconsistentRoute`로, 손으로 고친 파일을 막는다.
     - `task`: trim 결과와 같고, 비어 있지 않고, utf16 80 이하(`PreparationDraft.swift:106-116`).
     - `tag.name`: trim 결과가 비어 있지 않고 utf16 20 이하(`:118-121`).
     - `phase == .awaitingDeparture`이면 `progress.elapsedSeconds == 0`이고, 음수는 금지한다. BR-5를 저장 단에서 보장한다.
     - origin과 `currentStation`이 같아야 한다는 규칙은 넣지 않는다. 현재 정류장은 하차(W09)·포기(W07)에서 진행 여정 제거와 함께 바뀐다. 지금 이 둘을 묶으면 W05/W07이 저장 순서를 바꿀 때 불필요한 제약이 된다.
   - `JourneySection`의 decode/encode 코드는 그대로 둔다. 키 누락은 손상, null은 nil, 객체는 신규 struct로 처리된다. `{}`와 `"x"`는 필수 키나 타입 오류로 계속 실패한다(`AppSnapshotSectionsTests.swift:166-186` 유지).
   - 확장 여지(W05): 새 필드는 `decodeIfPresent`에 기본값을 두는 방식으로 추가하고, `Phase`에 `paused` 같은 case를 추가한다. 주의할 점이 있다. W04 앱은 모르는 키를 무시하고 다시 저장하면서 키를 떨어뜨린다(`SnapshotCodecTests.swift:144-151`). 그래서 W05가 필드를 추가할 때는 currentVersion을 4로 올리는 것을 권장한다. 이 내용을 `.dev/plan.md` W05 인계에 기록한다.

2. **`ios/FocusMate/AppSnapshot.swift`**: validate를 확장한다.
   - 현재: 정류장, 카드, 기록만 검증한다(`:63-81`). `launchRoute`는 cardIssued와 currentStation으로만 정한다(`:83-87`).
   - 변경: `SnapshotValidationIssue`에 `case invalidActiveJourney(ActiveJourneyValidationIssue)`를 추가한다(`:10-15`). validate 끝에 다음을 넣는다. `active`가 있으면 `currentStation != nil`(main 단계)이어야 하고, 아니면 `.inconsistentStage`다. 이어서 `try active.validate(currentCardID: currentCard?.id)`를 호출해 실패를 감싼다.
   - `launchRoute()`는 바꾸지 않는다. 진행 여정이 있어도 `.main`이므로, 승차 저장 때 `persist`의 `previousRoute != nextRoute` 분기가 경로를 비우지 않는다(`AppModel.swift:201`). 이 동작은 단위 테스트로 고정한다.
   - 고려사항: `LocalSnapshotStore.save`도 validate를 호출한다(`LocalSnapshotStore.swift:104-107`). 잘못된 후보는 쓰기 전에 `invalidState`로 거절되고 snapshot은 바뀌지 않는다. `RootView.message(for:)`는 기존 default 분기("저장된 이용 상태를 확인할 수 없어요.")를 그대로 쓴다.

3. **`ios/FocusMate/SnapshotCodec.swift`**: v2 계약을 고정한다.
   - 현재: `LegacySnapshotV2.journey: JourneySection`(`:26-34`)이라, 신규 struct가 v2 해석에 섞여 들어간다.
   - 변경: `struct LegacyJourneySectionV2: Decodable`을 추가한다. `active` 키가 필수이고 null만 허용하며, 그 외는 `DecodingError`로 `.corrupt`가 된다. `migrateV2`는 `.updating(journey: .empty)`를 쓴다(`:70-77`). v1은 원래 journey가 없어서 `.empty`다.
   - 버전 정책: `currentVersion = 3`을 유지한다.
     - (1) v3 계약은 처음부터 `journey.active`를 "nullable 객체, 내용은 추후 정의"로 예약했다. 이전 v3 앱은 null이 아닌 active를 손상으로 보고 읽기와 쓰기를 모두 막는다(`LocalSnapshotStore.swift:108-109` writeBlocked). 정리하려면 사용자 확인과 원본 백업을 거친다. 데이터가 조용히 사라질 경로는 없다.
     - (2) 4로 올리면 진행 여정이 없는 파일까지 모두 이전 앱에서 `unsupportedVersion`이 되어, 다운그레이드 영향이 더 넓다.
     - (3) active가 null인 기존 파일은 변환 없이 같은 바이트를 유지한다(`StorageV2Tests` AC2a 재저장 동일성 유지).
     - 비용: 이전 앱에서 보이는 문구가 "형식을 읽을 수 없어요"(corrupt)이고 "이 버전에서 열 수 없는 데이터"가 아니다. 아직 배포 전(W14)이라 감수한다.

4. **`ios/FocusMate/PreparationDraft.swift`**: `PreparationTagIcon`, `PreparationTagColor`, `JourneySound`에 `Codable` 채택만 추가한다(`:3`, `:24`, `:63`). raw 값을 그대로 저장하고, 모르는 raw는 decode 실패로 corrupt가 된다.

#### 2. 내비게이션과 모델 동작

5. **`ios/FocusMate/AppModel.swift`**: Destination과 open 가드.
   - 현재: `Destination`은 `preparation, records, settings, profile, time`이다(`:5-16`). `open()`은 `.ready(.main)`에서만 append한다(`:250-253`).
   - 변경: `case board, boarding, journey`를 추가한다(title은 "승차권", "승차 태그", "여행"). `open()`에 진입 가드를 둔다. `.board`와 `.boarding`은 `confirmedPreparation != nil`일 때만, `.journey`는 `snapshot?.journey.active != nil`일 때만 연다. BR-1의 "어떤 경로로도"를 모델 단에서 보장한다. init에 `journeyFactory: ActiveJourneyFactory = .init()`를 추가한다(기본값이 있어 기존 호출부는 그대로).
   - 고려사항: `AppFoundationTests.swift:220`의 `Destination.allCases` 루프는 main이 아닌 상태라 path가 계속 `[]`이다. 영향 없다.

6. **`ios/FocusMate/AppModel+Boarding.swift`(신규)**
   - `var activeJourney: JourneySnapshot?`: `snapshot?.journey.active`
   - `@discardableResult func showBoardingPass() -> Bool`: `confirmPreparation()`이 성공하면 `consumePreparationRequest()`로 요청을 1회 소비한다. 결과가 non-nil이고 `path.last != .board`일 때 `open(.board)`. W03이 W04용으로 남긴 요청·소비 쌍(`AppModel.swift:45-70`)을 그대로 쓴다. 연타해도 `path.last` 가드로 한 번만 쌓인다(`proceedToPreparation` 관례와 같음, `AppModel+JourneyStart.swift:35-39`). 미완성이면 false를 반환하고 이동하지 않는다.
   - `@discardableResult func openBoarding() -> Bool`: `path.last == .board`이고 `confirmedPreparation != nil`일 때 `open(.boarding)`. 저장은 하지 않는다(AC-4).
   - `func boardJourney() -> Bool` (`JourneyBoarding` 준수): 다음 조건을 확인한다. `.ready(.main)`, `snapshot`, `currentCard`, 그리고 `confirmedPreparation`(호출 시점 기준으로 다시 계산한 현재 준비). 통과하면 `journeyFactory.make(details:cardID:)`로 만든 값을 `save(snapshot.updating(journey: JourneySection(active:)))`로 저장한다. 기존 active는 교체되고 항상 최대 1건이다(BR-8). 실패하면 snapshot은 그대로이고 `saveFailure`가 남는다(AC-21).
   - `func finishBoardingTransition()`: `path.last == .boarding`이고 `activeJourney != nil`일 때만 `path = [.journey]`. 승차 태그, 승차권, 준비, 시간 선택이 모두 경로에서 빠진다(AC-13). 뒤로가기는 메인으로 간다. 뷰는 이미 450ms 페이드를 했으므로 `withTransaction(disablesAnimations)` 안에서 호출한다.
   - `@discardableResult func confirmDeparture() -> Bool` (`DepartureConfirming` 준수): active가 `.awaitingDeparture`이면 `confirmingDeparture()`로 바꿔 save한다. 이미 `.departed`이면 쓰지 않고 true를 반환한다(멱등).
   - `@discardableResult func startTripFromMain() -> Bool`: active가 없으면 `open(.time)`만 한다(쓰기 없음, 기존 round-trip 무쓰기 테스트 유지). active가 있으면 `save(snapshot.updating(journey: .empty))`. 성공하면 `open(.time)`, 실패하면 이동하지 않고 false를 반환한다. 메인 하단에 기존 `storage.saveFailure` 문구가 뜨고 안내는 남는다.
     - 폐기 실패 시 이동하지 않는 근거: 이동을 허용하면 사용자가 "정리됐다"고 믿은 채 새 여행을 진행하는데 저장소에는 이전 여정이 남는다. 재실행 시 다시 안내가 떠서 혼란스럽다. 실패 시 snapshot 불변 + 실패 안내라는 기존 관례와도 맞는다.
   - 고려사항: 완료 기록(records)은 어느 경로에서도 건드리지 않는다(BR-9, AC-1/AC-27 "완료 기록 0건").

#### 3. 승차 태그 상태 기계

7. **`ios/FocusMate/BoardingRules.swift`(신규, 순수 규칙)**
   - `struct BoardingGeometry`:
     - 상수: `tagAreaSize = 238×160`, `threshold = 0.30`, `maxHorizontal = 26`, `maxDown = 20`, `tapSlop = 8`, `activationOverlapFraction = 0.35`
     - `func clampedOffset(_ translation: CGSize, cardRest: CGRect, tagArea: CGRect) -> CGSize`: x는 ±26으로 자르고, y는 `[tagArea.minY - cardRest.minY, +20]`으로 자른다(카드 위쪽이 태그 영역 위쪽을 넘지 못함).
     - `func overlapRatio(card: CGRect, tagArea: CGRect) -> CGFloat`: 교집합 면적 ÷ 태그 영역 면적(BR-7).
     - `func isContact(card:tagArea:) -> Bool`: 비율 ≥ 0.3
     - `func isTap(_ translation: CGSize) -> Bool`: 이동 거리 < 8
     - `func activationOffset(cardRest:tagArea:) -> CGSize`: 카드 위쪽이 `tagArea.maxY - tagArea.height*0.35`에 오도록 해서, 아래 가장자리에 걸치면서 임계를 넘는 위치로 만든다(FR-7).
   - `struct BoardingTiming { contact: Duration = .milliseconds(300); hold = .milliseconds(1400); fade = .milliseconds(450); terminalEntrance = 0.12; cardEntrance = 0.38; static let standard; func contact(reduceMotion:) -> Duration; func fade(reduceMotion:) -> Duration }`: 동작 줄이기면 contact와 fade는 0이고 hold는 유지한다.
   - `enum BoardingClock { static func text(for date: Date, timeZone: TimeZone = .current) -> String }`: `HH:mm` 24시간, `en_US_POSIX`
   - 근거: 겹침, 고정 범위, 터치 판정을 뷰에서 떼어 내 AC-6~9를 좌표 값 단위 테스트로 결정적으로 검증한다.

8. **`ios/FocusMate/BoardingTagController.swift`(신규)**
   - 프로토콜: `@MainActor protocol JourneyBoarding: AnyObject { func boardJourney() -> Bool }`
   - `@MainActor @Observable final class BoardingTagController`:
     - `enum Phase: Equatable { case ready, dragging, contacting, held, fading, finished, failed, abandoned }`
     - 공개 상태: `phase`, `cardOffset: CGSize`, `showsTapHint: Bool`, `tapBounceCount: Int`, `showsSaveFailure: Bool`, `var isRecognized: Bool`(contacting, held, fading, finished, abandoned), `var lcd: LCDState`(`.ready` 또는 `.recognized(cardName)`)
     - `init(boarder: JourneyBoarding, haptics: IssuanceHaptics, announcer: AccessibilityAnnouncing, geometry: BoardingGeometry = .init(), timing: BoardingTiming = .standard, sleep: @escaping (Duration) async -> Void, holdSleep: ((Duration) async -> Void)? = nil, onFinished: @escaping () -> Void)`
     - `func updateLayout(cardRest: CGRect, tagArea: CGRect)`
     - `func dragChanged(translation: CGSize, reduceMotion: Bool)`
     - `func dragEnded(translation: CGSize, reduceMotion: Bool)`
     - `func activate(reduceMotion: Bool)`: VoiceOver나 키보드 활성화
     - `func cancelPendingTransition()`: 화면 사라짐이나 `scenePhase != .active`
   - 전이 규칙:
     - `dragChanged`: `ready`나 `failed`에서 이동 거리가 tapSlop을 넘으면 `dragging`이 되고 힌트를 숨긴다. `dragging`이면 `cardOffset = clampedOffset`으로 두고, `isContact`이면 손을 떼기 전이라도 즉시 `recognize()`(AC-6). 그 밖의 phase에서는 무시한다(AC-12).
     - `dragEnded`: tapSlop을 넘은 적이 없으면 터치로 처리한다. `tapBounceCount += 1`, `showsTapHint = true`, 인식과 저장은 없다(AC-9). `dragging`이면 offset을 `.zero`로 두고 `ready`(AC-7). 인식 이후에는 무시하고 카드는 그 자리에 남는다.
     - `activate`: `ready`나 `failed`에서만 동작한다. `cardOffset = activationOffset`, `recognize()`(AC-10).
     - `recognize()`: `generation += 1`, `phase = .contacting`. 동작 줄이기가 꺼져 있고 지원되면 `haptics.play(.boardingContact)`(AC-6, AC-22). contact가 0이면 `commit` 동기 호출, 아니면 `Task { await sleep(contact); commit(token) }`.
     - `commit(token)`: `phase == .contacting`이고 token이 일치할 때 `boarder.boardJourney()`. 성공하면 `phase = .held`, 낭독 "집중동행카드 인식됨, 승차했습니다" 1회, 그다음 `holdSleep ?? sleep`(1400ms) → token 확인 → `.fading` → `sleep(fade)` → token 확인 → `.finished` → `onFinished()`. 실패하면 `phase = .failed`, offset `.zero`, `showsSaveFailure = true`, 낭독 "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요." 다시 끌기나 활성화가 가능하다(AC-21).
     - `cancelPendingTransition()`: `generation += 1`. `contacting`이면 인식은 이미 성공했으므로 저장을 즉시 끝까지 수행(`commit`을 동기로)하고 성공하면 `abandoned`가 된다. "인식 = 정확히 1회 저장"을 지키기 위해서다. `held`나 `fading`이면 `abandoned`(AC-14, AC-15). `dragging`이면 `.zero`와 `ready`(AC-16). 나머지는 그대로다. `abandoned`에서는 복귀해도 재예약하지 않는다.
   - 햅틱: `IssuanceHaptics`를 재사용한다(`IssuanceFeedback.swift:4-8`). `IssuanceHapticPattern.boardingContact`를 추가한다(짧은 transient 1개, 0.12s 약한 연속음).
   - 낭독: `AccessibilityAnnouncing`을 재사용한다(`IssuanceFeedback.swift:10-13`). 인식 낭독을 저장 성공 뒤에 하는 이유는 저장 실패 시 "승차했습니다"가 거짓 안내가 되기 때문이다. 동작 줄이기에서는 contact가 0이라 즉시 낭독된다.
   - 고려사항: 발급(`CardIssuanceController.swift:61-62`)은 동작 줄이기와 무관하게 진동하지만, 승차는 PRD FR-16에 따라 동작 줄이기에서 진동을 생략한다. 이 차이를 코드 주석에 남긴다.

#### 4. 출발 안내

9. **`ios/FocusMate/DepartureBriefingController.swift`(신규)**
   - 프로토콜: `@MainActor protocol DepartureConfirming: AnyObject { func confirmDeparture() -> Bool }`
   - `@MainActor @Observable final class DepartureBriefingController`:
     - `static let sentences = ["문을 닫습니다", "자리에 앉아주세요", "버스 출발합니다"]`, `static let interval: Duration = .milliseconds(1700)`
     - 공개 상태: `visibleIndex: Int`, `showsAll: Bool`, `showsStart: Bool`, `focusTarget: FocusTarget?`(`.startButton`), `isConfirmed`, `showsSaveFailure`
     - `init(confirmer: DepartureConfirming, interval: Duration = interval, sleep: @escaping (Duration) async -> Void)`
     - `func begin(reduceMotion: Bool) async`: `generation += 1`. 동작 줄이기면 `showsAll`과 `showsStart`를 즉시 켠다(AC-18). 아니면 index 0 → sleep → 1 → sleep → 2, 이어서 `showsStart`. 각 단계에서 token을 확인한다. `showsStart`가 켜지면 `focusTarget = .startButton`.
     - `func reset()`: `generation += 1`, index 0, `showsStart = false`. 숨김 후 복귀하면 처음부터 다시 보여 준다.
     - `func confirm() -> Bool`: `showsStart`일 때만 동작한다. 성공하면 `isConfirmed`, 실패하면 `showsSaveFailure`이고 버튼을 유지해 재시도할 수 있다.
   - 일시정지 조작은 아예 없다. 진도와 남은 시간도 이 화면에 없어 BR-5와 AC-19를 구조적으로 만족한다.

#### 5. 화면

10. **`ios/FocusMate/BoardingPassContent.swift`(신규, 순수)**: `struct BoardingPassContent { init(details: PreparedJourneyDetails, now: Date, timeZone: TimeZone) }`
    - 필드: `originName`, `destinationName`, `stopsText`("12개"), `distanceText`(`JourneyPlanner.distanceText` 재사용), `boardingText = "지금"`, `dateText`("yyyy/MM/dd"), `tagName`, `task`, `stationFontSize: CGFloat`, `routeAccessibilityLabel`
    - 정류장 글꼴 크기는 프로토타입 규칙을 따른다(`designs/final/animation-preview.html:823`). 두 이름 중 긴 쪽 글자 수가 4 이하면 28, 6 이하면 24, 9 이하면 20, 그 외 17이다.
    - `routeAccessibilityLabel` = "{출발}에서 {도착}까지, {kind} {number}번 버스, {minutes}분 여행". 버스 번호와 여행 시간은 이 라벨에만 넣는다(AC-3).

11. **`ios/FocusMate/BoardingPassView.swift`(신규)**: 승차권(TUNX2).
    - 구조: `ZStack` 배경(`BoardMap` 또는 그라데이션, `accessibilityHidden`) 위에 `ScrollView`로 티켓 카드를 둔다. 티켓 배경에는 `TicketDots`를 깔고 노치만 남긴다. 칸 구조는 출발/도착, 정류장/거리, 탑승/날짜, 태그/할 일이다. 하단 '버스에 탑승하기 →'는 `.safeAreaInset(edge: .bottom)`에 고정해 가장 큰 글자에서도 화면 안에 있게 한다(AC-23).
    - 식별자: 컨테이너 `screen.board`(`accessibilityElement(children: .contain)`), 값 `board.origin`, `board.destination`, `board.stops`, `board.distance`, `board.boarding`, `board.date`, `board.tag`, `board.task`, 경로 요약 `board.route`(`.ignore`와 `routeAccessibilityLabel`), 버튼 `board.boardBus`
    - 데이터는 `model.confirmedPreparation`에서만 읽는다(단일 출처). 이 값이 nil이면 티켓과 버튼 대신 "준비를 다시 확인해주세요"를 보여 준다(방어 코드).
    - 내비게이션: 제목은 비우고(`navigationTitle("")`) 기본 back을 쓴다. W11에서 툴바 Text 식별자가 바깥 래퍼로 복사된 문제가 있었으므로(`.dev/feat-my-page/reports/t5-impl.md:12`) 화면 식별자는 툴바가 아닌 본문 컨테이너에만 둔다.

12. **`ios/FocusMate/BoardingTagView.swift`(신규)**: 승차 태그(kxUUR, JmXmQ, Vts6F).
    - 구조: 단말기(폭 274, LCD 'Focus Mate'와 `TimelineView(.everyMinute)` + `BoardingClock.text`, 상태 '승차 준비' 또는 카드 이름과 체크) → 태그 영역(238×160, `boarding.tagArea`) → 위쪽 화살표 → 점선 테두리 안 카드. 카드는 `PassFace(style: model.currentCardStyle)`(`PassFace.swift:4-18`)다.
    - 좌표: `.coordinateSpace(name: "boarding")` 안에서 GeometryReader로 카드 기준 위치와 태그 영역 frame을 `controller.updateLayout`에 넘긴다.
    - 제스처: `PassFace`는 자체적으로 `allowsHitTesting(false)`다(`PassFace.swift:17`). 그래서 카드를 감싼 컨테이너에 `contentShape(Rectangle())`과 `DragGesture(minimumDistance: 0, coordinateSpace: .named("boarding"))`를 붙인다.
    - 접근성: 카드 래퍼에 `accessibilityElement(children: .ignore)`, 라벨 "집중동행카드", `.isButton` trait를 준다. 힌트 "카드를 여기에 대면 승차해요. 두 번 탭해 태그하기"로 '카드를 여기에'와 '눌러서 태그하기'를 낭독 전용으로 유지한다. `accessibilityAction { controller.activate(…) }`을 단다(VoiceOver, Full Keyboard Access의 Space/Enter). 식별자는 `boarding.card`.
    - 낭독 전용 요소: 화면 머리 `boarding.title`(라벨 "승차 태그, {출발 정류장}, 승차 단계", 보이지 않는 `Color.clear` 1pt)과 단말기 `boarding.terminal`(라벨 "Focus Mate 단말기, HH:mm, 승차 준비" 또는 "집중동행카드 인식됨"). LCD 값 식별자는 `boarding.lcdStatus`다(value '승차 준비' 또는 '집중동행카드').
    - 보이는 안내: 터치 시 `boarding.tapHint` "카드를 위로 밀어 단말기에 대주세요"(AC-9), 저장 실패 시 `boarding.saveFailure`. RootView의 공용 저장 실패 문구는 메인 루트에만 있어서(`RootView.swift:28-31`) 이 화면에서는 보이지 않는다.
    - 연출: 진입 시 단말기 0.12s, 카드 0.38s(아래에서 위로), 올림 안내 2회, 점선 깜빡임. contacting에서는 300ms 동안 접촉 이동(작게 밀착), fading에서는 opacity 0까지 450ms. 동작 줄이기면 이 연출을 모두 생략한다(AC-22, FR-16).
    - 생명주기: `.onDisappear { controller.cancelPendingTransition() }`, `.onChange(of: scenePhase) { if $1 != .active { controller.cancelPendingTransition() } }`. `onFinished`는 `model.finishBoardingTransition()`에 연결한다.
    - LCD와 단말기 글자는 기기 모형이라 PassFace처럼 `dynamicTypeSize(.large)`로 고정한다. 안내와 실패 문구는 `...accessibility3` 상한을 둔다.

13. **`ios/FocusMate/JourneyView.swift`(신규)**: 여행 자리표시와 출발 안내(DO8HO).
    - active가 `.awaitingDeparture`이면 출발 안내를 보여 준다. 화면 전체를 덮는 어두운 그라데이션 위에 버스 아이콘(`bus`), 같은 자리에 문장 1개(`journey.briefingSentence`, value=현재 문장)를 둔다. 동작 줄이기면 세 문장을 세로로 한꺼번에 보여 준다. '시작' 버튼(`journey.start`)과 `@AccessibilityFocusState`가 `controller.focusTarget`을 반영한다. 큰 글자를 위해 `ScrollView` + `frame(minHeight:)` 가운데 정렬을 쓴다(AC-23). 안내 중에는 `navigationBarBackButtonHidden(true)`와 `toolbar(.hidden, for: .navigationBar)`로 이탈과 일시정지 수단을 두지 않는다. 노선, 버스, 정류장 텍스트는 없다(AC-17).
    - `.departed`이면 자리표시 `screen.journey`(제목 "여행"만)를 보여 준다. 남은 시간과 진도는 표시하지 않는다(W05). 뒤로가기는 메인으로 간다(가정, 질문 2).
    - 생명주기: `.task { await controller.begin(reduceMotion:) }`. `scenePhase != .active`이면 `reset()`, `.active`로 복귀하면 다시 `begin`해서 처음부터 보여 준다.
    - 출발 확인 실패 시 `journey.saveFailure`를 보여 주고 '시작'을 유지한다.

14. **`ios/FocusMate/DestinationScreen.swift`**: 분기를 추가한다.
    - 현재: profile만 별도 체인이고 나머지는 자리표시 + padding 24 + navigationTitle이다(`:10-35`).
    - 변경: `.board`, `.boarding`, `.journey`는 profile처럼 공통 체인 밖에서 그린다(자체 여백과 빈 제목). 새 프로퍼티 `services: JourneyServices`를 RootView에서 받는다. 컨트롤러는 각 View가 `@State`로 소유한다. 진입마다 새로 만들고, 사라지면 cancel한다.

15. **`ios/FocusMate/JourneyServices.swift`(신규)**: `struct JourneyServices { haptics: IssuanceHaptics; announcer: AccessibilityAnnouncing; sleep: (Duration) async -> Void; boardingHoldSleep: ((Duration) async -> Void)?; briefingSleep: (Duration) async -> Void; forcedReduceMotion: Bool }`
    - 효과적 동작 줄이기 값은 `systemReduceMotion || forcedReduceMotion`이다.
    - 운영 조립은 `CoreHapticsIssuancePlayer`와 `SystemAccessibilityAnnouncer`, Task.sleep이다. `FocusMateApp`에서 만들어 RootView에 넘긴다(`FocusMateApp.swift:15-44`, `:66-69`).

16. **`ios/FocusMate/PreparationView.swift`**
    - '승차권 보기' 동작을 `model.confirmPreparation()`(`:178`)에서 `model.showBoardingPass()`로 바꾼다. 비활성 조건(`disabled(!canConfirmPreparation)`, `:185`)은 그대로 둔다.
    - `test.preparedPreparation` 진단(`:190-209`)을 RootView 전역 진단으로 옮긴다. 승차권으로 이동한 뒤에도 테스트가 확정값을 읽어야 하기 때문이다.

17. **`ios/FocusMate/RootView.swift`**: 메인.
    - 현재: `.main` 분기가 루트 VStack 안에 그대로 나열된다(`:150-163`). '여행 준비'는 `model.open(destination.mainMenuTarget)`이다.
    - 변경: `.main` 내용을 `ScrollView`로 감싼다. 진행 여정 안내 추가와 가장 큰 글자를 고려한 것이다(AC-23).
    - 안내: active가 있으면 정류장 아래, 메뉴 위에 카드형 안내를 둔다. 식별자 `main.activeJourney`, `accessibilityElement(children: .combine)`. 문구는 "진행 중인 여정이 있어요"와 보조 문장 "여행 준비를 누르면 이 여정은 기록 없이 정리돼요"이며, 기존 메인의 secondary 텍스트 표현을 따른다.
    - 메뉴 버튼은 `destination == .preparation`이면 `model.startTripFromMain()`, 그 외는 기존대로 `open`이다.
    - DEBUG: `test.preparedPreparation`, `test.writeCount`, `test.releaseBoardingHold` 버튼(기존 `test.releaseIssuance`와 같은 trailing VStack)을 추가한다. `test.reduceMotion`은 효과적 값을 내보낸다.

#### 6. UI 테스트 지원

18. **`ios/FocusMate/UITestBootstrap.swift`**
    - 시드 추가(`:94`, `:96-109`). 모두 v3 `LocalSnapshotStore.save`로 만들고 `readySnapshot.issuingCard(fixedCard)`를 기반으로 한다.
      - `"activeJourney"`: seoulForest, -1, 60분, 2014, 12정류장, destination seongsuDong, 태그 reading, 할 일 "시드 여정", bus, `.awaitingDeparture`, 고정 id와 boardedAt
      - `"activeJourneyDeparted"`: 같은 값에 `.departed`
    - 인자 추가(`:40-50` 패턴):
      - `--fm-ui-boarding-hold manual`: hold 1400ms를 `UITestIssuanceGate.wait`로 붙잡는다(`:217-232`). 클래스는 재사용하고 인스턴스를 따로 둔다.
      - `--fm-ui-reduce-motion on`: `forcedReduceMotion = true`
    - `--fm-ui-save fail`은 재사용한다(`:42-44`, `:126`). 승차 저장, 출발 확인, 폐기가 모두 실패한다. 시드가 activeJourney면 "기존 저장 불변"을 확인할 수 있다(AC-21).
    - 쓰기 횟수: `modelStore.writeData`에서 성공 쓰기를 세는 `UITestWriteCounter`(@Observable)를 두고 `test.writeCount`로 노출한다. 중복 접촉이 저장 횟수를 늘리지 않음을 직접 단언한다(AC-12). 보조로 `test.persistedBytes` 동일성도 쓴다(재저장하면 id와 boardedAt이 바뀌므로 바이트가 달라진다).
    - 햅틱과 낭독: 기존 `UITestFeedbackRecorder`를 `JourneyServices.haptics/announcer`로 주입한다(`:204-214`). RootView 전역 오버레이의 `test.hapticCount`와 `test.announcements`로 읽는다(`RootView.swift:224-227`). 이 오버레이는 NavigationStack 전체 위에 있어 푸시된 화면에서도 보인다.
    - 화면별 진단(BoardingTagView, JourneyView DEBUG 오버레이):
      - `test.boarding`: `{"phase","offsetX","offsetY","overlap","showsTapHint"}`. AC-7, AC-8, AC-9에서 위치와 원위치를 수치로 단언한다.
      - `test.briefing`: `{"index","showsAll","showsStart","focus"}`. AC-17 포커스는 시뮬레이터 VoiceOver 없이 `focusTarget`으로 확인한다.
      - `test.activateBoardingCard`: 숨은 버튼. XCUITest는 VoiceOver 활성화를 흉내 낼 수 없어서, `accessibilityAction`과 같은 `controller.activate` 경로를 부른다(AC-10). 실제 VoiceOver는 W14 실기기에서 확인한다.
    - 끌기 테스트: `boarding.card`와 `boarding.tagArea`의 frame으로 목표를 계산한다. `card.coordinate(withNormalizedOffset: (0.5,0.5)).press(forDuration: 0.2, thenDragTo: …withOffset(dy: -d))`를 쓴다. AC-6의 "놓기 전 인식"은 UI에서 손을 뗀 뒤만 보이므로 컨트롤러 단위 테스트(`dragChanged`만으로 phase가 contacting)로 보장하고, UI는 결과(햅틱 1, LCD)를 본다. 끌기 범위 제한(AC-8)은 과도하게 끈 뒤 `test.boarding`의 offset과 프레임으로 단언한다.
    - 시간 결정성: LCD는 정규식 `^\d{2}:\d{2}$`로 검사한다. 포맷은 `BoardingClockTests`에서 고정 Date와 TimeZone으로 검증한다. 승차권 날짜도 같은 방식(`^\d{4}/\d{2}/\d{2}$`)이다.
    - `UITestLaunchSupport.swift:13-29`: `launch(...)`에 `boardingHold:`와 `reduceMotion:` 편의 인자를 추가한다.

### 의존성 및 영향도
- 새 외부 라이브러리는 없다. 쓰는 API는 SwiftUI, CoreHaptics(기존), iOS 17 범위(`TimelineView`, `AccessibilityFocusState`, `coordinateSpace(name:)`)이다.
- 저장소: active가 null인 기존 v1/v2/v3 파일은 영향 없다. v3에 active 객체가 실제 값으로 들어간다. v2 파일은 계속 null만 허용한다.
- `.dev/plan.md:63`의 W04 인계(카탈로그 밖 정류장, 현재 정류장 변경 시 선택 무효화): W04는 현재 정류장을 바꾸지 않는다. 카탈로그 밖 정류장이면 `journeyOrigin`이 nil이라 시간 선택 → 준비 → 승차권 경로가 처음부터 막힌다. 추가 변경 없이 기록만 갱신한다.
- 같은 세션의 `journeyPlan`과 `preparation` 초안은 승차 뒤에도 유지된다(기존 왕복 유지 동작, `PreparationFlowUITests.swift:64-88`).

**기존 테스트 영향**
- `PreparationEditorUITests.swift`: '승차권 보기'를 누르면 승차권으로 이동하므로 `PreparationView` 안의 `test.preparedPreparation`이 사라진다. 진단을 RootView로 옮기면 다음 테스트는 그대로 통과한다: AC9(:90-93), AC14-16(:139-140), AC19(:152-153), AC20(:168-169), AC24-25(:202-204), AC23(:215-216). 단 `testAC4_AC12`(:39-54)는 수정이 필요하다. 첫 확정 뒤 같은 화면에서 할 일을 고치고 `screen.preparation` 존재를 단언하기 때문이다. 확정 → `screen.board` 확인 → 뒤로 → 수정 → 재확정 → `screen.board`로 바꾼다. `snapshot.journey.active == null` 단언은 유지한다(AC-1).
- `PreparationFlowUITests.swift`: `buttons["여행 준비"]`를 쓰는 테스트(:67, :82, :107, :135)는 라벨이 유지되면 그대로 통과한다. active가 없으면 무쓰기다. `testPreparationHubInitially…`(:33-45)의 비활성 단언도 유지된다. plan의 "완료 버튼 없음" 검증은 이 비활성 단언으로 남아 있다.
- `AppFoundationTests.swift:205-229`(allCases open 무시), `:232~`(메인 목적지 무쓰기 왕복): `startTripFromMain`이 active가 없을 때 쓰지 않으므로 유지된다.
- `SnapshotCodecTests.swift:130-141`, `AppSnapshotSectionsTests.swift:166-186`: `{}`와 `"x"`는 계속 실패한다. v2는 `LegacyJourneySectionV2`로 고정한다. "미정의 원소" 주석은 "v2는 null만"으로 갱신한다.
- `CardCustomizationAppModelTests.swift:174`의 주석("nil만 표현 가능")을 갱신한다. 동작에는 영향이 없다.
- 메인을 ScrollView로 감싸므로 `Phase1FlowTests`, `LargeTextUITests`, `ProfileUITests`의 메인 요소 탐색을 회귀 실행으로 확인한다.

**하위 호환성**: currentVersion 3 유지. 근거는 상세 설계 3번.

#### 기존 구조와의 차이
- **경로 통째 교체**: 지금까지 경로 조작은 append/removeLast(`AppModel.swift:250-257`)와 최초 정류장 후 `path = [.time]`(`AppModel+JourneyStart.swift:29`)뿐이었다. 여행 진입은 `path = [.journey]`로 교체해 승차 태그가 경로에 남지 않게 한다(AC-13).
- **컨트롤러 내부 Task**: `CardIssuanceController`는 뷰가 `Task { await issue() }`로 호출하는 async 메서드였다. 승차 태그는 제스처 콜백(동기)에서 상태가 바뀌고 이후 지연을 세대 token으로 취소해야 해서, 컨트롤러가 Task를 내부에서 시작하고 token으로 늦은 전환을 무효화한다.
- **동작 줄이기와 햅틱**: 발급은 동작 줄이기와 무관하게 진동하지만 승차는 생략한다(PRD FR-16).
- **동작 줄이기 강제 주입**: 기존 화면은 시스템 `accessibilityReduceMotion`만 읽었다. UI 테스트에서 AC-18/AC-22를 재현하려고 `JourneyServices.forcedReduceMotion`(DEBUG 인자로만 켜짐)을 OR로 합친다.
- **v2 journey 디코딩 분리**: v2 해석이 공유 `JourneySection`을 쓰던 것을 전용 DTO로 고정한다(`LegacyCardV2DTO` 관례와 같음, `SnapshotCodec.swift:10-24`).
- **준비 확정 진단 위치**: 화면 국소 진단을 RootView 전역으로 옮긴다.

### 구현 순서
같은 파일을 고치는 단계끼리는 의존을 걸었다.

1. [Must] T1 진행 여정 저장 형식: `JourneySnapshot.swift`, `JourneySection.swift`, `AppSnapshot.swift`, `SnapshotCodec.swift`, `PreparationDraft.swift`(Codable). 단위: JourneySnapshotTests, JourneySnapshotStorageTests(왕복, 손상, v2 null 고정, 검증 위반별 invalidState, null 바이트 불변). AC-11(내용), AC-24(재실행 읽기) 기반, BR-5와 BR-8 저장 단. (의존: 없음)
2. [Must] T2 순수 규칙: `BoardingRules.swift`, `BoardingPassContent.swift`, `IssuanceHapticPattern.boardingContact`. 단위: 겹침과 임계, 범위 제한, 터치 판정, 활성 위치, 시각 포맷, 승차권 값과 글꼴 크기, 낭독 라벨. AC-3(값), AC-5(HH:mm), AC-6~9(계산), BR-7. (의존: 없음)
3. [Must] T3 모델과 내비게이션: `AppModel.swift`(Destination, open 가드, factory 주입), `AppModel+Boarding.swift`. 단위 BoardingModelTests: showBoardingPass 연타 1회, 미완성 차단, open 가드, boardJourney 교체 1건, path 불변(persist가 경로를 비우지 않음), 실패 시 불변과 saveFailure, finishBoardingTransition은 `[.journey]`, confirmDeparture 멱등, startTripFromMain(무쓰기, 폐기 후 time, 폐기 실패 시 이동 없음), records 불변. AC-1, 2, 4, 11, 13(경로), 20(모델), 21(모델), 25, 26(경로), 27. (의존: 1)
4. [Must] T4 승차 태그 컨트롤러: `BoardingTagController.swift`. 단위(SuspendingSleep, FakeIssuanceHaptics, RecordingAnnouncer 재사용, `CardIssuanceTestDoubles.swift:11-91`, `FakeJourneyBoarder`): 놓기 전 인식, 미만이면 원위치, 터치 힌트, 활성화와 낭독 1회, 300ms 뒤 1회 저장과 hold 중 미전환, 중복 무시, hold와 fade 뒤 onFinished, 이탈·숨김 시 전환 취소와 저장 유지(contacting 중 취소는 즉시 저장), 인식 전 취소는 예약 없음, 저장 실패면 재시도 가능, 동작 줄이기면 햅틱 0과 contact/fade 0이고 hold 유지. AC-6~16, 21, 22. (의존: 2)
5. [Must] T5 출발 안내 컨트롤러: `DepartureBriefingController.swift`. 단위: 문장 순서와 간격 주입, 마지막에 start와 focusTarget, 동작 줄이기면 동시 표시, reset 뒤 처음부터, confirm 실패 시 유지. AC-17, 18, 19, 20. (의존: 없음)
6. [Must] T6 화면과 연결: `JourneyServices.swift`, `BoardingPassView.swift`, `BoardingTagView.swift`, `JourneyView.swift`, `DestinationScreen.swift`, `PreparationView.swift`, `RootView.swift`(메인 안내, ScrollView, startTripFromMain, 진단 이동), `FocusMateApp.swift`, `TicketDots` 자산, `BoardMap` 자산. AC-1~5, 9, 13, 17, 20, 24, 26~28 화면 동작. (의존: 3, 4, 5)
7. [Must] T7 UI 테스트 부트스트랩: `UITestBootstrap.swift`(시드, boarding-hold 게이트, reduce-motion, write counter), `UITestLaunchSupport.swift`. (의존: 1. RootView 버튼과 진단 연결은 6에 포함되므로 6과 함께 머지)
8. [Must] T8 UI 테스트 작성과 기존 수정: `BoardingFlowUITests`(AC-1~4, 25, 26), `BoardingTagUITests`(AC-5~16, 21, 22), `DepartureBriefingUITests`(AC-17~20), `ActiveJourneyMainUITests`(AC-24, 27, 28, 폐기 실패), `PreparationEditorUITests` 수정. (의존: 6, 7)
9. [Should] T9 연출과 큰 글자: 진입 연출, 올림 안내, 점선 깜빡임, 접촉 이동, 페이드(동작 줄이기 분기 포함). 가장 큰 글자에서 '여행 준비', '버스에 탑승하기', '시작' 도달 UI 테스트(AC-23), FR-15 임시 동작 주석. (의존: 6, 8)

1, 2, 5는 병렬로 진행할 수 있다. 3과 4는 각각 1과 2 이후 병렬로 진행할 수 있다.

### 탐색 추가 항목
- `ios/FocusMate/AppModel.swift:5-16`: Destination. `:32-70`: 준비 확정과 요청 소비. `:184-206`: save/persist. `:201`은 route가 바뀔 때만 path를 비운다. `:250-257`: open/goBack 가드
- `ios/FocusMate/AppSnapshot.swift:10-15`, `:63-87`: 검증 이슈, validate, launchRoute(active 무관)
- `ios/FocusMate/JourneySection.swift:4-28`: 빈 enum, active 필수 키와 null 규칙
- `ios/FocusMate/SnapshotCodec.swift:26-34`, `:38`, `:70-77`: v2 DTO, 버전 3, migrateV2의 journey 전달
- `ios/FocusMate/LocalSnapshotStore.swift:104-115`: save 시 validate와 보호 파일 쓰기 차단
- `ios/FocusMate/CardSection.swift:24-41`: ISO8601 직접 인코딩 관례
- `ios/FocusMate/CardSnapshotFactory.swift:4-19`: 시계·난수 주입과 초 단위 내림
- `ios/FocusMate/PreparationDraft.swift:3-35`, `:63-92`, `:93-142`: 태그·소리 enum, 완성 조건, PreparedJourneyDetails
- `ios/FocusMate/JourneyPlanDraft.swift:4-11`, `ios/FocusMate/RouteData.swift:10-37`, `:77-88`, `ios/FocusMate/JourneyPlanner.swift:25-40`: 여정 선택, 정류장, 버스, 거리
- `ios/FocusMate/AppModel+JourneyStart.swift:35-47`: 연타 가드 관례, mainMenuTarget
- `ios/FocusMate/RootView.swift:28-31`(공용 저장 실패 문구, 메인 루트 전용), `:83-97`(테스트 게이트 버튼), `:150-163`(메인), `:214-230`(진단)
- `ios/FocusMate/DestinationScreen.swift:10-35`: 목적지 분기, padding, 제목 체인
- `ios/FocusMate/PreparationView.swift:175-187`('승차권 보기'), `:190-209`(준비 확정 진단), `:401`(scenePhase 관례)
- `ios/FocusMate/CardIssuanceController.swift:19-69`, `ios/FocusMate/CardIssuanceView.swift:47-51`: 주입형 컨트롤러, focusTarget, 하단 고정 CTA
- `ios/FocusMate/IssuanceFeedback.swift:4-13`, `ios/FocusMate/IssuanceHapticPattern.swift:24-33`: 햅틱·낭독 프로토콜, 패턴 값
- `ios/FocusMate/PassFace.swift:4-18`(`allowsHitTesting(false)`라 래퍼에 제스처 필요), `ios/FocusMate/PassIdentity.swift:5`(카드 이름)
- `ios/FocusMate/TimeSelectionView.swift:11-37`: 큰 글자 고정 영역 분리 관례
- `ios/FocusMate/FocusMateApp.swift:15-44`, `:66-69`: 테스트·운영 의존성 조립
- `ios/FocusMate/UITestBootstrap.swift:40-55`, `:94-145`, `:176-184`, `:203-232`: 인자, 시드, 실패 저장소, v2 원본 시드 헬퍼, 기록기와 게이트
- `ios/FocusMateTests/CardIssuanceTestDoubles.swift:11-91`: 재사용할 가짜 햅틱, 낭독기, SuspendingSleep
- `ios/FocusMateTests/SnapshotCodecTests.swift:115-141`, `ios/FocusMateTests/AppSnapshotSectionsTests.swift:166-186`: journey 골격과 미정의 원소 손상 계약
- `ios/FocusMateUITests/PreparationEditorUITests.swift:36-56`, `:289-297`: 확정 뒤 같은 화면 진단에 의존하는 테스트
- `ios/FocusMateUITests/PreparationFlowUITests.swift:64-143`: 메인 '여행 준비' 흐름
- `ios/FocusMateUITests/UITestLaunchSupport.swift:13-29`: 실행 하네스
- `ios/FocusMate.xcodeproj/project.pbxproj:22-26`, `:54-55`: 동기화 그룹(파일 등록 불필요), iOS 17.0, Swift 5
- `designs/final/animation-preview.html:823`: 승차권 정류장 글꼴 크기 규칙(4/6/9자 → 28/24/20/17)
- `designs/assets/next-stop/ticket/ticket-seoul-dots.png`: 승차권 질감 원본(있음). 앱 자산에는 `PassDots`(svg)만 있다(`ios/FocusMate/Assets.xcassets/PassDots.imageset/`).
- `docs/FLOWS.md:14-15`, `:28-37`, `:54-58`: 승차권, 승차 태그, 2차 출발 안내 계약. `:62`는 PRD에서 폐기한 계약이다.

---

## 확인이 필요한 사항

1. 메인 화면 여행 버튼의 글자를 무엇으로 할까요?
   - 맥락: PRD는 이 버튼을 '여행 시작하기'라고 부르지만, 지금 앱에 보이는 글자는 '여행 준비'입니다(식별자 `open.preparation`). 기존 자동 테스트 여러 개가 '여행 준비' 글자로 버튼을 찾습니다.
   - 유형: 선택
   - 선택지:
     - (a) '여행 준비' 그대로 두기 (권장): 이번 작업은 눌렀을 때의 동작(진행 여정 정리 후 시간 선택)만 바꿉니다. 글자 변경은 시안 정리와 함께 따로 하는 편이 안전하고, 기존 테스트도 그대로 씁니다.
     - (b) '여행 시작하기'로 바꾸기: 시안과 PRD 표현에 맞습니다. 대신 기존 테스트 문구를 함께 고쳐야 합니다.
     - (c) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다.

2. 출발 안내에서 '시작'을 누른 뒤 나오는 여행 자리표시 화면에서 메인으로 돌아갈 수 있게 할까요?
   - 맥락: 실제 여행 화면(일시정지·포기)은 W05/W07에서 만듭니다. 이번에는 '시작' 뒤 빈 자리표시만 있습니다. 나갈 길이 없으면 앱을 다시 켜야 메인으로 갈 수 있습니다. 출발 안내가 나오는 동안에는 시안대로 뒤로가기를 숨깁니다.
   - 유형: 선택
   - 선택지:
     - (a) '시작' 뒤에는 왼쪽 위 뒤로가기로 메인에 가기 (권장): 메인에서 "진행 중인 여정이 있어요" 안내를 보고 새 여행을 시작할 수 있습니다. 진행 여정은 저장된 채 남습니다.
     - (b) 뒤로가기 없음: 시안의 여행 화면과 같은 모습입니다. 이번 작업 범위에서는 앱을 다시 켜야 메인으로 갑니다.
     - (c) 직접 입력: 위 선택지 외 다른 방식을 직접 입력합니다.