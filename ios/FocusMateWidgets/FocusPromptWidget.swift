import SwiftUI
import WidgetKit

struct FocusPromptWidget: Widget {
    let kind = "FocusMate.FocusPrompt"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            FocusPromptWidgetView(entry: entry)
                .containerBackground(HomeWidgetStyle.charcoal, for: .widget)
        }
        .configurationDisplayName("다음 집중")
        .description("지금의 여정을 확인하고 다음 집중을 준비해요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
struct FocusPromptWidgetView: View {
    let entry: HomeWidgetEntry
    var familyOverride: WidgetFamily? = nil
    private var displayFamily: WidgetFamily { familyOverride ?? family }
    @Environment(\.widgetFamily) private var family
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        let content = WidgetPresentation.content(state: entry.state)
        Group {
            if typeSize.isAccessibilitySize { compact(content) }
            else {
            VStack(alignment: .leading, spacing: 8) {
            Text(content.title).font(displayFamily == .systemSmall ? .headline : .title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
            if !content.subtitle.isEmpty {
                Text(content.subtitle).font(.caption).foregroundStyle(HomeWidgetStyle.ink.opacity(0.72)).lineLimit(displayFamily == .systemSmall ? 2 : 1)
            }
            if let progress = content.progress {
                ProgressView(value: progress).tint(HomeWidgetStyle.ink)
                Text("저장된 진행 \(Int((progress * 100).rounded()))%").font(.caption2).foregroundStyle(HomeWidgetStyle.ink.opacity(0.72))
            }
            Spacer(minLength: 0)
            HStack {
                Text(content.actionTitle).font(.caption.weight(.semibold))
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right").font(.caption)
            }
            if !content.basisText.isEmpty {
                Text(content.basisText).font(.system(size: 9)).foregroundStyle(HomeWidgetStyle.ink.opacity(0.65)).lineLimit(2)
            }
        }
            }
        }
        .foregroundStyle(HomeWidgetStyle.ink)
        .widgetURL(WidgetEntryLinks.focus(state: entry.state))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.axSummary + ", " + content.actionTitle)
    }
    private func compact(_ content: WidgetDisplayContent) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(content.title).font(.system(size: 20, weight: .semibold)).lineLimit(2).minimumScaleFactor(0.75)
            if displayFamily == .systemMedium, !content.subtitle.isEmpty {
                Text(content.subtitle).font(.system(size: 12)).lineLimit(1).foregroundStyle(HomeWidgetStyle.ink.opacity(0.72))
            }
            if let progress = content.progress {
                ProgressView(value: progress).tint(HomeWidgetStyle.ink)
                Text("저장된 진행 \(Int((progress * 100).rounded()))%").font(.system(size: 12))
            }
            Spacer(minLength: 0)
            HStack { Text(content.actionTitle); Spacer(minLength: 2); Image(systemName: "arrow.up.right") }
                .font(.system(size: 13, weight: .semibold))
            if !content.basisText.isEmpty { Text(content.basisText).font(.system(size: 9)).lineLimit(2) }
        }
    }

}
