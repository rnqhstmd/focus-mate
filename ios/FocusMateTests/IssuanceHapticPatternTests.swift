import CoreHaptics
import XCTest
@testable import FocusMate

final class IssuanceHapticPatternTests: XCTestCase {
    // 깨짐 명명: 곡선이 내려가거나 평평하게 바뀌면(시작 >= 끝) 실패.
    func testAC17_세기_곡선은_약하게_시작해_강하게_끝난다() throws {
        let curve = IssuanceHapticPattern.issuance.intensityCurve
        let first = try XCTUnwrap(curve.first)
        let last = try XCTUnwrap(curve.last)

        XCTAssertLessThan(first.intensity, last.intensity)
    }

    // 깨짐 명명: 끝 탭이 없거나 2개 이상이거나 패턴 끝과 다른 시간에 있으면 실패.
    func testAC17_끝_탭은_하나이고_패턴_끝에_있다() throws {
        let pattern = IssuanceHapticPattern.issuance

        XCTAssertEqual(pattern.taps.count, 1)
        XCTAssertEqual(try XCTUnwrap(pattern.taps.first).time, pattern.duration)
    }

    // 깨짐 명명: 패턴 길이가 0.9 가 아니거나 CardIssuanceTiming.hapticDuration 과 어긋나면 실패.
    func testAC17_패턴_길이는_0점9초이고_타이밍_상수와_같다() {
        XCTAssertEqual(IssuanceHapticPattern.issuance.duration, 0.9, accuracy: 0.0001)
        XCTAssertEqual(CardIssuanceTiming.hapticDuration, 0.9, accuracy: 0.0001)
        XCTAssertEqual(IssuanceHapticPattern.issuance.duration, CardIssuanceTiming.hapticDuration, accuracy: 0.0001)
    }

    // 깨짐 명명: 제어점이나 파라미터가 CoreHaptics 가 거부하는 값이면 실패.
    func testAC17_CoreHaptics_패턴으로_변환해도_던지지_않는다() {
        XCTAssertNoThrow(try IssuanceHapticPattern.issuance.makeCHHapticPattern())
    }
}
