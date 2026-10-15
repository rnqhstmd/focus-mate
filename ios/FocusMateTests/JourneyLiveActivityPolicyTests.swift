import Foundation
import XCTest
@testable import FocusMate

/// Live Activity 정책: 속성·요청·appear/launch 계획 (AC-10, 11, 31~34, BR-1, BR-5).
final class JourneyLiveActivityPolicyTests: XCTestCase {
    private typealias F = BoardingFixtures
    private let now = Date(timeIntervalSince1970: 1_791_882_000)

    private func handle(_ id: String, _ journeyID: String) -> LiveActivityHandle {
        LiveActivityHandle(id: id, journeyID: journeyID)
    }

    private func departed(id: String = "j-1", elapsed: Int = 600) -> JourneySnapshot {
        F.journey(id: id, phase: .departed, elapsedSeconds: elapsed)
    }

    // MARK: attributes(for:)

    // 깨짐: journeyID/버스 번호/종류를 잘못 채우면 실패한다.
    func testV15_AC31_저장된_도착지가_계산값과_달라도_저장_이름과_버스를_쓴다() throws {
        let snapshot = F.journey(busID: "421", destinationStopID: "seongsuIntersection", phase: .departed)

        let attrs = try XCTUnwrap(JourneyLiveActivityPolicy.attributes(for: snapshot))

        XCTAssertEqual(attrs.journeyID, "journey-1")
        XCTAssertEqual(attrs.busNumber, "343")
        XCTAssertEqual(attrs.busKind, "간선")
        XCTAssertEqual(attrs.destinationName, snapshot.destinationName)
        XCTAssertNotNil(snapshot.destinationName)
        XCTAssertNotEqual(attrs.destinationName, "성동구민체육센터")
    }

    // 깨짐: 알 수 없는 버스인데도 속성을 만들면 실패한다.
    func testV15_정책_버스를_모르면_속성이_nil이다() {
        XCTAssertNil(JourneyLiveActivityPolicy.attributes(for: F.journey(busID: "gone-bus")))
    }

    // 깨짐: 알 수 없는 도착지인데도 속성을 만들면 실패한다.
    func testV15_정책_도착지를_모르면_속성이_nil이다() {
        XCTAssertNil(JourneyLiveActivityPolicy.attributes(for: F.journey(destinationStopID: "gone-dest")))
    }

    // MARK: request

    // 깨짐: endDate를 now + 남은 초로 계산하지 않거나 staleDate가 endDate와 다르면 실패한다.
    func testV15_정책_진행중_요청은_종료시각과_stale이_같다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .running, remainingSeconds: 3000, now: now))

        XCTAssertEqual(req.state.status, .running)
        XCTAssertEqual(req.state.endDate, Date(timeIntervalSince1970: 1_791_885_000))
        XCTAssertNil(req.state.pausedRemainingSeconds)
        XCTAssertEqual(req.staleDate, Date(timeIntervalSince1970: 1_791_885_000))
    }

    // 깨짐: 일시정지에 endDate/stale을 남기거나 남은 초를 담지 않으면 실패한다.
    func testV15_정책_일시정지_요청은_남은초만_담는다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: 1200, now: now))

        XCTAssertEqual(req.state.status, .paused)
        XCTAssertNil(req.state.endDate)
        XCTAssertEqual(req.state.pausedRemainingSeconds, 1200)
        XCTAssertNil(req.staleDate)
    }

    // 깨짐: 음수 남은 초를 0으로 올리지 않으면 실패한다.
    func testV15_정책_일시정지_음수_남은초는_0이다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: -5, now: now))

        XCTAssertEqual(req.state.pausedRemainingSeconds, 0)
    }

    // 깨짐: 도착 상태에서 요청을 만들면 실패한다.
    func testV15_정책_도착_요청은_nil이다() {
        XCTAssertNil(JourneyLiveActivityPolicy.request(status: .arrived, remainingSeconds: 0, now: now))
    }

    // 깨짐: pausedRequest가 paused 요청과 다르면 실패한다.
    func testV15_정책_pausedRequest는_일시정지_요청과_같다() {
        let expected = JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: 3000, now: now)

        XCTAssertNotNil(expected)
        XCTAssertEqual(JourneyLiveActivityPolicy.pausedRequest(remainingSeconds: 3000), expected)
    }

    // MARK: appearPlan

    // 깨짐: 같은 여정의 첫 handle을 재사용하지 않거나 나머지를 종료하지 않으면 실패한다.
    func testV15_정책_appear는_같은_여정_첫_handle을_재사용하고_나머지를_종료한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(
            existing: [handle("old-1", "j-1"), handle("old-2", "j-1")], journeyID: "j-1"
        )

        XCTAssertEqual(plan.reuseID, "old-1")
        XCTAssertEqual(plan.endIDs, ["old-2"])
    }

    // 깨짐: 다른 여정 handle을 재사용하면 실패한다.
    func testV15_정책_appear는_다른_여정_handle을_종료한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(existing: [handle("x-1", "other")], journeyID: "j-1")

        XCTAssertNil(plan.reuseID)
        XCTAssertEqual(plan.endIDs, ["x-1"])
    }

    // 깨짐: 빈 입력에서 무언가 반환하면 실패한다.
    func testV15_정책_appear는_기존이_없으면_비어_있다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(existing: [], journeyID: "j-1")

        XCTAssertNil(plan.reuseID)
        XCTAssertEqual(plan.endIDs, [])
    }

    // 깨짐: 다른 여정과 같은 여정이 섞일 때 입력 순서를 잃으면 실패한다.
    func testV15_정책_appear는_종료_목록의_입력_순서를_유지한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(
            existing: [handle("a", "other"), handle("b", "j-1"), handle("c", "other"), handle("d", "j-1")],
            journeyID: "j-1"
        )

        XCTAssertEqual(plan.reuseID, "b")
        XCTAssertEqual(plan.endIDs, ["a", "c", "d"])
    }

    // MARK: launchPlan

    // 깨짐: 여정이 없는데 기존 activity를 남기면 실패한다 (AC-10).
    func testV15_AC10_여정이_없으면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1"), handle("b", "j-2")], journey: nil
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a", "b"], pausedUpdate: nil))
    }

    // 깨짐: 출발 전 여정에 activity를 남기면 실패한다 (AC-10).
    func testV15_AC10_출발_전이면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .awaitingDeparture)
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a"], pausedUpdate: nil))
    }

    // 깨짐: 도착한 여정에 activity를 남기면 실패한다 (AC-11).
    func testV15_AC11_도착했으면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: departed(elapsed: 3600)
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a"], pausedUpdate: nil))
    }

    // 깨짐: 같은 여정 첫 handle을 일시정지로 갱신하지 않거나 남은 초(3600-600)를 잘못 계산하면 실패한다 (AC-32).
    func testV15_AC32_출발_미도착이면_첫_handle을_일시정지로_갱신한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [handle("a", "j-1")], journey: departed())

        XCTAssertEqual(plan.endIDs, [])
        XCTAssertEqual(plan.pausedUpdate, JourneyLaunchPlan.PausedUpdate(
            id: "a", request: JourneyLiveActivityPolicy.pausedRequest(remainingSeconds: 3000)
        ))
        XCTAssertEqual(plan.pausedUpdate?.request.state.pausedRemainingSeconds, 3000)
    }

    // 깨짐: 중복 activity와 다른 여정 activity를 종료하지 않으면 실패한다 (AC-33).
    func testV15_AC33_중복과_다른_여정은_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("x", "other"), handle("a", "j-1"), handle("b", "j-1")], journey: departed()
        )

        XCTAssertEqual(plan.endIDs, ["x", "b"])
        XCTAssertEqual(plan.pausedUpdate?.id, "a")
    }

    // 깨짐: 같은 여정 activity가 없는데 갱신을 만들면 실패한다.
    func testV15_정책_같은_여정이_없으면_다른_여정만_종료하고_갱신은_없다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [handle("x", "other")], journey: departed())

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["x"], pausedUpdate: nil))
    }

    // 깨짐: 기존이 없는데 계획이 비어 있지 않으면 실패한다 (AC-34).
    func testV15_AC34_기존이_없으면_계획이_비어_있다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [], journey: departed())

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: [], pausedUpdate: nil))
    }

    // 깨짐: journey.paused 값에 따라 계획이 달라지면 실패한다.
    func testV15_정책_저장된_paused_값은_계획에_영향을_주지_않는다() {
        let running = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .departed, elapsedSeconds: 600, paused: false)
        )
        let paused = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .departed, elapsedSeconds: 600, paused: true)
        )

        XCTAssertEqual(running, paused)
        XCTAssertEqual(running.pausedUpdate?.request.state.pausedRemainingSeconds, 3000)
    }
}
