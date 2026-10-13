import Foundation

/// 고른 시간에 정확히 맞는 버스 한 대와 그 도착지.
struct JourneyCandidate: Identifiable, Equatable {
    let bus: BusLine
    let minutes: Int
    let stops: Int
    let destination: String

    var id: String { bus.id }
    var distanceText: String { JourneyPlanner.distanceText(stops: stops) }
    var accessibilityLabel: String { "\(bus.kind) \(bus.number)번, \(destination), \(minutes)분, \(stops)정류장" }
}

enum JourneyPlanner {
    static let minuteRange: ClosedRange<Int> = 15...360
    static let initialMinutes = 25
    /// 정류장 하나의 거리(0.55km)를 0.01km 단위 정수로 둔다. 부동소수점 표기 오차를 피하기 위해서다.
    private static let hundredthsKmPerStop = 55

    static func clamp(_ minutes: Int) -> Int {
        min(max(minutes, minuteRange.lowerBound), minuteRange.upperBound)
    }

    static func candidates(minutes: Int, from origin: StopPosition) -> [JourneyCandidate] {
        guard minuteRange.contains(minutes) else { return [] }
        return BusLine.all.filter { minutes % $0.minutesPerStop == 0 }.map { bus in
            let stops = minutes / bus.minutesPerStop
            return JourneyCandidate(bus: bus, minutes: minutes, stops: stops,
                                    destination: RouteStops.name(at: origin.index + origin.direction * stops))
        }
    }

    static func distanceText(stops: Int) -> String {
        let hundredths = stops * hundredthsKmPerStop
        let whole = hundredths / 100, fraction = hundredths % 100
        if fraction == 0 { return "\(whole)km" }
        if fraction % 10 == 0 { return "\(whole).\(fraction / 10)km" }
        return "\(whole).\(String(format: "%02d", fraction))km"
    }
}
