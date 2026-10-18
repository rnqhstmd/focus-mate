import SwiftUI

/// 메인 진행 여정 카드. 정보 묶음은 한 요소로 읽히고, 이어가기·하차하기 버튼은 따로 읽힌다(FR-1, FR-12).
/// 컨테이너에는 식별자를 두지 않는다 — 스크롤 뷰 안 중첩 컨테이너의 식별자는 흡수될 수 있다.
struct ActiveJourneyCardView: View {
    let content: ActiveJourneyCardContent
    let onResume: () -> Void
    let onAlight: () -> Void

    var body: some View {
        // 시안 R31·R34: 제목 21 Bold → 할 일 17 Bold #AAAAAA → 버스 줄(오른쪽 상태 14 Bold) → 노선 12 #A6B1A8 → 51pt 버튼.
        // 간격은 Noto 줄 높이(1.45em)를 뺀 값이다(시안 줄 위끝 기준 26/21/11/28).
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(content.title).font(FontCatalog.text(21, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(.white)
                Text(content.task).font(FontCatalog.text(17, weight: .bold))
                    .foregroundStyle(Color(hex: 0xAAAAAA))
                    .padding(.top, 17.5)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(content.busText).font(FontCatalog.text(13, relativeTo: .subheadline))
                        .foregroundStyle(Color(hex: 0xC1CBC3))
                    Spacer(minLength: 0)
                    if let status = content.statusText {
                        Text(status).font(FontCatalog.text(14, weight: .bold, relativeTo: .subheadline))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.top, 14)
                Text(content.routeText).font(FontCatalog.text(12, relativeTo: .caption))
                    .foregroundStyle(Color(hex: 0xA6B1A8))
                    .padding(.top, 5)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(content.accessibilityLabel)
            .accessibilityIdentifier("main.activeJourney")
            if content.showsResume {
                Button(action: onResume) {
                    Text(JourneyLifecycleText.resumeButton).frame(maxWidth: .infinity)
                }
                .buttonStyle(FMPrimaryButtonStyle())
                .accessibilityLabel(JourneyLifecycleText.resumeButtonLabel)
                .accessibilityIdentifier("main.resumeJourney")
                .padding(.top, 25)
            }
            if content.showsAlight {
                // 시안 R34: 도착 카드도 "이전 여정 이어가기 →"를 보인다. 누르면 기존 하차 흐름으로 간다.
                Button(action: onAlight) {
                    Text(JourneyLifecycleText.alightButton).frame(maxWidth: .infinity)
                }
                .buttonStyle(FMPrimaryButtonStyle())
                .accessibilityLabel(JourneyLifecycleText.alightButtonLabel)
                .accessibilityIdentifier("open.alighting")
                .padding(.top, 25)
            }
        }
        .foregroundStyle(FMDesign.primary)
        .padding(.top, 21).padding(.horizontal, 20).padding(.bottom, 20)
        .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// 진행 여정 메인의 "새 여정 시작"(시안 R31·R34): 366x44 캡슐, #0A0A0A 85%, 흰 21% 테두리, 13pt 흰 글자.
struct FMNewJourneyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FontCatalog.text(13, relativeTo: .subheadline))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(FMDesign.panel.opacity(0.85), in: Capsule())
            .overlay { Capsule().strokeBorder(Color.white.opacity(0.21), lineWidth: 1) }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// 포기 뒤 메인 안내. 안내가 생길 때만 배치한다 — 빈 자리도 스택 간격을 차지해 큰 글씨에서 아래 메뉴를 밀어낸다.
/// 나타나면 초점을 준다. 낭독은 RootView가 안내 값이 바뀔 때 한 번 한다.
struct MainAbandonNoticeView: View {
    let stationName: String
    @AccessibilityFocusState private var focused: Bool

    var body: some View {
        Text(JourneyLifecycleText.abandonNotice(stationName: stationName))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("main.abandonNotice")
            .accessibilityFocused($focused)
            .onAppear { focused = true }
    }
}

extension View {
    /// 메인 '새 여정 시작' 확인 창(시안 R32). 시스템 alert 대신 직접 그린 창을 화면 전체 위에 띄운다.
    /// 안전한 선택(이전 여정 유지하기)이 위에 있고 기본 초점이며, 닫기 동작(escape)도 유지하기다.
    func newJourneyConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        overlay {
            if isPresented.wrappedValue {
                NewJourneyDialog(isPresented: isPresented, onConfirm: onConfirm)
            }
        }
    }
}

/// 시안 R32: 검정 60% 배경, 358폭 #0C0C0C 창(반경 24, 흰 25% 테두리), 제목 23 Bold, 본문 13 #AAAAAA,
/// 세로 버튼 "이전 여정 유지하기"(흰 캡슐 + 금색 바깥 테두리) → "새 여정 시작"(#111111 흰 글자, 빨강 아님).
struct NewJourneyDialog: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @AccessibilityFocusState private var keepFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(JourneyLifecycleText.newJourneyTitle)
                    .font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(JourneyLifecycleText.newJourneyMessage)
                    .font(FontCatalog.text(13, relativeTo: .footnote)).foregroundStyle(FMDesign.hintText)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
                VStack(spacing: 13) {
                    Button { isPresented = false } label: {
                        Text(JourneyLifecycleText.keepJourney).font(FontCatalog.text(15, relativeTo: .body)).foregroundStyle(.black)
                            .multilineTextAlignment(.center)
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
                    .accessibilityIdentifier("main.newJourney.keep")
                    .accessibilityFocused($keepFocused)
                    Button {
                        isPresented = false
                        onConfirm()
                    } label: {
                        Text(JourneyLifecycleText.newJourneyButton).font(FontCatalog.text(15, relativeTo: .body)).foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 43)
                            .background(Color(hex: 0x111111), in: Capsule())
                            .overlay(Capsule().strokeBorder(FMDesign.ctaStroke, lineWidth: 1))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("main.newJourney.confirm")
                }
                .padding(.top, 16)
                .padding(.horizontal, 1)
            }
            .padding(.horizontal, 25).padding(.top, 23).padding(.bottom, 25)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(hex: 0x0C0C0C)))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
            .padding(.horizontal, 22)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(JourneyLifecycleText.newJourneyTitle)
            .accessibilityIdentifier("main.newJourney.dialog")
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { isPresented = false }
        }
        // 시안: 창은 안전 영역이 아니라 화면 전체의 세로 가운데(y=311~563)에 온다.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .transition(.opacity)
        .onAppear { keepFocused = true }
    }
}
