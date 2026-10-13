import Foundation
import XCTest
@testable import FocusMate

final class JourneyPlannerTests: XCTestCase {
    private let seongsuForward = StopPosition(index: 0, direction: 1)
    private let seongsuReverse = StopPosition(index: 0, direction: -1)
    private let seoulForest = StopPosition(index: 4, direction: 1)

    private struct Row: Equatable {
        let number: String
        let destination: String
        let stops: Int
        let distance: String
    }

    private func rows(_ minutes: Int, _ origin: StopPosition) -> [Row] {
        JourneyPlanner.candidates(minutes: minutes, from: origin).map {
            Row(number: $0.bus.number, destination: $0.destination, stops: $0.stops, distance: $0.distanceText)
        }
    }

    func test_120분은_버스_3건을_순서대로_반환한다() {
        XCTAssertEqual(rows(120, seongsuForward), [
            Row(number: "2014", destination: "성수대교 북단", stops: 24, distance: "13.2km"),
            Row(number: "강남02", destination: "뚝섬역", stops: 20, distance: "11km"),
            Row(number: "343", destination: "성수대교 북단", stops: 15, distance: "8.25km"),
        ])
    }

    func test_24분은_2014를_제외하고_302와_421만_반환한다() {
        XCTAssertEqual(rows(24, seongsuForward), [
            Row(number: "강남02", destination: "서울숲역", stops: 4, distance: "2.2km"),
            Row(number: "343", destination: "성동구민체육센터", stops: 3, distance: "1.65km"),
        ])
    }

    func test_최소_15분은_2014_1건만_반환한다() {
        XCTAssertEqual(rows(15, seongsuForward), [
            Row(number: "2014", destination: "성동구민체육센터", stops: 3, distance: "1.65km"),
        ])
    }

    func test_최대_360분은_순환을_돌아_3건을_반환한다() {
        XCTAssertEqual(rows(360, seongsuForward), [
            Row(number: "2014", destination: "성수역", stops: 72, distance: "39.6km"),
            Row(number: "강남02", destination: "성수대교 북단", stops: 60, distance: "33km"),
            Row(number: "343", destination: "성수역", stops: 45, distance: "24.75km"),
        ])
    }

    func test_성수역_역방향_60분은_421을_제외한_2건을_반환한다() {
        XCTAssertEqual(rows(60, seongsuReverse), [
            Row(number: "2014", destination: "성수대교 북단", stops: 12, distance: "6.6km"),
            Row(number: "강남02", destination: "성수사거리", stops: 10, distance: "5.5km"),
        ])
    }

    func test_서울숲역_정방향_60분의_도착지는_뚝섬한강공원과_서울숲_입구다() {
        let result = JourneyPlanner.candidates(minutes: 60, from: seoulForest)
        XCTAssertEqual(result.map(\.bus.number), ["2014", "강남02"])
        XCTAssertEqual(result.map(\.destination), ["뚝섬한강공원", "서울숲 입구"])
    }

    func test_성수역_정방향_25분은_2014_1건_서울숲_입구_5정류장이다() {
        XCTAssertEqual(rows(25, seongsuForward), [
            Row(number: "2014", destination: "서울숲 입구", stops: 5, distance: "2.75km"),
        ])
    }

    func test_17분은_후보가_없다() {
        XCTAssertEqual(JourneyPlanner.candidates(minutes: 17, from: seongsuForward), [])
    }

    func test_범위_밖_14분과_361분은_후보가_없다() {
        XCTAssertEqual(JourneyPlanner.candidates(minutes: 14, from: seongsuForward), [])
        XCTAssertEqual(JourneyPlanner.candidates(minutes: 361, from: seongsuForward), [])
    }

    func test_clamp는_범위_밖_값을_경계로_맞추고_범위_안_값은_유지한다() {
        XCTAssertEqual(JourneyPlanner.clamp(14), 15)
        XCTAssertEqual(JourneyPlanner.clamp(361), 360)
        XCTAssertEqual(JourneyPlanner.clamp(60), 60)
    }

    func test_분_범위와_초기값은_15에서_360이고_초기값은_25다() {
        XCTAssertEqual(JourneyPlanner.minuteRange, 15...360)
        XCTAssertEqual(JourneyPlanner.initialMinutes, 25)
    }

    func test_distanceText는_끝_0을_제거하고_소수_둘째_자리까지_표기한다() {
        XCTAssertEqual(JourneyPlanner.distanceText(stops: 5), "2.75km")
        XCTAssertEqual(JourneyPlanner.distanceText(stops: 10), "5.5km")
        XCTAssertEqual(JourneyPlanner.distanceText(stops: 20), "11km")
    }

    func test_접근성_레이블은_종류_번호_도착지_분_정류장_순서다() {
        let first = JourneyPlanner.candidates(minutes: 60, from: seongsuForward).first
        XCTAssertEqual(first?.accessibilityLabel, "지선 2014번, 성동구민체육센터, 60분, 12정류장")
    }

    func test_버스_노선_정의는_번호_종류_정류장당_분을_가진다() {
        XCTAssertEqual(BusLine.all.map(\.number), ["2014", "강남02", "343"])
        XCTAssertEqual(BusLine.all.map(\.kind), ["지선", "마을", "간선"])
        XCTAssertEqual(BusLine.all.map(\.minutesPerStop), [5, 6, 8])
    }
}
