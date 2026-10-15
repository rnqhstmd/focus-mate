import Foundation

/// 지도 계산에 필요한 여정 입력. 진도 계산은 정수 초로 해서 경계 값이 정확히 맞게 한다.
struct CourseJourney: Equatable {
    let originIndex: Int
    let direction: Int
    let minutesPerStop: Int
    let totalMinutes: Int

    var totalStops: Int { totalMinutes / minutesPerStop }
    var totalSeconds: Int { totalMinutes * 60 }
    var destinationIndex: Int { RouteStops.wrap(originIndex + direction * totalStops) }

    init(originIndex: Int, direction: Int, minutesPerStop: Int, totalMinutes: Int) {
        self.originIndex = originIndex
        self.direction = direction
        self.minutesPerStop = minutesPerStop
        self.totalMinutes = totalMinutes
    }

    /// 저장된 여정에서 지도 입력을 만든다. 카탈로그 밖 값이거나 저장된 도착지가 계산값과 다르면 nil이다.
    /// nil이면 여행 화면은 지도 없이 W05 배치로 보인다(W09 도착 안내도 같은 일관성 규칙을 따른다).
    init?(journey: JourneySnapshot) {
        guard let origin = RouteStops.all.firstIndex(where: { $0.id == journey.originStopID }),
              let bus = journey.bus, bus.minutesPerStop > 0, journey.minutes % bus.minutesPerStop == 0
        else { return nil }
        self.init(originIndex: origin, direction: journey.direction, minutesPerStop: bus.minutesPerStop,
                  totalMinutes: journey.minutes)
        guard RouteStops.all[destinationIndex].id == journey.destinationStopID else { return nil }
    }
}

struct CourseBusPosition: Equatable {
    let point: CoursePoint
    let headingDegrees: Double
    let segmentFrom: Int
    let segmentTo: Int
    /// 구간 안 위치(0이면 segmentFrom 정류장 위).
    let fraction: Double
    let isArrived: Bool
}

/// 진도 → 버스 위치·남은 값(BR-2, BR-7). 진도 자체는 타이머가 소유하고 여기서는 읽기만 한다.
enum JourneyCourseProgress {
    private static let hundredthsKmPerStop = 55

    static func position(of journey: CourseJourney, elapsedSeconds: Int) -> CourseBusPosition {
        let (k, remainder) = travelled(journey, elapsedSeconds)
        if k >= journey.totalStops {
            let to = journey.destinationIndex
            let from = RouteStops.wrap(to - journey.direction)
            return CourseBusPosition(point: JourneyCourse.point(at: to), headingDegrees: heading(from: from, to: to),
                                     segmentFrom: to, segmentTo: to, fraction: 0, isArrived: true)
        }
        let from = RouteStops.wrap(journey.originIndex + journey.direction * k)
        let to = RouteStops.wrap(from + journey.direction)
        let fraction = Double(remainder) / Double(secondsPerStop(journey))
        let a = JourneyCourse.point(at: from), b = JourneyCourse.point(at: to)
        let point = CoursePoint(latitude: a.latitude + (b.latitude - a.latitude) * fraction,
                                longitude: a.longitude + (b.longitude - a.longitude) * fraction)
        return CourseBusPosition(point: point, headingDegrees: heading(from: from, to: to),
                                 segmentFrom: from, segmentTo: to, fraction: fraction, isArrived: false)
    }

    static func nextStopIndex(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        let k = travelled(journey, elapsedSeconds).stops
        return RouteStops.wrap(journey.originIndex + journey.direction * min(journey.totalStops, k + 1))
    }

    static func remainingStops(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        journey.totalStops - min(journey.totalStops, travelled(journey, elapsedSeconds).stops)
    }

    /// 0.1km 단위 정수. 소수 첫째 자리 반올림(half-up)을 정수 산술로 한다.
    static func remainingDistanceTenthsKm(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        let total = journey.totalSeconds
        guard total > 0 else { return 0 }
        let elapsed = clamped(journey, elapsedSeconds)
        let scaled = journey.totalStops * hundredthsKmPerStop * (total - elapsed)
        return (2 * scaled + 10 * total) / (20 * total)
    }

    private static func secondsPerStop(_ journey: CourseJourney) -> Int { journey.minutesPerStop * 60 }

    private static func clamped(_ journey: CourseJourney, _ elapsed: Int) -> Int {
        min(max(elapsed, 0), journey.totalSeconds)
    }

    private static func travelled(_ journey: CourseJourney, _ elapsed: Int) -> (stops: Int, remainder: Int) {
        let e = clamped(journey, elapsed), sps = secondsPerStop(journey)
        return (e / sps, e % sps)
    }

    /// 국지 평면 근사 방위(북쪽 0°, 시계 방향). 같은 구간을 반대로 가면 정확히 180° 차이가 난다.
    private static func heading(from: Int, to: Int) -> Double {
        let a = JourneyCourse.point(at: from), b = JourneyCourse.point(at: to)
        let meanLatitude = (a.latitude + b.latitude) / 2 * .pi / 180
        let degrees = atan2((b.longitude - a.longitude) * cos(meanLatitude), b.latitude - a.latitude) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }
}
