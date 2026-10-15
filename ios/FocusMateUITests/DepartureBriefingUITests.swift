import Foundation
import XCTest

@MainActor
final class DepartureBriefingUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let briefingTimeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchBoarding(reduceMotion: Bool = false) -> FocusMateUIHarness {
        var extra = ["--fm-ui-route", "boarding"]
        if reduceMotion { extra += ["--fm-ui-reduce-motion", "on"] }
        return FocusMateUIHarness.launch(seed: "ready", extraArguments: extra)
    }

    private func enterJourney(_ h: FocusMateUIHarness) {
        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
        let activate = h.element("test.activateBoardingCard")
        XCTAssertTrue(activate.waitForExistence(timeout: timeout))
        activate.tap()
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
    }

    private func briefingDiag(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let raw = try h.diagnostic("test.briefing")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func activeJourney(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        return try XCTUnwrap(journey["active"] as? [String: Any])
    }

    // 깨짐: 문장 순차 표시·시작 버튼 노출/초점, 정류장·버스·분 비노출, 시작 후 상태 전이, 뒤로가기 규칙 중 하나가 깨진다.
    func testU4_AC17_19_20_출발_안내가_끝나면_시작을_누르고_임시_화면에서_뒤로_메인으로_돌아온다() throws {
        let h = launchBoarding()
        enterJourney(h)
        XCTAssertTrue(h.element("journey.briefing").waitForExistence(timeout: timeout))

        let start = h.element("journey.start")
        let deadline = Date().addingTimeInterval(briefingTimeout)
        while Date() < deadline && !(start.exists && start.isHittable) {
            Thread.sleep(forTimeInterval: 0.2)
        }
        XCTAssertTrue(start.exists && start.isHittable)
        XCTAssertEqual(h.element("journey.briefingSentence").value as? String, "버스 출발합니다")
        // 보조: 실제 VoiceOver 포커스는 W14 실기기
        XCTAssertEqual(try briefingDiag(h)["focus"] as? String, "start")

        let texts = h.app.staticTexts.allElementsBoundByIndex.map(\.label)
        let leaking = texts.filter { $0.contains("서울숲역") || $0.contains("2014") || $0.contains("분") }
        XCTAssertEqual(leaking.count, 0, leaking.joined(separator: ","))
        let pauseLike = h.app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS '일시정지' OR identifier CONTAINS 'pause'")
        )
        XCTAssertEqual(pauseLike.count, 0)
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)

        let before = try activeJourney(h)
        XCTAssertEqual(before["phase"] as? String, "awaitingDeparture")
        XCTAssertEqual((before["progress"] as? [String: Any])?["elapsedSeconds"] as? Int, 0)

        start.tap()

        XCTAssertTrue(h.element("journey.placeholder").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.briefing").exists)
        let after = try activeJourney(h)
        XCTAssertEqual(after["phase"] as? String, "departed")
        XCTAssertEqual((after["progress"] as? [String: Any])?["elapsedSeconds"] as? Int, 0)

        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
    }

    // 깨짐: 동작 줄이기에서 세 문장이 한 번에 보이지 않거나 시작 버튼이 즉시 나오지 않는다.
    func testU9_AC18_동작_줄이기에서는_세_문장과_시작_버튼이_한꺼번에_보인다() throws {
        let h = launchBoarding(reduceMotion: true)
        enterJourney(h)

        let start = h.element("journey.start")
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(start.isHittable)
        let sentence = try XCTUnwrap(h.element("journey.briefingSentence").value as? String)
        for part in ["문을 닫습니다", "자리에 앉아주세요", "버스 출발합니다"] {
            XCTAssertTrue(sentence.contains(part), sentence)
        }
        // 보조: 실제 VoiceOver 포커스는 W14 실기기
        let diag = try briefingDiag(h)
        XCTAssertEqual(diag["showsAll"] as? Bool, true)
        XCTAssertEqual(diag["showsStart"] as? Bool, true)
    }
}
