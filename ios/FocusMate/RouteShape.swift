import Foundation

/// 정류장 i → i+1 구간마다의 실제 선(도로에 맞춘 polyline). 각 구간은 그 구간의 두 정류장에서 시작·끝난다.
/// 버스 위치는 구간 진행 비율을 그 구간 선 길이 비율로 바꿔 선 위에서 찾고, 방향은 그 자리의 선 접선으로 정한다.
/// 순수 계산이라 CoreLocation·MapKit 없이 테스트한다.
struct RouteShape: Equatable {
    /// 위치 = 구간 번호 + 구간 안 비율(0이면 그 구간 시작 정류장 위).
    struct Location: Equatable {
        let segment: Int
        let fraction: Double
    }

    /// 접선 방위를 볼 때 앞(또는 뒤)으로 내다보는 거리(m). 도로 선의 잔 꺾임에 흔들리지 않게 한다.
    static let lookMeters = 40.0

    let segments: [[CoursePoint]]
    /// 꼭짓점을 한 줄로 이은 선(구간 경계 정류장은 한 번만).
    let points: [CoursePoint]
    /// `points` 각 꼭짓점까지의 누적 거리(m).
    private let distances: [Double]
    /// 구간 i의 시작 꼭짓점 번호(`points` 기준). 마지막 원소는 끝 꼭짓점.
    private let segmentStarts: [Int]

    init(segments: [[CoursePoint]]) {
        let segments = segments.map { $0.count >= 2 ? $0 : ($0 + $0).prefix(2).map { $0 } }
        self.segments = segments
        var points: [CoursePoint] = []
        var starts: [Int] = []
        for segment in segments {
            if points.isEmpty { points.append(segment[0]) }
            starts.append(points.count - 1)
            points.append(contentsOf: segment.dropFirst())
        }
        starts.append(max(points.count - 1, 0))
        var distances: [Double] = points.isEmpty ? [] : [0]
        for i in points.indices.dropFirst() {
            distances.append(distances[i - 1] + Self.meters(points[i - 1], points[i]))
        }
        self.points = points
        self.distances = distances
        segmentStarts = starts
    }

    /// 정류장끼리 곧게 이은 선(도로 경로를 아직 못 받았거나 받지 못한 구간).
    static func straight(_ stops: [CoursePoint]) -> RouteShape {
        RouteShape(segments: zip(stops, stops.dropFirst()).map { [$0, $1] })
    }

    var totalMeters: Double { distances.last ?? 0 }

    /// 위치 → 선 시작부터의 거리(m).
    func distance(at location: Location) -> Double {
        guard !segments.isEmpty else { return 0 }
        if location.segment >= segments.count { return totalMeters }
        let s = max(location.segment, 0)
        let start = distances[segmentStarts[s]], end = distances[segmentStarts[s + 1]]
        return start + (end - start) * min(max(location.fraction, 0), 1)
    }

    func point(at location: Location) -> CoursePoint { point(atDistance: distance(at: location)) }

    func point(atDistance d: Double) -> CoursePoint {
        guard let first = points.first else { return CoursePoint(latitude: 0, longitude: 0) }
        guard d > 0 else { return first }
        guard d < totalMeters else { return points[points.count - 1] }
        let i = vertex(before: d)
        let span = distances[i + 1] - distances[i]
        let t = span > 0 ? (d - distances[i]) / span : 0
        let a = points[i], b = points[i + 1]
        return CoursePoint(latitude: a.latitude + (b.latitude - a.latitude) * t,
                           longitude: a.longitude + (b.longitude - a.longitude) * t)
    }

    /// 위치의 진행 방위(북 0°, 시계 방향). `range` 안(보통 탈 구간)에서만 내다본다.
    /// 앞으로 내다볼 거리가 없으면(도착) 뒤에서 그 자리까지의 방향을 쓴다. 선 길이가 0이면 nil.
    func heading(at location: Location, within range: ClosedRange<Double>? = nil, backward: Bool = false) -> Double? {
        let bounds = range ?? 0...totalMeters
        let d = min(max(distance(at: location), bounds.lowerBound), bounds.upperBound)
        if !backward, d + 0.5 < bounds.upperBound {
            let ahead = min(d + Self.lookMeters, bounds.upperBound)
            if let h = Self.bearing(point(atDistance: d), point(atDistance: ahead)) { return h }
        }
        let behind = max(d - Self.lookMeters, bounds.lowerBound)
        if let h = Self.bearing(point(atDistance: behind), point(atDistance: d)) { return h }
        return Self.bearing(point(atDistance: bounds.lowerBound), point(atDistance: bounds.upperBound))
    }

    /// 두 위치 사이의 선(앞 위치 → 뒤 위치). 두 끝은 정확히 그 위치 점이다.
    func line(from a: Location, to b: Location) -> [CoursePoint] {
        line(fromDistance: distance(at: a), toDistance: distance(at: b))
    }

    /// 두 거리 사이의 선. 화면에서 버스를 매끄럽게 옮길 때 소수 거리로 자른다.
    func line(fromDistance da: Double, toDistance db: Double) -> [CoursePoint] {
        guard db > da else { return [point(atDistance: da), point(atDistance: da)] }
        var result = [point(atDistance: da)]
        for i in points.indices where distances[i] > da && distances[i] < db { result.append(points[i]) }
        result.append(point(atDistance: db))
        return result
    }

    /// 마지막 꼭짓점 i: distances[i] ≤ d < distances[i+1].
    private func vertex(before d: Double) -> Int {
        var low = 0, high = distances.count - 1
        while high - low > 1 {
            let mid = (low + high) / 2
            if distances[mid] <= d { low = mid } else { high = mid }
        }
        return low
    }

    // MARK: 평면 근사 계산

    /// 짧은 거리용 국지 평면 근사(m).
    static func meters(_ a: CoursePoint, _ b: CoursePoint) -> Double {
        let lat = (a.latitude + b.latitude) / 2 * .pi / 180
        let dx = (b.longitude - a.longitude) * 111_320 * cos(lat)
        let dy = (b.latitude - a.latitude) * 110_540
        return (dx * dx + dy * dy).squareRoot()
    }

    /// a → b 방위(북 0°, 시계 방향, 0..<360). 같은 점이면 nil.
    static func bearing(_ a: CoursePoint, _ b: CoursePoint) -> Double? {
        guard meters(a, b) > 0.01 else { return nil }
        let lat = (a.latitude + b.latitude) / 2 * .pi / 180
        let degrees = atan2((b.longitude - a.longitude) * 111_320 * cos(lat), (b.latitude - a.latitude) * 110_540) * 180 / .pi
        return degrees < 0 ? degrees + 360 : degrees
    }

    /// 점에서 방위 쪽으로 몇 m 떨어진 점(국지 평면 근사).
    static func offset(_ point: CoursePoint, headingDegrees: Double, meters: Double) -> CoursePoint {
        let radians = headingDegrees * .pi / 180
        let lat = point.latitude * .pi / 180
        return CoursePoint(latitude: point.latitude + meters * cos(radians) / 110_540,
                           longitude: point.longitude + meters * sin(radians) / (111_320 * cos(lat)))
    }

    static func length(_ path: [CoursePoint]) -> Double {
        zip(path, path.dropFirst()).reduce(0) { $0 + meters($1.0, $1.1) }
    }
}

/// 도로 경로를 그 구간 선으로 받아들일지 정하는 규칙. 못 받았거나(실패·오프라인) 너무 돌아가면 곧은 선으로 대신한다.
enum RouteSegmentRule {
    /// 직선 거리의 이 배수를 넘게 돌아가면 다른 길로 샌 것으로 본다.
    static let maximumDetourRatio = 3.0
    /// 아주 가까운 정류장(길 건너편 등)은 배수만으로 판단하면 너무 엄격해서 이 거리까지는 허용한다.
    static let minimumAllowanceMeters = 300.0
    /// 도로 경로의 시작·끝이 정류장에서 이보다 멀면 엉뚱한 길에 붙은 것으로 본다.
    static let maximumSnapMeters = 150.0

    static func resolve(_ road: [CoursePoint]?, from: CoursePoint, to: CoursePoint) -> [CoursePoint] {
        let straight = [from, to]
        guard let road, road.count >= 2,
              RouteShape.meters(from, road[0]) <= maximumSnapMeters,
              RouteShape.meters(to, road[road.count - 1]) <= maximumSnapMeters else { return straight }
        // 도로 경로의 양 끝(도로 위로 붙인 점)을 정류장 자리로 바꾼다. 정류장 → 도로 끝점의 짧은 수직 연결선이
        // 남으면 정류장에 선 버스의 방향이 도로와 직각으로 잡힌다.
        var path = [from]
        for point in road.dropFirst().dropLast() + [to] where point != path[path.count - 1] { path.append(point) }
        let direct = RouteShape.meters(from, to)
        guard RouteShape.length(path) <= max(direct * maximumDetourRatio, minimumAllowanceMeters) else { return straight }
        return path
    }
}

/// 버스 진행 표시(다음 정류장·지난 수) 값.
struct JourneyStopProgress: Equatable {
    /// 지나온(도달한) 정류장 수. 출발 정류장은 세지 않는다.
    let passed: Int
    /// 출발 뒤 거쳐 갈 정류장 수(도착 포함).
    let total: Int
    let nextName: String

    init(journey: CourseJourney, nextStopIndex: Int) {
        total = journey.totalStops
        let next = min(max(nextStopIndex, 1), journey.totalStops)
        passed = next - 1
        nextName = journey.stops[next].name
    }
}
