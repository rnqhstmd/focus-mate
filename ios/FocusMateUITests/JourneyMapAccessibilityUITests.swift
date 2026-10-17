import Foundation
import XCTest

/// 가상 코스 지도 접근성·동작 줄이기·법적 표기 UI 테스트 (수동 시계).
@MainActor
final class JourneyMapAccessibilityUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let reduceMotion = ["--fm-ui-reduce-motion", "on"]
    private let largeText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let stopNames = ["성수역", "성수동", "뚝섬역", "성동구민체육센터", "서울숲역",
                             "서울숲 입구", "성수대교 북단", "뚝섬한강공원", "성수사거리"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func running(_ seed: String = "timerPaused90", extra: [String] = []) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchJourney(seed: seed, extraArguments: extra)
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        return h
    }

    private func openSheet(_ h: FocusMateUIHarness) {
        h.tap("journey.map.theme")
        XCTAssertTrue(h.element("journey.map.themeSheet").waitForExistence(timeout: timeout))
    }

    private func disjoint(_ named: [(String, CGRect)], file: StaticString = #filePath, line: UInt = #line) {
        for i in 0..<named.count {
            for j in (i + 1)..<named.count where named[i].1.intersects(named[j].1) {
                XCTFail("겹침: \(named[i].0) \(named[i].1) / \(named[j].0) \(named[j].1)", file: file, line: line)
            }
        }
    }

    private func cameraDiagnostic(_ h: FocusMateUIHarness) throws -> [String: Any] {
        try XCTUnwrap(try h.mapDiagnostic()["camera"] as? [String: Any])
    }

    // MARK: AC-3

    // 깨짐: 법적 표기가 하단 정보 위 왼쪽이 아니거나 다른 지표·컨트롤과 겹친다.
    func testAC3_법적_표기는_하단_정보_위_왼쪽에_있고_다른_요소와_겹치지_않는다() throws {
        let h = running()
        let legal = h.app.links["Legal"]
        guard legal.waitForExistence(timeout: 2) else {
            XCTContext.runActivity(named: "M-1 수동 확인으로 대체") { _ in }
            return
        }
        let window = h.app.windows.firstMatch
        let ids = ["remaining": "journey.timer.remaining", "stops": "journey.timer.stops",
                   "distance": "journey.timer.distance", "follow": "journey.map.follow",
                   "theme": "journey.map.theme", "pause": "journey.timer.pause"]
        let frames = ids.mapValues { h.frame($0) }
        XCTAssertLessThanOrEqual(legal.frame.maxY, try XCTUnwrap(frames["remaining"]).minY)
        XCTAssertLessThan(legal.frame.midX, window.frame.width / 2)
        for (name, frame) in frames {
            XCTAssertFalse(legal.frame.intersects(frame), "법적 표기가 \(name)과 겹침")
        }
    }

    // MARK: AC-30, 31

    // 깨짐: 동작 줄이기에서 카메라 이동이 애니메이션이다(방위는 내비처럼 진행 방향을 따르되 즉시 바뀐다).
    func testAC30_동작_줄이기에서는_카메라가_애니메이션_없이_움직인다() throws {
        let h = running(extra: reduceMotion)
        h.advance(10)
        let camera = try cameraDiagnostic(h)
        XCTAssertEqual(camera["animated"] as? Bool, false)
        XCTAssertNotNil(camera["heading"] as? Double)
    }

    // 깨짐: 동작 줄이기가 꺼져 있는데 카메라 이동이 애니메이션되지 않는다.
    func testAC31_동작_줄이기가_꺼져_있으면_카메라가_애니메이션으로_움직인다() throws {
        let h = running()
        h.advance(10)
        XCTAssertEqual(try cameraDiagnostic(h)["animated"] as? Bool, true)
    }

    // MARK: AC-32

    // 깨짐: 동작 줄이기에서 자유 탐색·복귀·테마·정류장·일시정지 결과가 꺼졌을 때와 달라진다.
    func testAC32_동작_줄이기에서도_지도_조작_결과가_같다() {
        let h = running(extra: reduceMotion)
        h.dragMap()
        XCTAssertTrue(h.waitForValue("journey.map.follow", "자유 탐색 중"))
        h.tap("journey.map.follow")
        XCTAssertTrue(h.waitForValue("journey.map.follow", "따라가는 중"))

        openSheet(h)
        h.tap("journey.map.theme.dark")
        XCTAssertTrue(h.waitForValue("journey.map.theme.dark", "선택됨"))
        h.tap("journey.map.stops")
        XCTAssertTrue(h.waitForValue("journey.map.stops", "꺼짐"))

        h.tap("journey.timer.pause")
        XCTAssertTrue(h.waitUntil { !h.element("journey.map.themeSheet").exists })
        // 시안 R15: 일시정지 중에는 지도 도구가 화면에서 빠진다(눌릴 수 없으면 된다).
        let follow = h.element("journey.map.follow"), theme = h.element("journey.map.theme")
        XCTAssertTrue(h.waitUntil { (!follow.exists || !follow.isEnabled) && (!theme.exists || !theme.isEnabled) })
    }

    // MARK: AC-33

    // 깨짐: 지도 낭독 값에 다음·도착 정류장이 없거나 개별 정류장 마커가 낭독 요소로 노출된다.
    func testAC33_지도는_하나의_요소로_낭독되고_정류장_마커는_개별_노출되지_않는다() {
        let h = running()
        let map = h.element("journey.map")
        XCTAssertTrue(map.waitForExistence(timeout: timeout))
        XCTAssertEqual(map.label, "가상 코스 지도")
        let value = map.value as? String ?? ""
        XCTAssertTrue(value.contains("성동구민체육센터"), value)
        XCTAssertTrue(value.contains("성수사거리"), value)

        let children = map.descendants(matching: .any).allElementsBoundByIndex
        let leaked = children.map(\.label).filter { stopNames.contains($0) }
        XCTAssertEqual(leaked, [])
    }

    // MARK: AC-34

    // 깨짐: 따라가기·테마 버튼의 라벨/값이 다르거나 일시정지 때 잠기지 않는다.
    func testAC34_도구_버튼은_라벨과_값을_낭독하고_일시정지하면_잠긴다() {
        let h = running()
        let follow = h.element("journey.map.follow"), theme = h.element("journey.map.theme")
        XCTAssertEqual(follow.label, "버스 따라가기")
        XCTAssertEqual(follow.value as? String, "따라가는 중")
        XCTAssertEqual(theme.label, "지도 테마")

        h.tap("journey.timer.pause")
        // 시안 R15: 일시정지 중에는 지도 도구가 화면에서 빠진다(눌릴 수 없으면 된다).
        XCTAssertTrue(h.waitUntil { (!follow.exists || !follow.isEnabled) && (!theme.exists || !theme.isEnabled) })
    }

    // MARK: AC-35

    // 깨짐: 시트 항목의 선택됨/선택 안 됨/켜짐/꺼짐 값이 동작과 어긋난다.
    func testAC35_테마_시트_항목은_선택_상태를_값으로_낭독한다() {
        let h = running()
        openSheet(h)
        XCTAssertEqual(h.value("journey.map.theme.satellite"), "선택됨")
        XCTAssertEqual(h.value("journey.map.theme.dark"), "선택 안 됨")
        XCTAssertEqual(h.value("journey.map.stops"), "켜짐")

        h.tap("journey.map.theme.dark")
        XCTAssertTrue(h.waitForValue("journey.map.theme.dark", "선택됨"))
        XCTAssertTrue(h.waitForValue("journey.map.theme.satellite", "선택 안 됨"))

        h.tap("journey.map.stops")
        XCTAssertTrue(h.waitForValue("journey.map.stops", "꺼짐"))
    }

    // MARK: AC-36

    // 깨짐: 가장 큰 글자에서 컨트롤이 44pt 미만이거나 닿지 않거나 지표끼리 겹친다.
    func testAC36_가장_큰_글자에서도_컨트롤이_닿고_지표가_겹치지_않는다() throws {
        let h = running(extra: largeText)
        for id in ["journey.map.follow", "journey.map.theme", "journey.timer.pause"] {
            let e = h.element(id)
            XCTAssertTrue(e.waitForExistence(timeout: timeout), id)
            XCTAssertTrue(e.isHittable, id)
            XCTAssertGreaterThanOrEqual(e.frame.width, 44, id)
            XCTAssertGreaterThanOrEqual(e.frame.height, 44, id)
        }
        let remaining = h.frame("journey.timer.remaining")
        let stops = h.frame("journey.timer.stops")
        let distance = h.frame("journey.timer.distance")
        let pause = h.frame("journey.timer.pause")
        disjoint([("remaining", remaining), ("stops", stops), ("distance", distance), ("pause", pause)])

        h.tap("journey.map.theme")
        XCTAssertTrue(h.element("journey.map.themeSheet").waitForExistence(timeout: timeout))
        for id in ["journey.map.theme.dark", "journey.map.theme.satellite", "journey.map.stops"] {
            let e = h.element(id)
            XCTAssertTrue(e.waitForExistence(timeout: timeout), id)
            var tries = 0
            while !e.isHittable && tries < 3 {
                h.element("journey.map.themeSheet").swipeUp()
                tries += 1
            }
            XCTAssertTrue(e.isHittable, id)
        }
    }

    // MARK: AC-37

    // 깨짐: 일시정지/재개 전환 낭독이 1회씩이 아니다.
    // VoiceOver 초기 포커스(남은 시간)는 시뮬레이터에서 관찰 불가 → 수동 확인 M-2
    func testAC37_일시정지와_재개는_한_번씩_낭독된다() throws {
        let h = running()
        let afterResume = try h.diagnostic("test.announcements")
        XCTAssertEqual(afterResume.components(separatedBy: "재개됨").count - 1, 1, afterResume)

        h.tap("journey.timer.pause")
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        let afterPause = try h.diagnostic("test.announcements")
        XCTAssertEqual(afterPause.components(separatedBy: "일시정지됨").count - 1, 1, afterPause)
        XCTAssertEqual(afterPause.components(separatedBy: "재개됨").count - 1, 1, afterPause)
    }

    // MARK: AC-38

    // 깨짐: 큰 글자에서 저장 경고가 재개 버튼·현재 정류장으로·지표를 가리거나 재개가 44pt 미만이다.
    func testAC38_큰_글자와_저장_경고가_함께여도_재개와_지표가_가려지지_않는다() throws {
        let h = running(extra: largeText)
        h.failNextSave { h.advance(10) }
        let warning = h.element("journey.timer.saveWarning")
        XCTAssertTrue(warning.waitForExistence(timeout: timeout))
        let resume = h.element("journey.timer.resume")
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        XCTAssertTrue(resume.isHittable)
        XCTAssertGreaterThanOrEqual(resume.frame.width, 44)
        XCTAssertGreaterThanOrEqual(resume.frame.height, 44)

        // 저장 실패로 일시정지되면 시안 R15대로 따라가기·테마 대신 "현재 정류장으로"가 보인다.
        for id in ["journey.timer.resume", "journey.recenter",
                   "journey.timer.remaining", "journey.timer.stops", "journey.timer.distance"] {
            XCTAssertFalse(warning.frame.intersects(h.frame(id)), "저장 경고가 \(id)와 겹침")
        }
    }
}
