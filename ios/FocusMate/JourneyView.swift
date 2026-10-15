import SwiftUI

/// 여행 화면. 출발 확인 전에는 출발 안내(시안 DO8HO)만 보이고, '시작' 뒤에는 실제 여행 화면(W05) 자리표시를 둔다.
@MainActor
struct JourneyView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    /// 출발 안내 컨트롤러는 화면이 처음 나타날 때 한 번만 만든다.
    @State private var briefing: DepartureBriefingController?

    var body: some View {
        Group {
            if let briefing { JourneyScreen(model: model, services: services, briefing: briefing) }
            else { Color.clear }
        }
        .onAppear {
            guard briefing == nil else { return }
            briefing = DepartureBriefingController(confirmer: model, sleep: services.sleep)
        }
    }
}

@MainActor
private struct JourneyScreen: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    let briefing: DepartureBriefingController
    @AccessibilityFocusState private var startFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduceMotion: Bool { services.reduceMotion(system: systemReduceMotion) }
    private var awaitingDeparture: Bool { model.activeJourney?.phase == .awaitingDeparture && !briefing.isConfirmed }

    var body: some View {
        // Group은 수식어를 자식마다 나눠 붙여 안쪽 식별자를 덮으므로, 컨테이너 하나로 감싼다.
        ZStack {
            if awaitingDeparture { departureBriefing } else { placeholder }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.journey")
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(awaitingDeparture)
        .toolbar(awaitingDeparture ? .hidden : .automatic, for: .navigationBar)
        .task { if awaitingDeparture { await briefing.begin(reduceMotion: reduceMotion) } }
        .onChange(of: scenePhase) { _, phase in
            guard awaitingDeparture else { return }
            if phase == .background { briefing.reset() }
            else if phase == .active, !briefing.showsStart {
                Task { await briefing.begin(reduceMotion: reduceMotion) }
            }
        }
        .onChange(of: briefing.focusTarget) { _, target in startFocused = target == .startButton }
        #if DEBUG
        .overlay(alignment: .topLeading) { diagnostics }
        #endif
    }

    private var departureBriefing: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 40) {
                    Image(systemName: "bus").font(.system(size: 44, weight: .semibold)).accessibilityHidden(true)
                    sentences
                    if briefing.showsStart {
                        Button { briefing.confirm() } label: {
                            Text("시작").font(.headline).foregroundStyle(.black)
                                .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                                .background(Color(white: 0.95), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("journey.start")
                        .accessibilityFocused($startFocused)
                    }
                    if briefing.showsSaveFailure {
                        Text("출발을 저장하지 못했어요. 다시 눌러주세요.").font(.subheadline).foregroundStyle(.orange)
                            .accessibilityIdentifier("journey.saveFailure")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [Color(white: 0.12), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        // 중첩 컨테이너 식별자는 스크롤 뷰에 흡수될 수 있어, 안내 단계 표지는 별도 요소로 둔다.
        .overlay(alignment: .topLeading) {
            Color.clear.frame(width: 1, height: 1).accessibilityElement()
                .accessibilityLabel("출발 안내").accessibilityIdentifier("journey.briefing")
        }
    }

    @ViewBuilder private var sentences: some View {
        if briefing.showsAll {
            VStack(spacing: 12) {
                ForEach(DepartureBriefingController.sentences, id: \.self) { Text($0).font(.title2.bold()) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityValue(DepartureBriefingController.sentences.joined(separator: " "))
            .accessibilityIdentifier("journey.briefingSentence")
        } else {
            let sentence = DepartureBriefingController.sentences[briefing.visibleIndex]
            Text(sentence).font(.title2.bold())
                .id(briefing.visibleIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: briefing.visibleIndex)
                .accessibilityValue(sentence)
                .accessibilityIdentifier("journey.briefingSentence")
        }
    }

    /// W05가 실제 분 타이머·지도로 교체한다. 지금은 제목만 두고 뒤로가기로 메인에 간다.
    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Destination.journey.title).font(.largeTitle.bold()).accessibilityIdentifier("journey.placeholder")
            Spacer()
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
    }

    #if DEBUG
    private var diagnostics: some View {
        let object: [String: Any] = ["index": briefing.visibleIndex, "showsAll": briefing.showsAll,
                                     "showsStart": briefing.showsStart,
                                     "focus": briefing.focusTarget == .startButton ? "start" : "none"]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("출발 안내 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.briefing")
    }
    #endif
}
