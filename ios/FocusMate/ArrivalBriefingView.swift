import SwiftUI

/// 여행 화면 위 도착 안내(FR-1). 아래 타이머·지도는 가려 접근·조작할 수 없다(BR-6, BR-7).
@MainActor
struct ArrivalBriefingView: View {
    let controller: ArrivalBriefingController
    @AccessibilityFocusState private var confirmFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 32) {
                    Image(systemName: "bus").font(.system(size: 44, weight: .semibold)).accessibilityHidden(true)
                    Text(controller.content.routeText).font(.headline).foregroundStyle(.white.opacity(0.8))
                        .accessibilityIdentifier("alighting.route")
                    sentences
                    if controller.showsConfirm {
                        Button { controller.confirm() } label: {
                            Text("확인").font(.headline).foregroundStyle(.black)
                                .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                                .background(Color(white: 0.95), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("alighting.confirm")
                        .accessibilityFocused($confirmFocused)
                    }
                    if controller.showsSaveFailure {
                        Text(JourneyTimerDisplay.transitionFailureText).font(.subheadline).foregroundStyle(.orange)
                            .accessibilityIdentifier("alighting.saveFailure")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .foregroundStyle(.white)
        .background(LinearGradient(colors: [Color(white: 0.12), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            Color.clear.frame(width: 1, height: 1).accessibilityElement()
                .accessibilityLabel("도착 안내").accessibilityIdentifier("alighting.briefing")
        }
        .onChange(of: controller.focusTarget) { _, target in confirmFocused = target == .confirmButton }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    @ViewBuilder private var sentences: some View {
        if controller.showsAll {
            VStack(spacing: 12) {
                ForEach(controller.content.sentences, id: \.self) { Text($0).font(.title2.bold()) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(controller.content.sentences.joined(separator: " "))
            .accessibilityIdentifier("alighting.sentence")
        } else {
            let sentence = controller.content.sentences[controller.visibleIndex]
            Text(sentence).font(.title2.bold())
                .id(controller.visibleIndex)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: controller.visibleIndex)
                .accessibilityLabel(sentence)
                .accessibilityIdentifier("alighting.sentence")
        }
    }

    #if DEBUG
    private var diagnostics: some View {
        let object: [String: Any] = ["index": controller.visibleIndex, "showsAll": controller.showsAll,
                                     "showsConfirm": controller.showsConfirm,
                                     "focus": controller.focusTarget == .confirmButton ? "confirm" : "none"]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("도착 안내 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.arrivalBriefing").allowsHitTesting(false)
    }
    #endif
}
