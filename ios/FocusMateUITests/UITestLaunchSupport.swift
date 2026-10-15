import Foundation
import XCTest

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
        target.tap()
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
