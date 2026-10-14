# W11 main/profile integration isolated test-author RED

Status: **READY FOR GREEN / ASSERTION RED CONFIRMED / BUILD-TEST SLOT RELEASED**

Only the newly merged upstream `ProfileModelTests.swift` and `ProfileUITests.swift` were edited. Production code was not read or edited. Existing 20 W10 locked test files, including all 13 W10 UI methods, match their original manifest hashes after this execution. No other test file changed. Unwhitelisted original method bodies and existing helpers in the two edited files were checked byte-for-byte unchanged via pre/post method extraction. Model method count remains 16; UI count is 22 (21 upstream cases with two replacements plus one new case).

## Retired contract and replacement coverage

W11 design W10 merger section (lines253–271) explicitly retires `Destination.cardStudio` and `ProfileMenuItem.customize`; the second-merging branch must inject the real editor callback, supply current card style, and replace AC24/25/33 placeholder tests. W10 AC34 requires real profile edit/save/close/visible success notice with identity/records/stats unchanged. AC35 requires maximum-text-size access using physical scroll and profile return.

Named retirement rationale: old assertions of placeholder push/title/rawValue/customize menu routing and its duplicate/nonprofile path guards describe a navigation route intentionally removed by this contract. They are replaced by real factory read-only/profile-path preservation and an enum-retirement oracle. Settings guards, settings menu mapping, main-menu order, aggregation, records and all unrelated assertions remain. The previous guard that rejected customize when settings was topmost is replaced by the retained settings-only duplicate-push guard; no unsupported path guard is imposed on the editor factory.

Exact old → new method whitelist:

### model_whitelist

- `testAC24_프로필에서_카드꾸미기를_열면_true와_함께_cardStudio가_쌓인다` → `testAC24_프로필에서_실제편집_factory는_경로와저장외형을_보존한다`
- `testAC25_카드꾸미기가_이미_열려_있으면_false이고_경로는_그대로다` → `testAC25_편집_factory를_다시조회해도_프로필경로와원본을_보존한다`
- `testAC24_26_경로_마지막이_프로필이_아니면_false이고_경로는_불변이다` → `testAC26_경로_마지막이_프로필이_아니면_설정은_false이고_경로는_불변이다`
- `testAC24_경로_마지막이_설정이면_카드꾸미기는_false이고_경로는_불변이다` → `testAC27_설정이_최상단이면_설정중복push는_false이고_경로는_불변이다`
- `testAC28_메인_메뉴는_네_항목이며_카드꾸미기를_포함하지_않는다` → `testAC28_메인_메뉴는_네_항목이며_카드꾸미기를_포함하지_않는다`
- `testAC33_cardStudio의_rawValue와_제목이_고정이다` → `testAC33_실제편집합류후_cardStudio_자리표시목적지가_없다`
- `testAC33_프로필_메뉴_항목은_각각의_목적지로_이어진다` → `testAC33_프로필_설정_메뉴는_기존설정목적지로_이어진다`

### ui_whitelist

- `testAC24_카드_꾸미기를_누르면_카드_스튜디오가_열린다` → `testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다`
- `testAC25_카드_스튜디오에서_뒤로가면_마이페이지로_돌아온다` → `testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다`

New UI method: `testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다`.

AC24/AC34 UI opens actual editor, explicitly closes to profile without changes, reopens, changes to literal sand RGB217/205/185, saves, requires modal disappearance, real visible savedNotice, unchanged card ID/issue date/complete records and literal 3 journeys/65min statistics, then reopens and checks saved current style. AC25/AC34 UI requires actual editor open/close to profile with identity/records/file bytes/stats unchanged. New AC35 uses only native app swipes plus actual fully contained/hittable targets; no offscreen forcing, fake setters or app-gutter gestures. The inherited XXXL diagnostics must remain accessibility5.

Independent profileRecords seed checks use existing harness `test.snapshot`: actual card `FM-12345678`, records count3 and minute values15/25/25. Full record content and issue date are canonically compared before/after; UI statistics are independently literal 3 / 1 h 5 min. No production seed source was read. Existing ProfileSeedTests and stats/records tests remain untouched.

## Actual focused execution

Owned iOS27 UUID `F226C28A-81D5-4708-B939-81B605AC748E` only, already booted and VO disabled. No simulator boot/shutdown/erase or other device action was performed. One sequential build/test used `.build/ios`, `parallel-testing-enabled NO`, and the seven changed model methods plus three changed/new UI methods only.

Log: DEV `t5-w11-integration-red.log`.
Result: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_23-18-44-+0900.xcresult`.
Actual **exit65 / 10 cases / 4 assertion failures / 0 unexpected**, comprising unit7 (6PASS,1RED) and UI3 (3RED). Compilation succeeded. Unit actual factory path/style/snapshot/write guards, settings guards, main-menu order, and settings mapping all passed; no already-working guard was forced to fail.

```text
Test Case '-[FocusMateTests.ProfileModelTests testAC24_프로필에서_실제편집_factory는_경로와저장외형을_보존한다]' passed (0.016 seconds).
Test Case '-[FocusMateTests.ProfileModelTests testAC25_편집_factory를_다시조회해도_프로필경로와원본을_보존한다]' passed (0.001 seconds).
Test Case '-[FocusMateTests.ProfileModelTests testAC26_경로_마지막이_프로필이_아니면_설정은_false이고_경로는_불변이다]' passed (0.001 seconds).
Test Case '-[FocusMateTests.ProfileModelTests testAC27_설정이_최상단이면_설정중복push는_false이고_경로는_불변이다]' passed (0.001 seconds).
Test Case '-[FocusMateTests.ProfileModelTests testAC28_메인_메뉴는_네_항목이며_카드꾸미기를_포함하지_않는다]' passed (0.001 seconds).
/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/ProfileModelTests.swift:254: error: -[FocusMateTests.ProfileModelTests testAC33_실제편집합류후_cardStudio_자리표시목적지가_없다] : XCTAssertFalse failed
Test Case '-[FocusMateTests.ProfileModelTests testAC33_실제편집합류후_cardStudio_자리표시목적지가_없다]' failed (0.084 seconds).
Test Case '-[FocusMateTests.ProfileModelTests testAC33_프로필_설정_메뉴는_기존설정목적지로_이어진다]' passed (0.000 seconds).
/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateUITests/ProfileUITests.swift:183: error: -[FocusMateUITests.ProfileUITests testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다] : XCTAssertTrue failed
Test Case '-[FocusMateUITests.ProfileUITests testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다]' failed (15.119 seconds).
/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateUITests/ProfileUITests.swift:235: error: -[FocusMateUITests.ProfileUITests testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다] : XCTAssertTrue failed
Test Case '-[FocusMateUITests.ProfileUITests testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다]' failed (16.379 seconds).
/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateUITests/ProfileUITests.swift:332: error: -[FocusMateUITests.ProfileUITests testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다] : XCTAssertTrue failed
Test Case '-[FocusMateUITests.ProfileUITests testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다]' failed (21.398 seconds).
```

The unit failure proves `Destination.allCases` still includes cardStudio. All three UI failures occur at actual `screen.cardCustomization` appearance after a real profile.customize tap; this is the real integration RED, not a compiler failure or absence of fixture data. Save, success-notice, reopen-style and close-return assertions after the failing entry are not yet executed and cannot be claimed verified.

AC35 evidence limit: on this seed/runtime, main `open.profile` was already fully visible/hittable; reach required no main swipe. The case then performed a real profile swipe and failed at real editor entry. Therefore this run does **not** prove a main scroll defect, nor is the unreachable-main hypothesis reported as confirmed. The reach helper will swipe when needed, but its first successful main reach is a positive guard in this run.

## Integrity and handoff

- model_before_sha256: `e88f3798264a487580468db60219e81d9a9ddbd2024557e2494ba81bf321926a`
- ui_before_sha256: `bbc415338c97f69fe9abe28a559b2deff0ff7a711df1dbc0d40baaf1317c335d`
- model_after_sha256: `3859d442f4b9e4dd7eae59c81dfbc36238c3607b5c0739f2e07f845d9325e8b5`
- ui_after_sha256: `ff85a2fdbf15f0a661611ff870009254dd2bf30c317150ad3a42796e3712fadc`

- ios/FocusMateTests/ProfileModelTests.swift Git-blob SHA1: `be939ee5296cd0afe2df63a30a7f18d1654867ad`
- ios/FocusMateUITests/ProfileUITests.swift Git-blob SHA1: `7369922d4c0c7d1918e84cc8788367373e9e7bfc`

All logs/results preserved; no process remains active. Exclusive build/test slot released. Parent must add these two upstream test files to the frozen manifest with these hashes before source execution. Full W11/Profile/Phase1/CardIssuance/W10 cumulative regression remains a later verification gate; this author ran only scoped tests.

API evidence came exclusively from declarations in the dispatch, existing test factories/harness/model test patterns, W11 merger design and W10 PRD/design. No production implementation was opened. Whitelist machine record: `reports/t5-w11-author-whitelist.json`.

## Full focused command

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination "platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E" -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO -collect-test-diagnostics never "-only-testing:FocusMateTests/ProfileModelTests/testAC24_프로필에서_실제편집_factory는_경로와저장외형을_보존한다" "-only-testing:FocusMateTests/ProfileModelTests/testAC25_편집_factory를_다시조회해도_프로필경로와원본을_보존한다" "-only-testing:FocusMateTests/ProfileModelTests/testAC26_경로_마지막이_프로필이_아니면_설정은_false이고_경로는_불변이다" "-only-testing:FocusMateTests/ProfileModelTests/testAC27_설정이_최상단이면_설정중복push는_false이고_경로는_불변이다" "-only-testing:FocusMateTests/ProfileModelTests/testAC28_메인_메뉴는_네_항목이며_카드꾸미기를_포함하지_않는다" "-only-testing:FocusMateTests/ProfileModelTests/testAC33_실제편집합류후_cardStudio_자리표시목적지가_없다" "-only-testing:FocusMateTests/ProfileModelTests/testAC33_프로필_설정_메뉴는_기존설정목적지로_이어진다" "-only-testing:FocusMateUITests/ProfileUITests/testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다" "-only-testing:FocusMateUITests/ProfileUITests/testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다" "-only-testing:FocusMateUITests/ProfileUITests/testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다"
```

## Complete test source: ios/FocusMateTests/ProfileModelTests.swift

```swift
import Foundation
import XCTest
@testable import FocusMate

/// 마이페이지(프로필) 모델 동작: 통계 파생, 진입 경로, 메뉴 대상.
@MainActor
final class ProfileModelTests: XCTestCase {
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)

    private static let emptyV2 = Data(
        #"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[]},"journey":{"active":null},"records":{"items":[]}}}"#.utf8
    )

    private final class Probe {
        var writeCalls = 0
    }

    private func readyModel(_ probe: Probe = Probe()) throws -> AppModel {
        let bytes = try SnapshotCodec.encode(Self.stage(true, Self.seongsu, Self.seongsu))
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { _, _ in probe.writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        return model
    }

    private static func input(minutes: Int = 25) -> RecordCompletionInput {
        RecordCompletionInput(
            id: "journey-001",
            completedAt: "2026-10-13T01:00:00Z",
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구"
        )
    }

    private static func record(id: String, minutes: Int) -> RecordSnapshot {
        RecordSnapshot(
            id: id,
            completedAt: "2026-10-13T01:00:00Z",
            date: "2026-10-13",
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구",
            memo: ""
        )
    }

    // MARK: AC-13 예시 완료는 통계를 바꾸지 않는다

    // 깨짐 명명: 예시 완료를 통계 계산에 포함하면(또는 기록을 추가하면) 전후 통계가 달라져 실패.
    func testAC13_예시_하차_완료는_profileStats를_바꾸지_않는다() throws {
        let model = try readyModel()
        let before = model.profileStats

        _ = model.recordCompletion(Self.input(), outcome: .alighted, isExample: true, timeZone: Self.seoul)

        XCTAssertEqual(model.profileStats, before)
        XCTAssertEqual(model.profileStats, .loaded(RecordLifetimeSummary(count: 0, minutes: 0)))
    }

    // MARK: AC-14 저장 필드 재정의 금지 + 단일 출처

    // 깨짐 명명: CardSnapshot에 count/minutes/summary/journeys/total 계열 통계 필드를 저장하면 실패.
    func testAC14_CardSnapshot은_통계_저장_필드를_갖지_않는다() {
        let card = CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000))
        let forbidden = ["count", "minutes", "summary", "journeys", "total"]

        let labels = Mirror(reflecting: card).children.compactMap { $0.label?.lowercased() }

        for label in labels {
            for word in forbidden {
                XCTAssertFalse(label.contains(word), "통계성 필드 금지: \(label)")
            }
        }
    }

    // 깨짐 명명: profileStats가 별도 캐시/카운터를 쓰거나 records 파생과 다른 값을 내면 실패.
    func testAC14_profileStats는_스냅샷_기록에서_파생한_값과_같다() throws {
        let model = try readyModel()

        XCTAssertEqual(model.profileStats, ProfileStats.from(model.snapshot?.records))
    }

    // MARK: AC-17 완료 후 갱신

    // 깨짐 명명: 완료 저장 후 profileStats가 갱신되지 않거나 분/건수를 잘못 합산하면 실패.
    func testAC17_25분_하차_완료_뒤_profileStats는_1건_25분이다() throws {
        try withTemporaryFile { fileURL in
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.emptyV2.write(to: fileURL)
            let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            model.loadIfNeeded()
            XCTAssertEqual(model.profileStats, .loaded(RecordLifetimeSummary(count: 0, minutes: 0)))

            XCTAssertTrue(model.recordCompletion(Self.input(minutes: 25), outcome: .alighted, isExample: false, timeZone: Self.seoul))

            XCTAssertEqual(model.profileStats, .loaded(RecordLifetimeSummary(count: 1, minutes: 25)))
        }
    }

    // MARK: AC-15 읽기는 쓰기를 만들지 않는다

    // 깨짐 명명: 프로필 열기/통계 읽기가 저장(write)을 호출하면 실패.
    func testAC15_프로필을_열고_통계를_읽어도_쓰기는_0회다() throws {
        let probe = Probe()
        let model = try readyModel(probe)

        model.open(.profile)
        _ = model.profileStats

        XCTAssertEqual(model.path, [.profile])
        XCTAssertEqual(probe.writeCalls, 0)
    }

    // MARK: AC-24/25 카드 꾸미기 진입

    // 깨짐 명명: 실제 편집 factory 조회가 프로필 경로/저장 외형을 바꾸거나 쓰기를 만들면 실패.
    func testAC24_프로필에서_실제편집_factory는_경로와저장외형을_보존한다() throws {
        let probe = Probe()
        let original = Self.stage(true, Self.seongsu, Self.seongsu).issuingCard(
            CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000)))
        let bytes = try SnapshotCodec.encode(original)
        let model = AppModel(store: LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes }, createDirectory: { _ in },
            writeData: { _, _ in probe.writeCalls += 1 }))
        model.loadIfNeeded()
        model.open(.profile)

        let controller = try XCTUnwrap(model.beginCardCustomization())

        XCTAssertEqual(controller.draft, model.currentCardStyle)
        XCTAssertEqual(model.path, [.profile])
        XCTAssertEqual(model.snapshot, original)
        XCTAssertEqual(probe.writeCalls, 0)
    }

    // 깨짐 명명: factory 재조회가 경로를 쌓거나 원본을 변경하면 실패.
    func testAC25_편집_factory를_다시조회해도_프로필경로와원본을_보존한다() throws {
        let probe = Probe()
        let original = Self.stage(true, Self.seongsu, Self.seongsu).issuingCard(
            CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000)))
        let bytes = try SnapshotCodec.encode(original)
        let model = AppModel(store: LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes }, createDirectory: { _ in },
            writeData: { _, _ in probe.writeCalls += 1 }))
        model.loadIfNeeded()
        model.open(.profile)

        let first = try XCTUnwrap(model.beginCardCustomization())
        let second = try XCTUnwrap(model.beginCardCustomization())

        XCTAssertEqual(first.draft, model.currentCardStyle)
        XCTAssertEqual(second.draft, model.currentCardStyle)
        XCTAssertEqual(model.path, [.profile])
        XCTAssertEqual(model.snapshot, original)
        XCTAssertEqual(probe.writeCalls, 0)
    }

    // MARK: AC-26/27 설정 진입

    // 깨짐 명명: settings 진입이 path에 .settings를 쌓지 않으면 실패.
    func testAC26_프로필에서_설정을_열면_settings가_쌓인다() throws {
        let model = try readyModel()
        model.open(.profile)

        XCTAssertTrue(model.openFromProfile(.settings))

        XCTAssertEqual(model.path, [.profile, .settings])
    }

    // 깨짐 명명: 프로필이 최상단이 아닐 때(빈 경로)도 push를 허용하면 실패.
    func testAC26_경로_마지막이_프로필이_아니면_설정은_false이고_경로는_불변이다() throws {
        let model = try readyModel()
        XCTAssertEqual(model.path, [])

        XCTAssertFalse(model.openFromProfile(.settings))

        XCTAssertEqual(model.path, [])
    }

    // 깨짐 명명: 이미 설정이 최상단인데 settings 중복 push를 허용하면 실패.
    func testAC27_설정이_최상단이면_설정중복push는_false이고_경로는_불변이다() throws {
        let model = try readyModel()
        model.open(.profile)
        XCTAssertTrue(model.openFromProfile(.settings))
        XCTAssertEqual(model.path, [.profile, .settings])

        XCTAssertFalse(model.openFromProfile(.settings))

        XCTAssertEqual(model.path, [.profile, .settings])
    }

    // MARK: AC-28 메인 메뉴

    // 깨짐 명명: mainMenu에 cardStudio를 넣거나 순서·profile 누락이 생기면 실패.
    func testAC28_메인_메뉴는_네_항목이며_카드꾸미기를_포함하지_않는다() {
        XCTAssertEqual(Destination.mainMenu, [.preparation, .records, .settings, .profile])
        XCTAssertFalse(Destination.mainMenu.map(\.rawValue).contains("cardStudio"))
    }

    // MARK: AC-29/30 통계 파생

    // 깨짐 명명: 0분 기록이 섞인 손상 데이터를 부분 집계(.loaded)로 내보내면 실패.
    func testAC29_0분_기록이_섞이면_unavailable이다() {
        let section = RecordSection(items: [
            Self.record(id: "a", minutes: 25),
            Self.record(id: "b", minutes: 25),
            Self.record(id: "c", minutes: 0),
            Self.record(id: "d", minutes: 25),
            Self.record(id: "e", minutes: 25),
        ])

        XCTAssertEqual(ProfileStats.from(section), .unavailable)
    }

    // 깨짐 명명: nil 기록을 0건 loaded로 처리하면 실패.
    func testAC29_기록이_nil이면_unavailable이다() {
        XCTAssertEqual(ProfileStats.from(nil), .unavailable)
    }

    // 깨짐 명명: 건수 또는 분 합산이 틀리면(예: 25+25+15 != 65) 실패.
    func testAC12_유효한_세_건은_3건_65분이다() {
        let section = RecordSection(items: [
            Self.record(id: "a", minutes: 25),
            Self.record(id: "b", minutes: 25),
            Self.record(id: "c", minutes: 15),
        ])

        XCTAssertEqual(ProfileStats.from(section), .loaded(RecordLifetimeSummary(count: 3, minutes: 65)))
    }

    // MARK: AC-33 카드 꾸미기 목적지와 메뉴 매핑

    // 깨짐 명명: W10 합류 뒤에도 cardStudio placeholder enum이 남으면 실패.
    func testAC33_실제편집합류후_cardStudio_자리표시목적지가_없다() {
        XCTAssertFalse(Destination.allCases.map(\.rawValue).contains("cardStudio"))
    }

    // 깨짐 명명: 메뉴 항목이 잘못된 목적지로 매핑되면 실패.
    func testAC33_프로필_설정_메뉴는_기존설정목적지로_이어진다() {
        XCTAssertEqual(ProfileMenuItem.settings.destination, .settings)
    }
}
```

## Complete test source: ios/FocusMateUITests/ProfileUITests.swift

```swift
import Foundation
import XCTest

@MainActor
final class ProfileUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - 진입·구성

    // 깨짐 명명: open.profile 탭이 마이페이지로 이동하지 않거나 제목이 "마이페이지"가 아니면 실패
    func testAC1_메인에서_마이페이지로_진입하면_제목이_마이페이지다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        let screen = openProfile(h)
        XCTAssertEqual(screen.label, "마이페이지")
    }

    // 깨짐 명명: 요소 순서가 바뀌거나 한 요소라도 빠지면 실패
    func testAC2_마이페이지_요소는_설계_순서대로_위에서_아래로_배치된다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let ids = [
            "screen.profile", "profile.headline", "profile.subhead", "profile.card",
            "profile.cardName", "profile.cardTagline", "profile.customize",
            "profile.stat.journeys", "profile.stat.time", "profile.settings"
        ]
        var frames: [(String, CGFloat, CGFloat)] = []
        for id in ids {
            let e = h.element(id)
            XCTAssertTrue(e.waitForExistence(timeout: timeout), "없음: \(id)")
            frames.append((id, e.frame.minY.rounded(), e.frame.minX))
        }
        // 통계 두 칸은 같은 행(minY 1pt 이내)일 수 있으므로 같은 행이면 minX로 비교
        for i in 1..<frames.count {
            let prev = frames[i - 1], cur = frames[i]
            let sameRow = abs(prev.1 - cur.1) <= 1
            let ordered = sameRow ? prev.2 <= cur.2 : prev.1 < cur.1
            XCTAssertTrue(ordered, "순서 위반: \(prev.0)(\(prev.1),\(prev.2)) -> \(cur.0)(\(cur.1),\(cur.2))")
        }
    }

    // 깨짐 명명: 헤드라인·서브헤드 문구가 달라지면 실패
    func testAC3_헤드라인과_서브헤드_문구가_설계와_같다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.headline").label, "내 시간에, 내 취향을.")
        XCTAssertEqual(h.element("profile.subhead").label, "한 장으로 함께하는 나만의 여정")
    }

    // 깨짐 명명: 카드 이름·태그라인 문구가 달라지면 실패
    func testAC4_카드_이름과_태그라인_문구가_설계와_같다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.cardName").label, "집중동행카드")
        XCTAssertEqual(h.element("profile.cardTagline").label, "모든 몰입 여정에 함께")
    }

    // 깨짐 명명: 통계 칸 접근성 라벨에 항목 이름이 빠지면 실패
    func testAC4_통계_칸_라벨에_항목_이름이_들어_있다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertTrue(h.element("profile.stat.journeys").label.contains("완료한 여정"))
        XCTAssertTrue(h.element("profile.stat.time").label.contains("함께한 시간"))
    }

    // 깨짐 명명: 카드 접근성 라벨이 "집중동행카드"가 아니거나 카드 번호(FM-)가 노출되면 실패
    func testAC19_카드_접근성_라벨은_집중동행카드이고_카드번호를_노출하지_않는다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        let card = h.element("profile.card")
        XCTAssertTrue(card.exists)
        XCTAssertTrue(card.label.contains("집중동행카드"))
        XCTAssertFalse(card.label.contains("FM-"))
    }

    // 깨짐 명명: 화면 어디에든 카드 번호(FM-)가 label/value로 노출되면 실패
    func testAC6_마이페이지_화면_어디에도_카드번호가_보이지_않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        XCTAssertTrue(h.element("profile.settings").waitForExistence(timeout: timeout))
        let root = try h.app.snapshot()
        var texts: [String] = []
        collect(root, into: &texts)
        XCTAssertFalse(texts.isEmpty, "수집된 텍스트가 없음")
        XCTAssertTrue(texts.filter { $0.contains("FM-") }.isEmpty, "카드번호 노출: \(texts.filter { $0.contains("FM-") })")
    }

    // MARK: - 통계 값

    // 깨짐 명명: 기록 0건에서 0/0 min이 아니거나 오류가 표시되면 실패
    func testAC8_기록이_없으면_통계가_0과_0분이고_오류가_없다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.stat.journeys.value").label, "0")
        XCTAssertEqual(h.element("profile.stat.time.value").label, "0 min")
        XCTAssertFalse(h.element("profile.statsError").exists)
    }

    // 깨짐 명명: 기록 3건(65분) 집계가 틀리거나 값에 한국어 단위가 섞이면 실패
    func testAC9_22_기록_3건은_3과_1h_5min으로_단위_없이_표시된다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        let journeys = h.element("profile.stat.journeys.value").label
        let time = h.element("profile.stat.time.value").label
        XCTAssertEqual(journeys, "3")
        XCTAssertEqual(time, "1 h 5 min")
        for text in [journeys, time] {
            XCTAssertFalse(text.contains("분"))
            XCTAssertFalse(text.contains("시간"))
        }
    }

    // 깨짐 명명: 통계 칸 접근성 라벨이 한국어 단위 문장("3회", "1시간 5분")이 아니면 실패
    func testAC18_통계_칸_접근성_라벨은_한국어_단위로_읽힌다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.stat.journeys").label, "완료한 여정, 3회")
        XCTAssertEqual(h.element("profile.stat.time").label, "함께한 시간, 1시간 5분")
    }

    // 깨짐 명명: 정상 집계인데 오류 안내가 표시되면 실패
    func testAC32_정상_집계에서는_통계_오류가_없다() {
        for seed in ["ready", "profileRecords"] {
            let h = FocusMateUIHarness.launch(seed: seed)
            _ = openProfile(h)
            XCTAssertTrue(h.element("profile.settings").waitForExistence(timeout: timeout))
            XCTAssertFalse(h.element("profile.statsError").exists, "seed=\(seed)")
            h.app.terminate()
        }
    }

    // MARK: - 읽기 전용·내비게이션

    // 깨짐 명명: 마이페이지가 열려 있는 동안 저장 파일을 바꾸면(쓰기 발생) 실패
    func testAC15_마이페이지를_열어도_저장_데이터는_바뀌지_않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("open.profile").waitForExistence(timeout: timeout))
        let before = try h.diagnostic("test.persistedBytes")
        _ = openProfile(h)
        let result = XCTWaiter().wait(for: [XCTestExpectation(description: "idle")], timeout: 3)
        XCTAssertEqual(result, .timedOut)
        backButton(h).tap()
        XCTAssertTrue(h.element("open.profile").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), before)
    }

    // 깨짐 명명: 뒤로 버튼이 마이페이지를 닫지 않거나 메인 진입점이 복구되지 않으면 실패
    func testAC16_뒤로를_누르면_메인으로_돌아와_마이페이지_진입점이_눌린다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        backButton(h).tap()
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.profile").exists)
        XCTAssertTrue(entry.isHittable)
    }

    // 깨짐 명명: customize/settings를 버튼으로 노출하지 않거나 라벨·탭 가능 상태가 틀리면 실패
    func testAC23_카드_꾸미기와_설정은_눌리는_버튼으로_노출된다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let customize = h.app.buttons["profile.customize"]
        let settings = h.app.buttons["profile.settings"]
        XCTAssertTrue(customize.waitForExistence(timeout: timeout))
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        XCTAssertEqual(customize.label, "카드 꾸미기")
        XCTAssertEqual(settings.label, "설정")
        XCTAssertTrue(customize.isHittable)
        XCTAssertTrue(settings.isHittable)
    }

    // 깨짐 명명: 실제 편집 대신 placeholder를 열거나 저장 뒤 프로필 복귀/안내/외형 또는 사용 기록을 잃으면 실패
    func testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다() throws {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        let beforeUsage = try profileUsage(h)
        _ = openProfile(h)
        assertProfileRecordStats(h)
        h.element("profile.customize").tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
        let originalStyle = try customizationJSON(h)
        let close = h.element("cardCustomization.close")
        XCTAssertTrue(close.isHittable); close.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardCustomization").exists)
        XCTAssertEqual(try profileUsage(h), beforeUsage)

        h.element("profile.customize").tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
        let sand = h.element("cardCustomization.color.sand")
        try reachVisible(sand, h)
        sand.tap()
        let edited = try customizationJSON(h)
        let draft = try XCTUnwrap(edited["draft"] as? [String: Any])
        let background = try XCTUnwrap(draft["background"] as? [String: Any])
        XCTAssertEqual(try XCTUnwrap(background["red"] as? Double), 217.0 / 255, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(background["green"] as? Double), 205.0 / 255, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(background["blue"] as? Double), 185.0 / 255, accuracy: 0.000001)
        let save = h.element("cardCustomization.save")
        XCTAssertTrue(save.isHittable); save.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !h.element("screen.cardCustomization").exists
        }, object: h.app)
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: timeout), .completed)
        let notice = h.element("cardCustomization.savedNotice")
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, "카드 외형을 저장했어요.")
        XCTAssertTrue(h.app.frame.contains(notice.frame), "저장 안내 전체가 현재 프로필 화면에 보여야 한다")
        XCTAssertTrue(notice.isHittable, "저장 안내가 가려지면 안 된다")
        XCTAssertEqual(try profileUsage(h), beforeUsage)
        assertProfileRecordStats(h)
        let savedStyle = try customizationJSON(h)
        XCTAssertEqual(savedStyle["cardID"] as? String, originalStyle["cardID"] as? String)
        XCTAssertEqual(try canonicalJSON(savedStyle["background"]), try canonicalJSON(background))
        h.element("profile.customize").tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
        let reopened = try XCTUnwrap(try customizationJSON(h)["draft"] as? [String: Any])
        XCTAssertEqual(try canonicalJSON(reopened["background"]), try canonicalJSON(background))
        h.element("cardCustomization.close").tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    // 깨짐 명명: 실제 편집기 닫기가 프로필로 복귀하지 않거나 정체성/기록/파일을 변경하면 실패
    func testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다() throws {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        let beforeUsage = try profileUsage(h)
        let bytes = try h.diagnostic("test.persistedBytes")
        _ = openProfile(h)
        assertProfileRecordStats(h)
        h.element("profile.customize").tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
        let close = h.element("cardCustomization.close")
        XCTAssertTrue(close.isHittable); close.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardCustomization").exists)
        XCTAssertEqual(try profileUsage(h), beforeUsage)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        assertProfileRecordStats(h)
    }

    // 깨짐 명명: 설정 탭이 설정 화면으로 이동하지 않으면 실패
    func testAC26_설정을_누르면_설정_화면이_열린다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.settings").tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
    }

    // 깨짐 명명: 설정에서 뒤로가 마이페이지로 복귀시키지 않으면 실패
    func testAC27_설정에서_뒤로가면_마이페이지로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.settings").tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
        backButton(h).tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    // 깨짐 명명: 내비 버튼이 뒤로 외에 더 있거나 본문 버튼이 customize/settings 2개가 아니면 실패
    func testAC23_마이페이지의_버튼_구성은_뒤로와_카드꾸미기와_설정뿐이다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let nav = h.app.navigationBars.firstMatch
        XCTAssertTrue(nav.waitForExistence(timeout: timeout))
        XCTAssertEqual(nav.buttons.count, 1)
        XCTAssertEqual(h.app.buttons.count, 3)
    }

    // MARK: - 최대 글자 크기

    // 깨짐 명명: 큰 글자에서 주요 요소가 스크롤해도 가시 영역에 완전히 들어오지 않으면 실패
    func testAC20_최대_글자_크기에서_주요_요소가_스크롤로_가시_영역에_들어온다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: xxxl)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")
        entry.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))

        let navMaxY = h.app.navigationBars.firstMatch.frame.maxY
        let windowMaxY = h.app.windows.firstMatch.frame.maxY
        for id in ["profile.card", "profile.customize", "profile.stat.journeys", "profile.stat.time", "profile.settings"] {
            let target = h.element(id)
            XCTAssertTrue(target.waitForExistence(timeout: timeout), "없음: \(id)")
            var swipes = 0
            while !(target.frame.minY >= navMaxY && target.frame.maxY <= windowMaxY) && swipes < 3 {
                h.app.swipeUp()
                swipes += 1
            }
            XCTAssertGreaterThanOrEqual(target.frame.minY, navMaxY, "\(id) 위쪽이 내비바에 가림")
            XCTAssertLessThanOrEqual(target.frame.maxY, windowMaxY, "\(id) 아래쪽이 화면 밖")
        }
    }

    // 깨짐 명명: 큰 글자에서 설정 버튼 탭이 설정 화면을 열지 못하면 실패
    func testAC20_최대_글자_크기에서_설정을_눌러_설정에_가고_뒤로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: xxxl)
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")
        entry.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        let settings = h.element("profile.settings")
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        var swipes = 0
        while !settings.isHittable && swipes < 3 {
            h.app.swipeUp()
            swipes += 1
        }
        settings.tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
        backButton(h).tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    func testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다() throws {
        let h = FocusMateUIHarness.launch(seed: "profileRecords", extraArguments: xxxl)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let beforeUsage = try profileUsage(h)
        let entry = h.element("open.profile")
        try reachVisible(entry, h)
        entry.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        let customize = h.element("profile.customize")
        try reachVisible(customize, h)
        customize.tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
        let close = h.element("cardCustomization.close")
        XCTAssertTrue(close.isHittable); close.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardCustomization").exists)
        XCTAssertEqual(try profileUsage(h), beforeUsage)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
    }

    // MARK: - Helpers

    private let xxxl = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    @discardableResult
    private func openProfile(_ h: FocusMateUIHarness) -> XCUIElement {
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout), "open.profile 없음")
        entry.tap()
        let screen = h.element("screen.profile")
        XCTAssertTrue(screen.waitForExistence(timeout: timeout), "screen.profile 없음")
        return screen
    }

    private func backButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.app.navigationBars.firstMatch.buttons.firstMatch
    }

    private func collect(_ node: XCUIElementSnapshot, into texts: inout [String]) {
        if !node.identifier.hasPrefix("test.") {
            if !node.label.isEmpty { texts.append(node.label) }
            if let value = node.value as? String, !value.isEmpty { texts.append(value) }
        }
        for child in node.children { collect(child, into: &texts) }
    }

    private func reachVisible(_ target: XCUIElement, _ h: FocusMateUIHarness) throws {
        XCTAssertTrue(target.waitForExistence(timeout: timeout))
        func visible() -> Bool {
            let top = h.app.navigationBars.firstMatch.exists ? h.app.navigationBars.firstMatch.frame.maxY : h.app.frame.minY
            return target.isHittable && h.app.frame.contains(target.frame) && target.frame.minY >= top
        }
        for _ in 0..<6 {
            if visible() { break }
            // Native swipe only; no tapping an offscreen coordinate or synthesizing a product action.
            if target.frame.minY < h.app.frame.minY { h.app.swipeDown() }
            else { h.app.swipeUp() }
        }
        XCTAssertTrue(visible(), "실제 스크롤로 화면 안에 도달해야 한다: " + target.identifier)
    }

    private func profileUsage(_ h: FocusMateUIHarness) throws -> Data {
        let snapshot = try h.snapshot()
        let cards = try XCTUnwrap(snapshot["cards"] as? [String: Any])
        let firstCard = try XCTUnwrap((cards["items"] as? [[String: Any]])?.first)
        XCTAssertEqual(firstCard["id"] as? String, "FM-12345678")
        let records = try XCTUnwrap(snapshot["records"] as? [String: Any])
        let items = try XCTUnwrap(records["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.compactMap { $0["minutes"] as? Int }.sorted(), [15, 25, 25])
        return try canonicalJSON(["cardID": firstCard["id"] ?? NSNull(),
                                  "issuedAt": firstCard["issuedAt"] ?? NSNull(), "records": records])
    }

    private func assertProfileRecordStats(_ h: FocusMateUIHarness) {
        XCTAssertEqual(h.element("profile.stat.journeys.value").label, "3")
        XCTAssertEqual(h.element("profile.stat.time.value").label, "1 h 5 min")
    }

    private func customizationJSON(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let raw = try h.diagnostic("test.cardStyleJSON")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
    }

    private func canonicalJSON(_ value: Any?) throws -> Data {
        try JSONSerialization.data(withJSONObject: value ?? NSNull(), options: [.sortedKeys, .fragmentsAllowed])
    }
}
```
