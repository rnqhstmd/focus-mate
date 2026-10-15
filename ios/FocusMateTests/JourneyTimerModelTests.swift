import Foundation
import XCTest
@testable import FocusMate

/// 진도 저장·재실행 정규화·재승차 차단 모델 동작 (T4). 60분 여정의 total은 3600초.
final class JourneyTimerModelTests: XCTestCase {
    private typealias F = BoardingFixtures
    private enum ProbeError: Error { case expected }

    private final class Probe {
        var writes: [Data] = []
    }

    @MainActor
    private func makeModel(active: JourneySnapshot?, probe: Probe) throws -> AppModel {
        let bytes = try SnapshotCodec.encode(F.snapshot(active: active))
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in probe.writes.append(data) }
        )
        let factory = ActiveJourneyFactory(makeID: { "new-journey" }, now: { F.boardedAt })
        let model = AppModel(store: store, journeyFactory: factory, routeData: BoardingFixtures.readyRouteData())
        model.loadIfNeeded()
        XCTAssertEqual(model.launchState, .ready(.main))
        return model
    }

    @MainActor
    private func fillPreparation(_ model: AppModel) {
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        BoardingFixtures.chooseRoute("2014", in: model)
        XCTAssertTrue(model.proceedToPreparation())
        XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
        model.preparation.setTask("책 읽기")
    }

    private func lastSavedActive(_ probe: Probe) throws -> JourneySnapshot {
        let snapshot = try SnapshotCodec.decode(try XCTUnwrap(probe.writes.last))
        return try XCTUnwrap(snapshot.journey.active)
    }

    private func departed(elapsed: Int = 100, paused: Bool = true) -> JourneySnapshot {
        F.journey(phase: .departed, elapsedSeconds: elapsed, paused: paused)
    }

    // MARK: saveJourneyProgress 가드

    // 깨짐: awaiting 여정에 진도를 쓰도록 허용하면 true/쓰기 발생으로 실패.
    @MainActor
    func testAC1_대기중_여정에는_진도를_저장하지_않고_false다() throws {
        let probe = Probe()
        let model = try makeModel(active: F.journey(), probe: probe)

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 0, paused: false))

        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: id 일치를 확인하지 않으면 다른 여정에 쓰므로 실패.
    @MainActor
    func testAC1_id가_다르면_진도를_저장하지_않고_false다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(), probe: probe)

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "other", elapsedSeconds: 200, paused: false))

        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.activeJourney?.progress.elapsedSeconds, 100)
    }

    // 깨짐: active 없음을 가드하지 않으면 크래시 또는 true.
    @MainActor
    func testAC1_진행여정이_없으면_진도를_저장하지_않고_false다() throws {
        let probe = Probe()
        let model = try makeModel(active: nil, probe: probe)

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 10, paused: true))

        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: 총 시간(3600) 초과를 거부하지 않으면 true이거나 snapshot이 바뀌어 실패.
    @MainActor
    func testAC1_총시간을_넘는_진도는_거부되고_snapshot이_그대로다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(), probe: probe)
        let before = model.snapshot

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 3601, paused: true))

        XCTAssertEqual(model.snapshot, before)
    }

    // 깨짐: 음수 진도를 거부하지 않으면 true이거나 snapshot이 바뀌어 실패.
    @MainActor
    func testAC1_음수_진도는_거부되고_snapshot이_그대로다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(), probe: probe)
        let before = model.snapshot

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: -1, paused: true))

        XCTAssertEqual(model.snapshot, before)
    }

    // MARK: saveJourneyProgress 성공

    // 깨짐: 값이 저장되지 않거나 paused가 반영되지 않거나 records를 건드리면 실패.
    @MainActor
    func testAC31_진도를_저장하면_경과와_paused가_반영되고_기록_수는_그대로다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(elapsed: 100, paused: true), probe: probe)

        XCTAssertTrue(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 250, paused: false))

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSavedActive(probe)
        XCTAssertEqual(saved.progress.elapsedSeconds, 250)
        XCTAssertFalse(saved.paused)
        XCTAssertEqual(model.activeJourney, saved)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐: 같은 값이라 쓰기를 생략하면 쓰기 수가 1로 실패.
    @MainActor
    func testAC1_같은_값을_두번_저장해도_쓰기를_생략하지_않는다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(), probe: probe)

        XCTAssertTrue(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 100, paused: true))
        XCTAssertTrue(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 100, paused: true))

        XCTAssertEqual(probe.writes.count, 2)
    }

    // 깨짐: 도착 저장(total, paused=true)이 기록을 만들면 records 수가 0이 아니라 실패.
    @MainActor
    func testAC13_도착값을_저장해도_기록은_만들지_않는다() throws {
        let probe = Probe()
        let model = try makeModel(active: departed(elapsed: 3000, paused: false), probe: probe)

        XCTAssertTrue(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 3600, paused: true))

        XCTAssertEqual(model.activeJourney?.isArrived, true)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // MARK: hasDepartedJourney

    // 깨짐: phase를 보지 않고 active 존재만 보면 awaiting에서 true.
    @MainActor
    func testAC18_출발한_여정이_있을_때만_hasDepartedJourney가_true다() throws {
        let awaiting = try makeModel(active: F.journey(), probe: Probe())
        let none = try makeModel(active: nil, probe: Probe())
        let departedModel = try makeModel(active: departed(), probe: Probe())

        XCTAssertFalse(awaiting.hasDepartedJourney)
        XCTAssertFalse(none.hasDepartedJourney)
        XCTAssertTrue(departedModel.hasDepartedJourney)
    }

    // MARK: AC-11 / AC-13 로드

    // 깨짐: 로드가 restingForLaunch를 적용하지 않으면 paused가 false로 남아 실패.
    @MainActor
    func testAC11_출발_상태_저장본을_로드하면_메모리에서_paused가_된다() throws {
        let model = try makeModel(active: departed(elapsed: 120, paused: false), probe: Probe())

        XCTAssertEqual(model.activeJourney?.paused, true)
        XCTAssertEqual(model.activeJourney?.progress.elapsedSeconds, 120)
    }

    // 깨짐: 로드 정규화를 파일에 쓰면 쓰기 수가 1이라 실패.
    @MainActor
    func testAC11_로드_정규화는_파일을_쓰지_않는다() throws {
        let probe = Probe()
        _ = try makeModel(active: departed(elapsed: 120, paused: false), probe: probe)

        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: 도착 저장본 복원이 경과를 바꾸거나 기록을 만들면 실패.
    @MainActor
    func testAC13_도착한_저장본을_로드하면_도착_상태이고_기록은_0이다() throws {
        let model = try makeModel(active: departed(elapsed: 3600, paused: true), probe: Probe())

        XCTAssertEqual(model.activeJourney?.isArrived, true)
        XCTAssertEqual(model.activeJourney?.progress.elapsedSeconds, 3600)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // MARK: AC-18 재승차 차단 (모델 단위)

    // 깨짐: departed 가드가 없으면 showBoardingPass가 true가 되어 실패.
    @MainActor
    func testAC18_출발한_여정이_있으면_승차권_진입이_거부되고_여정이_불변이다() throws {
        let probe = Probe()
        let active = departed(elapsed: 100, paused: true)
        let model = try makeModel(active: active, probe: probe)
        fillPreparation(model)

        XCTAssertFalse(model.showBoardingPass())

        XCTAssertEqual(model.activeJourney, active)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: boardJourney에 가드가 없으면 새 여정으로 덮어써 true/쓰기 1로 실패.
    @MainActor
    func testAC18_출발한_여정이_있으면_승차_저장이_거부된다() throws {
        let probe = Probe()
        let active = departed(elapsed: 100, paused: true)
        let model = try makeModel(active: active, probe: probe)
        fillPreparation(model)
        XCTAssertTrue(model.confirmPreparation())

        XCTAssertFalse(model.boardJourney())

        XCTAssertEqual(model.activeJourney, active)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: openBoarding에 가드가 없으면 .boarding이 열려 true로 실패.
    @MainActor
    func testAC18_출발한_여정이_있으면_승차태그_진입이_거부된다() throws {
        let probe = Probe()
        let model = try makeModel(active: F.journey(), probe: probe)
        fillPreparation(model)
        XCTAssertTrue(model.showBoardingPass())
        XCTAssertTrue(model.confirmDeparture())
        let pathBefore = model.path

        XCTAssertFalse(model.openBoarding())

        XCTAssertEqual(model.path, pathBefore)
    }

    // 깨짐: open이 departed에서도 .board/.boarding을 열면 path가 바뀌어 실패.
    @MainActor
    func testAC18_출발한_여정이_있으면_open으로_승차권과_승차태그가_열리지_않는다() throws {
        let model = try makeModel(active: departed(), probe: Probe())
        fillPreparation(model)
        XCTAssertTrue(model.confirmPreparation())
        let pathBefore = model.path

        model.open(.board)
        model.open(.boarding)

        XCTAssertEqual(model.path, pathBefore)
    }

    // 깨짐: goBack 가드가 없으면 여행 화면에서 pop되어 path가 비어 실패.
    @MainActor
    func testAC18_출발한_여정의_여행_화면에서는_뒤로가기가_무시된다() throws {
        let model = try makeModel(active: departed(), probe: Probe())
        model.open(.journey)
        XCTAssertEqual(model.path, [.journey])

        model.goBack()

        XCTAssertEqual(model.path, [.journey])
    }
}
