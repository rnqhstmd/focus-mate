import SwiftUI
import CoreText

/// Bundled Seoul city fonts; system text remains the fallback if registration fails.
enum FontCatalog {
    static func register() {
        for name in ["SeoulAlrim-Medium", "SeoulAlrim-Bold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func text(_ size: CGFloat, bold: Bool = false, relativeTo: Font.TextStyle = .body) -> Font {
        .custom(bold ? "SeoulAlrimTTF-Bold" : "SeoulAlrimTTF-Medium", size: size, relativeTo: relativeTo)
    }
}

extension CardColor {
    var swiftUIColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
}
