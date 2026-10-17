import SwiftUI
import WidgetKit

struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let state: WidgetReadState
}
struct HomeWidgetProvider: TimelineProvider {
    private var store: WidgetSnapshotStore {
        WidgetSnapshotStore(containerURL: { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.focusmate.prototype") })
    }
    func placeholder(in context: Context) -> HomeWidgetEntry { HomeWidgetEntry(date: Date(), state: .unavailable) }
    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
        let now = Date()
        #if DEBUG
        if context.isPreview { completion(HomeWidgetEntry(date: now, state: .valid(HomeWidgetSamples.snapshot(now: now)))); return }
        #endif
        completion(HomeWidgetEntry(date: now, state: store.read(now: now, timeZone: .current)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
        let now = Date()
        let state = store.read(now: now, timeZone: .current)
        let plan = WidgetTimelinePlan.entries(state: state, now: now, timeZone: .current)
        let entries = plan.map { HomeWidgetEntry(date: $0.date, state: $0.state) }
        completion(Timeline(entries: entries, policy: .after(entries.last?.date ?? now.addingTimeInterval(900))))
    }
}

enum HomeWidgetStyle {
    static let charcoal = Color(red: 0.105, green: 0.113, blue: 0.109)
    static let ink = Color(red: 0.94, green: 0.94, blue: 0.91)
    static func minutes(_ value: Int) -> String { value >= 60 ? "\(value / 60)시간 \(value % 60)분" : "\(value)분" }
}
