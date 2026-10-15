import Foundation

/// 고른 시간에 맞는 노선 하나와 그 도착지(서울 전체 데이터). 기존 `JourneyCandidate`를 대신할 타입이다.
struct RouteCandidate: Identifiable, Equatable {
    let routeID: String
    let busNumber: String
    let busKind: String
    let minutes: Int
    let stops: Int
    let destinationStopID: String
    let destination: String
    let leg: RouteLeg

    var id: String { routeID }

    /// 0.1km 단위 반올림. 정수 km면 소수점을 붙이지 않는다.
    var distanceText: String {
        let tenths = (leg.distanceMeters + 50) / 100
        return tenths % 10 == 0 ? "\(tenths / 10)km" : "\(tenths / 10).\(tenths % 10)km"
    }

    var accessibilityLabel: String { "\(busKind) \(busNumber)번, \(destination), \(minutes)분, \(stops)정류장" }
}

/// FR-4·BR-8: 출발 정류장을 지나는 노선마다 후보 1건, 시간 차이 → 노선 번호 순, 최대 20건.
enum RouteCandidates {
    static let limit = 20

    static func candidates(minutes: Int, originStop: Int, in catalog: RouteCatalog) -> [RouteCandidate] {
        let legs = catalog.visits(stopIndex: originStop).compactMap { visit in
            RouteLegFinder.leg(route: visit.route, originStop: originStop, minutes: minutes, in: catalog)
        }
        return legs
            .sorted { ($0.differenceSeconds, $0.routeIndex) < ($1.differenceSeconds, $1.routeIndex) }
            .prefix(limit)
            .map { leg in
                let route = catalog.routes[leg.routeIndex]
                let destination = catalog.stops[leg.stopIndices[leg.stopIndices.count - 1]]
                return RouteCandidate(routeID: route.id, busNumber: route.number, busKind: route.kind,
                                      minutes: minutes, stops: leg.segmentSeconds.count,
                                      destinationStopID: destination.id, destination: destination.name, leg: leg)
            }
    }
}
