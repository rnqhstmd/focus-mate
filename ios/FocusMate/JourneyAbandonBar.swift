import SwiftUI

/// 타이머 화면의 포기(종료). 일시정지 중에만 오른쪽 위 빨간 X(R15)로 보이고(BR-6), 직접 그린 확인 창(R16)을 거쳐 메인으로 간다(FR-5, FR-6).
/// 컨테이너는 항상 두고 버튼만 조건부로 그린다 — 상태가 바뀌어도 흐름 상태와 확인 창이 유지된다.
/// 타이머 화면 위에 겹쳐 놓이며, 버튼·창 밖은 터치를 아래로 넘긴다.
@MainActor
struct JourneyAbandonBar: View {
    let timer: JourneyTimerController
    private let abandoner: JourneyAbandoning
    @State private var flow: JourneyAbandonController
    @AccessibilityFocusState private var abandonFocused: Bool
    @AccessibilityFocusState private var dialogTitleFocused: Bool

    init(abandoner: JourneyAbandoning, timer: JourneyTimerController) {
        self.timer = timer
        self.abandoner = abandoner
        _flow = State(initialValue: JourneyAbandonController(abandoner: abandoner))
    }

    private var isPaused: Bool { timer.status == .paused }

    var body: some View {
        ZStack {
            VStack(alignment: .trailing, spacing: 8) {
                if isPaused {
                    Button { flow.request(isPaused: isPaused) } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background {
                                Circle().fill(Color(hex: 0xD13A42)).overlay(Circle().fill(Color.white.opacity(0.19)))
                            }
                            .contentShape(Circle())
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
                    Text(JourneyLifecycleText.saveFailure).font(FontCatalog.style(.subheadline)).foregroundStyle(.orange)
                        .multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                        .accessibilityIdentifier("journey.timer.saveFailure")
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .accessibilityHidden(flow.isConfirming)
            if flow.isConfirming { dialog }
        }
        .foregroundStyle(.white)
        // 확정 성공과 닫힘의 순서가 정해져 있지 않으므로 닫힌 뒤 컨트롤러 상태로만 판정한다.
        .onChange(of: flow.isConfirming) { _, open in
            if open { dialogTitleFocused = true } else { abandonFocused = flow.focusTarget == .abandonButton }
        }
        .onChange(of: timer.status) { _, _ in flow.clearFailure() }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    // MARK: 확인 창(R16)

    private var dialog: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(JourneyLifecycleText.abandonTitle)
                    .font(FontCatalog.text(22, weight: .bold, relativeTo: .title2)).foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($dialogTitleFocused)
                Text(JourneyLifecycleText.abandonMessageLines)
                    .font(FontCatalog.text(13, relativeTo: .footnote)).foregroundStyle(FMDesign.hintText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .accessibilityLabel(JourneyLifecycleText.abandonMessage)
                VStack(spacing: 13) {
                    Button { flow.cancel() } label: {
                        Text(JourneyLifecycleText.continueTrip).font(FontCatalog.text(15, relativeTo: .body)).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 43)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
                            // 시안의 기본 선택 강조(금색 바깥 테두리).
                            .padding(5.5)
                            .overlay(Capsule().strokeBorder(Color(hex: 0xD7B378), lineWidth: 2))
                            .padding(-5.5)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("journey.abandon.cancel")
                    Button { flow.confirm(isPaused: isPaused) } label: {
                        Text(JourneyLifecycleText.quitTrip).font(FontCatalog.text(15, relativeTo: .body)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 43)
                            .background(Color(hex: 0x111111), in: Capsule())
                            .overlay(Capsule().strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("journey.abandon.confirm")
                }
                .padding(.top, 15)
            }
            .padding(.horizontal, 25).padding(.top, 26).padding(.bottom, 25)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0x0C0C0C)))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .padding(.horizontal, 22)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(JourneyLifecycleText.abandonTitle)
            .accessibilityIdentifier("journey.abandon.dialog")
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { flow.cancel() }
        }
        .transition(.opacity)
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
