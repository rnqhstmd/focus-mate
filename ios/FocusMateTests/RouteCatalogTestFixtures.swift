import Foundation
@testable import FocusMate

/// 노선 카탈로그 테스트 공용 픽스처. 좌표는 임의이며 정류장마다 서로 다르다.
enum RouteCatalogFixture {
    static let metadata = RouteDataMetadata(
        baseDate: "2026-09-02", dataset: "서울시버스노선별정류소정보", datasetID: "OA-1095",
        provider: "서울 열린데이터광장", copyright: "서울특별시", license: "공공누리 제1유형",
        routeInfoDataset: "서울시버스노선기본정보", routeInfoDatasetID: "OA-15066",
        stopsFile: "stops.csv", routeInfoFile: "routes.csv"
    )

    static func stop(_ id: String, _ name: String, ars: String? = nil, _ order: Int = 0) -> RouteCatalog.Stop {
        RouteCatalog.Stop(
            id: id, name: name, ars: ars,
            point: CoursePoint(latitude: 37.5 + Double(order) / 1_000, longitude: 127.0 + Double(order) / 500)
        )
    }

    /// stopIDs는 stops 배열의 id로 적고 색인으로 변환한다. 구간 초·미터는 생략하면 각각 60·500.
    static func route(
        _ id: String, number: String? = nil, kind: String = "지선", stops stopIDs: [String],
        in stops: [RouteCatalog.Stop], seconds: [Int]? = nil, meters: [Int]? = nil
    ) -> RouteCatalog.Route {
        let indexes = stopIDs.map { id in stops.firstIndex { $0.id == id } ?? -1 }
        return RouteCatalog.Route(
            id: id, number: number ?? id, kind: kind, stops: indexes,
            seconds: seconds ?? Array(repeating: 60, count: stopIDs.count),
            meters: meters ?? Array(repeating: 500, count: stopIDs.count)
        )
    }

    static func make(stops: [RouteCatalog.Stop], routes: [RouteCatalog.Route]) throws -> RouteCatalog {
        try RouteCatalog(stops: stops, routes: routes, metadata: metadata)
    }

    static func acceptance() throws -> RouteCatalog {
        let stops = [
            stop("S1", "알파", ars: "10001", 1), stop("S1b", "알파", ars: "10002", 2),
            stop("S2", "베타", ars: "10003", 3), stop("S3", "감마", ars: "10004", 4),
            stop("S4", "델타", ars: "10005", 5), stop("S5", "엡실론", ars: "10006", 6),
            stop("S9", "알파센터", ars: "10007", 7), stop("S10", "Alpha Dong", ars: "40001", 8),
            stop("S11", "무번호정류장", ars: nil, 9),
            stop("S6", "X", ars: "30001", 10), stop("S7", "Y", ars: "30002", 11), stop("S8", "Z", ars: "30003", 12),
            stop("P1", "파이1", ars: "20001", 13), stop("P2", "파이2", ars: "20002", 14), stop("P3", "파이3", ars: "20003", 15),
        ]
        let routes = [
            route("1111", kind: "지선", stops: ["S1", "S2", "S3", "S4", "S5"], in: stops,
                  seconds: [300, 240, 420, 360, 120], meters: [800, 600, 1100, 900, 700]),
            route("2222", kind: "간선", stops: ["S1", "S3", "S5"], in: stops, seconds: [660, 600, 60]),
            route("3333", kind: "순환", stops: ["S6", "S7", "S8"], in: stops, seconds: [300, 300, 300]),
            route("5555", kind: "지선", stops: ["S1b", "S4"], in: stops, seconds: [600, 60]),
            route("7777", kind: "지선", stops: ["P1", "P2", "P3"], in: stops, seconds: [300, 120, 60]),
            route("8888", kind: "지선", stops: ["S11", "S4"], in: stops, seconds: [600, 60]),
        ]
        return try make(stops: stops, routes: routes)
    }
}
