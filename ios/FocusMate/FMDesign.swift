import SwiftUI

/// Shared surfaces from the final prototype. Disabled controls retain readable labels.
enum FMDesign {
    static let background = Color(red: 15 / 255, green: 16 / 255, blue: 18 / 255)
    static let panel = Color(red: 10 / 255, green: 10 / 255, blue: 10 / 255)
    static let primary = Color(red: 244 / 255, green: 246 / 255, blue: 242 / 255)
    static let secondaryText = Color(red: 191 / 255, green: 198 / 255, blue: 193 / 255)
}

struct FMPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FontCatalog.text(17, bold: true, relativeTo: .headline))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(isEnabled ? Color.black : Color.black.opacity(0.7))
            .background(isEnabled ? FMDesign.primary : FMDesign.primary.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
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
            .background(FMDesign.panel.opacity(0.85), in: RoundedRectangle(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(FMDesign.primary.opacity(isEnabled ? 0.3 : 0.15)) }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    func fmPanel(padding: CGFloat = 22) -> some View {
        self.padding(padding).background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 24))
    }
}
