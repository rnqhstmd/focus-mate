import SwiftUI

/// Shared surfaces from the Pen design (G-global 2). Disabled controls retain readable labels.
enum FMDesign {
    // MARK: Surfaces
    static let background = Color(hex: 0x090909)
    /// Map base colour shown under imagery while tiles load or when offline.
    static let mapBase = Color(hex: 0x14191B)
    static let panel = Color(hex: 0x0A0A0A)
    static let panelStroke = Color.white.opacity(0.2)
    /// Uniform black 33% (#00000055) over every map backdrop.
    static let mapScrim = Color.black.opacity(0.33)
    static let rowFill = Color(hex: 0x111111)
    static let chipFill = Color(hex: 0x1A1A1A)

    // MARK: Text
    static let primary = Color.white
    static let secondaryText = Color(hex: 0xBFC6C1)
    static let tertiaryText = Color(hex: 0xB5B5BA)
    static let hintText = Color(hex: 0xAAAAAA)
    /// Labels over the journey map (#FFFFFFA3).
    static let overlayLabel = Color.white.opacity(0.64)

    // MARK: Controls
    static let ctaStroke = Color(hex: 0x444444)
    /// Disabled white-pill CTA (R04·R05·R07): #303A33 fill, #C6D0C9 label.
    static let ctaDisabledFill = Color(hex: 0x303A33)
    static let ctaDisabledText = Color(hex: 0xC6D0C9)
    /// Round icon button fill (#0A0A0ABF).
    static let circleFill = Color(hex: 0x0A0A0A).opacity(0.75)

    // MARK: Route
    static let routeTrunk = Color(hex: 0x2563EB)
    static let routeBranch = Color(hex: 0x168445)
    /// Remaining (not yet travelled) part of a route line (#FFFFFF44).
    static let routeRemaining = Color.white.opacity(0.27)
    static let stopPassed = Color(hex: 0x777777)
    static let stopStroke = Color(hex: 0x0A0A0A)

    // MARK: Tags (R07 chips)
    static let tagReading = Color(hex: 0xE8B64C)
    static let tagStudy = Color(hex: 0xA78BFA)
    static let tagWork = Color(hex: 0x60A5FA)
    static let tagRest = Color(hex: 0x4ADE80)

    /// Route colour by Seoul bus kind. 간선·지선 come from the design; the others follow Seoul bus colours
    /// and still need designer confirmation.
    static func routeColor(kind: String) -> Color {
        switch kind {
        case "간선": routeTrunk
        case "지선": routeBranch
        case "마을": Color(hex: 0x53B332)
        case "광역": Color(hex: 0xDC2626)
        case "순환": Color(hex: 0xD49B00)
        case "공항": Color(hex: 0x0284C7)
        case "심야": Color(hex: 0x3B4B8F)
        default: routeBranch
        }
    }
}

extension Color {
    /// sRGB colour from a 0xRRGGBB literal.
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}

/// White pill CTA: capsule, 1pt #444444, 15pt Regular black, no icon.
struct FMPrimaryButtonStyle: ButtonStyle {
    enum Size {
        /// Main and issuance CTA (51pt).
        case regular
        /// CTA inside panels and lists (43pt; touch target stays ≥ 44 with the stroke).
        case compact

        var height: CGFloat { self == .regular ? 51 : 44 }
    }

    var size: Size = .regular
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FontCatalog.text(15, relativeTo: .headline))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: size.height)
            .foregroundStyle(isEnabled ? Color.black : FMDesign.ctaDisabledText)
            .background(isEnabled ? Color.white : FMDesign.ctaDisabledFill, in: Capsule())
            .overlay { Capsule().strokeBorder(isEnabled ? FMDesign.ctaStroke : FMDesign.ctaDisabledFill, lineWidth: 1) }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct FMSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FontCatalog.text(15, relativeTo: .subheadline))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isEnabled ? FMDesign.primary : FMDesign.secondaryText)
            .background(FMDesign.panel.opacity(0.85), in: Capsule())
            .overlay { Capsule().strokeBorder(isEnabled ? FMDesign.ctaStroke : FMDesign.ctaStroke.opacity(0.5)) }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Round icon button over the map: 75% #0A0A0A, 1pt #444444, white symbol. Keeps a 44pt touch target.
struct FMCircleButtonStyle: ButtonStyle {
    var diameter: CGFloat = 43

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(FMDesign.primary)
            .frame(width: diameter, height: diameter)
            .background(FMDesign.circleFill, in: Circle())
            .overlay { Circle().strokeBorder(FMDesign.ctaStroke, lineWidth: 1) }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    func fmPanel(padding: CGFloat = 22) -> some View {
        self.padding(padding)
            .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
    }

    /// Pen bottom sheet: content padding (top 24 · sides 17 · bottom 28), #0A0A0A, radius 28, 1pt white 20%,
    /// floating 12pt from the sides and 20pt above the screen bottom (ignores the bottom safe area).
    func fmBottomPanel(floating: Bool = true) -> some View {
        self.padding(.top, 24).padding(.horizontal, 17).padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
            .padding(.horizontal, floating ? 12 : 0)
            .padding(.bottom, floating ? 20 : 0)
    }

    /// Uniform map darkening (black 33%) that never intercepts touches.
    func fmMapScrim() -> some View {
        overlay { FMDesign.mapScrim.allowsHitTesting(false).accessibilityHidden(true) }
    }
}

/// Route badge: kind-coloured rounded rectangle (height 32) with outline bus icon 18pt, kind 9pt #B5B5BA,
/// number 17pt Bold white.
struct RouteBadge: View {
    let kind: String
    let number: String
    @ScaledMetric(relativeTo: .headline) private var height: CGFloat = 32
    @ScaledMetric(relativeTo: .headline) private var iconSize: CGFloat = 18

    init(kind: String, number: String, height: CGFloat = 32) {
        self.kind = kind
        self.number = number
        _height = ScaledMetric(wrappedValue: height, relativeTo: .headline)
        _iconSize = ScaledMetric(wrappedValue: height >= 38 ? 20 : 18, relativeTo: .headline)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bus")
                .font(.system(size: iconSize * 0.78, weight: .light))
                .frame(width: iconSize, height: iconSize)
            Text(kind).font(FontCatalog.text(9, relativeTo: .caption2)).foregroundStyle(FMDesign.tertiaryText)
            Text(number).font(FontCatalog.text(17, weight: .bold, relativeTo: .headline)).lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.leading, 7).padding(.trailing, 8)
        .frame(minHeight: height)
        .background(FMDesign.routeColor(kind: kind), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind) \(number)")
    }
}
