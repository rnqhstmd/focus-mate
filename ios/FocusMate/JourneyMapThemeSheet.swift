import SwiftUI

/// 지도 테마 시트(FR-6). 상태는 컨트롤러에 있고 저장하지 않는다.
@MainActor
struct JourneyMapThemeSheet: View {
    let map: JourneyMapController
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(JourneyMapDisplay.themeLabel).font(FontCatalog.style(.headline, weight: .semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button("닫기") { map.dismissThemeSheet() }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("journey.map.themeSheet.close")
                }
                themeButton(JourneyMapDisplay.darkLabel, theme: .dark, id: "journey.map.theme.dark")
                themeButton(JourneyMapDisplay.satelliteLabel, theme: .satellite, id: "journey.map.theme.satellite")
                // SwiftUI Toggle은 UI 테스트에서 값이 갱신되지 않아(T0) 토글 특성을 가진 버튼으로 둔다.
                Button { map.setShowsStops(!map.state.showsStops) } label: {
                    HStack {
                        Text(JourneyMapDisplay.stopsLabel)
                        Spacer()
                        Image(systemName: map.state.showsStops ? "checkmark.circle.fill" : "circle")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(JourneyMapDisplay.stopsLabel)
                .accessibilityValue(JourneyMapDisplay.switchValue(map.state.showsStops))
                .accessibilityAddTraits(.isToggle)
                .accessibilityIdentifier("journey.map.stops")
            }
            .padding(20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("journey.map.themeSheet")
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationBackgroundInteraction(.enabled)
        .onAppear { if dynamicTypeSize.isAccessibilitySize { detent = .large } }
    }

    private func themeButton(_ title: String, theme: JourneyMapTheme, id: String) -> some View {
        let selected = map.state.theme == theme
        return Button { map.select(theme: theme) } label: {
            HStack {
                Text(title)
                Spacer()
                if selected { Image(systemName: "checkmark") }
            }
            .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(JourneyMapDisplay.selectedValue(selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}
