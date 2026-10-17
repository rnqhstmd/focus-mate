import Foundation
import XCTest

/// 도착 안내 → 하차 태그 → 요약 → 메인 흐름 (alight* 시드, 수동 시계).
/// AC-1~9, 10, 12, 13, 14, 15, 17, 18, 20, 21, 22, 23.
@MainActor
final class AlightingFlowUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    /// 문장 3개(약 1.7초 간격) + 확인 노출까지 기다리는 여유.
    private let briefingTimeout: TimeInterval = 10
    private let sentences = ["곧 서울숲 입구에 도착합니다", "버스가 멈추면 일어나주세요", "카드를 찍고 내려주세요"]
    private let reduceMotion = ["--fm-ui-reduce-motion", "on"]
    private let saveFailureText = "저장하지 못했어요. 다시 눌러주세요."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: helpers

    private func resumeFromMain(_ h: FocusMateUIHarness) {
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "main.resumeJourney 없음")
        resume.tap()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
    }

    private func openAlighting(_ h: FocusMateUIHarness) {
        let button = h.app.buttons["open.alighting"]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "open.alighting 없음")
        button.tap()
        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout), "alighting.briefing 없음")
    }

    private func confirmBriefing(_ h: FocusMateUIHarness) {
        let confirm = h.element("alighting.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: briefingTimeout), "alighting.confirm 없음")
        confirm.tap()
        XCTAssertTrue(h.element("alighting.tag").waitForExistence(timeout: timeout), "alighting.tag 없음")
    }

    private func activateCard(_ h: FocusMateUIHarness) {
        h.tap("test.activateAlightingCard")
    }

    private func toSummary(_ h: FocusMateUIHarness) {
        openAlighting(h)
        confirmBriefing(h)
        activateCard(h)
        XCTAssertTrue(h.element("screen.alightingSummary").waitForExistence(timeout: timeout), "요약 화면 없음")
    }

    private func jsonDiagnostic(_ h: FocusMateUIHarness, _ id: String) throws -> [String: Any] {
        let raw = try h.diagnostic(id)
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func briefing(_ h: FocusMateUIHarness) throws -> [String: Any] {
        try jsonDiagnostic(h, "test.arrivalBriefing")
    }

    /// Live Activity 요청 기록 중 시작 − 종료 수(활성 표시 수).
    private func activeLiveActivities(_ h: FocusMateUIHarness) -> Int? {
        guard let raw = h.value("test.liveActivity"),
              let data = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let requests = root["requests"] as? [[String: Any]] else { return nil }
        let starts = requests.filter { ($0["op"] as? String) == "start" }.count
        let ends = requests.filter { ($0["op"] as? String) == "end" }.count
        return starts - ends
    }

    private func persistedMemoText(_ h: FocusMateUIHarness) throws -> String {
        try h.persistedText()
    }

    // MARK: ① 도착 안내 → 하차 태그 (AC-1, 6, 7, 8, 9, 21, 22)

    // 깨짐: 도착해도 도착 안내가 안 뜨거나, 문장이 순서대로 나오지 않거나, 확인이 안 나오거나,
    // 일시정지·포기가 남거나, 안내 중에 기록이 생긴다.
    func testAC1_22_도착하면_도착_안내가_문장_순서대로_나오고_확인이_나오며_일시정지와_포기는_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightPaused1499")
        resumeFromMain(h)

        h.advance(1)

        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        // 문장 순서는 ArrivalBriefingControllerTests가 결정적으로 검증한다. UI는 처음엔 확인이 없고 끝에 마지막 문장과 함께 나옴을 본다.
        XCTAssertEqual(try briefing(h)["showsConfirm"] as? Bool, false)
        XCTAssertFalse(h.element("alighting.confirm").exists)
        XCTAssertTrue(h.element("alighting.confirm").waitForExistence(timeout: briefingTimeout), "확인 버튼이 나오지 않음")
        XCTAssertEqual(h.element("alighting.sentence").label, sentences[2])
        XCTAssertEqual(try briefing(h)["index"] as? Int, 2)
        for id in ["journey.timer.pause", "journey.timer.resume", "journey.abandon"] {
            XCTAssertFalse(h.element(id).exists, id)
        }
        XCTAssertFalse(h.element("journey.arrived").exists)
        XCTAssertEqual(try h.recordCount(), 0)
    }

    // 깨짐: 확인 뒤 하차 태그로 가지 않거나, 카드에 초점이 없거나, 뒤로가기가 보이거나,
    // 카드 탭만으로 저장·하차 처리가 되거나, 터치 안내가 없거나, LCD에 카드 번호·옛 문구가 나온다.
    func testAC6_7_8_9_21_하차_태그는_카드에_초점이_있고_뒤로가_없으며_탭만으로는_완료되지_않고_활성화하면_카드_이름이_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightPaused1499")
        resumeFromMain(h)
        h.advance(1, times: 2)
        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        confirmBriefing(h)

        for id in ["journey.timer.pause", "journey.timer.resume", "journey.abandon"] {
            XCTAssertFalse(h.element(id).exists, id)
        }
        XCTAssertEqual(try jsonDiagnostic(h, "test.alighting")["focus"] as? String, "card")
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)
        let before = try h.writeAttempts()
        let card = h.element("alighting.card")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        card.tap()
        let hint = h.element("alighting.tapHint")
        XCTAssertTrue(hint.waitForExistence(timeout: timeout), "터치 뒤 안내가 없음")
        // 시안 R28: 하차 화면은 안내 문구를 늘 보인다.
        XCTAssertTrue(hint.label.contains("카드를 위의 단말기로 올려주세요"), hint.label)
        XCTAssertEqual(try h.writeAttempts(), before)
        XCTAssertTrue(h.element("alighting.tag").exists)
        XCTAssertFalse(h.element("screen.alightingSummary").exists)

        activateCard(h)

        XCTAssertTrue(h.waitForValue("alighting.lcdStatus", "집중동행카드"), h.value("alighting.lcdStatus") ?? "nil")
        XCTAssertFalse(h.app.staticTexts["하차 완료"].exists)
        XCTAssertFalse(h.element("alighting.lcdStatus").label.contains("하차 완료"))
    }

    // MARK: ② 하차 → 요약 → 메인 (AC-5, 10, 15, 17)

    // 깨짐: 요약이 할 일·시간·도착지를 보이지 않거나, 메모 저장 뒤 기록이 1건·메모가 아니거나,
    // 여정이 남거나 현재 정류장이 도착지로 바뀌지 않거나 Live Activity가 남는다.
    func testAC5_10_15_17_하차하면_요약을_보이고_메모와_함께_완료하면_기록_1건이_저장되고_메인으로_돌아온다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        openAlighting(h)
        confirmBriefing(h)

        activateCard(h)

        XCTAssertTrue(h.element("screen.alightingSummary").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.element("summary.task").label, "논문")
        XCTAssertEqual(h.element("summary.minutes").label, "25 min")
        XCTAssertEqual(h.element("summary.destination").label, "서울숲 입구")

        let memo = h.element("summary.memo")
        XCTAssertTrue(memo.waitForExistence(timeout: timeout))
        memo.tap()
        memo.typeText("집중 잘됨")
        h.tap("summary.home")

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.persistedCurrentStation().id, "seoulForestGate")
        XCTAssertEqual(try h.persistedRecordCount(), 1)
        XCTAssertTrue(try persistedMemoText(h).contains("집중 잘됨"))
        XCTAssertEqual(activeLiveActivities(h), 0)
    }

    // MARK: ③ 동작 줄이기 (AC-2, 3)

    // 깨짐: 동작 줄이기에서 문장이 순차로만 나오거나 확인이 지연된다.
    func testAC2_동작_줄이기에서는_세_문장과_확인이_즉시_함께_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightPaused1499", extraArguments: reduceMotion)
        resumeFromMain(h)

        h.advance(1, times: 2)

        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("alighting.confirm").waitForExistence(timeout: 1))
        let diag = try briefing(h)
        XCTAssertEqual(diag["showsAll"] as? Bool, true)
        XCTAssertEqual(diag["showsConfirm"] as? Bool, true)
        let label = h.element("alighting.sentence").label
        for sentence in sentences {
            XCTAssertTrue(label.contains(sentence), "문장 누락: \(sentence) / \(label)")
        }
    }

    // 깨짐: 도착이 저장되지 않거나(1500 아님), 쓰기가 1회가 아니거나, 도착만으로 기록이 생긴다.
    func testAC3_도착하면_저장본은_도착_상태이고_쓰기는_1회이며_기록은_0건이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightPaused1499", extraArguments: reduceMotion)
        resumeFromMain(h)
        let before = try h.writeAttempts()

        h.advance(1, times: 2)
        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.persistedElapsed(), 1500)
        XCTAssertEqual(try h.writeAttempts(), before + 1)
        XCTAssertEqual(try h.persistedRecordCount(), 0)
    }

    // MARK: ④ 복원 (AC-4, 13, 14, 21)

    // 깨짐: 도착 카드에 새 여정 시작이 남거나 하차하기가 없다.
    func testAC21_도착_여정_카드에는_하차하기만_있고_새_여정_시작은_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")

        let alight = h.app.buttons["open.alighting"]
        XCTAssertTrue(alight.waitForExistence(timeout: timeout))
        XCTAssertEqual(alight.label, "하차하기")
        XCTAssertFalse(h.element("open.preparation").exists)
        XCTAssertFalse(h.app.buttons["새 여정 시작"].exists)
        XCTAssertFalse(h.app.buttons["이어가기"].exists)
        XCTAssertFalse(h.element("main.resumeJourney").exists)
    }

    // 깨짐: 안내 중 재실행 후 안내가 처음부터 다시 시작하지 않는다.
    func testAC4_안내_중_재실행하면_메인에서_하차하기로_안내를_처음부터_다시_본다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        openAlighting(h)
        XCTAssertTrue(h.element("alighting.confirm").waitForExistence(timeout: briefingTimeout))
        XCTAssertEqual(try briefing(h)["showsConfirm"] as? Bool, true)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        openAlighting(h)
        // 확인을 이미 본 뒤 재실행했는데 다시 확인 없이 시작한다 = 처음부터. 이후 다시 확인이 나온다.
        XCTAssertEqual(try briefing(h)["showsConfirm"] as? Bool, false)
        XCTAssertFalse(h.element("alighting.confirm").exists)
        XCTAssertTrue(h.element("alighting.confirm").waitForExistence(timeout: briefingTimeout))
    }

    // 깨짐: 하차 태그에서 재실행했을 때 기록이 생기거나 하차하기로 복귀하지 못한다.
    func testAC14_하차_태그에서_재실행하면_기록_없이_메인_하차하기로_돌아온다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        openAlighting(h)
        confirmBriefing(h)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.app.buttons["open.alighting"].waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedRecordCount(), 0)
    }

    // 깨짐: 요약에서 재실행하면 요약이 복원되거나 기록이 사라진다(요약은 메모리 전용).
    func testAC13_요약에서_재실행하면_메인으로_돌아오고_기록은_1건_요약은_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        toSummary(h)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.alightingSummary").exists)
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertEqual(try h.persistedRecordCount(), 1)
        XCTAssertEqual(try h.recordCount(), 1)
    }

    // MARK: ⑤ 실패 (AC-12, 18, 20)

    // 깨짐: 하차 저장 실패에 태그 화면을 떠나거나, 실패 문구가 없거나, 기록·현재 정류장·여정이 바뀐다.
    func testAC12_하차_저장_실패는_태그_화면에_남고_상태를_바꾸지_않으며_다시_하면_요약으로_간다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        openAlighting(h)
        confirmBriefing(h)

        h.tap("test.alighting.failNextSave")
        activateCard(h)

        let failure = h.element("alighting.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, saveFailureText)
        XCTAssertTrue(h.element("alighting.tag").exists)
        XCTAssertFalse(h.element("screen.alightingSummary").exists)
        XCTAssertEqual(try h.persistedRecordCount(), 0)
        XCTAssertEqual(try h.persistedCurrentStation().id, "seongsu")
        XCTAssertNotNil(try h.persistedJourney().active)

        activateCard(h)

        XCTAssertTrue(h.element("screen.alightingSummary").waitForExistence(timeout: timeout))
    }

    // 깨짐: 메모 길이 상한(200)이 없거나 카운터가 200 / 200이 아니다.
    func testAC18_메모에_201자를_붙여넣으면_200자로_잘리고_카운터는_200_200이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        toSummary(h)

        let memo = h.element("summary.memo")
        XCTAssertTrue(memo.waitForExistence(timeout: timeout))
        memo.tap()
        memo.typeText(String(repeating: "가", count: 201))

        XCTAssertEqual((memo.value as? String)?.count, 200)
        XCTAssertEqual(h.element("summary.memoCounter").label, "200 / 200")
    }

    // 깨짐: 요약 저장 실패에 메인으로 가거나, 입력이 지워지거나, 실패 문구가 없다.
    func testAC20_요약_저장_실패는_요약에_남고_입력을_보존하며_다시_하면_메인으로_간다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightArrived")
        toSummary(h)
        h.tap("test.summary.failNextSave")
        let memo = h.element("summary.memo")
        XCTAssertTrue(memo.waitForExistence(timeout: timeout))
        memo.tap()
        memo.typeText("집중 잘됨")
        // 키보드가 메인으로 버튼을 가리면 화면 윗부분을 눌러 내린다.
        if h.app.keyboards.count > 0 {
            h.element("screen.alightingSummary").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
        }

        h.tap("summary.home")

        let failure = h.element("summary.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, saveFailureText)
        XCTAssertTrue(h.element("screen.alightingSummary").exists)
        XCTAssertFalse(h.element("screen.main").exists)
        XCTAssertEqual(memo.value as? String, "집중 잘됨")

        h.tap("summary.home")

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedRecordCount(), 1)
    }

    // MARK: ⑥ 지도 생략 (AC-23)

    // 깨짐: 계산 도착지와 저장 도착지가 다른데 지도가 그려지거나 지도 도구가 눌릴 수 있다.
    func testAC23_도착지가_계산과_다르면_지도와_지도_도구_없이_확인만_보인다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightMismatchArrived")
        openAlighting(h)

        XCTAssertTrue(h.element("alighting.confirm").waitForExistence(timeout: briefingTimeout))
        XCTAssertFalse(h.element("journey.map").exists)
        XCTAssertFalse(h.element("test.map").exists)
        for id in ["journey.map.follow", "journey.map.theme"] {
            let tool = h.element(id)
            XCTAssertTrue(!tool.exists || !tool.isEnabled, "지도 도구가 눌릴 수 있음: \(id)")
        }
    }

    // 깨짐(AC-79): 하차 뒤 현재 정류장이 계산 값이나 출발지가 되어 저장된 도착 정류장(ttukseom/뚝섬역)과 달라진다.
    func testAC79_하차하면_현재_정류장은_저장된_도착_정류장이다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "alightMismatchArrived")
        toSummary(h)

        h.tap("summary.home")

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedCurrentStation().id, "ttukseom")
        XCTAssertEqual(h.element("main.currentStation").value as? String, "뚝섬역")
    }
}
