import Foundation

/// 한 노선 위에서 출발 정류장부터 고른 시간에 맞춘 도착 정류장까지의 구간(BR-6, BR-7).
/// 구간 초는 합이 고른 시간과 정확히 같도록 비례 조정된 값이다.
struct RouteLeg: Equatable, Sendable {
    let routeIndex: Int
    let originPosition: Int
    let stopIndices: [Int]
    let segmentSeconds: [Int]
    let segmentMeters: [Int]
    let cumulativeSeconds: [Int]
    let differenceSeconds: Int
    let distanceMeters: Int
}

enum RouteLegFinder {
    static let toleranceSeconds = 60

    static func leg(route routeIndex: Int, originStop: Int, minutes: Int, in catalog: RouteCatalog) -> RouteLeg? {
        guard (1...JourneySnapshot.maximumMinutes).contains(minutes),
              let visit = catalog.visits(stopIndex: originStop).first(where: { $0.route == routeIndex }) else { return nil }
        let route = catalog.routes[routeIndex]
        let count = route.stops.count
        let target = minutes * 60

        var elapsed = 0
        var best: (steps: Int, original: Int, difference: Int)?
        var step = 0
        while elapsed <= target + toleranceSeconds {
            elapsed += route.seconds[(visit.position + step) % count]
            step += 1
            guard route.stops[(visit.position + step) % count] != originStop else { continue }
            let difference = abs(elapsed - target)
            if difference <= toleranceSeconds, difference < (best?.difference ?? .max) {
                best = (step, elapsed, difference)
            }
        }
        guard let best else { return nil }

        let segments = (0..<best.steps).map { (visit.position + $0) % count }
        let original = segments.map { route.seconds[$0] }
        guard let adjusted = scaled(original, from: best.original, to: target) else { return nil }
        let meters = segments.map { route.meters[$0] }
        return RouteLeg(
            routeIndex: routeIndex, originPosition: visit.position,
            stopIndices: (0...best.steps).map { route.stops[(visit.position + $0) % count] },
            segmentSeconds: adjusted, segmentMeters: meters,
            cumulativeSeconds: adjusted.reduce(into: [0]) { $0.append($0.last! + $1) },
            differenceSeconds: best.difference, distanceMeters: meters.reduce(0, +))
    }

    /// 앞 구간부터 반올림(0.5 올림)하고 마지막 구간이 차이를 흡수한다. 마지막이 1초 미만이면 nil.
    private static func scaled(_ seconds: [Int], from original: Int, to target: Int) -> [Int]? {
        guard original != target else { return seconds }
        var result = seconds.dropLast().map { (2 * $0 * target + original) / (2 * original) }
        let last = target - result.reduce(0, +)
        guard last >= 1 else { return nil }
        result.append(last)
        return result
    }
}
