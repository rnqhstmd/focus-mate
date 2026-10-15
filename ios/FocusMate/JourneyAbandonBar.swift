import SwiftUI

/// 타이머 화면 하단의 '포기하기'. 일시정지 중에만 보이고(BR-6), 확인 창을 거쳐 메인으로 간다(FR-5, FR-6).
/// 컨테이너는 항상 두고 버튼만 조건부로 그린다 — 상태가 바뀌어도 흐름 상태와 확인 창이 유지된다.
@MainActor
struct JourneyAbandonBar: View {
    let timer: JourneyTimerController
    private let abandoner: JourneyAbandoning
    @State private var flow: JourneyAbandonController
    @AccessibilityFocusState private var abandonFocused: Bool

    init(abandoner: JourneyAbandoning, timer: JourneyTimerController) {
        self.timer = timer
        self.abandoner = abandoner
        _flow = State(initialValue: JourneyAbandonController(abandoner: abandoner))
    }

    private var isPaused: Bool { timer.status == .paused }

    var body: some View {
        VStack(spacing: 8) {
            if isPaused {
                Button { flow.request(isPaused: isPaused) } label: {
                    Text(JourneyLifecycleText.abandonButton).font(.headline)
                        .frame(minWidth: 160, minHeight: 44).padding(.vertical, 8).padding(.horizontal, 24)
                        .overlay(Capsule().stroke(Color(white: 0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                // 정류장 데이터를 읽는 중에는 도달 정류장을 정할 수 없다(AC-43).
                .disabled(!abandoner.canEndActiveJourney)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .accessibilityLabel(JourneyLifecycleText.abandonButton)
                .accessibilityIdentifier("journey.abandon")
                .accessibilityFocused($abandonFocused)
            }
            // 같은 문구를 타이머가 이미 보이고 있으면 식별자가 겹치지 않게 그리지 않는다.
            if flow.showsFailure && !timer.showsTransitionFailure {
                Text(JourneyLifecycleText.saveFailure).font(.subheadline).foregroundStyle(.orange)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .accessibilityIdentifier("journey.timer.saveFailure")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24).padding(.bottom, 8)
        .foregroundStyle(.white)
        .alert(JourneyLifecycleText.abandonTitle, isPresented: Binding(
            get: { flow.isConfirming }, set: { if !$0 { flow.cancel() } })) {
            Button(JourneyLifecycleText.continueTrip, role: .cancel) {}
                .accessibilityIdentifier("journey.abandon.cancel")
            Button(JourneyLifecycleText.quitTrip, role: .destructive) { flow.confirm(isPaused: isPaused) }
                .accessibilityIdentifier("journey.abandon.confirm")
        } message: {
            Text(JourneyLifecycleText.abandonMessage)
        }
        // 확정 성공과 닫힘의 순서가 정해져 있지 않으므로 닫힌 뒤 컨트롤러 상태로만 판정한다.
        .onChange(of: flow.isConfirming) { _, open in
            if !open { abandonFocused = flow.focusTarget == .abandonButton }
        }
        .onChange(of: timer.status) { _, _ in flow.clearFailure() }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    #if DEBUG
    private var diagnostics: some View {
        let object: [String: Any] = ["visible": isPaused, "enabled": abandoner.canEndActiveJourney, "confirming": flow.isConfirming,
                                     "showsFailure": flow.showsFailure,
                                     "focus": flow.focusTarget == .abandonButton ? "abandon" : "none"]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return Text("포기 진단").font(.system(size: 1)).foregroundStyle(.clear)
            .accessibilityValue(json).accessibilityIdentifier("test.abandon").allowsHitTesting(false)
    }
    #endif
}
