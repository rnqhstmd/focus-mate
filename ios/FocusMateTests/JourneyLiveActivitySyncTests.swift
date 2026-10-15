import Foundation
import XCTest
@testable import FocusMate

/// 타이머 상태 변화가 Live Activity 게이트웨이 요청으로 정확히 옮겨지는지 검증한다.
@MainActor
final class JourneyLiveActivitySyncTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_791_882_000)

    @MainActor struct Rig {
        let controller: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
        let gateway: RecordingLiveActivityGateway
        let sync: JourneyLiveActivitySync
        let journey: JourneySnapshot
        let base: Date

        /// 시계 현재 시각 (정수 초).
        var currentDate: Date { base.addingTimeInterval(TimeInterval(clock.now.components.seconds)) }
    }

    func makeRig(
        existing: [LiveActivityHandle] = [],
        elapsed: Int = 0,
        paused: Bool = false,
        autoStart: Bool = true,
        results: [Bool] = []
    ) throws -> Rig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver(results: results)
        let gateway = RecordingLiveActivityGateway(existing: existing)
        let journey = BoardingFixtures.journey(
            minutes: 60, busID: "421", busNumber: "343", busKind: "간선", phase: .departed, elapsedSeconds: elapsed, paused: paused
        )
        let start = base
        let sync = try XCTUnwrap(JourneyLiveActivitySync(
            journey: journey, gateway: gateway,
            now: { start.addingTimeInterval(TimeInterval(clock.now.components.seconds)) }
        ))
        let controller = JourneyTimerController(
            journey: journey, autoStart: autoStart, saver: saver, clock: clock,
            ticker: clock, announcer: RecordingAnnouncer(), observer: sync
        )
        return Rig(controller: controller, clock: clock, saver: saver, gateway: gateway,
                   sync: sync, journey: journey, base: start)
    }

    // MARK: AC-1

    // 깨짐: 진입 시 start를 안 하거나 2번 하거나, endDate/staleDate/속성(버스·종류·목적지·journeyID)이 틀리면 실패한다.
    func testV15_AC1_진행_중_진입하면_종료시각이_정해진_실행_카드를_1회_시작한다() throws {
        let rig = try makeRig()
        let t = rig.currentDate

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        let request = try XCTUnwrap(rig.gateway.entries.first?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t.addingTimeInterval(3600))
        XCTAssertEqual(request.staleDate, t.addingTimeInterval(3600))
        let attributes = try XCTUnwrap(rig.gateway.lastStartAttributes)
        XCTAssertEqual(attributes.busNumber, "343")
        XCTAssertEqual(attributes.busKind, "간선")
        XCTAssertEqual(attributes.destinationName, rig.journey.destinationName)
        XCTAssertEqual(attributes.journeyID, rig.journey.id)
    }

    // MARK: AC-2

    // 깨짐: pause에서 update를 안 보내거나, 남은 3000초 대신 다른 값을 쓰거나, endDate/staleDate를 남기면 실패한다.
    func testV15_AC2_일시정지하면_남은초를_담은_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)

        rig.controller.pause()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(rig.gateway.entries.last?.op, .update)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // MARK: AC-4

    // 깨짐: 재개 시 종료 시각을 시작 시점 기준(T+3600)으로 두거나 start를 다시 호출하면 실패한다.
    func testV15_AC4_재개하면_현재_시각_기준으로_종료시각을_다시_계산해_갱신한다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        rig.clock.advance(by: .seconds(300), notify: false)
        let t2 = rig.currentDate

        rig.controller.resume()

        XCTAssertEqual(rig.gateway.count(.update), 2)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t2.addingTimeInterval(3000))
        XCTAssertEqual(request.staleDate, t2.addingTimeInterval(3000))
    }

    // MARK: AC-5

    // 깨짐: 재개 저장이 실패했는데도 게이트웨이에 running 갱신을 보내면 실패한다.
    func testV15_AC5_재개_저장이_실패하면_게이트웨이_요청이_늘지_않는다() throws {
        let rig = try makeRig(results: [true, false])
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        let before = rig.gateway.entries.count

        rig.controller.resume()

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // MARK: AC-6

    // 깨짐: 도착 시 end를 안 보내거나 2번 보내거나, 도착 뒤 start/update가 또 나가면 실패한다.
    func testV15_AC6_도착하면_종료를_1회만_보내고_이후_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()

        rig.clock.advance(by: .seconds(3600))
        XCTAssertEqual(rig.controller.status, .arrived)
        rig.controller.returnToForeground()
        rig.controller.tick()

        XCTAssertEqual(rig.gateway.count(.end), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // MARK: AC-7

    // 깨짐: 이미 도착한 여정 진입에서 start(또는 end/update)를 보내면 실패한다.
    func testV15_AC7_도착_상태로_진입하면_어떤_요청도_보내지_않는다() throws {
        let rig = try makeRig(elapsed: 3600)

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        XCTAssertEqual(rig.gateway.count(.end), 0)
    }

    // MARK: AC-8

    // 깨짐: 일시정지 진입에서 start를 안 하거나 running 카드로 시작하거나 endDate/staleDate를 넣으면 실패한다.
    func testV15_AC8_일시정지_상태로_진입하면_정지_카드를_1회_시작한다() throws {
        let rig = try makeRig(elapsed: 600, paused: true, autoStart: false)

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.first?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // MARK: AC-9

    // 깨짐: 정지 진입 뒤 재개에서 start를 또 하거나 종료 시각을 T3+3000으로 계산하지 않으면 실패한다.
    func testV15_AC9_일시정지로_시작한_뒤_재개하면_start_없이_갱신한다() throws {
        let rig = try makeRig(elapsed: 600, paused: true, autoStart: false)
        rig.controller.appear()
        rig.clock.advance(by: .seconds(120), notify: false)
        let t3 = rig.currentDate

        rig.controller.resume()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t3.addingTimeInterval(3000))
        XCTAssertEqual(request.staleDate, t3.addingTimeInterval(3000))
    }

    // MARK: 이전 실행이 남긴 표시 정리 (AC-11~15)

    // 깨짐: 도착한 여행 화면에서 남은 표시를 안 끝내거나 2번 끝내거나 start/update를 보내면 실패한다.
    func testV15_AC11_도착한_여행_화면에_들어오면_남은_표시를_1회_끝낸다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")], elapsed: 3600
        )

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["old-1"])
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 남은 표시를 재사용하지 않고 start 하거나, 종료 시각을 현재 시각 기준으로 계산하지 않으면 실패한다.
    func testV15_AC12_진행_중_진입하면_남은_표시를_새로_만들지_않고_현재_시각_기준으로_갱신한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )
        rig.clock.advance(by: .seconds(100), notify: false)
        let t4 = rig.currentDate

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t4.addingTimeInterval(TimeInterval(rig.controller.remainingSeconds)))
        XCTAssertEqual(request.staleDate, request.state.endDate)
    }

    // 깨짐: 일시정지 진입에서 남은 표시를 재사용하지 않거나 정지 카드에 endDate/staleDate를 넣으면 실패한다.
    func testV15_AC13_일시정지_진입하면_남은_표시를_정지_카드로_갱신한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")],
            elapsed: 600, paused: true, autoStart: false
        )

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 중복 표시를 정리하지 않거나 첫 표시 대신 마지막 표시를 재사용하면 실패한다.
    func testV15_AC14_같은_여행_표시가_2개면_첫째를_갱신하고_나머지를_끝낸다() throws {
        let rig = try makeRig(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "old-2", journeyID: "journey-1")
        ])

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["old-2"])
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.activeActivities.map(\.id), ["old-1"])
    }

    // 깨짐: 다른 여행의 표시를 안 끝내거나, 현재 여행 표시를 새로 시작하지 않으면 실패한다.
    func testV15_AC15_다른_여행_표시는_끝내고_현재_여행을_새로_시작한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "other-1", journeyID: "other-journey")]
        )

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["other-1"])
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.activeActivities.count, 1)
        XCTAssertEqual(rig.gateway.activeActivities.first?.journeyID, rig.journey.id)
    }

    // MARK: 요청 억제·실패·종료 (AC-3, 16~25)

    func tickSeconds(_ rig: Rig, _ n: Int) {
        for _ in 0..<n { rig.clock.advance(by: .seconds(1), notify: true) }
    }

    // 깨짐: 일시정지 중 복귀·appear를 반복할 때마다 같은 정지 카드를 다시 보내면 실패한다.
    func testV15_AC3_일시정지_뒤_복귀와_appear를_반복해도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        rig.clock.advance(by: .seconds(300), notify: false)
        let before = rig.gateway.entries.count

        for _ in 0..<3 { rig.controller.returnToForeground() }
        for _ in 0..<3 { rig.controller.appear() }

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.controller.remainingSeconds, 3000)
    }

    // 깨짐: start 실패 때 컨트롤러 흐름이 바뀌거나 저장 기록이 달라지거나 오류 표시가 켜지면 실패한다.
    func testV15_AC16_표시_시작이_실패해도_타이머와_저장은_성공_때와_같다() throws {
        func run(failing: Bool) throws -> (Rig, [JourneyTimerController.Status]) {
            let rig = try makeRig()
            rig.gateway.failsStart = failing
            var statuses: [JourneyTimerController.Status] = []
            rig.controller.appear(); statuses.append(rig.controller.status)
            rig.controller.pause(); statuses.append(rig.controller.status)
            rig.controller.resume(); statuses.append(rig.controller.status)
            rig.clock.advance(by: .seconds(3600)); statuses.append(rig.controller.status)
            return (rig, statuses)
        }
        let (failed, failedStatuses) = try run(failing: true)
        let (normal, _) = try run(failing: false)

        XCTAssertEqual(failedStatuses, [.running, .paused, .running, .arrived])
        XCTAssertEqual(failed.saver.writes.map(\.elapsed), normal.saver.writes.map(\.elapsed))
        XCTAssertEqual(failed.saver.writes.map(\.paused), normal.saver.writes.map(\.paused))
        XCTAssertFalse(failed.controller.showsTransitionFailure)
        XCTAssertFalse(failed.controller.showsSaveWarning)
    }

    // 깨짐: start 실패 뒤 update·end나 start 재시도를 보내면 실패한다.
    func testV15_AC17_표시_시작이_실패하면_그_세션에서_더_이상_요청하지_않는다() throws {
        let rig = try makeRig()
        rig.gateway.failsStart = true

        rig.controller.appear()
        rig.controller.pause()
        rig.controller.resume()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(3600))

        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        XCTAssertEqual(rig.gateway.count(.end), 0)
    }

    // 깨짐: 상태 변화 없는 tick·복귀·appear마다 같은 내용의 갱신을 보내면 실패한다.
    func testV15_AC18_상태가_그대로면_tick과_복귀와_appear를_반복해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        let before = rig.gateway.entries.count

        tickSeconds(rig, 10)
        for _ in 0..<3 { rig.controller.returnToForeground() }
        for _ in 0..<3 { rig.controller.appear() }

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 체크포인트 저장 성공마다 갱신을 보내면 실패한다.
    func testV15_AC19_체크포인트_저장이_성공해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()

        tickSeconds(rig, 180)

        XCTAssertGreaterThanOrEqual(rig.saver.writes.count, 3)
        XCTAssertEqual(rig.gateway.entries.count, 1)
    }

    // 깨짐: 저장 실패로 멈춘 뒤 정지 카드 갱신이 없거나 남은 초가 다르거나 endDate/staleDate가 남으면 실패한다.
    func testV15_AC20_체크포인트_저장이_실패해_멈추면_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig(elapsed: 120, results: [false])
        rig.controller.appear()

        var guardCount = 0
        while !rig.controller.showsSaveWarning && guardCount < 200 {
            tickSeconds(rig, 1)
            guardCount += 1
        }

        XCTAssertTrue(rig.controller.showsSaveWarning)
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.gateway.count(.update), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, rig.controller.remainingSeconds)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 백그라운드 진입 저장 성공이 요청을 보내면 실패한다.
    func testV15_AC21_백그라운드_진입_저장이_성공해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        let before = rig.gateway.entries.count

        rig.controller.enterBackground()

        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // 깨짐: running 요청의 staleDate가 endDate와 다르거나 paused 요청에 staleDate가 있으면 실패한다.
    func testV15_AC22_모든_기록에서_running은_staleDate가_endDate이고_paused는_nil이다() throws {
        var rigs: [Rig] = []
        let r1 = try makeRig(); r1.controller.appear(); rigs.append(r1)
        let r4 = try makeRig(); r4.controller.appear()
        r4.clock.advance(by: .seconds(600), notify: false); r4.controller.pause()
        r4.clock.advance(by: .seconds(300), notify: false); r4.controller.resume(); rigs.append(r4)
        let r8 = try makeRig(elapsed: 600, paused: true, autoStart: false); r8.controller.appear(); rigs.append(r8)
        let r12 = try makeRig(existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")])
        r12.clock.advance(by: .seconds(100), notify: false); r12.controller.appear(); rigs.append(r12)
        let r13 = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")],
            elapsed: 600, paused: true, autoStart: false
        ); r13.controller.appear(); rigs.append(r13)
        let r20 = try makeRig(elapsed: 120, results: [false]); r20.controller.appear()
        var n = 0
        while !r20.controller.showsSaveWarning && n < 200 { tickSeconds(r20, 1); n += 1 }
        rigs.append(r20)

        var checked = 0
        for rig in rigs {
            for entry in rig.gateway.entries {
                guard let request = entry.request else { continue }
                checked += 1
                switch request.state.status {
                case .running: XCTAssertEqual(request.staleDate, request.state.endDate)
                case .paused: XCTAssertNil(request.staleDate)
                default: break
                }
            }
        }
        // 깨짐: 기록 수가 9가 아니면(누락·중복) 실패 — r1 1 + r4 3 + r8 1 + r12 1 + r13 1 + r20 2
        XCTAssertEqual(checked, 9)
    }

    // 깨짐: 총 시간 초과 뒤 복귀·appear 반복에서 end를 여러 번 보내거나 안 보내면 실패한다.
    func testV15_AC23_백그라운드_중_총시간을_넘기면_복귀_뒤_end가_총_1회다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.controller.enterBackground()
        rig.clock.armForegroundAdvance(by: .seconds(3700))
        rig.clock.applyArmedForegroundAdvance()

        rig.controller.returnToForeground()
        rig.controller.appear()
        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.count(.end), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 화면을 떠날 때 정지 카드 갱신이 없거나 남은 초(2700)·endDate/staleDate가 틀리거나 end를 보내면 실패한다.
    func testV15_AC24_진행_중_화면을_떠나면_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig(elapsed: 900)
        rig.controller.appear()

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.end), 0)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 2700)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 이미 정지된 상태에서 떠날 때 같은 정지 카드를 또 보내면 실패한다.
    func testV15_AC25a_일시정지_상태에서_떠나도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        let before = rig.gateway.entries.count

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // 깨짐: 도착으로 표시가 끝난 뒤 떠날 때 요청을 더 보내면 실패한다.
    func testV15_AC25b_도착해_표시가_끝난_뒤_떠나도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(3600))
        let before = rig.gateway.entries.count

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.gateway.count(.end), 1)
    }
}
