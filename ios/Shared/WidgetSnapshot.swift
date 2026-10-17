import Foundation

enum WidgetJourneyPhase: String, Codable, Equatable, CaseIterable {
    case setup, ready, awaitingDeparture, running, paused, arrived
}
struct WidgetJourney: Codable, Equatable {
    let phase: WidgetJourneyPhase
    let journeyID: String?
    let busNumber: String?
    let destination: String?
    let totalSeconds: Int?
    let elapsedSeconds: Int?
}
struct WidgetDay: Codable, Equatable { let day: String; let minutes: Int; let count: Int }
struct WidgetTag: Codable, Equatable {
    let id: AnalyticsTagID
    let name: String
    let color: String
    let minutes: Int
    let count: Int
}
struct WidgetAnalytics: Codable, Equatable {
    let today: WidgetDay
    let weekStart: String
    let weekEnd: String
    let weekMinutes: Int
    let weekCount: Int
    let days: [WidgetDay]
    let tags: [WidgetTag]
}
struct WidgetSnapshot: Codable, Equatable {
    let version: Int
    let generatedAt: Date
    let basisDay: String
    let timeZoneID: String
    let journey: WidgetJourney
    let analytics: WidgetAnalytics
}
enum WidgetDecodedState: Equatable { case valid(WidgetSnapshot), malformed, unsupportedVersion(Int) }
enum WidgetReadState: Equatable {
    case unavailable, malformed, unsupportedVersion(Int), stale(WidgetSnapshot), validEmpty(WidgetSnapshot), valid(WidgetSnapshot)
}
enum WidgetDataIssue: Error, Equatable { case invalidSnapshot, containerUnavailable, readFailed, writeFailed, notImplemented }
enum WidgetSnapshotCodec {
    static func encode(_ snapshot: WidgetSnapshot) throws -> Data {
        guard isValid(snapshot) else { throw WidgetDataIssue.invalidSnapshot }
        return try JSONEncoder().encode(snapshot)
    }
    static func decode(_ data: Data) -> WidgetDecodedState {
        struct Version: Decodable { let version: Int }
        guard let version = try? JSONDecoder().decode(Version.self, from: data) else { return .malformed }
        guard version.version == 1 else { return .unsupportedVersion(version.version) }
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data), isValid(snapshot) else { return .malformed }
        return .valid(snapshot)
    }
    private static func isValid(_ value: WidgetSnapshot) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard value.version == 1, value.generatedAt.timeIntervalSinceReferenceDate.isFinite,
              let zone = TimeZone(identifier: value.timeZoneID),
              (try? RecordsAnalytics.today(now: value.generatedAt, calendar: calendar, timeZone: zone)) == value.basisDay,
              let week = try? RecordsAnalytics.period(kind: .week, containing: value.basisDay, calendar: calendar),
              week.startDay == value.analytics.weekStart, week.endDay == value.analytics.weekEnd else { return false }
        let analytics = value.analytics
        var utc = calendar; utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let formatter = DateFormatter(); formatter.calendar = utc; formatter.timeZone = utc.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        guard analytics.days.count == 7, let first = formatter.date(from: week.startDay) else { return false }
        var minutes = 0, count = 0
        for (index, day) in analytics.days.enumerated() {
            guard let date = utc.date(byAdding: .day, value: index, to: first),
                  day.day == formatter.string(from: date), validAmount(day.minutes, day.count),
                  day.day <= value.basisDay || (day.minutes == 0 && day.count == 0),
                  add(day.minutes, to: &minutes), add(day.count, to: &count) else { return false }
        }
        guard minutes == analytics.weekMinutes, count == analytics.weekCount,
              analytics.days.first(where: { $0.day == value.basisDay }) == analytics.today,
              analytics.tags.count <= 4 else { return false }
        if analytics.tags.count == 4 {
            guard analytics.tags.last?.id == .remainder,
                  analytics.tags.prefix(3).allSatisfy({ if case .named = $0.id { return true }; return false }) else { return false }
        } else {
            guard analytics.tags.allSatisfy({ if case .named = $0.id { return true }; return false }) else { return false }
        }
        var tagMinutes = 0, tagCount = 0
        var ids = Set<AnalyticsTagID>()
        for tag in analytics.tags {
            guard ids.insert(tag.id).inserted, validText(tag.name),
                  tag.color.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil,
                  tag.minutes > 0, validAmount(tag.minutes, tag.count),
                  add(tag.minutes, to: &tagMinutes), add(tag.count, to: &tagCount) else { return false }
            switch tag.id {
            case .named(let name): guard name == tag.name else { return false }
            case .remainder: guard tag.name == "기타" else { return false }
            }
        }
        guard tagMinutes == minutes, tagCount == count else { return false }
        let journey = value.journey
        switch journey.phase {
        case .setup, .ready:
            return journey.journeyID == nil && journey.busNumber == nil && journey.destination == nil && journey.totalSeconds == nil && journey.elapsedSeconds == nil
        case .awaitingDeparture, .running, .paused, .arrived:
            guard let id = journey.journeyID, validText(id), let bus = journey.busNumber, validText(bus),
                  let destination = journey.destination, validText(destination),
                  let total = journey.totalSeconds, (1...21600).contains(total),
                  let elapsed = journey.elapsedSeconds, (0...total).contains(elapsed) else { return false }
            if journey.phase == .awaitingDeparture { return elapsed == 0 }
            if journey.phase == .arrived { return elapsed == total }
            return true
        }
    }
    private static func validText(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.utf8.count <= 4096 }
    private static func validAmount(_ minutes: Int, _ count: Int) -> Bool {
        guard minutes >= 0, count >= 0 else { return false }
        if count == 0 { return minutes == 0 }
        let (maximum, overflow) = count.multipliedReportingOverflow(by: 360)
        return minutes >= count && (overflow || minutes <= maximum)
    }
    private static func add(_ amount: Int, to total: inout Int) -> Bool {
        let (next, overflow) = total.addingReportingOverflow(amount)
        guard !overflow else { return false }; total = next; return true
    }
}
enum WidgetFreshness {
    static func classify(_ decoded: WidgetDecodedState, now: Date, timeZone: TimeZone) -> WidgetReadState {
        switch decoded {
        case .malformed: return .malformed
        case .unsupportedVersion(let version): return .unsupportedVersion(version)
        case .valid(let snapshot):
            let age = now.timeIntervalSince(snapshot.generatedAt)
            guard age.isFinite, age >= 0 else { return .malformed }
            let today = try? RecordsAnalytics.today(now: now, calendar: Calendar(identifier: .gregorian), timeZone: timeZone)
            guard age < 1800, today == snapshot.basisDay, timeZone.identifier == snapshot.timeZoneID else { return .stale(snapshot) }
            return snapshot.analytics.weekCount == 0 && snapshot.analytics.weekMinutes == 0 ? .validEmpty(snapshot) : .valid(snapshot)
        }
    }
}
