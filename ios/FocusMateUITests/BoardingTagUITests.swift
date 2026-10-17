import Foundation
import XCTest

// 주의: 이 파일의 testU7은 이 저장소 최초로 XCUIDevice.shared.press(.home)을 쓴다.
// 시뮬레이터에서 scenePhase가 background로 넘어가는지는 이 테스트 자체가 첫 확인이다.
@MainActor
final class BoardingTagUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - 도우미

    private func launchBoarding(
        hold: Bool = false,
        reduceMotion: Bool = false,
        save: String? = nil
    ) -> FocusMateUIHarness {
        var extra = ["--fm-ui-route", "boarding"]
        if hold { extra += ["--fm-ui-boarding-hold", "manual"] }
        if reduceMotion { extra += ["--fm-ui-reduce-motion", "on"] }
        return FocusMateUIHarness.launch(seed: "ready", save: save, extraArguments: extra)
    }

    private func boardingDiag(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let raw = try h.diagnostic("test.boarding")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func activeJourney(_ h: FocusMateUIHarness) throws -> [String: Any]? {
        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        return journey["active"] as? [String: Any]
    }

    private func hapticCount(_ h: FocusMateUIHarness) throws -> Int {
        try XCTUnwrap(Int(try h.diagnostic("test.hapticCount")))
    }

    private func announcements(_ h: FocusMateUIHarness) throws -> String {
        try h.diagnostic("test.announcements")
    }

    private func waitForBoarding(_ h: FocusMateUIHarness) {
        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("boarding.card").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("boarding.tagArea").waitForExistence(timeout: timeout))
    }

    private func dragCardToTagArea(_ h: FocusMateUIHarness) {
        let card = h.element("boarding.card")
        let area = h.element("boarding.tagArea")
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2,
                   thenDragTo: area.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
    }

    private func lcd(_ h: FocusMateUIHarness) throws -> String {
        try h.diagnostic("boarding.lcdStatus")
    }

    private func waitForPhase(_ phase: String, _ h: FocusMateUIHarness) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try boardingDiag(h)["phase"] as? String == phase { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertEqual(try boardingDiag(h)["phase"] as? String, phase)
    }

    private func releaseHold(_ h: FocusMateUIHarness) {
        let release = h.element("test.releaseBoardingHold")
        XCTAssertTrue(release.waitForExistence(timeout: timeout))
        release.tap()
    }

    // MARK: - AC-5

    // 깨짐: LCD 상표/시각/상태, 낭독 라벨이 빠지거나 원본 카드 ID·옛 안내 문구가 보인다.
    // 시안 우선 변경: 카드 번호는 "FM · 0000 0000"으로 보일 수 있고(BR-4), 태그 영역 문구 "카드를 여기에"는 시안 R27 표시다.
    func testU4_AC5_승차_태그_화면_초기_요소와_원본_카드ID_비노출() throws {
        let h = launchBoarding()
        waitForBoarding(h)

        let terminal = h.element("boarding.terminal")
        XCTAssertTrue(terminal.waitForExistence(timeout: timeout))
        XCTAssertTrue(terminal.label.contains("Focus Mate"), terminal.label)
        XCTAssertNotNil(terminal.label.range(of: #"\d{2}:\d{2}"#, options: .regularExpression), terminal.label)
        XCTAssertEqual(try lcd(h), "승차 준비")

        let title = h.element("boarding.title")
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        for part in ["승차 태그", "승차 단계", "카드를 위로 밀어 단말기에 대주세요"] {
            XCTAssertTrue(title.label.contains(part), title.label)
        }
        XCTAssertTrue(title.label.contains("서울숲역"), title.label)
        XCTAssertEqual(h.element("boarding.card").label, "집중동행카드")

        let texts = h.app.staticTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(texts.filter { $0.contains("FM-") }.count, 0, texts.joined(separator: ","))
        XCTAssertFalse(h.app.staticTexts["눌러서 태그하기"].exists)
    }

    // MARK: - U4 태그 구간

    // 깨짐: 끌기 도중 인식(dragChanged) 연결, 햅틱 1회, 즉시 1회 저장, 중복 인식 방지, hold 해제 후 전환이 깨진다.
    func testU4_끌어서_인식하면_저장되고_재시도에_불변이며_해제하면_안내로_전환된다() throws {
        let h = launchBoarding(hold: true)
        waitForBoarding(h)
        XCTAssertNil(try activeJourney(h))
        let hapticsBefore = try hapticCount(h)
        XCTAssertEqual(hapticsBefore, 0)

        dragCardToTagArea(h)
        try waitForPhase("held", h)

        XCTAssertEqual(try hapticCount(h), 1)
        XCTAssertEqual(try lcd(h), "집중동행카드")
        // 보조: SwiftUI offset은 접근성 frame에 반영되지 않아 카드 위치는 진단값으로 확인(실제 위치는 W14 실기기·시각 확인)
        XCTAssertLessThan(try XCTUnwrap(try boardingDiag(h)["offsetY"] as? Double), 0)
        let active = try XCTUnwrap(try activeJourney(h))
        XCTAssertEqual(active["phase"] as? String, "awaitingDeparture")
        let progress = try XCTUnwrap(active["progress"] as? [String: Any])
        XCTAssertEqual(progress["elapsedSeconds"] as? Int, 0)
        XCTAssertTrue(h.element("screen.boarding").exists)
        XCTAssertFalse(h.element("screen.journey").exists)

        let bytes = try h.diagnostic("test.persistedBytes")
        let id = try XCTUnwrap(active["id"] as? String)
        let announced = try announcements(h)

        dragCardToTagArea(h)
        let activate = h.element("test.activateBoardingCard")
        XCTAssertTrue(activate.waitForExistence(timeout: timeout))
        activate.tap()

        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        XCTAssertEqual(try XCTUnwrap(try activeJourney(h))["id"] as? String, id)
        XCTAssertEqual(try hapticCount(h), 1)
        XCTAssertEqual(try announcements(h), announced)
        XCTAssertFalse(h.element("screen.journey").exists)

        releaseHold(h)
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
    }

    // MARK: - U5

    // 깨짐: 짧은 끌기가 인식되거나, 원위치로 돌아가지 않거나, 터치 안내가 안 뜨거나, 숨김 복귀가 전환/저장을 일으킨다.
    func testU5_짧은_끌기는_미인식이고_터치하면_안내가_뜨며_복귀해도_전환되지_않는다() throws {
        let h = launchBoarding()
        waitForBoarding(h)

        let card = h.element("boarding.card")
        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.2, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 40)))

        XCTAssertEqual(try hapticCount(h), 0)
        XCTAssertEqual(try lcd(h), "승차 준비")
        // 보조: SwiftUI offset은 접근성 frame에 반영되지 않아 카드 위치는 진단값으로 확인(실제 위치는 W14 실기기·시각 확인)
        XCTAssertEqual(try boardingDiag(h)["offsetY"] as? Double, 0)

        card.tap()
        XCTAssertTrue(h.element("boarding.tapHint").waitForExistence(timeout: timeout))

        XCUIDevice.shared.press(.home)
        h.app.activate()

        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertNil(try activeJourney(h))
    }

    // MARK: - U6

    // 깨짐: 활성화 경로가 인식/낭독/저장으로 연결되지 않거나 낭독이 중복된다.
    func testU6_활성화하면_인식되고_낭독이_한_번이며_저장된다() throws {
        let h = launchBoarding(hold: true)
        waitForBoarding(h)
        let activate = h.element("test.activateBoardingCard")
        XCTAssertTrue(activate.waitForExistence(timeout: timeout))
        activate.tap()

        try waitForPhase("held", h)
        XCTAssertEqual(try lcd(h), "집중동행카드")
        let spoken = try announcements(h)
        let count = spoken.components(separatedBy: "집중동행카드 인식됨, 승차했습니다").count - 1
        XCTAssertEqual(count, 1, spoken)
        XCTAssertNotNil(try activeJourney(h))
    }

    // MARK: - U7

    // 깨짐: 앱이 숨겨진 동안 대기 중인 전환이 취소되지 않아 해제 후 안내 화면으로 넘어가 버린다.
    func testU7_인식_후_홈으로_나가면_전환이_취소되고_해제해도_넘어가지_않는다() throws {
        let h = launchBoarding(hold: true)
        waitForBoarding(h)
        dragCardToTagArea(h)
        try waitForPhase("held", h)
        let id = try XCTUnwrap(try activeJourney(h)?["id"] as? String)

        XCUIDevice.shared.press(.home)
        h.app.activate()

        try waitForPhase("ready", h)
        XCTAssertEqual(try lcd(h), "승차 준비")

        releaseHold(h)
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.boarding").exists)
        XCTAssertEqual(try XCTUnwrap(try activeJourney(h))["id"] as? String, id)
    }

    // MARK: - U8

    // 깨짐: 저장 실패가 오류로 안 보이거나, 실패했는데 인식·여정이 생기거나, 재시도가 성공 전환으로 이어지지 않는다.
    func testU8_저장_실패는_오류를_보이고_다시_끌면_성공해_전환된다() throws {
        let h = launchBoarding(save: "fail-once-boarding")
        waitForBoarding(h)
        let bytes = try h.diagnostic("test.persistedBytes")

        dragCardToTagArea(h)

        XCTAssertTrue(h.element("boarding.saveFailure").waitForExistence(timeout: timeout))
        XCTAssertEqual(try lcd(h), "승차 준비")
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        XCTAssertNil(try activeJourney(h))

        dragCardToTagArea(h)

        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        XCTAssertNotNil(try activeJourney(h))
    }

    // MARK: - U9

    // 깨짐: 동작 줄이기에서 햅틱이 울리거나, 유지 시간이 보존되지 않아 해제 전에 전환되거나, 해제 후 전환이 안 된다.
    func testU9_동작_줄이기에서도_인식은_햅틱_없이_되고_해제하면_전환된다() throws {
        let h = launchBoarding(hold: true, reduceMotion: true)
        waitForBoarding(h)

        dragCardToTagArea(h)
        try waitForPhase("held", h)

        XCTAssertEqual(try hapticCount(h), 0)
        XCTAssertEqual(try lcd(h), "집중동행카드")
        XCTAssertFalse(h.element("screen.journey").exists)

        releaseHold(h)
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
    }

    // MARK: - AC-9 튐 연출

    // 깨짐: 터치(끌지 않음)가 화면의 튐 연출(tapBounces)로 연결되지 않거나 힌트가 안 뜨거나 횟수가 누적되지 않는다.
    func testU5_AC9_끌지_않고_터치하면_튐_연출이_실행되고_안내가_뜬다() throws {
        let h = launchBoarding()
        waitForBoarding(h)
        XCTAssertEqual(try boardingDiag(h)["tapBounces"] as? Int, 0)

        h.element("boarding.card").tap()
        XCTAssertTrue(h.element("boarding.tapHint").waitForExistence(timeout: timeout))
        XCTAssertEqual(try lcd(h), "승차 준비")
        // 컨트롤러·화면 연출 연결 계약 확인용(보조)
        XCTAssertEqual(try boardingDiag(h)["tapBounces"] as? Int, 1)

        h.element("boarding.card").tap()
        XCTAssertTrue(h.element("boarding.tapHint").exists)
        XCTAssertEqual(try lcd(h), "승차 준비")
        // 컨트롤러·화면 연출 연결 계약 확인용(보조)
        XCTAssertEqual(try boardingDiag(h)["tapBounces"] as? Int, 2)
    }
}
