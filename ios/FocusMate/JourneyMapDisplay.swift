import Foundation

/// 지도·하단 정보 문구와 접근성 값(BR-8, FR-12, FR-15).
enum JourneyMapDisplay {
    static let mapLabel = "가상 코스 지도"
    static let followLabel = "버스 따라가기"
    static let themeLabel = "지도 테마"
    static let darkLabel = "어두운 지도"
    static let satelliteLabel = "위성"
    static let stopsLabel = "정류장 표시"
    static let remainingStopsLabel = "남은 정류장"
    static let remainingDistanceLabel = "남은 거리"


    static func mapValue(destination: String) -> String { "도착 정류장 \(destination)" }
    static func followValue(_ mode: JourneyCameraMode) -> String { mode == .follow ? "따라가는 중" : "자유 탐색 중" }
    static func selectedValue(_ on: Bool) -> String { on ? "선택됨" : "선택 안 됨" }
    static func switchValue(_ on: Bool) -> String { on ? "켜짐" : "꺼짐" }
    static func stopsText(_ count: Int) -> String { "\(count)" }
    static func stopsAccessibilityValue(_ count: Int) -> String { "\(count)개" }
    static func distanceText(tenthsKm: Int) -> String { "\(tenthsKm / 10).\(tenthsKm % 10)" }
    static func distanceAccessibilityValue(tenthsKm: Int) -> String { distanceText(tenthsKm: tenthsKm) + "km" }
}
