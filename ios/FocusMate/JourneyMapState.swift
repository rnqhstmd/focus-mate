import Foundation

enum JourneyCameraMode: String { case follow, explore }
enum JourneyMapTheme: String { case dark, satellite }

/// 지도 화면 상태(BR-3~5). 저장하지 않는 메모리 상태이고, 동작 줄이기 값은 담지 않는다(AC-32).
struct JourneyMapState: Equatable {
    private(set) var camera: JourneyCameraMode = .follow
    private(set) var theme: JourneyMapTheme = .dark
    private(set) var showsStops = true
    private(set) var isThemeSheetPresented = false
    private(set) var status: JourneyTimerController.Status

    /// 일시정지 중에만 지도 도구 두 버튼을 잠근다. 지도 직접 조작은 막지 않는다.
    var toolsEnabled: Bool { status != .paused }

    init(status: JourneyTimerController.Status) { self.status = status }

    mutating func userMovedCamera() { camera = .explore }

    /// 따라가기는 토글이 아니라 항상 버스로 복귀한다. true면 카메라를 버스에 다시 맞춘다.
    @discardableResult
    mutating func followTapped() -> Bool {
        guard toolsEnabled else { return false }
        camera = .follow
        return true
    }

    /// 일시정지 화면의 "현재 정류장으로"(R15). 도구 잠금과 무관하게 카메라를 버스로 되돌린다.
    mutating func recenter() { camera = .follow }

    mutating func openThemeSheet() {
        guard toolsEnabled else { return }
        isThemeSheetPresented = true
    }

    mutating func dismissThemeSheet() { isThemeSheetPresented = false }
    mutating func select(theme: JourneyMapTheme) { self.theme = theme }
    mutating func setShowsStops(_ on: Bool) { showsStops = on }

    mutating func timerStatusChanged(_ status: JourneyTimerController.Status) {
        self.status = status
        if status != .running { isThemeSheetPresented = false }
    }

    mutating func leave() { isThemeSheetPresented = false }
}

struct JourneyCameraTarget: Equatable {
    /// 카메라 중심. 버스를 화면 아래쪽에 두려고 진행 방향 앞으로 옮긴 점이다.
    let center: CoursePoint
    /// 카메라가 따라가는 버스 위치(중심을 옮기기 전).
    let focus: CoursePoint
    let headingDegrees: Double
    let pitchDegrees: Double
    let distanceMeters: Double
    let animated: Bool
    /// 같은 목표를 다시 적용해야 할 때(따라가기 복귀) 값이 바뀌도록 올린다.
    let revision: Int
}

/// 카메라 목표 규칙. 내비처럼 진행 방향이 화면 위(heading-up)인 기울인 3D 시점.
/// 버스는 화면 가운데보다 아래(약 63% 높이)에 두어 앞쪽 길이 더 보이게 하고, 동작 줄이기면 애니메이션 없이 바꾼다.
/// 시안 R13은 거의 내려다보는 시점(약 30~40°)에 화면 높이에 정류장 약 5개가 들어오는 축척이다.
enum JourneyCameraPolicy {
    static let pitchDegrees: Double = 40
    static let distanceMeters: Double = 1000
    /// 카메라 중심을 버스 앞으로 옮기는 거리. 기울기 40°·거리 1000m에서 버스가 화면 높이 약 63%에 온다.
    static let leadMeters: Double = 150
    /// 이보다 작은 방위 변화는 무시한다(도로 경로의 잔흔들림에 지도가 계속 돌지 않게).
    static let headingThresholdDegrees: Double = 5

    /// - Parameters:
    ///   - busHeading: 버스 진행 방위(북 0°, 시계 방향).
    ///   - previousHeading: 직전 카메라 방위. 없으면(처음·따라가기 복귀) 진행 방위 그대로.
    static func target(bus: CoursePoint, busHeading: Double, previousHeading: Double?,
                       reduceMotion: Bool, revision: Int) -> JourneyCameraTarget {
        let heading = smoothedHeading(busHeading, previous: previousHeading)
        return JourneyCameraTarget(center: RouteShape.offset(bus, headingDegrees: heading, meters: leadMeters), focus: bus,
                                   headingDegrees: heading, pitchDegrees: pitchDegrees, distanceMeters: distanceMeters,
                                   animated: !reduceMotion, revision: revision)
    }

    /// 새 진행 방위를 직전 카메라 방위에 이어 붙인다. 변화가 문턱 미만이면 직전 값을 유지하고,
    /// 아니면 최단 회전 쪽 값(예: 350° → 10°는 370°)을 돌려 359°→1°에서 지도가 한 바퀴 돌지 않게 한다.
    static func smoothedHeading(_ heading: Double, previous: Double?) -> Double {
        guard let previous else { return heading }
        let delta = shortestDelta(from: previous, to: heading)
        return abs(delta) < headingThresholdDegrees ? previous : previous + delta
    }

    /// a에서 b로 가는 가장 짧은 회전 각도(-180..<180).
    static func shortestDelta(from a: Double, to b: Double) -> Double {
        let d = (b - a).truncatingRemainder(dividingBy: 360)
        let wrapped = d < 0 ? d + 360 : d
        return wrapped >= 180 ? wrapped - 360 : wrapped
    }
}
