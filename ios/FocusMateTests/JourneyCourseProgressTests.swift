import Foundation
import XCTest
@testable import FocusMate

/// 경과 시간 -> 가상 코스 위치·남은 수치 (AC-6~9, AC-39 계산). 좌표는 JourneyCourse와 비교한다.
final class JourneyCourseProgressTests: XCTestCase {
    private let accuracy = 1e-9

    private func wrap(_ i: Int) -> Int { ((i % 9) + 9) % 9 }

    private func journey(_ origin: Int, _ dir: Int, per: Int = 5, total: Int = 25) -> CourseJourney {
        CourseJourney(originIndex: origin, direction: dir, minutesPerStop: per, totalMinutes: total)
    }

    private func assertPoint(_ p: CoursePoint, equals q: CoursePoint, _ msg: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(p.latitude, q.latitude, accuracy: accuracy, msg, file: file, line: line)
        XCTAssertEqual(p.longitude, q.longitude, accuracy: accuracy, msg, file: file, line: line)
    }

    // 깨짐: 정방향 보간이 구간 인덱스를 잘못 고르면(k 계산 오류) 실패한다.
    func test1_AC6_정방향_정류장_경계에서_위치가_정류장_좌표다() {
        for i in 0..<9 {
            let j = journey(i, 1)
            for (elapsed, step) in [(0, 0), (300, 1), (600, 2)] {
                let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: elapsed)
                assertPoint(pos.point, equals: JourneyCourse.point(at: i + step), "origin \(i) e \(elapsed)")
                XCTAssertFalse(pos.isArrived, "origin \(i) e \(elapsed)")
            }
        }
    }

    // 깨짐: 선형 보간이 아니면(fraction/중간점 오류) 실패한다.
    func test2_AC6_정방향_750초는_i2와_i3의_정확한_중간이다() {
        for i in 0..<9 {
            let pos = JourneyCourseProgress.position(of: journey(i, 1), elapsedSeconds: 750)
            let a = JourneyCourse.point(at: i + 2), b = JourneyCourse.point(at: i + 3)
            XCTAssertEqual(pos.fraction, 0.5, accuracy: accuracy)
            XCTAssertEqual(pos.segmentFrom, wrap(i + 2))
            XCTAssertEqual(pos.segmentTo, wrap(i + 3))
            XCTAssertEqual(pos.point.latitude, (a.latitude + b.latitude) / 2, accuracy: accuracy)
            XCTAssertEqual(pos.point.longitude, (a.longitude + b.longitude) / 2, accuracy: accuracy)
            XCTAssertFalse(pos.isArrived)
        }
    }

    // 깨짐: 총 시간에 도달해도 도착 정류장(i+5)에 고정하지 않으면 실패한다.
    func test3_AC6_정방향_1500초는_도착_정류장에_도착한다() {
        for i in 0..<9 {
            let j = journey(i, 1)
            let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: 1500)
            XCTAssertTrue(pos.isArrived, "origin \(i)")
            XCTAssertEqual(j.destinationIndex, wrap(i + 5))
            assertPoint(pos.point, equals: JourneyCourse.point(at: i + 5), "origin \(i)")
        }
    }

    // 깨짐: 역방향이 정방향과 같은 쪽으로 진행하면 실패한다.
    func test4_AC7_역방향_300초는_i_minus_1이고_1500초는_i_minus_5로_순환한다() {
        for i in 0..<9 {
            let j = journey(i, -1)
            let p300 = JourneyCourseProgress.position(of: j, elapsedSeconds: 300)
            assertPoint(p300.point, equals: JourneyCourse.point(at: wrap(i - 1)), "origin \(i)")
            let p1500 = JourneyCourseProgress.position(of: j, elapsedSeconds: 1500)
            assertPoint(p1500.point, equals: JourneyCourse.point(at: wrap(i - 5)), "origin \(i)")
            XCTAssertTrue(p1500.isArrived)
            XCTAssertEqual(j.destinationIndex, wrap(i - 5))
        }
    }

    // 깨짐: 방향이 반대인 같은 구간의 heading이 180도 차이가 아니면 실패한다.
    func test5_AC7_같은_구간_반대_방향의_heading_차이는_180도다() {
        for i in 0..<9 {
            let fwd = JourneyCourseProgress.position(of: journey(i, 1), elapsedSeconds: 150)
            let rev = JourneyCourseProgress.position(of: journey(wrap(i + 1), -1), elapsedSeconds: 150)
            var diff = (fwd.headingDegrees - rev.headingDegrees).truncatingRemainder(dividingBy: 360)
            if diff < 0 { diff += 360 }
            XCTAssertEqual(diff, 180, accuracy: accuracy, "origin \(i)")
            XCTAssertTrue((0..<360).contains(fwd.headingDegrees))
            XCTAssertTrue((0..<360).contains(rev.headingDegrees))
        }
    }

    // 깨짐: 360분 여정에서 9정류장 순환(wrap) 또는 도착 고정이 틀리면 실패한다.
    func test6_AC8_360분_2014_한_바퀴_후_출발_정류장으로_돌아오고_도착_고정된다() {
        for dir in [1, -1] {
            for i in 0..<9 {
                let j = journey(i, dir, per: 5, total: 360)
                XCTAssertEqual(j.totalStops, 72)
                let lap = JourneyCourseProgress.position(of: j, elapsedSeconds: 2700)
                assertPoint(lap.point, equals: JourneyCourse.point(at: i), "dir \(dir) origin \(i) lap")
                XCTAssertFalse(lap.isArrived)
                let end = JourneyCourseProgress.position(of: j, elapsedSeconds: 21600)
                XCTAssertTrue(end.isArrived)
                assertPoint(end.point, equals: JourneyCourse.point(at: j.destinationIndex), "dir \(dir) origin \(i) end")
                let after = JourneyCourseProgress.position(of: j, elapsedSeconds: 30000)
                XCTAssertTrue(after.isArrived)
                assertPoint(after.point, equals: end.point)
            }
        }
    }

    private func sweep(per: Int, total: Int, file: StaticString = #filePath, line: UInt = #line) {
        let closed = JourneyCourse.closedPath
        var maxSegment = 0.0
        for n in 1..<closed.count {
            maxSegment = max(maxSegment, hypot(closed[n].latitude - closed[n - 1].latitude,
                                               closed[n].longitude - closed[n - 1].longitude))
        }
        let sps = per * 60
        let stopPoints = JourneyCourse.stops.map(\.point)
        for (origin, dir) in [(0, 1), (3, -1), (8, 1), (5, -1)] {
            let j = journey(origin, dir, per: per, total: total)
            var prev = JourneyCourseProgress.position(of: j, elapsedSeconds: 0).point
            for e in 0...(total * 60) {
                let pos = JourneyCourseProgress.position(of: j, elapsedSeconds: e)
                let step = hypot(pos.point.latitude - prev.latitude, pos.point.longitude - prev.longitude)
                XCTAssertLessThanOrEqual(step, maxSegment + 1e-12, "per \(per) o \(origin) d \(dir) e \(e)", file: file, line: line)
                let atStop = stopPoints.contains {
                    hypot($0.latitude - pos.point.latitude, $0.longitude - pos.point.longitude) < 1e-12
                }
                XCTAssertEqual(atStop, e % sps == 0, "per \(per) o \(origin) d \(dir) e \(e)", file: file, line: line)
                prev = pos.point
            }
        }
    }

    // 깨짐: 5분 버스에서 위치가 점프하거나 정류장 사이에서 정류장 좌표에 멈추면 실패한다.
    func test7_AC9_5분_버스_전_구간_1초_스윕은_연속이고_정류장_좌표는_경계에서만() {
        sweep(per: 5, total: 25)
    }

    // 깨짐: 6분 버스에서 위치가 점프하거나 정류장 사이에서 정류장 좌표에 멈추면 실패한다.
    func test8_AC9_6분_버스_전_구간_1초_스윕은_연속이고_정류장_좌표는_경계에서만() {
        sweep(per: 6, total: 30)
    }

    // 깨짐: 8분 버스에서 위치가 점프하거나 정류장 사이에서 정류장 좌표에 멈추면 실패한다.
    func test9_AC9_8분_버스_전_구간_1초_스윕은_연속이고_정류장_좌표는_경계에서만() {
        sweep(per: 8, total: 40)
    }

    // 깨짐: 경과 0에서 남은 정류장/거리가 총량과 다르면 실패한다. (5 x 0.55 = 2.75 -> half-up 2.8)
    func test10_AC39_경과_0에서는_총_정류장과_총거리가_남는다() {
        let j = journey(2, 1)
        XCTAssertEqual(JourneyCourseProgress.remainingStops(of: j, elapsedSeconds: 0), 5)
        XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: j, elapsedSeconds: 0), 28)
        let long = journey(2, 1, per: 5, total: 360) // 72 x 0.55 = 39.6km
        XCTAssertEqual(JourneyCourseProgress.remainingStops(of: long, elapsedSeconds: 0), 72)
        XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: long, elapsedSeconds: 0), 396)
    }

    // 깨짐: 도착(및 그 이후)에 남은 정류장/거리가 0이 아니면 실패한다.
    func test11_AC39_도착하면_남은_정류장과_거리는_0이다() {
        let j = journey(2, 1)
        for e in [1500, 1800] {
            XCTAssertEqual(JourneyCourseProgress.remainingStops(of: j, elapsedSeconds: e), 0)
            XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: j, elapsedSeconds: e), 0)
        }
    }

    // 깨짐: 남은 거리의 반올림/비율 공식이 틀리면 실패한다. 손 계산: 2.75 x (1500-e)/1500.
    func test12_AC39_중간_경과의_남은_정류장과_거리() {
        let j = journey(2, 1)
        // (경과초, 남은 정류장, 남은 거리 0.1km) 90: 2.585->26, 300: 2.2->22, 750: 1.375->14, 1000: 0.9167->9, 1499: 0.0018->0
        let cases: [(Int, Int, Int)] = [(90, 5, 26), (299, 5, 22), (300, 4, 22), (750, 3, 14), (1000, 2, 9), (1499, 1, 0)]
        for c in cases {
            XCTAssertEqual(JourneyCourseProgress.remainingStops(of: j, elapsedSeconds: c.0), c.1, "stops e \(c.0)")
            if c.0 != 299 {
                XCTAssertEqual(JourneyCourseProgress.remainingDistanceTenthsKm(of: j, elapsedSeconds: c.0), c.2, "dist e \(c.0)")
            }
        }
    }

    // 깨짐: 다음 정류장이 from이 아닌 to(k+1) 기준이 아니거나 도착 후 목적지에 고정되지 않으면 실패한다.
    func test13_AC39_다음_정류장은_구간_끝이고_도착하면_도착_정류장이다() {
        for i in 0..<9 {
            let fwd = journey(i, 1)
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: fwd, elapsedSeconds: 0), wrap(i + 1))
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: fwd, elapsedSeconds: 299), wrap(i + 1))
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: fwd, elapsedSeconds: 300), wrap(i + 2))
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: fwd, elapsedSeconds: 1500), wrap(i + 5))
            let rev = journey(i, -1)
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: rev, elapsedSeconds: 0), wrap(i - 1))
            XCTAssertEqual(JourneyCourseProgress.nextStopIndex(of: rev, elapsedSeconds: 1800), wrap(i - 5))
        }
    }
}
