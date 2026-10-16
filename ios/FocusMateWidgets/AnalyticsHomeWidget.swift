import SwiftUI
import WidgetKit

struct AnalyticsHomeWidget: Widget {
    let kind = "FocusMate.Analytics"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            AnalyticsHomeWidgetView(entry: entry)
                .containerBackground(HomeWidgetStyle.charcoal, for: .widget)
        }
        .configurationDisplayName("집중 기록")
        .description("오늘과 이번 주의 완료 기록을 확인해요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
struct AnalyticsHomeWidgetView: View {
    let entry: HomeWidgetEntry
    var familyOverride: WidgetFamily? = nil
    private var displayFamily: WidgetFamily { familyOverride ?? family }
    @Environment(\.widgetFamily) private var family
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        let content = WidgetPresentation.content(state: entry.state)
        VStack(alignment: .leading, spacing: 7) {
            if let snapshot = content.snapshot {
                if typeSize.isAccessibilitySize {
                    Group {
                        if displayFamily == .systemSmall { small(snapshot, stale: content.isStale) }
                        else { medium(snapshot, stale: content.isStale) }
                    }.dynamicTypeSize(.large)
                } else {
                    if displayFamily == .systemSmall { small(snapshot, stale: content.isStale) }
                    else { medium(snapshot, stale: content.isStale) }
                }
                Spacer(minLength: 0)
                Text(content.basisText).font(.system(size: 9)).foregroundStyle(HomeWidgetStyle.ink.opacity(0.65)).lineLimit(2)
            } else {
                Text("집중 기록").font(.caption).foregroundStyle(HomeWidgetStyle.ink.opacity(0.7))
                Text(content.title).font(typeSize.isAccessibilitySize ? .system(size: 20, weight: .semibold) : .headline).lineLimit(3)
                Spacer(minLength: 0)
                Text("앱 열기 ↗").font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(HomeWidgetStyle.ink)
        .widgetURL(WidgetEntryLinks.analytics(state: entry.state))
        .accessibilityElement(children: .contain)
    }
    private func small(_ snapshot: WidgetSnapshot, stale: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(stale ? "기준일의 집중" : "오늘의 집중").font(.caption)
            Text(HomeWidgetStyle.minutes(snapshot.analytics.today.minutes)).font(.system(size: typeSize.isAccessibilitySize ? 32 : 27, weight: .semibold)).minimumScaleFactor(0.7).lineLimit(1)
            Text("완료한 여정 \(snapshot.analytics.today.count)회").font(.caption2).foregroundStyle(HomeWidgetStyle.ink.opacity(0.7))
            Spacer(minLength: 2)
            Text("\(stale ? "해당 주" : "이번 주") \(HomeWidgetStyle.minutes(snapshot.analytics.weekMinutes)) · \(snapshot.analytics.weekCount)회")
                .font(.caption2).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
    private func medium(_ snapshot: WidgetSnapshot, stale: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(stale ? "해당 주" : "이번 주") 집중 · \(snapshot.analytics.weekCount)회").font(.caption).lineLimit(1)
                Text(HomeWidgetStyle.minutes(snapshot.analytics.weekMinutes)).font(.system(size: 23, weight: .semibold)).minimumScaleFactor(0.7).lineLimit(1)
                Text("\(stale ? "기준일" : "오늘") \(snapshot.analytics.today.minutes)분 · \(snapshot.analytics.today.count)회").font(.caption2)
                ForEach(snapshot.analytics.tags, id: \.id) { tag in
                    if let url = WidgetEntryLinks.analytics(state: entry.state, tag: tag) {
                        Link(destination: url) {
                            HStack(spacing: 4) { Text(tag.name).lineLimit(1); Spacer(minLength: 2); Text("\(tag.minutes)분") }
                                .font(.system(size: 9))
                        }.accessibilityLabel("\(tag.name), \(tag.minutes)분, \(tag.count)회, 해당 주 분석 열기")
                    }
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            weeklyChart(snapshot.analytics.days).frame(maxWidth: .infinity)
        }
    }
    private func weeklyChart(_ days: [WidgetDay]) -> some View {
        let maximum = max(1, days.map(\.minutes).max() ?? 1)
        return HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                if let url = WidgetEntryLinks.analytics(state: entry.state, day: day.day) {
                    Link(destination: url) {
                        VStack(spacing: 5) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 2).fill(HomeWidgetStyle.ink.opacity(day.minutes == 0 ? 0.18 : 0.85))
                                .frame(height: max(3, 63 * Double(day.minutes) / Double(maximum)))
                            Text(["월", "화", "수", "목", "금", "토", "일"][index]).font(.system(size: 9))
                        }.frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel("\(day.day), \(day.minutes)분, \(day.count)회, 해당 주 분석 열기")
                }
            }
        }.frame(height: 86)
    }
}
