import SwiftUI

enum CardIssuanceCopy {
    static let readyTitle = "집중동행카드를 발급받아볼까요?"
    static let readyBody = "독서도, 작업도, 잠깐의 쉼도. 한 장의 카드로 나만의 여정을 시작해요."
    static let readyHint = "한 번 발급받아, 모든 몰입 여정에 사용해요."
    static let issuedTitle = "카드가 발급됐어요. 이제, 어디에서 출발할까요?"
    static let issuedBody = "오늘부터, 나만의 시간으로. 이 카드가 매 여정에 함께해요."
    static let issuedHint = "발급받은 카드는 승차할 때와 하차할 때 사용해요."
    static let issueButton = "집중동행카드 발급받기"
    static let issuingButton = "카드를 발급하고 있어요"
    static let retryButton = "다시 발급받기"
    static let continueButton = "출발지 선택하기"
    static let issueError = CardIssuanceController.failedAnnouncement
}

/// 카드 발급 화면. 상태는 `CardIssuanceController`가 갖고, 이 뷰는 그리기와 시스템 동작 줄이기 전달만 한다.
struct CardIssuanceView: View {
    let controller: CardIssuanceController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var continueFocused: Bool
    @State private var cardOut = false

    private var isIssued: Bool { controller.phase == .issued }
    private var showsCard: Bool { controller.phase == .issuing || isIssued }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isIssued ? CardIssuanceCopy.issuedTitle : CardIssuanceCopy.readyTitle)
                    .font(.title.bold())
                    .accessibilityValue(isIssued ? CardIssuanceCopy.issuedTitle : CardIssuanceCopy.readyTitle)
                    .accessibilityIdentifier("card.title")
                Text(isIssued ? CardIssuanceCopy.issuedBody : CardIssuanceCopy.readyBody)
                    .foregroundStyle(.secondary)
                cardStage
                Text(isIssued ? CardIssuanceCopy.issuedHint : CardIssuanceCopy.readyHint)
                    .font(.footnote).foregroundStyle(.secondary)
                if controller.phase == .failed {
                    Text(CardIssuanceCopy.issueError)
                        .accessibilityValue(CardIssuanceCopy.issueError)
                        .accessibilityIdentifier("card.issueError")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .bottom) { actionButton.padding(.top, 12) }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.cardEntry")
        .onChange(of: controller.focusTarget) { _, target in continueFocused = target == .continueButton }
    }

    private var cardStage: some View {
        ZStack(alignment: .top) {
            Capsule().fill(.secondary.opacity(0.4)).frame(width: 180, height: 6)
            if showsCard {
                PassFace()
                    .accessibilityIdentifier("card.face")
                    .offset(y: cardOut ? 0 : -42)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(maxHeight: .infinity).scaleEffect(y: cardOut ? 1 : 0.02, anchor: .bottom)
                    }
                    .padding(.top, 14)
                    .onAppear { slideOut() }
            }
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var actionButton: some View {
        if isIssued {
            Button { controller.proceed() } label: { buttonLabel(CardIssuanceCopy.continueButton) }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("card.continueButton")
                .accessibilityFocused($continueFocused)
        } else {
            Button {
                Task { await controller.issue(reduceMotion: reduceMotion) }
            } label: {
                buttonLabel(controller.phase == .issuing ? CardIssuanceCopy.issuingButton
                            : controller.phase == .failed ? CardIssuanceCopy.retryButton : CardIssuanceCopy.issueButton)
            }
            .buttonStyle(.borderedProminent)
            .disabled(controller.phase == .issuing)
            .accessibilityIdentifier("card.issueButton")
        }
    }

    private func buttonLabel(_ title: String) -> some View {
        Text(title).frame(maxWidth: .infinity, minHeight: 44).multilineTextAlignment(.center)
    }

    private func slideOut() {
        guard !cardOut else { return }
        if reduceMotion { cardOut = true; return }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: CardIssuanceTiming.slotAnimation)) { cardOut = true }
    }
}
