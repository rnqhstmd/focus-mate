import Foundation
import XCTest
@testable import FocusMate

/// 경과 시간 -> 코스 위치·남은 수치 (AC-6~9, AC-39 계산). uiTestFixture의 2014(구간 300초)를 성수역에서 25분 탄다.
/// 코스 위치 0...5 = seongsu, seongsuDong, ttukseom, seongdongSportsCenter, seoulForest, seoulForestGate.
/// 이 파일은 uiTestFixture 2014 코스의 위치·남은 정류장/거리를 다룬다. 구간이 불균등한 경우의 거리 반올림(AC-28)은 CourseJourneyTests가 acceptanceFixture 1111로 다룬다. 방위 규칙은 이 파일에서 검증하지 않는다.
final class JourneyCourseProgressTests: XCTestCase {
    private let accuracy = 1e-9

    private func course(minutes: Int = 25) throws -> CourseJourney {
        let catalog = BoardingFixtures.uiCatalog()
        let route = try XCTUnwrap(catalog.routeIndex(id: "2014"))
        let origin = try XCTUnwrap(catalog.stopIndex(id: "seongsu"))
        let leg = try XCTUnwrap(RouteLegFinder.leg(route: route, originStop: origin, minutes: minutes, in: catalog))
        return CourseJourney(leg: leg, catalog: catalog)
    }

    // 깨짐: 정류장 경계에서 위치가 코스 정류장 좌표가 아니면(구간 선택 오류) 실패한다.
    func test_정류장_경계에서_위치가_정류장_좌표다() throws {
        let j = try course()
        for (elapsed, position) in [(0, 0), (300, 1), (600, 2), (1200, 4)] {
            let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: elapsed)
            XCTAssertEqual(pos.point.latitude, j.stops[position].point.latitude, accuracy: accuracy, "e \(elapsed)")
            XCTAssertEqual(pos.point.longitude, j.stops[position].point.longitude, accuracy: accuracy, "e \(elapsed)")
            XCTAssertFalse(pos.isArrived)
        }
    }

    // 깨짐: 선형 보간이 아니면(fraction/중간점 오류) 실패한다.
    func test_750초는_코스위치2와3의_정확한_중간이다() throws {
        let j = try course()
        let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: 750)
        let a = j.stops[2].point, b = j.stops[3].point
        XCTAssertEqual(pos.fraction, 0.5, accuracy: accuracy)
        XCTAssertEqual(pos.segmentFrom, 2)
        XCTAssertEqual(pos.segmentTo, 3)
        XCTAssertEqual(pos.point.latitude, (a.latitude + b.latitude) / 2, accuracy: accuracy)
        XCTAssertEqual(pos.point.longitude, (a.longitude + b.longitude) / 2, accuracy: accuracy)
    }

    // 깨짐: 총 시간에 도달해도 마지막 정류장에 고정하지 않으면 실패한다.
    func test_1500초_이후는_도착_정류장에_고정된다() throws {
        let j = try course()
        for elapsed in [1500, 1800] {
            let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: elapsed)
            XCTAssertTrue(pos.isArrived)
            XCTAssertEqual(pos.point.latitude, j.stops[5].point.latitude, accuracy: accuracy)
            XCTAssertEqual(pos.point.longitude, j.stops[5].point.longitude, accuracy: accuracy)
        }
    }

    // 깨짐: 방위가 0...360 범위를 벗어나면 실패한다.
    func test_방위는_0이상_360미만이다() throws {
        let j = try course()
        for elapsed in stride(from: 0, to: 1500, by: 150) {
            XCTAssertTrue((0..<360).contains(JourneyCourseProgress.position(of: j, elapsedSeconds: elapsed).headingDegrees))
        }
    }

    // 깨짐: 경과 0에서 남은 정류장이 총 정류장 수와 다르면 실패한다.
    func test_경과0에서는_총_정류장이_남는다() throws {
        XCTAssertEqual(JourneyCourseProgress.remainingStops(of: try course(), elapsedSeconds: 0), 5)
    }

    // 깨짐: 도착(및 그 이후)에 남은 정류장/거리가 0이 아니면 실패한다.
    func test_도착하면_남은_정류장과_거리는_0이다() throws {
        let j = try course()
        for e in [1500, 1800] {
            XCTAssertEqual(JourneyCourseProgress.remainingStops(of: j, elapsedSeconds: e), 0)
            XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: j, elapsedSeconds: e), 0)
        }
    }

    // 깨짐: 남은 정류장이 k - j 가 아니면(경계 포함 비교 오류) 실패한다.
    func test_중간_경과의_남은_정류장() throws {
        let j = try course()
        let cases: [(Int, Int)] = [(299, 5), (300, 4), (750, 3), (1000, 2), (1499, 1)]
        for c in cases {
            XCTAssertEqual(JourneyCourseProgress.remainingStops(of: j, elapsedSeconds: c.0), c.1, "e \(c.0)")
        }
    }

    // 깨짐: 다음 정류장이 min(k, j+1)이 아니거나 도착 후 마지막에 고정되지 않으면 실패한다.
    func test_다음_정류장은_구간_끝이고_도착하면_마지막이다() throws {
        let j = try course()
        XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: j, elapsedSeconds: 0), 1)
        XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: j, elapsedSeconds: 299), 1)
        XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: j, elapsedSeconds: 300), 2)
        XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: j, elapsedSeconds: 1500), 5)
        XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: j, elapsedSeconds: 1800), 5)
    }
}
