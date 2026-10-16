import Foundation
import XCTest
@testable import FocusMate

/// 실제 저장소 경계의 closure만 대체한다. AppModel/Projection/Publisher는 실제 대상을 사용한다.
@MainActor
final class WidgetAppProbe {
    var now = WidgetFixtures.generated
    var disk: Data?
    var shared: Data?
    var writes = 0
    var shareAttempts = 0
    var sharedWrites = 0
    var reloads = 0
    var localFails = false
    var shareFails = false
    var readFails = false
    var events: [String] = []
}

@MainActor
enum WidgetAppTestFixtures {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = WidgetFixtures.utc
        return value
    }
    static func source(active: JourneySnapshot? = nil) -> AppSnapshot {
        BoardingFixtures.snapshot(active: active)
    }
    static func make(
        snapshot: AppSnapshot, probe: WidgetAppProbe, legacy: Data? = nil,
        overrideStore: LocalSnapshotStore? = nil
    ) throws -> (AppModel, WidgetSnapshotPublisher) {
        probe.disk = try legacy ?? SnapshotCodec.encode(snapshot)
        let sharedStore = WidgetSnapshotStore(
            containerURL: { URL(fileURLWithPath: "/unused/widget-group", isDirectory: true) },
            readData: { _ in
                guard let bytes = probe.shared else { throw WidgetDataIssue.readFailed }
                return bytes
            },
            atomicWrite: { bytes, _ in
                probe.shareAttempts += 1
                if probe.shareFails { throw WidgetDataIssue.writeFailed }
                probe.shared = bytes
                probe.sharedWrites += 1
                probe.events.append("share")
            }
        )
        let publisher = WidgetSnapshotPublisher(
            store: sharedStore, now: { probe.now }, calendar: calendar,
            timeZone: { WidgetFixtures.utc }, reload: { probe.reloads += 1; probe.events.append("reload") }
        )
        let localStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                if probe.readFails { throw CocoaError(.fileReadNoPermission) }
                guard let bytes = probe.disk else { throw CocoaError(.fileReadNoSuchFile) }
                return bytes
            },
            createDirectory: { _ in },
            writeData: { bytes, _ in
                probe.writes += 1
                if probe.localFails { throw WidgetDataIssue.writeFailed }
                probe.disk = bytes
                probe.events.append("local")
            }
        )
        let model = AppModel(
            store: overrideStore ?? localStore,
            recordClock: RecordClock(now: { probe.now }, timeZone: { WidgetFixtures.utc }),
            routeData: BoardingFixtures.readyRouteData(), widgetPublisher: publisher
        )
        return (model, publisher)
    }
    static func initialOption() throws -> StopSearchOption {
        guard case let .results(options, _) = StationSearch.search("성수역", in: BoardingFixtures.uiCatalog()) else {
            throw WidgetDataIssue.invalidSnapshot
        }
        return try XCTUnwrap(options.first { $0.id == "seongsu" })
    }
}

@MainActor
final class WidgetPublicationTests: XCTestCase {
    private typealias F = WidgetAppTestFixtures

    // 깨짐: 공용주결과대신 위젯전용집계를 사용하여 날짜·태그합이 달라진다.
    func testW18_원본투영은_60분3회와_주7일을_보존한다() throws {
        let records = [
            RecordsCalendarTests.record(id: "a", date: "2026-10-12", minutes: 10),
            RecordsCalendarTests.record(id: "b", date: "2026-10-12", minutes: 20),
            RecordsCalendarTests.record(id: "c", date: "2026-10-14", minutes: 30)
        ]
        let source = F.source().updating(records: RecordSection(items: records))
        let result = try WidgetSnapshotProjection.make(snapshot: source, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        XCTAssertEqual(result.analytics.days.map(\.minutes), [30, 0, 30, 0, 0, 0, 0])
        XCTAssertEqual(result.analytics.weekMinutes, 60)
        XCTAssertEqual(result.analytics.weekCount, 3)
        XCTAssertEqual(result.analytics.today.minutes, 0)
        XCTAssertEqual(result.analytics.tags.map(\.minutes), [60])
    }

    // 깨짐: 진행/정지/도착을모두같게투영하거나 복원할때경과값을시계로외삽한다.
    func testW18_여정상태와_저장경과를_그대로_투영한다() throws {
        let examples: [(JourneySnapshot, WidgetJourneyPhase, Int)] = [
            (BoardingFixtures.journey(minutes: 30, phase: .awaitingDeparture), .awaitingDeparture, 0),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: false), .running, 678),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: true), .paused, 678),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 1800, paused: true), .arrived, 1800)
        ]
        for (journey, expectedPhase, expectedElapsed) in examples {
            let result = try WidgetSnapshotProjection.make(snapshot: F.source(active: journey), now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
            XCTAssertEqual(result.journey.phase, expectedPhase)
            XCTAssertEqual(result.journey.elapsedSeconds, expectedElapsed)
            XCTAssertEqual(result.journey.totalSeconds, 1800)
        }
    }

    // 깨짐: 설정전과완료후여정없음을구별하지않는다.
    func testW18_설정전과_새준비를_서로다르게_투영한다() throws {
        let setup = try WidgetSnapshotProjection.make(snapshot: .empty, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        let ready = try WidgetSnapshotProjection.make(snapshot: F.source(), now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        XCTAssertEqual(setup.journey.phase, .setup)
        XCTAssertEqual(ready.journey.phase, .ready)
    }

    // 깨짐: 원본카드ID/완료기록ID/할일/메모를 공유DTO로투영한다.
    func testW18_원본투영은_금지원문을_공유JSON에_넣지않는다() throws {
        let source = F.source().updating(records: RecordSection(items: [RecordsCalendarTests.record(id: "private-record", date: "2026-10-14", minutes: 30, memo: "private-memo")]))
        let result = try WidgetSnapshotProjection.make(snapshot: source, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        let text = String(decoding: try JSONEncoder().encode(result), as: UTF8.self)
        XCTAssertFalse(text.contains("private-record"))
        XCTAssertFalse(text.contains("private-memo"))
        XCTAssertFalse(text.contains("FM-01234567"))
        XCTAssertFalse(text.contains("책 한 챕터 읽기"))
    }

    // 깨짐: 정상게시후reload를생략하거나 동일payload를반복쓰기한다.
    func testW18_성공게시만_reload하고_동일payload는_중복게시하지않는다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.events, ["share", "reload"])
        probe.now = WidgetFixtures.date("2026-10-16T12:00:01Z")
        _ = publisher.publish(snapshot: F.source())
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 동일값이라는이유로30분지난공유본을갱신하지않는다.
    func testW18_동일payload라도_30분만료면_재게시한다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        probe.now = WidgetFixtures.date("2026-10-16T12:30:00Z")
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.sharedWrites, 2)
        XCTAssertEqual(probe.reloads, 2)
    }

    // 깨짐: 공유쓰기실패때이전bytes를잃거나실패후reload한다.
    func testW18_공유실패는_이전공유본과_reload횟수를_보존한다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        let before = probe.shared
        probe.shareFails = true
        probe.now = WidgetFixtures.date("2026-10-17T00:00:00Z")
        XCTAssertFalse(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.shared, before)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 성공복원된paused원본을공유하지않거나경과를재시작한다.
    func testW18_성공복원은_정지저장진행을_게시한다() throws {
        let probe = WidgetAppProbe()
        let source = F.source(active: BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: true))
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.loadIfNeeded()
        XCTAssertEqual(probe.sharedWrites, 1)
        let decoded = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared))
        guard case .valid(let result) = decoded else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(result.journey.phase, .paused)
        XCTAssertEqual(result.journey.elapsedSeconds, 678)
    }

    // 깨짐: 원본저장실패후후보를게시하거나성공재시도게시를누락한다.
    func testW18_저장실패후보는_미게시하고_성공재시도뒤만_게시한다() throws {
        let probe = WidgetAppProbe()
        let source = F.source(active: BoardingFixtures.journey(phase: .departed, elapsedSeconds: 600, paused: true))
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.loadIfNeeded()
        let before = probe.shared
        let sharedBefore = probe.sharedWrites
        probe.localFails = true
        XCTAssertEqual(model.resumeJourney(), .saveFailed)
        XCTAssertEqual(probe.sharedWrites, sharedBefore)
        XCTAssertEqual(probe.shared, before)
        probe.localFails = false
        XCTAssertEqual(model.resumeJourney(), .done)
        XCTAssertEqual(probe.sharedWrites, sharedBefore + 1)
        XCTAssertEqual(Array(probe.events.suffix(3)), ["local", "share", "reload"])
    }

    // 깨짐: 공유실패를앱원본저장실패로전파한다.
    func testW18_공유실패여도_앱저장은_성공한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(active: BoardingFixtures.journey(phase: .departed, paused: true)), probe: probe)
        model.loadIfNeeded()
        let sharedBefore = probe.shared
        let reloadBefore = probe.reloads
        probe.shareFails = true
        XCTAssertEqual(model.resumeJourney(), .done)
        XCTAssertFalse(try XCTUnwrap(model.snapshot?.journey.active).paused)
        XCTAssertEqual(probe.shared, sharedBefore)
        XCTAssertEqual(probe.reloads, reloadBefore)
    }

    // 깨짐: 읽기실패를0으로게시하거나 retry복원성공후게시하지않는다.
    func testW18_원본읽기실패는_0공유본을_게시하지않는다() throws {
        let probe = WidgetAppProbe()
        probe.shared = Data("previous-share".utf8)
        probe.readFails = true
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        model.loadIfNeeded()
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shared, Data("previous-share".utf8))
        XCTAssertEqual(probe.shareAttempts, 0)
        XCTAssertEqual(probe.reloads, 0)
        probe.readFails = false
        model.retryLoad()
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: migration저장실패후foreground가미확정이전결과를게시한다.
    func testW18_마이그레이션실패는_foreground도_미게시하고_후속저장성공으로_복구한다() throws {
        let probe = WidgetAppProbe()
        probe.localFails = true
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, legacy: W16bFixtures.legacyData(version: 4))
        model.start()
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shareAttempts, 0)
        probe.localFails = false
        XCTAssertTrue(model.confirmInitialStation(try F.initialOption()))
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 자정foreground때원본을다시저장하거나공유기준일을갱신하지않는다.
    func testW18_foreground자정갱신은_원본추가저장없이_새기준을_게시한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        model.loadIfNeeded()
        let originalWrites = probe.writes
        probe.now = WidgetFixtures.date("2026-10-17T00:00:00Z")
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.writes, originalWrites)
        XCTAssertEqual(probe.sharedWrites, 2)
        guard case .valid(let value) = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared)) else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(value.basisDay, "2026-10-17")
    }
    private func cleanupStore(failBackup: Bool) throws -> LocalSnapshotStore {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("w18-cleanup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("app-state.json")
        try Data("{broken".utf8).write(to: file)
        return LocalSnapshotStore(fileURL: file, writeBackup: { bytes, url in
            if failBackup { throw WidgetDataIssue.writeFailed }
            try bytes.write(to: url, options: .atomic)
        })
    }

    // 깨짐: 원본정리성공후에도이전공유값을유지하거나정상빈설정상태를게시하지않는다.
    func testW18_복구정리성공은_확정empty원본을_게시한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, overrideStore: cleanupStore(failBackup: false))
        model.loadIfNeeded()
        model.requestCleanup()
        XCTAssertTrue(model.confirmCleanup())
        XCTAssertEqual(probe.sharedWrites, 1)
        guard case .valid(let result) = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared)) else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(result.journey.phase, .setup)
        XCTAssertEqual(result.analytics.weekMinutes, 0)
        XCTAssertEqual(result.analytics.weekCount, 0)
    }

    // 호환회귀. 깨짐: 실패한정리후보empty를게시하여이전공유본을덮는다.
    func testW18_복구정리실패는_이전공유본을_보존한다() throws {
        let probe = WidgetAppProbe()
        probe.shared = Data("previous-share".utf8)
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, overrideStore: cleanupStore(failBackup: true))
        model.loadIfNeeded()
        model.requestCleanup()
        XCTAssertFalse(model.confirmCleanup())
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shared, Data("previous-share".utf8))
        XCTAssertEqual(probe.shareAttempts, 0)
        XCTAssertEqual(probe.reloads, 0)
    }

    // 깨짐: supplementCard의직접save성공을공유성공경계에서빠뜨린다.
    func testW18_기존발급상태의_카드보충성공도_저장뒤_게시한다() throws {
        let probe = WidgetAppProbe()
        let station = StationSnapshot(id: "seongsu", name: "성수역")
        let source = XCTestCase.stage(true, station, station)
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.start()
        XCTAssertEqual(model.snapshot?.cards.items.count, 1)
        XCTAssertEqual(probe.writes, 1)
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
        XCTAssertEqual(Array(probe.events.suffix(3)), ["local", "share", "reload"])
    }

}
