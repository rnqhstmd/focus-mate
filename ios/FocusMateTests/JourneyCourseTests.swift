import Foundation
import XCTest
@testable import FocusMate

/// 가상 코스 정류장 좌표 (AC-5). 좌표 값 자체는 하드코딩하지 않고 성질만 검증한다.
final class JourneyCourseTests: XCTestCase {
    // 깨짐: 정류장 수가 9개가 아니거나 RouteStops.all의 순서·id와 달라지면 실패한다.
    func test1_AC5_정류장은_9개이고_순서와_id가_RouteStops와_같다() {
        XCTAssertEqual(JourneyCourse.stops.count, 9)
        XCTAssertEqual(JourneyCourse.stops.map(\.id), RouteStops.all.map(\.id))
        XCTAssertEqual(JourneyCourse.stops.map(\.index), Array(0..<9))
        XCTAssertEqual(JourneyCourse.stops.map(\.name), RouteStops.all.map(\.name))
    }

    // 깨짐: 두 정류장이 같은 좌표를 가지면 실패한다.
    func test2_AC5_정류장_좌표는_서로_모두_다르다() {
        let points = JourneyCourse.stops.map(\.point)
        XCTAssertEqual(Set(points).count, 9)
    }

    // 깨짐: 한 정류장이라도 서울 경계 상자(37.41~37.72, 126.76~127.19) 밖이면 실패한다.
    func test3_AC5_모든_좌표는_서울_경계_상자_안이다() {
        for stop in JourneyCourse.stops {
            XCTAssertTrue((37.41...37.72).contains(stop.point.latitude), stop.id)
            XCTAssertTrue((126.76...127.19).contains(stop.point.longitude), stop.id)
        }
    }

    // 깨짐: 닫힌 경로가 10점이 아니거나 마지막 점이 첫 점이 아니면 실패한다.
    func test4_AC5_닫힌_경로는_10점이고_마지막이_첫_점이다() {
        let path = JourneyCourse.closedPath
        XCTAssertEqual(path.count, 10)
        XCTAssertEqual(path.last, path.first)
        XCTAssertEqual(Array(path.prefix(9)), JourneyCourse.stops.map(\.point))
    }

    // 깨짐: point(at:)가 9 순환(wrap)을 적용하지 않으면 실패한다.
    func test5_AC5_point_at은_인덱스를_9로_순환한다() {
        XCTAssertEqual(JourneyCourse.point(at: 9), JourneyCourse.stops[0].point)
        XCTAssertEqual(JourneyCourse.point(at: -1), JourneyCourse.stops[8].point)
        XCTAssertEqual(JourneyCourse.point(at: 4), JourneyCourse.stops[4].point)
    }
}
