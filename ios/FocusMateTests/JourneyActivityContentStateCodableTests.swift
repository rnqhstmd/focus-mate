import Foundation
import XCTest
@testable import FocusMate

final class JourneyActivityContentStateCodableTests: XCTestCase {
    private func roundTrip(_ json: String) throws -> [String: Any] {
        let state = try JSONDecoder().decode(
            JourneyActivityAttributes.ContentState.self, from: Data(json.utf8)
        )
        let data = try JSONEncoder().encode(state)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // 깨짐: 실행 상태의 총 시간을 디코딩 또는 인코딩 중 버린다.
    func testW17_실행_JSON왕복은_총1800초를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"running","endDate":813576522,"totalSeconds":1800}"#
        )

        XCTAssertEqual(object["totalSeconds"] as? Int, 1800)
        XCTAssertEqual(object["status"] as? String, "running")
    }

    // 깨짐: 일시정지 상태의 총 시간을 누락하거나 고정 잔여로 대체한다.
    func testW17_일시정지_JSON왕복은_총3600초를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"paused","pausedRemainingSeconds":1122,"totalSeconds":3600}"#
        )

        XCTAssertEqual(object["totalSeconds"] as? Int, 3600)
        XCTAssertEqual(object["pausedRemainingSeconds"] as? Int, 1122)
    }

    // 깨짐: 총 시간이 없는 이전 실행 상태를 복원하지 못하거나 임의 총 시간을 만든다.
    func testW17_legacy_총시간누락_JSON은_시간과_상태를_보존한다() throws {
        let object = try roundTrip(#"{"status":"running","endDate":813576522}"#)

        XCTAssertEqual(object["status"] as? String, "running")
        XCTAssertEqual(object["endDate"] as? Double, 813576522)
        XCTAssertTrue(object["totalSeconds"] == nil || object["totalSeconds"] is NSNull)
    }

    // 깨짐: 명시적 null 총 시간의 이전 정지 상태를 거절하거나 잔여 시간을 잃는다.
    func testW17_legacy_총시간null_JSON은_정지잔여를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"paused","pausedRemainingSeconds":1122,"totalSeconds":null}"#
        )

        XCTAssertEqual(object["status"] as? String, "paused")
        XCTAssertEqual(object["pausedRemainingSeconds"] as? Int, 1122)
        XCTAssertTrue(object["totalSeconds"] == nil || object["totalSeconds"] is NSNull)
    }
}
