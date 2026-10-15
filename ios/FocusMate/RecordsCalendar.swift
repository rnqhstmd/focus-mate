import Foundation

/// 기록 화면의 날짜. 저장 기록의 `date` 키("YYYY-MM-DD")와 같은 달력 날짜다.
struct RecordDay: Hashable, Comparable {
    let year, month, day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init?(key: String) {
        let parts = key.split(separator: "-")
        guard key.utf8.count == 10, parts.count == 3,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        let candidate = RecordDay(year: year, month: month, day: day)
        guard candidate.date != nil else { return nil }
        self = candidate
    }

    var key: String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func from(_ date: Date, timeZone: TimeZone) -> RecordDay {
        var calendar = Self.calendar
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return RecordDay(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    static func january1(_ year: Int) -> RecordDay { RecordDay(year: year, month: 1, day: 1) }

    static func < (lhs: RecordDay, rhs: RecordDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// `delta`일 뒤 날짜. 달력 계산은 UTC 그레고리력으로 한다.
    func adding(days delta: Int) -> RecordDay? {
        guard let date, let moved = Self.calendar.date(byAdding: .day, value: delta, to: date) else { return nil }
        return RecordDay.from(moved, timeZone: Self.calendar.timeZone)
    }

    fileprivate var date: Date? {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = Self.calendar.date(from: components) else { return nil }
        let actual = Self.calendar.dateComponents([.year, .month, .day], from: date)
        return actual.year == year && actual.month == month && actual.day == day ? date : nil
    }

    fileprivate static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
}

/// 잔디 5단계(하루 합계 0 / 1~30 / 31~60 / 61~120 / 121분 이상).
enum RecordHeatLevel {
    static func level(minutes: Int) -> Int {
        switch minutes {
        case ...0: 0
        case 1...30: 1
        case 31...60: 2
        case 61...120: 3
        default: 4
        }
    }
}

struct RecordDayCell: Equatable, Identifiable {
    let day: RecordDay
    let count, minutes, level: Int
    let isFuture, isToday: Bool
    var id: String { day.key }
    var accessibilityLabel: String {
        "\(day.month)월 \(day.day)일 · \(count)회 · \(ProfileTimeText.spoken(minutes: minutes))"
    }
}

struct RecordYearSummary: Equatable {
    let count, days, minutes: Int
    /// 0분이면 시간을 뺀다("0회 여행 · 0일").
    var text: String {
        let base = "\(count)회 여행 · \(days)일"
        return minutes == 0 ? base : "\(base) · \(ProfileTimeText.display(minutes: minutes))"
    }
}

/// 기록 화면의 순수 집계. 오늘보다 뒤 날짜의 기록은 집계하지 않는다.
enum RecordsCalendar {
    /// 일요일 시작 주에서 1월 1일 앞의 빈 칸 수.
    static func leadingBlanks(year: Int) -> Int {
        guard let date = RecordDay.january1(year).date else { return 0 }
        return RecordDay.calendar.component(.weekday, from: date) - 1
    }

    static func cells(year: Int, records: [RecordSnapshot], today: RecordDay) -> [RecordDayCell] {
        let byDay = Dictionary(grouping: counted(records, today: today), by: \.date)
        var cells: [RecordDayCell] = []
        var day = RecordDay.january1(year)
        while day.year == year {
            let items = byDay[day.key] ?? []
            let minutes = items.reduce(0) { $0 + $1.minutes }
            cells.append(RecordDayCell(day: day, count: items.count, minutes: minutes,
                                       level: RecordHeatLevel.level(minutes: minutes),
                                       isFuture: day > today, isToday: day == today))
            guard let next = day.adding(days: 1) else { break }
            day = next
        }
        return cells
    }

    static func summary(year: Int, records: [RecordSnapshot], today: RecordDay) -> RecordYearSummary {
        let items = counted(records, today: today).filter { RecordDay(key: $0.date)?.year == year }
        return RecordYearSummary(count: items.count, days: Set(items.map(\.date)).count,
                                 minutes: items.reduce(0) { $0 + $1.minutes })
    }

    /// 그 날의 기록. 하차 시각 최신순이다.
    static func records(on day: RecordDay, in records: [RecordSnapshot]) -> [RecordSnapshot] {
        let key = day.key
        let dated: [(offset: Int, record: RecordSnapshot, at: Date)] = records.enumerated().compactMap { item in
            guard item.element.date == key else { return nil }
            return (item.offset, item.element, instant(item.element.completedAt) ?? .distantPast)
        }
        return dated.sorted { $0.at == $1.at ? $0.offset < $1.offset : $0.at > $1.at }.map(\.record)
    }

    static func latestRecordDay(year: Int, records: [RecordSnapshot], today: RecordDay) -> RecordDay? {
        counted(records, today: today).compactMap { RecordDay(key: $0.date) }.filter { $0.year == year }.max()
    }

    /// 올해·작년·선택 연도·기록이 있는 연도(최신순).
    static func yearOptions(records: [RecordSnapshot], today: RecordDay, selectedYear: Int) -> [Int] {
        var years: Set<Int> = [today.year, today.year - 1, selectedYear]
        for record in counted(records, today: today) {
            if let day = RecordDay(key: record.date) { years.insert(day.year) }
        }
        return years.filter { $0 <= today.year }.sorted(by: >)
    }

    private static func counted(_ records: [RecordSnapshot], today: RecordDay) -> [RecordSnapshot] {
        records.filter { RecordDay(key: $0.date).map { $0 <= today } ?? false }
    }

    /// 저장 시각(밀리초 유무 모두). 해석하지 못하면 가장 오래된 것으로 본다.
    static func instant(_ value: String) -> Date? {
        fractionalFormatter.date(from: value) ?? plainFormatter.date(from: value)
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let plainFormatter = ISO8601DateFormatter()
}

enum RecordsEmptyState: Equatable { case noRecords, noRecordsOnDay }

/// 기록 화면의 선택 상태(연도·날짜·목록 개수). 기록 배열은 저장하지 않고 인자로 받는다.
struct RecordsBrowser: Equatable {
    static let pageSize = 10
    let today: RecordDay
    private(set) var year: Int
    private(set) var selectedDay: RecordDay
    private(set) var listLimit = RecordsBrowser.pageSize

    init(today: RecordDay) {
        self.today = today
        year = today.year
        selectedDay = today
    }

    /// 오늘 이후 날짜는 고르지 않는다. 고르면 목록은 처음 10개로 돌아간다.
    @discardableResult mutating func select(_ day: RecordDay) -> Bool {
        guard day <= today else { return false }
        year = day.year
        selectedDay = day
        listLimit = Self.pageSize
        return true
    }

    /// 선택 연도 안에서 하루씩 움직인다(VoiceOver 조정).
    @discardableResult mutating func stepDay(by delta: Int) -> Bool {
        guard let next = selectedDay.adding(days: delta), next.year == year else { return false }
        return select(next)
    }

    mutating func moveYear(by delta: Int, records: [RecordSnapshot]) {
        selectYear(year + delta, records: records)
    }

    /// 올해면 오늘, 아니면 그 해의 가장 최근 기록일, 기록이 없으면 1월 1일을 고른다.
    mutating func selectYear(_ target: Int, records: [RecordSnapshot]) {
        guard target <= today.year, target >= 1 else { return }
        year = target
        selectedDay = target == today.year ? today
            : RecordsCalendar.latestRecordDay(year: target, records: records, today: today) ?? .january1(target)
        listLimit = Self.pageSize
    }

    var canGoNextYear: Bool { year < today.year }
    var canGoPreviousYear: Bool { year > 1 }

    mutating func showMore() { listLimit += Self.pageSize }

    func visibleRecords(in records: [RecordSnapshot]) -> [RecordSnapshot] {
        Array(RecordsCalendar.records(on: selectedDay, in: records).prefix(listLimit))
    }

    func hasMore(in records: [RecordSnapshot]) -> Bool {
        RecordsCalendar.records(on: selectedDay, in: records).count > listLimit
    }

    func emptyState(records: [RecordSnapshot]) -> RecordsEmptyState? {
        if records.isEmpty { return .noRecords }
        return RecordsCalendar.records(on: selectedDay, in: records).isEmpty ? .noRecordsOnDay : nil
    }
}

/// 기록 목록 한 줄의 표시 값.
struct RecordListItemContent: Equatable {
    let task, minutesText, timeText, routeText, tag, memo: String

    init(record: RecordSnapshot, timeZone: TimeZone) {
        task = record.task
        minutesText = ProfileTimeText.display(minutes: record.minutes)
        if let instant = RecordsCalendar.instant(record.completedAt) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let parts = calendar.dateComponents([.hour, .minute], from: instant)
            timeText = String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
        } else {
            timeText = ""
        }
        routeText = "\(record.bus) · \(record.from) → \(record.to)"
        tag = record.tag
        memo = record.memo
    }

    var memoButtonTitle: String { memo.isEmpty ? "메모 남기기" : "메모 수정" }
}
