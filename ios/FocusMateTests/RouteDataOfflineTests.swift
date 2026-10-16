import Foundation
import XCTest
@testable import FocusMate

private final class RequestRecorder: URLProtocol {
    nonisolated(unsafe) static var count = 0
    private static let lock = NSLock()
    override class func canInit(with request: URLRequest) -> Bool {
        lock.lock(); count += 1; lock.unlock()
        return false
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {}
    override func stopLoading() {}
}

/// W16b T6 — AC-51: 검색·후보·코스 계산은 네트워크 요청을 만들지 않는다.
final class RouteDataOfflineTests: XCTestCase {
    override func setUp() {
        super.setUp()
        RequestRecorder.count = 0
        URLProtocol.registerClass(RequestRecorder.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(RequestRecorder.self)
        super.tearDown()
    }

    // 깨짐: 검색/후보/코스 계산 경로가 원격 요청을 보낸다.
    func testAC51_검색_후보_코스계산은_네트워크요청_0건이다() throws {
        let catalog = try RouteCatalogLoader.bundled(Bundle.main)

        _ = StationSearch.search("강남", in: catalog)
        _ = StationSearch.search("100", in: catalog)

        var leg: RouteLeg?
        for i in stride(from: 0, to: catalog.stops.count, by: 53) where leg == nil {
            leg = RouteCandidates.candidates(minutes: 25, originStop: i, in: catalog).first?.leg
        }
        let found = try XCTUnwrap(leg, "후보를 만들 정류장이 없음")

        let course = CourseJourney(leg: found, catalog: catalog)
        for elapsed in [0, 300, 900, 1500] {
            _ = JourneyCourseProgress.position(of: course, elapsedSeconds: elapsed)
        }
        XCTAssertEqual(RequestRecorder.count, 0)
    }
}
