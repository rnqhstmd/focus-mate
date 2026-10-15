import Foundation
import XCTest

/// W07 포기하기 흐름 (AC-13~22, 26, 31, 32 라벨).
/// 진입 경로는 메인 이어가기 -> 일시정지 -> journey.abandon이다. 현재 정류장 단언은 life* 시드만 쓴다.
/// alert가 열린 동안의 불변은 열기 전 값과 안전 버튼으로 닫은 직후 값의 차이로 본다(R6).
/// alert 버튼은 첫 탭에 닫히므로 진짜 두 번 탭은 재현할 수 없다. doubleTap + 쓰기 +1 + 화면으로 최대한 재현하고,
/// 1차 보장은 컨트롤러·모델 단위 테스트(hasFinished, .rejected)다.
@MainActor
final class JourneyAbandonUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let alertTitle = "여행을 그만둘까요?"
    private let alertBody = "지금 도달한 정류장에서 다음 여행을 시작할 수 있어요. 완료 기록은 남기지 않습니다."
    private let saveFailureText = "저장하지 못했어요. 다시 눌러주세요."
    private let noticeText = "뚝섬역에서 여행을 마쳤어요. 완료 기록은 남기지 않았어요."

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

    /// 이어가기 -> 일시정지까지 진행해 journey.abandon이 보이는 상태로 둔다.
    private func launchPaused(_ seed: String) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchLifecycle(seed: seed)
        resumeFromMain(h)
        h.tap("journey.timer.pause", timeout: timeout)
        XCTAssertTrue(h.element("journey.abandon").waitForExistence(timeout: timeout), "journey.abandon 없음")
        return h
    }

    private func confirmButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("journey.abandon.confirm", label: "그만두기")
    }

    private func cancelButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.alertButton("journey.abandon.cancel", label: "계속 여행")
    }

    private func openAlert(_ h: FocusMateUIHarness) {
        h.tap("journey.abandon", timeout: timeout)
        XCTAssertTrue(h.alert(titled: alertTitle).waitForExistence(timeout: timeout), "포기 alert 없음")
    }

    private func tapConfirm(_ h: FocusMateUIHarness) {
        let button = confirmButton(h)
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "journey.abandon.confirm 없음")
        button.tap()
    }

    private func abandonToMain(_ seed: String) -> FocusMateUIHarness {
        let h = launchPaused(seed)
        openAlert(h)
        tapConfirm(h)
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout), "메인으로 못 돌아옴")
        return h
    }

    private func announcementLines(_ h: FocusMateUIHarness, equalTo text: String) throws -> Int {
        try h.diagnostic("test.announcements").components(separatedBy: "\n").filter { $0 == text }.count
    }

    private func stationName(_ h: FocusMateUIHarness) -> String? {
        h.element("main.currentStation").value as? String
    }

    // MARK: AC-13 (포기 버튼은 일시정지에서만)

    // 깨짐: 진행 중에도 포기 버튼이 보이거나, 일시정지에 보이지 않거나, 재개 뒤에도 남는다.
    func testAC13_포기_버튼은_일시정지에서만_있다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.abandon").exists, "이어가기 직후 진행 중")

        h.tap("journey.timer.pause")
        XCTAssertTrue(h.element("journey.abandon").waitForExistence(timeout: timeout), "일시정지")

        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.abandon").exists, "재개 뒤")
    }

    // 깨짐: 도착 화면에도 포기 버튼이 남는다.
    func testAC13_도착_화면에는_포기_버튼이_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused1499")
        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        h.advance(1, times: 2)

        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.abandon").exists)
    }

    // 깨짐: 출발 안내 단계에 포기 버튼이 나온다.
    func testAC13_출발_안내_단계에는_포기_버튼이_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeAwaiting")
        resumeFromMain(h)

        XCTAssertTrue(h.element("journey.briefing").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.abandon").exists)
    }

    // MARK: AC-14 (alert 내용·열기/닫기 불변)

    // 깨짐: 제목 또는 본문 문구가 PRD와 다르다.
    func testAC14_포기_alert의_제목과_본문() throws {
        let h = launchPaused("lifePaused600")
        openAlert(h)

        XCTAssertTrue(h.alert(titled: alertTitle).staticTexts[alertBody].exists, "본문 없음")
    }

    // 깨짐: 버튼 id 또는 문구가 계약과 다르다.
    func testAC14_포기_alert는_계속_여행과_그만두기_두_버튼을_가진다() throws {
        let h = launchPaused("lifePaused600")
        openAlert(h)

        XCTAssertTrue(cancelButton(h).waitForExistence(timeout: timeout))
        XCTAssertTrue(confirmButton(h).exists)
    }

    // 깨짐: 열고 안전 버튼으로 닫는 동안 저장이 일어나거나 저장값이 바뀐다 (R6).
    func testAC14_alert를_열었다_닫아도_저장값과_쓰기_횟수가_그대로다() throws {
        let h = launchPaused("lifePaused600")
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()

        openAlert(h)
        cancelButton(h).tap()
        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))

        XCTAssertEqual(try h.writeAttempts(), attemptsBefore)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
    }

    // MARK: AC-15 (계속 여행)

    // 깨짐: 계속 여행이 alert를 닫지 않거나 재개 버튼이 사라진다.
    func testAC15_계속_여행은_alert만_닫고_재개_버튼이_보인다() throws {
        let h = launchPaused("lifePaused600")
        openAlert(h)

        cancelButton(h).tap()

        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("screen.journey").exists)
    }

    // 깨짐: 닫은 뒤 포커스 복귀 의도가 포기 버튼으로 보고되지 않는다.
    func testAC15_계속_여행_뒤_포커스는_포기_버튼으로_돌아온다() throws {
        let h = launchPaused("lifePaused600")
        openAlert(h)

        cancelButton(h).tap()
        XCTAssertFalse(h.alert(titled: alertTitle).waitForExistence(timeout: 1))

        XCTAssertEqual(try h.abandonDiagnostic()["focus"] as? String, "abandon")
    }

    // MARK: AC-16 (일반 포기)

    // 깨짐: 포기 뒤 메인에 안내가 없거나 문구가 다르다.
    func testAC16_포기하면_메인에_뚝섬역_안내가_나온다() throws {
        let h = abandonToMain("lifePaused600")

        let notice = h.element("main.abandonNotice")
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, noticeText)
    }

    // 깨짐: 포기 뒤에도 진행 카드가 남거나 현재 정류장이 뚝섬역이 아니다.
    func testAC16_포기하면_진행_카드가_없고_현재_정류장은_뚝섬역이다() throws {
        let h = abandonToMain("lifePaused600")

        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(stationName(h), "뚝섬역")
    }

    // 깨짐: 저장된 현재 정류장이 도달 정류장(뚝섬 정방향)이 아니거나 완료 기록이 늘거나 줄거나 여정이 남는다.
    func testAC16_포기하면_저장된_정류장은_뚝섬_정방향이고_기록은_1건이다() throws {
        let h = abandonToMain("lifePaused600")

        let station = try h.persistedCurrentStation()
        XCTAssertEqual(station.id, "ttukseom")
        XCTAssertEqual(station.direction, 1)
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }

    // 깨짐: 포기 안내 낭독이 없거나 두 번 이상 나간다 (R4).
    func testAC16_포기하면_포기_안내_낭독이_정확히_1회_나간다() throws {
        let h = launchPaused("lifePaused600")
        let before = try announcementLines(h, equalTo: noticeText)
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("main.abandonNotice").waitForExistence(timeout: timeout))

        XCTAssertEqual(try announcementLines(h, equalTo: noticeText), before + 1)
    }

    // 깨짐: 현재 정류장 변경과 여정 삭제가 두 번 저장으로 쪼개지거나 저장이 없다 (BR-4).
    func testAC16_포기는_저장_쓰기_정확히_1회다() throws {
        let h = launchPaused("lifePaused600")
        let before = try h.writeAttempts()
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // MARK: AC-17/18/19 (도달 정류장 경계)

    // 깨짐: 299초는 1칸 미만이라 출발 정류장(성수역)이어야 한다.
    func testAC17_299초에서_포기하면_성수역이다() throws {
        let h = abandonToMain("lifePaused299")
        XCTAssertEqual(stationName(h), "성수역")
    }

    // 깨짐: 300초 경계에서 한 칸 진행한 성수동이 아니다.
    func testAC17_300초에서_포기하면_성수동이다() throws {
        let h = abandonToMain("lifePaused300")
        XCTAssertEqual(stationName(h), "성수동")
    }

    // 깨짐: 역방향 진행을 정방향으로 계산하거나 방향을 잃는다.
    func testAC18_역방향_300초에서_포기하면_성수사거리이고_방향은_역이다() throws {
        let h = abandonToMain("lifeReverse300")

        XCTAssertEqual(stationName(h), "성수사거리")
        XCTAssertEqual(try h.persistedCurrentStation().direction, -1)
    }

    // 깨짐: 노선 끝을 넘는 진행이 순환하지 않는다.
    func testAC18_순환_900초에서_포기하면_성수역이다() throws {
        let h = abandonToMain("lifeWrap900")
        XCTAssertEqual(stationName(h), "성수역")
    }

    // 깨짐: 0초 진행인데 출발 정류장이 아닌 곳으로 옮겨진다.
    func testAC19_0초에서_포기하면_성수역이다() throws {
        let h = abandonToMain("lifePaused0")
        XCTAssertEqual(stationName(h), "성수역")
    }

    // MARK: AC-20 (저장 실패)

    // 깨짐: 실패했는데 여행 화면을 벗어나거나 안내가 사라지거나 재개 버튼이 없다.
    func testAC20_포기_저장이_실패하면_여행_화면에_머물고_실패_문구를_보인다() throws {
        let h = launchPaused("lifePaused600")
        h.tap("test.failNextSave")
        openAlert(h)

        tapConfirm(h)

        let failure = h.element("journey.timer.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, saveFailureText)
        XCTAssertTrue(h.element("screen.journey").exists)
        XCTAssertTrue(h.element("journey.timer.resume").exists)
        XCTAssertFalse(h.element("main.abandonNotice").exists)
    }

    // 깨짐: 실패한 시도가 저장값을 바꾸거나 시도 수가 1이 아니다(예약 소비 증명).
    func testAC20_포기_저장_실패는_저장값을_바꾸지_않고_시도는_정확히_1회다() throws {
        let h = launchPaused("lifePaused600")
        let attemptsBefore = try h.writeAttempts()
        let bytesBefore = try h.persistedBytes()
        h.tap("test.failNextSave")
        openAlert(h)

        tapConfirm(h)
        XCTAssertTrue(h.element("journey.timer.saveFailure").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), attemptsBefore + 1)
        XCTAssertEqual(try h.persistedBytes(), bytesBefore)
    }

    // 깨짐: 실패 뒤 재시도가 성공하지 않거나 AC-16 결과와 다르다.
    func testAC20_실패_뒤_재시도하면_포기가_완료된다() throws {
        let h = launchPaused("lifePaused600")
        h.tap("test.failNextSave")
        openAlert(h)
        tapConfirm(h)
        XCTAssertTrue(h.element("journey.timer.saveFailure").waitForExistence(timeout: timeout))

        openAlert(h)
        tapConfirm(h)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.element("main.abandonNotice").label, noticeText)
        XCTAssertEqual(stationName(h), "뚝섬역")
        XCTAssertFalse(h.element("main.activeJourney").exists)
    }

    // MARK: AC-21 (연타)

    // 깨짐: 포기 버튼 연타가 alert를 둘 이상 띄운다.
    func testAC21_포기_버튼_연타는_alert_하나만_연다() throws {
        let h = launchPaused("lifePaused600")
        let abandon = h.element("journey.abandon")

        abandon.doubleTap()

        XCTAssertTrue(h.alert(titled: alertTitle).waitForExistence(timeout: timeout))
        XCTAssertEqual(h.app.alerts.count, 1)
    }

    // 깨짐: 그만두기 연타가 저장을 두 번 하거나 메인으로 가지 못한다.
    func testAC21_그만두기_연타는_저장_쓰기_1회이고_메인에_도착한다() throws {
        let h = launchPaused("lifePaused600")
        let before = try h.writeAttempts()
        openAlert(h)
        let confirm = confirmButton(h)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))

        confirm.doubleTap()

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // MARK: AC-22 (재실행)

    // 깨짐: 포기 뒤 재실행에서 카드가 되살아나거나 정류장이 달라지거나 안내가 다시 나온다 (R4).
    func testAC22_포기_뒤_재실행하면_카드와_안내가_없고_정류장은_뚝섬역이다() throws {
        let h = abandonToMain("lifePaused600")

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(stationName(h), "뚝섬역")
        XCTAssertFalse(h.element("main.abandonNotice").exists)
    }

    // 깨짐: 재실행 때 포기 안내가 다시 낭독된다 (R4).
    func testAC22_포기_뒤_재실행하면_포기_안내_낭독이_없다() throws {
        let h = abandonToMain("lifePaused600")

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))

        XCTAssertEqual(try announcementLines(h, equalTo: noticeText), 0)
    }

    // MARK: AC-26 (뒤로 나갈 수 없음)

    private func assertStaysOnJourneyAfterSwipes(_ h: FocusMateUIHarness) throws {
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)

        let edge = h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
        let center = h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.1, thenDragTo: h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)))

        XCTAssertTrue(h.element("screen.journey").exists)
        XCTAssertFalse(h.element("screen.main").exists)
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)
    }

    // 깨짐: 진행 중 화면에 뒤로가기가 생기거나 스와이프로 메인에 돌아간다.
    func testAC26_진행_중_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        try assertStaysOnJourneyAfterSwipes(h)
    }

    // 깨짐: 일시정지(포기 버튼 있음) 화면에 뒤로가기가 생기거나 스와이프로 메인에 돌아간다.
    func testAC26_일시정지_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = launchPaused("lifePaused90")
        try assertStaysOnJourneyAfterSwipes(h)
    }

    // 깨짐: 도착 화면에 뒤로가기가 생기거나 스와이프로 메인에 돌아간다.
    func testAC26_도착_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused1499")
        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.advance(1, times: 2)
        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        try assertStaysOnJourneyAfterSwipes(h)
    }

    // MARK: AC-31 (기록 유지)

    // 깨짐: 포기가 완료 기록을 만들거나 지운다(메모리·저장 모두 1건).
    func testAC31_포기해도_완료_기록은_1건_그대로다() throws {
        let h = abandonToMain("lifePaused600")

        XCTAssertEqual(try h.recordCount(), 1)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }

    // MARK: AC-32 (포기하기 라벨)

    // 깨짐: 버튼 접근성 라벨이 "포기하기"가 아니다.
    func testAC32_포기_버튼의_라벨은_포기하기다() throws {
        let h = launchPaused("lifePaused90")

        XCTAssertEqual(h.element("journey.abandon").label, "포기하기")
    }
}
