import Foundation

/// 번들 데이터의 출처 정보(데이터 출처 화면에 표시한다).
struct RouteDataMetadata: Equatable, Sendable {
    let baseDate: String
    let dataset: String
    let datasetID: String
    let provider: String
    let copyright: String
    let license: String
    let routeInfoDataset: String
    let routeInfoDatasetID: String
    let stopsFile: String
    let routeInfoFile: String
}

/// 한 정류장을 지나는 노선과 그 노선 안의 첫 지점.
struct RouteVisit: Equatable, Sendable {
    let route: Int
    let position: Int
}

enum RouteCatalogIssue: Error, Equatable {
    case invalidRoute(String)
    case unknownStop(String)
    case malformed
}

/// 노선 번호 자연 정렬. 숫자 덩어리는 크기로, 글자 덩어리는 유니코드 순으로 비교한다(720 → 1111 → 강남02).
enum RouteNumberOrder {
    static func areInIncreasingOrder(_ lhs: String, _ rhs: String) -> Bool {
        let left = chunks(lhs), right = chunks(rhs)
        for (a, b) in zip(left, right) {
            switch (a.isNumber, b.isNumber) {
            case (true, false): return true
            case (false, true): return false
            case (true, true):
                let x = a.text.drop { $0 == "0" }, y = b.text.drop { $0 == "0" }
                if x.count != y.count { return x.count < y.count }
                if x != y { return x < y }
                if a.text.count != b.text.count { return a.text.count < b.text.count }
            case (false, false):
                if a.text != b.text { return a.text.unicodeScalars.lexicographicallyPrecedes(b.text.unicodeScalars) }
            }
        }
        return left.count < right.count
    }

    private static func chunks(_ text: String) -> [(text: String, isNumber: Bool)] {
        var result: [(text: String, isNumber: Bool)] = []
        for character in text {
            let isNumber = character.isASCII && character.isNumber
            if let last = result.last, last.isNumber == isNumber {
                result[result.count - 1].text.append(character)
            } else {
                result.append((String(character), isNumber))
            }
        }
        return result
    }
}

/// 서울 버스 정류장·노선 데이터. 모든 경로 규칙은 이 값을 주입받는다(전역 상수 대신).
struct RouteCatalog: Sendable {
    struct Stop: Equatable, Sendable {
        let id: String
        let name: String
        let ars: String?
        let point: CoursePoint
    }

    /// `stops`는 카탈로그 정류장 색인. 구간 i는 정류장 i → i+1이고 마지막은 회차(마지막 → 첫 정류장)다.
    struct Route: Equatable, Sendable {
        let id: String
        let number: String
        let kind: String
        let stops: [Int]
        let seconds: [Int]
        let meters: [Int]
    }

    let stops: [Stop]
    let routes: [Route]
    let metadata: RouteDataMetadata
    private let stopIndexByID: [String: Int]
    private let routeIndexByID: [String: Int]
    private let visitsByStop: [[RouteVisit]]

    init(stops: [Stop], routes: [Route], metadata: RouteDataMetadata) throws {
        for route in routes {
            let count = route.stops.count
            guard count >= 2, route.seconds.count == count, route.meters.count == count,
                  route.seconds.allSatisfy({ $0 >= 1 }), route.stops.allSatisfy(stops.indices.contains)
            else { throw RouteCatalogIssue.invalidRoute(route.id) }
        }
        let ordered = routes.sorted {
            $0.number == $1.number ? $0.id < $1.id : RouteNumberOrder.areInIncreasingOrder($0.number, $1.number)
        }
        var visits = Array(repeating: [RouteVisit](), count: stops.count)
        for (routeIndex, route) in ordered.enumerated() {
            var seen = Set<Int>()
            for (position, stop) in route.stops.enumerated() where seen.insert(stop).inserted {
                visits[stop].append(RouteVisit(route: routeIndex, position: position))
            }
        }
        self.stops = stops
        self.routes = ordered
        self.metadata = metadata
        stopIndexByID = Dictionary(stops.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        routeIndexByID = Dictionary(ordered.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        visitsByStop = visits
    }

    func stopIndex(id: String) -> Int? { stopIndexByID[id] }

    func routeIndex(id: String) -> Int? { routeIndexByID[id] }

    func visits(stopIndex: Int) -> [RouteVisit] { visitsByStop[stopIndex] }

    /// 지나는 노선이 가장 많이 향하는 다음 정류장의 "○○ 방면". 동률이면 정렬상 앞선 노선의 다음 정류장이다.
    func boundLabel(stopIndex: Int) -> String? {
        var counts: [Int: (count: Int, firstRoute: Int)] = [:]
        for visit in visitsByStop[stopIndex] {
            let route = routes[visit.route]
            let next = route.stops[(visit.position + 1) % route.stops.count]
            let current = counts[next] ?? (0, visit.route)
            counts[next] = (current.count + 1, current.firstRoute)
        }
        let best = counts.min { a, b in
            a.value.count != b.value.count ? a.value.count > b.value.count : a.value.firstRoute < b.value.firstRoute
        }
        return best.map { stops[$0.key].name + " 방면" }
    }
}
