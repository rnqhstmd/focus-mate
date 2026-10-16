import Foundation
import XCTest
@testable import FocusMate

/// 첫 정거장 확정과 여정 준비 진입 모델 동작.
final class JourneyStartModelTests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private final class Probe {
        var writes: [Data] = []
        var shouldFail = false
    }

    private static let seongsuForward = StationSnapshot(id: "seongsu", name: "성수역")

    @MainActor
    private func makeModel(_ snapshot: AppSnapshot, probe: Probe) throws -> AppModel {
        let bytes = try SnapshotCodec.encode(snapshot)
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in
                if probe.shouldFail { throw ProbeError.expected }
                probe.writes.append(data)
            }
        )
        let model = AppModel(store: store, routeData: BoardingFixtures.readyRouteData())
        model.loadIfNeeded()
        return model
    }

    @MainActor
    private func readyModel(_ probe: Probe, station: StationSnapshot? = nil) throws -> AppModel {
        let s = station ?? Self.seongsuForward
        return try makeModel(Self.stage(true, s, s), probe: probe)
    }

    @MainActor
    private func cardOnlyModel(_ probe: Probe) throws -> AppModel {
        try makeModel(Self.stage(true, nil, nil), probe: probe)
    }

    @MainActor
    private func reverseOption() throws -> StopSearchOption {
        guard case let .results(options, _) = StationSearch.search("성수역", in: BoardingFixtures.uiCatalog()) else {
            XCTFail("성수역 검색 결과가 없다")
            throw ProbeError.expected
        }
        return try XCTUnwrap(options.first { $0.id == "seongsu-r" })
    }

    // MARK: confirmInitialStation

    @MainActor
    func test카드만_발급된_상태에서_성수역_역방향_정류장을_확정하면_true와_함께_한번_저장한다() throws {
        let probe = Probe()
        let model = try cardOnlyModel(probe)

        XCTAssertTrue(model.confirmInitialStation(try reverseOption()))

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try SnapshotCodec.decode(try XCTUnwrap(probe.writes.first))
        let expected = StationSnapshot(id: "seongsu-r", name: "성수역")
        XCTAssertEqual(saved.initialStation, expected)
        XCTAssertEqual(saved.currentStation, expected)
        XCTAssertTrue(saved.cardIssued)
        XCTAssertTrue(saved.cards.items.isEmpty)
        XCTAssertNil(saved.journey.active)
        XCTAssertTrue(saved.records.items.isEmpty)
    }

    @MainActor
    func test첫_정거장_확정에_성공하면_메인으로_가고_시간_선택_화면이_열린다() throws {
        let probe = Probe()
        let model = try cardOnlyModel(probe)

        XCTAssertTrue(model.confirmInitialStation(try reverseOption()))

        XCTAssertEqual(model.launchState, .ready(.main))
        XCTAssertEqual(model.path, [.time])
    }

    @MainActor
    func test저장이_실패하면_false를_반환하고_상태와_경로를_유지한다() throws {
        let probe = Probe()
        probe.shouldFail = true
        let model = try cardOnlyModel(probe)

        XCTAssertFalse(model.confirmInitialStation(try reverseOption()))

        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        XCTAssertNil(model.snapshot?.currentStation)
        XCTAssertEqual(model.saveFailure, .writeFailed)
    }

    @MainActor
    func test저장_실패_뒤_재시도가_성공하면_시간_선택으로_가고_실패_표시가_사라진다() throws {
        let probe = Probe()
        probe.shouldFail = true
        let model = try cardOnlyModel(probe)
        let option = try reverseOption()
        XCTAssertFalse(model.confirmInitialStation(option))

        probe.shouldFail = false
        XCTAssertTrue(model.confirmInitialStation(option))

        XCTAssertEqual(model.path, [.time])
        XCTAssertNil(model.saveFailure)
    }

    @MainActor
    func test이미_첫_정거장이_있으면_확정을_거부하고_저장하지_않는다() throws {
        let probe = Probe()
        let model = try readyModel(probe)

        XCTAssertFalse(model.confirmInitialStation(try reverseOption()))

        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.snapshot?.currentStation, Self.seongsuForward)
    }

    // MARK: proceedToPreparation

    @MainActor
    private func selectedModel(_ probe: Probe) throws -> AppModel {
        let model = try readyModel(probe)
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        BoardingFixtures.chooseRoute("2014", in: model)
        return model
    }

    @MainActor
    func test시간과_버스를_고르고_진행하면_준비_화면으로_가고_선택값이_만들어지며_저장하지_않는다() throws {
        let probe = Probe()
        let model = try selectedModel(probe)

        XCTAssertTrue(model.proceedToPreparation())

        XCTAssertEqual(model.path, [.time, .preparation])
        let prepared = try XCTUnwrap(model.preparedJourney)
        XCTAssertEqual(prepared.originStopID, "seongsu")
        XCTAssertEqual(prepared.originName, "성수역")
        XCTAssertEqual(prepared.boundLabel, "성수동 방면")
        XCTAssertEqual(prepared.minutes, 60)
        XCTAssertEqual(prepared.busID, "2014")
        XCTAssertEqual(prepared.busNumber, "2014")
        XCTAssertEqual(prepared.busKind, "지선")
        XCTAssertEqual(prepared.destinationStopID, "seongdongSportsCenter")
        XCTAssertEqual(prepared.destination, "성동구민체육센터")
        XCTAssertEqual(prepared.stops, 12)
        XCTAssertEqual(probe.writes.count, 0)
    }

    @MainActor
    func test진행을_연속으로_눌러도_준비_화면이_중복으로_쌓이지_않는다() throws {
        let probe = Probe()
        let model = try selectedModel(probe)
        XCTAssertTrue(model.proceedToPreparation())

        XCTAssertTrue(model.proceedToPreparation())

        XCTAssertEqual(model.path, [.time, .preparation])
    }

    @MainActor
    func test시간을_고르지_않으면_진행이_차단되고_경로가_그대로다() throws {
        let probe = Probe()
        let model = try readyModel(probe)
        model.open(.time)

        XCTAssertFalse(model.proceedToPreparation())

        XCTAssertEqual(model.path, [.time])
        XCTAssertNil(model.preparedJourney)
    }

    @MainActor
    func test준비_화면에서_뒤로_가면_시간_선택이_남고_선택값이_유지된다() throws {
        let probe = Probe()
        let model = try selectedModel(probe)
        XCTAssertTrue(model.proceedToPreparation())

        model.goBack()

        XCTAssertEqual(model.path, [.time])
        XCTAssertEqual(model.journeyPlan.minutes, 60)
        XCTAssertEqual(model.journeyPlan.selectedRouteID, "2014")
    }

    @MainActor
    func test메인으로_나갔다_시간_선택에_다시_들어와도_선택값이_유지된다() throws {
        let probe = Probe()
        let model = try selectedModel(probe)
        XCTAssertTrue(model.proceedToPreparation())

        model.path = []
        model.open(.time)

        XCTAssertEqual(model.journeyPlan.minutes, 60)
        XCTAssertEqual(model.journeyPlan.selectedRouteID, "2014")
    }

    @MainActor
    func test새_모델의_여정_계획은_기본_25분이고_버스가_선택되지_않았다() throws {
        let model = try readyModel(Probe())

        XCTAssertEqual(model.journeyPlan.minutes, 25)
        XCTAssertNil(model.journeyPlan.selectedRouteID)
    }

    // MARK: 출발 위치

    @MainActor
    func test현재_정류장이_성수역_정방향이면_출발_위치와_후보_버스가_정해진다() throws {
        let model = try readyModel(Probe())

        XCTAssertEqual(model.journeyOrigin?.stopID, "seongsu")
        XCTAssertEqual(model.journeyOrigin?.name, "성수역")
        XCTAssertEqual(model.journeyOrigin?.boundLabel, "성수동 방면")
        XCTAssertEqual(model.journeyCandidates.map(\.routeID), ["2014"])
    }

    @MainActor
    func test현재_역을_카탈로그에서_못_찾으면_출발_위치가_없고_진행할_수_없다() throws {
        let probe = Probe()
        let model = try readyModel(probe, station: StationSnapshot(id: "unknown", name: "어딘가"))
        model.open(.time)

        XCTAssertNil(model.journeyOrigin)
        XCTAssertEqual(model.journeyCandidates, [])
        XCTAssertEqual(model.journeyProceedState, .originUnavailable)
        XCTAssertFalse(model.proceedToPreparation())
        XCTAssertEqual(model.path, [.time])
    }

    // MARK: 메뉴

    func test메인_메뉴_순서와_준비_항목의_이동_대상() {
        XCTAssertEqual(Destination.mainMenu, [.preparation, .records, .settings, .profile])
        XCTAssertEqual(Destination.preparation.mainMenuTarget, .time)
        XCTAssertEqual(Destination.records.mainMenuTarget, .records)
        XCTAssertEqual(Destination.time.title, "시간 선택")
    }
}
