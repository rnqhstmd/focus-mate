import CoreText
import SwiftUI
import UIKit
import XCTest
@testable import FocusMate

/// 시안 글꼴(Noto Sans KR 400/600/700)이 Info.plist UIAppFonts로 등록되고, 이전 서울알림체는 번들에 없어야 한다.
final class FontCatalogTests: XCTestCase {
    // 깨짐: 폰트 파일·UIAppFonts·PostScript 이름 중 하나라도 어긋나면 글자가 시스템 글꼴로 대체돼 실패한다.
    func test1_세_굵기의_Noto_Sans_KR가_등록되어_한글을_그린다() throws {
        for weight in FMFontWeight.allCases {
            let font = try XCTUnwrap(UIFont(name: weight.postScriptName, size: 15), weight.postScriptName)
            XCTAssertTrue(font.familyName.hasPrefix("Noto Sans KR"), font.familyName)
            let glyphs = CTFontCreateWithName(weight.postScriptName as CFString, 15, nil)
            var characters = Array("갈똠힣·→‹".utf16)
            var out = [CGGlyph](repeating: 0, count: characters.count)
            XCTAssertTrue(CTFontGetGlyphsForCharacters(glyphs, &characters, &out, characters.count), weight.postScriptName)
        }
    }

    // 깨짐: 서울알림체 파일이나 등록이 남아 있으면 실패한다.
    func test2_서울알림체는_번들과_등록에서_제거됐다() {
        XCTAssertNil(Bundle.main.url(forResource: "SeoulAlrim-Medium", withExtension: "ttf"))
        XCTAssertNil(Bundle.main.url(forResource: "SeoulAlrim-Bold", withExtension: "ttf"))
        XCTAssertNil(UIFont(name: "SeoulAlrimTTF-Medium", size: 15))
        XCTAssertNotNil(Bundle.main.url(forResource: "NotoSansKR-OFL", withExtension: "txt"), "OFL 1.1 전문 동봉")
        let fonts = Bundle.main.object(forInfoDictionaryKey: "UIAppFonts") as? [String]
        XCTAssertEqual(fonts, ["NotoSansKR-Regular.ttf", "NotoSansKR-SemiBold.ttf", "NotoSansKR-Bold.ttf"])
    }

    // 깨짐: 노선 종류 색이 시안(간선 파랑·지선 초록)과 다르면 실패한다.
    func test3_노선_종류_색은_시안_값이다() {
        XCTAssertEqual(UIColor(FMDesign.routeColor(kind: "간선")).hexRGB, 0x2563EB)
        XCTAssertEqual(UIColor(FMDesign.routeColor(kind: "지선")).hexRGB, 0x168445)
        XCTAssertEqual(UIColor(FMDesign.primary).hexRGB, 0xFFFFFF)
        XCTAssertEqual(UIColor(FMDesign.background).hexRGB, 0x090909)
    }
}

private extension UIColor {
    var hexRGB: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UInt32((r * 255).rounded()) << 16 | UInt32((g * 255).rounded()) << 8 | UInt32((b * 255).rounded())
    }
}
