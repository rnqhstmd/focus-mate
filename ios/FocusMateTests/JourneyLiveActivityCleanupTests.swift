import Foundation
import XCTest
@testable import FocusMate

/// 앱 시작 때 저장 상태 기준으로 이전 실행이 남긴 표시를 맞추는 동작을 게이트웨이 결과로 검증한다.
@MainActor
final class JourneyLiveActivityCleanupTests: XCTestCase {
    func endIDs(_ gateway: RecordingLiveActivityGateway) -> [String] {
        gateway.entries.filter { $0.op == .end }.compactMap(\.activityID)
    }

    func updateIDs(_ gateway: RecordingLiveActivityGateway) -> [String] {
        gateway.entries.filter { $0.op == .update }.compactMap(\.activityID)
    }

    // 깨짐: 저장 여행이 없는데 남은 표시를 끝내지 않거나 새로 start/update 하면 실패한다.
    func testV15_AC10_저장된_여행이_없으면_남은_표시를_끝낸다() {
        let gateway = RecordingLiveActivityGateway(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: nil)

        XCTAssertEqual(endIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
    }

    // 깨짐: 도착한 여행의 남은 표시를 끝내지 않거나 2번 끝내거나 update 하면 실패한다.
    func testV15_AC11_저장된_여행이_도착_상태면_남은_표시를_1회_끝낸다() {
        let gateway = RecordingLiveActivityGateway(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 3600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
    }

    // 깨짐: 다른 여행 표시를 안 끝내거나, 같은 여행 표시를 정지 카드(3000초, endDate/staleDate nil)로 갱신하지 않으면 실패한다.
    func testV15_AC32_출발_뒤_진행_중이면_다른_여행은_끝내고_같은_여행은_일시정지로_갱신한다() throws {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "other-1", journeyID: "other-journey")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["other-1"])
        XCTAssertEqual(updateIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        let request = try XCTUnwrap(gateway.entries.first { $0.op == .update }?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 중복 표시를 정리하지 않거나 첫 표시 대신 마지막 표시를 남기면 실패한다.
    func testV15_AC33_같은_여행_표시가_2개면_첫째만_일시정지로_남기고_나머지를_끝낸다() {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "old-2", journeyID: "journey-1")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["old-2"])
        XCTAssertEqual(updateIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.activeActivities.map(\.id), ["old-1"])
    }

    // 깨짐: 남은 표시가 없는데 start/update/end 중 하나라도 보내면 실패한다.
    func testV15_AC34_남은_표시가_없으면_어떤_요청도_보내지_않는다() {
        let gateway = RecordingLiveActivityGateway()
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(gateway.entries.count, 0)
    }

    // 깨짐: 미출발 여행인데 남은 표시를 일부라도 남기거나 start 하면 실패한다.
    func testV15_AC32b_미출발_여행이면_남은_표시를_전부_끝낸다() {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "other-1", journeyID: "other-journey")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .awaitingDeparture)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(Set(endIDs(gateway)), ["old-1", "other-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
        XCTAssertEqual(gateway.activeActivities.count, 0)
    }
}
