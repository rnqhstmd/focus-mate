import Foundation
@testable import FocusMate

/// W18 테스트 값만 제공한다. 생산 타입·함수는 정의하지 않는다.
enum WidgetFixtures {
    static let utc = TimeZone(secondsFromGMT: 0)!
    static func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }
    static var generated: Date { date("2026-10-16T12:00:00Z") }
    static var journey: WidgetJourney {
        WidgetJourney(phase: .paused, journeyID: "journey-독서", busNumber: "2014", destination: "성동구민체육센터", totalSeconds: 1800, elapsedSeconds: 678)
    }
    static func snapshot(empty: Bool = false, version: Int = 1, total: Int? = nil) -> WidgetSnapshot {
        let days = [
            WidgetDay(day: "2026-10-12", minutes: empty ? 0 : 30, count: empty ? 0 : 2),
            WidgetDay(day: "2026-10-13", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-14", minutes: empty ? 0 : 30, count: empty ? 0 : 1),
            WidgetDay(day: "2026-10-15", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-16", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-17", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-18", minutes: 0, count: 0)
        ]
        return WidgetSnapshot(
            version: version, generatedAt: generated, basisDay: "2026-10-16", timeZoneID: "GMT",
            journey: journey,
            analytics: WidgetAnalytics(
                today: WidgetDay(day: "2026-10-16", minutes: 0, count: 0),
                weekStart: "2026-10-12", weekEnd: "2026-10-18",
                weekMinutes: total ?? (empty ? 0 : 60), weekCount: empty ? 0 : 3,
                days: days,
                tags: empty ? [] : [WidgetTag(id: .named("독서"), name: "독서", color: "#12ABef", minutes: 60, count: 3)]
            )
        )
    }
    static func replacingDays(_ days: [WidgetDay]) -> WidgetSnapshot {
        let s = snapshot()
        return WidgetSnapshot(
            version: s.version, generatedAt: s.generatedAt, basisDay: s.basisDay, timeZoneID: s.timeZoneID,
            journey: s.journey,
            analytics: WidgetAnalytics(today: s.analytics.today, weekStart: s.analytics.weekStart, weekEnd: s.analytics.weekEnd, weekMinutes: 60, weekCount: 3, days: days, tags: s.analytics.tags)
        )
    }
}
