import Foundation
import XCTest

/// 가상 코스 지도 UI 테스트 (수동 시계, 여행 화면 직접 진입).
@MainActor
final class JourneyMapUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let journeyArguments = FocusMateUIHarness.manualClockArguments + ["--fm-ui-route", "journey"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func running(_ seed: String = "timerPaused90") -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchJourney(seed: seed)
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        return h
    }

    private func openSheet(_ h: FocusMateUIHarness) {
        h.tap("journey.map.theme")
        XCTAssertTrue(h.element("journey.map.themeSheet").waitForExistence(timeout: timeout))
    }

    private func closeSheet(_ h: FocusMateUIHarness) {
        h.tap("journey.map.themeSheet.close")
        XCTAssertTrue(h.waitUntil { !h.element("journey.map.themeSheet").exists })
    }

    private func latLon(_ dict: [String: Any]?) throws -> (Double, Double) {
        let d = try XCTUnwrap(dict)
        return (try XCTUnwrap(d["lat"] as? Double), try XCTUnwrap(d["lon"] as? Double))
    }

    // MARK: AC-1, AC-29

    // 깨짐: 지도·세 지표·일시정지·두 도구 중 하나라도 화면에 없거나, 위치 권한 요청이 뜬다.
    func testAC1_지도와_지표_컨트롤이_모두_보이고_위치_권한_요청이_없다() {
        let h = running()
        for id in ["journey.map", "journey.timer.remaining", "journey.timer.stops", "journey.timer.distance",
                   "journey.timer.pause", "journey.map.follow", "journey.map.theme"] {
            XCTAssertTrue(h.element(id).waitForExistence(timeout: timeout), "Missing: \(id)")
        }
        XCTAssertEqual(h.app.alerts.count, 0)
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
    }

    // MARK: AC-2

    // 깨짐: 지표가 하단 좌/중/우 순서가 아니거나 일시정지·도구가 위쪽 모서리에 없다.
    func testAC2_지표는_아래에_좌중우로_컨트롤은_위에_배치된다() {
        let h = running()
        let window = h.app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: timeout))
        let w = window.frame.width, hh = window.frame.height
        let remaining = h.frame("journey.timer.remaining"), stops = h.frame("journey.timer.stops")
        let distance = h.frame("journey.timer.distance"), pause = h.frame("journey.timer.pause")
        let follow = h.frame("journey.map.follow"), theme = h.frame("journey.map.theme")

        XCTAssertTrue(remaining.midY > hh / 2 && remaining.midX < w / 2)
        XCTAssertTrue(stops.midY > hh / 2 && stops.midX > w / 3 && stops.midX < 2 * w / 3)
        XCTAssertTrue(distance.midY > hh / 2 && distance.midX > w / 2)
        XCTAssertTrue(remaining.midX < stops.midX && stops.midX < distance.midX)
        XCTAssertTrue(pause.midY < hh * 0.2 && pause.midX < w / 2)
        XCTAssertTrue(follow.midY < hh * 0.2 && follow.midX > w / 2)
        XCTAssertTrue(theme.midY < hh * 0.2 && theme.midX > w / 2)
        XCTAssertTrue(follow.midY < theme.midY)
    }

    // MARK: AC-4

    // 깨짐: 나침반·피치·전체 노선·축척·사용자 위치 등 금지된 기본 컨트롤이 노출된다.
    func testAC4_금지된_기본_지도_컨트롤이_화면에_없다() {
        let h = running()
        XCTAssertTrue(h.element("journey.map").waitForExistence(timeout: timeout))
        let contains = ["Compass", "나침반", "Pitch", "전체 노선", "Scale", "UserLocation", "현재 위치"]
        for word in contains {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@ OR identifier CONTAINS[c] %@", word, word)
            XCTAssertEqual(h.app.descendants(matching: .any).matching(predicate).count, 0, word)
        }
        for word in ["2D", "3D"] {
            let predicate = NSPredicate(format: "label == %@ OR identifier == %@", word, word)
            XCTAssertEqual(h.app.descendants(matching: .any).matching(predicate).count, 0, word)
        }
    }

    // MARK: AC-14, AC-15

    // 깨짐: 앱 갱신·시트 개폐가 따라가기를 풀거나, 드래그가 자유 탐색으로 안 바꾸거나, 다시 따라가기가 버스 위치로 복귀하지 않는다.
    func testAC14_15_드래그로만_자유_탐색이_되고_따라가기_탭으로_버스에_복귀한다() throws {
        let h = running()
        XCTAssertTrue(h.waitForValue("journey.map.follow", "따라가는 중"))
        h.advance(10, times: 3)
        openSheet(h)
        closeSheet(h)
        XCTAssertEqual(h.value("journey.map.follow"), "따라가는 중")

        h.dragMap()
        XCTAssertTrue(h.waitForValue("journey.map.follow", "자유 탐색 중"))

        h.tap("journey.map.follow")
        XCTAssertTrue(h.waitForValue("journey.map.follow", "따라가는 중"))
        let diagnostic = try h.mapDiagnostic()
        let bus = try latLon(diagnostic["bus"] as? [String: Any])
        let camera = try latLon(diagnostic["camera"] as? [String: Any])
        XCTAssertEqual(camera.0, bus.0, accuracy: 1e-6)
        XCTAssertEqual(camera.1, bus.1, accuracy: 1e-6)
    }

    // MARK: AC-19, 20, 21

    // 깨짐: 시트 기본 선택(어두운 지도·정류장 켜짐)이 다르거나 시트가 열리지 않는다.
    func testAC19_테마_시트는_어두운_지도와_정류장_켜짐으로_열린다() {
        let h = running()
        openSheet(h)
        for id in ["journey.map.theme.dark", "journey.map.theme.satellite", "journey.map.stops"] {
            XCTAssertTrue(h.element(id).waitForExistence(timeout: timeout), "Missing: \(id)")
        }
        XCTAssertTrue(h.element("journey.map.theme.dark").isSelected)
        XCTAssertFalse(h.element("journey.map.theme.satellite").isSelected)
        XCTAssertEqual(h.value("journey.map.stops"), "켜짐")
    }

    // 깨짐: 테마 선택이 반영되지 않거나 두 테마가 동시에 선택된다.
    func testAC20_테마를_바꾸면_선택_표시가_따라_바뀐다() {
        let h = running()
        openSheet(h)
        h.tap("journey.map.theme.satellite")
        XCTAssertTrue(h.waitUntil { h.element("journey.map.theme.satellite").isSelected })
        XCTAssertFalse(h.element("journey.map.theme.dark").isSelected)

        h.tap("journey.map.theme.dark")
        XCTAssertTrue(h.waitUntil { h.element("journey.map.theme.dark").isSelected })
        XCTAssertFalse(h.element("journey.map.theme.satellite").isSelected)
    }

    // 깨짐: 정류장 토글이 마커만 지우지 않고 경로·버스·목적지까지 지우거나, 다시 켜도 코스 정류장 6개로 복구되지 않는다.
    func testAC21_정류장_표시를_끄면_마커만_사라지고_켜면_돌아온다() throws {
        let h = running()
        openSheet(h)
        h.tap("journey.map.stops")
        XCTAssertTrue(h.waitForValue("journey.map.stops", "꺼짐"))
        var render = try XCTUnwrap(try h.mapDiagnostic()["render"] as? [String: Any])
        XCTAssertEqual(render["stopMarkers"] as? Int, 0)
        XCTAssertEqual(render["route"] as? Int, 6)  // 닫는 선 없음: 코스 정류장 수와 같다
        XCTAssertEqual(render["bus"] as? Bool, true)
        XCTAssertEqual(render["destination"] as? Bool, true)

        h.tap("journey.map.stops")
        XCTAssertTrue(h.waitForValue("journey.map.stops", "켜짐"))
        render = try XCTUnwrap(try h.mapDiagnostic()["render"] as? [String: Any])
        XCTAssertEqual(render["stopMarkers"] as? Int, 6)  // 시드 여정 코스 정류장: 2014-r 5구간 + 출발 = 6
    }

    // MARK: AC-22, 24, 25

    // 깨짐: 일시정지해도 시트가 남거나 도구가 잠기지 않고, 재개해도 풀리지 않는다.
    func testAC22_시트가_열린_채_일시정지하면_시트가_닫히고_도구가_잠긴다() {
        let h = running()
        openSheet(h)
        h.tap("journey.timer.pause")
        XCTAssertTrue(h.waitUntil { !h.element("journey.map.themeSheet").exists })
        XCTAssertTrue(h.waitUntil { !h.element("journey.map.follow").isEnabled && !h.element("journey.map.theme").isEnabled })

        h.tap("journey.timer.resume")
        XCTAssertTrue(h.waitUntil { h.element("journey.map.follow").isEnabled && h.element("journey.map.theme").isEnabled })
    }

    // 깨짐: 시트가 열린 채 도착해도 시트가 남거나, 도착 안내 아래의 지도 도구가 눌릴 수 있다.
    func testAC24_시트가_열린_채_도착하면_시트가_닫히고_도구는_도착_안내에_가려져_누를_수_없다() {
        let h = running("timerNearArrival")
        openSheet(h)
        h.advance(60)
        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.waitUntil { !h.element("journey.map.themeSheet").exists })
        for id in ["journey.map.follow", "journey.map.theme"] {
            XCTAssertFalse(h.element(id).exists, id)
        }
    }

    // 깨짐: 일시정지 상태에서 테마 버튼이 활성이거나 탭하면 시트가 열린다.
    func testAC25_일시정지_상태에서는_테마_버튼이_잠기고_시트가_열리지_않는다() {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        let theme = h.element("journey.map.theme")
        XCTAssertTrue(theme.waitForExistence(timeout: timeout))
        XCTAssertFalse(theme.isEnabled)
        theme.tap()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(h.element("journey.map.themeSheet").exists)
    }

    // MARK: AC-26, 27, 28

    private func changeMapState(_ h: FocusMateUIHarness) {
        openSheet(h)
        h.tap("journey.map.theme.satellite")
        h.tap("journey.map.stops")
        XCTAssertTrue(h.waitForValue("journey.map.stops", "꺼짐"))
        closeSheet(h)
        h.dragMap()
        XCTAssertTrue(h.waitForValue("journey.map.follow", "자유 탐색 중"))
    }

    // 깨짐: 지도 상태가 저장 파일에 들어가거나 저장 버전이 5가 아니다.
    func testAC26_지도_조작_후에도_저장_파일에_지도_키가_없고_버전은_5다() throws {
        let h = running()
        changeMapState(h)
        let persisted = try h.persistedJourney()
        XCTAssertEqual(persisted.version, 5)
        let text = try h.persistedText()
        for key in ["theme", "mapMode", "camera", "pitch", "showsStops"] {
            XCTAssertFalse(text.contains("\"\(key)\""), key)
        }
    }

    // 깨짐: 재실행 후 지도 상태가 복원되어 따라가기가 아니거나 테마·정류장이 기본값이 아니다.
    func testAC27_재실행하면_지도_상태가_기본값으로_돌아온다() {
        let h = running()
        changeMapState(h)
        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments + ["--fm-ui-route", "journey"])
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.waitForValue("journey.map.follow", "따라가는 중"))
        openSheet(h)
        XCTAssertTrue(h.element("journey.map.theme.dark").isSelected)
        XCTAssertEqual(h.value("journey.map.stops"), "켜짐")
    }

    // 깨짐: 지도 조작이 저장 파일을 쓰거나 타이머 경과·상태를 바꾼다.
    func testAC28_지도_조작은_저장_파일과_타이머를_바꾸지_않는다() throws {
        let h = running()
        let bytes = try h.persistedBytes()
        let before = try h.timerDiagnostic()

        h.dragMap()
        openSheet(h)
        h.tap("journey.map.theme.satellite")
        h.tap("journey.map.stops")
        closeSheet(h)
        h.tap("journey.map.follow")

        XCTAssertEqual(try h.persistedBytes(), bytes)
        let after = try h.timerDiagnostic()
        XCTAssertEqual(after["elapsed"] as? Int, before["elapsed"] as? Int)
        XCTAssertEqual(after["status"] as? String, before["status"] as? String)
    }

    // MARK: AC-39

    // 깨짐: 진행 중 남은 정류장·거리 표시가 5개/2.6km가 아니거나, 도착하면 도착 안내가 아닌 타이머 지표가 그대로 노출된다.
    func testAC39_남은_정류장과_거리는_진행에서_표시되고_도착에서는_도착_안내가_대신한다() {
        let paused = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        XCTAssertTrue(paused.waitForValue("journey.timer.stops", "5개"))
        XCTAssertTrue(paused.waitForValue("journey.timer.distance", "2.6km"))
        paused.app.terminate()

        let arrived = FocusMateUIHarness.launchJourney(seed: "timerArrived")
        XCTAssertTrue(arrived.element("alighting.briefing").waitForExistence(timeout: timeout))
        XCTAssertFalse(arrived.element("journey.timer.stops").exists, "journey.timer.stops")
        XCTAssertFalse(arrived.element("journey.timer.distance").exists, "journey.timer.distance")
    }
}
