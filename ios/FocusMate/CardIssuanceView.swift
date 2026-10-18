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
    /// 발급된 카드 번호("FM · 0842 3017"). 발급 직후부터 카드 앞면 왼쪽 아래에 보인다(R36·R37).
    var numberText: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var continueFocused: Bool
    @State private var cardOut = false

    private var isIssued: Bool { controller.phase == .issued }
    private var showsCard: Bool { controller.phase == .issuing || isIssued }

    // 시안 R35~R37 세로 배치. 간격은 시안 글자 상자(줄 높이 = 글자 크기)를 Noto 줄 높이(1.448배) 프레임으로 환산한 값이다.
    private enum Metric {
        static let titleTop: CGFloat = 50
        static let bodyTop: CGFloat = 20
        static let slotTop: CGFloat = 73
        static let cardTop: CGFloat = 31
        static let issuedTop: CGFloat = 17
        static let hintToButton: CGFloat = 24
        static let buttonBottom: CGFloat = 5
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Focus Mate")
                    .font(FontCatalog.text(16, weight: .bold, relativeTo: .subheadline))
                Text(displayTitle)
                    .font(FontCatalog.text(28, weight: .bold, relativeTo: .title))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityValue(isIssued ? CardIssuanceCopy.issuedTitle : CardIssuanceCopy.readyTitle)
                    .accessibilityIdentifier("card.title")
                    .padding(.top, Metric.titleTop)
                Text(showsCard ? "오늘부터, 나만의 시간으로.\n이 카드가 매 여정에 함께해요." : "독서도, 작업도, 잠깐의 쉼도.\n한 장의 카드로 나만의 여정을 시작해요.")
                    .font(FontCatalog.text(14, relativeTo: .subheadline)).lineSpacing(3.7)
                    .foregroundStyle(Color(hex: 0xC1CDC4))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Metric.bodyTop)
                cardStage.padding(.top, Metric.slotTop)
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Metric.hintToButton) {
                if controller.phase == .failed {
                    Text(CardIssuanceCopy.issueError)
                        .font(FontCatalog.text(12, relativeTo: .footnote)).fixedSize(horizontal: false, vertical: true)
                        .accessibilityValue(CardIssuanceCopy.issueError)
                        .accessibilityIdentifier("card.issueError")
                }
                Text(showsCard ? CardIssuanceCopy.issuedHint : CardIssuanceCopy.readyHint)
                    .font(FontCatalog.text(12, relativeTo: .footnote)).foregroundStyle(Color(hex: 0xAAB9AE))
                    .multilineTextAlignment(.center)
                actionButton
            }
            .padding(.horizontal, 26.5).padding(.top, 12).padding(.bottom, Metric.buttonBottom)
        }
        .background(Color(hex: 0x101112).ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.cardEntry")
        .onChange(of: controller.focusTarget) { _, target in continueFocused = target == .continueButton }
    }

    private var displayTitle: String {
        if isIssued { return "카드가 발급됐어요.\n이제, 어디에서 출발할까요?" }
        if controller.phase == .issuing { return "나만의 카드를\n발급하고 있어요." }
        return "집중동행카드를\n발급받아볼까요?"
    }

    /// 카드 슬롯 막대. 발급 중에는 초록빛으로 켜진다(R36).
    private var slot: some View {
        let lit = controller.phase == .issuing
        return Capsule()
            .fill(Color(hex: lit ? 0x819B88 : 0x040805))
            .overlay(Capsule().stroke(Color(hex: lit ? 0xA6C8B0 : 0x566359), lineWidth: 1))
            .frame(width: 213, height: 6)
            .accessibilityHidden(true)
    }

    private var cardStage: some View {
        VStack(spacing: 0) {
            slot
            ZStack {
                if showsCard {
                    PassFace(layout: .issue, numberText: numberText)
                        .accessibilityIdentifier("card.face")
                        .offset(y: cardOut ? 0 : -42)
                        .mask(alignment: .bottom) {
                            Rectangle().scaleEffect(y: cardOut ? 1 : 0.02, anchor: .bottom)
                        }
                        .onAppear { slideOut() }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "plus.rectangle").font(.system(size: 20, weight: .regular))
                        Text("당신의 여정이 담길 한 장").font(FontCatalog.text(13, relativeTo: .footnote))
                    }
                    .padding(.top, 6)
                    .foregroundStyle(Color(hex: 0xA6B7AA))
                    .frame(maxWidth: .infinity, minHeight: 184)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x6E8274).opacity(0x63 / 255)))
                    .accessibilityHidden(true)
                }
            }
            .padding(.top, Metric.cardTop)
            if isIssued {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold)).accessibilityHidden(true)
                    Text("발급 완료").font(FontCatalog.text(13, relativeTo: .footnote))
                }
                .foregroundStyle(Color(hex: 0xB4D4BB))
                .accessibilityElement(children: .combine)
                .padding(.top, Metric.issuedTop)
            }
        }
        .frame(maxWidth: 292)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var actionButton: some View {
        if isIssued {
            Button { controller.proceed() } label: { buttonLabel(CardIssuanceCopy.continueButton) }
                .buttonStyle(FMPrimaryButtonStyle(size: .issuance))
                .accessibilityIdentifier("card.continueButton")
                .accessibilityFocused($continueFocused)
        } else {
            Button {
                Task { await controller.issue(reduceMotion: reduceMotion) }
            } label: {
                buttonLabel(controller.phase == .issuing ? CardIssuanceCopy.issuingButton
                            : controller.phase == .failed ? CardIssuanceCopy.retryButton : CardIssuanceCopy.issueButton)
            }
            .buttonStyle(FMPrimaryButtonStyle(size: .issuance))
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
