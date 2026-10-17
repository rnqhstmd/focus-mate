import Foundation

enum JourneyCameraMode: String { case follow, explore }
enum JourneyMapTheme: String { case dark, satellite }

/// 지도 화면 상태(BR-3~5). 저장하지 않는 메모리 상태이고, 동작 줄이기 값은 담지 않는다(AC-32).
struct JourneyMapState: Equatable {
    private(set) var camera: JourneyCameraMode = .follow
    private(set) var theme: JourneyMapTheme = .satellite
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
    let center: CoursePoint
    let headingDegrees: Double
    let pitchDegrees: Double
    let distanceMeters: Double
    let animated: Bool
    /// 같은 목표를 다시 적용해야 할 때(따라가기 복귀) 값이 바뀌도록 올린다.
    let revision: Int
}

/// 카메라 목표 규칙. 기울인 3D 시점, 북쪽 위 고정(FR-17 제외), 동작 줄이기면 애니메이션 없음.
/// 시안 R13은 거의 내려다보는 시점(약 30~40°)에 화면 높이에 정류장 약 5개가 들어오는 축척이다.
enum JourneyCameraPolicy {
    static let pitchDegrees: Double = 40
    static let distanceMeters: Double = 1000

    static func target(center: CoursePoint, reduceMotion: Bool, revision: Int) -> JourneyCameraTarget {
        JourneyCameraTarget(center: center, headingDegrees: 0, pitchDegrees: pitchDegrees,
                            distanceMeters: distanceMeters, animated: !reduceMotion, revision: revision)
    }
}
