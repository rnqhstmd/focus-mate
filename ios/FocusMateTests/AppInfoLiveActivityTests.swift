import Foundation
import XCTest

/// AC-29 프로젝트 구성: Live Activity 지원 설정과 위젯 확장 임베드를 확인한다.
final class AppInfoLiveActivityTests: XCTestCase {
    private let appexName = "FocusMateWidgets.appex"

    private func widgetBundle() -> Bundle? {
        guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent(appexName),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return Bundle(url: url)
    }

    // 깨짐: Info.plist에서 NSSupportsLiveActivities 키가 빠지거나 false가 된다.
    func testV15_AC29_앱_Info가_라이브_액티비티_지원을_선언한다() {
        XCTAssertEqual(
            Bundle.main.object(forInfoDictionaryKey: "NSSupportsLiveActivities") as? Bool,
            true
        )
    }

    // 깨짐: 위젯 확장이 앱의 PlugIns 폴더에 임베드되지 않는다.
    func testV15_AC29_위젯_확장이_앱_번들에_내장되어_있다() {
        XCTAssertNotNil(widgetBundle(), "PlugIns/\(appexName) 없음")
    }

    // 깨짐: 확장의 extension point가 widgetkit-extension이 아니게 된다.
    func testV15_AC29_위젯_확장의_확장_포인트가_위젯킷이다() throws {
        let bundle = try XCTUnwrap(widgetBundle(), "PlugIns/\(appexName) 없음")
        let ext = bundle.object(forInfoDictionaryKey: "NSExtension") as? [String: Any]
        XCTAssertEqual(ext?["NSExtensionPointIdentifier"] as? String, "com.apple.widgetkit-extension")
    }

    // 깨짐: 확장의 번들 식별자가 app.focusmate.prototype.widgets에서 바뀐다.
    func testV15_AC29_위젯_확장의_번들_식별자가_약속된_값이다() throws {
        let bundle = try XCTUnwrap(widgetBundle(), "PlugIns/\(appexName) 없음")
        XCTAssertEqual(bundle.bundleIdentifier, "app.focusmate.prototype.widgets")
    }

    // 깨짐: 앱과 확장의 마케팅 버전이 어긋나거나 비게 된다.
    func testV15_AC29_앱과_위젯_확장의_버전이_같고_비어_있지_않다() throws {
        let bundle = try XCTUnwrap(widgetBundle(), "PlugIns/\(appexName) 없음")
        let app = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let ext = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        XCTAssertFalse((app ?? "").isEmpty)
        XCTAssertEqual(app, ext)
    }
}
