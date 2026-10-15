import Foundation
import XCTest
@testable import FocusMate

/// 마이페이지(프로필) 모델 동작: 통계 파생, 진입 경로, 메뉴 대상.
@MainActor
final class ProfileModelTests: XCTestCase {
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수역")

    private static let emptyV5 = Data(
        #"{"version":5,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수"},"currentStation":{"id":"seoulForest","name":"서울숲"},"cards":{"items":[]},"journey":{"active":null},"records":{"items":[]}}}"#.utf8
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
            try Self.emptyV5.write(to: fileURL)
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

    // 깨짐 명명: 데이터 출처 진입이 .dataSource를 쌓지 않으면 실패.
    func testAC49_프로필에서_데이터출처를_열면_dataSource가_쌓인다() throws {
        let model = try readyModel()
        model.open(.profile)

        XCTAssertTrue(model.openFromProfile(.dataSource))

        XCTAssertEqual(model.path, [.profile, .dataSource])
    }

    // 깨짐 명명: 프로필이 최상단이 아닌데 push를 허용하면 실패.
    func testAC49_경로_마지막이_프로필이_아니면_데이터출처는_false이고_경로는_불변이다() throws {
        let model = try readyModel()

        XCTAssertFalse(model.openFromProfile(.dataSource))

        XCTAssertEqual(model.path, [])
    }

    // 깨짐 명명: 데이터 출처가 최상단인데 중복 push를 허용하면 실패.
    func testAC49_데이터출처가_최상단이면_중복push는_false이다() throws {
        let model = try readyModel()
        model.open(.profile)
        XCTAssertTrue(model.openFromProfile(.dataSource))

        XCTAssertFalse(model.openFromProfile(.dataSource))

        XCTAssertEqual(model.path, [.profile, .dataSource])
    }

    // 깨짐 명명: 메뉴 항목이 잘못된 목적지로 매핑되거나 제목이 달라지면 실패.
    func testAC49_데이터출처_메뉴는_데이터출처_목적지로_이어진다() {
        XCTAssertEqual(ProfileMenuItem.dataSource.destination, .dataSource)
        XCTAssertEqual(Destination.dataSource.title, "데이터 출처")
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
