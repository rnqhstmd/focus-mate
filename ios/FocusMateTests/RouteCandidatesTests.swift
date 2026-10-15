import Foundation
import XCTest
@testable import FocusMate

final class RouteCandidatesTests: XCTestCase {
    private typealias F = RouteCatalogFixture

    private func candidates(
        from stopID: String, minutes: Int, in catalog: RouteCatalog
    ) throws -> [RouteCandidate] {
        let stop = try XCTUnwrap(catalog.stopIndex(id: stopID))
        return RouteCandidates.candidates(minutes: minutes, originStop: stop, in: catalog)
    }

    /// 출발 O, 도착 D 두 정류장에 노선 (id, O→D 초, O→D 미터)를 놓은 카탈로그.
    private func twoStopCatalog(_ specs: [(id: String, seconds: Int, meters: Int)]) throws -> RouteCatalog {
        let stops = [F.stop("O", "출발", 1), F.stop("D", "도착", 2)]
        let routes = specs.map {
            F.route($0.id, stops: ["O", "D"], in: stops, seconds: [$0.seconds, 60], meters: [$0.meters, 500])
        }
        return try F.make(stops: stops, routes: routes)
    }

    // 깨짐: 후보를 노선 하나만 만들거나 정렬 규칙을 바꾸면 실패한다.
    func testAC13_출발_정류장을_지나는_노선마다_후보_하나를_만든다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 10, in: catalog)
        XCTAssertEqual(result.map(\.id), ["1111", "2222"])
        XCTAssertEqual(result.map(\.destination), ["감마", "감마"])
        XCTAssertEqual(result.map(\.stops), [2, 1])
    }

    // 깨짐: 허용 오차 밖 노선(2222, 차이 120)을 포함하면 실패한다.
    func testAC14_허용_오차_밖_노선은_제외된다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 9, in: catalog)
        XCTAssertEqual(result.map(\.id), ["1111"])
        XCTAssertEqual(result.map(\.stops), [2])
    }

    // 깨짐: 가장 가까운 지점 대신 첫 지점을 고르면 도착지가 달라져 실패한다.
    func testAC15_가장_가까운_도착지를_쓴다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 16, in: catalog)
        XCTAssertEqual(result.map(\.id), ["1111"])
        XCTAssertEqual(result.first?.destination, "델타")
        XCTAssertEqual(result.first?.stops, 3)
    }

    // 깨짐: 비례 조정 전 원래 구간을 후보에 담으면 실패한다.
    func testAC16_후보의_구간_시간은_비례_조정된_값이다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 17, in: catalog)
        XCTAssertEqual(result.map(\.id), ["1111"])
        XCTAssertEqual(result.first?.leg.segmentSeconds, [319, 255, 446])
    }

    // 깨짐: 허용 오차를 넘는 노선을 억지로 채우면 실패한다.
    func testAC17_맞는_노선이_없으면_빈_배열이다() throws {
        let catalog = try F.acceptance()
        XCTAssertEqual(try candidates(from: "S1", minutes: 18, in: catalog), [])
    }

    // 깨짐: 출발 정류장을 도착지로 허용하면 후보가 생겨 실패한다.
    func testAC18_출발_정류장만_가능한_순환_노선은_빈_배열이다() throws {
        let catalog = try F.acceptance()
        XCTAssertEqual(try candidates(from: "S6", minutes: 15, in: catalog), [])
    }

    // 깨짐: 순환 노선이 한 바퀴만 보면 정류장 수가 달라져 실패한다.
    func testAC19_순환_노선_후보가_여러_정류장을_이어간다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S6", minutes: 25, in: catalog)
        XCTAssertEqual(result.map(\.id), ["3333"])
        XCTAssertEqual(result.first?.destination, "Z")
        XCTAssertEqual(result.first?.stops, 5)
    }

    // 깨짐: 회차하지 않으면 6정류장 후보가 나오지 않아 실패한다.
    func testAC20_회차하는_노선_후보가_두_바퀴째까지_간다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 30, in: catalog)
        XCTAssertEqual(result.map(\.id), ["1111"])
        XCTAssertEqual(result.first?.destination, "베타")
        XCTAssertEqual(result.first?.stops, 6)
    }

    // 깨짐: 동률에서 늦은 지점을 고르면 도착지가 파이3이 되어 실패한다.
    func testAC21_동률이면_이른_도착지가_후보가_된다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "P1", minutes: 6, in: catalog)
        XCTAssertEqual(result.map(\.id), ["7777"])
        XCTAssertEqual(result.first?.destination, "파이2")
    }

    // 깨짐: 20건 제한이 없거나 번호 순이 아니면 실패한다.
    func testAC22_후보는_20건까지_번호_순으로_자른다() throws {
        let catalog = try twoStopCatalog((1...25).map { (id: String($0), seconds: 600, meters: 500) })
        let result = try candidates(from: "O", minutes: 10, in: catalog)
        XCTAssertEqual(result.count, 20)
        XCTAssertEqual(result.map(\.busNumber), (1...20).map(String.init))
    }

    // 깨짐: 문자열 사전순(1111 < 720 < 강남02)으로 정렬하면 실패한다.
    func testAC23_차이가_같으면_번호_자연_정렬_순이다() throws {
        let catalog = try twoStopCatalog([
            (id: "강남02", seconds: 600, meters: 500),
            (id: "1111", seconds: 600, meters: 500),
            (id: "720", seconds: 600, meters: 500),
        ])
        let result = try candidates(from: "O", minutes: 10, in: catalog)
        XCTAssertEqual(result.map(\.id), ["720", "1111", "강남02"])
    }

    // 깨짐: 차이를 무시하고 노선 순으로만 정렬하면 ["1","2"]가 되어 실패한다.
    func testDifferenceComesBeforeRouteOrder() throws {
        let catalog = try twoStopCatalog([
            (id: "1", seconds: 630, meters: 500),
            (id: "2", seconds: 600, meters: 500),
        ])
        let result = try candidates(from: "O", minutes: 10, in: catalog)
        XCTAssertEqual(result.map(\.id), ["2", "1"])
    }

    // 깨짐: 구간 미터 합을 쓰지 않거나 반올림이 틀리면 실패한다.
    func testAC25_거리_문구는_구간_합을_소수_한_자리_km로_쓴다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 16, in: catalog)
        XCTAssertEqual(result.first?.distanceText, "2.5km")
    }

    // 깨짐: 소수 0일 때 ".0"을 붙이면 실패한다.
    func testDistanceTextOmitsZeroDecimal() throws {
        let catalog = try twoStopCatalog([(id: "1", seconds: 600, meters: 3000)])
        XCTAssertEqual(try candidates(from: "O", minutes: 10, in: catalog).first?.distanceText, "3km")
    }

    // 깨짐: 내림이나 올림만 쓰면 1449 또는 1450 중 하나가 틀려 실패한다.
    func testDistanceTextRoundsAtFiftyMeters() throws {
        let low = try twoStopCatalog([(id: "1", seconds: 600, meters: 1449)])
        let high = try twoStopCatalog([(id: "1", seconds: 600, meters: 1450)])
        XCTAssertEqual(try candidates(from: "O", minutes: 10, in: low).first?.distanceText, "1.4km")
        XCTAssertEqual(try candidates(from: "O", minutes: 10, in: high).first?.distanceText, "1.5km")
    }

    // 깨짐: 읽기 문구의 순서나 단위가 달라지면 실패한다.
    func testAC26_접근성_문구는_종류_번호_도착지_시간_정류장_수_순이다() throws {
        let catalog = try F.acceptance()
        let result = try candidates(from: "S1", minutes: 16, in: catalog)
        XCTAssertEqual(result.first?.accessibilityLabel, "지선 1111번, 델타, 16분, 3정류장")
    }
}
