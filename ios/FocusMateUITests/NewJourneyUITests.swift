import Foundation
import XCTest

/// W07 새 여정 시작 확인 흐름 (AC-6~12, AC-24 확정).
/// 현재 정류장을 단언하므로 life* 시드만 쓴다(AC-12 제외: 여정 없음만 필요).
/// 알림이 열린 동안의 불변은 열기 전 값과 안전 버튼으로 닫은 직후 값의 차이로 본다(R6).
/// AC-11의 alert 버튼은 첫 탭에 닫히므로 진짜 두 번 탭은 재현할 수 없다.
/// doubleTap + 쓰기 증가 1 + 화면 1회로 최대한 재현하고, 1차 보장은 모델 단위 테스트(.rejected)다.
@MainActor
final class NewJourneyUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let alertTitle = "새 여정을 시작할까요?"
    private let alertBody = "이전 여정은 그만두고 새 여행을 준비해요. 완료 기록은 남기지 않아요."
    private let saveFailureText = "저장하지 못했어요. 다시 눌러주세요."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func tapStart(_ h: FocusMateUIHarness) {
        let start = h.app.buttons["open.preparation"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout), "open.preparation 없음")
        start.tap()
    }

    private func openAlert(_ h: FocusMateUIHarness) {
        tapStart(h)
        XCTAssertTrue(h.alert(titled: alertTitle).waitForExistence(timeout: timeout), "새 여정 alert 없음")
    }

    private func confirmButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("main.newJourney.confirm", label: "새 여정 시작")
    }

    private func keepButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("main.newJourney.keep", label: "이전 여정 유지하기")
    }

    private func tapConfirm(_ h: FocusMateUIHarness) {
        let button = confirmButton(h)
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "main.newJourney.confirm 없음")
        button.tap()
    }

    // MARK: AC-6

    // 깨짐: 제목·본문 문구가 PRD와 다르다.
    func testAC6_새_여정_대화상자의_제목과_본문() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        openAlert(h)

        let alert = h.alert(titled: alertTitle)
        XCTAssertTrue(alert.staticTexts[alertBody].exists, "본문 없음")
    }

    // 깨짐: 두 버튼의 id 또는 문구가 계약과 다르다.
    func testAC6_새_여정_대화상자는_유지하기와_새_여정_시작_두_버튼을_가진다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        openAlert(h)

        XCTAssertTrue(keepButton(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(confirmButton(h).exists)
    }

    // MARK: AC-7

    // 깨짐: 유지하기가 대화상자를 닫지 않거나 시간 선택으로 이동한다.
    func testAC7_유지하기는_대화상자만_닫고_메인에_머문다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        openAlert(h)

        keepButton(h).tap()

        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertFalse(h.element("screen.time").exists)
        XCTAssertTrue(h.element("main.activeJourney").exists)
    }

    // 깨짐: 열기·취소 중 저장이 일어나거나 저장값이 바뀐다 (R6: 열기 전과 닫은 직후 비교).
    func testAC7_유지하기는_저장_쓰기_0회이고_저장값이_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()

        openAlert(h)
        keepButton(h).tap()
        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))

        XCTAssertEqual(try h.writeAttempts(), attemptsBefore)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }

    // 깨짐: 취소했는데 현재 정류장 표시가 바뀐다 (성수역 출발 시드).
    func testAC7_유지하기_뒤_현재_정류장은_출발_정류장_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.currentStation").waitForExistence(timeout: timeout))
        let before = h.element("main.currentStation").value as? String

        openAlert(h)
        keepButton(h).tap()
        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))

        XCTAssertEqual(h.element("main.currentStation").value as? String, before)
    }

    // MARK: AC-8

    // 깨짐: 확정 후 시간 선택으로 이동하지 않거나 메인 카드가 남는다.
    func testAC8_확정하면_시간_선택으로_가고_카드는_사라진다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)

        tapConfirm(h)

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
    }

    // 깨짐: 도달 정류장(600초=2칸=뚝섬역)이 아닌 곳이 저장된다.
    func testAC8_확정하면_저장된_현재_정류장은_뚝섬역이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        let station = try h.persistedCurrentStation()
        XCTAssertEqual(station.id, "ttukseom")
        XCTAssertEqual(station.name, "뚝섬역")
    }

    // 깨짐: 여정이 삭제되지 않거나 완료 기록이 만들어지거나 지워진다.
    func testAC8_확정하면_진행_여정이_삭제되고_완료_기록은_1건_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }

    // 깨짐: 현재 정류장 변경과 여정 삭제가 두 번 저장으로 쪼개진다(BR-4).
    func testAC8_확정은_저장_쓰기_정확히_1회다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // MARK: AC-9

    // 깨짐: 재실행 뒤 여정이 되살아나거나 현재 정류장이 되돌아간다.
    func testAC9_확정_뒤_재실행하면_카드_없이_현재_정류장은_뚝섬역이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)
        tapConfirm(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "뚝섬역")
    }

    // 깨짐: 여정이 없는데 시작 버튼이 계속 "새 여정 시작"이다.
    func testAC9_확정_뒤_재실행하면_시작_버튼은_새_여정_시작이_아니다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)
        tapConfirm(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        let start = h.app.buttons["open.preparation"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertNotEqual(start.label, "새 여정 시작")
        XCTAssertEqual(try h.persistedCurrentStation().id, "ttukseom")
    }

    // MARK: AC-10

    // 깨짐: 저장 실패인데 시간 선택으로 이동하거나 카드가 사라지거나 실패 안내가 없다.
    func testAC10_확정_저장_실패는_메인에_머물고_실패_안내를_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.failNextMainSave {
            openAlert(h)
            tapConfirm(h)
        }

        let failure = h.element("main.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, saveFailureText)
        XCTAssertFalse(h.element("screen.time").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("main.activeJourney").exists)
    }

    // 깨짐: 실패한 확정이 저장값을 바꾸거나 예약이 소비되지 않는다(시도 정확히 1).
    func testAC10_확정_저장_실패는_저장값을_바꾸지_않고_시도는_1회다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()

        h.failNextMainSave {
            openAlert(h)
            tapConfirm(h)
        }
        XCTAssertTrue(h.element("main.saveFailure").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), attemptsBefore + 1)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
    }

    // 깨짐: 재시도해도 AC-8의 결과(뚝섬역, 여정 삭제, 시간 선택)가 되지 않는다.
    func testAC10_실패_뒤_다시_확정하면_AC8_결과가_된다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let attemptsBefore = try h.writeAttempts()

        h.failNextMainSave {
            openAlert(h)
            tapConfirm(h)
        }
        XCTAssertTrue(h.element("main.saveFailure").waitForExistence(timeout: timeout))

        openAlert(h)
        tapConfirm(h)

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedCurrentStation().id, "ttukseom")
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.writeAttempts(), attemptsBefore + 2)
    }

    // MARK: AC-11

    // 깨짐: 연타로 저장이 두 번 일어난다.
    func testAC11_확정_연타는_저장_쓰기_1회다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()
        openAlert(h)
        let confirm = confirmButton(h)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))

        confirm.doubleTap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // 깨짐: 연타로 시간 선택 화면이 두 번 쌓인다.
    func testAC11_확정_연타는_시간_선택_화면을_한_번만_연다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600")
        openAlert(h)
        let confirm = confirmButton(h)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))

        confirm.doubleTap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.app.descendants(matching: .any).matching(identifier: "screen.time").count, 1)
    }

    // MARK: AC-12

    // 깨짐: 진행 여정이 없는데 대화상자가 뜨거나 시간 선택으로 가지 않는다.
    func testAC12_여정이_없으면_대화상자_없이_시간_선택으로_간다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "invalidMinutesJourney", extraArguments: FocusMateUIHarness.manualClockArguments
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)

        tapStart(h)

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.alert(titled: alertTitle).exists)
    }

    // 깨짐: 여정이 없는 시작이 저장을 일으킨다.
    func testAC12_여정이_없으면_시작해도_저장_쓰기_0회다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "invalidMinutesJourney", extraArguments: FocusMateUIHarness.manualClockArguments
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()

        tapStart(h)
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before)
    }

    // MARK: AC-24 (도착 여정은 새 여정 경로 없음)

    // 깨짐: 도착 여정에 새 여정 시작 경로(open.preparation)가 남거나, 확정 알림이 열리거나 저장이 일어난다.
    // 기존 확정 경로 2건(현재 정류장 서울숲 입구 / 여정 삭제·기록 1건)은 하차 흐름으로 이동해 중복이라 하나로 합쳤다.
    func testAC24_도착_여정에는_새_여정_경로가_없고_하차하기만_있다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeArrived")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))

        XCTAssertTrue(h.app.buttons["open.alighting"].waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("open.preparation").exists)
        XCTAssertFalse(h.alert(titled: alertTitle).exists)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }
}
