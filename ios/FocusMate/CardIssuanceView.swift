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
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Focus Mate")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .padding(.top, 12).padding(.bottom, 46)
                    Text(displayTitle)
                        .font(FontCatalog.text(28, bold: true, relativeTo: .title))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityValue(isIssued ? CardIssuanceCopy.issuedTitle : CardIssuanceCopy.readyTitle)
                        .accessibilityIdentifier("card.title")
                    Text(showsCard ? "오늘부터, 나만의 시간으로.\n이 카드가 매 여정에 함께해요." : "독서도, 작업도, 잠깐의 쉼도.\n한 장의 카드로 나만의 여정을 시작해요.")
                        .font(.subheadline).lineSpacing(5)
                        .foregroundStyle(Color(red: 0.76, green: 0.80, blue: 0.77))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18)
                    Spacer(minLength: 30)
                    cardStage
                    Spacer(minLength: 30)
                }
                .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 116), alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 18) {
                    if controller.phase == .failed {
                        Text(CardIssuanceCopy.issueError)
                            .font(.footnote).fixedSize(horizontal: false, vertical: true)
                            .accessibilityValue(CardIssuanceCopy.issueError)
                            .accessibilityIdentifier("card.issueError")
                    }
                    Text(showsCard ? CardIssuanceCopy.issuedHint : CardIssuanceCopy.readyHint)
                        .font(.footnote).foregroundStyle(Color(red: 0.67, green: 0.73, blue: 0.68))
                        .multilineTextAlignment(.center)
                    actionButton
                }.padding(.top, 12).padding(.bottom, 12)
            }
        }
        .background(Color(red: 0x10 / 255, green: 0x11 / 255, blue: 0x12 / 255).ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.cardEntry")
        .onChange(of: controller.focusTarget) { _, target in continueFocused = target == .continueButton }
    }

    private var displayTitle: String {
        if isIssued { return "카드가 발급됐어요.\n이제, 어디에서 출발할까요?" }
        if controller.phase == .issuing { return "나만의 카드를\n발급하고 있어요." }
        return "집중동행카드를\n발급받아볼까요?"
    }

    private var cardStage: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.black)
                .overlay(Capsule().stroke(Color(red: 0.34, green: 0.39, blue: 0.35)))
                .frame(width: 214, height: 7)
                .accessibilityHidden(true)
            ZStack {
                if showsCard {
                    PassFace()
                        .accessibilityIdentifier("card.face")
                        .offset(y: cardOut ? 0 : -42)
                        .mask(alignment: .bottom) {
                            Rectangle().scaleEffect(y: cardOut ? 1 : 0.02, anchor: .bottom)
                        }
                        .onAppear { slideOut() }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "creditcard").font(.system(size: 31, weight: .light))
                        Text("당신의 여정이 담길 한 장").font(.footnote)
                    }
                    .foregroundStyle(Color(red: 0.65, green: 0.72, blue: 0.67))
                    .frame(maxWidth: .infinity, minHeight: 184)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.43, green: 0.51, blue: 0.45).opacity(0.4)))
                    .accessibilityHidden(true)
                }
            }
            if isIssued {
                Label("발급 완료", systemImage: "checkmark.circle")
                    .font(.footnote).foregroundStyle(Color(red: 0.71, green: 0.83, blue: 0.73))
            }
        }
        .frame(maxWidth: 292)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var actionButton: some View {
        if isIssued {
            Button { controller.proceed() } label: { buttonLabel(CardIssuanceCopy.continueButton) }
                .buttonStyle(FMPrimaryButtonStyle())
                .accessibilityIdentifier("card.continueButton")
                .accessibilityFocused($continueFocused)
        } else {
            Button {
                Task { await controller.issue(reduceMotion: reduceMotion) }
            } label: {
                buttonLabel(controller.phase == .issuing ? CardIssuanceCopy.issuingButton
                            : controller.phase == .failed ? CardIssuanceCopy.retryButton : CardIssuanceCopy.issueButton)
            }
            .buttonStyle(FMPrimaryButtonStyle())
            .disabled(controller.phase == .issuing)
            .accessibilityIdentifier("card.issueButton")
        }
    }

    private func buttonLabel(_ title: String) -> some View {
        Text(title).frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }

    private func slideOut() {
        guard !cardOut else { return }
        if reduceMotion { cardOut = true; return }
        withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: CardIssuanceTiming.slotAnimation)) { cardOut = true }
    }
}
