import Foundation
import XCTest
@testable import FocusMate

/// 승차권 진입·승차 저장·전환·출발 확인·메인에서 새 여행 모델 동작 (T3).
final class BoardingModelTests: XCTestCase {
    private typealias F = BoardingFixtures
    private enum ProbeError: Error { case expected }

    private final class Probe {
        var writes: [Data] = []
        var shouldFail = false
    }

    private static let fixedBoardedAt = Date(timeIntervalSince1970: 1_791_882_000)

    @MainActor
    private func makeModel(active: JourneySnapshot?, probe: Probe, newID: String = "new-journey") throws -> AppModel {
        let bytes = try SnapshotCodec.encode(F.snapshot(active: active))
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in
                if probe.shouldFail { throw ProbeError.expected }
                probe.writes.append(data)
            }
        )
        let factory = ActiveJourneyFactory(makeID: { newID }, now: { Self.fixedBoardedAt })
        let model = AppModel(store: store, journeyFactory: factory)
        model.loadIfNeeded()
        XCTAssertEqual(model.launchState, .ready(.main))
        return model
    }

    /// 시간·버스·태그·할 일을 채우고 준비를 확정하기 직전(준비 화면)까지 만든다.
    @MainActor
    private func fillPreparation(_ model: AppModel) {
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        _ = model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
        XCTAssertTrue(model.proceedToPreparation())
        XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
        model.preparation.setTask("책 읽기")
    }

    @MainActor
    private func boardingModel(active: JourneySnapshot? = nil, probe: Probe) throws -> AppModel {
        let model = try makeModel(active: active, probe: probe)
        fillPreparation(model)
        XCTAssertTrue(model.showBoardingPass())
        XCTAssertTrue(model.openBoarding())
        return model
    }

    private func lastSaved(_ probe: Probe) throws -> AppSnapshot {
        try SnapshotCodec.decode(try XCTUnwrap(probe.writes.last))
    }

    // MARK: AC-1

    // 깨짐: showBoardingPass가 .board를 열지 않거나, 열면서 active를 만들거나 저장하면 실패.
    @MainActor
    func testAC1_준비가_완성되면_승차권으로_가고_진행여정과_기록과_쓰기는_0이다() throws {
        let probe = Probe()
        let model = try makeModel(active: nil, probe: probe)
        fillPreparation(model)

        XCTAssertTrue(model.showBoardingPass())

        XCTAssertEqual(model.path, [.time, .preparation, .board])
        XCTAssertNil(model.activeJourney)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: 연타 가드가 없으면 .board가 2번 쌓여 실패.
    @MainActor
    func testAC1_승차권_진입을_연타해도_board는_한번만_쌓인다() throws {
        let model = try makeModel(active: nil, probe: Probe())
        fillPreparation(model)

        model.showBoardingPass()
        model.showBoardingPass()
        model.showBoardingPass()

        XCTAssertEqual(model.path.filter { $0 == .board }.count, 1)
    }

    // MARK: AC-2

    // 깨짐: 미완성인데 true를 반환하거나 경로를 바꾸면 실패.
    @MainActor
    func testAC2_준비가_미완성이면_false이고_경로가_그대로다() throws {
        let probe = Probe()
        let model = try makeModel(active: nil, probe: probe)
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        _ = model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
        XCTAssertTrue(model.proceedToPreparation())
        let before = model.path

        XCTAssertFalse(model.showBoardingPass())

        XCTAssertEqual(model.path, before)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: open의 가드가 없으면 확정 준비 없이도 .board/.boarding이 열려 실패.
    @MainActor
    func testAC2_확정된_준비가_없으면_open으로도_승차권과_승차태그가_열리지_않는다() throws {
        let model = try makeModel(active: nil, probe: Probe())

        model.open(.board)
        model.open(.boarding)

        XCTAssertEqual(model.path, [])
    }

    // MARK: AC-4

    // 깨짐: openBoarding이 .boarding을 열지 않거나 active를 만들거나 저장하면 실패.
    @MainActor
    func testAC4_승차권에서_승차태그를_열어도_진행여정은_없고_쓰기는_0이다() throws {
        let probe = Probe()
        let model = try makeModel(active: nil, probe: probe)
        fillPreparation(model)
        XCTAssertTrue(model.showBoardingPass())

        XCTAssertTrue(model.openBoarding())

        XCTAssertEqual(model.path.last, .boarding)
        XCTAssertNil(model.activeJourney)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // 깨짐: path.last가 .board가 아닌데도 openBoarding이 열리면 실패.
    @MainActor
    func testAC4_승차권_화면이_아니면_승차태그는_열리지_않는다() throws {
        let model = try makeModel(active: nil, probe: Probe())
        fillPreparation(model)
        XCTAssertTrue(model.confirmPreparation())
        let before = model.path

        XCTAssertFalse(model.openBoarding())

        XCTAssertEqual(model.path, before)
    }

    // MARK: AC-11

    // 깨짐: 저장 건수가 1이 아니거나 내용이 확정 준비와 다르면 실패.
    @MainActor
    func testAC11_승차하면_확정한_준비_내용으로_한건_저장한다() throws {
        let probe = Probe()
        let model = try boardingModel(probe: probe)

        XCTAssertTrue(model.boardJourney())

        XCTAssertEqual(probe.writes.count, 1)
        let active = try XCTUnwrap(try lastSaved(probe).journey.active)
        XCTAssertEqual(active.id, "new-journey")
        XCTAssertEqual(active.cardID, F.cardID)
        XCTAssertEqual(active.task, "책 읽기")
        XCTAssertEqual(active.minutes, 60)
        XCTAssertEqual(active.busID, "2014")
        XCTAssertEqual(active.tag.name, "독서")
        XCTAssertEqual(active.phase, .awaitingDeparture)
        XCTAssertEqual(active.progress.elapsedSeconds, 0)
        XCTAssertEqual(model.activeJourney, active)
    }

    // 깨짐: persist가 승차 저장 뒤 path를 비우면 실패.
    @MainActor
    func testAC11_승차_저장_뒤에도_경로가_비워지지_않는다() throws {
        let model = try boardingModel(probe: Probe())

        XCTAssertTrue(model.boardJourney())

        XCTAssertEqual(model.path.last, .boarding)
        XCTAssertEqual(model.launchState, .ready(.main))
    }

    // MARK: AC-13

    // 깨짐: 전환이 path를 [.journey]로 교체하지 않으면 실패.
    @MainActor
    func testAC13_승차_후_전환을_마치면_경로는_여행_하나뿐이다() throws {
        let model = try boardingModel(probe: Probe())
        XCTAssertTrue(model.boardJourney())

        model.finishBoardingTransition()

        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: path.last가 .boarding이 아닌데도 전환하면 실패.
    @MainActor
    func testAC13_승차태그_화면이_아니면_전환은_무시된다() throws {
        let model = try makeModel(active: F.journey(), probe: Probe())
        model.open(.time)

        model.finishBoardingTransition()

        XCTAssertEqual(model.path, [.time])
    }

    // 깨짐: active가 없는데 전환해 빈 여행 화면으로 가면 실패.
    @MainActor
    func testAC13_진행여정이_없으면_승차태그에서도_전환되지_않는다() throws {
        let model = try makeModel(active: nil, probe: Probe())
        fillPreparation(model)
        XCTAssertTrue(model.showBoardingPass())
        XCTAssertTrue(model.openBoarding())

        model.finishBoardingTransition()

        XCTAssertEqual(model.path.last, .boarding)
    }

    // MARK: AC-20

    // 깨짐: 출발 확인이 phase를 departed로 저장하지 않거나 진도를 올리면 실패.
    @MainActor
    func testAC20_출발을_확인하면_departed로_저장되고_진도는_0이다() throws {
        let probe = Probe()
        let model = try boardingModel(probe: probe)
        XCTAssertTrue(model.boardJourney())

        XCTAssertTrue(model.confirmDeparture())

        let active = try XCTUnwrap(try lastSaved(probe).journey.active)
        XCTAssertEqual(active.phase, .departed)
        XCTAssertEqual(active.progress.elapsedSeconds, 0)
        XCTAssertEqual(probe.writes.count, 2)
    }

    // 깨짐: 이미 departed인데 다시 쓰거나 false를 반환하면 실패.
    @MainActor
    func testAC20_이미_출발한_여정의_출발확인은_쓰기없이_true다() throws {
        let probe = Probe()
        let model = try makeModel(active: F.journey(phase: .departed, elapsedSeconds: 30), probe: probe)

        XCTAssertTrue(model.confirmDeparture())

        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.activeJourney?.progress.elapsedSeconds, 30)
    }

    // MARK: AC-21

    // 깨짐: 저장 실패 때 snapshot(기존 active 포함)을 바꾸거나 saveFailure를 안 남기면 실패.
    @MainActor
    func testAC21_저장이_실패하면_기존_진행여정을_그대로_두고_실패를_기록한다() throws {
        let probe = Probe()
        let old = F.journey(id: "old-journey")
        let model = try boardingModel(active: old, probe: probe)
        probe.shouldFail = true

        XCTAssertFalse(model.boardJourney())

        XCTAssertEqual(model.activeJourney, old)
        XCTAssertEqual(model.saveFailure, .writeFailed)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // MARK: AC-25

    // 깨짐: 기존 active A를 B로 교체하지 않고 둘 다 두거나 A를 유지하면 실패.
    @MainActor
    func testAC25_진행여정_A가_있어도_승차하면_B로_교체되어_한건만_남는다() throws {
        let probe = Probe()
        let model = try boardingModel(active: F.journey(id: "journey-A", task: "옛 일"), probe: probe)

        XCTAssertTrue(model.boardJourney())

        XCTAssertEqual(probe.writes.count, 1)
        let active = try XCTUnwrap(try lastSaved(probe).journey.active)
        XCTAssertEqual(active.id, "new-journey")
        XCTAssertEqual(active.task, "책 읽기")
        XCTAssertEqual(model.activeJourney?.id, "new-journey")
    }

    // MARK: AC-26

    // 깨짐: board와 boarding이 각각 쌓이지 않거나 뒤로가기가 한 번에 두 단계를 건너뛰면 실패.
    @MainActor
    func testAC26_승차태그에서_뒤로가기_두번이면_준비_화면이다() throws {
        let model = try makeModel(active: nil, probe: Probe())
        fillPreparation(model)
        XCTAssertTrue(model.showBoardingPass())
        XCTAssertTrue(model.openBoarding())
        XCTAssertEqual(model.path.suffix(2), [.board, .boarding])

        model.goBack()
        XCTAssertEqual(model.path.last, .board)
        model.goBack()

        XCTAssertEqual(model.path.last, .preparation)
    }

    // MARK: AC-27

    // 깨짐: 확인 없이 startTripFromMain이 active를 폐기하면 true/쓰기 발생으로 실패.
    @MainActor
    func testAC27_진행여정이_있으면_startTripFromMain은_false이고_쓰기없이_유지한다() throws {
        let probe = Probe()
        let old = F.journey()
        let model = try makeModel(active: old, probe: probe)

        XCTAssertFalse(model.startTripFromMain())

        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.activeJourney, old)
        XCTAssertEqual(model.path, [])
    }

    // 깨짐: 새 여정 확정이 active를 폐기하지 않거나 .time을 열지 않거나 records를 건드리면 실패.
    @MainActor
    func testAC27_새여정_확정이_진행여정을_폐기하고_시간선택을_연다() throws {
        let probe = Probe()
        let model = try makeModel(active: F.journey(), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(model.path.last, .time)
        XCTAssertNil(model.activeJourney)
        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertNil(try lastSaved(probe).journey.active)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐: 폐기 실패인데 .time으로 이동하거나 active를 지우거나 일반 saveFailure를 남기면 실패.
    @MainActor
    func testAC27_새여정_확정이_실패하면_이동하지_않고_진행여정이_남는다() throws {
        let probe = Probe()
        let old = F.journey()
        let model = try makeModel(active: old, probe: probe)
        probe.shouldFail = true

        XCTAssertEqual(model.confirmNewJourney(), .saveFailed)

        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.activeJourney, old)
        XCTAssertNil(model.saveFailure)
    }

    // 깨짐: active가 없는데 저장하면 실패.
    @MainActor
    func testAC27_진행여정이_없으면_쓰기없이_시간선택만_연다() throws {
        let probe = Probe()
        let model = try makeModel(active: nil, probe: probe)

        model.startTripFromMain()

        XCTAssertEqual(model.path.last, .time)
        XCTAssertEqual(probe.writes.count, 0)
    }

    // MARK: 리뷰 R1 — 확정값 저장 (F4)

    // 깨짐: boardJourney 가 확정 시점이 아니라 현재 준비 초안을 다시 읽으면 false/다른 할 일로 저장되어 실패.
    @MainActor
    func testR1_인식_뒤_준비_초안이_바뀌어도_확정_당시_값으로_저장한다() throws {
        let probe = Probe()
        let model = try boardingModel(probe: probe)
        model.preparation.setTask("바뀐 일")

        XCTAssertTrue(model.boardJourney())

        XCTAssertEqual(probe.writes.count, 1)
        let active = try XCTUnwrap(try lastSaved(probe).journey.active)
        XCTAssertEqual(active.task, "책 읽기")
    }

    // 깨짐: 메인에서 새 여행 시작(폐기)으로 확정값이 사라진 뒤에도 승차를 저장하면 실패.
    @MainActor
    func testR1_메인에서_새_여행을_시작한_뒤의_승차는_저장하지_않고_false다() throws {
        let probe = Probe()
        let model = try boardingModel(probe: probe)
        XCTAssertTrue(model.startTripFromMain())
        let writesBefore = probe.writes.count

        XCTAssertFalse(model.boardJourney())

        XCTAssertEqual(probe.writes.count, writesBefore)
        XCTAssertNil(model.activeJourney)
    }

    // MARK: 리뷰 R1 — open(.journey) 가드 (F5)

    // 깨짐: 진행 여정이 없는데 open(.journey)가 빈 여행 화면을 열면 실패.
    @MainActor
    func testR1_진행여정이_없으면_open_journey는_무시된다() throws {
        let model = try makeModel(active: nil, probe: Probe())

        model.open(.journey)

        XCTAssertEqual(model.path, [])
    }

    // 깨짐: 가드가 과해 진행 여정이 있어도 여행 화면이 안 열리면 실패.
    @MainActor
    func testR1_진행여정이_있으면_open_journey가_열린다() throws {
        let model = try makeModel(active: F.journey(), probe: Probe())

        model.open(.journey)

        XCTAssertEqual(model.path, [.journey])
    }

    // MARK: 출발 후 확정값 정리 (T4)

    // 깨짐: confirmDeparture 성공 뒤에도 확정 준비가 남아 있으면 실패.
    @MainActor
    func testT4_출발을_확인하면_확정한_준비값이_정리된다() throws {
        let model = try boardingModel(probe: Probe())
        XCTAssertTrue(model.boardJourney())
        XCTAssertNotNil(model.confirmedPreparation)

        XCTAssertTrue(model.confirmDeparture())

        XCTAssertNil(model.confirmedPreparation)
    }

    // 깨짐: 출발 확인 뒤 같은 확정값으로 다시 승차하면(가드·정리 없음) true가 되어 실패.
    @MainActor
    func testAC18_출발한_뒤에는_다시_승차할_수_없고_여정이_그대로다() throws {
        let probe = Probe()
        let model = try boardingModel(probe: probe)
        XCTAssertTrue(model.boardJourney())
        XCTAssertTrue(model.confirmDeparture())
        let departedJourney = model.activeJourney
        let writesBefore = probe.writes.count

        XCTAssertFalse(model.boardJourney())

        XCTAssertEqual(model.activeJourney, departedJourney)
        XCTAssertEqual(probe.writes.count, writesBefore)
    }

    // 회귀 보호(현재 통과): awaiting 상태 재승차는 새 id로 교체되어야 한다. 가드가 과해지면 실패.
    @MainActor
    func testAC19_시작_전_대기상태에서는_다시_승차하면_새_id로_교체된다() throws {
        let probe = Probe()
        let model = try boardingModel(active: F.journey(id: "journey-A"), probe: probe)

        XCTAssertTrue(model.boardJourney())

        XCTAssertEqual(model.activeJourney?.id, "new-journey")
        XCTAssertEqual(model.activeJourney?.phase, .awaitingDeparture)
    }

    // MARK: 메인 버튼 라벨

    // 깨짐: mainMenuTitle이 준비 항목을 "여행 준비" 그대로 두거나 다른 항목 title을 바꾸면 실패.
    func test메인_메뉴_라벨은_준비만_여행_시작하기이고_나머지는_제목이다() {
        XCTAssertEqual(Destination.preparation.mainMenuTitle, "여행 시작하기")
        XCTAssertEqual(Destination.records.mainMenuTitle, Destination.records.title)
        XCTAssertEqual(Destination.board.title, "승차권")
        XCTAssertEqual(Destination.boarding.title, "승차 태그")
        XCTAssertEqual(Destination.journey.title, "여행")
    }
}
