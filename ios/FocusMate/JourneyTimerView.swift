import SwiftUI

/// 출발 뒤 타이머 화면. 남은 시간과 일시정지/재개만 둔다. 지도(W06)와 도착 안내(W09)는 이 위에 붙는다.
@MainActor
struct JourneyTimerView: View {
    let controller: JourneyTimerController
    let reduceMotion: Bool
    #if DEBUG
    var path: [Destination] = []
    #endif
    @AccessibilityFocusState private var remainingFocused: Bool
    /// 일시정지↔재개 버튼이 같은 자리에서 바뀌므로, 연타의 두 번째 탭이 반대 전환으로 들어가지 않게 잠깐 무시한다.
    @State private var lastControlTap: ContinuousClock.Instant?
    private static let tapGuard: Duration = .milliseconds(500)

    private var minutesText: String { JourneyTimerDisplay.text(minutes: controller.remainingMinutes) }

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)
            remaining
            control
            notices
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            controller.appear()
            remainingFocused = true
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    private var remaining: some View {
        Text(minutesText)
            .font(.system(size: 64, weight: .bold))
            .lineLimit(1).minimumScaleFactor(0.5)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(reduceMotion ? nil : .default, value: controller.remainingMinutes)
            .accessibilityLabel(JourneyTimerDisplay.accessibilityLabel)
            .accessibilityValue(JourneyTimerDisplay.accessibilityValue(minutes: controller.remainingMinutes))
            .accessibilityIdentifier("journey.timer.remaining")
            .accessibilityFocused($remainingFocused)
    }

    @ViewBuilder private var control: some View {
        switch controller.status {
        case .running:
            controlButton(JourneyTimerDisplay.pauseLabel, systemImage: "pause.fill", id: "journey.timer.pause") { controller.pause() }
        case .paused:
            controlButton(JourneyTimerDisplay.resumeLabel, systemImage: "play.fill", id: "journey.timer.resume") { controller.resume() }
        case .arrived:
            // 임시 도착 상태. 도착 안내·하차 태그는 W09가 대체한다.
            Text("도착했어요").font(.title2.bold()).accessibilityIdentifier("journey.arrived")
        }
    }

    private func controlButton(_ title: String, systemImage: String, id: String, action: @escaping () -> Void) -> some View {
        Button {
            let now = ContinuousClock.now
            if let last = lastControlTap, last.duration(to: now) < Self.tapGuard { return }
            lastControlTap = now
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline).foregroundStyle(.black)
                .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                .background(Color(white: 0.95), in: Capsule())
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityLabel(title)
        .accessibilityIdentifier(id)
    }

    @ViewBuilder private var notices: some View {
        if controller.showsTransitionFailure {
            Text(JourneyTimerDisplay.transitionFailureText).font(.subheadline).foregroundStyle(.orange)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("journey.timer.saveFailure")
        }
        if controller.showsSaveWarning {
            Text(controller.status == .arrived ? JourneyTimerDisplay.arrivalWarningText : JourneyTimerDisplay.checkpointWarningText)
                .font(.subheadline).foregroundStyle(.orange)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("journey.timer.saveWarning")
        }
    }

    #if DEBUG
    private var diagnostics: some View {
        let status = switch controller.status { case .running: "running"; case .paused: "paused"; case .arrived: "arrived" }
        let object: [String: Any] = [
            "status": status, "elapsed": controller.elapsedSeconds, "remainingMinutes": controller.remainingMinutes,
            "text": minutesText, "showsSaveWarning": controller.showsSaveWarning,
            "showsSaveFailure": controller.showsTransitionFailure, "focus": remainingFocused ? "remaining" : "none",
            "path": path.map { "\($0)" },
        ]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("타이머 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.timer").allowsHitTesting(false)
    }
    #endif
}
