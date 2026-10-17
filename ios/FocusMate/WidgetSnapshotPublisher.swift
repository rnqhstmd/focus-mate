import Foundation

enum WidgetSnapshotProjection {
    static func make(snapshot: AppSnapshot, now: Date, calendar: Calendar, timeZone: TimeZone) throws -> WidgetSnapshot {
        let route = try snapshot.launchRoute()
        let day = try RecordsAnalytics.today(now: now, calendar: calendar, timeZone: timeZone)
        let week = try RecordsAnalytics.period(kind: .week, containing: day, calendar: calendar)
        let inputs = try snapshot.records.items.map { record in
            guard let instant = RecordsCalendar.instant(record.completedAt) else { throw AnalyticsIssue.invalidInput }
            return AnalyticsRecordInput(id: record.id, day: record.date, completedAt: instant, minutes: record.minutes,
                                        tag: record.tag, tagColor: record.tagColor, bus: record.bus, from: record.from, to: record.to)
        }
        let report = try RecordsAnalytics.compute(records: inputs, period: week, selectedTag: nil, now: now, calendar: calendar, timeZone: timeZone).report
        let days = report.days.map { WidgetDay(day: $0.day, minutes: $0.minutes, count: $0.count) }
        guard let today = days.first(where: { $0.day == day }) else { throw WidgetDataIssue.invalidSnapshot }
        let journey: WidgetJourney
        if route != .main {
            journey = WidgetJourney(phase: .setup, journeyID: nil, busNumber: nil, destination: nil, totalSeconds: nil, elapsedSeconds: nil)
        } else if let active = snapshot.journey.active {
            let phase: WidgetJourneyPhase = active.phase == .awaitingDeparture ? .awaitingDeparture : active.isArrived ? .arrived : active.paused ? .paused : .running
            journey = WidgetJourney(phase: phase, journeyID: active.id, busNumber: active.busNumber, destination: active.destinationName,
                                    totalSeconds: active.totalSeconds, elapsedSeconds: active.progress.elapsedSeconds)
        } else {
            journey = WidgetJourney(phase: .ready, journeyID: nil, busNumber: nil, destination: nil, totalSeconds: nil, elapsedSeconds: nil)
        }
        return WidgetSnapshot(version: 1, generatedAt: now, basisDay: day, timeZoneID: timeZone.identifier, journey: journey,
                              analytics: WidgetAnalytics(today: today, weekStart: week.startDay, weekEnd: week.endDay,
                                  weekMinutes: report.totals.minutes, weekCount: report.totals.count, days: days,
                                  tags: report.topTags.map { WidgetTag(id: $0.id, name: $0.name, color: $0.color, minutes: $0.minutes, count: $0.count) }))
    }
}

@MainActor
final class WidgetSnapshotPublisher {
    private let store: WidgetSnapshotStore
    private let now: () -> Date
    private let calendar: Calendar
    private let timeZone: () -> TimeZone
    private let reload: () -> Void

    init(store: WidgetSnapshotStore, now: @escaping () -> Date, calendar: Calendar,
         timeZone: @escaping () -> TimeZone, reload: @escaping () -> Void) {
        self.store = store; self.now = now; self.calendar = calendar; self.timeZone = timeZone; self.reload = reload
    }
    @discardableResult func publish(snapshot: AppSnapshot) -> Bool {
        do {
            let instant = now(), zone = timeZone()
            let value = try WidgetSnapshotProjection.make(snapshot: snapshot, now: instant, calendar: calendar, timeZone: zone)
            let previous: WidgetSnapshot?
            switch store.read(now: instant, timeZone: zone) {
            case .valid(let old), .validEmpty(let old): previous = old
            default: previous = nil
            }
            if let previous, previous.version == value.version, previous.basisDay == value.basisDay,
               previous.timeZoneID == value.timeZoneID, previous.journey == value.journey, previous.analytics == value.analytics { return false }
            try store.write(value)
            reload()
            return true
        } catch { return false }
    }
}
