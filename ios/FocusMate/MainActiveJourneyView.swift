import SwiftUI

/// 메인 진행 여정 카드. 정보 묶음은 한 요소로 읽히고, 이어가기·하차하기 버튼은 따로 읽힌다(FR-1, FR-12).
/// 컨테이너에는 식별자를 두지 않는다 — 스크롤 뷰 안 중첩 컨테이너의 식별자는 흡수될 수 있다.
struct ActiveJourneyCardView: View {
    let content: ActiveJourneyCardContent
    let onResume: () -> Void
    let onAlight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title).font(.headline)
                Text(content.task)
                Text(content.busText).foregroundStyle(.secondary)
                if let remaining = content.remainingText { Text(remaining).font(.title3.bold()) }
                Text(content.routeText).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(content.accessibilityLabel)
            .accessibilityIdentifier("main.activeJourney")
            if content.showsResume {
                // 버튼 바깥 frame은 누르는 영역을 늘리지 않으므로 글자 쪽에서 44pt를 확보한다(QE-2).
                Button(action: onResume) {
                    Text(JourneyLifecycleText.resumeButton).frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(JourneyLifecycleText.resumeButtonLabel)
                .accessibilityIdentifier("main.resumeJourney")
            }
            if content.showsAlight {
                Button(action: onAlight) {
                    Text(JourneyLifecycleText.alightButton).frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("open.alighting")
            }
        }
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
    /// 메인 '새 여정 시작' 확인 창. 안전한 선택(이전 여정 유지하기)이 취소 위치다.
    func newJourneyConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert(JourneyLifecycleText.newJourneyTitle, isPresented: isPresented) {
            Button(JourneyLifecycleText.keepJourney, role: .cancel) {}
                .accessibilityIdentifier("main.newJourney.keep")
            Button(JourneyLifecycleText.newJourneyButton, role: .destructive, action: onConfirm)
                .accessibilityIdentifier("main.newJourney.confirm")
        } message: {
            Text(JourneyLifecycleText.newJourneyMessage)
        }
    }
}
