import Foundation
import XCTest
@testable import FocusMate

final class JourneyActivityPresentationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_791_882_000)

    private func state(
        _ status: JourneyActivityStatus = .running,
        end: Date? = nil, paused: Int? = nil, total: Int? = 1800
    ) -> JourneyActivityAttributes.ContentState {
        JourneyActivityAttributes.ContentState(
            status: status, endDate: end, pausedRemainingSeconds: paused, totalSeconds: total
        )
    }

    // 깨짐: 잔여/총 시간을 진행률로 그대로 반환하거나 전체 시간으로 나누지 않는다.
    func testW17_잔여1122초의_진행률은_0점3766667이다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let value = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(value, 0.3766667, accuracy: 0.000001)
    }

    // 깨짐: 종료 근처에도 시작 진행률을 고정하거나 잔여초를 잘못 계산한다.
    func testW17_잔여135초의_진행률은_0점925다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_882_135))

        let value = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(value, 0.925, accuracy: 0.000001)
    }

    // 깨짐: 진행 막대를 now...end로 만들어 현재 잔여 시간 전체를 새 세션으로 취급한다.
    func testW17_running_진행막대는_종료에서총1800초를뺀_날짜범위다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: now)

        XCTAssertEqual(result.progress, .timer(
            Date(timeIntervalSince1970: 1_791_881_322)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
        XCTAssertEqual(result.time, .countdown(
            Date(timeIntervalSince1970: 1_791_882_000)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
    }

    // 깨짐: now가 60초 이동해도 잔여를 시작 표본1122초로 고정한다.
    func testW17_60초후_잔여는1062초다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))

        let result = JourneyActivityDisplay.remainingSeconds(
            state: input, isStale: false, now: Date(timeIntervalSince1970: 1_791_882_060)
        )

        XCTAssertEqual(result, 1062)
    }

    // 깨짐: 관찰 시각이 지나도 진행률을 고정하거나 날짜 기반 진행 범위를 이동시킨다.
    func testW17_60초후_진행률은0점41이며_진행날짜범위는_유지된다() throws {
        let input = state(end: Date(timeIntervalSince1970: 1_791_883_122))
        let observed = Date(timeIntervalSince1970: 1_791_882_060)

        let fraction = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: observed))
        let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: observed)

        XCTAssertEqual(fraction, 0.41, accuracy: 0.000001)
        XCTAssertEqual(result.progress, .timer(
            Date(timeIntervalSince1970: 1_791_881_322)...Date(timeIntervalSince1970: 1_791_883_122)
        ))
    }

    // 깨짐: stale을 정지보다 우선하거나 정지 중 진행 채움을 계속 움직인다.
    func testW17_stale정지의_진행채움은300초후에도_0점3766667이다() throws {
        let input = state(.paused, paused: 1122)

        let result = JourneyActivityDisplay.presentation(
            state: input, isStale: true, now: Date(timeIntervalSince1970: 1_791_882_300)
        )

        XCTAssertEqual(result.status, .paused)
        XCTAssertEqual(result.time, .fixed("18:42"))
        guard case .fixed(let fraction) = result.progress else {
            XCTFail("정지 진행 채움은 fixed여야 한다")
            return
        }
        XCTAssertEqual(fraction, 0.3766667, accuracy: 0.000001)
        let sampled = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: true, now: now))
        XCTAssertEqual(sampled, 0.3766667, accuracy: 0.000001)
    }

    // 깨짐: 정지 남은 시간에서 관찰 시각300초를 차감하거나 stale 때문에0을 반환한다.
    func testW17_stale정지의_잔여1122초는300초후에도_유지된다() {
        let input = state(.paused, paused: 1122)

        let result = JourneyActivityDisplay.remainingSeconds(
            state: input, isStale: true, now: Date(timeIntervalSince1970: 1_791_882_300)
        )

        XCTAssertEqual(result, 1122)
    }

    // 깨짐: 잔여가 총 시간보다 클 때 음수 진행률을 그대로 반환한다.
    func testW17_잔여1900초는_진행률0으로_제한한다() throws {
        let input = state(.paused, paused: 1900)

        let result = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(result, 0, accuracy: 0.000001)
    }

    // 깨짐: 음수 잔여로 진행률이1을 넘거나 진행률을 숨긴다.
    func testW17_잔여음수5초는_진행률1로_제한한다() throws {
        let input = state(.paused, paused: -5)

        let result = try XCTUnwrap(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))

        XCTAssertEqual(result, 1, accuracy: 0.000001)
    }

    // 깨짐: 소수 잔여초를 버림하여 종료까지 남은 시간을1초 짧게 표시한다.
    func testW17_잔여1점2초는_2초로_올림한다() {
        let input = state(end: Date(timeIntervalSince1970: 1_791_882_001.2))

        let result = JourneyActivityDisplay.remainingSeconds(state: input, isStale: false, now: now)

        XCTAssertEqual(result, 2)
    }

    // 호환 회귀. 깨짐: nil/0/음수 총 시간에서 허위 진행률·진행 막대를 제공한다.
    func testW17_호환_유효하지않은총시간은_진행을숨기고_시간을보존한다() {
        let totals: [Int?] = [nil, 0, -1]
        for total in totals {
            let input = state(end: Date(timeIntervalSince1970: 1_791_883_122), total: total)

            let result = JourneyActivityDisplay.presentation(state: input, isStale: false, now: now)

            XCTAssertEqual(result.status, .running)
            XCTAssertEqual(result.time, .countdown(
                Date(timeIntervalSince1970: 1_791_882_000)...Date(timeIntervalSince1970: 1_791_883_122)
            ))
            XCTAssertEqual(result.progress, .hidden)
            XCTAssertNil(JourneyActivityDisplay.progressFraction(state: input, isStale: false, now: now))
        }
    }

    // 호환 회귀. 깨짐: 만료·도착·종료누락 중 하나에서 문구·상태·진행이 서로 어긋난다.
    func testW17_호환_missingend_stale_arrived는_도착으로_정규화한다() {
        let examples: [(JourneyActivityAttributes.ContentState, Bool)] = [
            (state(), false),
            (state(end: Date(timeIntervalSince1970: 1_791_883_122)), true),
            (state(.arrived), false)
        ]
        for (input, stale) in examples {
            let result = JourneyActivityDisplay.presentation(state: input, isStale: stale, now: now)

            XCTAssertEqual(result.status, .arrived)
            XCTAssertEqual(result.time, .fixed("도착했어요"))
            XCTAssertEqual(result.progress, .hidden)
        }
    }

    // 호환 회귀. 깨짐: 장시간 정지 표시가 시간 단위로 바뀌거나 stale을 도착으로 덮는다.
    func testW17_호환_장시간정지는_120분과360분을_유지한다() {
        let examples: [(Int, String)] = [(7200, "120:00"), (21600, "360:00")]
        for (remaining, expected) in examples {
            let input = state(.paused, paused: remaining, total: nil)

            let result = JourneyActivityDisplay.presentation(state: input, isStale: true, now: now)

            XCTAssertEqual(result.status, .paused)
            XCTAssertEqual(result.time, .fixed(expected))
            XCTAssertEqual(result.progress, .hidden)
        }
    }

    // 호환 회귀. 깨짐: summary가 긴 이름을 축약하거나 별도 시간 요소와 시간을 중복한다.
    func testW17_호환_장시간정지summary는_전체이름과_상태만_제공한다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "long-journey", busNumber: "서울도심순환심야광역급행12345",
            busKind: "심야광역급행", destinationName: "서울특별시성동구성수동복합문화체육센터정문앞"
        )
        for remaining in [7200, 21600] {
            let result = JourneyActivityDisplay.presentation(
                state: state(.paused, paused: remaining, total: nil), isStale: true, now: now
            )

            let summary = JourneyActivityDisplay.accessibilitySummary(attributes: attributes, presentation: result)

            XCTAssertEqual(summary, "서울도심순환심야광역급행12345번 심야광역급행 버스, 도착지 서울특별시성동구성수동복합문화체육센터정문앞, 일시정지")
        }
    }
}
