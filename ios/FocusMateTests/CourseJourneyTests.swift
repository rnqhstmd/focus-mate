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

    // MARK: AC-28 / AC-32 (phase-review 보강)

    /// acceptanceFixture 노선 1111, 출발 S1, 16분: 정류장 S1,S2,S3,S4 / 구간 초 [300,240,420] / 구간 미터 [800,600,1100].
    /// 미터는 RouteLegTests의 distanceMeters(S1~S3 1400, S1~S4 2500)와 AC-28 기대값(420초 → 14)에서 역산한 값이다.
    private func acceptanceCourse() throws -> CourseJourney {
        let catalog = try RouteCatalogFixture.acceptance()
        let route = try XCTUnwrap(catalog.routeIndex(id: "1111"))
        let origin = try XCTUnwrap(catalog.stopIndex(id: "S1"))
        let leg = try XCTUnwrap(RouteLegFinder.leg(route: route, originStop: origin, minutes: 16, in: catalog))
        return CourseJourney(leg: leg, catalog: catalog)
    }

    // 깨짐: 남은 거리를 구간 비례(절반 지점 = 240초 구간의 반)로 계산하지 않거나 0.1km 반올림이 틀리면 실패한다.
    func testAC28_420초의_남은_거리는_1점4km다() throws {
        let course = try acceptanceCourse()
        XCTAssertEqual(course.cumulativeSeconds, [0, 300, 540, 960])
        XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: course, elapsedSeconds: 420), 14)
    }

    // 깨짐: 420초 위치가 구간 1의 정확한 중간(fraction 0.5)이 아니면 실패한다.
    func testAC28_420초_위치는_구간1의_중간이다() throws {
        let position = JourneyCourseProgress.position(of: try acceptanceCourse(), elapsedSeconds: 420)
        XCTAssertEqual(position.segmentFrom, 1)
        XCTAssertEqual(position.segmentTo, 2)
        XCTAssertEqual(position.fraction, 0.5, accuracy: 1e-9)
        XCTAssertFalse(position.isArrived)
    }

    // 깨짐: 경계(0·300·540·960초)에서 구간 선택 또는 반올림이 틀리면 해당 경계에서 실패한다.
    func testAC28_경계_경과의_남은_거리() throws {
        let course = try acceptanceCourse()
        let cases: [(elapsed: Int, tenths: Int)] = [(0, 25), (300, 17), (540, 11), (960, 0)]
        for c in cases {
            XCTAssertEqual(
                JourneyCourseProgress.remainingDistanceTenthsKm(of: course, elapsedSeconds: c.elapsed), c.tenths,
                "elapsed \(c.elapsed)"
            )
        }
    }

    // 깨짐: BR-11 범위(33~39 / 124~130) 안의 서울 밖 좌표를 코스에서 걸러 내거나 코스를 nil로 만들면 실패한다.
    func testAC32_서울_밖_좌표_정류장도_코스에_포함된다() throws {
        let outside = CoursePoint(latitude: 37.70, longitude: 126.70)
        let stops = [
            RouteCatalogFixture.stop("A", "에이", 1),
            RouteCatalog.Stop(id: "OUT", name: "서울밖", ars: nil, point: outside),
            RouteCatalogFixture.stop("C", "씨", 3),
        ]
        let route = RouteCatalogFixture.route("r-1", number: "1", stops: ["A", "OUT", "C"], in: stops, seconds: [600, 900, 60], meters: [1000, 2000, 100])
        let catalog = try RouteCatalog(stops: stops, routes: [route], metadata: RouteCatalog.fixtureMetadata)
        let journey = F.journey(
            minutes: 25, busID: "r-1", busNumber: "1", destinationStopID: "C", destinationName: "씨"
        )

        let course = try XCTUnwrap(CourseJourney(journey: journey, catalog: catalog))

        XCTAssertEqual(course.stops.map(\.id), ["A", "OUT", "C"])
        let point = try XCTUnwrap(course.stops.first { $0.id == "OUT" }?.point)
        XCTAssertEqual(point.latitude, 37.70, accuracy: 1e-9)
        XCTAssertEqual(point.longitude, 126.70, accuracy: 1e-9)
    }
}
