import Foundation
import XCTest
@testable import FocusMate

/// W16b T6 — 실제 앱 번들의 서울 전체 데이터 회귀·성능(AC-50, 52~54, 56).
final class RouteDataBundleTests: XCTestCase {
    private nonisolated(unsafe) static var catalog: RouteCatalog!

    override class func setUp() {
        super.setUp()
        catalog = try? RouteCatalogLoader.bundled(Bundle.main)
    }

    private func catalog() throws -> RouteCatalog {
        try XCTUnwrap(Self.catalog, "번들 카탈로그 로드 실패")
    }

    private func seconds(_ d: Duration) -> Double {
        Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }

    // 깨짐: 데이터 파일이 번들에 포함되지 않거나 file 스킴이 아니다.
    func testAC50_번들_데이터파일은_file스킴_URL로_존재한다() throws {
        let url = try XCTUnwrap(RouteCatalogLoader.bundledURL(Bundle.main))
        XCTAssertEqual(url.scheme, "file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    // 깨짐: 산출 파일이 10MB(10,000,000바이트)를 넘는다.
    func testAC56_번들_데이터파일_용량은_10MB_이하다() throws {
        let url = try XCTUnwrap(RouteCatalogLoader.bundledURL(Bundle.main))
        let size = try XCTUnwrap(try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber).intValue
        XCTAssertGreaterThan(size, 0)
        XCTAssertLessThanOrEqual(size, 10_000_000)
    }

    // 깨짐: 번들 데이터가 샘플/축소본이다.
    func test번들_카탈로그는_서울_전체_규모의_정류장과_노선을_가진다() throws {
        let c = try catalog()
        XCTAssertGreaterThan(c.stops.count, 10_000)
        XCTAssertGreaterThan(c.routes.count, 600)
    }

    // 깨짐: 기준일·출처 URL 메타데이터가 틀리거나 비어 있다.
    func test메타데이터는_기준일과_서울열린데이터광장_출처를_가진다() throws {
        let m = try catalog().metadata
        XCTAssertEqual(m.baseDate, "2026-09-02")
        XCTAssertTrue(m.sourceURL.hasPrefix("https://data.seoul.go.kr/"))
        XCTAssertTrue(m.routeInfoSourceURL.hasPrefix("https://data.seoul.go.kr/"))
    }

    // 깨짐: 로드가 느려져 평균 1초를 넘는다.
    func testAC54_번들_로드_20회_평균은_1초_이하다() throws {
        let clock = ContinuousClock()
        var total = 0.0
        var maxT = 0.0
        for _ in 0..<20 {
            var loaded: RouteCatalog?
            let d = clock.measure { loaded = try? RouteCatalogLoader.bundled(Bundle.main) }
            XCTAssertNotNil(loaded)
            let s = seconds(d)
            total += s
            maxT = max(maxT, s)
        }
        print("[T6] AC-54 load avg=\(total / 20)s max=\(maxT)s")
        XCTAssertLessThanOrEqual(total / 20, 1.0)
    }

    // 깨짐: 검색 인덱스가 없어 전체 순회로 평균 0.3초를 넘는다.
    func testAC52_이름2글자와_숫자_검색_20회_평균은_0점3초_이하다() throws {
        let c = try catalog()
        let queries = ["서울", "강남", "종로", "신촌", "잠실", "역삼", "시청", "홍대", "사당", "노원",
                       "100", "1001", "200", "2001", "300", "1234", "500", "5001", "700", "8000"]
        let clock = ContinuousClock()
        var total = 0.0
        var maxT = 0.0
        for q in queries {
            let d = clock.measure { _ = StationSearch.search(q, in: c) }
            let s = seconds(d)
            total += s
            maxT = max(maxT, s)
        }
        print("[T6] AC-52 search avg=\(total / 20)s max=\(maxT)s")
        XCTAssertLessThanOrEqual(total / 20, 0.3)
    }

    // 깨짐: 가장 붐비는 정류장의 후보 계산이 평균 0.2초를 넘는다.
    func testAC53_최다노선_정류장_후보계산_20회_평균은_0점2초_이하다() throws {
        let c = try catalog()
        var best = 0
        var bestCount = -1
        for i in 0..<c.stops.count {
            let n = c.visits(stopIndex: i).count
            if n > bestCount { bestCount = n; best = i }
        }
        let clock = ContinuousClock()
        var total = 0.0
        var maxT = 0.0
        for k in 0..<20 {
            let minutes = 15 + 18 * k
            let d = clock.measure { _ = RouteCandidates.candidates(minutes: minutes, originStop: best, in: c) }
            let s = seconds(d)
            total += s
            maxT = max(maxT, s)
        }
        print("[T6] AC-53 stop=\(c.stops[best].name) visits=\(bestCount) avg=\(total / 20)s max=\(maxT)s")
        XCTAssertLessThanOrEqual(total / 20, 0.2)
    }

    // 깨짐: 25분 요청에서 후보가 없는 정류장이 절반 이상이다(변환/필터 회귀).
    func test무작위_200개_정류장_25분_후보없음_비율을_보고한다() throws {
        let c = try catalog()
        var empty = 0
        let n = 200
        for i in 0..<n {
            let idx = (i * 97) % c.stops.count
            if RouteCandidates.candidates(minutes: 25, originStop: idx, in: c).isEmpty { empty += 1 }
        }
        let ratio = Double(empty) / Double(n)
        print("[T6] zero-candidate ratio @25min = \(ratio) (\(empty)/\(n))")
        XCTAssertLessThan(ratio, 0.5)
    }
}
