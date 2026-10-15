import Foundation
import XCTest
@testable import FocusMate

final class RouteLegTests: XCTestCase {
    private typealias F = RouteCatalogFixture

    private func leg(
        _ routeID: String, from stopID: String, minutes: Int, in catalog: RouteCatalog
    ) throws -> RouteLeg? {
        let route = try XCTUnwrap(catalog.routeIndex(id: routeID))
        let stop = try XCTUnwrap(catalog.stopIndex(id: stopID))
        return RouteLegFinder.leg(route: route, originStop: stop, minutes: minutes, in: catalog)
    }

    private func ids(_ leg: RouteLeg, in catalog: RouteCatalog) -> [String] {
        leg.stopIndices.map { catalog.stops[$0].id }
    }

    // 깨짐: 허용 오차 경계(정확히 60초)를 제외하면 실패한다.
    func testAC13_차이_60초는_후보이며_구간이_비례_조정된다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("1111", from: "S1", minutes: 10, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S2", "S3"])
        XCTAssertEqual(leg.segmentSeconds, [333, 267])
        XCTAssertEqual(leg.differenceSeconds, 60)
        XCTAssertEqual(leg.distanceMeters, 1400)
    }

    // 깨짐: 노선별 구간 대신 다른 노선 데이터를 쓰면 실패한다.
    func testAC13_다른_노선도_같은_규칙으로_도착지를_찾는다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("2222", from: "S1", minutes: 10, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S3"])
        XCTAssertEqual(leg.segmentSeconds, [600])
        XCTAssertEqual(leg.differenceSeconds, 60)
    }

    // 깨짐: 정확히 맞는 지점에서 비례 조정을 하면 구간이 바뀌어 실패한다.
    func testAC14_정확히_맞으면_원래_구간_그대로다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("1111", from: "S1", minutes: 9, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S2", "S3"])
        XCTAssertEqual(leg.segmentSeconds, [300, 240])
        XCTAssertEqual(leg.differenceSeconds, 0)
    }

    // 깨짐: 허용 오차를 넘는 후보(차이 120)를 받아들이면 실패한다.
    func testAC14_허용_오차를_넘으면_nil이다() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("2222", from: "S1", minutes: 9, in: catalog))
    }

    // 깨짐: 더 가까운 후보 대신 첫 후보를 고르면 S3(1일 때 차이 있음)로 끝나 실패한다.
    func testAC15_더_가까운_먼_지점을_고른다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("1111", from: "S1", minutes: 16, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S2", "S3", "S4"])
        XCTAssertEqual(leg.segmentSeconds, [300, 240, 420])
        XCTAssertEqual(leg.differenceSeconds, 0)
        XCTAssertEqual(leg.distanceMeters, 2500)
    }

    // 깨짐: 가장 가까운 후보가 300초 차이인데도 반환하면 실패한다.
    func testAC15_모든_지점이_허용_밖이면_nil이다() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("2222", from: "S1", minutes: 16, in: catalog))
    }

    // 깨짐: 반올림 규칙이나 마지막 구간 = 나머지 규칙이 틀리면 실패한다.
    func testAC16_비례_조정은_앞은_반올림_마지막은_나머지다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("1111", from: "S1", minutes: 17, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S2", "S3", "S4"])
        XCTAssertEqual(leg.segmentSeconds, [319, 255, 446])
        XCTAssertEqual(leg.cumulativeSeconds, [0, 319, 574, 1020])
        XCTAssertEqual(leg.differenceSeconds, 60)
    }

    // 깨짐: 출발 정류장을 도착지로 허용하면 X 900초가 선택되어 실패한다.
    func testAC18_출발_정류장은_도착지에서_제외된다() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("3333", from: "S6", minutes: 15, in: catalog))
    }

    // 깨짐: 출발 정류장을 지나가지 못하게 하거나 한 바퀴만 보면 실패한다.
    func testAC19_순환_노선은_출발지를_지나_여러_정류장을_이어간다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("3333", from: "S6", minutes: 25, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S6", "S7", "S8", "S6", "S7", "S8"])
        XCTAssertEqual(leg.segmentSeconds, [300, 300, 300, 300, 300])
        XCTAssertEqual(leg.differenceSeconds, 0)
    }

    // 깨짐: 회차 후 처음으로 돌아가지 않으면 7개 정류장이 나오지 않아 실패한다.
    func testAC20_회차하며_노선을_넘어_두_바퀴째까지_걷는다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("1111", from: "S1", minutes: 30, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["S1", "S2", "S3", "S4", "S5", "S1", "S2"])
        XCTAssertEqual(leg.segmentSeconds, [310, 248, 434, 372, 124, 312])
        XCTAssertEqual(leg.segmentSeconds.reduce(0, +), 1800)
        XCTAssertEqual(leg.differenceSeconds, 60)
    }

    // 깨짐: 2바퀴 후보(차이 180)나 S5(차이 540)를 허용하면 실패한다.
    func testAC20_두_바퀴째도_허용_밖이면_nil이다() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("2222", from: "S1", minutes: 30, in: catalog))
    }

    // 깨짐: 동률에서 늦은 지점을 고르면 P3가 되어 실패한다.
    func testAC21_차이가_같으면_이른_지점을_고른다() throws {
        let catalog = try F.acceptance()
        let leg = try XCTUnwrap(try leg("7777", from: "P1", minutes: 6, in: catalog))
        XCTAssertEqual(ids(leg, in: catalog), ["P1", "P2"])
        XCTAssertEqual(leg.segmentSeconds, [360])
        XCTAssertEqual(leg.differenceSeconds, 60)
    }

    // 깨짐: 경계를 61초까지 넓히면 B가 선택되어 실패한다.
    func testDifference61SecondsIsExcluded() throws {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2)]
        let catalog = try F.make(
            stops: stops, routes: [F.route("9", stops: ["A", "B"], in: stops, seconds: [301, 60])]
        )
        XCTAssertNil(try leg("9", from: "A", minutes: 4, in: catalog))
    }

    // 깨짐: 노선에 없는 출발 정류장에서 값을 만들거나 크래시하면 실패한다.
    func testOriginStopNotOnRouteIsNil() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("1111", from: "S1b", minutes: 10, in: catalog))
    }

    // 깨짐: 마지막 구간 0초를 그대로 반환하면 실패한다.
    // 손계산: 노선 [A,B,A,C] 초 [59,119,1,1000], 2분(120초).
    // B 59 차이 61 밖, A 178 출발지 제외, C 179 차이 59 후보. 비례(120/179):
    // round(59*120/179 = 39.55) = 40, round(119*120/179 = 79.78) = 80, 마지막 = 120 - 120 = 0 -> nil.
    func testLastSegmentUnderOneSecondIsNil() throws {
        let stops = [F.stop("A", "에이", 1), F.stop("B", "비", 2), F.stop("C", "씨", 3)]
        let catalog = try F.make(
            stops: stops,
            routes: [F.route("9", stops: ["A", "B", "A", "C"], in: stops, seconds: [59, 119, 1, 1000])]
        )
        XCTAssertNil(try leg("9", from: "A", minutes: 2, in: catalog))
    }

    // 깨짐: 분 범위 검사를 빼면 0분·361분에서 값이 나와 실패한다.
    func testMinutesOutsideOneTo360IsNil() throws {
        let catalog = try F.acceptance()
        XCTAssertNil(try leg("1111", from: "S1", minutes: 0, in: catalog))
        XCTAssertNil(try leg("1111", from: "S1", minutes: 361, in: catalog))
    }
}
