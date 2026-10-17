import Foundation
import XCTest

extension XCUIApplication {
    /// 최초 정류장 검색 화면에서 검색어를 입력한다(빈 검색어는 결과를 보이지 않는다).
    @MainActor
    func typeStationQuery(_ text: String, timeout: TimeInterval = 5) {
        let field = descendants(matching: .any)["search.query"]
        XCTAssertTrue(field.waitForExistence(timeout: timeout), "Missing: search.query")
        field.tap()
        field.typeText(text)
    }
}

extension XCUIApplication {
    /// 메인의 방면 줄(main.bound)이 기대 값이 될 때까지 기다린다. 정류장 데이터는 시작 뒤 비동기로 준비된다.
    @MainActor
    func waitForBound(_ expected: String, timeout: TimeInterval = 5) -> Bool {
        let bound = descendants(matching: .any)["main.bound"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (bound.value as? String) == expected { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return (bound.value as? String) == expected
    }
}

/// 카드 발급 UI 테스트용 실행·진단 도우미. (XCTestCase 아님)
/// Phase1FlowTests의 private 헬퍼와 별개로 둔다.
struct FocusMateUIHarness {
    static let timeout: TimeInterval = 3

    let app: XCUIApplication
    let testID: UUID

    @MainActor
    static func launch(
        seed: String? = nil,
        save: String? = nil,
        hold: String? = nil,
        extraArguments: [String] = [],
        testID: UUID = UUID()
    ) -> FocusMateUIHarness {
        let app = XCUIApplication()
        var arguments = ["--fm-ui-test-id", testID.uuidString]
        if let seed { arguments += ["--fm-ui-seed", seed] }
        if let save { arguments += ["--fm-ui-save", save] }
        if let hold { arguments += ["--fm-ui-issue-hold", hold] }
        arguments += extraArguments
        app.launchArguments = arguments
        app.launch()
        return FocusMateUIHarness(app: app, testID: testID)
    }

    /// 앱을 끄고 같은 저장소로 다시 연다. 추가 인자가 없으면 인자 없이 연다.
    @MainActor
    func relaunch(extraArguments: [String] = []) {
        app.terminate()
        app.launchArguments = ["--fm-ui-test-id", testID.uuidString] + extraArguments
        app.launch()
    }

    @MainActor
    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    func diagnostic(_ identifier: String) throws -> String {
        let observed = element(identifier)
        XCTAssertTrue(observed.waitForExistence(timeout: Self.timeout), "Missing diagnostic: \(identifier)")
        return try XCTUnwrap(observed.value as? String, "Diagnostic has no string value: \(identifier)")
    }

    @MainActor
    func snapshot() throws -> [String: Any] {
        let raw = try diagnostic("test.snapshot")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

/// 여행 타이머 UI 테스트 공용 도우미 (수동 시계 전제).
extension FocusMateUIHarness {
    static let manualClockArguments = ["--fm-ui-clock", "manual"]

    /// 수동 시계 + 여행 화면 진입 경로로 시드 상태에서 연다.
    @MainActor
    static func launchJourney(seed: String, extraArguments: [String] = []) -> FocusMateUIHarness {
        launch(
            seed: seed,
            extraArguments: manualClockArguments + ["--fm-ui-route", "journey"] + extraArguments
        )
    }

    @MainActor
    func timerDiagnostic() throws -> [String: Any] {
        let raw = try diagnostic("test.timer")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// 메모리 상태의 진행 여정(test.snapshot). 없으면 nil.
    @MainActor
    func memoryActive() throws -> [String: Any]? {
        let journey = try XCTUnwrap(try snapshot()["journey"] as? [String: Any])
        return journey["active"] as? [String: Any]
    }

    @MainActor
    func memoryElapsed() throws -> Int? {
        let progress = try memoryActive()?["progress"] as? [String: Any]
        return progress?["elapsedSeconds"] as? Int
    }

    /// 파일에 저장된 바이트 문자열(test.persistedBytes) 원문.
    @MainActor
    func persistedBytes() throws -> String {
        try diagnostic("test.persistedBytes")
    }

    /// 저장된 바이트를 JSON으로 읽어 "active" 사전과 최상위 version을 찾는다.
    @MainActor
    func persistedJourney() throws -> (version: Int?, active: [String: Any]?) {
        let raw = try persistedBytes()
        // persistedBytes는 파일 바이트의 base64 문자열이다("absent"/"unreadable"은 디코드 실패로 드러난다).
        let data = try XCTUnwrap(Data(base64Encoded: raw), "persistedBytes가 base64가 아님: \(raw)")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        func find(_ node: Any) -> [String: Any]? {
            guard let dict = node as? [String: Any] else { return nil }
            if let active = dict["active"] as? [String: Any] { return active }
            for value in dict.values { if let found = find(value) { return found } }
            return nil
        }
        return (root["version"] as? Int, find(root))
    }

    @MainActor
    func persistedElapsed() throws -> Int? {
        let progress = try persistedJourney().active?["progress"] as? [String: Any]
        return progress?["elapsedSeconds"] as? Int
    }

    @MainActor
    func persistedPaused() throws -> Bool? {
        try persistedJourney().active?["paused"] as? Bool
    }

    @MainActor
    func tap(_ identifier: String, timeout: TimeInterval = FocusMateUIHarness.timeout) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: timeout), "Missing: \(identifier)")
        let buttons = app.buttons.matching(identifier: identifier)
        if buttons.count == 1 {
            buttons.element.tap()
        } else {
            target.tap()
        }
    }

    /// 다음 저장 1건을 실패시키고 곧바로 action을 실행한다(수동 시계에는 자율 쓰기가 없어 결정적이다).
    @MainActor
    func failNextSave(then action: () -> Void) {
        tap("test.failNextSave")
        action()
    }

    @MainActor
    func advance(_ seconds: Int, times: Int = 1) {
        for _ in 0..<times { tap("test.clock.advance\(seconds)") }
    }

    @MainActor
    func waitForTimerText(_ text: String, timeout: TimeInterval = FocusMateUIHarness.timeout) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (try? timerDiagnostic()["text"] as? String) == text { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }

    @MainActor
    func goBackground() {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1)
        app.activate()
    }
}

extension FocusMateUIHarness {
    @MainActor
    func recordCount() throws -> Int {
        let records = try XCTUnwrap(try snapshot()["records"] as? [String: Any])
        return try XCTUnwrap(records["items"] as? [Any]).count
    }

    @MainActor
    func cardCount() throws -> Int {
        let cards = try XCTUnwrap(try snapshot()["cards"] as? [String: Any])
        return try XCTUnwrap(cards["items"] as? [Any]).count
    }
}

/// W07 생명주기(이어가기·새 여정·포기) UI 테스트 도우미.
extension FocusMateUIHarness {
    /// life* 시드로 수동 시계와 함께 연다. 시드는 재실행된 상태라 메인으로 열린다.
    @MainActor
    static func launchLifecycle(seed: String, extraArguments: [String] = []) -> FocusMateUIHarness {
        launch(seed: seed, extraArguments: manualClockArguments + extraArguments)
    }

    /// 프로세스 시작 이후 저장 시도 수(실패 포함, test.writeAttempts). 재실행을 넘어 비교하지 않는다.
    @MainActor
    func writeAttempts() throws -> Int {
        let raw = try diagnostic("test.writeAttempts")
        return try XCTUnwrap(Int(raw), "writeAttempts가 정수가 아님: \(raw)")
    }

    /// 메인에서 다음 저장 1건을 실패시키도록 예약한 뒤 action을 실행한다.
    /// 쓰기가 반드시 일어나는 동작 직전에만 쓴다(예약이 다음 쓰기로 새지 않게).
    @MainActor
    func failNextMainSave(then action: () throws -> Void) rethrows {
        tap("test.main.failNextSave")
        try action()
    }

    /// 여행 포기 확인 창(R16)은 시스템 alert가 아니라 직접 그린 창이다.
    static let abandonDialogTitle = "여행을 그만둘까요?"
    /// 새 여정 확인 창(R32)도 직접 그린 창이다(`main.newJourney.dialog`).
    static let newJourneyDialogTitle = "새 여정을 시작할까요?"

    /// 제목 label로 찾은 시스템 alert (CardCustomizationFlowTests와 같은 방식).
    /// 포기 확인(R16)·새 여정 확인(R32)은 시안대로 직접 그린 창(label = 제목)을 돌려준다.
    @MainActor
    func alert(titled title: String) -> XCUIElement {
        if title == Self.abandonDialogTitle {
            return app.descendants(matching: .any).matching(identifier: "journey.abandon.dialog").firstMatch
        }
        if title == Self.newJourneyDialogTitle {
            return app.descendants(matching: .any).matching(identifier: "main.newJourney.dialog").firstMatch
        }
        return app.alerts
            .matching(NSPredicate(format: "label == %@", title))
            .firstMatch
    }

    /// ID와 정확한 문구를 우선한다. 시스템이 ID를 누락하면 단일 alert의 유일한 같은 문구 버튼만 허용한다.
    @MainActor
    func alertButton(_ id: String, label: String) -> XCUIElement {
        let exactLabel = NSPredicate(format: "label == %@", label)
        if id.hasPrefix("journey.abandon.") || id.hasPrefix("main.newJourney.") {
            // 직접 그린 포기 확인 창(R16)의 버튼.
            return app.buttons.matching(identifier: id).matching(exactLabel).firstMatch
        }
        let identified = app.alerts.buttons
            .matching(identifier: id)
            .matching(exactLabel)
        let identifiedCandidates = identified.allElementsBoundByAccessibilityElement
        let identifiedLeaves = identifiedCandidates.filter {
            $0.descendants(matching: .button)
                .matching(identifier: id)
                .matching(exactLabel).count == 0
        }
        if identifiedLeaves.count == 1 {
            return identifiedLeaves[0]
        }
        if identifiedCandidates.isEmpty, app.alerts.count == 1 {
            let labeled = app.alerts.element.buttons.matching(exactLabel)
            let labeledLeaves = labeled.allElementsBoundByAccessibilityElement.filter {
                $0.descendants(matching: .button).matching(exactLabel).count == 0
            }
            if labeledLeaves.count == 1 {
                return labeledLeaves[0]
            }
        }
        // 일치 없음이나 중복은 실패하게 두고 임의의 첫 버튼을 선택하지 않는다.
        return identified.element
    }

    /// 저장된 바이트(base64)의 최상위 state 사전. 없으면 최상위 자체.
    @MainActor
    func persistedState() throws -> [String: Any] {
        let raw = try persistedBytes()
        let data = try XCTUnwrap(Data(base64Encoded: raw), "persistedBytes가 base64가 아님: \(raw)")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return (root["state"] as? [String: Any]) ?? root
    }

    @MainActor
    func persistedCurrentStation() throws -> (id: String?, name: String?) {
        let station = try persistedState()["currentStation"] as? [String: Any]
        return (station?["id"] as? String, station?["name"] as? String)
    }

    @MainActor
    func persistedRecordCount() throws -> Int {
        let records = try XCTUnwrap(try persistedState()["records"] as? [String: Any])
        return try XCTUnwrap(records["items"] as? [Any]).count
    }

    /// 포기 흐름 진단(test.abandon): {"visible","confirming","showsFailure","focus"}.
    @MainActor
    func abandonDiagnostic() throws -> [String: Any] {
        let raw = try diagnostic("test.abandon")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

/// 가상 코스 지도 UI 테스트 도우미.
extension FocusMateUIHarness {
    /// 조건이 참이 될 때까지 폴링한다.
    @MainActor
    func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return condition()
    }

    /// 요소의 accessibilityValue가 기대 문자열이 될 때까지 기다린다.
    @MainActor
    func waitForValue(_ identifier: String, _ expected: String, timeout: TimeInterval = 5) -> Bool {
        waitUntil(timeout: timeout) { (element(identifier).value as? String) == expected }
    }

    @MainActor
    func value(_ identifier: String) -> String? {
        element(identifier).value as? String
    }

    @MainActor
    func frame(_ identifier: String) -> CGRect {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "Missing: \(identifier)")
        return target.frame
    }

    /// test.map 진단 JSON.
    @MainActor
    func mapDiagnostic() throws -> [String: Any] {
        let raw = try diagnostic("test.map")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// 사용자 손가락 드래그로 지도를 민다.
    @MainActor
    func dragMap() {
        let map = element("journey.map")
        XCTAssertTrue(map.waitForExistence(timeout: Self.timeout), "Missing: journey.map")
        let start = map.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        let end = map.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// 저장 파일 원문(base64 디코드한 JSON 문자열).
    @MainActor
    func persistedText() throws -> String {
        let raw = try persistedBytes()
        let data = try XCTUnwrap(Data(base64Encoded: raw), "persistedBytes가 base64가 아님: \(raw)")
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }
}


extension XCUIApplication {
    /// 시간 패널 안에서 실제 target 위치에 맞는 방향으로만 스크롤한다.
    @MainActor
    func revealTimeContent(_ target: XCUIElement, maxAttempts: Int = 6,
                           fullyVisible: Bool = false, timeout: TimeInterval = 5) -> Bool {
        if !fullyVisible, target.isHittable { return true }
        let scroll = scrollViews["time.contentScroll"]
        guard scroll.waitForExistence(timeout: timeout) else { return false }
        func reached() -> Bool {
            guard target.isHittable else { return false }
            if !fullyVisible { return true }
            let viewport = scroll.frame.intersection(frame).insetBy(dx: 0, dy: 8)
            return target.frame.minY >= viewport.minY && target.frame.maxY <= viewport.maxY
        }
        for _ in 0..<maxAttempts {
            if reached() { return true }
            let viewport = scroll.frame.intersection(frame).insetBy(dx: 0, dy: 8)
            guard viewport.height > 80, viewport.width > 0 else { return false }
            let moveDown = target.frame.midY < viewport.midY
            let startY = moveDown ? viewport.minY + viewport.height * 0.25 : viewport.minY + viewport.height * 0.75
            let distance = min(viewport.height * 0.5, max(40, abs(target.frame.midY - viewport.midY)))
            let endY = startY + (moveDown ? distance : -distance)
            let anchor = coordinate(withNormalizedOffset: .zero)
            let x = viewport.minX + viewport.width * 0.92
            let start = anchor.withOffset(CGVector(dx: x - frame.minX, dy: startY - frame.minY))
            let end = anchor.withOffset(CGVector(dx: x - frame.minX, dy: endY - frame.minY))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        return reached()
    }

    /// Canvas 눈금자에 실제 손가락 드래그를 보내고 접근성으로 정확한 분 값을 확인한다.
    /// accessibilityRepresentation Slider에는 XCTest의 물리 scrubber 좌표가 없어 adjust API를 쓰지 않는다.
    @MainActor
    func setJourneyMinutes(_ minutes: Int, timeout: TimeInterval = 5,
                           file: StaticString = #filePath, line: UInt = #line) {
        guard (15...360).contains(minutes) else {
            XCTFail("여행 시간 범위 밖: \(minutes)", file: file, line: line)
            return
        }
        let ruler = sliders["time.ruler"]
        guard ruler.waitForExistence(timeout: timeout) else {
            XCTFail("Missing: time.ruler", file: file, line: line)
            return
        }
        guard revealTimeContent(ruler, maxAttempts: 6, fullyVisible: true, timeout: timeout) else {
            XCTFail("6회 panel 스크롤 후 눈금자에 닿지 않음: ruler=\(ruler.frame), viewport=\(scrollViews["time.contentScroll"].frame)", file: file, line: line)
            return
        }
        let displayed = descendants(matching: .any)["time.minutesLabel"]
        if launchArguments.contains(where: { $0.hasPrefix("UICTContentSizeCategoryAccessibility") }) {
            // The visible +/- controls provide exact one-minute steps even on a narrow native Slider.
            let deadline = Date().addingTimeInterval(90)
            for attempt in 0..<345 {
                guard let raw = displayed.value as? String, let current = Int(raw) else {
                    XCTFail("여행 시간 분 값을 읽을 수 없음: \(String(describing: displayed.value))", file: file, line: line)
                    return
                }
                if current == minutes {
                    XCTAssertEqual(ruler.value as? String, "\(minutes)분", file: file, line: line)
                    return
                }
                guard Date() < deadline else {
                    XCTFail("1분 버튼 조절 90초 초과: 목표 \(minutes), 현재 \(current), 시도 \(attempt)", file: file, line: line)
                    return
                }
                let increasing = current < minutes
                let button = buttons[increasing ? "time.minute.increase" : "time.minute.decrease"]
                guard button.exists, button.isHittable, button.isEnabled else {
                    XCTFail("여행 시간 1분 버튼에 닿을 수 없음: \(button.identifier), 현재 \(current)", file: file, line: line)
                    return
                }
                let expected = current + (increasing ? 1 : -1)
                button.tap()
                let predicate = NSPredicate(format: "value == %@", String(expected))
                let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: displayed)],
                                           timeout: min(timeout, max(0, deadline.timeIntervalSinceNow)))
                guard result == .completed else {
                    XCTFail("1분 버튼이 정확히 한 분 변경하지 않음: 이전 \(current), 기대 \(expected), 실제 \(String(describing: displayed.value))", file: file, line: line)
                    return
                }
                XCTAssertEqual(ruler.value as? String, "\(expected)분", file: file, line: line)
                if expected == minutes {
                    XCTAssertEqual(displayed.value as? String, String(minutes), file: file, line: line)
                    return
                }
            }
            XCTFail("1분 버튼 345회 후 목표에 도달하지 못함: 목표 \(minutes), 현재 \(String(describing: displayed.value))", file: file, line: line)
            return
        }
        let deadline = Date().addingTimeInterval(60)
        let maxAttempts = 60
        for attempt in 0..<maxAttempts {
            guard let raw = displayed.value as? String, let current = Int(raw) else {
                XCTFail("time.minutesLabel 분 값을 읽을 수 없음: \(String(describing: displayed.value))", file: file, line: line)
                return
            }
            if current == minutes {
                XCTAssertEqual(ruler.value as? String, "\(minutes)분", file: file, line: line)
                return
            }
            guard Date() < deadline else {
                XCTFail("눈금자 드래그 60초 초과: 목표 \(minutes), 현재 \(current), 시도 \(attempt)", file: file, line: line)
                return
            }
            let width = ruler.frame.width
            let capacity = Int((width * 0.6 / 8).rounded(.down))
            guard capacity >= 1, ruler.isHittable else {
                XCTFail("눈금자 드래그 영역에 닿을 수 없음: \(ruler.frame), hittable=\(ruler.isHittable)", file: file, line: line)
                return
            }
            let increasing = minutes > current
            let step = min(abs(minutes - current), capacity)
            let distance = CGFloat(step) * 8 / width
            let startX: CGFloat = increasing ? 0.8 : 0.2
            let endX = startX + (increasing ? -distance : distance)
            let start = ruler.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
            let end = ruler.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end)
            let changed = NSPredicate(format: "value != %@", String(current))
            let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: changed, object: displayed)],
                                       timeout: min(timeout, max(0, deadline.timeIntervalSinceNow)))
            guard result == .completed else {
                XCTFail("실제 드래그 후 분 값이 바뀌지 않음: 현재 \(current), 목표 \(minutes), 이동 \(step * 8)pt", file: file, line: line)
                return
            }
        }
        XCTFail("눈금자 드래그 \(maxAttempts)회 초과: 목표 \(minutes), 현재 \(String(describing: displayed.value))", file: file, line: line)
    }
}
