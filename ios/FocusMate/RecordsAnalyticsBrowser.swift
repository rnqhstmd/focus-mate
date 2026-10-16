import Foundation

struct RecordsAnalyticsBrowser: Equatable {
    private(set) var period: AnalyticsPeriod
    private(set) var selectedTag: String?
    private(set) var anchorDay: String

    init(selectedDay: String, calendar: Calendar) throws {
        period = try RecordsAnalytics.period(kind: .month, containing: selectedDay, calendar: calendar)
        anchorDay = selectedDay
        selectedTag = nil
    }
    mutating func setKind(_ kind: AnalyticsPeriodKind, calendar: Calendar) throws {
        period = try RecordsAnalytics.period(kind: kind, containing: anchorDay, calendar: calendar)
        selectedTag = nil
    }
    @discardableResult mutating func move(by offset: Int, today: String, calendar: Calendar) throws -> Bool {
        guard let candidate = try RecordsAnalytics.shift(period: period, by: offset, today: today, calendar: calendar) else { return false }
        period = candidate
        anchorDay = candidate.startDay
        selectedTag = nil
        return true
    }
    mutating func returnToToday(today: String, calendar: Calendar) throws {
        period = try RecordsAnalytics.period(kind: period.kind, containing: today, calendar: calendar)
        anchorDay = today
        selectedTag = nil
    }
    mutating func selectTag(_ name: String?, available: [AnalyticsTagTotal]) {
        guard let name, available.contains(where: { $0.id == .named(name) }) else { selectedTag = nil; return }
        selectedTag = selectedTag == name ? nil : name
    }
    mutating func reconcileTags(available: [AnalyticsTagTotal]) {
        if let selectedTag, !available.contains(where: { $0.id == .named(selectedTag) }) { self.selectedTag = nil }
    }
}
