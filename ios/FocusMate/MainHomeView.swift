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
                VStack(spacing: 0) {
                    tools
                        .padding(.leading, 24).padding(.trailing, 16)
                    GeometryReader { scrollGeometry in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                welcome
                                if model.activeJourneyCard == nil {
                                    // 시안 R01: 정류장 표시는 제목 아래 화면 가운데 근처(라벨 y≈437)에 둔다.
                                    Spacer(minLength: 24).frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? 24 : 137)
                                    station
                                } else {
                                    Spacer(minLength: 16)
                                }
                                Spacer(minLength: 32)
                                footer
                            }
                            .padding(.horizontal, isIdle ? 24 : 20)
                            .padding(.bottom, isIdle ? max(0, 28 - geometry.safeAreaInsets.bottom) : 16)
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

    /// 시안 R01: 오른쪽 위 원형 버튼 2개(기록·마이페이지). 설정·카드 꾸미기는 마이페이지에서 연다.
    /// 진행 여정이 없는 기본 메인(R01). 진행 여정 메인(R31~R34)의 배치는 그 단계에서 맞춘다.
    private var isIdle: Bool { model.activeJourneyCard == nil }

    private var tools: some View {
        HStack(spacing: 11) {
            Spacer(minLength: 8)
            tool(symbol: "doc.plaintext", size: 15, destination: .records)
            tool(symbol: "person", size: 17, destination: .profile)
        }
    }

    private func tool(symbol: String, size: CGFloat, destination: Destination) -> some View {
        Button { openDestination(destination) } label: {
            Image(systemName: symbol).font(.system(size: size, weight: .regular))
        }
        .buttonStyle(FMCircleButtonStyle())
        .accessibilityLabel(destination.mainMenuTitle)
        .accessibilityIdentifier("open.\(destination.rawValue)")
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 10) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(greeting(at: context.date)).font(FontCatalog.text(15, relativeTo: .subheadline))
                    .foregroundStyle(Color(hex: 0xE1E5E8))
            }
            // 시안 R01: 줄마다 검정 53% 받침, 흰 28pt Bold.
            VStack(alignment: .leading, spacing: -9) {
                ForEach(Self.welcomeLines, id: \.self) { line in
                    Text(line)
                        .font(FontCatalog.text(dynamicTypeSize.isAccessibilitySize ? 22 : 28, weight: .bold, relativeTo: .title))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.5), radius: 0, y: 2)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color.black.opacity(0.53))
                }
            }
            .padding(.leading, -10)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.welcomeLines.joined(separator: " "))
            .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 25)
    }

    static let welcomeLines = ["오늘은 어디에서", "출발해볼까요?"]

    private func greeting(at date: Date) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case ..<6: "고요한 밤이에요."
        case ..<12: "좋은 아침이에요."
        case ..<18: "좋은 오후예요."
        default: "오늘도 수고했어요."
        }
    }

    private var station: some View {
        VStack(spacing: 3) {
            Text("현재 위치").font(FontCatalog.text(10, relativeTo: .caption2)).foregroundStyle(FMDesign.tertiaryText)
                .shadow(color: .black.opacity(0.75), radius: 4, y: 1)
                .accessibilityLabel("현재 정류장")
                .accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Text(station.name).font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color.black)
                    .accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                // 시안에는 방면 줄이 없다. 낭독과 상태 확인을 위해 보이지 않는 요소로 남긴다.
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityLabel(model.currentStationBound ?? "")
                    .accessibilityValue(model.currentStationBound ?? "").accessibilityIdentifier("main.bound")
            }
        }
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
                        .padding(.horizontal, isIdle ? -5 : 0)
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
