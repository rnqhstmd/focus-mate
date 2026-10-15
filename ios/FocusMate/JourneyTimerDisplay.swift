import Foundation

/// 타이머 화면 표기 규칙. 남은 시간은 분 단위 "N min"만 쓰고 초·시 표기는 쓰지 않는다(designs/final/README.md).
enum JourneyTimerDisplay {
    /// 올림이라 "0 min"은 정확히 0초가 남았을 때만 나온다. 입력은 내림한 정수 경과 초다.
    static func remainingMinutes(totalSeconds: Int, elapsedSeconds: Int) -> Int {
        max(0, (totalSeconds - elapsedSeconds + 59) / 60)
    }

    static func text(minutes: Int) -> String { "\(minutes) min" }
    static func accessibilityValue(minutes: Int) -> String { "남은 시간 \(minutes)분" }

    static let accessibilityLabel = "타이머"
    static let pauseLabel = "일시정지"
    static let resumeLabel = "재개"
    static let pausedAnnouncement = "일시정지됨"
    static let resumedAnnouncement = "재개됨"
    static let transitionFailureText = "저장하지 못했어요. 다시 눌러주세요."
    static let checkpointWarningText = "진도를 저장하지 못해 멈췄어요. 재개를 눌러주세요."
    /// 도착에는 재개 수단이 없어 체크포인트 문구를 쓸 수 없다. 문구 톤은 W09 도착 안내에서 다시 정한다.
    static let arrivalWarningText = "도착을 저장하지 못했어요."
}
