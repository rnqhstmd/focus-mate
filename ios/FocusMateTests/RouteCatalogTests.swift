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
    "source":{"baseDate":"2026-09-02","copyright":"서울특별시","dataset":"서울시버스노선별정류소정보","datasetID":"OA-1095","license":"공공누리 제1유형","provider":"서울 열린데이터광장","routeInfoDataset":"서울시버스노선기본정보","routeInfoDatasetID":"OA-15066","routeInfoFile":"r.csv","routeInfoSourceURL":"https://example.test/r","sourceURL":"https://example.test/s","stopsFile":"s.csv"}
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

    // MARK: 검증 (W16b)

    private func assertIssue(
        _ expected: RouteCatalogIssue, stops: [RouteCatalog.Stop], routes: [RouteCatalog.Route],
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertThrowsError(try F.make(stops: stops, routes: routes), file: file, line: line) {
            XCTAssertEqual($0 as? RouteCatalogIssue, expected, file: file, line: line)
        }
    }

    // 깨짐: 정류장 id 중복 검사를 빼면 throw하지 않아 실패한다.
    func testDuplicateStopIDIsRejected() {
        let stops = [F.stop("A", "에이", 1), F.stop("A", "에이2", 2), F.stop("B", "비", 3)]
        assertIssue(.duplicateID("A"), stops: stops, routes: [F.route("1", stops: ["B", "B"], in: stops)])
    }

    // 깨짐: 노선 id 중복 검사를 빼면 실패한다.
    func testDuplicateRouteIDIsRejected() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let routes = [F.route("1", stops: ["A", "B"], in: stops), F.route("1", number: "2", stops: ["A", "B"], in: stops)]
        assertIssue(.duplicateID("1"), stops: stops, routes: routes)
    }

    // 깨짐: 상한 비교를 >= 로 쓰거나 검사를 빼면 실패한다.
    func testSegmentSeconds21601IsOutOfRange() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        assertIssue(.outOfRange("1"), stops: stops, routes: [F.route("1", stops: ["A", "B"], in: stops, seconds: [21_601, 60])])
    }

    func testSegmentSeconds21600IsAllowed() throws {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        XCTAssertNoThrow(try F.make(stops: stops, routes: [F.route("1", stops: ["A", "B"], in: stops, seconds: [21_600, 60])]))
    }

    func testNegativeSegmentMetersIsOutOfRange() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        assertIssue(.outOfRange("1"), stops: stops, routes: [F.route("1", stops: ["A", "B"], in: stops, meters: [-1, 500])])
    }

    func testSegmentMeters200001IsOutOfRange() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        assertIssue(.outOfRange("1"), stops: stops, routes: [F.route("1", stops: ["A", "B"], in: stops, meters: [200_001, 500])])
    }

    func testRouteWith1001StopsIsOutOfRange() {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let ids = (0..<1_001).map { $0 % 2 == 0 ? "A" : "B" }
        assertIssue(.outOfRange("1"), stops: stops, routes: [F.route("1", stops: ids, in: stops)])
    }

    // MARK: 로더 검증 (W16b)

    private func loaderJSON(
        stop1: String = "[\"N1\",\"시작\",\"\",37500000,127000000]", sourceExtra: String? = nil
    ) -> Data {
        var source = Self.source
        if let sourceExtra { source = sourceExtra }
        return Data("""
        {"format":1,\(source),"stops":[\(stop1),["N2","끝","12345",37510000,127010000]],"routes":[["R1","100","지선",["N1","N2"],[60,120],[500,700]]]}
        """.utf8)
    }

    private func assertLoadIssue(_ expected: RouteCatalogIssue, _ data: Data, line: UInt = #line) {
        XCTAssertThrowsError(try RouteCatalogLoader.load(data: data), line: line) {
            XCTAssertEqual($0 as? RouteCatalogIssue, expected, line: line)
        }
    }

    // 깨짐: 위도 범위 검사를 빼면 실패한다.
    func testLoaderRejectsLatitudeOutOfKoreaRange() {
        assertLoadIssue(.outOfRange("N1"), loaderJSON(stop1: "[\"N1\",\"시작\",\"\",40000000,127000000]"))
    }

    func testLoaderRejectsLongitudeOutOfKoreaRange() {
        assertLoadIssue(.outOfRange("N1"), loaderJSON(stop1: "[\"N1\",\"시작\",\"\",37500000,123999999]"))
    }

    // 깨짐: JSON true를 숫자 1로 받아들이면 실패한다.
    func testLoaderRejectsBooleanInNumericSlot() {
        assertLoadIssue(.malformed, loaderJSON(stop1: "[\"N1\",\"시작\",\"\",true,127000000]"))
    }

    func testLoaderRejectsMissingSourceURL() {
        let source = """
        "source":{"baseDate":"2026-09-02","copyright":"서울특별시","dataset":"d","datasetID":"OA-1095","license":"l","provider":"p","routeInfoDataset":"r","routeInfoDatasetID":"OA-15066","routeInfoFile":"r.csv","routeInfoSourceURL":"https://example.test/r","stopsFile":"s.csv"}
        """
        assertLoadIssue(.malformed, loaderJSON(sourceExtra: source))
    }

    func testLoaderRejectsMissingRouteInfoSourceURL() {
        let source = """
        "source":{"baseDate":"2026-09-02","copyright":"서울특별시","dataset":"d","datasetID":"OA-1095","license":"l","provider":"p","routeInfoDataset":"r","routeInfoDatasetID":"OA-15066","routeInfoFile":"r.csv","sourceURL":"https://example.test/s","stopsFile":"s.csv"}
        """
        assertLoadIssue(.malformed, loaderJSON(sourceExtra: source))
    }

    // 깨짐: URL 필드를 다른 키에서 읽거나 서로 바꾸면 실패한다.
    func testLoaderReadsSourceURLs() throws {
        let catalog = try RouteCatalogLoader.load(data: loaderJSON())
        XCTAssertEqual(catalog.metadata.sourceURL, "https://example.test/s")
        XCTAssertEqual(catalog.metadata.routeInfoSourceURL, "https://example.test/r")
    }

    // 깨짐: 번들 조회가 없거나 다른 파일명을 찾으면 nil이어서 실패한다.
    func testBundledURLFindsRouteDataInAppBundle() throws {
        let url = try XCTUnwrap(RouteCatalogLoader.bundledURL())
        XCTAssertTrue(url.isFileURL)
        XCTAssertEqual(url.lastPathComponent, "seoul-route-data.json")
    }

    // MARK: uiTestFixture (W16b)

    private func candidateSummary(minutes: Int) throws -> [RouteCandidate] {
        let catalog = try RouteCatalog.uiTestFixture()
        let origin = try XCTUnwrap(catalog.stopIndex(id: "seongsu"))
        return RouteCandidates.candidates(minutes: minutes, originStop: origin, in: catalog)
    }

    // 깨짐: 구간 초를 바꾸면 17분에 후보가 생겨 실패한다.
    func testUITestFixture_17분은_후보가_없다() throws {
        XCTAssertEqual(try candidateSummary(minutes: 17).map(\.id), [])
    }

    func testUITestFixture_25분은_2014_서울숲_입구다() throws {
        let result = try candidateSummary(minutes: 25)
        XCTAssertEqual(result.map(\.id), ["2014"])
        XCTAssertEqual(result.first?.destination, "서울숲 입구")
        XCTAssertEqual(result.first?.stops, 5)
    }

    func testUITestFixture_60분은_2014와_302다() throws {
        let result = try candidateSummary(minutes: 60)
        XCTAssertEqual(result.map(\.id), ["2014", "302"])
        XCTAssertEqual(result[0].destination, "성동구민체육센터")
        XCTAssertEqual(result[0].stops, 12)
        XCTAssertEqual(result[1].stops, 8)
    }

    func testUITestFixture_120분은_세_노선이며_차이_순이다() throws {
        let result = try candidateSummary(minutes: 120)
        XCTAssertEqual(result.map(\.id), ["2014", "302", "421"])
    }

    // 깨짐: 정/역방향 id 접미나 방면 계산이 달라지면 실패한다.
    func testUITestFixture_방면_라벨() throws {
        let catalog = try RouteCatalog.uiTestFixture()
        let fwd = try XCTUnwrap(catalog.stopIndex(id: "seongsu"))
        let rev = try XCTUnwrap(catalog.stopIndex(id: "seongsu-r"))
        XCTAssertEqual(catalog.boundLabel(stopIndex: fwd), "성수동 방면")
        XCTAssertEqual(catalog.boundLabel(stopIndex: rev), "성수사거리 방면")
    }
}
