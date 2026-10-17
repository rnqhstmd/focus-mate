import Foundation

enum AnalyticsPeriodKind: String, Codable, Equatable, CaseIterable { case week, month }
enum AnalyticsTimeBand: String, Codable, Equatable, CaseIterable { case dawn, morning, afternoon, evening }
enum AnalyticsLengthBand: String, Codable, Equatable, CaseIterable { case upTo30, from31To60, from61To120, from121To240, from241To360 }
enum AnalyticsTagID: Codable, Equatable, Hashable { case named(String), remainder }

struct AnalyticsPeriod: Codable, Equatable {
    let kind: AnalyticsPeriodKind
    let startDay: String
    let endDay: String
}

struct AnalyticsRecordInput: Codable, Equatable {
    let id: String
    let day: String
    let completedAt: Date
    let minutes: Int
    let tag: String
    let tagColor: String
    let bus: String
    let from: String
    let to: String
}

struct AnalyticsTotals: Codable, Equatable {
    let minutes: Int
    let count: Int
    let activeDays: Int
    let averageMinutes: Int
}

struct AnalyticsTagTotal: Codable, Equatable {
    let id: AnalyticsTagID
    let name: String
    let color: String
    let minutes: Int
    let count: Int
    let share: Double
}

struct AnalyticsDayTotal: Codable, Equatable {
    let day: String
    let minutes: Int
    let count: Int
    let isFuture: Bool
    let tags: [AnalyticsTagTotal]
}

struct AnalyticsComparison: Codable, Equatable {
    let previousStartDay: String?
    let previousEndDay: String?
    let currentMinutes: Int
    let previousMinutes: Int
    let deltaMinutes: Int
    let changePercent: Double?
}

struct AnalyticsTimeBandTotal: Codable, Equatable {
    let band: AnalyticsTimeBand
    let minutes: Int
    let count: Int
}

struct AnalyticsLengthTotal: Codable, Equatable {
    let band: AnalyticsLengthBand
    let minutes: Int
    let count: Int
}

struct AnalyticsRouteTotal: Codable, Equatable {
    let bus: String
    let from: String
    let to: String
    let minutes: Int
    let count: Int
}

struct AnalyticsInsights: Codable, Equatable {
    let timeBands: [AnalyticsTimeBandTotal]
    let needsMoreTimeBandRecords: Bool
    let routes: [AnalyticsRouteTotal]
    let lengths: [AnalyticsLengthTotal]
    let longestStreak: Int
}

struct RecordsAnalyticsReport: Codable, Equatable {
    let period: AnalyticsPeriod
    let today: String
    let totals: AnalyticsTotals
    let days: [AnalyticsDayTotal]
    let tags: [AnalyticsTagTotal]
    let topTags: [AnalyticsTagTotal]
    let comparison: AnalyticsComparison
}

struct RecordsAnalyticsComputation: Equatable {
    let report: RecordsAnalyticsReport
    let effectiveTag: String?
    let filteredDays: [AnalyticsDayTotal]
    let scopedRecordIDs: [String]
    let insights: AnalyticsInsights
}

enum AnalyticsIssue: Error, Equatable { case invalidCalendar, invalidDay(String), invalidPeriod, invalidInput, arithmeticOverflow, notImplemented }
