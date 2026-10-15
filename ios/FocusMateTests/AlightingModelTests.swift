import Foundation
import XCTest
@testable import FocusMate

/// 하차 태그·요약·기록 저장 모델 동작. 현재 정류장 성수역, 25분 여정(도착지 서울숲 입구, 태그 독서, 할 일 "논문").
/// recordClock은 2026-10-13T09:25:00.500Z / Asia/Seoul로 고정한다.
final class AlightingModelTests: XCTestCase {
    private typealias F = BoardingFixtures

    private static let station = StationSnapshot(id: "seongsu", name: "성수역")
    private static let gate = StationSnapshot(id: "seoulForestGate", name: "서울숲 입구")
    private static let fixedNow = Date(timeIntervalSince1970: 1_791_883_500.5) // 2026-10-13T09:25:00.500Z
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!

    private func active(elapsed: Int = 1500, phase: JourneySnapshot.Phase = .departed) -> JourneySnapshot {
        F.journey(
            minutes: 25, destinationStopID: "seoulForestGate", destinationName: "서울숲 입구", task: "논문",
            phase: phase, elapsedSeconds: elapsed, paused: true
        )
    }

    private func seedRecord(id: String, minutes: Int) -> RecordSnapshot {
        RecordSnapshot(
            id: id, completedAt: "2026-10-12T01:00:00Z", date: "2026-10-12", bus: "버스2014",
            tag: "독서", tagColor: "#12ABef", task: "이전 일", minutes: minutes, sound: "빗소리",
            from: "성수역", to: "서울숲 입구", memo: ""
        )
    }

    @MainActor
    private func makeModel(
        active: JourneySnapshot?, probe: LifecycleProbe, records: [RecordSnapshot] = []
    ) throws -> AppModel {
        let base = XCTestCase.stage(true, Self.station, Self.station)
            .issuingCard(CardSnapshot(id: F.cardID, issuedAt: F.boardedAt))
            .updating(records: RecordSection(items: records))
            .updating(journey: JourneySection(active: active))
        let bytes = try SnapshotCodec.encode(base)
        let localStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in try probe.record(data) }
        )
        let model = AppModel(
            store: localStore,
            journeyFactory: ActiveJourneyFactory(makeID: { "new-journey" }, now: { F.boardedAt }),
            recordClock: RecordClock(now: { Self.fixedNow }, timeZone: { Self.seoul }),
            routeData: BoardingFixtures.readyRouteData()
        )
        model.loadIfNeeded()
        XCTAssertEqual(model.launchState, .ready(.main))
        return model
    }

    /// 도착 저장 상태 -> 하차 태그 화면까지 연다 (쓰기 0).
    @MainActor
    private func atAlightingTag(probe: LifecycleProbe, records: [RecordSnapshot] = []) throws -> AppModel {
        let model = try makeModel(active: active(), probe: probe, records: records)
        XCTAssertEqual(model.beginAlighting(), .done)
        XCTAssertEqual(model.confirmArrival(timerArrived: true), .done)
        XCTAssertEqual(model.path, [.journey, .alighting])
        return model
    }

    /// 하차 성공 -> 요약 화면까지 연다.
    @MainActor
    private func atSummary(probe: LifecycleProbe) throws -> AppModel {
        let model = try atAlightingTag(probe: probe)
        XCTAssertTrue(model.alightJourney())
        XCTAssertTrue(model.finishAlightingTransition())
        XCTAssertEqual(model.path, [.alightingSummary])
        return model
    }

    private func lastSaved(_ probe: LifecycleProbe) throws -> AppSnapshot {
        try SnapshotCodec.decode(try XCTUnwrap(probe.writes.last))
    }

    // MARK: 진입 (beginAlighting, confirmArrival, BR-1)

    // 깨짐: beginAlighting이 path를 [.journey]로 안 만들거나 쓰기/기록을 만들면 실패.
    @MainActor
    func testAC10_도착_여정의_beginAlighting은_쓰기없이_타이머_화면을_연다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(), probe: probe)

        XCTAssertEqual(model.beginAlighting(), .done)

        XCTAssertEqual(model.path, [.journey])
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐: 미도착 여정에서도 beginAlighting이 .done이면 실패.
    @MainActor
    func testAC10_미도착_여정의_beginAlighting은_rejected다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 1499), probe: probe)

        XCTAssertEqual(model.beginAlighting(), .rejected)

        XCTAssertEqual(model.path, [])
        XCTAssertEqual(probe.attempts, 0)
    }

    // 깨짐: confirmArrival이 하차 태그를 안 쌓거나 쓰기/기록을 만들면 실패.
    @MainActor
    func testBR1_confirmArrival은_하차태그를_쌓되_쓰기와_기록이_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(), probe: probe)
        model.beginAlighting()

        XCTAssertEqual(model.confirmArrival(timerArrived: true), .done)

        XCTAssertEqual(model.path, [.journey, .alighting])
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐: 저장본이 미도착(1499초)인데 타이머 신호만 믿으면 .done/path 변경으로 실패.
    @MainActor
    func testconfirmArrival_저장본이_미도착이면_saveFailed이고_쓰기없이_path가_유지된다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(elapsed: 1499), probe: probe)
        model.open(.journey)
        XCTAssertEqual(model.path, [.journey])

        XCTAssertEqual(model.confirmArrival(timerArrived: true), .saveFailed)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.path, [.journey])
    }

    // 깨짐: 중복 호출 가드가 없으면 .alighting이 두 번 쌓이거나 .done이 된다.
    @MainActor
    func testconfirmArrival_두번째_호출은_rejected이고_path는_그대로다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)

        XCTAssertEqual(model.confirmArrival(timerArrived: true), .rejected)

        XCTAssertEqual(model.path, [.journey, .alighting])
    }

    // 깨짐: 타이머가 도착하지 않았다는 신호를 무시하면 .done으로 실패.
    @MainActor
    func testconfirmArrival_timerArrived_false는_rejected다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(), probe: probe)
        model.beginAlighting()

        XCTAssertEqual(model.confirmArrival(timerArrived: false), .rejected)

        XCTAssertEqual(model.path, [.journey])
    }

    // MARK: 하차 저장 (AC-10, 11, 12, 13)

    // 깨짐: 기록 필드·정류장·여정 삭제·요약 값 중 하나라도 틀리거나 쓰기가 2회 이상이면 실패.
    @MainActor
    func testAC10_하차는_기록_1건을_한번에_저장하고_요약을_만든다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)

        XCTAssertTrue(model.alightJourney())

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.records.items.count, 1)
        let record = try XCTUnwrap(saved.records.items.first)
        XCTAssertEqual(record.minutes, 25)
        XCTAssertEqual(record.task, "논문")
        XCTAssertEqual(record.to, "서울숲 입구")
        XCTAssertEqual(record.memo, "")
        XCTAssertEqual(record.date, "2026-10-13")
        XCTAssertEqual(saved.currentStation, Self.gate)
        XCTAssertNil(saved.journey.active)
        XCTAssertNil(model.activeJourney)
        let summary = AlightingSummary(recordID: "journey-1", task: "논문", destinationName: "서울숲 입구", minutes: 25)
        XCTAssertEqual(model.alightingSummary, summary)
        XCTAssertEqual(model.alightingSummary?.minutesText, "25 min")
        XCTAssertEqual(record.id, "journey-1")
    }

    // 깨짐: 재호출이 다시 저장하거나 false를 반환하면 실패 (시도 1회 유지).
    @MainActor
    func testAC11_하차_재호출은_쓰기없이_true다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        XCTAssertTrue(model.alightJourney())

        XCTAssertTrue(model.alightJourney())

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertEqual(model.snapshot?.records.items.count, 1)
    }

    // 깨짐: 실패 시 snapshot/path/summary를 먼저 바꾸거나 일반 saveFailure를 남기면 실패.
    @MainActor
    func testAC12_하차_저장실패는_false이고_상태가_불변이며_saveFailure가_없다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        let before = model.snapshot
        probe.shouldFail = true

        XCTAssertFalse(model.alightJourney())

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 0)
        XCTAssertEqual(model.snapshot, before)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
        XCTAssertNotNil(model.activeJourney)
        XCTAssertEqual(model.path, [.journey, .alighting])
        XCTAssertNil(model.alightingSummary)
        XCTAssertNil(model.saveFailure)
    }

    // 깨짐: 실패 뒤 재시도가 막히거나 결과가 AC-10과 다르면 실패.
    @MainActor
    func testAC12_하차_실패_뒤_재시도하면_성공한다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        probe.shouldFail = true
        XCTAssertFalse(model.alightJourney())
        probe.shouldFail = false

        XCTAssertTrue(model.alightJourney())

        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertEqual(model.alightingSummary?.minutes, 25)
    }

    // 깨짐: 요약을 메모리 밖(파일)에 남기면 새 모델에서 summary/path가 복원되어 실패.
    @MainActor
    func testAC13_하차_뒤_새_AppModel은_요약없이_메인에서_시작한다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        XCTAssertTrue(model.alightJourney())
        let savedBytes = try XCTUnwrap(probe.writes.last)
        let reloaded = AppModel(store: LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in savedBytes }, createDirectory: { _ in }, writeData: { _, _ in }
        ))

        reloaded.loadIfNeeded()

        XCTAssertNil(reloaded.alightingSummary)
        XCTAssertEqual(reloaded.path, [])
        XCTAssertEqual(reloaded.snapshot?.records.items.count, 1)
        XCTAssertNil(reloaded.activeJourney)
    }

    // 깨짐: 하차 후에도 진도 저장이 먹혀 여정을 되살리거나 쓰기를 하면 실패.
    @MainActor
    func test위험1_하차_뒤_진도저장은_false이고_쓰기가_추가되지_않는다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        XCTAssertTrue(model.alightJourney())

        XCTAssertFalse(model.saveJourneyProgress(journeyID: "journey-1", elapsedSeconds: 1500, paused: true))

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(probe.writes.count, 1)
    }

    // MARK: 전환·요약 완료 (AC-16, 17, 19, 20)

    // 깨짐: 요약이 없는데 전환하거나, 전환 뒤 path가 [.alightingSummary]가 아니면 실패.
    @MainActor
    func test전환은_요약이_있어야_하고_path를_요약으로_교체한다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(probe: probe)
        XCTAssertFalse(model.finishAlightingTransition())
        XCTAssertEqual(model.path, [.journey, .alighting])

        XCTAssertTrue(model.alightJourney())
        XCTAssertTrue(model.finishAlightingTransition())

        XCTAssertEqual(model.path, [.alightingSummary])
    }

    // 깨짐: 빈 메모에서 쓰기를 하거나 path/summary를 안 비우면 실패.
    @MainActor
    func testAC16_빈_메모로_끝내면_쓰기없이_메인으로_돌아간다() throws {
        let probe = LifecycleProbe()
        let model = try atSummary(probe: probe)

        XCTAssertEqual(model.finishAlightingSummary(memo: ""), .done)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(model.path, [])
        XCTAssertNil(model.alightingSummary)
    }

    // 깨짐: trim 없이 공백 메모를 저장하면 쓰기 2회/메모 "   "로 실패.
    @MainActor
    func testAC19_공백만_있는_메모는_저장하지_않는다() throws {
        let probe = LifecycleProbe()
        let model = try atSummary(probe: probe)

        XCTAssertEqual(model.finishAlightingSummary(memo: "   "), .done)

        XCTAssertEqual(probe.attempts, 1)
        XCTAssertEqual(model.snapshot?.records.items.first?.memo, "")
        XCTAssertEqual(model.path, [])
    }

    // 깨짐: 메모를 저장하지 않거나 엉뚱한 기록에 쓰거나 path/summary를 안 비우면 실패.
    @MainActor
    func testAC17_메모를_입력하면_기록에_저장하고_메인으로_돌아간다() throws {
        let probe = LifecycleProbe()
        let model = try atSummary(probe: probe)

        XCTAssertEqual(model.finishAlightingSummary(memo: "집중 잘됨"), .done)

        XCTAssertEqual(probe.writes.count, 2)
        XCTAssertEqual(try lastSaved(probe).records.items.first?.memo, "집중 잘됨")
        XCTAssertEqual(model.path, [])
        XCTAssertNil(model.alightingSummary)
    }

    // 깨짐: 실패를 .done으로 보고하거나 path·summary를 먼저 비우거나 메모를 메모리에 먼저 반영하면 실패.
    @MainActor
    func testAC20_메모_저장실패는_saveFailed이고_요약화면이_유지된다() throws {
        let probe = LifecycleProbe()
        let model = try atSummary(probe: probe)
        let summary = model.alightingSummary
        probe.shouldFail = true

        XCTAssertEqual(model.finishAlightingSummary(memo: "집중 잘됨"), .saveFailed)

        XCTAssertEqual(model.path, [.alightingSummary])
        XCTAssertEqual(model.alightingSummary, summary)
        XCTAssertNotNil(model.alightingSummary)
        XCTAssertEqual(model.snapshot?.records.items.first?.memo, "")
        XCTAssertNil(model.saveFailure)
    }

    // MARK: 가드 (AC-21)

    // 깨짐: 도착 여정에서 준비·시간·승차 계열 open이 path를 바꾸면 실패.
    @MainActor
    func testAC21_도착_여정이_저장된_상태에서_시작_계열_open은_거부된다() throws {
        let model = try makeModel(active: active(), probe: LifecycleProbe())

        for destination in [Destination.preparation, .time, .board, .boarding] {
            model.open(destination)
            XCTAssertEqual(model.path, [], "\(destination)")
        }
    }

    // 깨짐: open으로 하차 계열 화면을 열 수 있으면 실패.
    @MainActor
    func testAC21_하차_계열은_open으로_열_수_없다() throws {
        let model = try makeModel(active: active(), probe: LifecycleProbe())

        model.open(.alighting)
        XCTAssertEqual(model.path, [])
        model.open(.alightingSummary)
        XCTAssertEqual(model.path, [])
    }

    // 깨짐: 도착 여정의 새 여정 확정이 쓰기를 하거나 .done이면 실패.
    @MainActor
    func testAC21_도착_여정의_새여정_확정은_rejected이고_쓰기가_없다() throws {
        let probe = LifecycleProbe()
        let model = try makeModel(active: active(), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .rejected)

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNotNil(model.activeJourney)
    }

    // 깨짐: 도착 여정인데 메뉴에 준비가 남거나, 도착이 아닌데 준비가 빠지면 실패.
    @MainActor
    func testAC21_도착_여정이면_메뉴에서_준비가_빠진다() throws {
        let arrived = try makeModel(active: active(), probe: LifecycleProbe())
        let moving = try makeModel(active: active(elapsed: 600), probe: LifecycleProbe())
        let none = try makeModel(active: nil, probe: LifecycleProbe())

        XCTAssertEqual(arrived.mainMenuDestinations, [.records, .settings, .profile])
        XCTAssertEqual(moving.mainMenuDestinations, [.preparation, .records, .settings, .profile])
        XCTAssertEqual(none.mainMenuDestinations, [.preparation, .records, .settings, .profile])
    }

    // 깨짐: 하차 태그 화면에서 뒤로가기가 path를 줄이면 실패.
    @MainActor
    func testAC21_하차_태그_화면에서_뒤로가기는_거부된다() throws {
        let model = try atAlightingTag(probe: LifecycleProbe())

        model.goBack()

        XCTAssertEqual(model.path, [.journey, .alighting])
    }

    // 깨짐: 요약 화면에서 뒤로가기가 path를 줄이면 실패.
    @MainActor
    func testAC21_요약_화면에서_뒤로가기는_거부된다() throws {
        let model = try atSummary(probe: LifecycleProbe())

        model.goBack()

        XCTAssertEqual(model.path, [.alightingSummary])
    }

    // MARK: 통계 (AC-32)

    // 깨짐: 하차 기록이 통계에 반영되지 않으면(65분 -> 90분, 2회 -> 3회) 실패.
    @MainActor
    func testAC32_하차_뒤_프로필_통계는_3회_1시간_30분이다() throws {
        let probe = LifecycleProbe()
        let model = try atAlightingTag(
            probe: probe, records: [seedRecord(id: "seed-1", minutes: 40), seedRecord(id: "seed-2", minutes: 25)]
        )
        XCTAssertEqual(model.snapshot?.records.items.count, 2)

        XCTAssertTrue(model.alightJourney())

        XCTAssertEqual(model.profileStats, .loaded(RecordLifetimeSummary(count: 3, minutes: 90)))
        let display = ProfileStatsDisplay(model.profileStats)
        XCTAssertEqual(display.journeysText, "3")
        XCTAssertEqual(display.timeText, "1 h 30 min")
    }
}
