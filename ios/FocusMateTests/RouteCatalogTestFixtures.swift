import Foundation
@testable import FocusMate

/// 노선 카탈로그 테스트 공용 픽스처. 좌표는 임의이며 정류장마다 서로 다르다.
enum RouteCatalogFixture {
    static let metadata = RouteDataMetadata(
        baseDate: "2026-09-02", dataset: "서울시버스노선별정류소정보", datasetID: "OA-1095",
        provider: "서울 열린데이터광장", copyright: "서울특별시", license: "공공누리 제1유형",
        routeInfoDataset: "서울시버스노선기본정보", routeInfoDatasetID: "OA-15066",
        stopsFile: "stops.csv", routeInfoFile: "routes.csv",
        sourceURL: "https://example.test/stops", routeInfoSourceURL: "https://example.test/routes"
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
        try RouteCatalog.acceptanceFixture()
    }
}
