import Foundation
import XCTest
@testable import FocusMate

final class StationSearchTests: XCTestCase {
    private typealias F = RouteCatalogFixture

    private func options(_ query: String, in catalog: RouteCatalog, file: StaticString = #filePath, line: UInt = #line) throws -> (options: [StopSearchOption], overflow: Bool) {
        guard case let .results(options, overflow) = StationSearch.search(query, in: catalog) else {
            XCTFail("results가 아님: \(query)", file: file, line: line)
            return ([], false)
        }
        return (options, overflow)
    }

    // 깨짐: 정확 일치를 앞부분 일치와 같은 단계로 두거나 번호 정렬을 빼면 순서가 달라진다.
    func testAC1_이름_정확일치가_앞부분일치보다_먼저_나오고_번호순이다() throws {
        let result = try options("알파", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S1", "S1b", "S9"])
        XCTAssertFalse(result.overflow)
    }

    // 깨짐: 공백 제거나 소문자 비교가 빠지면 0건이 된다.
    func testAC2_앞뒤_공백과_대소문자를_무시한다() throws {
        let result = try options("  ALPHA  ", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S10"])
    }

    // 깨짐: 번호 정확 일치를 지원하지 않으면 실패한다.
    func testAC3_숫자_입력은_번호_정확일치를_찾는다() throws {
        let result = try options("10003", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S2"])
    }

    // 깨짐: 번호 앞자리 일치를 못 하거나 번호순 정렬이 아니면 실패한다.
    func testAC4_번호_앞자리_일치는_번호_오름차순이다() throws {
        let result = try options("100", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S1", "S1b", "S2", "S3", "S4", "S5", "S9"])
    }

    // 깨짐: 결과 없음을 prompt나 빈 results로 돌려주면 실패한다.
    func testAC5_일치가_없으면_empty이다() throws {
        XCTAssertEqual(StationSearch.search("없는이름", in: try F.acceptance()), .empty)
    }

    // 깨짐: 빈 입력이나 공백만 입력을 empty로 처리하면 실패한다.
    func testAC6_빈_입력과_공백만_입력은_prompt이다() throws {
        let catalog = try F.acceptance()
        XCTAssertEqual(StationSearch.search("", in: catalog), .prompt)
        XCTAssertEqual(StationSearch.search("   ", in: catalog), .prompt)
    }

    // 깨짐: 50건 제한이나 overflow 표시가 없으면 실패한다.
    func testAC7_결과는_50건으로_자르고_overflow를_켠다() throws {
        let stops = (1...60).map { F.stop("T\($0)", "테스트\($0)", $0) }
        let catalog = try F.make(stops: stops, routes: [])
        let result = try options("테스트", in: catalog)
        XCTAssertEqual(result.options.count, 50)
        XCTAssertTrue(result.overflow)
        XCTAssertEqual(result.options.prefix(3).map(\.name), ["테스트1", "테스트10", "테스트11"])
    }

    // 깨짐: 방면 라벨을 옵션에 싣지 않거나 접근성 문구 형식이 다르면 실패한다.
    func testAC8_옵션은_방면과_접근성_라벨을_가진다() throws {
        let result = try options("알파", in: try F.acceptance())
        let s1 = try XCTUnwrap(result.options.first { $0.id == "S1" })
        XCTAssertEqual(s1.boundLabel, "베타 방면")
        XCTAssertEqual(s1.accessibilityLabel, "알파, 10001, 베타 방면")
    }

    // 깨짐: 번호를 숫자로 바꿔 앞의 0을 잃으면 "001" 검색이 실패한다.
    func testAC9_번호는_문자열_그대로_앞자리_비교한다() throws {
        let stops = [F.stop("A", "가나", ars: "00123", 1), F.stop("B", "다라", ars: "7832", 2), F.stop("C", "마바", 3)]
        let catalog = try F.make(stops: stops, routes: [])
        XCTAssertEqual(try options("001", in: catalog).options.map(\.ars), ["00123"])
        XCTAssertEqual(try options("78", in: catalog).options.map(\.ars), ["7832"])
    }

    // 깨짐: 번호 없는 정류장의 라벨에 번호 자리가 남거나 ars가 채워지면 실패한다.
    func testAC12_번호_없는_정류장은_번호_없이_이름과_방면만_읽는다() throws {
        let result = try options("무번호", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S11"])
        XCTAssertNil(result.options.first?.ars)
        XCTAssertEqual(result.options.first?.accessibilityLabel, "무번호정류장, 델타 방면")
    }

    // 깨짐: 숫자 입력에서도 이름을 검색하면 "100번가"가 결과에 섞인다.
    func testNumericSearchDoesNotLookAtNames() throws {
        let stops = [F.stop("N", "100번가", ars: "55555", 1), F.stop("M", "에이", ars: "10001", 2)]
        let catalog = try F.make(stops: stops, routes: [])
        XCTAssertEqual(try options("100", in: catalog).options.map(\.id), ["M"])
    }

    // 깨짐: 방면이 없을 때 빈 문구나 "nil"이 라벨에 붙으면 실패한다.
    func testAccessibilityLabelOmitsBoundWhenNil() throws {
        let result = try options("알파센터", in: try F.acceptance())
        XCTAssertNil(result.options.first?.boundLabel)
        XCTAssertEqual(result.options.first?.accessibilityLabel, "알파센터, 10007")
    }

    // 깨짐: 부분 일치(3단계)를 지원하지 않으면 0건이 된다.
    func testNameContainsMatchFindsStop() throws {
        let result = try options("센터", in: try F.acceptance())
        XCTAssertEqual(result.options.map(\.id), ["S9"])
    }
}
