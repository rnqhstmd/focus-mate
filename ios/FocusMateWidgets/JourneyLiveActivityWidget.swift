import ActivityKit
import SwiftUI
import WidgetKit

private enum JourneyActivityPalette {
    static let charcoal = Color(red: 0.08, green: 0.085, blue: 0.09)
    static let paper = Color(red: 0.95, green: 0.945, blue: 0.92)
}

/// 시간·상태는 같은 presentation에서 읽고 실제 시간 진행은 시스템 renderer에 맡긴다.
struct JourneyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JourneyActivityAttributes.self) { context in
            let presentation = JourneyActivityDisplay.presentation(state: context.state, isStale: context.isStale, now: .now)
            JourneyLockScreenView(attributes: context.attributes, presentation: presentation)
                .activityBackgroundTint(JourneyActivityPalette.charcoal)
                .activitySystemActionForegroundColor(JourneyActivityPalette.paper)
        } dynamicIsland: { context in
            let presentation = JourneyActivityDisplay.presentation(state: context.state, isStale: context.isStale, now: .now)
            let summary = JourneyActivityDisplay.accessibilitySummary(attributes: context.attributes, presentation: presentation)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(JourneyActivityDisplay.busTitle(busNumber: context.attributes.busNumber, busKind: context.attributes.busKind))
                        .font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                        .accessibilityLabel(summary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        JourneyActivityTimeText(presentation: presentation)
                            .font(.title2.weight(.semibold).monospacedDigit())
                        Text(presentation.status == .running ? "남은 집중 시간" : JourneyActivityDisplay.statusName(presentation.status))
                            .font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    JourneyActivityTimeline(destination: context.attributes.destinationName, presentation: presentation)
                        .padding(.top, 6).accessibilityHidden(true)
                }
            } compactLeading: {
                Image(systemName: presentation.statusSymbol)
                    .foregroundStyle(JourneyActivityPalette.paper)
                    .accessibilityLabel(summary)
            } compactTrailing: {
                JourneyActivityTimeText(presentation: presentation)
                    .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                    .lineLimit(1).minimumScaleFactor(0.75).frame(maxWidth: 64)
            } minimal: {
                Image(systemName: presentation.statusSymbol)
                    .foregroundStyle(JourneyActivityPalette.paper)
                    .accessibilityLabel(summary)
                    .accessibilityValue(presentation.status == .arrived ? Text("") : JourneyActivityTimeText.text(presentation.time))
            }
            .keylineTint(JourneyActivityPalette.paper)
        }
    }
}

struct JourneyLockScreenView: View {
    let attributes: JourneyActivityAttributes
    let presentation: JourneyActivityPresentation

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: presentation.statusSymbol).font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(JourneyActivityDisplay.busTitle(busNumber: attributes.busNumber, busKind: attributes.busKind))
                        .font(.headline).lineLimit(1)
                    Text(attributes.destinationName).font(.subheadline).lineLimit(1)
                    Text(JourneyActivityDisplay.statusName(presentation.status)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(JourneyActivityDisplay.accessibilitySummary(attributes: attributes, presentation: presentation))
            JourneyActivityTimeText(presentation: presentation)
                .font(.title2.weight(.semibold).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(JourneyActivityPalette.paper)
        .padding(18)
    }
}

struct JourneyActivityTimeline: View {
    let destination: String
    let presentation: JourneyActivityPresentation

    var body: some View {
        VStack(spacing: 8) {
            if presentation.progress != .hidden {
                HStack(spacing: 10) {
                    // 이 심볼은 여정 표시다. 진행 위치는 시스템 막대의 채움만 나타낸다.
                    Image(systemName: presentation.statusSymbol).font(.system(size: 16, weight: .medium))
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<25, id: \.self) { index in
                                Rectangle().fill(JourneyActivityPalette.paper.opacity(index.isMultiple(of: 6) ? 0.8 : 0.35))
                                    .frame(width: 1, height: index.isMultiple(of: 6) ? 9 : 4)
                                if index != 24 { Spacer(minLength: 1) }
                            }
                        }
                        switch presentation.progress {
                        case .timer(let range):
                            ProgressView(timerInterval: range, countsDown: false)
                                .progressViewStyle(.linear).labelsHidden()
                        case .fixed(let fraction):
                            ProgressView(value: fraction).progressViewStyle(.linear)
                        case .hidden: EmptyView()
                        }
                    }
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(presentation.status == .running ? "출발" : JourneyActivityDisplay.statusName(presentation.status))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(destination).lineLimit(1).truncationMode(.tail)
            }
            .font(.caption)
        }
        .tint(JourneyActivityPalette.paper)
        .foregroundStyle(JourneyActivityPalette.paper)
    }
}

struct JourneyActivityTimeText: View {
    let presentation: JourneyActivityPresentation

    static func text(_ content: JourneyActivityTimeContent) -> Text {
        switch content {
        case .countdown(let range): Text(timerInterval: range, countsDown: true, showsHours: false)
        case .fixed(let value): Text(value)
        }
    }

    var body: some View {
        Self.text(presentation.time)
            .accessibilityHint(Text("남은 집중 시간"))
            .accessibilityHidden(presentation.status == .arrived)
    }
}
