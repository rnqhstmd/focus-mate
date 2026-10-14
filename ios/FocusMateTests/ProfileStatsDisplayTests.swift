import Foundation
import XCTest
@testable import FocusMate

final class ProfileStatsDisplayTests: XCTestCase {
    // 깨짐 명명: 0건 표시가 "0"/"0 min"이 아니거나 라벨이 0회/0분이 아니면 실패
    func testAC8_기록이_없으면_0과_0분을_보여주고_오류는_없다() {
        let display = ProfileStatsDisplay(.loaded(RecordLifetimeSummary(count: 0, minutes: 0)))

        XCTAssertEqual(display.journeysText, "0")
        XCTAssertEqual(display.timeText, "0 min")
        XCTAssertEqual(display.journeysAccessibilityLabel, "완료한 여정, 0회")
        XCTAssertEqual(display.timeAccessibilityLabel, "함께한 시간, 0분")
        XCTAssertNil(display.errorMessage)
    }

    // 깨짐 명명: 65분을 "65 min"으로 두거나 시/분 분해·라벨 한국어 단위를 틀리면 실패
    func testAC9_3회_65분은_시와_분으로_나누어_보여준다() {
        let display = ProfileStatsDisplay(.loaded(RecordLifetimeSummary(count: 3, minutes: 65)))

        XCTAssertEqual(display.journeysText, "3")
        XCTAssertEqual(display.timeText, "1 h 5 min")
        XCTAssertEqual(display.journeysAccessibilityLabel, "완료한 여정, 3회")
        XCTAssertEqual(display.timeAccessibilityLabel, "함께한 시간, 1시간 5분")
        XCTAssertNil(display.errorMessage)
    }

    // 깨짐 명명: 집계 실패를 0으로 보여주거나 오류 문구를 누락하면 실패
    func testAC29_집계_불가면_대시와_오류_문구를_보여준다() {
        let display = ProfileStatsDisplay(.unavailable)

        XCTAssertEqual(display.journeysText, "-")
        XCTAssertEqual(display.timeText, "-")
        XCTAssertEqual(display.journeysAccessibilityLabel, "완료한 여정")
        XCTAssertEqual(display.timeAccessibilityLabel, "함께한 시간")
        XCTAssertEqual(display.errorMessage, "기록을 불러오지 못했어요")
    }
}
