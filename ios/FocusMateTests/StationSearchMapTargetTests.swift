import XCTest
@testable import FocusMate

final class StationSearchMapTargetTests: XCTestCase {
    func testSwitchingBetweenSameNameStopsUsesEachSelectedCoordinate() throws {
        let a = RouteCatalogFixture.stop("a", "시장", 1)
        let b = RouteCatalogFixture.stop("b", "시장", 2)
        let stops = [a, b]
        let route = RouteCatalogFixture.route("route", stops: [a.id, b.id], in: stops)
        let catalog = try RouteCatalogFixture.make(stops: stops, routes: [route])

        var search = StationSearchState()
        search.query = "시장"
        let results = search.result(in: catalog)
        XCTAssertTrue(search.select(a.id, from: results))
        let first = try XCTUnwrap(StationSearchMapTarget(stationID: search.selectedOption(from: results)?.id, catalog: catalog))
        XCTAssertTrue(search.select(b.id, from: results))
        let second = try XCTUnwrap(StationSearchMapTarget(stationID: search.selectedOption(from: results)?.id, catalog: catalog))
        XCTAssertEqual(first.point, a.point)
        XCTAssertEqual(second.point, b.point)
        XCTAssertNotEqual(first, second)

        search.query = "다른 정류장"
        XCTAssertNil(StationSearchMapTarget(stationID: search.selectedID, catalog: catalog))
    }

    func testMissingSelectionOrCatalogProducesNoMapTarget() throws {
        let catalog = try RouteCatalogFixture.acceptance()
        XCTAssertNil(StationSearchMapTarget(stationID: nil, catalog: catalog))
        XCTAssertNil(StationSearchMapTarget(stationID: "missing", catalog: catalog))
        XCTAssertNil(StationSearchMapTarget(stationID: "a", catalog: nil))
    }

    func testMapUsesOnlyTheUncoveredHeightAndDisappearsWhenTooShort() {
        XCTAssertEqual(StationSearchMapTarget.visibleHeight(viewHeight: 760, bottomInset: 320), 440)
        XCTAssertEqual(StationSearchMapTarget.visibleHeight(viewHeight: 760, bottomInset: 540), 220)
        XCTAssertEqual(StationSearchMapTarget.visibleHeight(viewHeight: 760, bottomInset: -20), 760)
        XCTAssertNil(StationSearchMapTarget.visibleHeight(viewHeight: 430, bottomInset: 350))
        XCTAssertNil(StationSearchMapTarget.visibleHeight(viewHeight: 430, bottomInset: 500))
    }
}
