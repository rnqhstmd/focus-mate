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

    /// 앱을 끄고 같은 저장소로 인자 없이 다시 연다.
    @MainActor
    func relaunch() {
        app.terminate()
        app.launchArguments = ["--fm-ui-test-id", testID.uuidString]
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
