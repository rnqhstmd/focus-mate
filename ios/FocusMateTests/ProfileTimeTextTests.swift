import Foundation
import XCTest
@testable import FocusMate

final class ProfileTimeTextTests: XCTestCase {
    // 깨짐 명명: 0분을 빈 문자열이나 "0 h"로 바꾸면 실패
    func testAC10_0분은_0_min으로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 0), "0 min")
    }

    // 깨짐 명명: 시간 승격 기준을 59 이하로 낮추면 실패
    func testAC10_59분은_시간으로_올리지_않고_59_min으로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 59), "59 min")
    }

    // 깨짐 명명: 60분에서 "1 h 0 min"을 붙이면 실패
    func testAC10_60분은_분_없이_1_h로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 60), "1 h")
    }

    // 깨짐 명명: 나머지 분 계산(% 60)을 빼면 실패
    func testAC10_61분은_1_h_1_min으로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 61), "1 h 1 min")
    }

    // 깨짐 명명: 나머지가 0일 때 "2 h 0 min"을 붙이면 실패
    func testAC10_120분은_2_h로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 120), "2 h")
    }

    // 깨짐 명명: 시간을 24 등으로 상한 처리하면 실패
    func testAC10_6000분은_100_h로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 6000), "100 h")
    }

    // 깨짐 명명: 큰 시간값에서 분 표기를 누락하면 실패
    func testAC10_6005분은_100_h_5_min으로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 6005), "100 h 5 min")
    }

    // 깨짐 명명: 천 단위 구분 기호("1,000 h")를 넣으면 실패
    func testAC10_60000분은_천_단위_구분_없이_1000_h로_표기한다() {
        XCTAssertEqual(ProfileTimeText.display(minutes: 60000), "1000 h")
    }

    // 깨짐 명명: 접근성 표기가 영문 단위를 쓰면 실패
    func testAC11_0분은_0분으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 0), "0분")
    }

    func testAC11_59분은_59분으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 59), "59분")
    }

    func testAC11_60분은_1시간으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 60), "1시간")
    }

    // 깨짐 명명: 시간과 분 사이 공백을 빼면 실패
    func testAC11_61분은_1시간_1분으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 61), "1시간 1분")
    }

    func testAC11_120분은_2시간으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 120), "2시간")
    }

    func testAC11_6000분은_100시간으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 6000), "100시간")
    }

    func testAC11_6005분은_100시간_5분으로_읽는다() {
        XCTAssertEqual(ProfileTimeText.spoken(minutes: 6005), "100시간 5분")
    }

    // 깨짐 명명: display가 spoken과 같은 한국어 단위를 쓰면 실패
    func testAC22_화면_표기에는_분과_시간_글자가_없다() {
        for minutes in [0, 59, 60, 61, 120, 6000, 6005, 60000] {
            let text = ProfileTimeText.display(minutes: minutes)
            XCTAssertFalse(text.contains("분"), "\(minutes)분 → \(text)")
            XCTAssertFalse(text.contains("시간"), "\(minutes)분 → \(text)")
            XCTAssertFalse(text.isEmpty, "\(minutes)분 → 빈 문자열")
        }
    }
}
