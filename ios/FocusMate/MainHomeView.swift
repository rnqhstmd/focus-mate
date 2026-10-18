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
                                 showsStationAnnotation: false)
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
                            .padding(.horizontal, isIdle ? 24 : 18)
                            // 시안 R01·R18·R31·R34: 맨 아래 버튼 바닥이 화면 바닥 28pt 위(홈 표시줄 안전 영역 34보다 아래까지 내려간다).
                            // 저장 실패 안내(RootView의 아래 inset)가 있으면 안전 영역에 그 높이가 더해지므로 음수 여백을 쓰지 않는다 —
                            // 쓰면 "새 여정 시작"이 안내 뒤로 숨는다.
                            .padding(.bottom, model.saveFailure == nil ? 28 - geometry.safeAreaInsets.bottom : 16)
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
    /// 도착 여정 메인(시안 R34).
    private var isArrived: Bool { model.activeJourneyCard?.kind == .arrived }
    /// 진행 여정 메인(시안 R31·R34 공통): 18pt 여백, 현재 정류장 묶음·지도 핀 없음, 카드 아래 5pt에 "새 여정 시작".
    private var isActive: Bool { model.activeJourneyCard != nil }

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
                ForEach(welcomeLines, id: \.self) { line in
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
            .accessibilityLabel(welcomeLines.joined(separator: " "))
            .accessibilityAddTraits(.isHeader)
        }
        .padding(.top, 25)
    }

    static let welcomeLines = ["오늘은 어디에서", "출발해볼까요?"]

    /// 시안 R18(하차 후 홈)·R34(도착 여정): "{정류장}에서, / 오늘은 조금 느긋하게."
    /// 마친 여행 기록이 있거나 도착 여정이 있을 때 쓴다. 처음 쓰는 메인(R01)은 기본 문구다.
    /// 시안 R31(멈춘 여정): "{정류장}에서, / 잠깐, 나에게 집중해요."
    private var welcomeLines: [String] {
        if isActive, !isArrived, let name = model.snapshot?.currentStation?.name { return ["\(name)에서,", "잠깐, 나에게 집중해요."] }
        guard let name = model.snapshot?.currentStation?.name,
              isArrived || (isIdle && !(model.snapshot?.records.items.isEmpty ?? true)) else { return Self.welcomeLines }
        return ["\(name)에서,", "오늘은 조금 느긋하게."]
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
            // 시안 R31·R34에는 현재 정류장 묶음이 없다. 낭독·상태 확인용 식별자는 보이지 않는 요소로 남긴다.
            if isActive { hiddenStationSemantics }
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
                    startButton.buttonStyle(FMNewJourneyButtonStyle())
                        .padding(.top, -7)
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

    private var hiddenStationSemantics: some View {
        ZStack {
            Color.clear.frame(width: 1, height: 1)
                .accessibilityElement().accessibilityLabel("현재 정류장").accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityElement().accessibilityLabel(station.name)
                    .accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityElement().accessibilityLabel(model.currentStationBound ?? "")
                    .accessibilityValue(model.currentStationBound ?? "").accessibilityIdentifier("main.bound")
            }
        }
        .frame(width: 1, height: 1)
        .padding(.bottom, -12)
    }

    private var startButton: some View {
        Button { openDestination(.preparation) } label: {
            Text(model.mainStartTitle).frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("open.preparation")
    }
}
