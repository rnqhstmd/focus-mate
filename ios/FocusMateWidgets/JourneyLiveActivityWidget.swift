import ActivityKit
import SwiftUI
import WidgetKit

/// 여행 진행 표시(잠금 화면·다이나믹 아일랜드). 문구·시간 선택은 `JourneyActivityDisplay`가 정하고 여기서는 그리기만 한다.
struct JourneyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JourneyActivityAttributes.self) { context in
            JourneyLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.busNumber, systemImage: "bus.fill").font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    JourneyActivityTimeText(context: context).font(.title3.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.attributes.destinationName).lineLimit(1)
                        Spacer()
                        Text(statusName(context))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "bus.fill")
                    .accessibilityLabel(JourneyActivityDisplay.compactAccessibilityLabel(busNumber: context.attributes.busNumber))
            } compactTrailing: {
                JourneyActivityTimeText(context: context).monospacedDigit().frame(maxWidth: 56)
            } minimal: {
                JourneyActivityTimeText(context: context).monospacedDigit()
            }
        }
    }
}

private func statusName(_ context: ActivityViewContext<JourneyActivityAttributes>) -> String {
    JourneyActivityDisplay.statusName(JourneyActivityDisplay.displayStatus(state: context.state, isStale: context.isStale))
}

private struct JourneyLockScreenView: View {
    let context: ActivityViewContext<JourneyActivityAttributes>

    var body: some View {
        // 설명(버스·도착지·상태)과 카운트다운을 따로 둔다. 하나로 합치면 운행 중 남은 시간이 읽히지 않는다.
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bus.fill").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(JourneyActivityDisplay.busTitle(busNumber: context.attributes.busNumber,
                                                         busKind: context.attributes.busKind)).font(.headline)
                    Text(context.attributes.destinationName).font(.subheadline).lineLimit(1)
                }
                Spacer()
                Text(statusName(context)).font(.caption)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(JourneyActivityDisplay.accessibilityLabel(attributes: context.attributes,
                                                                         state: context.state, isStale: context.isStale))
            JourneyActivityTimeText(context: context).font(.title2.monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(16)
    }
}

/// 운행 중은 시스템 카운트다운, 일시정지·만료는 정적 문자열.
private struct JourneyActivityTimeText: View {
    let context: ActivityViewContext<JourneyActivityAttributes>

    var body: some View {
        switch JourneyActivityDisplay.timeContent(state: context.state, isStale: context.isStale, now: .now) {
        case .countdown(let range): Text(timerInterval: range, countsDown: true, showsHours: false)
        case .fixed(let text): Text(text)
        }
    }
}
