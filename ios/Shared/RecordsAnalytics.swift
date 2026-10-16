import Foundation

/// 앱·위젯 공용 순수 분석. 저장된 날짜와 표시 시간대를 분리한다.
enum RecordsAnalytics {
    private static var utc: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private static func check(_ calendar: Calendar) throws {
        guard calendar.identifier == .gregorian else { throw AnalyticsIssue.invalidCalendar }
    }

    private static func key(_ date: Date, in calendar: Calendar = utc) throws -> String {
        let c = calendar.dateComponents([.era, .year, .month, .day], from: date)
        guard c.era == 1, let y = c.year, (1...9999).contains(y), let m = c.month, let d = c.day else {
            throw AnalyticsIssue.invalidInput
        }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    private static func date(_ day: String) throws -> Date {
        guard day.utf8.count == 10, day.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else {
            throw AnalyticsIssue.invalidDay(day)
        }
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...9999).contains(parts[0]),
              let result = utc.date(from: DateComponents(era: 1, year: parts[0], month: parts[1], day: parts[2])),
              (try? key(result)) == day else { throw AnalyticsIssue.invalidDay(day) }
        return result
    }

    static func today(now: Date, calendar: Calendar, timeZone: TimeZone) throws -> String {
        try check(calendar)
        guard now.timeIntervalSinceReferenceDate.isFinite else { throw AnalyticsIssue.invalidInput }
        var local = utc
        local.timeZone = timeZone
        return try key(now, in: local)
    }

    static func period(kind: AnalyticsPeriodKind, containing day: String, calendar: Calendar) throws -> AnalyticsPeriod {
        try check(calendar)
        let value = try date(day)
        let start: Date
        let end: Date
        switch kind {
        case .week:
            let back = (utc.component(.weekday, from: value) + 5) % 7
            guard let first = utc.date(byAdding: .day, value: -back, to: value),
                  let last = utc.date(byAdding: .day, value: 6, to: first) else { throw AnalyticsIssue.invalidPeriod }
            start = first; end = last
        case .month:
            let c = utc.dateComponents([.year, .month], from: value)
            guard let first = utc.date(from: DateComponents(era: 1, year: c.year, month: c.month, day: 1)),
                  let range = utc.range(of: .day, in: .month, for: first),
                  let last = utc.date(byAdding: .day, value: range.count - 1, to: first) else { throw AnalyticsIssue.invalidPeriod }
            start = first; end = last
        }
        return try AnalyticsPeriod(kind: kind, startDay: key(start), endDay: key(end))
    }

    private static func validate(_ value: AnalyticsPeriod, calendar: Calendar) throws {
        guard try period(kind: value.kind, containing: value.startDay, calendar: calendar) == value else { throw AnalyticsIssue.invalidPeriod }
    }

    static func shift(period value: AnalyticsPeriod, by offset: Int, today: String, calendar: Calendar) throws -> AnalyticsPeriod? {
        try check(calendar)
        try validate(value, calendar: calendar)
        _ = try date(today)
        guard (-120_000...120_000).contains(offset) else { return nil }
        let component: Calendar.Component = value.kind == .week ? .day : .month
        let amount = value.kind == .week ? offset * 7 : offset
        guard let moved = utc.date(byAdding: component, value: amount, to: try date(value.startDay)),
              let day = try? key(moved),
              let candidate = try? period(kind: value.kind, containing: day, calendar: calendar),
              candidate.startDay <= today else { return nil }
        return candidate
    }

    private static func sum(_ values: [Int]) throws -> Int {
        try values.reduce(0) { total, value in
            let (next, overflow) = total.addingReportingOverflow(value)
            guard !overflow else { throw AnalyticsIssue.arithmeticOverflow }
            return next
        }
    }

    private static func tags(_ records: [AnalyticsRecordInput]) throws -> [AnalyticsTagTotal] {
        let total = try sum(records.map(\.minutes))
        return try Dictionary(grouping: records, by: \.tag).map { name, items in
            let minutes = try sum(items.map(\.minutes))
            let latest = items.dropFirst().reduce(items[0]) { $1.completedAt > $0.completedAt ? $1 : $0 }
            return AnalyticsTagTotal(id: .named(name), name: name, color: latest.tagColor, minutes: minutes,
                                     count: items.count, share: total == 0 ? 0 : Double(minutes) / Double(total))
        }.sorted {
            if $0.minutes != $1.minutes { return $0.minutes > $1.minutes }
            if $0.count != $1.count { return $0.count > $1.count }
            return $0.name < $1.name
        }
    }

    private static func days(_ records: [AnalyticsRecordInput], period: AnalyticsPeriod, today: String) throws -> [AnalyticsDayTotal] {
        let grouped = Dictionary(grouping: records, by: \.day)
        let last = try date(period.endDay)
        var current = try date(period.startDay)
        var result: [AnalyticsDayTotal] = []
        while current <= last {
            let day = try key(current)
            let items = grouped[day] ?? []
            result.append(try AnalyticsDayTotal(day: day, minutes: sum(items.map(\.minutes)), count: items.count,
                                               isFuture: day > today, tags: tags(items)))
            guard let next = utc.date(byAdding: .day, value: 1, to: current), next > current else { throw AnalyticsIssue.invalidPeriod }
            current = next
        }
        return result
    }

    private static func comparison(_ records: [AnalyticsRecordInput], period: AnalyticsPeriod, today: String, currentMinutes: Int, calendar: Calendar) throws -> AnalyticsComparison {
        guard let previous = try shift(period: period, by: -1, today: today, calendar: calendar) else {
            return AnalyticsComparison(previousStartDay: nil, previousEndDay: nil, currentMinutes: currentMinutes,
                                       previousMinutes: 0, deltaMinutes: currentMinutes, changePercent: nil)
        }
        var previousEnd = previous.endDay
        if period.startDay <= today, today <= period.endDay {
            let elapsed = utc.dateComponents([.day], from: try date(period.startDay), to: try date(today)).day ?? 0
            if let end = utc.date(byAdding: .day, value: elapsed, to: try date(previous.startDay)) {
                previousEnd = min(previousEnd, try key(end))
            }
        }
        let previousMinutes = try sum(records.filter { previous.startDay <= $0.day && $0.day <= previousEnd }.map(\.minutes))
        let delta = currentMinutes - previousMinutes
        return AnalyticsComparison(previousStartDay: previous.startDay, previousEndDay: previousEnd, currentMinutes: currentMinutes,
                                   previousMinutes: previousMinutes, deltaMinutes: delta,
                                   changePercent: previousMinutes == 0 ? nil : Double(delta) / Double(previousMinutes) * 100)
    }

    private static func streak(_ records: [AnalyticsRecordInput]) throws -> Int {
        let ordered = Set(records.map(\.day)).sorted()
        var last: Date?
        var length = 0
        var longest = 0
        for day in ordered {
            let current = try date(day)
            length = last.flatMap { utc.date(byAdding: .day, value: 1, to: $0) } == current ? length + 1 : 1
            longest = max(longest, length)
            last = current
        }
        return longest
    }

    private struct Route: Hashable { let bus, from, to: String }

    static func compute(records: [AnalyticsRecordInput], period: AnalyticsPeriod, selectedTag: String?, now: Date, calendar: Calendar, timeZone: TimeZone) throws -> RecordsAnalyticsComputation {
        try check(calendar)
        try validate(period, calendar: calendar)
        let today = try today(now: now, calendar: calendar, timeZone: timeZone)
        var ids = Set<[UInt16]>()
        for record in records {
            _ = try date(record.day)
            guard !record.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, record.id.utf16.count <= 100,
                  ids.insert(Array(record.id.utf16)).inserted, (1...360).contains(record.minutes),
                  record.completedAt.timeIntervalSinceReferenceDate.isFinite,
                  [record.tag, record.bus, record.from, record.to].allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.utf16.count <= 500 }),
                  record.tagColor.range(of: "^#[0-9a-fA-F]{6}$", options: .regularExpression) != nil else { throw AnalyticsIssue.invalidInput }
        }
        let eligible = records.filter { $0.day <= today && $0.completedAt <= now }
        let current = eligible.filter { period.startDay <= $0.day && $0.day <= period.endDay }
        let minutes = try sum(current.map(\.minutes))
        let totals = AnalyticsTotals(minutes: minutes, count: current.count, activeDays: Set(current.map(\.day)).count,
                                     averageMinutes: current.isEmpty ? 0 : Int((Double(minutes) / Double(current.count)).rounded()))
        let allTags = try tags(current)
        var topTags = Array(allTags.prefix(3))
        if allTags.count > 3 {
            let remainder = Array(allTags.dropFirst(3))
            let restMinutes = try sum(remainder.map(\.minutes))
            topTags.append(AnalyticsTagTotal(id: .remainder, name: "기타", color: "#BFC6C1", minutes: restMinutes,
                                            count: try sum(remainder.map(\.count)), share: minutes == 0 ? 0 : Double(restMinutes) / Double(minutes)))
        }
        let effectiveTag = selectedTag.flatMap { name in allTags.contains { $0.name == name } ? name : nil }
        let scoped = current.filter { effectiveTag == nil || $0.tag == effectiveTag }
        let orderedIDs = scoped.enumerated().sorted {
            $0.element.completedAt == $1.element.completedAt ? $0.offset < $1.offset : $0.element.completedAt > $1.element.completedAt
        }.map(\.element.id)
        var local = utc
        local.timeZone = timeZone
        func timeBand(_ item: AnalyticsRecordInput) -> AnalyticsTimeBand {
            switch local.component(.hour, from: item.completedAt) {
            case 0..<5: .dawn
            case 5..<12: .morning
            case 12..<18: .afternoon
            default: .evening
            }
        }
        let timeBands = try AnalyticsTimeBand.allCases.map { band in
            let items = scoped.filter { timeBand($0) == band }
            return try AnalyticsTimeBandTotal(band: band, minutes: sum(items.map(\.minutes)), count: items.count)
        }
        func lengthBand(_ item: AnalyticsRecordInput) -> AnalyticsLengthBand {
            switch item.minutes {
            case 1...30: .upTo30
            case 31...60: .from31To60
            case 61...120: .from61To120
            case 121...240: .from121To240
            default: .from241To360
            }
        }
        let lengths = try AnalyticsLengthBand.allCases.map { band in
            let items = scoped.filter { lengthBand($0) == band }
            return try AnalyticsLengthTotal(band: band, minutes: sum(items.map(\.minutes)), count: items.count)
        }
        let routes = try Dictionary(grouping: scoped, by: { Route(bus: $0.bus, from: $0.from, to: $0.to) }).map { route, items in
            try AnalyticsRouteTotal(bus: route.bus, from: route.from, to: route.to, minutes: sum(items.map(\.minutes)), count: items.count)
        }.sorted {
            if $0.count != $1.count { return $0.count > $1.count }
            if $0.minutes != $1.minutes { return $0.minutes > $1.minutes }
            return ($0.bus, $0.from, $0.to) < ($1.bus, $1.from, $1.to)
        }
        let report = try RecordsAnalyticsReport(period: period, today: today, totals: totals, days: days(current, period: period, today: today),
                                               tags: allTags, topTags: topTags,
                                               comparison: comparison(eligible, period: period, today: today, currentMinutes: minutes, calendar: calendar))
        return try RecordsAnalyticsComputation(report: report, effectiveTag: effectiveTag, filteredDays: days(scoped, period: period, today: today),
                                               scopedRecordIDs: orderedIDs,
                                               insights: AnalyticsInsights(timeBands: timeBands, needsMoreTimeBandRecords: scoped.count < 3,
                                                                           routes: Array(routes.prefix(3)), lengths: lengths, longestStreak: streak(current)))
    }
}
