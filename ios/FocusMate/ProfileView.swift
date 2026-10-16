import SwiftUI

/// 마이페이지 문구(시안 EPnQQ). 카드 이름은 PassIdentity, 행 이름은 목적지 제목을 단일 출처로 쓴다.
enum ProfileCopy {
    static let headline = "내 시간에, 내 취향을."
    static let subhead = "한 장으로 함께하는 나만의 여정"
    static let cardTagline = "모든 몰입 여정에 함께"
    static let journeysLabel = "완료한 여정"
    static let timeLabel = "함께한 시간"
    static let statsError = "기록을 불러오지 못했어요"
    static let unavailableValue = "-"
}

/// 통계 표시 값. 화면은 시안의 숫자·"min/h", VoiceOver는 "N회"·"분/시간"으로 읽는다.
struct ProfileStatsDisplay: Equatable {
    let journeysText: String
    let timeText: String
    let journeysAccessibilityLabel: String
    let timeAccessibilityLabel: String
    let errorMessage: String?

    init(_ stats: ProfileStats) {
        switch stats {
        case let .loaded(summary):
            journeysText = "\(summary.count)"
            timeText = ProfileTimeText.display(minutes: summary.minutes)
            journeysAccessibilityLabel = "\(ProfileCopy.journeysLabel), \(summary.count)회"
            timeAccessibilityLabel = "\(ProfileCopy.timeLabel), \(ProfileTimeText.spoken(minutes: summary.minutes))"
            errorMessage = nil
        case .unavailable:
            // 값 "-"는 읽지 않고 항목 이름만 읽는다. 이유는 바로 아래 안내 문구가 알려 준다.
            journeysText = ProfileCopy.unavailableValue
            timeText = ProfileCopy.unavailableValue
            journeysAccessibilityLabel = ProfileCopy.journeysLabel
            timeAccessibilityLabel = ProfileCopy.timeLabel
            errorMessage = ProfileCopy.statsError
        }
    }
}

private enum ProfileLayout {
    static let background = Color(red: 0x0F / 255, green: 0x10 / 255, blue: 0x12 / 255)
    static let horizontal: CGFloat = 24
}

/// 마이페이지(읽기 전용). 하단 고정 요소 없이 전체를 스크롤해 가장 큰 글자에서도 모든 요소가 통째로 보이게 한다.
/// 애니메이션이 없어 동작 줄이기 설정과 무관하게 같은 화면이다.
@MainActor
struct ProfileView: View {
    let model: AppModel
    /// 카드 꾸미기 진입. W10 합류 때 주입하는 쪽만 꾸미기 세션 시작으로 바꾼다.
    let onCustomize: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stats = ProfileStatsDisplay(model.profileStats)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(ProfileCopy.headline).font(.title2.bold())
                    .accessibilityIdentifier("profile.headline")
                Text(ProfileCopy.subhead).font(.subheadline).foregroundStyle(.secondary)
                    .padding(.top, 8).accessibilityIdentifier("profile.subhead")
                PassFace(style: model.currentCardStyle).frame(maxWidth: .infinity)
                    .padding(.top, 32).accessibilityIdentifier("profile.card")
                Text(PassIdentity.displayName).font(.title3.bold())
                    .padding(.top, 16).accessibilityIdentifier("profile.cardName")
                Text(ProfileCopy.cardTagline).font(.subheadline).foregroundStyle(.secondary)
                    .padding(.top, 4).accessibilityIdentifier("profile.cardTagline")
                Divider().padding(.top, 28)
                ProfileMenuRow(systemImage: "pencil", title: "카드 꾸미기",
                               identifier: "profile.customize", action: onCustomize)
                statsSection(stats).padding(.top, 20)
                Divider().padding(.top, 32)
                ProfileMenuRow(systemImage: "slider.horizontal.3", title: Destination.settings.title,
                               identifier: "profile.settings") { model.openFromProfile(.settings) }
                ProfileMenuRow(systemImage: "info.circle", title: Destination.dataSource.title,
                               identifier: "profile.dataSource") { model.openFromProfile(.dataSource) }
            }
            .padding(.horizontal, ProfileLayout.horizontal)
            .padding(.vertical, 32)
        }
        .background(ProfileLayout.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar { titleItem }
    }

    /// 시안처럼 뒤로 chevron 오른쪽에 버블 없는 좌측 정렬 제목을 둔다. 바 높이가 고정이라 글자 크기에 상한을 둔다.
    @ToolbarContentBuilder private var titleItem: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) { title }.sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) { title }
        }
    }

    // 툴바는 제목 뷰를 감싸는 래퍼에 바깥 식별자를 복사한다. 바깥 컨테이너에 별도 식별자를 줘
    // 제목 Text의 screen.profile이 한 요소로만 잡히게 한다.
    private var title: some View {
        HStack {
            Text(Destination.profile.title).font(.title2.bold()).fixedSize()
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.profile")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("profile.titleBar")
    }

    @ViewBuilder private func statsSection(_ stats: ProfileStatsDisplay) -> some View {
        // 접근성 크기에서는 세로로 쌓는다. 여정이 위, 시간이 아래라 위→아래 순서는 그대로다.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 24))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        VStack(alignment: .leading, spacing: 12) {
            layout {
                ProfileStatView(value: stats.journeysText, label: ProfileCopy.journeysLabel,
                                accessibilityLabel: stats.journeysAccessibilityLabel, identifier: "profile.stat.journeys")
                ProfileStatView(value: stats.timeText, label: ProfileCopy.timeLabel,
                                accessibilityLabel: stats.timeAccessibilityLabel, identifier: "profile.stat.time")
            }
            if let message = stats.errorMessage {
                Text(message).font(.subheadline).foregroundStyle(.secondary)
                    .accessibilityIdentifier("profile.statsError")
            }
        }
        .padding(.top, 20)
    }
}

private struct ProfileMenuRow: View {
    let systemImage: String
    let title: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage).frame(width: 24).accessibilityHidden(true)
                Text(title)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .padding(.vertical, 20)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
}

private struct ProfileStatView: View {
    let value: String
    let label: String
    let accessibilityLabel: String
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value).font(.title.bold()).lineLimit(1).minimumScaleFactor(0.6)
                .accessibilityIdentifier("\(identifier).value")
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
