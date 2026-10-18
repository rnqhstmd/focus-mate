import Foundation
import XCTest
@testable import FocusMate

/// 지도 화면 표시 문구·수치 형식. 접근성 문구는 PRD가 정한 사용자 노출 계약이다.
final class JourneyMapDisplayTests: XCTestCase {
    // 깨짐: 거리 표기가 소수 1자리가 아니게 되면(2.6 → "3", "2.60") 실패한다.
    func test1_AC39_거리_텍스트는_소수_1자리다() {
        XCTAssertEqual(JourneyMapDisplay.distanceText(tenthsKm: 26), "2.6")
        XCTAssertEqual(JourneyMapDisplay.distanceText(tenthsKm: 0), "0.0")
        XCTAssertEqual(JourneyMapDisplay.distanceText(tenthsKm: 28), "2.8")
    }

    // 깨짐: 낭독 값에 km 단위가 빠지면 실패한다.
    func test2_AC39_거리_낭독_값은_km_단위를_붙인다() {
        XCTAssertEqual(JourneyMapDisplay.distanceAccessibilityValue(tenthsKm: 26), "2.6km")
        XCTAssertEqual(JourneyMapDisplay.distanceAccessibilityValue(tenthsKm: 0), "0.0km")
    }

    // 깨짐: 정류장 수 텍스트/낭독 값 형식이 "5"/"5개"에서 벗어나면 실패한다.
    func test3_AC39_정류장_수_텍스트와_낭독_값() {
        XCTAssertEqual(JourneyMapDisplay.stopsText(5), "5")
        XCTAssertEqual(JourneyMapDisplay.stopsAccessibilityValue(5), "5개")
        XCTAssertEqual(JourneyMapDisplay.stopsAccessibilityValue(0), "0개")
    }

    // 깨짐: 도착 정류장 이름이 지도 낭독 값에서 빠지면 실패한다. 다음 정류장 이름은 알리지 않는다.
    func test4_AC39_지도_낭독_값은_도착_정류장만_포함한다() {
        let value = JourneyMapDisplay.mapValue(destination: "성수사거리")
        XCTAssertTrue(value.contains("성수사거리"))
        XCTAssertEqual(value, "도착 정류장 성수사거리")
    }

    // 깨짐: 선택 상태 낭독 값이 뒤바뀌거나 바뀌면 실패한다.
    func test5_AC39_선택_상태_낭독_값() {
        XCTAssertEqual(JourneyMapDisplay.selectedValue(true), "선택됨")
        XCTAssertEqual(JourneyMapDisplay.selectedValue(false), "선택 안 됨")
    }

    // 깨짐: 스위치 상태 낭독 값이 뒤바뀌거나 바뀌면 실패한다.
    func test6_AC39_스위치_상태_낭독_값() {
        XCTAssertEqual(JourneyMapDisplay.switchValue(true), "켜짐")
        XCTAssertEqual(JourneyMapDisplay.switchValue(false), "꺼짐")
    }

    // 깨짐: 컨트롤·통계 라벨 문구가 PRD 계약과 달라지면 실패한다.
    func test7_AC39_컨트롤_라벨은_PRD_문구다() {
        XCTAssertEqual(JourneyMapDisplay.mapLabel, "가상 코스 지도")
        XCTAssertEqual(JourneyMapDisplay.followLabel, "버스 따라가기")
        XCTAssertEqual(JourneyMapDisplay.themeLabel, "지도 테마")
        XCTAssertEqual(JourneyMapDisplay.darkLabel, "어두운 지도")
        XCTAssertEqual(JourneyMapDisplay.satelliteLabel, "위성")
        XCTAssertEqual(JourneyMapDisplay.stopsLabel, "정류장 표시")
        XCTAssertEqual(JourneyMapDisplay.remainingStopsLabel, "남은 정류장")
        XCTAssertEqual(JourneyMapDisplay.remainingDistanceLabel, "남은 거리")
    }
}
