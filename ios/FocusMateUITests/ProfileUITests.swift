import Foundation
import XCTest

@MainActor
final class ProfileUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - 진입·구성

    // 깨짐 명명: open.profile 탭이 마이페이지로 이동하지 않거나 제목이 "마이페이지"가 아니면 실패
    func testAC1_메인에서_마이페이지로_진입하면_제목이_마이페이지다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        let screen = openProfile(h)
        XCTAssertEqual(screen.label, "마이페이지")
    }

    // 깨짐 명명: 요소 순서가 바뀌거나 한 요소라도 빠지면 실패
    func testAC2_마이페이지_요소는_설계_순서대로_위에서_아래로_배치된다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let ids = [
            "screen.profile", "profile.headline", "profile.subhead", "profile.card",
            "profile.cardName", "profile.cardTagline", "profile.customize",
            "profile.stat.journeys", "profile.stat.time", "profile.settings"
        ]
        var frames: [(String, CGFloat, CGFloat)] = []
        for id in ids {
            let e = h.element(id)
            XCTAssertTrue(e.waitForExistence(timeout: timeout), "없음: \(id)")
            frames.append((id, e.frame.minY.rounded(), e.frame.minX))
        }
        // 통계 두 칸은 같은 행(minY 1pt 이내)일 수 있으므로 같은 행이면 minX로 비교
        for i in 1..<frames.count {
            let prev = frames[i - 1], cur = frames[i]
            let sameRow = abs(prev.1 - cur.1) <= 1
            let ordered = sameRow ? prev.2 <= cur.2 : prev.1 < cur.1
            XCTAssertTrue(ordered, "순서 위반: \(prev.0)(\(prev.1),\(prev.2)) -> \(cur.0)(\(cur.1),\(cur.2))")
        }
    }

    // 깨짐 명명: 헤드라인·서브헤드 문구가 달라지면 실패
    func testAC3_헤드라인과_서브헤드_문구가_설계와_같다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.headline").label, "내 시간에, 내 취향을.")
        XCTAssertEqual(h.element("profile.subhead").label, "한 장으로 함께하는 나만의 여정")
    }

    // 깨짐 명명: 카드 이름·태그라인 문구가 달라지면 실패
    func testAC4_카드_이름과_태그라인_문구가_설계와_같다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.cardName").label, "집중동행카드")
        XCTAssertEqual(h.element("profile.cardTagline").label, "모든 몰입 여정에 함께")
    }

    // 깨짐 명명: 통계 칸 접근성 라벨에 항목 이름이 빠지면 실패
    func testAC4_통계_칸_라벨에_항목_이름이_들어_있다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertTrue(h.element("profile.stat.journeys").label.contains("완료한 여정"))
        XCTAssertTrue(h.element("profile.stat.time").label.contains("함께한 시간"))
    }

    // 깨짐 명명: 카드 접근성 라벨이 "집중동행카드"가 아니거나 카드 번호(FM-)가 노출되면 실패
    func testAC19_카드_접근성_라벨은_집중동행카드이고_카드번호를_노출하지_않는다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        let card = h.element("profile.card")
        XCTAssertTrue(card.exists)
        XCTAssertTrue(card.label.contains("집중동행카드"))
        XCTAssertFalse(card.label.contains("FM-"))
    }

    // 깨짐 명명: 화면 어디에든 카드 번호(FM-)가 label/value로 노출되면 실패
    func testAC6_마이페이지_화면_어디에도_카드번호가_보이지_않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        XCTAssertTrue(h.element("profile.settings").waitForExistence(timeout: timeout))
        let root = try h.app.snapshot()
        var texts: [String] = []
        collect(root, into: &texts)
        XCTAssertFalse(texts.isEmpty, "수집된 텍스트가 없음")
        XCTAssertTrue(texts.filter { $0.contains("FM-") }.isEmpty, "카드번호 노출: \(texts.filter { $0.contains("FM-") })")
    }

    // MARK: - 통계 값

    // 깨짐 명명: 기록 0건에서 0/0 min이 아니거나 오류가 표시되면 실패
    func testAC8_기록이_없으면_통계가_0과_0분이고_오류가_없다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.stat.journeys.value").label, "0")
        XCTAssertEqual(h.element("profile.stat.time.value").label, "0 min")
        XCTAssertFalse(h.element("profile.statsError").exists)
    }

    // 깨짐 명명: 기록 3건(65분) 집계가 틀리거나 값에 한국어 단위가 섞이면 실패
    func testAC9_22_기록_3건은_3과_1h_5min으로_단위_없이_표시된다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        let journeys = h.element("profile.stat.journeys.value").label
        let time = h.element("profile.stat.time.value").label
        XCTAssertEqual(journeys, "3")
        XCTAssertEqual(time, "1 h 5 min")
        for text in [journeys, time] {
            XCTAssertFalse(text.contains("분"))
            XCTAssertFalse(text.contains("시간"))
        }
    }

    // 깨짐 명명: 통계 칸 접근성 라벨이 한국어 단위 문장("3회", "1시간 5분")이 아니면 실패
    func testAC18_통계_칸_접근성_라벨은_한국어_단위로_읽힌다() {
        let h = FocusMateUIHarness.launch(seed: "profileRecords")
        _ = openProfile(h)
        XCTAssertEqual(h.element("profile.stat.journeys").label, "완료한 여정, 3회")
        XCTAssertEqual(h.element("profile.stat.time").label, "함께한 시간, 1시간 5분")
    }

    // 깨짐 명명: 정상 집계인데 오류 안내가 표시되면 실패
    func testAC32_정상_집계에서는_통계_오류가_없다() {
        for seed in ["ready", "profileRecords"] {
            let h = FocusMateUIHarness.launch(seed: seed)
            _ = openProfile(h)
            XCTAssertTrue(h.element("profile.settings").waitForExistence(timeout: timeout))
            XCTAssertFalse(h.element("profile.statsError").exists, "seed=\(seed)")
            h.app.terminate()
        }
    }

    // MARK: - 읽기 전용·내비게이션

    // 깨짐 명명: 마이페이지가 열려 있는 동안 저장 파일을 바꾸면(쓰기 발생) 실패
    func testAC15_마이페이지를_열어도_저장_데이터는_바뀌지_않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("open.profile").waitForExistence(timeout: timeout))
        let before = try h.diagnostic("test.persistedBytes")
        _ = openProfile(h)
        let result = XCTWaiter().wait(for: [XCTestExpectation(description: "idle")], timeout: 3)
        XCTAssertEqual(result, .timedOut)
        backButton(h).tap()
        XCTAssertTrue(h.element("open.profile").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), before)
    }

    // 깨짐 명명: 뒤로 버튼이 마이페이지를 닫지 않거나 메인 진입점이 복구되지 않으면 실패
    func testAC16_뒤로를_누르면_메인으로_돌아와_마이페이지_진입점이_눌린다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        backButton(h).tap()
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.profile").exists)
        XCTAssertTrue(entry.isHittable)
    }

    // 깨짐 명명: customize/settings를 버튼으로 노출하지 않거나 라벨·탭 가능 상태가 틀리면 실패
    func testAC23_카드_꾸미기와_설정은_눌리는_버튼으로_노출된다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let customize = h.app.buttons["profile.customize"]
        let settings = h.app.buttons["profile.settings"]
        XCTAssertTrue(customize.waitForExistence(timeout: timeout))
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        XCTAssertEqual(customize.label, "카드 꾸미기")
        XCTAssertEqual(settings.label, "설정")
        XCTAssertTrue(customize.isHittable)
        XCTAssertTrue(settings.isHittable)
    }

    // 깨짐 명명: 카드 꾸미기 탭이 카드 스튜디오로 이동하지 않으면 실패
    func testAC24_카드_꾸미기를_누르면_카드_스튜디오가_열린다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.customize").tap()
        let studio = h.element("screen.cardStudio")
        XCTAssertTrue(studio.waitForExistence(timeout: timeout))
        XCTAssertEqual(studio.label, "카드 꾸미기")
    }

    // 깨짐 명명: 카드 스튜디오에서 뒤로가 마이페이지로 복귀시키지 않으면 실패
    func testAC25_카드_스튜디오에서_뒤로가면_마이페이지로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.customize").tap()
        XCTAssertTrue(h.element("screen.cardStudio").waitForExistence(timeout: timeout))
        backButton(h).tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardStudio").exists)
    }

    // 깨짐 명명: 설정 탭이 설정 화면으로 이동하지 않으면 실패
    func testAC26_설정을_누르면_설정_화면이_열린다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.settings").tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
    }

    // 깨짐 명명: 설정에서 뒤로가 마이페이지로 복귀시키지 않으면 실패
    func testAC27_설정에서_뒤로가면_마이페이지로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        h.element("profile.settings").tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
        backButton(h).tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    // 깨짐 명명: 내비 버튼이 뒤로 외에 더 있거나 본문 버튼이 customize/settings 2개가 아니면 실패
    func testAC23_마이페이지의_버튼_구성은_뒤로와_카드꾸미기와_설정뿐이다() {
        let h = FocusMateUIHarness.launch(seed: "ready")
        _ = openProfile(h)
        let nav = h.app.navigationBars.firstMatch
        XCTAssertTrue(nav.waitForExistence(timeout: timeout))
        XCTAssertEqual(nav.buttons.count, 1)
        XCTAssertEqual(h.app.buttons.count, 3)
    }

    // MARK: - 최대 글자 크기

    // 깨짐 명명: 큰 글자에서 주요 요소가 스크롤해도 가시 영역에 완전히 들어오지 않으면 실패
    func testAC20_최대_글자_크기에서_주요_요소가_스크롤로_가시_영역에_들어온다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: xxxl)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")
        entry.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))

        let navMaxY = h.app.navigationBars.firstMatch.frame.maxY
        let windowMaxY = h.app.windows.firstMatch.frame.maxY
        for id in ["profile.card", "profile.customize", "profile.stat.journeys", "profile.stat.time", "profile.settings"] {
            let target = h.element(id)
            XCTAssertTrue(target.waitForExistence(timeout: timeout), "없음: \(id)")
            var swipes = 0
            while !(target.frame.minY >= navMaxY && target.frame.maxY <= windowMaxY) && swipes < 3 {
                h.app.swipeUp()
                swipes += 1
            }
            XCTAssertGreaterThanOrEqual(target.frame.minY, navMaxY, "\(id) 위쪽이 내비바에 가림")
            XCTAssertLessThanOrEqual(target.frame.maxY, windowMaxY, "\(id) 아래쪽이 화면 밖")
        }
    }

    // 깨짐 명명: 큰 글자에서 설정 버튼 탭이 설정 화면을 열지 못하면 실패
    func testAC20_최대_글자_크기에서_설정을_눌러_설정에_가고_뒤로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: xxxl)
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")
        entry.tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        let settings = h.element("profile.settings")
        XCTAssertTrue(settings.waitForExistence(timeout: timeout))
        var swipes = 0
        while !settings.isHittable && swipes < 3 {
            h.app.swipeUp()
            swipes += 1
        }
        settings.tap()
        XCTAssertTrue(h.element("screen.settings").waitForExistence(timeout: timeout))
        backButton(h).tap()
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
    }

    // MARK: - Helpers

    private let xxxl = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    @discardableResult
    private func openProfile(_ h: FocusMateUIHarness) -> XCUIElement {
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout), "open.profile 없음")
        entry.tap()
        let screen = h.element("screen.profile")
        XCTAssertTrue(screen.waitForExistence(timeout: timeout), "screen.profile 없음")
        return screen
    }

    private func backButton(_ h: FocusMateUIHarness) -> XCUIElement {
        h.app.navigationBars.firstMatch.buttons.firstMatch
    }

    private func collect(_ node: XCUIElementSnapshot, into texts: inout [String]) {
        if !node.identifier.hasPrefix("test.") {
            if !node.label.isEmpty { texts.append(node.label) }
            if let value = node.value as? String, !value.isEmpty { texts.append(value) }
        }
        for child in node.children { collect(child, into: &texts) }
    }
}
