import Foundation
import XCTest

/// 실제 분 타이머 접근성 UI 테스트 V7 (--fm-ui-clock manual).
@MainActor
final class JourneyTimerAccessibilityUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐: 낭독 값(남은 시간 N분)·라벨(타이머)·보이는 텍스트(N min) 중 하나가 어긋난다.
    func testV7_AC27_남은_시간은_라벨_타이머와_값_남은_시간_24분으로_낭독된다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        let remaining = h.element("journey.timer.remaining")
        XCTAssertTrue(remaining.waitForExistence(timeout: timeout))

        XCTAssertEqual(remaining.label, "타이머")
        XCTAssertEqual(remaining.value as? String, "남은 시간 24분")
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "24 min")
    }

    // 깨짐: 0초 도달 때 낭독 값이 "남은 시간 0분"이 아니다.
    func testV7_AC27_도착하면_낭독_값은_남은_시간_0분이다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerArrived")
        let remaining = h.element("journey.timer.remaining")
        XCTAssertTrue(remaining.waitForExistence(timeout: timeout))

        XCTAssertEqual(remaining.value as? String, "남은 시간 0분")
    }

    // 깨짐: 버튼 라벨이 상태와 어긋나거나, 전환 알림이 1회가 아니거나, 시간이 흐르는 동안 알림이 생긴다.
    func testV7_AC28_전환할_때만_일시정지됨_재개됨을_한_번씩_알리고_시간이_흘러도_알리지_않는다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        let resume = h.element("journey.timer.resume")
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        XCTAssertEqual(resume.label, "재개")
        let initial = try h.diagnostic("test.announcements")

        resume.tap()
        let pause = h.element("journey.timer.pause")
        XCTAssertTrue(pause.waitForExistence(timeout: timeout))
        XCTAssertEqual(pause.label, "일시정지")
        let afterResume = try h.diagnostic("test.announcements")
        XCTAssertEqual(afterResume.components(separatedBy: "재개됨").count - 1, 1, afterResume)

        h.advance(60)
        XCTAssertEqual(try h.diagnostic("test.announcements"), afterResume)

        pause.tap()
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        let afterPause = try h.diagnostic("test.announcements")
        XCTAssertEqual(afterPause.components(separatedBy: "일시정지됨").count - 1, 1, afterPause)
        XCTAssertNotEqual(afterPause, initial)
    }

    // 깨짐: 최대 글자 크기에서 남은 시간·버튼이 가려지거나 44pt 미만이거나 스크롤해야 닿는다.
    func testV7_AC29_가장_큰_글자에서도_남은_시간과_버튼이_스크롤_없이_닿는다() throws {
        let h = FocusMateUIHarness.launchJourney(
            seed: "timerPaused90",
            extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        )
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let remaining = h.element("journey.timer.remaining")
        XCTAssertTrue(remaining.waitForExistence(timeout: timeout))
        XCTAssertTrue(remaining.isHittable)
        let resume = h.element("journey.timer.resume")
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        XCTAssertTrue(resume.isHittable)
        XCTAssertGreaterThanOrEqual(resume.frame.width, 44)
        XCTAssertGreaterThanOrEqual(resume.frame.height, 44)

        resume.tap()
        let pause = h.element("journey.timer.pause")
        XCTAssertTrue(pause.waitForExistence(timeout: timeout))
        XCTAssertTrue(pause.isHittable)
        XCTAssertGreaterThanOrEqual(pause.frame.width, 44)
        XCTAssertGreaterThanOrEqual(pause.frame.height, 44)
        XCTAssertEqual(h.app.scrollViews.count, 0)
    }

    // 깨짐: 동작 줄이기에서 일시정지·재개 결과(분 표기·경과)가 꺼졌을 때와 달라진다.
    func testV7_AC30_동작_줄이기에서도_일시정지_재개_결과가_같다() throws {
        let h = FocusMateUIHarness.launchJourney(
            seed: "timerPaused90",
            extraArguments: ["--fm-ui-reduce-motion", "on"]
        )
        XCTAssertTrue(h.element("journey.timer.remaining").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "24 min")

        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.advance(60)

        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 150)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "23 min")
        XCTAssertEqual(h.element("journey.timer.remaining").value as? String, "남은 시간 23분")
    }
}
