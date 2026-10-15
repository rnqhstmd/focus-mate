import Foundation
import XCTest

/// W07 생명주기·접근성 (AC-27, 28, 32, 33, 34).
/// alert가 열린 동안의 불변은 열기 전 값과 안전 버튼으로 닫은 직후 값의 차이로 본다(R6).
/// 첫 VoiceOver 포커스 위치(alert의 기본 안전 버튼)는 시스템 alert라 XCUITest로 자동화할 수 없다.
/// 이 항목과 낭독 순서는 W14 접근성 수동 점검으로 이관한다. 여기서는 두 안전 버튼의 존재·문구·누를 수 있음만 본다.
@MainActor
final class JourneyLifecycleSafetyUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let abandonTitle = "여행을 그만둘까요?"
    private let newJourneyTitle = "새 여정을 시작할까요?"
    private let noticeText = "뚝섬역에서 여행을 마쳤어요. 완료 기록은 남기지 않았어요."
    private let maxTextArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let reduceMotionArguments = ["--fm-ui-reduce-motion", "on"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: 도우미

    private func resumeFromMain(_ h: FocusMateUIHarness) {
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "main.resumeJourney 없음")
        resume.tap()
    }

    private func launchPaused(_ seed: String, extra: [String] = []) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchLifecycle(seed: seed, extraArguments: extra)
        resumeFromMain(h)
        h.tap("journey.timer.pause", timeout: timeout)
        XCTAssertTrue(h.element("journey.abandon").waitForExistence(timeout: timeout), "journey.abandon 없음")
        return h
    }

    private func openAbandonAlert(_ h: FocusMateUIHarness) {
        h.tap("journey.abandon", timeout: timeout)
        XCTAssertTrue(h.alert(titled: abandonTitle).waitForExistence(timeout: timeout), "포기 alert 없음")
    }

    private func openNewJourneyAlert(_ h: FocusMateUIHarness) {
        let start = h.app.buttons["open.preparation"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout), "open.preparation 없음")
        start.tap()
        XCTAssertTrue(h.alert(titled: newJourneyTitle).waitForExistence(timeout: timeout), "새 여정 alert 없음")
    }

    private func abandonCancel(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("journey.abandon.cancel", label: "계속 여행")
    }

    private func abandonConfirm(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("journey.abandon.confirm", label: "그만두기")
    }

    private func keepButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("main.newJourney.keep", label: "이전 여정 유지하기")
    }

    private func confirmNewButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("main.newJourney.confirm", label: "새 여정 시작")
    }

    /// 메인은 ScrollView라 아래로 스크롤하며 누를 수 있게 만든다.
    private func scrollUntilHittable(_ element: XCUIElement, in h: FocusMateUIHarness) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        var tries = 0
        while !element.isHittable && tries < 6 {
            h.app.swipeUp()
            tries += 1
        }
        return element.isHittable
    }

    // MARK: AC-27 (alert 중 백그라운드 왕복)

    // 깨짐: 백그라운드 복귀가 포기 alert를 닫거나, 닫은 뒤 저장이 일어난다.
    func testAC27_포기_alert는_백그라운드_왕복_뒤에도_열려_있고_안전_버튼으로_닫아도_저장이_그대로다() throws {
        let h = launchPaused("lifePaused600")
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()
        openAbandonAlert(h)

        h.goBackground()

        XCTAssertTrue(h.alert(titled: abandonTitle).waitForExistence(timeout: timeout), "복귀 뒤 alert 사라짐")
        let cancel = abandonCancel(h)
        XCTAssertTrue(cancel.waitForExistence(timeout: timeout))
        cancel.tap()
        XCTAssertFalse(h.alert(titled: abandonTitle).waitForExistence(timeout: 1))
        XCTAssertEqual(try h.writeAttempts(), attemptsBefore)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
    }

    // 깨짐: 백그라운드 복귀가 새 여정 alert를 닫거나, 닫은 뒤 저장이 일어난다.
    func testAC27_새_여정_alert는_백그라운드_왕복_뒤에도_열려_있고_안전_버튼으로_닫아도_저장이_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()
        openNewJourneyAlert(h)

        h.goBackground()

        XCTAssertTrue(h.alert(titled: newJourneyTitle).waitForExistence(timeout: timeout), "복귀 뒤 alert 사라짐")
        let keep = keepButton(h)
        XCTAssertTrue(keep.waitForExistence(timeout: timeout))
        keep.tap()
        XCTAssertFalse(h.alert(titled: newJourneyTitle).waitForExistence(timeout: 1))
        XCTAssertEqual(try h.writeAttempts(), attemptsBefore)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
    }

    // MARK: AC-28 (alert 중 종료·재실행)

    // 깨짐: 새 여정 alert가 열린 채 종료·재실행하면 여정이 사라지거나 경과가 늘거나 정류장이 바뀐다.
    func testAC28_새_여정_alert가_열린_채_재실행하면_카드와_경과_90과_정류장이_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        openNewJourneyAlert(h)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("24 min 남음"), card.label)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "성수역")
    }

    // 깨짐: 포기 alert가 열린 채 종료·재실행하면 포기가 확정되거나 경과가 늘거나 정류장이 바뀐다.
    func testAC28_포기_alert가_열린_채_재실행하면_카드와_경과_90과_정류장이_그대로다() throws {
        let h = launchPaused("lifePaused90")
        openAbandonAlert(h)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("24 min 남음"), card.label)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "성수역")
        XCTAssertFalse(h.element("main.abandonNotice").exists)
    }

    // MARK: AC-32 (낭독 구조; 첫 포커스는 W14 이관)

    // 깨짐: 포기 alert의 안전 버튼 문구·식별자가 계약과 다르다.
    func testAC32_포기_alert의_안전_버튼은_계속_여행이다() throws {
        let h = launchPaused("lifePaused600")
        openAbandonAlert(h)

        XCTAssertTrue(abandonCancel(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(abandonConfirm(h).exists)
    }

    // 깨짐: 새 여정 alert의 안전 버튼 문구·식별자가 계약과 다르다.
    func testAC32_새_여정_alert의_안전_버튼은_이전_여정_유지하기다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        openNewJourneyAlert(h)

        XCTAssertTrue(keepButton(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(confirmNewButton(h).exists)
    }

    // 깨짐: 이어가기 카드가 여러 요소로 쪼개지거나 이어가기 버튼이 카드에 합쳐져 따로 읽히지 않는다.
    func testAC32_이어가기_카드는_한_요소이고_이어가기는_별도_버튼이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")

        let cards = h.app.descendants(matching: .any).matching(identifier: "main.activeJourney")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: timeout))
        XCTAssertEqual(cards.count, 1)
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.exists)
        XCTAssertEqual(resume.label, "이전 여정 이어가기")
        XCTAssertNotEqual(resume.identifier, cards.firstMatch.identifier)
    }

    // MARK: AC-33 (최대 접근성 글씨)

    // 깨짐: 최대 글씨에서 일시정지 화면의 남은 시간·재개·포기가 가려지거나 44pt 미만이거나 스크롤이 생긴다.
    func testAC33_최대_글씨의_일시정지_화면에서_남은_시간_재개_포기가_스크롤_없이_닿는다() throws {
        let h = launchPaused("lifePaused600", extra: maxTextArguments)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")

        for id in ["journey.timer.remaining", "journey.timer.resume", "journey.abandon"] {
            let target = h.element(id)
            XCTAssertTrue(target.waitForExistence(timeout: timeout), "\(id) 없음")
            XCTAssertTrue(target.isHittable, "\(id) 누를 수 없음")
            if id != "journey.timer.remaining" {
                XCTAssertGreaterThanOrEqual(target.frame.height, 44, "\(id) 높이")
            }
        }
        XCTAssertEqual(h.app.scrollViews.count, 0)
    }

    // 깨짐: 최대 글씨에서 포기 alert 버튼이 눌리지 않는다.
    func testAC33_최대_글씨의_포기_alert_두_버튼을_누를_수_있다() throws {
        let h = launchPaused("lifePaused600", extra: maxTextArguments)
        openAbandonAlert(h)

        XCTAssertTrue(abandonCancel(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(abandonCancel(h).isHittable)
        XCTAssertTrue(abandonConfirm(h).isHittable)
    }

    // 깨짐: 최대 글씨에서 메인의 이어가기·새 여정 시작 버튼에 닿을 수 없다.
    func testAC33_최대_글씨의_메인에서_이어가기와_새_여정_시작에_닿는다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90", extraArguments: maxTextArguments)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")

        XCTAssertTrue(scrollUntilHittable(h.app.buttons["main.resumeJourney"], in: h), "main.resumeJourney")
        XCTAssertTrue(scrollUntilHittable(h.app.buttons["open.preparation"], in: h), "open.preparation")
    }

    // 깨짐: 최대 글씨에서 새 여정 alert 버튼이 눌리지 않는다.
    func testAC33_최대_글씨의_새_여정_alert_두_버튼을_누를_수_있다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90", extraArguments: maxTextArguments)
        let start = h.app.buttons["open.preparation"]
        XCTAssertTrue(scrollUntilHittable(start, in: h), "open.preparation")
        start.tap()
        XCTAssertTrue(h.alert(titled: newJourneyTitle).waitForExistence(timeout: timeout))

        XCTAssertTrue(keepButton(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(keepButton(h).isHittable)
        XCTAssertTrue(confirmNewButton(h).isHittable)
    }

    // MARK: AC-34 (동작 줄이기: 꺼졌을 때와 같은 결과)

    // 깨짐: 동작 줄이기에서 이어가기가 진행 상태로 열리지 않거나 60초 뒤 23 min이 아니다 (AC-3).
    func testAC34_동작_줄이기에서도_이어가기는_진행_상태로_열리고_60초_뒤_23분이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90", extraArguments: reduceMotionArguments)
        resumeFromMain(h)

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        h.advance(60)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "23 min")
    }

    // 깨짐: 동작 줄이기에서 새 여정 확정이 시간 선택으로 가지 않거나 저장 정류장이 다르다 (AC-8).
    func testAC34_동작_줄이기에서도_새_여정_확정은_시간_선택과_뚝섬역_저장이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600", extraArguments: reduceMotionArguments)
        openNewJourneyAlert(h)
        let confirm = confirmNewButton(h)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))

        confirm.tap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedCurrentStation().id, "ttukseom")
    }

    // 깨짐: 동작 줄이기에서 포기 결과가 다르다 — 안내가 없거나 정류장이 뚝섬역이 아니다 (AC-16).
    func testAC34_동작_줄이기에서도_포기하면_안내가_나오고_현재_정류장은_뚝섬역이다() throws {
        let h = launchPaused("lifePaused600", extra: reduceMotionArguments)
        openAbandonAlert(h)
        let confirm = abandonConfirm(h)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))

        confirm.tap()

        XCTAssertTrue(h.element("main.abandonNotice").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.element("main.abandonNotice").label, noticeText)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "뚝섬역")
    }
}
