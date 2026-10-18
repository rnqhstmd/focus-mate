import XCTest

@MainActor
final class DataSourceUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let xxxl = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐 명명: 마이페이지 → 설정 안의 진입이 없거나 탭이 데이터 출처로 이동하지 않으면 실패.
    // 시안 R38에는 마이페이지 '데이터 출처' 줄이 없어 설정(settings.dataSource) 안으로 옮겼다(F단계).
    func testAC49_마이페이지에서_데이터출처로_진입하면_제목이_데이터출처다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: ["--fm-ui-route-data", "fixture"])
        let screen = openDataSource(h)
        XCTAssertEqual(screen.label, "데이터 출처")
    }

    // 깨짐 명명: 문구 6종 중 하나라도 빠지거나 값이 달라지면 실패.
    func testAC49_출처_문구_여섯_종이_보인다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: ["--fm-ui-route-data", "fixture"])
        _ = openDataSource(h)

        assertLabel(h, "dataSource.copyright", contains: "서울특별시")
        assertLabel(h, "dataSource.provider", contains: "서울 열린데이터광장")
        assertLabel(h, "dataSource.dataset.0", contains: "서울시버스노선별정류소정보 (OA-1095)")
        assertLabel(h, "dataSource.dataset.1", contains: "서울시버스노선기본정보 (OA-15066)")
        assertLabel(h, "dataSource.license", contains: "공공누리 제1유형")
        assertLabel(h, "dataSource.baseDate", contains: "데이터 기준일 2026.09.02")
    }

    // 깨짐 명명: 원천 주소 둘 또는 가공 고지가 빠지면 실패.
    func testAC49_원천_주소_둘과_가공_문구가_보인다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: ["--fm-ui-route-data", "fixture"])
        _ = openDataSource(h)

        assertLabel(h, "dataSource.url.0", contains: "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do")
        assertLabel(h, "dataSource.url.1", contains: "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do")
        assertLabel(h, "dataSource.processing", contains: "구간 시간과 거리는 원천 데이터를 가공·계산한 값이에요")
    }

    // 깨짐 명명: 큰 글자에서 스크롤 가능한 컨테이너가 아니라 가공 문구가 잘려 닿지 못하면 실패.
    func testAC49_큰_글자에서도_스크롤하면_가공_문구에_닿는다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: ["--fm-ui-route-data", "fixture"] + xxxl)
        _ = openDataSource(h)

        let notice = h.element("dataSource.processing")
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        var swipes = 0
        while !notice.isHittable && swipes < 8 {
            h.app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(notice.isHittable, "가공 문구에 스크롤로 닿지 못함")
    }

    // MARK: - 도우미

    private func assertLabel(_ h: FocusMateUIHarness, _ id: String, contains text: String, file: StaticString = #filePath, line: UInt = #line) {
        let e = h.element(id)
        XCTAssertTrue(e.waitForExistence(timeout: timeout), "없음: \(id)", file: file, line: line)
        XCTAssertTrue(e.label.contains(text), "\(id) 라벨 불일치: \(e.label)", file: file, line: line)
    }

    private func openDataSource(_ h: FocusMateUIHarness) -> XCUIElement {
        let entry = h.element("open.profile")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout), "open.profile 없음")
        entry.tap()
        XCTAssertFalse(h.element("profile.dataSource").exists, "마이페이지에는 데이터 출처 줄이 없어야 한다")
        let settings = h.element("profile.settings")
        XCTAssertTrue(settings.waitForExistence(timeout: timeout), "profile.settings 없음")
        var settingsSwipes = 0
        while !settings.isHittable && settingsSwipes < 8 {
            h.app.swipeUp()
            settingsSwipes += 1
        }
        settings.tap()
        let row = h.element("settings.dataSource")
        XCTAssertTrue(row.waitForExistence(timeout: timeout), "settings.dataSource 없음")
        var swipes = 0
        while !row.isHittable && swipes < 8 {
            h.app.swipeUp()
            swipes += 1
        }
        row.tap()
        let screen = h.element("screen.dataSource")
        XCTAssertTrue(screen.waitForExistence(timeout: timeout), "screen.dataSource 없음")
        return screen
    }
}
