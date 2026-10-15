import Foundation
import XCTest
@testable import FocusMate

/// 이어가기·새 여정·포기 모델 동작 (T4). 현재 정류장은 출발지 성수역(1), 완료 기록 1건 포함.
final class JourneyLifecycleModelTests: XCTestCase {
    private typealias F = BoardingFixtures

    private static let station = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)

    private func active(elapsed: Int, paused: Bool = true, phase: JourneySnapshot.Phase = .departed) -> JourneySnapshot {
        F.journey(
            minutes: 25, destinationStopID: "seoulForestGate",
            phase: phase, elapsedSeconds: elapsed, paused: paused
        )
    }

    private func appSnapshot(active: JourneySnapshot?) -> AppSnapshot {
        let record = RecordSnapshot(
            id: "seed-record-1", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", bus: "버스2014",
            tag: "독서", tagColor: "#12ABef", task: "책 한 챕터 읽기", minutes: 25, sound: "빗소리",
            from: "성수역", to: "서울숲 입구", memo: ""
        )
        return XCTestCase.stage(true, Self.station, Self.station)
            .issuingCard(CardSnapshot(id: F.cardID, issuedAt: F.boardedAt))
            .updating(records: RecordSection(items: [record]))
            .updating(journey: JourneySection(active: active))
    }

    @MainActor
    private func makeModel(active: JourneySnapshot?, probe: LifecycleProbe) throws -> AppModel {
        let bytes = try SnapshotCodec.encode(appSnapshot(active: active))
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in try probe.record(data) }
        )
        let factory = ActiveJourneyFactory(makeID: { "new-journey" }, now: { F.boardedAt })
        let model = AppModel(store: store, journeyFactory: factory)
        model.loadIfNeeded()
        XCTAssertEqual(model.launchState, .ready(.main))
        return model
    }

    /// 포기 진입 상태: 저장된 일시정지 여정이 있고 타이머 화면이 열려 있다.
    @MainActor
    private func timerOpen(elapsed: Int, probe: LifecycleProbe) throws -> AppModel {
        let model = try makeModel(active: active(elapsed: elapsed), probe: probe)
        model.open(.journey)
        XCTAssertEqual(model.path, [.journey])
        return model
    }

    private func lastSaved(_ probe: LifecycleProbe) throws -> AppSnapshot {
        try SnapshotCodec.decode(try XCTUnwrap(probe.writes.last))
    }

    // MARK: 이어가기 (AC-4, 5, 35, 23, 24)

    // 깨짐: 저장 경과를 바꾸거나 paused를 true로 두거나 path를 안 열면 실패.
    @MainActor
    func testAC4_이어가기는_경과_90_paused_false를_한번_저장하고_타이머를_연다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)

        XCTAssertEqual(model.resumeJourney(), .done)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 1)
        let saved = try XCTUnwrap(try lastSaved(probe).journey.active)
        XCTAssertEqual(saved.progress.elapsedSeconds, 90)
        XCTAssertFalse(saved.paused)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: 이어가기가 완료 기록을 만들거나 지우면 실패.
    @MainActor
    func testAC31_이어가기는_완료기록_수를_바꾸지_않는다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)

        model.resumeJourney()

        XCTAssertEqual(try lastSaved(probe).records.items.count, 1)
        XCTAssertEqual(model.snapshot?.records.items.count, 1)
    }

    // 깨짐: path 가드가 없으면 두 번째도 저장해 attempts 2, .done이 된다.
    @MainActor
    func testAC5_이어가기_연타의_두번째는_rejected이고_시도는_1회다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)

        XCTAssertEqual(model.resumeJourney(), .done)
        XCTAssertEqual(model.resumeJourney(), .rejected)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: 첫 호출 전에도 true거나 두 번째 호출도 true면 실패.
    @MainActor
    func testR_consumeResumeEntry는_이어가기_성공_후_처음만_true다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)
        XCTAssertFalse(model.consumeResumeEntry(journeyID: "journey-1"))

        model.resumeJourney()

        XCTAssertTrue(model.consumeResumeEntry(journeyID: "journey-1"))
        XCTAssertFalse(model.consumeResumeEntry(journeyID: "journey-1"))
    }

    // 깨짐: 실패를 .done으로 보고하거나 이동하거나 저장값/신호를 바꾸거나 일반 saveFailure를 남기면 실패.
    @MainActor
    func testAC35_이어가기_저장실패는_saveFailed이고_이동과_저장값과_신호가_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)
        probe.shouldFail = true

        XCTAssertEqual(model.resumeJourney(), .saveFailed)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.activeJourney?.progress.elapsedSeconds, 90)
        XCTAssertEqual(model.activeJourney?.paused, true)
        XCTAssertFalse(model.consumeResumeEntry(journeyID: "journey-1"))
        XCTAssertNil(model.saveFailure)
    }

    // 깨짐: 실패 후 재시도가 막히거나 결과가 AC-4와 다르면 실패.
    @MainActor
    func testAC35_이어가기_실패_뒤_재시도하면_성공한다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 90), probe: probe)
        probe.shouldFail = true
        model.resumeJourney()
        probe.shouldFail = false

        XCTAssertEqual(model.resumeJourney(), .done)

        XCTAssertEqual(probe.attempts, 2)
        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: 출발 대기 여정에 저장하면 attempts가 1이 되고, 화면을 안 열면 path가 달라 실패.
    @MainActor
    func testAC23_출발대기_여정의_이어가기는_쓰기없이_타이머_화면을_연다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 0, paused: false, phase: .awaitingDeparture), probe: probe)

        XCTAssertEqual(model.resumeJourney(), .done)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: 도착 여정에서 이어가기를 허용하면 .done/쓰기 발생으로 실패.
    @MainActor
    func testAC24_도착_여정의_이어가기는_rejected이고_쓰기가_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 1500), probe: probe)

        XCTAssertEqual(model.resumeJourney(), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [])
    }

    // MARK: 새 여정 (AC-8, 10, 11, 12, 23, 24)

    // 깨짐: 현재 정류장을 도달 정류장으로 바꾸지 않거나 active를 안 지우거나 쓰기가 2회거나 .time을 안 열면 실패.
    @MainActor
    func testAC8_새여정_확정은_도달정류장_저장_여정삭제_시간선택_이동을_한번에_한다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 600), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.currentStation, StationSnapshot(id: "ttukseom", name: "뚝섬역", direction: 1))
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.records.items.count, 1)
        XCTAssertEqual(model.path, [.time])
        XCTAssertNil(model.activeJourney)
    }

    // 깨짐: 실패를 .done으로 보고하거나 상태를 바꾸거나 일반 saveFailure를 남기면 실패.
    @MainActor
    func testAC10_새여정_저장실패는_saveFailed이고_상태가_불변이다() throws {
        let probe = LifecycleProbe()
        let old = active(elapsed: 600)
        let model = try makeModel(active: old, probe: probe)
        let before = model.snapshot
        probe.shouldFail = true

        XCTAssertEqual(model.confirmNewJourney(), .saveFailed)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.snapshot, before)
        XCTAssertEqual(model.activeJourney, old)
        XCTAssertNil(model.saveFailure)
    }

    // 깨짐: 실패 후 재시도가 막히면 실패.
    @MainActor
    func testAC10_새여정_실패_뒤_재시도하면_AC8_결과가_된다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 600), probe: probe)
        probe.shouldFail = true
        model.confirmNewJourney()
        probe.shouldFail = false

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(probe.attempts, 2)
        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertEqual(try lastSaved(probe).currentStation?.id, "ttukseom")
        XCTAssertEqual(model.path, [.time])
    }

    // 깨짐: 연타 가드가 없으면 .time이 두 번 쌓이거나 두 번째가 .done이 된다.
    @MainActor
    func testAC11_새여정_연타의_두번째는_rejected이고_time은_한번만_쌓인다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 600), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)
        XCTAssertEqual(model.confirmNewJourney(), .rejected)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(model.path, [.time])
    }

    // 깨짐: 진행 여정 없이 startTripFromMain이 저장하거나 .time으로 안 가면 실패.
    @MainActor
    func testAC12_진행여정이_없으면_startTripFromMain은_쓰기없이_time으로_간다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: nil, probe: probe)

        XCTAssertTrue(model.startTripFromMain())

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [.time])
    }

    // 깨짐: 확인 없이 폐기하는 옛 동작이면 true/쓰기 발생으로 실패.
    @MainActor
    func testAC12_진행여정이_있으면_startTripFromMain은_false이고_쓰기없이_유지한다() throws {
        let probe = LifecycleProbe()
        let old = active(elapsed: 600)
        let model = try makeModel(active: old, probe: probe)

        XCTAssertFalse(model.startTripFromMain())

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.activeJourney, old)
        XCTAssertEqual(model.path, [])
    }

    // 깨짐: 출발 대기에서 정류장이 바뀌거나 여정이 안 지워지면 실패.
    @MainActor
    func testAC23_출발대기_새여정_확정은_출발정류장_그대로_여정삭제_시간선택이다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 0, paused: false, phase: .awaitingDeparture), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.currentStation, Self.station)
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(model.path, [.time])
    }

    // 깨짐: 도착 여정이 출발 정류장을 유지하거나 식으로 계산하면 실패.
    @MainActor
    func testAC24_도착_여정의_새여정_확정은_도착지가_현재정류장이다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 1500), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.currentStation, StationSnapshot(id: "seoulForestGate", name: "서울숲 입구", direction: 1))
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.records.items.count, 1)
    }

    // 깨짐: 여정이 없을 때 확정이 .done이거나 쓰기를 하면 실패.
    @MainActor
    func testAC31_진행여정이_없으면_새여정_확정은_rejected이고_쓰기가_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: nil, probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [])
    }

    // MARK: mainStartTitle

    // 깨짐: active 유무를 안 보면 문구가 같아 실패.
    @MainActor
    func testFR3_진행여정이_있으면_시작_버튼_문구는_새_여정_시작이다() throws {
        let model = try makeModel(active: active(elapsed: 90), probe: LifecycleProbe())

        XCTAssertEqual(model.mainStartTitle, "새 여정 시작")
    }

    // 깨짐: 없을 때도 "새 여정 시작"이면 실패.
    @MainActor
    func testFR3_진행여정이_없으면_시작_버튼_문구는_기존_메인_문구다() throws {
        let model = try makeModel(active: nil, probe: LifecycleProbe())

        XCTAssertEqual(model.mainStartTitle, "여행 시작하기")
    }

    // MARK: 포기 (AC-16, 17, 19, 20, BR-6, BR-10)

    // 깨짐: 도달 정류장이 아닌 곳을 저장하거나, path/notice/쓰기 횟수가 다르면 실패.
    @MainActor
    func testAC16_포기_확정은_도달정류장_저장_여정삭제_메인이동_안내를_한번에_한다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.currentStation, StationSnapshot(id: "ttukseom", name: "뚝섬역", direction: 1))
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.records.items.count, 1)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.abandonNotice, "뚝섬역")
        XCTAssertNil(model.activeJourney)
    }

    // 깨짐: 0초에서 정류장을 이동시키면 실패.
    @MainActor
    func testAC19_0초_포기는_성수역_그대로다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 0, probe: probe)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)

        XCTAssertEqual(try lastSaved(probe).currentStation, Self.station)
        XCTAssertEqual(model.abandonNotice, "성수역")
        XCTAssertNil(model.activeJourney)
    }

    // 깨짐: 실패를 .done으로 보고하거나 path/상태를 바꾸거나 일반 saveFailure를 남기면 실패.
    @MainActor
    func testAC20_포기_저장실패는_saveFailed이고_타이머_화면과_상태가_불변이다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)
        let before = model.snapshot
        probe.shouldFail = true

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .saveFailed)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.path, [.journey])
        XCTAssertEqual(model.snapshot, before)
        XCTAssertNil(model.abandonNotice)
        XCTAssertNil(model.saveFailure)
    }

    // 깨짐: 실패 후 재시도가 막히면 실패.
    @MainActor
    func testAC20_포기_실패_뒤_재시도하면_AC16_결과가_된다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)
        probe.shouldFail = true
        model.abandonJourney(timerPaused: true)
        probe.shouldFail = false

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)

        XCTAssertEqual(try lastSaved(probe).currentStation?.id, "ttukseom")
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(model.abandonNotice, "뚝섬역")
    }

    // 깨짐: 호출자가 진행 중이라고 알려도 포기를 허용하면 .done/쓰기 발생으로 실패.
    @MainActor
    func testBR6_타이머가_진행중이면_포기는_rejected이고_쓰기가_없다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)

        XCTAssertEqual(model.abandonJourney(timerPaused: false), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: path 마지막이 .journey인지 안 보면 메인에서도 포기되어 실패.
    @MainActor
    func testBR6_타이머_화면이_아니면_포기는_rejected다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 600), probe: probe)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNotNil(model.activeJourney)
    }

    // 깨짐: 출발 대기 여정을 포기할 수 있으면 실패.
    @MainActor
    func testBR6_출발대기_여정은_포기할_수_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 0, paused: false, phase: .awaitingDeparture), probe: probe)
        model.open(.journey)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .rejected)

        XCTAssertEqual(probe.attempts, 0)
    }

    // 깨짐: 도착 여정을 포기할 수 있으면 실패.
    @MainActor
    func testBR6_도착_여정은_포기할_수_없다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 1500, probe: probe)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: open이 안내를 지우지 않으면 실패.
    @MainActor
    func testBR10_open은_포기_안내를_지운다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)
        model.abandonJourney(timerPaused: true)
        XCTAssertEqual(model.abandonNotice, "뚝섬역")

        model.open(.time)

        XCTAssertNil(model.abandonNotice)
    }

    // 깨짐: beginCardCustomization이 안내를 지우지 않으면 실패.
    @MainActor
    func testBR10_카드_꾸미기_진입은_포기_안내를_지운다() throws {
        let probe = LifecycleProbe()
        let model = try timerOpen(elapsed: 600, probe: probe)
        model.abandonJourney(timerPaused: true)
        XCTAssertEqual(model.abandonNotice, "뚝섬역")

        XCTAssertNotNil(model.beginCardCustomization())

        XCTAssertNil(model.abandonNotice)
    }
}
