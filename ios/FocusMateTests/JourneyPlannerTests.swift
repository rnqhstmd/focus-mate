import Foundation
import XCTest
@testable import FocusMate

/// 후보 계산(candidates·distanceText·JourneyCandidate)은 W16b에서 카탈로그 기반 RouteCandidates로 옮겨졌다.
/// 여기서는 남은 분 범위·초기값·clamp만 본다.
final class JourneyPlannerTests: XCTestCase {
    func test_clamp는_범위_밖_값을_경계로_맞추고_범위_안_값은_유지한다() {
        XCTAssertEqual(JourneyPlanner.clamp(14), 15)
        XCTAssertEqual(JourneyPlanner.clamp(361), 360)
        XCTAssertEqual(JourneyPlanner.clamp(60), 60)
    }

    func test_분_범위와_초기값은_15에서_360이고_초기값은_25다() {
        XCTAssertEqual(JourneyPlanner.minuteRange, 15...360)
        XCTAssertEqual(JourneyPlanner.initialMinutes, 25)
    }
}
