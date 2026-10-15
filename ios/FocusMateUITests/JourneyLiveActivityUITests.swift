import Foundation
import XCTest

/// Live Activity 요청 기록기 배선 스모크 (UI 테스트 모드에서 test.liveActivity로 노출).
@MainActor
final class JourneyLiveActivityUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func requests(_ h: FocusMateUIHarness) -> [[String: Any]]? {
        guard let raw = h.value("test.liveActivity"),
              let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return root["requests"] as? [[String: Any]]
    }

    private func waitForRequestCount(_ h: FocusMateUIHarness, _ count: Int) -> Bool {
        h.waitUntil(timeout: timeout) { requests(h)?.count == count }
    }

    private func isNil(_ value: Any?) -> Bool {
        value == nil || value is NSNull
    }

    private func number(_ value: Any?) -> Double? {
        (value as? NSNumber)?.doubleValue
    }

    // 깨짐: 화면이 Live Activity 시작을 요청하지 않거나(0건), 앱 시작 정리로 요청이 추가되거나,
    // 일시정지 시작인데 status·남은 시간(1500-90=1410)·endDate/staleDate가 틀린다.
    // 이어서 재개는 running update(endDate=staleDate), 시계 진행은 무요청, 일시정지는 남은 1350 update여야 한다.
    func testV15_배선_일시정지_시드_진입부터_재개_시계진행_일시정지까지_요청이_기록된다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))

        XCTAssertTrue(waitForRequestCount(h, 1), "시작 요청이 정확히 1건이어야 함: \(h.value("test.liveActivity") ?? "nil")")
        let start = try XCTUnwrap(requests(h)?.first)
        XCTAssertEqual(start["op"] as? String, "start")
        XCTAssertEqual(start["status"] as? String, "paused")
        XCTAssertEqual(number(start["pausedRemaining"]), 1410)
        XCTAssertTrue(isNil(start["endDate"]))
        XCTAssertTrue(isNil(start["staleDate"]))

        h.tap("journey.timer.resume")
        XCTAssertTrue(waitForRequestCount(h, 2))
        let resumed = try XCTUnwrap(requests(h)?[1])
        XCTAssertEqual(resumed["op"] as? String, "update")
        XCTAssertEqual(resumed["status"] as? String, "running")
        let endDate = try XCTUnwrap(number(resumed["endDate"]))
        XCTAssertEqual(number(resumed["staleDate"]), endDate)

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.advance(60)
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(requests(h)?.count, 2)

        h.tap("journey.timer.pause")
        XCTAssertTrue(waitForRequestCount(h, 3))
        let paused = try XCTUnwrap(requests(h)?[2])
        XCTAssertEqual(paused["op"] as? String, "update")
        XCTAssertEqual(paused["status"] as? String, "paused")
        XCTAssertEqual(number(paused["pausedRemaining"]), 1350)
    }
}
