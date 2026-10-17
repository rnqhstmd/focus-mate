import Foundation

/// 마이페이지 누적 시간 표기. 화면은 시안의 "min/h", VoiceOver는 한국어 "분/시간"으로 같은 구조를 쓴다.
/// 마이페이지 전용이며 다른 화면의 "분" 표기와 무관하다. 로캘 형식을 쓰지 않아 천 단위 구분 기호가 없다.
enum ProfileTimeText {
    static func display(minutes: Int) -> String { format(minutes, hour: " h", minute: " min") }
    static func spoken(minutes: Int) -> String { format(minutes, hour: "시간", minute: "분") }
    /// 도넛 가운데 짧은 형식(시안 R23·R24): "16h 35m", 1시간 미만은 "25 min", 0은 "0 min".
    static func compact(minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) min" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours)h" : "\(hours)h \(rest)m"
    }

    private static func format(_ minutes: Int, hour: String, minute: String) -> String {
        guard minutes >= 60 else { return "\(minutes)\(minute)" }
        let hours = minutes / 60, rest = minutes % 60
        return rest == 0 ? "\(hours)\(hour)" : "\(hours)\(hour) \(rest)\(minute)"
    }
}
