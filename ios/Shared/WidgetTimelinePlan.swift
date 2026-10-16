import Foundation

struct WidgetTimelineValue: Equatable {
    let date: Date
    let state: WidgetReadState
}
enum WidgetTimelinePlan {
    static func entries(state: WidgetReadState, now: Date, timeZone: TimeZone) -> [WidgetTimelineValue] {
        let next = WidgetPresentation.nextRefreshDate(state: state, now: now, timeZone: timeZone)
        let future: WidgetReadState
        switch state {
        case .valid(let snapshot), .validEmpty(let snapshot), .stale(let snapshot):
            future = WidgetFreshness.classify(.valid(snapshot), now: next, timeZone: timeZone)
        default: future = state
        }
        return [WidgetTimelineValue(date: now, state: state), WidgetTimelineValue(date: next, state: future)]
    }
}
