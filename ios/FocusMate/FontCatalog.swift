import SwiftUI

/// Weights bundled from Noto Sans KR (OFL 1.1). Fonts are registered through Info.plist `UIAppFonts`.
enum FMFontWeight: CaseIterable, Sendable {
    case regular, semibold, bold

    var postScriptName: String {
        switch self {
        case .regular: "NotoSansKR-Regular"
        case .semibold: "NotoSansKR-SemiBold"
        case .bold: "NotoSansKR-Bold"
        }
    }
}

/// The Pen design typeface. Every helper keeps a `relativeTo` text style so Dynamic Type still scales.
enum FontCatalog {
    /// Design font at a point size, scaled with `relativeTo`.
    static func text(_ size: CGFloat, weight: FMFontWeight = .regular, relativeTo: Font.TextStyle = .body) -> Font {
        .custom(weight.postScriptName, size: size, relativeTo: relativeTo)
    }

    /// Design font at the iOS default size of a text style; replaces SF text-style fonts such as `.font(.headline)`.
    static func style(_ style: Font.TextStyle, weight: FMFontWeight = .regular) -> Font {
        text(defaultSize(of: style), weight: weight, relativeTo: style)
    }

    /// Design font that never scales. Only for lettering drawn inside a fixed-size graphic (card, terminal LCD).
    static func fixed(_ size: CGFloat, weight: FMFontWeight = .regular) -> Font {
        .custom(weight.postScriptName, fixedSize: size)
    }

    // MARK: Pen type scale (G-global 1-1)
    static var display: Font { text(32, weight: .bold, relativeTo: .largeTitle) }
    static var title: Font { text(28, weight: .bold, relativeTo: .title) }
    static var title2: Font { text(22, weight: .bold, relativeTo: .title2) }
    static var heading: Font { text(18, weight: .bold, relativeTo: .title3) }
    static var number: Font { text(17, weight: .bold, relativeTo: .headline) }
    static var subhead: Font { text(15, weight: .bold, relativeTo: .subheadline) }
    static var body: Font { text(15, relativeTo: .body) }
    static var chip: Font { text(14, weight: .semibold, relativeTo: .subheadline) }
    static var callout: Font { text(13, relativeTo: .footnote) }
    static var caption: Font { text(12, relativeTo: .caption) }
    static var footnote: Font { text(11, relativeTo: .caption2) }
    static var micro: Font { text(10, relativeTo: .caption2) }
    static var badge: Font { text(9, relativeTo: .caption2) }

    static func defaultSize(of style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}

extension CardColor {
    var swiftUIColor: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: 1) }
}
