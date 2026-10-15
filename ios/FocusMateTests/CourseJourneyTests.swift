import Foundation
import XCTest
@testable import FocusMate

/// 카탈로그 노선 위의 가상 코스. r-100 A→B→C→D, 25분 정확 일치: 초 [600,540,360], 미터 [500,600,700].
final class CourseJourneyTests: XCTestCase {
    private typealias F = W16bFixtures

    private func leg(minutes: Int = 25, in catalog: RouteCatalog) throws -> RouteLeg {
        let route = try XCTUnwrap(catalog.routeIndex(id: "r-100"))
        let stop = try XCTUnwrap(catalog.stopIndex(id: "A"))
        return try XCTUnwrap(RouteLegFinder.leg(route: route, originStop: stop, minutes: minutes, in: catalog))
    }

    // 깨짐: stops가 카탈로그 정류장 id·이름·코스 위치(index)와 다르면 실패한다.
    func testStopsCarryCatalogIdentityAndCoursePosition() throws {
        let catalog = try F.single()
        let course = CourseJourney(leg: try leg(in: catalog), catalog: catalog)
        XCTAssertEqual(course.stops.map(\.id), ["A", "B", "C", "D"])
        XCTAssertEqual(course.stops.map(\.name), ["에이", "비", "씨", "디"])
        XCTAssertEqual(course.stops.map(\.index), [0, 1, 2, 3])
    }

    // 깨짐: 좌표를 카탈로그 정류장 좌표 대신 다른 값으로 채우면 실패한다.
    func testStopPointsAreCatalogCoordinates() throws {
        let catalog = try F.single()
        let course = CourseJourney(leg: try leg(in: catalog), catalog: catalog)
        for (position, stop) in course.stops.enumerated() {
            let source = catalog.stops[try XCTUnwrap(catalog.stopIndex(id: stop.id))].point
            XCTAssertEqual(stop.point.latitude, source.latitude, accuracy: 1e-9, "position \(position)")
            XCTAssertEqual(stop.point.longitude, source.longitude, accuracy: 1e-9, "position \(position)")
        }
    }

    // 깨짐: 구간 초·미터·누적(0 포함 k+1개)·총 시간 계산이 틀리면 실패한다.
    func testSegmentsAndCumulativeSeconds() throws {
        let catalog = try F.single()
        let course = CourseJourney(leg: try leg(in: catalog), catalog: catalog)
        XCTAssertEqual(course.segmentSeconds, [600, 540, 360])
        XCTAssertEqual(course.segmentMeters, [500, 600, 700])
        XCTAssertEqual(course.cumulativeSeconds, [0, 600, 1140, 1500])
        XCTAssertEqual(course.totalSeconds, 1500)
    }

    // 깨짐: 비례 조정된 leg의 구간 초 대신 노선 원본 초를 쓰면 실패한다. (24분 = 1440초: D 1500초와 차이 60초라 비례 조정된 구간을 쓴다)
    func testSegmentSecondsFollowAdjustedLeg() throws {
        let catalog = try F.single()
        let adjusted = try leg(minutes: 24, in: catalog)
        let course = CourseJourney(leg: adjusted, catalog: catalog)
        XCTAssertEqual(course.segmentSeconds, adjusted.segmentSeconds)
        XCTAssertEqual(course.totalSeconds, adjusted.segmentSeconds.reduce(0, +))
    }

    // 깨짐: 저장 여정에서 코스를 못 만들거나 leg 기반 코스와 다르면 실패한다.
    func testInitFromJourneyMatchesLegCourse() throws {
        let catalog = try F.single()
        let fromJourney = try XCTUnwrap(CourseJourney(journey: F.journey(), catalog: catalog))
        XCTAssertEqual(fromJourney, CourseJourney(leg: try leg(in: catalog), catalog: catalog))
    }

    // 깨짐: 노선이 카탈로그에 없는데 코스를 만들면 실패한다.
    func testInitFromJourneyIsNilWhenRouteMissing() throws {
        XCTAssertNil(CourseJourney(journey: F.journey(busID: "gone"), catalog: try F.single()))
        XCTAssertNil(CourseJourney(journey: F.journey(), catalog: try F.withoutRoute100()))
    }

    // 깨짐: 출발 정류장이 없는데 코스를 만들면 실패한다.
    func testInitFromJourneyIsNilWhenOriginMissing() throws {
        XCTAssertNil(CourseJourney(journey: F.journey(originStopID: "ZZ"), catalog: try F.single()))
        XCTAssertNil(CourseJourney(journey: F.journey(), catalog: try F.withoutStopA()))
    }

    // 깨짐: 분에 맞는 leg가 없는데 코스를 만들면 실패한다.
    func testInitFromJourneyIsNilWhenNoLeg() throws {
        XCTAssertNil(CourseJourney(journey: F.journey(minutes: 3), catalog: try F.single()))
    }

    // 깨짐: 재계산 도착 id와 저장 도착 id가 달라도 코스를 만들면 실패한다 (BR-12).
    func testInitFromJourneyIsNilWhenRecomputedDestinationDiffers() throws {
        XCTAssertNil(CourseJourney(journey: F.journey(destinationStopID: "C"), catalog: try F.single()))
    }
}
