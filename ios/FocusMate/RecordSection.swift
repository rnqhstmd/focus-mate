import Foundation

struct RecordSnapshot: Codable, Equatable {
    let id: String
    let completedAt: String
    let date: String
    let bus: String
    let tag: String
    let tagColor: String
    let task: String
    let minutes: Int
    let sound: String
    let from: String
    let to: String
    let memo: String
}

struct RecordCompletionInput: Equatable {
    let id: String
    let completedAt: String
    let bus: String
    let tag: String
    let tagColor: String
    let task: String
    let minutes: Int
    let sound: String
    let from: String
    let to: String
}

enum RecordCompletionOutcome: Equatable { case alighted, active, abandoned }
struct RecordDaySummary: Equatable { let count: Int; let minutes: Int }
struct RecordLifetimeSummary: Equatable { let count: Int; let minutes: Int }
enum RecordValidationIssue: Error, Equatable {
    case invalidID, invalidText(String), invalidTagColor, invalidCompletedAt, invalidDate
    case invalidMinutes(Int), memoTooLong, duplicateJourneyID(String), recordNotFound(String)
}

struct RecordSection: Codable, Equatable {
    let items: [RecordSnapshot]
    static let empty = RecordSection(items: [])
    func validate() throws {
        var identifiers = Set<[UInt16]>()
        for record in items {
            try record.validate()
            guard identifiers.insert(Array(record.id.utf16)).inserted else {
                throw RecordValidationIssue.duplicateJourneyID(record.id)
            }
        }
    }
    func recordingCompletion(_ input: RecordCompletionInput, outcome: RecordCompletionOutcome,
                             isExample: Bool = false, timeZone: TimeZone) throws -> RecordSection {
        try validate()
        guard outcome == .alighted, !isExample else { return self }
        try RecordSnapshot.validateID(input.id)
        if items.contains(where: { $0.id.utf16.elementsEqual(input.id.utf16) }) { return self }
        guard let instant = RecordDates.instant(input.completedAt) else { throw RecordValidationIssue.invalidCompletedAt }
        let date = try RecordDates.localKey(instant, timeZone: timeZone)
        let record = RecordSnapshot(id: input.id, completedAt: input.completedAt, date: date,
            bus: input.bus, tag: input.tag, tagColor: input.tagColor, task: input.task,
            minutes: input.minutes, sound: input.sound, from: input.from, to: input.to, memo: "")
        try record.validate()
        return RecordSection(items: items + [record]).sortedNewestFirst()
    }
    func updatingMemo(_ memo: String, forJourneyID id: String) throws -> RecordSection {
        try validate()
        try RecordSnapshot.validateID(id)
        guard let index = items.firstIndex(where: { $0.id.utf16.elementsEqual(id.utf16) }) else {
            throw RecordValidationIssue.recordNotFound(id)
        }
        let limited = RecordMemoLimit.prefix(memo.trimmingCharacters(in: .whitespacesAndNewlines))
        let original = items[index]
        var changed = items
        changed[index] = RecordSnapshot(id: original.id, completedAt: original.completedAt, date: original.date,
            bus: original.bus, tag: original.tag, tagColor: original.tagColor, task: original.task,
            minutes: original.minutes, sound: original.sound, from: original.from, to: original.to, memo: limited)
        return RecordSection(items: changed)
    }
    func dailySummary(on date: String) throws -> RecordDaySummary {
        try validate()
        guard RecordDates.day(date) != nil else { throw RecordValidationIssue.invalidDate }
        let matches = items.filter { $0.date == date }
        return RecordDaySummary(count: matches.count, minutes: matches.reduce(0) { $0 + $1.minutes })
    }
    func lifetimeSummary() throws -> RecordLifetimeSummary {
        try validate()
        return RecordLifetimeSummary(count: items.count, minutes: items.reduce(0) { $0 + $1.minutes })
    }
    func sortedNewestFirst() -> RecordSection {
        let sorted = items.enumerated().sorted { left, right in
            let a = RecordDates.instant(left.element.completedAt)!
            let b = RecordDates.instant(right.element.completedAt)!
            return a == b ? left.offset < right.offset : a > b
        }
        return RecordSection(items: sorted.map(\.element))
    }
}

/// 저장 시각은 Gregorian/UTC로 읽고, 완료 시간대는 새 날짜 생성에만 사용한다.
private enum RecordDates {
    private static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    static func day(_ key: String) -> Date? {
        guard key.utf8.count == 10,
              key.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else { return nil }
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...9999).contains(parts[0]) else { return nil }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = utc.date(from: components) else { return nil }
        let actual = utc.dateComponents([.era, .year, .month, .day], from: date)
        guard actual.era == 1, actual.year == parts[0], actual.month == parts[1], actual.day == parts[2] else { return nil }
        return date
    }
    static func instant(_ value: String) -> Date? {
        guard [20, 24].contains(value.utf8.count),
              value.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]{3})?Z$", options: .regularExpression) != nil,
              let day = day(String(value.prefix(10))) else { return nil }
        let characters = Array(value.utf8)
        func number(_ range: Range<Int>) -> Int { Int(String(decoding: characters[range], as: UTF8.self))! }
        let hour = number(11..<13), minute = number(14..<16), second = number(17..<19)
        guard hour < 24, minute < 60, second < 60 else { return nil }
        let milliseconds = characters.count == 24 ? number(20..<23) : 0
        return day.addingTimeInterval(Double(hour * 3600 + minute * 60 + second) + Double(milliseconds) / 1000)
    }
    static func localKey(_ instant: Date, timeZone: TimeZone) throws -> String {
        var calendar = utc
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.era, .year, .month, .day], from: instant)
        guard parts.era == 1, let year = parts.year, (1...9999).contains(year),
              let month = parts.month, let day = parts.day else { throw RecordValidationIssue.invalidDate }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

private extension RecordSnapshot {
    static func validateID(_ value: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, value.utf16.count <= 100 else {
            throw RecordValidationIssue.invalidID
        }
    }
    func validate() throws {
        try Self.validateID(id)
        for (name, text) in [("bus", bus), ("tag", tag), ("task", task), ("sound", sound), ("from", from), ("to", to)] {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, text.utf16.count <= 500 else {
                throw RecordValidationIssue.invalidText(name)
            }
        }
        guard tagColor.utf8.count == 7,
              tagColor.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil else {
            throw RecordValidationIssue.invalidTagColor
        }
        guard RecordDates.instant(completedAt) != nil else { throw RecordValidationIssue.invalidCompletedAt }
        guard RecordDates.day(date) != nil else { throw RecordValidationIssue.invalidDate }
        guard (1...360).contains(minutes) else { throw RecordValidationIssue.invalidMinutes(minutes) }
        guard memo.utf16.count <= 200 else { throw RecordValidationIssue.memoTooLong }
    }
}
