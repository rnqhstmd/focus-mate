import Foundation
import XCTest
@testable import FocusMate

/// 도로 맞춤 노선선: 선 위 보간·접선 방위, 구간 대체 규칙, 진행 칩 값, 저장소(가짜 길찾기).
@MainActor
final class RouteShapeTests: XCTestCase {
    private let origin = CoursePoint(latitude: 37.5, longitude: 127.0)

    /// 기준점에서 북쪽 n m, 동쪽 e m.
    private func p(north: Double, east: Double) -> CoursePoint {
        CoursePoint(latitude: origin.latitude + north / 110_540,
                    longitude: origin.longitude + east / (111_320 * cos(origin.latitude * .pi / 180)))
    }

    private func assertMeters(_ a: CoursePoint, _ b: CoursePoint, within limit: Double = 0.5,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThan(RouteShape.meters(a, b), limit, file: file, line: line)
    }

    // 깨짐: 구간 비율을 꼭짓점 수나 직선 기준으로 나누면 ㄱ자 선 위 위치가 어긋난다.
    func test01_구간_비율은_선_길이_비율로_선_위_점이_된다() {
        // 구간 0: 북 100m → 동 300m (길이 400). 구간 1: 동쪽 직선 200m.
        let shape = RouteShape(segments: [[p(north: 0, east: 0), p(north: 100, east: 0), p(north: 100, east: 300)],
                                          [p(north: 100, east: 300), p(north: 100, east: 500)]])
        XCTAssertEqual(shape.totalMeters, 600, accuracy: 0.5)
        assertMeters(shape.point(at: .init(segment: 0, fraction: 0.5)), p(north: 100, east: 100))
        assertMeters(shape.point(at: .init(segment: 0, fraction: 0.125)), p(north: 50, east: 0))
        assertMeters(shape.point(at: .init(segment: 1, fraction: 0.5)), p(north: 100, east: 400))
        assertMeters(shape.point(at: .init(segment: 2, fraction: 0)), p(north: 100, east: 500))
    }

    // 깨짐: 방위가 구간 전체 직선(정류장→정류장) 기준이거나 부호가 뒤집히면 실패한다.
    func test02_방위는_현재_위치의_선_접선이고_정류장에서는_다음_구간_도착에서는_마지막_방향이다() throws {
        let shape = RouteShape(segments: [[p(north: 0, east: 0), p(north: 100, east: 0), p(north: 100, east: 300)],
                                          [p(north: 100, east: 300), p(north: 0, east: 300)]])
        XCTAssertEqual(try XCTUnwrap(shape.heading(at: .init(segment: 0, fraction: 0.1))), 0, accuracy: 0.5)    // 북
        XCTAssertEqual(try XCTUnwrap(shape.heading(at: .init(segment: 0, fraction: 0.5))), 90, accuracy: 0.5)   // 동
        // 구간 1 시작 정류장 위: 다음 구간(남쪽) 방향.
        XCTAssertEqual(try XCTUnwrap(shape.heading(at: .init(segment: 1, fraction: 0))), 180, accuracy: 0.5)
        // 도착(끝): 뒤에서 끝으로 오는 방향(남쪽).
        XCTAssertEqual(try XCTUnwrap(shape.heading(at: .init(segment: 2, fraction: 0), backward: true)), 180, accuracy: 0.5)
        // 서쪽은 270°(0..<360).
        let west = RouteShape.straight([p(north: 0, east: 0), p(north: 0, east: -50)])
        XCTAssertEqual(try XCTUnwrap(west.heading(at: .init(segment: 0, fraction: 0.5))), 270, accuracy: 0.5)
    }

    // 깨짐: 지나온/남은 선이 버스 위치에서 끊기지 않거나 중간 꼭짓점을 빠뜨리면 실패한다.
    func test03_두_위치_사이_선은_중간_꼭짓점을_포함한다() {
        let corner = p(north: 100, east: 0)
        let shape = RouteShape(segments: [[p(north: 0, east: 0), corner, p(north: 100, east: 300)]])
        let bus = RouteShape.Location(segment: 0, fraction: 0.5)
        let travelled = shape.line(from: .init(segment: 0, fraction: 0), to: bus)
        XCTAssertEqual(travelled.count, 3)
        XCTAssertEqual(travelled[1], corner)
        XCTAssertEqual(travelled.last, shape.point(at: bus))
        let remaining = shape.line(from: bus, to: .init(segment: 1, fraction: 0))
        XCTAssertEqual(remaining, [shape.point(at: bus), p(north: 100, east: 300)])
    }

    // 깨짐: 실패·너무 먼 우회·엉뚱한 길을 그대로 쓰거나, 정상 경로의 양 끝을 정류장에 붙이지 않으면 실패한다.
    func test04_구간_대체_규칙() {
        let from = p(north: 0, east: 0), to = p(north: 0, east: 400)
        XCTAssertEqual(RouteSegmentRule.resolve(nil, from: from, to: to), [from, to])
        XCTAssertEqual(RouteSegmentRule.resolve([from], from: from, to: to), [from, to])
        // 정상: 도로 끝(도로 위로 붙인 점)이 정류장에서 몇 m 떨어져 있으면 그 끝점을 정류장 자리로 바꾼다
        // (정류장 → 도로의 직각 연결선이 남지 않게).
        let road = [p(north: 12, east: 0), p(north: 60, east: 200), p(north: 12, east: 400)]
        XCTAssertEqual(RouteSegmentRule.resolve(road, from: from, to: to), [from, road[1], to])
        // 우회: 직선 400m의 3배(1200m) 초과.
        let detour = [p(north: 0, east: 0), p(north: 700, east: 200), p(north: 0, east: 400)]
        XCTAssertEqual(RouteSegmentRule.resolve(detour, from: from, to: to), [from, to])
        // 3배 안이면 받아들인다.
        let within = [p(north: 0, east: 0), p(north: 500, east: 200), p(north: 0, east: 400)]
        XCTAssertEqual(RouteSegmentRule.resolve(within, from: from, to: to).count, 3)
        // 시작점이 정류장에서 150m 넘게 떨어진 길.
        let far = [p(north: 300, east: 0), p(north: 0, east: 400)]
        XCTAssertEqual(RouteSegmentRule.resolve(far, from: from, to: to), [from, to])
        // 아주 가까운 정류장(50m)은 300m까지 허용.
        let near = p(north: 0, east: 50)
        let uTurn = [from, p(north: 100, east: 0), p(north: 100, east: 50), near]
        XCTAssertEqual(RouteSegmentRule.resolve(uTurn, from: from, to: near), uTurn)
    }

    // 깨짐: 지난 수에 출발 정류장을 세거나 다음 정류장이 하나 밀리면 실패한다.
    func test05_진행_칩은_다음_정류장과_지난_수_전체를_준다() {
        let catalog = BoardingFixtures.uiCatalog()
        let leg = RouteLegFinder.leg(route: catalog.routeIndex(id: "2014")!, originStop: catalog.stopIndex(id: "seongsu")!,
                                     minutes: 25, in: catalog)!
        let journey = CourseJourney(leg: leg, catalog: catalog)
        let start = JourneyStopProgress(journey: journey, nextStopIndex: 1)
        XCTAssertEqual(start.passed, 0)
        XCTAssertEqual(start.total, 5)
        XCTAssertEqual(start.nextName, journey.stops[1].name)
        let middle = JourneyStopProgress(journey: journey, nextStopIndex: 3)
        XCTAssertEqual([middle.passed, middle.total], [2, 5])

        // 컨트롤러: 600초(구간 300초 × 2) = 정류장 2에 도달, 다음은 3.
        let map = JourneyMapController(journey: journey, status: .running, elapsedSeconds: 600, reduceMotion: true)
        XCTAssertEqual(map.stopProgress, middle)
    }

    // 깨짐: 도로 경로를 받아도 버스가 정류장 직선 위에 남거나, 방향이 직선 방위로 남으면 실패한다.
    func test06_컨트롤러는_받은_도로_선_위에서_버스를_놓고_접선으로_돌린다() {
        let catalog = BoardingFixtures.uiCatalog()
        let leg = RouteLegFinder.leg(route: catalog.routeIndex(id: "2014")!, originStop: catalog.stopIndex(id: "seongsu")!,
                                     minutes: 25, in: catalog)!
        let journey = CourseJourney(leg: leg, catalog: catalog)
        let map = JourneyMapController(journey: journey, status: .running, elapsedSeconds: 150, reduceMotion: true)
        // 구간 0을 a → (a의 위도, b의 경도) → b 의 ㄱ자로 바꾼다.
        let offset = journey.stopsBefore.count
        var segments = map.shape.segments
        let a = journey.stops[0].point, b = journey.stops[1].point
        let corner = CoursePoint(latitude: a.latitude, longitude: b.longitude)
        segments[offset] = [a, corner, b]
        map.apply(shape: RouteShape(segments: segments))

        let shape = RouteShape(segments: [[a, corner, b]])
        assertMeters(map.bus.point, shape.point(at: .init(segment: 0, fraction: 0.5)))
        XCTAssertEqual(map.bus.headingDegrees, shape.heading(at: .init(segment: 0, fraction: 0.5))!, accuracy: 0.5)
        XCTAssertTrue(map.travelledPoints.contains(corner) || map.remainingPoints.contains(corner))
    }

    // 깨짐: 동시 요청이 3개를 넘거나, 실패 구간을 저장해 다시 시도하지 않거나, 우회 구간을 곧은 선으로 바꾸지 않으면 실패한다.
    func test07_저장소는_동시_요청을_제한하고_실패는_곧은_선으로_남긴다() async {
        let provider = FakeRoadProvider()
        let store = RouteShapeStore(provider: provider, cacheDirectory: nil)
        let points = (0...8).map { p(north: 0, east: Double($0) * 200) }
        let requests = (0..<8).map {
            RouteSegmentRequest(routeID: "R", fromID: "\($0)", toID: "\($0 + 1)", from: points[$0], to: points[$0 + 1])
        }
        await provider.setFailing(["R|2|3"])
        await provider.setDetour(["R|4|5"])
        await store.load(requests)

        let maxConcurrent = await provider.maxConcurrent
        XCTAssertLessThanOrEqual(maxConcurrent, RouteShapeStore.maximumConcurrentRequests)
        let segments = store.segments(for: requests)
        XCTAssertEqual(segments[0].count, 3)                      // 도로 경로(가운데 꼭짓점 1개)
        XCTAssertEqual(segments[2], [points[2], points[3]])        // 실패 → 곧은 선
        XCTAssertNil(store.resolved["R|2|3"])                      // 저장하지 않아 다시 시도한다
        XCTAssertEqual(segments[4], [points[4], points[5]])        // 우회 → 곧은 선
        XCTAssertNotNil(store.resolved["R|4|5"])
    }
}

private actor FakeRoadProvider: RouteShapeProviding {
    nonisolated var cachesToDisk: Bool { false }
    private var running = 0
    private(set) var maxConcurrent = 0
    private var failing: Set<String> = []
    private var detour: Set<String> = []

    func setFailing(_ keys: Set<String>) { failing = keys }
    func setDetour(_ keys: Set<String>) { detour = keys }

    func roadPath(from: CoursePoint, to: CoursePoint) async throws -> [CoursePoint] {
        running += 1
        maxConcurrent = max(maxConcurrent, running)
        defer { running -= 1 }
        try await Task.sleep(for: .milliseconds(20))
        let key = keyFor(from, to)
        if failing.contains(key) { throw URLError(.notConnectedToInternet) }
        let mid = CoursePoint(latitude: (from.latitude + to.latitude) / 2 + (detour.contains(key) ? 0.01 : 0.0002),
                              longitude: (from.longitude + to.longitude) / 2)
        return [from, mid, to]
    }

    /// 테스트 점은 동쪽 200m 간격이라 경도 순서로 번호를 되찾는다.
    private func keyFor(_ from: CoursePoint, _ to: CoursePoint) -> String {
        let step = 200 / (111_320 * cos(37.5 * .pi / 180))
        let i = Int(((from.longitude - 127.0) / step).rounded())
        return "R|\(i)|\(i + 1)"
    }
}
