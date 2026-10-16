import XCTest

/// 승인 시안과 직접 대조할 네이티브 화면 수집 도구. 기능 RED나 시각 합격 판정이 아니다.
@MainActor
final class RecordsAnalyticsVisualCaptureTests: XCTestCase {
    func testCapture_분석요약과_인사이트의_실제네이티브화면을_첨부한다() {
        continueAfterFailure = false
        let h = FocusMateUIHarness.launch(seed: "analytics")
        h.tap("open.records")
        h.tap("records.analytics.open")
        XCTAssertTrue(h.element("screen.analytics").waitForExistence(timeout: 5))

        let normal = XCTAttachment(screenshot: h.app.screenshot())
        normal.name = "w09b-analysis-normal"
        normal.lifetime = .keepAlways
        add(normal)

        h.app.swipeUp()
        h.app.swipeUp()
        let insights = XCTAttachment(screenshot: h.app.screenshot())
        insights.name = "w09b-analysis-insights"
        insights.lifetime = .keepAlways
        add(insights)
    }
}
