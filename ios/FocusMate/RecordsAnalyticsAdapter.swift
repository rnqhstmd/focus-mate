import Foundation

enum RecordsAnalyticsLoad: Equatable {
    case available(RecordsAnalyticsContent)
    case unavailable
}

struct RecordsAnalyticsContent: Equatable {
    let computation: RecordsAnalyticsComputation
    let recent: [RecordSnapshot]
    let memoCount: Int
    let recentMemos: [RecordSnapshot]
    let hasAnyEligibleRecords: Bool
}

enum RecordsAnalyticsAdapter {
    static func load(section: RecordSection?, period: AnalyticsPeriod, selectedTag: String?, now: Date, calendar: Calendar, timeZone: TimeZone) -> RecordsAnalyticsLoad {
        guard let section else { return .unavailable }
        do {
            return .available(try validatedContent(section: section, period: period, selectedTag: selectedTag,
                                                 now: now, calendar: calendar, timeZone: timeZone))
        } catch { return .unavailable }
    }
    static func validatedContent(section: RecordSection, period: AnalyticsPeriod, selectedTag: String?, now: Date, calendar: Calendar, timeZone: TimeZone) throws -> RecordsAnalyticsContent {
        try section.validate()
        let inputs = try section.items.map { record in
            guard let completedAt = RecordsCalendar.instant(record.completedAt) else { throw AnalyticsIssue.invalidInput }
            return AnalyticsRecordInput(id: record.id, day: record.date, completedAt: completedAt, minutes: record.minutes,
                                        tag: record.tag, tagColor: record.tagColor, bus: record.bus, from: record.from, to: record.to)
        }
        let result = try RecordsAnalytics.compute(records: inputs, period: period, selectedTag: selectedTag,
                                                  now: now, calendar: calendar, timeZone: timeZone)
        let originals = Dictionary(uniqueKeysWithValues: section.items.map { (Array($0.id.utf16), $0) })
        let scoped = try result.scopedRecordIDs.map { id in
            guard let original = originals[Array(id.utf16)] else { throw AnalyticsIssue.invalidInput }
            return original
        }
        let memos = scoped.filter { !$0.memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let today = try RecordsAnalytics.today(now: now, calendar: calendar, timeZone: timeZone)
        return RecordsAnalyticsContent(computation: result, recent: Array(scoped.prefix(5)), memoCount: memos.count,
                                       recentMemos: Array(memos.prefix(3)),
                                       hasAnyEligibleRecords: inputs.contains { $0.day <= today && $0.completedAt <= now })
    }
}
