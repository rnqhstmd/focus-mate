#if DEBUG
import SwiftUI
import WidgetKit

enum HomeWidgetSamples {
    static func snapshot(now: Date = Date(), empty: Bool = false, phase: WidgetJourneyPhase = .paused) -> WidgetSnapshot {
        let calendar = Calendar(identifier: .gregorian), zone = TimeZone.current
        let day = try! RecordsAnalytics.today(now: now, calendar: calendar, timeZone: zone)
        let period = try! RecordsAnalytics.period(kind: .week, containing: day, calendar: calendar)
        var utc = calendar; utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = period.startDay.split(separator: "-").map { Int($0)! }
        let start = utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
        let days = (0..<7).map { offset -> WidgetDay in
            let instant = utc.date(byAdding: .day, value: offset, to: start)!
            let key = try! RecordsAnalytics.today(now: instant, calendar: utc, timeZone: utc.timeZone)
            let count = !empty && key <= day ? 1 : 0
            return WidgetDay(day: key, minutes: count * 25, count: count)
        }
        let count = days.reduce(0) { $0 + $1.count }
        let idle = phase == .ready || phase == .setup
        let journey = WidgetJourney(phase: phase, journeyID: idle ? nil : "preview-journey", busNumber: idle ? nil : "2014",
            destination: idle ? nil : "성동구민체육센터", totalSeconds: idle ? nil : 1800,
            elapsedSeconds: idle ? nil : phase == .awaitingDeparture ? 0 : phase == .arrived ? 1800 : 678)
        return WidgetSnapshot(version: 1, generatedAt: now, basisDay: day, timeZoneID: zone.identifier, journey: journey,
            analytics: WidgetAnalytics(today: days.first { $0.day == day }!, weekStart: period.startDay, weekEnd: period.endDay,
                weekMinutes: count * 25, weekCount: count, days: days,
                tags: empty ? [] : [WidgetTag(id: .named("독서"), name: "독서", color: "#BFC6C1", minutes: count * 25, count: count)]))
    }
}
#Preview("집중 소형", as: .systemSmall) { FocusPromptWidget() } timeline: {
    HomeWidgetEntry(date: Date(), state: .valid(HomeWidgetSamples.snapshot()))
    HomeWidgetEntry(date: Date(), state: .validEmpty(HomeWidgetSamples.snapshot(empty: true, phase: .ready)))
    HomeWidgetEntry(date: Date(), state: .unavailable)
}
#Preview("집중 중형", as: .systemMedium) { FocusPromptWidget() } timeline: {
    HomeWidgetEntry(date: Date(), state: .valid(HomeWidgetSamples.snapshot(phase: .running)))
    HomeWidgetEntry(date: Date(), state: .stale(HomeWidgetSamples.snapshot()))
}
#Preview("분석 소형", as: .systemSmall) { AnalyticsHomeWidget() } timeline: {
    HomeWidgetEntry(date: Date(), state: .valid(HomeWidgetSamples.snapshot()))
    HomeWidgetEntry(date: Date(), state: .validEmpty(HomeWidgetSamples.snapshot(empty: true)))
}
#Preview("분석 중형", as: .systemMedium) { AnalyticsHomeWidget() } timeline: {
    HomeWidgetEntry(date: Date(), state: .valid(HomeWidgetSamples.snapshot()))
    HomeWidgetEntry(date: Date(), state: .stale(HomeWidgetSamples.snapshot()))
    HomeWidgetEntry(date: Date(), state: .unavailable)
}
#endif
