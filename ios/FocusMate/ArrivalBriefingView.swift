import SwiftUI

/// 여행 화면 위 도착 안내(FR-1). 아래 타이머·지도는 가려 접근·조작할 수 없다(BR-6, BR-7).
@MainActor
struct ArrivalBriefingView: View {
    let controller: ArrivalBriefingController
    var model: AppModel? = nil
    var reduceMotion: Bool = false
    @AccessibilityFocusState private var confirmFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 44, weight: .regular)).accessibilityHidden(true)
                        .padding(.bottom, 36)
                    sentences
                    if controller.showsConfirm {
                        Button { controller.confirm() } label: {
                            Text("확인").font(FontCatalog.style(.body, weight: .semibold)).padding(.horizontal, 24)
                                .frame(minWidth: 160, minHeight: 52)
                                .foregroundStyle(.black)
                                .background(Color(white: 0.95), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .frame(width: 160).padding(.top, 64)
                        .transition(.opacity)
                        .accessibilityIdentifier("alighting.confirm")
                        .accessibilityFocused($confirmFocused)
                    }
                    if controller.showsSaveFailure {
                        Text(JourneyTimerDisplay.transitionFailureText).font(FontCatalog.style(.subheadline)).foregroundStyle(.orange)
                            .accessibilityIdentifier("alighting.saveFailure")
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32).padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .foregroundStyle(.white)
        .background {
            GeometryReader { background in
                Group {
                    if let model {
                        SceneMapBackdrop(model: model, stationID: model.activeJourney?.destinationStopID,
                                         bottomInset: max(0, background.size.height - 200))
                    } else { Color.black }
                }
                .overlay(JourneyBriefingShade())
            }
            .ignoresSafeArea()
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: controller.showsConfirm)
        .overlay(alignment: .topTrailing) {
            // The final reference hides the route line; retain its existing accessibility contract.
            Text(controller.content.routeText).font(.system(size: 1)).foregroundStyle(.clear)
                .accessibilityIdentifier("alighting.route").allowsHitTesting(false)
        }
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
                ForEach(controller.content.sentences, id: \.self) { Text($0).font(FontCatalog.style(.title2, weight: .semibold)) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(controller.content.sentences.joined(separator: " "))
            .accessibilityIdentifier("alighting.sentence")
        } else {
            let sentence = controller.content.sentences[controller.visibleIndex]
            Text(sentence).font(FontCatalog.style(.title2, weight: .semibold))
                .id(controller.visibleIndex)
                .transition(.opacity)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: controller.visibleIndex)
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
