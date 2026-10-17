import Foundation

/// 지도 계산에 필요한 여정 구간(실제 노선의 출발 → 도착). 진도 계산은 정수 초로 해서 경계 값이 정확히 맞게 한다.
struct CourseJourney: Equatable {
    /// 코스 위치 0…k(출발 포함).
    let stops: [CourseStop]
    let segmentSeconds: [Int]
    let segmentMeters: [Int]
    /// 0을 포함한 k+1개.
    let cumulativeSeconds: [Int]
    /// 노선 종류("간선"·"지선"·"마을" 등). 지도 노선선 색에만 쓴다.
    let routeKind: String
    /// 노선 ID. 도로 경로 캐시 키에 쓴다.
    let routeID: String
    /// 노선 전체를 흐린 선으로 보이기 위한 탈 구간 앞·뒤 정류장(노선 순서, 최대 `contextStops`개씩).
    let stopsBefore: [CourseStop]
    let stopsAfter: [CourseStop]

    static let contextStops = 6

    var totalSeconds: Int { cumulativeSeconds.last! }
    var totalStops: Int { segmentSeconds.count }

    init(leg: RouteLeg, catalog: RouteCatalog) {
        stops = leg.stopIndices.enumerated().map { position, index in
            let stop = catalog.stops[index]
            return CourseStop(index: position, id: stop.id, name: stop.name, point: stop.point)
        }
        segmentSeconds = leg.segmentSeconds
        segmentMeters = leg.segmentMeters
        cumulativeSeconds = leg.cumulativeSeconds
        let route = catalog.routes.indices.contains(leg.routeIndex) ? catalog.routes[leg.routeIndex] : nil
        routeKind = route?.kind ?? ""
        routeID = route?.id ?? ""
        if let route, !route.stops.isEmpty {
            let count = route.stops.count
            // 순환 노선이라 위치는 나머지로 돈다. 앞뒤 정류장이 탈 구간과 겹치지 않게 남은 수를 나눈다.
            let free = max(count - leg.segmentSeconds.count - 1, 0)
            let before = min(Self.contextStops, free / 2), after = min(Self.contextStops, free - free / 2)
            func stop(_ offset: Int) -> CourseStop {
                let index = route.stops[((leg.originPosition + offset) % count + count) % count]
                let item = catalog.stops[index]
                return CourseStop(index: offset, id: item.id, name: item.name, point: item.point)
            }
            stopsBefore = (0..<before).map { stop($0 - before) }
            stopsAfter = (0..<after).map { stop(leg.segmentSeconds.count + 1 + $0) }
        } else {
            stopsBefore = []
            stopsAfter = []
        }
    }

    /// 노선선 전체(앞 문맥 + 탈 구간 + 뒤 문맥)의 구간 요청. 탈 구간은 `stopsBefore.count`번째 구간부터다.
    var segmentRequests: [RouteSegmentRequest] {
        let all = stopsBefore + stops + stopsAfter
        return zip(all, all.dropFirst()).map {
            RouteSegmentRequest(routeID: routeID, fromID: $0.id, toID: $1.id, from: $0.point, to: $1.point)
        }
    }

    /// 저장된 여정에서 구간을 다시 만든다. 노선·출발 정류장이 없거나, 구간이 없거나, 다시 계산한 도착지가 저장값과 다르면 nil이다(BR-12).
    /// nil이면 여행 화면은 지도 없이 W05 배치로 보인다.
    init?(journey: JourneySnapshot, catalog: RouteCatalog) {
        guard let route = catalog.routeIndex(id: journey.busID), let origin = catalog.stopIndex(id: journey.originStopID),
              let leg = RouteLegFinder.leg(route: route, originStop: origin, minutes: journey.minutes, in: catalog),
              leg.stopIndices.last.map({ catalog.stops[$0].id }) == journey.destinationStopID
        else { return nil }
        self.init(leg: leg, catalog: catalog)
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
    static func position(of journey: CourseJourney, elapsedSeconds: Int) -> CourseBusPosition {
        let e = clamped(journey, elapsedSeconds)
        let j = reachedIndex(journey, e)
        let k = journey.totalStops
        if j >= k {
            return CourseBusPosition(point: journey.stops[k].point, headingDegrees: heading(journey, segment: k - 1),
                                     segmentFrom: k, segmentTo: k, fraction: 0, isArrived: true)
        }
        let fraction = Double(e - journey.cumulativeSeconds[j]) / Double(journey.segmentSeconds[j])
        let a = journey.stops[j].point, b = journey.stops[j + 1].point
        let point = CoursePoint(latitude: a.latitude + (b.latitude - a.latitude) * fraction,
                                longitude: a.longitude + (b.longitude - a.longitude) * fraction)
        return CourseBusPosition(point: point, headingDegrees: heading(journey, segment: j),
                                 segmentFrom: j, segmentTo: j + 1, fraction: fraction, isArrived: false)
    }

    static func nextStopIndex(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        min(journey.totalStops, reachedIndex(journey, clamped(journey, elapsedSeconds)) + 1)
    }

    static func remainingStops(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        journey.totalStops - reachedIndex(journey, clamped(journey, elapsedSeconds))
    }

    /// 남은 거리(m)를 0.1km 단위 정수로 반올림(half-up)한다. 지나는 중인 구간은 남은 시간 비율만큼 센다.
    static func remainingDistanceTenthsKm(of journey: CourseJourney, elapsedSeconds: Int) -> Int {
        let e = clamped(journey, elapsedSeconds)
        let j = reachedIndex(journey, e)
        guard j < journey.totalStops else { return 0 }
        let seconds = journey.segmentSeconds[j]
        let ahead = journey.segmentMeters[(j + 1)...].reduce(0, +)
        // 남은 m × 구간 초. 나눗셈을 한 번만 해서 반올림 오차를 없앤다.
        let scaled = ahead * seconds + journey.segmentMeters[j] * (journey.cumulativeSeconds[j + 1] - e)
        return (2 * scaled + 100 * seconds) / (200 * seconds)
    }

    private static func clamped(_ journey: CourseJourney, _ elapsed: Int) -> Int {
        min(max(elapsed, 0), journey.totalSeconds)
    }

    /// j = max{i | cum[i] ≤ e}.
    private static func reachedIndex(_ journey: CourseJourney, _ elapsed: Int) -> Int {
        journey.cumulativeSeconds.lastIndex { $0 <= elapsed } ?? 0
    }

    /// 국지 평면 근사 방위(북쪽 0°, 시계 방향). 좌표가 같은 구간은 직전 구간 방위를 쓴다(첫 구간이면 0).
    private static func heading(_ journey: CourseJourney, segment: Int) -> Double {
        var i = segment
        while i >= 0 {
            let a = journey.stops[i].point, b = journey.stops[i + 1].point
            if a != b {
                let meanLatitude = (a.latitude + b.latitude) / 2 * .pi / 180
                let degrees = atan2((b.longitude - a.longitude) * cos(meanLatitude), b.latitude - a.latitude) * 180 / .pi
                return degrees < 0 ? degrees + 360 : degrees
            }
            i -= 1
        }
        return 0
    }
}
