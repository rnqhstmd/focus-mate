import Foundation
import XCTest

/// DEBUG URL entry injection only; this does not verify OS URL delivery or a real widget tap.
@MainActor
final class WidgetEntryUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func url(_ path: String, age: TimeInterval = 0, items: [URLQueryItem] = []) throws -> String {
        var value = URLComponents()
        value.scheme = "focusmate"
        value.host = "widget"
        value.path = "/" + path
        value.queryItems = [URLQueryItem(name: "v", value: "1"),
                           URLQueryItem(name: "issuedAt", value: String(Int(Date().timeIntervalSince1970 - age)))] + items
        return try XCTUnwrap(value.url?.absoluteString)
    }

    private func dayToday() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // Break: widget analytics entry loses its week/tag context or filters the upper total.
    func testAC5_분석링크는_주간과독서필터로열고_전체150분6회를유지한다() throws {
        let link = try url("analytics", items: [URLQueryItem(name: "day", value: dayToday()),
                                               URLQueryItem(name: "tag", value: "독서"),
                                               URLQueryItem(name: "period", value: "week")])
        let h = FocusMateUIHarness.launch(seed: "analytics", extraArguments: ["--fm-ui-widget-url", link])
        XCTAssertTrue(h.element("screen.analytics").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("analytics.period.week").isSelected)
        XCTAssertTrue(h.element("analytics.tag.독서").isSelected)
        XCTAssertTrue(h.element("analytics.clearTag").exists)
        let summary = h.element("analytics.summary")
        let text = summary.label + " " + ((summary.value as? String) ?? "")
        XCTAssertNotNil(text.range(of: "(?<![0-9])150분", options: .regularExpression))
        XCTAssertNotNil(text.range(of: "(?<![0-9])6회", options: .regularExpression))
    }

    private func assertSafeHome(_ link: String) throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", link])
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.analytics").exists)
        XCTAssertFalse(h.element("screen.time").exists)
        XCTAssertEqual(try h.persistedBytes(), bytes)
        XCTAssertEqual(try h.writeAttempts(), 0)
    }

    // Compatibility guard: malformed entry must not navigate or change persisted data.
    func testAC5_잘못된경로링크는_메인과저장을유지한다() throws {
        try assertSafeHome(url("unknown"))
    }

    // Compatibility guard: expired analytics entry must not open old context.
    func testAC5_24시간지난분석링크는_메인과저장을유지한다() throws {
        try assertSafeHome(url("analytics", age: 90_000))
    }

    // Compatibility guard: journey link must not resume the paused timer or save.
    func testAC5_정지여정링크는_기존카드만보이고_자동재개하거나저장하지않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let id = try XCTUnwrap(try h.memoryActive()?["id"] as? String)
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", try url("journey", items: [URLQueryItem(name: "id", value: id)])])
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertTrue(h.app.buttons["main.resumeJourney"].exists)
        XCTAssertFalse(h.element("journey.timer.remaining").exists)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(try h.writeAttempts(), 0)
        XCTAssertEqual(try h.persistedBytes(), bytes)
    }

    // Break: new-journey link bypasses confirmation or cancellation destroys the old journey.
    func testAC5_새여정링크는_기존확인을열고_취소하면원본을유지한다() throws {
        let h = FocusMateUIHarness.launch(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let id = try XCTUnwrap(try h.memoryActive()?["id"] as? String)
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", try url("new", items: [URLQueryItem(name: "id", value: id)])])
        let alert = h.alert(titled: "새 여정을 시작할까요?")
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        let confirmExists = h.alertButton("main.newJourney.confirm", label: "새 여정 시작").waitForExistence(timeout: timeout)
        if !confirmExists {
            let tree = XCTAttachment(string: h.app.debugDescription)
            tree.name = "widget-entry-alert-tree"
            tree.lifetime = .keepAlways
            add(tree)
        }
        XCTAssertTrue(confirmExists)
        XCTAssertEqual(try h.writeAttempts(), 0)
        let keep = h.alertButton("main.newJourney.keep", label: "이전 여정 유지하기")
        XCTAssertTrue(keep.waitForExistence(timeout: timeout))
        keep.tap()
        XCTAssertTrue(h.waitUntil { !alert.exists })
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertEqual(try h.memoryActive()?["id"] as? String, id)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(try h.writeAttempts(), 0)
        XCTAssertEqual(try h.persistedBytes(), bytes)
    }
}
