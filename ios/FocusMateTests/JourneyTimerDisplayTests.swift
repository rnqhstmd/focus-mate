import Foundation
import XCTest
@testable import FocusMate

/// 타이머 표시 규칙 (T3). 남은 분은 올림, 사용자 노출 문구는 PRD가 정한 계약이다.
final class JourneyTimerDisplayTests: XCTestCase {
    // 깨짐: 올림 대신 내림/반올림을 쓰면 elapsed 1·61에서 실패한다.
    func test_남은_분은_초_단위_경과를_올림으로_계산한다() {
        // 1500초 여정: 손 계산 (1500 - elapsed) / 60 올림
        let cases: [(elapsed: Int, minutes: Int)] = [
            (0, 25), (1, 25), (60, 24), (61, 24), (1499, 1), (1500, 0),
        ]
        for c in cases {
            XCTAssertEqual(
                JourneyTimerDisplay.remainingMinutes(totalSeconds: 1500, elapsedSeconds: c.elapsed),
                c.minutes,
                "elapsed \(c.elapsed)"
            )
        }
    }

    // 깨짐: 하한 0을 걸지 않으면 음수가 반환되어 실패한다.
    func test_경과가_총시간을_넘어도_남은_분은_0이다() {
        XCTAssertEqual(JourneyTimerDisplay.remainingMinutes(totalSeconds: 1500, elapsedSeconds: 1800), 0)
    }

    // 깨짐: 형식이 "N min"이 아니거나 시·초·콜론 표기가 섞이면 실패한다.
    func test_표시_문구는_분만_N_min_형식이다() {
        let text = JourneyTimerDisplay.text(minutes: 24)
        XCTAssertEqual(text, "24 min")
        XCTAssertFalse(text.contains("h"))
        XCTAssertFalse(text.contains("초"))
        XCTAssertFalse(text.contains(":"))
    }

    // 깨짐: 낭독 문구 형식이 바뀌면 실패한다.
    func test_낭독_값은_남은_시간_N분이다() {
        XCTAssertEqual(JourneyTimerDisplay.accessibilityValue(minutes: 24), "남은 시간 24분")
        XCTAssertEqual(JourneyTimerDisplay.accessibilityValue(minutes: 0), "남은 시간 0분")
    }

    // 깨짐: 접근성 라벨이 PRD 계약과 다르면 실패한다.
    func test_접근성_라벨과_버튼_라벨은_PRD_계약을_따른다() {
        XCTAssertEqual(JourneyTimerDisplay.accessibilityLabel, "타이머")
        XCTAssertEqual(JourneyTimerDisplay.pauseLabel, "일시정지")
        XCTAssertEqual(JourneyTimerDisplay.resumeLabel, "재개")
    }

    // 깨짐: 상태 변경 낭독 문구가 PRD 계약과 다르면 실패한다.
    func test_상태_변경_낭독_문구는_PRD_계약을_따른다() {
        XCTAssertEqual(JourneyTimerDisplay.pausedAnnouncement, "일시정지됨")
        XCTAssertEqual(JourneyTimerDisplay.resumedAnnouncement, "재개됨")
    }

    // 깨짐: 실패 안내 문구가 PRD 계약과 다르면 실패한다.
    func test_저장_실패_안내_문구는_PRD_계약을_따른다() {
        XCTAssertEqual(JourneyTimerDisplay.transitionFailureText, "저장하지 못했어요. 다시 눌러주세요.")
        XCTAssertEqual(JourneyTimerDisplay.checkpointWarningText, "진도를 저장하지 못해 멈췄어요. 재개를 눌러주세요.")
    }
}
