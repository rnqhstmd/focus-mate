#if DEBUG
import Foundation

/// 단위·UI 테스트 공용 카탈로그(PRD 수용 기준 표와 예시 데이터 재현). 앱 출시 빌드에는 들어가지 않는다.
extension RouteCatalog {
    static let fixtureMetadata = RouteDataMetadata(
        baseDate: "2026-09-02", dataset: "서울시버스노선별정류소정보", datasetID: "OA-1095",
        provider: "서울 열린데이터광장", copyright: "서울특별시", license: "공공누리 제1유형",
        routeInfoDataset: "서울시버스노선기본정보", routeInfoDatasetID: "OA-15066",
        stopsFile: "fixture-stops.xlsx", routeInfoFile: "fixture-routes.xlsx",
        sourceURL: "https://data.seoul.go.kr/dataList/OA-1095/F/1/datasetView.do",
        routeInfoSourceURL: "https://data.seoul.go.kr/dataList/OA-15066/F/1/datasetView.do")

    /// PRD 수용 기준 픽스처(S1~S11, X·Y·Z=S6~S8, P1~P3 / 노선 1111·2222·3333·5555·7777·8888).
    static func acceptanceFixture() throws -> RouteCatalog {
        let stops = acceptanceStops
        return try RouteCatalog(stops: stops, routes: acceptanceRoutes(in: stops), metadata: fixtureMetadata)
    }

    /// acceptance + 예시 데이터 9개 순환 정류장(정방향 id 그대로, 역방향은 "-r")과 노선 2014·2014-r·302·421.
    static func uiTestFixture() throws -> RouteCatalog {
        let forward = legacyStops.map { Stop(id: $0.id, name: $0.name, ars: nil, point: $0.point) }
        let reverse = legacyStops.map { Stop(id: $0.id + "-r", name: $0.name, ars: nil, point: $0.point) }
        let stops = acceptanceStops + forward + reverse
        let forwardIDs = legacyStops.map(\.id)
        let reverseIDs = ([forwardIDs[0]] + forwardIDs.dropFirst().reversed()).map { $0 + "-r" }
        let routes = acceptanceRoutes(in: stops) + [
            route("2014", number: "2014", kind: "지선", forwardIDs, seconds: 300, in: stops),
            route("2014-r", number: "2014", kind: "지선", reverseIDs, seconds: 300, in: stops),
            route("302", number: "강남02", kind: "마을", forwardIDs, seconds: 450, in: stops),
            route("421", number: "343", kind: "간선", forwardIDs, seconds: 424, in: stops),
        ]
        return try RouteCatalog(stops: stops, routes: routes, metadata: fixtureMetadata)
    }

    private static var acceptanceStops: [Stop] {
        let rows: [(String, String, String?)] = [
            ("S1", "알파", "10001"), ("S1b", "알파", "10002"), ("S2", "베타", "10003"), ("S3", "감마", "10004"),
            ("S4", "델타", "10005"), ("S5", "엡실론", "10006"), ("S9", "알파센터", "10007"),
            ("S10", "Alpha Dong", "40001"), ("S11", "무번호정류장", nil),
            ("S6", "X", "30001"), ("S7", "Y", "30002"), ("S8", "Z", "30003"),
            ("P1", "파이1", "20001"), ("P2", "파이2", "20002"), ("P3", "파이3", "20003"),
        ]
        return rows.enumerated().map { order, row in
            Stop(id: row.0, name: row.1, ars: row.2,
                 point: CoursePoint(latitude: 37.5 + Double(order + 1) / 1_000, longitude: 127.0 + Double(order + 1) / 500))
        }
    }

    private static func acceptanceRoutes(in stops: [Stop]) -> [Route] {
        [
            route("1111", kind: "지선", ["S1", "S2", "S3", "S4", "S5"], seconds: [300, 240, 420, 360, 120],
                  meters: [800, 600, 1100, 900, 700], in: stops),
            route("2222", kind: "간선", ["S1", "S3", "S5"], seconds: [660, 600, 60], in: stops),
            route("3333", kind: "순환", ["S6", "S7", "S8"], seconds: [300, 300, 300], in: stops),
            route("5555", kind: "지선", ["S1b", "S4"], seconds: [600, 60], in: stops),
            route("7777", kind: "지선", ["P1", "P2", "P3"], seconds: [300, 120, 60], in: stops),
            route("8888", kind: "지선", ["S11", "S4"], seconds: [600, 60], in: stops),
        ]
    }

    /// 예시 데이터(W02)의 9개 순환 정류장과 W06 근사 좌표.
    private static let legacyStops: [(id: String, name: String, point: CoursePoint)] = [
        ("seongsu", "성수역", CoursePoint(latitude: 37.5446, longitude: 127.0559)),
        ("seongsuDong", "성수동", CoursePoint(latitude: 37.5445, longitude: 127.0507)),
        ("ttukseom", "뚝섬역", CoursePoint(latitude: 37.5474, longitude: 127.0474)),
        ("seongdongSportsCenter", "성동구민체육센터", CoursePoint(latitude: 37.5466, longitude: 127.0429)),
        ("seoulForest", "서울숲역", CoursePoint(latitude: 37.5437, longitude: 127.0447)),
        ("seoulForestGate", "서울숲 입구", CoursePoint(latitude: 37.5432, longitude: 127.0396)),
        ("seongsuBridgeNorth", "성수대교 북단", CoursePoint(latitude: 37.5403, longitude: 127.0355)),
        ("ttukseomHangangPark", "뚝섬한강공원", CoursePoint(latitude: 37.5296, longitude: 127.0670)),
        ("seongsuIntersection", "성수사거리", CoursePoint(latitude: 37.5410, longitude: 127.0573)),
    ]

    private static func route(_ id: String, number: String? = nil, kind: String, _ stopIDs: [String],
                              seconds: Int, in stops: [Stop]) -> Route {
        route(id, number: number, kind: kind, stopIDs, seconds: Array(repeating: seconds, count: stopIDs.count),
              meters: Array(repeating: 550, count: stopIDs.count), in: stops)
    }

    private static func route(_ id: String, number: String? = nil, kind: String, _ stopIDs: [String], seconds: [Int],
                              meters: [Int]? = nil, in stops: [Stop]) -> Route {
        Route(id: id, number: number ?? id, kind: kind,
              stops: stopIDs.map { stopID in stops.firstIndex { $0.id == stopID }! },
              seconds: seconds, meters: meters ?? Array(repeating: 500, count: stopIDs.count))
    }
}
#endif
