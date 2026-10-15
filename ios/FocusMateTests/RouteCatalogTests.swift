import Foundation
import XCTest
@testable import FocusMate

final class RouteCatalogTests: XCTestCase {
    private typealias F = RouteCatalogFixture

    // 깨짐: 동률 시 정렬 순이 아닌 다른 노선을 고르면 실패한다.
    func testAC10_동률이면_번호가_앞선_노선의_다음_정류장_방면이다() throws {
        let catalog = try F.acceptance()
        let s1 = try XCTUnwrap(catalog.stopIndex(id: "S1"))
        XCTAssertEqual(catalog.boundLabel(stopIndex: s1), "베타 방면")
    }

    // 깨짐: 항상 첫 노선·고정 값을 쓰면 S1과 다른 값이어야 하는 이 테스트가 실패한다.
    func testAC11_노선_하나만_지나면_그_노선의_다음_정류장_방면이다() throws {
        let catalog = try F.acceptance()
        let s1b = try XCTUnwrap(catalog.stopIndex(id: "S1b"))
        XCTAssertEqual(catalog.boundLabel(stopIndex: s1b), "델타 방면")
    }

    // 깨짐: 다수결 대신 첫 노선을 고르면 B가 나와 실패한다.
    func testBoundLabelUsesMajorityNextStop() throws {
        let stops = [F.stop("Q", "큐", 1), F.stop("A", "에이", 2), F.stop("B", "비", 3)]
        let routes = [
            F.route("1", stops: ["Q", "B"], in: stops),
            F.route("2", stops: ["Q", "A"], in: stops),
            F.route("3", stops: ["Q", "A"], in: stops),
        ]
        let catalog = try F.make(stops: stops, routes: routes)
        XCTAssertEqual(catalog.boundLabel(stopIndex: 0), "에이 방면")
    }

    // 깨짐: 마지막 정류장에서 nil이나 크래시가 나면 실패한다.
    func testBoundLabelWrapsToFirstStopAtRouteEnd() throws {
        let catalog = try F.acceptance()
        let p3 = try XCTUnwrap(catalog.stopIndex(id: "P3"))
        XCTAssertEqual(catalog.boundLabel(stopIndex: p3), "파이1 방면")
    }

    // 깨짐: 지나는 노선이 없는데 문자열을 주면 실패한다.
    func testBoundLabelIsNilWhenNoRoutePasses() throws {
        let catalog = try F.acceptance()
        let s9 = try XCTUnwrap(catalog.stopIndex(id: "S9"))
        XCTAssertNil(catalog.boundLabel(stopIndex: s9))
    }

    // 깨짐: 반복 정류장을 마지막·중복 지점으로 세면 실패한다.
    func testVisitsReportsOnlyFirstPositionOfRepeatedStop() throws {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2), F.stop("C", "씨", 3)]
        let catalog = try F.make(stops: stops, routes: [F.route("9", stops: ["A", "B", "A", "C"], in: stops)])
        XCTAssertEqual(catalog.visits(stopIndex: 0), [RouteVisit(route: 0, position: 0)])
    }

    // 깨짐: 숫자를 문자열 사전순으로 비교하면 "1111" < "720"이 되어 실패한다.
    func testAC23_노선_번호는_자연_정렬된다() throws {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let routes = ["강남02", "1111", "720"].map { F.route($0, stops: ["A", "B"], in: stops) }
        let catalog = try F.make(stops: stops, routes: routes)
        XCTAssertEqual(catalog.routes.map(\.number), ["720", "1111", "강남02"])
    }

    func testRouteNumberOrderComparisons() {
        let pairs = [("9", "10"), ("720", "1111"), ("1111", "강남02"), ("N13", "N61"), ("6640A", "6640B"), ("100", "100A"), ("2", "02")]
        for (small, large) in pairs {
            XCTAssertTrue(RouteNumberOrder.areInIncreasingOrder(small, large), "\(small) < \(large)")
            XCTAssertFalse(RouteNumberOrder.areInIncreasingOrder(large, small), "\(large) !< \(small)")
        }
    }

    // 깨짐: 정류장 2개 미만 검사를 빼면 throw하지 않아 실패한다.
    func testRouteWithSingleStopIsInvalid() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        XCTAssertThrowsError(try F.make(stops: stops, routes: [F.route("1", stops: ["A"], in: stops)])) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .invalidRoute("1"))
        }
    }

    func testRouteWithMismatchedSecondsLengthIsInvalid() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let route = F.route("1", stops: ["A", "B"], in: stops, seconds: [60])
        XCTAssertThrowsError(try F.make(stops: stops, routes: [route])) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .invalidRoute("1"))
        }
    }

    func testRouteWithZeroSegmentSecondsIsInvalid() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let route = F.route("1", stops: ["A", "B"], in: stops, seconds: [0, 60])
        XCTAssertThrowsError(try F.make(stops: stops, routes: [route])) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .invalidRoute("1"))
        }
    }

    // 깨짐: 색인 조회가 항상 nil이거나 없는 id에 값을 주면 실패한다.
    func testStopAndRouteIndexLookup() throws {
        let catalog = try F.acceptance()
        XCTAssertEqual(catalog.stopIndex(id: "S4"), 4)
        XCTAssertNil(catalog.stopIndex(id: "nope"))
        XCTAssertEqual(catalog.routeIndex(id: "2222"), 1)
        XCTAssertNil(catalog.routeIndex(id: "nope"))
    }

    // MARK: 로더

    private static let source = """
    "source":{"baseDate":"2026-09-02","copyright":"서울특별시","dataset":"서울시버스노선별정류소정보","datasetID":"OA-1095","license":"공공누리 제1유형","provider":"서울 열린데이터광장","routeInfoDataset":"서울시버스노선기본정보","routeInfoDatasetID":"OA-15066","routeInfoFile":"r.csv","stopsFile":"s.csv"}
    """

    private func json(routeNodes: String) -> Data {
        Data("""
        {"format":1,\(Self.source),"stops":[["N1","시작",  "",37500000,127000000],["N2","끝","12345",37510000,127010000]],"routes":[["R1","100","지선",\(routeNodes),[60,120],[500,700]]]}
        """.utf8)
    }

    // 깨짐: 좌표 나눗셈·ARS 빈 값 처리·색인 매핑·메타데이터 중 하나라도 틀리면 실패한다.
    func testLoaderParsesStopsRoutesAndMetadata() throws {
        let catalog = try RouteCatalogLoader.load(data: json(routeNodes: "[\"N1\",\"N2\"]"))
        XCTAssertEqual(catalog.metadata.baseDate, "2026-09-02")
        XCTAssertEqual(catalog.stops[0].point.latitude, 37.5, accuracy: 1e-9)
        XCTAssertEqual(catalog.stops[0].point.longitude, 127.0, accuracy: 1e-9)
        XCTAssertNil(catalog.stops[0].ars)
        XCTAssertEqual(catalog.stops[1].ars, "12345")
        XCTAssertEqual(catalog.routes[0].stops, [0, 1])
        XCTAssertEqual(catalog.routes[0].seconds, [60, 120])
    }

    func testLoaderRejectsUnknownStopReference() {
        XCTAssertThrowsError(try RouteCatalogLoader.load(data: json(routeNodes: "[\"N1\",\"X\"]"))) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .unknownStop("X"))
        }
    }

    func testLoaderRejectsMissingFormat() {
        let data = Data("{\"stops\":[],\"routes\":[]}".utf8)
        XCTAssertThrowsError(try RouteCatalogLoader.load(data: data)) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .malformed)
        }
    }

    func testLoaderRejectsInvalidJSON() {
        XCTAssertThrowsError(try RouteCatalogLoader.load(data: Data("not json".utf8))) {
            XCTAssertEqual($0 as? RouteCatalogIssue, .malformed)
        }
    }
}
