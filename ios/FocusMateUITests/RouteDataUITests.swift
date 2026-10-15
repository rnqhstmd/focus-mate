import Foundation
import XCTest

/// 서울 전체 정류장 데이터 연결의 UI 검증: 사라진 노선·정류장(AC-37~40), 방면 줄과 로딩 차단(AC-41~44), 옛 저장 이전(AC-46~48).
/// 기본 픽스처(`--fm-ui-route-data fixture`)로 열고, 로딩이 끝나지 않는 상태는 `pending`을 쓴다.
@MainActor
final class RouteDataUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let pending = ["--fm-ui-route-data", "pending"]
    private let stationRemovedNotice = "저장된 출발 정류장이 서울 버스 데이터에서 사라져 다시 골라 주세요"
    private let replacedNotice = "정류장 데이터가 서울 전체로 바뀌어 출발 정류장을 다시 골라 주세요"
    private let abandonTitle = "여행을 그만둘까요?"
    private let newJourneyTitle = "새 여정을 시작할까요?"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: helpers

    /// 이어가기 → 일시정지 → 포기 확인까지 진행한다.
    private func abandon(_ h: FocusMateUIHarness) {
        h.tap("main.resumeJourney")
        h.tap("journey.timer.pause")
        h.tap("journey.abandon")
        XCTAssertTrue(h.alert(titled: abandonTitle).waitForExistence(timeout: timeout), "포기 alert 없음")
        let confirm = h.alertButton("journey.abandon.confirm", label: "그만두기")
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()
    }

    private func startNewJourneyAndConfirm(_ h: FocusMateUIHarness) {
        h.tap("open.preparation")
        XCTAssertTrue(h.alert(titled: newJourneyTitle).waitForExistence(timeout: timeout), "새 여정 alert 없음")
        let confirm = h.alertButton("main.newJourney.confirm", label: "새 여정 시작")
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()
    }

    // MARK: AC-37

    // 깨짐: 노선만 사라졌는데 출발 정류장을 잃거나 최초 정류장 화면·재선택 안내로 간다.
    func testAC37_노선이_사라져도_포기하면_출발_정류장에_머물고_안내가_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeRouteGone700")

        abandon(h)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.initialStationEntry").exists)
        XCTAssertFalse(h.element("search.resetNotice").exists)
        XCTAssertEqual(try h.persistedCurrentStation().id, "seongsu")
        XCTAssertNil(try h.persistedJourney().active)
    }

    // MARK: AC-38, AC-39

    // 깨짐: 노선과 출발 정류장이 모두 사라졌는데 정류장을 비우지 않거나, 안내가 없거나, 카드·기록이 바뀐다.
    func testAC38_노선과_출발_정류장이_사라진_여정을_포기하면_최초_정류장_화면과_안내가_나온다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeOriginGone700")
        let records = try h.persistedRecordCount()

        abandon(h)

        let notice = h.element("search.resetNotice")
        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, stationRemovedNotice)
        XCTAssertNil(try h.persistedCurrentStation().id)
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.persistedRecordCount(), records)
        XCTAssertEqual(try h.cardCount(), 1)
    }

    // 깨짐: 새 여정 확정이 포기와 다른 결과(시간 선택으로 이동, 정류장 유지)를 낸다.
    func testAC39_같은_상태에서_새_여정을_확정해도_최초_정류장_화면과_안내가_나온다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeOriginGone700")
        let records = try h.persistedRecordCount()

        startNewJourneyAndConfirm(h)

        let notice = h.element("search.resetNotice")
        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, stationRemovedNotice)
        XCTAssertFalse(h.element("screen.time").exists)
        XCTAssertNil(try h.persistedCurrentStation().id)
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.persistedRecordCount(), records)
    }

    // MARK: AC-40

    // 깨짐: 진행 여정이 없고 현재 정류장이 데이터에 없는데 시작 때 메인에 머문다.
    func testAC40_진행_여정_없이_현재_정류장이_사라졌으면_시작하자_최초_정류장_화면과_안내가_나온다() throws {
        let h = FocusMateUIHarness.launch(seed: "stationGone", extraArguments: FocusMateUIHarness.manualClockArguments)

        let notice = h.element("search.resetNotice")
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, stationRemovedNotice)
        XCTAssertTrue(h.element("screen.initialStationEntry").exists)
        XCTAssertNil(try h.persistedCurrentStation().id)
        XCTAssertEqual(try h.cardCount(), 1)
    }

    // MARK: AC-41, AC-42

    // 깨짐: 메인에 현재 정류장 방면이 나오지 않거나 옛 "정방향/역방향" 문구가 남는다.
    func testAC41_메인은_현재_정류장_방면을_보이고_정방향_역방향_문구가_없다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.app.waitForBound("성동구민체육센터 방면"))
        XCTAssertFalse(h.app.staticTexts["정방향"].exists)
        XCTAssertFalse(h.app.staticTexts["역방향"].exists)
    }

    // 깨짐: 데이터를 읽기 전에 방면 줄이 사라지거나 값이 채워져 있다.
    func testAC42_정류장_데이터가_준비되지_않으면_방면_줄은_있고_값이_비어_있다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: pending)

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let bound = h.element("main.bound")
        XCTAssertTrue(bound.waitForExistence(timeout: timeout))
        XCTAssertEqual(bound.value as? String ?? "", "")
    }

    // MARK: AC-43, AC-44

    // 깨짐: 데이터를 읽는 중에 포기가 눌려 도달 정류장을 잃는다(포기 버튼이 활성이거나 저장이 일어난다).
    func testAC43_정류장_데이터가_준비되지_않으면_포기_버튼은_비활성이고_상태는_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600", extraArguments: pending)
        h.tap("main.resumeJourney")
        h.tap("journey.timer.pause")

        let abandon = h.element("journey.abandon")
        XCTAssertTrue(abandon.waitForExistence(timeout: timeout))
        XCTAssertFalse(abandon.isEnabled)
        XCTAssertEqual(try h.abandonDiagnostic()["enabled"] as? Bool, false)
        XCTAssertEqual(try h.persistedCurrentStation().id, "seongsu")
        XCTAssertNotNil(try h.persistedJourney().active)
    }

    // 깨짐: 데이터를 읽는 중 새 여정 확정이 시간 선택으로 넘어가거나 저장을 일으켜 진행 여정을 잃는다.
    func testAC44_정류장_데이터가_준비되지_않으면_새_여정_확정은_거절되고_저장_없이_그대로다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused600", extraArguments: pending)
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let writes = try h.writeAttempts()

        startNewJourneyAndConfirm(h)

        XCTAssertFalse(h.element("screen.time").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertEqual(try h.writeAttempts(), writes)
        XCTAssertEqual(try h.persistedCurrentStation().id, "seongsu")
        XCTAssertNotNil(try h.persistedJourney().active)
    }

    // MARK: AC-46, AC-47, AC-48

    // 깨짐: 옛 저장(v4)의 정류장·여정이 비워지지 않거나 카드·기록이 줄거나, 안내가 없거나 정류장을 고른 뒤에도 남는다.
    func testAC46_47_옛_저장은_정류장과_여정이_비워지고_안내는_정류장을_고르면_사라진다() throws {
        let h = FocusMateUIHarness.launch(seed: "legacyV4Stations", extraArguments: FocusMateUIHarness.manualClockArguments)

        let notice = h.element("search.resetNotice")
        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertEqual(notice.label, replacedNotice)
        XCTAssertNil(try h.persistedCurrentStation().id)
        XCTAssertNil(try h.persistedJourney().active)
        XCTAssertEqual(try h.cardCount(), 1)
        XCTAssertEqual(try h.persistedRecordCount(), 3)

        h.app.typeStationQuery("성수역")
        let result = h.element("search.result.seongsu")
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        h.tap("search.confirm")

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("search.resetNotice").exists)
    }

    // 깨짐: 이전이 끝난 저장 상태에서 다시 시작해도 안내가 또 나온다(이전 표시가 저장되지 않음).
    func testAC48_이전이_끝난_뒤_다시_시작하면_안내가_다시_나오지_않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "legacyV4Stations", extraArguments: FocusMateUIHarness.manualClockArguments)
        XCTAssertTrue(h.element("search.resetNotice").waitForExistence(timeout: timeout))

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("search.resetNotice").waitForExistence(timeout: 1))
        XCTAssertEqual(try h.persistedRecordCount(), 3)
    }
}
