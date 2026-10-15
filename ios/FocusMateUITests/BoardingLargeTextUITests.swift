import Foundation
import XCTest

@MainActor
final class BoardingLargeTextUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func reach(_ target: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(target.waitForExistence(timeout: timeout), target.identifier)
        var attempts = 0
        while !target.isHittable && attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)")
    }

    // 깨짐: 가장 큰 글자에서 진행 여정 안내가 있는 메인이 스크롤되지 않아 메뉴 버튼이 화면 밖에 갇힌다.
    func testF3_가장_큰_글자에서_진행_여정_안내가_있어도_메인_메뉴_버튼_모두_닿고_프로필을_열_수_있다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "activeJourney",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        for id in ["open.preparation", "open.records", "open.settings", "open.profile", "open.cardCustomization"] {
            let button = h.app.buttons[id]
            XCTAssertTrue(button.waitForExistence(timeout: timeout), id)
            var attempts = 0
            while !button.isHittable && attempts < 6 {
                h.app.swipeUp()
                attempts += 1
            }
            XCTAssertTrue(button.isHittable, "스크롤해도 닿지 않음: \(id)")
        }

        let profile = h.app.buttons["open.profile"]
        var attempts = 0
        while !profile.isHittable && attempts < 6 {
            h.app.swipeUp()
            attempts += 1
        }
        profile.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    // 깨짐: 가장 큰 글자에서 폐기·승차권·탑승·시작 버튼 중 하나가 화면 안에 닿지 않는다.
    func testU11_AC23_가장_큰_글자에서도_승차_태그와_출발_안내_시작까지_끝낼_수_있다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "activeJourney",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
                "--fm-ui-reduce-motion", "on"
            ]
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let open = h.app.buttons["open.preparation"]
        reach(open, in: h.app)
        open.tap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        let wheel = h.app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout))
        wheel.adjust(toPickerWheelValue: "60분")
        let bus = h.element("time.candidate.2014")
        reach(bus, in: h.app)
        bus.tap()
        let proceed = h.element("time.proceed")
        reach(proceed, in: h.app)
        proceed.tap()

        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
        let tag = h.element("preparation.tag.reading")
        reach(tag, in: h.app)
        tag.tap()
        let field = h.element("preparation.task")
        reach(field, in: h.app)
        field.tap()
        field.typeText("보고서 읽기")
        let confirm = h.app.buttons["preparation.confirm"]
        reach(confirm, in: h.app)
        confirm.tap()

        let boardBus = h.app.buttons["board.boardBus"]
        reach(boardBus, in: h.app)
        boardBus.tap()

        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
        let activate = h.element("test.activateBoardingCard")
        XCTAssertTrue(activate.waitForExistence(timeout: timeout))
        activate.tap()

        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        let start = h.element("journey.start")
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        XCTAssertTrue(start.isHittable, "시작 버튼이 화면 안에서 닿지 않음")
    }
}
