import Foundation

/// 시간 선택 휠의 범위. 후보 계산은 `RouteCandidates`가 한다.
enum JourneyPlanner {
    static let minuteRange: ClosedRange<Int> = 15...360
    static let initialMinutes = 25

    static func clamp(_ minutes: Int) -> Int {
        min(max(minutes, minuteRange.lowerBound), minuteRange.upperBound)
    }
}
