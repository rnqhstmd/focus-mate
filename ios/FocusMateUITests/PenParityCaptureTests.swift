import Foundation
import XCTest

/// Pen 시안(R01~R42)과 1:1로 대조할 현재 앱 화면을 캡처한다. 기능 검증이 아니라 수집 도구다.
/// 파일 이름 = 시안 이름. 저장 위치는 `TEST_RUNNER_FM_PEN_CAPTURE_DIR`(러너에는 `FM_PEN_CAPTURE_DIR`)로 바꿀 수 있다.
/// 앱에 없는 화면(R14·R21·R22·R25)은 메서드를 두지 않는다 — INDEX.md 참고.
@MainActor
final class PenParityCaptureTests: XCTestCase {
    private let timeout: TimeInterval = 8
    private let briefingTimeout: TimeInterval = 15
    private static let defaultDirectory =
        "/private/tmp/claude-501/-Users-bonseung-projects-focus-mate/14fef95d-d406-4015-b86e-eb6e4d215e53/scratchpad/app"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - 공용

    private var outputDirectory: URL {
        URL(fileURLWithPath: ProcessInfo.processInfo.environment["FM_PEN_CAPTURE_DIR"] ?? Self.defaultDirectory,
            isDirectory: true)
    }

    /// 애니메이션이 끝나도록 1초 기다린 뒤 전체 화면을 PNG로 저장하고 첨부한다.
    private func capture(_ name: String, settle: TimeInterval = 1.0) {
        Thread.sleep(forTimeInterval: settle)
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        do {
            try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            try shot.pngRepresentation.write(to: outputDirectory.appendingPathComponent(name + ".png"), options: .atomic)
        } catch {
            XCTFail("캡처 저장 실패 \(name): \(error)")
        }
    }

    private func wait(_ h: FocusMateUIHarness, _ id: String, timeout: TimeInterval? = nil) {
        XCTAssertTrue(h.element(id).waitForExistence(timeout: timeout ?? self.timeout), "Missing: \(id)")
    }

    /// 보이지 않으면 위로 밀어 닿게 한 뒤 누른다.
    private func tapReaching(_ h: FocusMateUIHarness, _ id: String) {
        let target = h.element(id)
        XCTAssertTrue(target.waitForExistence(timeout: timeout), "Missing: \(id)")
        var attempts = 0
        while !target.isHittable && attempts < 6 {
            if id.hasPrefix("preparation.tag.") || id == "preparation.addTag" {
                h.app.scrollViews["preparation.tags"].swipeLeft()
            } else {
                h.app.swipeUp()
            }
            attempts += 1
        }
        target.tap()
    }

    private func dismissKeyboardWithReturn(_ field: XCUIElement) {
        field.typeText("\n")
    }

    // MARK: 경로 도우미

    /// `TEST_RUNNER_FM_ROUTE_SHAPE=live`면 노선선을 실제 Apple 길찾기로 받는다(기본은 네트워크 없는 곧은 선).
    private var routeShapeArguments: [String] {
        ProcessInfo.processInfo.environment["FM_ROUTE_SHAPE"] == "live" ? ["--fm-ui-route-shape", "live"] : []
    }

    /// cardOnly 시드: 최초 정류장 검색 화면.
    private func launchFirstUse() -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: "cardOnly", extraArguments: routeShapeArguments)
        wait(h, "screen.initialStationEntry")
        return h
    }

    /// 최초 정류장 "성수역"으로 검색해 성수역(seongsu, 성수동 방면)을 고른 상태.
    /// "성수"(8건)로 치면 결과 선택 때 목록이 스크롤돼 검색칸이 화면 밖으로 밀린다.
    private func searchAndSelectSeongsu(_ h: FocusMateUIHarness) {
        let field = h.element("search.query")
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText("성수역")
        let result = h.element("search.result.seongsu")
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        dismissKeyboardWithReturn(field)
        result.tap()
        wait(h, "search.confirmation")
    }

    /// cardOnly → 성수역 확정 → 시간 선택(기본 25분).
    private func openFirstTimeScreen() -> FocusMateUIHarness {
        let h = launchFirstUse()
        searchAndSelectSeongsu(h)
        h.element("search.confirm").tap()
        wait(h, "screen.time")
        return h
    }

    /// ready 시드 → 여행 시작하기 → 60분 → 2014-r → 준비 화면.
    private func openPreparation(extra: [String] = []) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: extra + routeShapeArguments)
        wait(h, "screen.main")
        enterPreparationFromMain(h)
        return h
    }

    private func enterPreparationFromMain(_ h: FocusMateUIHarness) {
        h.app.buttons["open.preparation"].tap()
        wait(h, "screen.time")
        h.app.setJourneyMinutes(60, timeout: timeout)
        tapReaching(h, "time.candidate.2014-r")
        tapReaching(h, "time.proceed")
        wait(h, "screen.preparation")
    }

    /// 독서 태그 + "책 한 챕터 읽기" 입력 후 키보드를 내린다.
    private func fillPreparation(_ h: FocusMateUIHarness) {
        tapReaching(h, "preparation.tag.reading")
        let field = h.element("preparation.task")
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText("책 한 챕터 읽기")
        dismissKeyboardWithReturn(field)
    }

    private func confirmPreparation(_ h: FocusMateUIHarness) {
        tapReaching(h, "preparation.confirm")
        wait(h, "screen.board")
    }

    private func boardBus(_ h: FocusMateUIHarness) {
        let board = h.app.buttons["board.boardBus"]
        XCTAssertTrue(board.waitForExistence(timeout: timeout))
        board.tap()
        wait(h, "screen.boarding")
    }

    private func waitTagPhase(_ h: FocusMateUIHarness, _ diagnostic: String, _ expected: String) {
        let ok = h.waitUntil(timeout: timeout) {
            guard let raw = h.value(diagnostic),
                  let object = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else { return false }
            return object["phase"] as? String == expected
        }
        XCTAssertTrue(ok, "\(diagnostic) phase가 \(expected)가 아님: \(h.value(diagnostic) ?? "nil")")
    }

    /// 진행 여정 시드로 여행 화면을 바로 연다(실시간 시계 — 수동 시계의 검은 테스트 버튼을 피한다).
    private func launchJourneyScreen(seed: String) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: seed, extraArguments: ["--fm-ui-route", "journey"] + routeShapeArguments)
        wait(h, "screen.journey")
        return h
    }

    /// alightArrived 시드: 메인 → 하차하기 → 도착 안내 확인 → 하차 태그 화면.
    private func openAlightingTag(extra: [String] = []) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: "alightArrived", extraArguments: extra)
        let open = h.app.buttons["open.alighting"]
        XCTAssertTrue(open.waitForExistence(timeout: timeout))
        open.tap()
        wait(h, "alighting.briefing")
        let confirm = h.element("alighting.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: briefingTimeout))
        confirm.tap()
        wait(h, "alighting.tag")
        return h
    }

    private func openSummary() -> FocusMateUIHarness {
        let h = openAlightingTag()
        h.tap("test.activateAlightingCard")
        wait(h, "screen.alightingSummary")
        return h
    }

    private func openRecords(seed: String) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: seed)
        wait(h, "screen.main")
        h.tap("open.records")
        wait(h, "screen.records")
        return h
    }

    private func openCustomization(manifest: String? = "valid2") -> FocusMateUIHarness {
        var extra: [String] = []
        if let manifest { extra = ["--fm-ui-card-photo-manifest", "FocusMate/UITestPhotoFixtures/\(manifest).json"] }
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: extra)
        wait(h, "screen.main")
        h.tap("open.profile")
        wait(h, "screen.profile")
        tapReaching(h, "profile.customize")
        wait(h, "screen.cardCustomization")
        return h
    }

    /// 사진 2장을 넣고 배경을 sand로 바꾼 꾸미기 상태.
    private func decorateCard(_ h: FocusMateUIHarness) {
        h.tap("test.cardImportFixture")
        let imported = h.waitUntil(timeout: timeout) {
            guard let raw = h.value("test.cardStyleJSON"),
                  let object = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
                  let draft = object["draft"] as? [String: Any],
                  let photos = draft["photos"] as? [Any] else { return false }
            return photos.count == 2 && (object["isImporting"] as? Bool) == false
        }
        XCTAssertTrue(imported, "사진 2장 입력이 끝나지 않음")
        tapReaching(h, "cardCustomization.color.sand")
    }

    private func saveCustomization(_ h: FocusMateUIHarness) {
        h.tap("cardCustomization.save")
        wait(h, "screen.profile")
        XCTAssertTrue(h.waitUntil(timeout: timeout) { !h.element("screen.cardCustomization").exists })
    }

    // MARK: - R01~R06 메인·최초 이용·시간

    func testR01_main() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        wait(h, "screen.main")
        _ = h.app.waitForBound("성동구민체육센터 방면")
        capture("R01-main")
    }

    func testR02_first() {
        _ = launchFirstUse()
        capture("R02-first")
    }

    func testR03_search() {
        let h = launchFirstUse()
        searchAndSelectSeongsu(h)
        capture("R03-search")
    }

    func testR04_searchTime() {
        _ = openFirstTimeScreen()
        capture("R04-search-time")
    }

    func testR05_noCandidate() {
        let h = openFirstTimeScreen()
        h.app.setJourneyMinutes(17, timeout: timeout)
        XCTAssertEqual(h.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "time.candidate.")).count, 0)
        capture("R05-no-candidate")
    }

    func testR26_timeBefore() {
        let h = openFirstTimeScreen()
        h.app.setJourneyMinutes(120, timeout: timeout)
        wait(h, "time.candidate.302")
        capture("R26-time-before")
    }

    func testR06_timeDest() {
        let h = openFirstTimeScreen()
        h.app.setJourneyMinutes(120, timeout: timeout)
        tapReaching(h, "time.candidate.2014")
        capture("R06-time-dest")
    }

    // MARK: - R07~R12, R27 준비·승차

    func testR07_prepare() {
        _ = openPreparation()
        capture("R07-prepare")
    }

    func testR08_prepareFilled() {
        let h = openPreparation()
        fillPreparation(h)
        capture("R08-prepare-filled")
    }

    func testR09_newTag() {
        let h = openPreparation()
        tapReaching(h, "preparation.addTag")
        wait(h, "tagEditor.name")
        capture("R09-new-tag")
    }

    func testR10_sound() {
        let h = openPreparation()
        tapReaching(h, "preparation.sound")
        wait(h, "sound.save")
        capture("R10-sound")
    }

    func testR11_boardingPass() {
        let h = openPreparation()
        fillPreparation(h)
        confirmPreparation(h)
        capture("R11-boarding-pass")
    }

    func testR27_boardTag() {
        let h = openPreparation()
        fillPreparation(h)
        confirmPreparation(h)
        boardBus(h)
        capture("R27-board-tag")
    }

    func testR12_boardingDone() {
        let h = openPreparation(extra: ["--fm-ui-boarding-hold", "manual"])
        fillPreparation(h)
        confirmPreparation(h)
        boardBus(h)
        h.tap("test.activateBoardingCard")
        waitTagPhase(h, "test.boarding", "held")
        capture("R12-boarding-done")
    }

    // MARK: - R13, R15, R16, R33 여행

    func testR13_focusMap() {
        let h = launchJourneyScreen(seed: "lifePaused600")
        h.tap("journey.timer.resume")
        wait(h, "journey.timer.pause")
        capture("R13-focus-map", settle: 2.0)
    }

    func testR15_paused() {
        let h = launchJourneyScreen(seed: "lifePaused600")
        wait(h, "journey.timer.resume")
        capture("R15-paused", settle: 2.0)
    }

    func testR16_endConfirm() {
        let h = launchJourneyScreen(seed: "lifePaused600")
        h.tap("journey.abandon")
        XCTAssertTrue(h.element("journey.abandon.dialog").waitForExistence(timeout: timeout), "그만두기 확인 창 없음")
        capture("R16-end-confirm")
    }

    func testR33_resumed() {
        let h = FocusMateUIHarness.launch(seed: "lifePaused600")
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        resume.tap()
        wait(h, "journey.timer.pause")
        capture("R33-resumed", settle: 2.0)
    }

    // MARK: - R28~R30, R17, R18 하차

    func testR28_alightTag() {
        _ = openAlightingTag()
        capture("R28-alight-tag")
    }

    func testR29_alightDone() {
        let h = openAlightingTag(extra: ["--fm-ui-boarding-hold", "manual"])
        h.tap("test.activateAlightingCard")
        waitTagPhase(h, "test.alighting", "held")
        capture("R29-alight-done")
    }

    func testR17_summary() {
        _ = openSummary()
        capture("R17-summary")
    }

    func testR30_summaryMemo() {
        let h = openSummary()
        let memo = h.element("summary.memo")
        XCTAssertTrue(memo.waitForExistence(timeout: timeout))
        memo.tap()
        memo.typeText("좋은 문장을 발견했어요.\n내일은 다음 챕터부터 이어가기.")
        // 시안처럼 키보드 없이: 요약 스크롤(scrollDismissesKeyboard .interactively)을 키보드 쪽으로 끌어 내린다.
        if h.app.keyboards.firstMatch.exists {
            h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                .press(forDuration: 0.05, thenDragTo: h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        }
        capture("R30-summary-memo")
    }

    func testR18_homeAfter() {
        let h = openSummary()
        h.tap("summary.home")
        wait(h, "screen.main")
        XCTAssertTrue(h.waitForValue("main.currentStation", "서울숲 입구"))
        capture("R18-home-after")
    }

    // MARK: - R31, R32, R34 진행 여정이 있는 메인

    func testR31_resumePrev() {
        let h = FocusMateUIHarness.launch(seed: "lifePaused600")
        wait(h, "main.activeJourney")
        capture("R31-resume-prev")
    }

    func testR32_newConfirm() {
        let h = FocusMateUIHarness.launch(seed: "lifePaused600")
        wait(h, "main.activeJourney")
        h.app.buttons["open.preparation"].tap()
        wait(h, "main.newJourney.dialog")
        capture("R32-new-confirm")
    }

    func testR34_alightResume() {
        let h = FocusMateUIHarness.launch(seed: "alightArrived")
        wait(h, "open.alighting")
        capture("R34-alight-resume")
    }

    // MARK: - R19, R20, R23, R24 기록·설정

    func testR19_records() {
        _ = openRecords(seed: "recordsMemo")
        capture("R19-records")
    }

    func testR20_settings() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        wait(h, "screen.main")
        h.tap("open.profile")
        wait(h, "screen.profile")
        tapReaching(h, "profile.settings")
        wait(h, "screen.settings")
        capture("R20-settings")
    }

    func testR23_analytics() {
        let h = openRecords(seed: "analytics")
        h.tap("records.analytics.open")
        wait(h, "screen.analytics")
        capture("R23-analytics")
    }

    func testR24_analyticsEmpty() {
        let h = openRecords(seed: "ready")
        h.tap("records.analytics.open")
        wait(h, "screen.analytics")
        capture("R24-analytics-empty")
    }

    // MARK: - R35~R37 카드 발급

    func testR35_issue() {
        let h = FocusMateUIHarness.launch(seed: "none")
        wait(h, "card.issueButton")
        capture("R35-issue")
    }

    func testR36_issuing() {
        let h = FocusMateUIHarness.launch(seed: "none", hold: "manual")
        let button = h.element("card.issueButton")
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()
        XCTAssertTrue(h.waitUntil(timeout: timeout) { button.label == "카드를 발급하고 있어요" })
        capture("R36-issuing")
    }

    func testR37_issued() {
        let h = FocusMateUIHarness.launch(seed: "none", hold: "manual")
        h.tap("card.issueButton")
        h.tap("test.releaseIssuance")
        wait(h, "card.continueButton")
        capture("R37-issued")
    }

    // MARK: - R38~R42 마이페이지·카드 꾸미기

    func testR38_profile() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        wait(h, "screen.main")
        h.tap("open.profile")
        wait(h, "screen.profile")
        capture("R38-profile")
    }

    func testR39_studio() {
        _ = openCustomization()
        capture("R39-studio")
    }

    func testR40_studioPhotos() {
        let h = openCustomization()
        decorateCard(h)
        capture("R40-studio-photos")
    }

    func testR41_profileCustom() {
        let h = openCustomization()
        decorateCard(h)
        saveCustomization(h)
        // 시안 R41에는 저장 안내 띠가 없다. 띠는 몇 초 뒤 스스로 사라진다.
        XCTAssertTrue(h.waitUntil(timeout: timeout) { !h.element("cardCustomization.savedNotice").exists }, "저장 안내 띠가 사라지지 않음")
        capture("R41-profile-custom")
    }

    func testR42_boardCustom() {
        let h = openCustomization()
        decorateCard(h)
        saveCustomization(h)
        h.app.navigationBars.buttons.firstMatch.tap()
        wait(h, "screen.main")
        enterPreparationFromMain(h)
        fillPreparation(h)
        confirmPreparation(h)
        boardBus(h)
        capture("R42-board-custom")
    }
}
