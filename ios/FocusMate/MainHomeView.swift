import SwiftUI

private struct MainFooterHeight: PreferenceKey {
    static var defaultValue: CGFloat = 100
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Main's map, greeting and actions. Navigation and lifecycle decisions remain in RootView.
@MainActor
struct MainHomeView: View {
    var model: AppModel
    var actionFailed: Bool
    let openDestination: (Destination) -> Void
    let customizeCard: () -> Void
    let resume: () -> Void
    let alight: () -> Void
    @State private var footerHeight: CGFloat = 100
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SceneMapBackdrop(model: model, bottomInset: footerHeight + geometry.safeAreaInsets.bottom + 40,
                                 showsStationAnnotation: model.activeJourneyCard != nil)
                    .ignoresSafeArea()
                // 지도 공통 덮개(33%) 위에 제목 영역만 옅게 받친다.
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .clear, location: 0.35)
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea().allowsHitTesting(false)
                VStack(spacing: 0) {
                    tools
                        .padding(.horizontal, 20).padding(.vertical, 8)
                    GeometryReader { scrollGeometry in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                welcome
                                Spacer(minLength: model.activeJourneyCard == nil ? 80 : 16)
                                if model.activeJourneyCard == nil { station }
                                Spacer(minLength: 32)
                                footer
                            }
                            .padding(.horizontal, 20).padding(.bottom, 16)
                            .frame(minHeight: scrollGeometry.size.height, alignment: .topLeading)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
        }
        .background(FMDesign.background)
        .foregroundStyle(FMDesign.primary)
        .onPreferenceChange(MainFooterHeight.self) { footerHeight = $0 }
    }

    private var tools: some View {
        HStack(spacing: 10) {
            Text("Focus Mate").font(FontCatalog.text(12, weight: .bold, relativeTo: .caption)).tracking(1.4)
                .lineLimit(1).minimumScaleFactor(0.6)
                .foregroundStyle(FMDesign.secondaryText)
            Spacer(minLength: 8)
            tool(symbol: "book.closed", destination: .records)
            tool(symbol: "person.crop.circle", destination: .profile)
            tool(symbol: "gearshape", destination: .settings)
            Button(action: customizeCard) {
                Image(systemName: "creditcard")
            }
            .buttonStyle(FMCircleButtonStyle())
            .accessibilityLabel("카드 꾸미기")
            .accessibilityIdentifier("open.cardCustomization")
        }
    }

    private func tool(symbol: String, destination: Destination) -> some View {
        Button { openDestination(destination) } label: {
            Image(systemName: symbol)
        }
        .buttonStyle(FMCircleButtonStyle())
        .accessibilityLabel(destination.mainMenuTitle)
        .accessibilityIdentifier("open.\(destination.rawValue)")
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 8) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(greeting(at: context.date)).font(FontCatalog.text(15, relativeTo: .subheadline))
                    .foregroundStyle(FMDesign.secondaryText)
            }
            Text(welcomeTitle)
                .font(FontCatalog.text(dynamicTypeSize.isAccessibilitySize ? 22 : 28, weight: .bold, relativeTo: .title))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 12)
    }

    private var welcomeTitle: String {
        guard let name = model.snapshot?.currentStation?.name else { return "오늘은 어디에서\n출발해볼까요?" }
        return "\(name)에서,\n나만의 속도로 출발해요."
    }

    private func greeting(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case ..<6: "고요한 밤이에요."
        case ..<12: "좋은 아침이에요."
        case ..<18: "좋은 오후예요."
        default: "오늘도 수고했어요."
        }
    }

    private var station: some View {
        VStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 36)).padding(.bottom, 6)
                .accessibilityHidden(true)
            Text("앱 속 현재 정류장").font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                .accessibilityLabel("현재 정류장")
                .accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Text(station.name).font(FontCatalog.text(20, weight: .bold, relativeTo: .title3))
                    .accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                Text(model.currentStationBound ?? " ").font(FontCatalog.text(12, relativeTo: .caption))
                    .foregroundStyle(FMDesign.secondaryText)
                    .accessibilityValue(model.currentStationBound ?? "").accessibilityIdentifier("main.bound")
            }
        }
        .shadow(color: .black.opacity(0.75), radius: 5, y: 2)
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Active journeys retain station semantics without repeating a large station panel.
            if model.activeJourneyCard != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 정류장").font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                        .accessibilityIdentifier("screen.main")
                    if let station = model.snapshot?.currentStation {
                        Text(station.name).font(FontCatalog.text(17, weight: .bold, relativeTo: .headline)).accessibilityValue(station.name)
                            .accessibilityIdentifier("main.currentStation")
                        Text(model.currentStationBound ?? " ").font(FontCatalog.text(12, relativeTo: .caption))
                            .accessibilityValue(model.currentStationBound ?? "").accessibilityIdentifier("main.bound")
                    }
                }
            }
            if let stationName = model.abandonNotice { MainAbandonNoticeView(stationName: stationName) }
            if actionFailed {
                Text(JourneyLifecycleText.saveFailure).foregroundStyle(.orange)
                    .accessibilityIdentifier("main.saveFailure")
            }
            if let card = model.activeJourneyCard {
                ActiveJourneyCardView(content: card, onResume: resume, onAlight: alight)
            }
            if model.mainMenuDestinations.contains(.preparation) {
                if model.activeJourney != nil {
                    startButton.buttonStyle(FMSecondaryButtonStyle())
                } else {
                    startButton.buttonStyle(FMPrimaryButtonStyle())
                }
            }
        }
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: MainFooterHeight.self, value: geometry.size.height)
            }
        }
    }

    private var startButton: some View {
        Button { openDestination(.preparation) } label: {
            Text(model.mainStartTitle).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("open.preparation")
    }
}
