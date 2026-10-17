import Foundation
import Observation

/// 지도 화면 연결부. 타이머 값을 받아 상태·버스 위치·카메라 목표를 갱신한다.
/// 저장자·타이머를 갖지 않으므로 지도 때문에 저장이 일어날 경로가 없다(BR-6).
@MainActor
@Observable
final class JourneyMapController {
    private(set) var state: JourneyMapState
    private(set) var bus: CourseBusPosition
    private(set) var cameraTarget: JourneyCameraTarget
    private(set) var nextStopIndex: Int
    private(set) var remainingStops: Int
    private(set) var remainingDistanceTenthsKm: Int
    @ObservationIgnored let journey: CourseJourney
    @ObservationIgnored private var reduceMotion: Bool

    init(journey: CourseJourney, status: JourneyTimerController.Status, elapsedSeconds: Int, reduceMotion: Bool) {
        self.journey = journey
        self.reduceMotion = reduceMotion
        state = JourneyMapState(status: status)
        let bus = JourneyCourseProgress.position(of: journey, elapsedSeconds: elapsedSeconds)
        self.bus = bus
        cameraTarget = JourneyCameraPolicy.target(center: bus.point, reduceMotion: reduceMotion, revision: 0)
        nextStopIndex = JourneyCourseProgress.nextStopIndex(of: journey, elapsedSeconds: elapsedSeconds)
        remainingStops = JourneyCourseProgress.remainingStops(of: journey, elapsedSeconds: elapsedSeconds)
        remainingDistanceTenthsKm = JourneyCourseProgress.remainingDistanceTenthsKm(of: journey, elapsedSeconds: elapsedSeconds)
    }

    /// 출발 → 도착 실제 노선 구간. 닫는 선이 없다.
    var routePoints: [CoursePoint] { journey.stops.map(\.point) }
    /// 지나온 구간: 출발 → 현재 버스 위치. 남은 구간: 버스 위치 → 도착.
    var travelledPoints: [CoursePoint] { Array(routePoints.prefix(bus.segmentFrom + 1)) + [bus.point] }
    var remainingPoints: [CoursePoint] { [bus.point] + Array(routePoints.dropFirst(bus.segmentFrom + 1)) }
    /// 버스가 이미 지난(도달한) 정류장인지. 다음 정류장 앞까지가 지난 정류장이다.
    func isPassed(_ stop: CourseStop) -> Bool { stop.index < nextStopIndex }
    var visibleStops: [CourseStop] { state.showsStops ? journey.stops : [] }
    var destinationStop: CourseStop { journey.stops.last! }
    var nextStop: CourseStop { journey.stops[nextStopIndex] }

    func sync(status: JourneyTimerController.Status, elapsedSeconds: Int) {
        if status != state.status { state.timerStatusChanged(status) }
        bus = JourneyCourseProgress.position(of: journey, elapsedSeconds: elapsedSeconds)
        nextStopIndex = JourneyCourseProgress.nextStopIndex(of: journey, elapsedSeconds: elapsedSeconds)
        remainingStops = JourneyCourseProgress.remainingStops(of: journey, elapsedSeconds: elapsedSeconds)
        remainingDistanceTenthsKm = JourneyCourseProgress.remainingDistanceTenthsKm(of: journey, elapsedSeconds: elapsedSeconds)
        if state.camera == .follow { retarget() }
    }

    func setReduceMotion(_ on: Bool) {
        reduceMotion = on
        if state.camera == .follow { retarget() }
    }

    func userMovedCamera() { state.userMovedCamera() }
    func followTapped() { if state.followTapped() { retarget() } }
    func openThemeSheet() { state.openThemeSheet() }
    func dismissThemeSheet() { state.dismissThemeSheet() }
    func select(theme: JourneyMapTheme) { state.select(theme: theme) }
    func setShowsStops(_ on: Bool) { state.setShowsStops(on) }
    func leave() { state.leave() }

    private func retarget() {
        cameraTarget = JourneyCameraPolicy.target(center: bus.point, reduceMotion: reduceMotion,
                                                  revision: cameraTarget.revision + 1)
    }
}
