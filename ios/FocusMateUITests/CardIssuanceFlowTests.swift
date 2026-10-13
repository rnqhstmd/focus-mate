import Foundation
import XCTest

@MainActor
final class CardIssuanceFlowTests: XCTestCase {
    private let timeout: TimeInterval = 3
    private let completionTimeout: TimeInterval = 8
    private let idPattern = "^FM-[0-9]{8}$"
    private let xxxl = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: AC-1

    func testAC1_저장_파일이_없으면_발급_전_화면을_보여준다() throws {
        // 깨짐 명명: cardEntry 대신 initialStationEntry로 보내거나 제목/버튼 문구가 바뀌면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")

        XCTAssertTrue(h.element("screen.cardEntry").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.element("card.title").value as? String, "집중동행카드를 발급받아볼까요?")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertEqual(button.label, "집중동행카드 발급받기")
        XCTAssertTrue(button.isEnabled)
        XCTAssertFalse(h.element("card.face").exists)
        XCTAssertFalse(h.element("card.continueButton").exists)
        XCTAssertFalse(h.element("card.issueError").exists)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), "absent")
    }

    // MARK: AC-2

    func testAC2_발급_버튼을_누르면_카드_한_장이_저장된다() throws {
        // 깨짐 명명: 저장을 건너뛰거나 카드를 2장 저장하거나 id 형식이 바뀌면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")
        try issueAndWait(h)

        try assertIssuedSnapshot(h)
        XCTAssertNotEqual(try h.diagnostic("test.persistedBytes"), "absent")
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "1")
    }

    // MARK: AC-3

    func testAC3_발급_완료_화면은_5초_동안_유지된다() throws {
        // 깨짐 명명: 완료 후 자동으로 출발지 선택으로 넘어가면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")
        try issueAndWait(h)

        XCTAssertFalse(h.element("screen.initialStationEntry").waitForExistence(timeout: 5))

        XCTAssertTrue(h.element("screen.cardEntry").exists)
        XCTAssertEqual(h.element("card.title").value as? String, "카드가 발급됐어요. 이제, 어디에서 출발할까요?")
        XCTAssertTrue(h.element("card.face").exists)
        XCTAssertEqual(h.element("card.continueButton").label, "출발지 선택하기")
        XCTAssertFalse(h.element("card.issueButton").exists)
        XCTAssertFalse(h.element("screen.initialStationEntry").exists)
    }

    // MARK: AC-4

    func testAC4_계속_버튼은_출발지_선택으로_이동하고_카드를_유지한다() throws {
        // 깨짐 명명: 이동 시 카드를 새로 발급하거나 cardEntry가 남으면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")
        try issueAndWait(h)
        let issuedID = try cardID(try h.snapshot())

        h.element("card.continueButton").tap()

        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        let items = try cardItems(try h.snapshot())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?["id"] as? String, issuedID)
    }

    // MARK: AC-5

    func testAC5_발급_중_연타해도_카드는_한_장이고_버튼이_잠긴다() throws {
        // 깨짐 명명: 발급 중 재탭이 두 번째 저장을 일으키거나 버튼이 활성이면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none", hold: "manual")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()

        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForLabel(button, "카드를 발급하고 있어요"))
        XCTAssertFalse(button.isEnabled)

        for _ in 0..<2 {
            XCTAssertTrue(button.exists)
            button.tap()
        }

        let release = h.element("test.releaseIssuance")
        XCTAssertTrue(release.waitForExistence(timeout: timeout))
        release.tap()

        XCTAssertTrue(h.element("card.continueButton").waitForExistence(timeout: completionTimeout))
        XCTAssertEqual(try cardItems(try h.snapshot()).count, 1)
        XCTAssertFalse(h.element("card.issueButton").exists)
    }

    // MARK: AC-6

    func testAC6_재실행해도_같은_카드로_출발지_선택이_열린다() throws {
        // 깨짐 명명: 재실행 때 cardEntry로 돌아가거나 카드를 다시 발급하면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")
        try issueAndWait(h)
        let issuedID = try cardID(try h.snapshot())

        h.relaunch()

        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        XCTAssertFalse(h.element("card.issueButton").exists)
        let items = try cardItems(try h.snapshot())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?["id"] as? String, issuedID)
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "0")
    }

    // MARK: AC-7

    func testAC7_저장이_실패하면_오류와_다시_발급_버튼을_보여준다() throws {
        // 깨짐 명명: 실패인데 카드를 보여주거나 상태에 카드를 남기거나 진동을 울리면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none", save: "fail")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()

        let error = h.element("card.issueError")
        XCTAssertTrue(error.waitForExistence(timeout: completionTimeout))
        XCTAssertEqual(error.value as? String, "카드를 발급하지 못했어요. 다시 시도해 주세요.")
        XCTAssertFalse(h.element("card.face").exists)
        XCTAssertFalse(h.element("card.continueButton").exists)
        XCTAssertFalse(h.element("screen.initialStationEntry").exists)
        XCTAssertTrue(waitForLabel(button, "다시 발급받기"))
        XCTAssertTrue(button.isEnabled)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), "absent")
        let snapshot = try h.snapshot()
        XCTAssertEqual(snapshot["cardIssued"] as? Bool, false)
        XCTAssertEqual(try cardItems(snapshot).count, 0)
        XCTAssertFalse(h.element("storage.saveFailure").exists)
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "0")
    }

    // MARK: AC-16

    func testAC16_완료_화면의_어떤_요소에도_카드_번호가_노출되지_않는다() throws {
        // 깨짐 명명: 라벨/값/텍스트 어디에든 숫자 8자리나 "FM ·"를 노출하면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none")
        try issueAndWait(h)
        let id = try cardID(try h.snapshot())
        let digits = String(id.dropFirst(3))
        XCTAssertEqual(digits.count, 8)

        let elements = h.app.descendants(matching: .any).allElementsBoundByIndex
        XCTAssertGreaterThan(elements.count, 0)
        var texts: [String] = []
        for element in elements where !element.identifier.hasPrefix("test.") {
            texts.append(element.label)
            if let value = element.value as? String { texts.append(value) }
        }
        XCTAssertTrue(texts.contains("집중동행카드"), "조회가 카드 얼굴을 포함해야 한다")
        XCTAssertEqual(texts.filter { $0.contains(digits) }.count, 0)
        XCTAssertEqual(texts.filter { $0.hasPrefix("FM ·") }.count, 0)
    }

    // MARK: AC-19

    func testAC19_상태별_접근성_라벨과_안내_문구가_맞다() throws {
        // 깨짐 명명: 라벨이 바뀌거나, 발급 중 버튼 비활성이 풀리거나, 안내가 빠지거나 순서가 뒤바뀌면 실패한다. (하위 장식 비노출·완료 후 포커스는 AC-19M 수동)
        let h = FocusMateUIHarness.launch(seed: "none", hold: "manual")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertEqual(button.label, "집중동행카드 발급받기")
        XCTAssertTrue(button.isEnabled)

        button.tap()
        XCTAssertTrue(waitForLabel(button, "카드를 발급하고 있어요"))
        XCTAssertFalse(button.isEnabled)

        let release = h.element("test.releaseIssuance")
        XCTAssertTrue(release.waitForExistence(timeout: timeout))
        release.tap()

        let continueButton = h.element("card.continueButton")
        XCTAssertTrue(continueButton.waitForExistence(timeout: completionTimeout))
        XCTAssertEqual(continueButton.label, "출발지 선택하기")
        let face = h.element("card.face")
        XCTAssertTrue(face.waitForExistence(timeout: timeout))
        XCTAssertEqual(face.label, "집중동행카드")
        // iOS 27 XCUITest는 accessibilityHidden 하위 요소도 자동화 트리에 노출해 descendants 수로 VoiceOver 노출을 판정할 수 없다 — 장식 비노출은 수동 VoiceOver 확인(trust-ledger)

        let announcements = try h.diagnostic("test.announcements")
        let lines = announcements.components(separatedBy: "\n")
        let startIndex = lines.firstIndex(of: "카드를 발급하고 있어요.")
        let doneIndex = lines.firstIndex(of: "카드가 발급됐어요. 출발지를 선택해보세요.")
        XCTAssertNotNil(startIndex)
        XCTAssertNotNil(doneIndex)
        if let startIndex, let doneIndex {
            XCTAssertLessThan(startIndex, doneIndex)
        }
    }

    // MARK: AC-20

    func testAC20_큰_글자에서_발급_버튼을_누를_수_있다() throws {
        // 깨짐 명명: 큰 글자에서 버튼이 화면 밖/가려짐이면 isHittable이 false가 되어 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none", extraArguments: xxxl)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertTrue(button.isHittable)

        button.tap()

        XCTAssertTrue(h.element("card.continueButton").waitForExistence(timeout: completionTimeout))
        try assertIssuedSnapshot(h)
    }

    func testAC20_큰_글자에서_계속_버튼을_누르면_출발지_선택으로_이동한다() throws {
        // 깨짐 명명: 완료 화면에서 계속 버튼이 가려지면 isHittable 단언이 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none", extraArguments: xxxl)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let issue = h.element("card.issueButton")
        XCTAssertTrue(issue.waitForExistence(timeout: timeout))
        issue.tap()
        let button = h.element("card.continueButton")
        XCTAssertTrue(button.waitForExistence(timeout: completionTimeout))
        let issuedID = try cardID(try h.snapshot())
        XCTAssertTrue(button.isHittable)

        button.tap()

        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        XCTAssertEqual(try cardID(try h.snapshot()), issuedID)
    }

    // MARK: helpers

    private func issueAndWait(_ h: FocusMateUIHarness) throws {
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()
        XCTAssertTrue(h.element("card.continueButton").waitForExistence(timeout: completionTimeout))
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func cardItems(_ snapshot: [String: Any]) throws -> [[String: Any]] {
        let cards = try XCTUnwrap(snapshot["cards"] as? [String: Any], "cards 섹션 없음")
        return try XCTUnwrap(cards["items"] as? [[String: Any]], "cards.items 없음")
    }

    private func cardID(_ snapshot: [String: Any]) throws -> String {
        let first = try XCTUnwrap(try cardItems(snapshot).first, "카드 없음")
        return try XCTUnwrap(first["id"] as? String)
    }

    private func assertIssuedSnapshot(_ h: FocusMateUIHarness) throws {
        let snapshot = try h.snapshot()
        XCTAssertEqual(snapshot["cardIssued"] as? Bool, true)
        let items = try cardItems(snapshot)
        XCTAssertEqual(items.count, 1)
        let id = try XCTUnwrap(items.first?["id"] as? String)
        XCTAssertNotNil(id.range(of: idPattern, options: .regularExpression), "id 형식: \(id)")
        let issuedAt = try XCTUnwrap(items.first?["issuedAt"] as? String)
        let plain = ISO8601DateFormatter()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertTrue(plain.date(from: issuedAt) != nil || fractional.date(from: issuedAt) != nil, "issuedAt: \(issuedAt)")
        let journey = try XCTUnwrap(snapshot["journey"] as? [String: Any])
        XCTAssertTrue(journey["active"] is NSNull)
        let records = try XCTUnwrap(snapshot["records"] as? [String: Any])
        XCTAssertEqual((records["items"] as? [Any])?.count, 0)
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "1")
    }
}
