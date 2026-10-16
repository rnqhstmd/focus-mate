import Foundation

struct WidgetAnalyticsEntry: Equatable {
    let day: String
    let tag: String?
    var kind: AnalyticsPeriodKind = .week
}
struct WidgetNavigationState: Equatable {
    let isReady: Bool
    let needsSetup: Bool
    let activeJourneyID: String?
    let phase: WidgetJourneyPhase
    let isJourneyOpen: Bool
    let hasOtherOpenFlow: Bool
}
enum WidgetNavigationDecision: Equatable {
    case safeHome, deferUntilReady, alreadyOpen, showSetup, prepare, showDeparture, showActiveJourney, alight, confirmNewJourney
    case analytics(day: String, tag: String?, kind: AnalyticsPeriodKind = .week)
}
enum WidgetNavigationPolicy {
    static func decide(link: WidgetLinkParseResult, state: WidgetNavigationState, now: Date, calendar: Calendar, timeZone: TimeZone) -> WidgetNavigationDecision {
        guard state.isReady else { return .deferUntilReady }
        guard !state.isJourneyOpen, !state.hasOtherOpenFlow else { return .alreadyOpen }
        guard case .valid(let value) = link else { return .safeHome }
        guard !state.needsSetup else { return .showSetup }
        switch value.target {
        case .journey(let expected), .newJourney(let expected):
            let matches: Bool
            switch (expected, state.activeJourneyID) {
            case (nil, nil): matches = true
            case (let lhs?, let rhs?): matches = lhs.utf16.elementsEqual(rhs.utf16)
            default: matches = false
            }
            guard matches else { return .safeHome }
            if case .newJourney = value.target, state.activeJourneyID != nil {
                return state.phase == .arrived ? .alight : .confirmNewJourney
            }
            switch state.phase {
            case .setup: return .showSetup
            case .ready: return .prepare
            case .awaitingDeparture: return .showDeparture
            case .running, .paused: return .showActiveJourney
            case .arrived: return .alight
            }
        case .analytics(let requested, let tag, let kind):
            guard let today = try? RecordsAnalytics.today(now: now, calendar: calendar, timeZone: timeZone) else { return .safeHome }
            let day = requested.flatMap { candidate -> String? in
                guard candidate <= today, (try? RecordsAnalytics.period(kind: kind, containing: candidate, calendar: calendar)) != nil else { return nil }
                return candidate
            } ?? today
            return .analytics(day: day, tag: tag, kind: kind)
        }
    }
}
