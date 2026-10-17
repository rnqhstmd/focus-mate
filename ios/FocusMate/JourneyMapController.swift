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
    /// 노선선(앞 문맥 + 탈 구간 + 뒤 문맥). 처음에는 곧은 선이고 도로 경로를 받는 대로 `apply(shape:)`로 바뀐다.
    private(set) var shape: RouteShape
    @ObservationIgnored let journey: CourseJourney
    @ObservationIgnored private var reduceMotion: Bool
    @ObservationIgnored private var elapsedSeconds: Int

    init(journey: CourseJourney, status: JourneyTimerController.Status, elapsedSeconds: Int, reduceMotion: Bool) {
        self.journey = journey
        self.reduceMotion = reduceMotion
        self.elapsedSeconds = elapsedSeconds
        state = JourneyMapState(status: status)
        let shape = RouteShape.straight((journey.stopsBefore + journey.stops + journey.stopsAfter).map(\.point))
        self.shape = shape
        let bus = Self.locate(JourneyCourseProgress.position(of: journey, elapsedSeconds: elapsedSeconds), journey: journey, shape: shape)
        self.bus = bus
        cameraTarget = JourneyCameraPolicy.target(bus: bus.point, busHeading: bus.headingDegrees, previousHeading: nil,
                                                  reduceMotion: reduceMotion, revision: 0)
        nextStopIndex = JourneyCourseProgress.nextStopIndex(of: journey, elapsedSeconds: elapsedSeconds)
        remainingStops = JourneyCourseProgress.remainingStops(of: journey, elapsedSeconds: elapsedSeconds)
        remainingDistanceTenthsKm = JourneyCourseProgress.remainingDistanceTenthsKm(of: journey, elapsedSeconds: elapsedSeconds)
    }

    /// 출발 → 도착 실제 노선 구간. 닫는 선이 없다.
    var routePoints: [CoursePoint] { journey.stops.map(\.point) }
    /// 노선 전체(탈 구간 앞뒤 포함) 흐린 선.
    var contextPoints: [CoursePoint] { shape.points }
    /// 지나온 구간: 출발 → 현재 버스 위치. 남은 구간: 버스 위치 → 도착. 둘 다 노선선(도로 경로) 위를 따른다.
    var travelledPoints: [CoursePoint] { shape.line(from: legLocation(0, 0), to: busLocation) }
    var remainingPoints: [CoursePoint] { shape.line(from: busLocation, to: legLocation(journey.totalStops, 0)) }
    /// 도로 경로에 쓸 구간 요청(노선 ID + 정류장 쌍).
    var segmentRequests: [RouteSegmentRequest] { journey.segmentRequests }
    /// 버스가 이미 지난(도달한) 정류장인지. 다음 정류장 앞까지가 지난 정류장이다.
    func isPassed(_ stop: CourseStop) -> Bool { stop.index < nextStopIndex }
    /// 버스가 그 정류장 위(구간 시작 바로 근처)에 서 있는지.
    func isUnderBus(_ stop: CourseStop) -> Bool {
        stop.index == bus.segmentFrom && bus.fraction < 0.05
    }
    var visibleStops: [CourseStop] { state.showsStops ? journey.stops : [] }
    var destinationStop: CourseStop { journey.stops.last! }
    var nextStop: CourseStop { journey.stops[nextStopIndex] }
    /// 화면 진행 칩 값(다음 정류장·지난 수/전체).
    var stopProgress: JourneyStopProgress { JourneyStopProgress(journey: journey, nextStopIndex: nextStopIndex) }

    /// 받은 도로 경로로 노선선을 바꾸고 버스 위치·방향을 그 선 위에서 다시 계산한다.
    func apply(shape: RouteShape) {
        guard shape != self.shape, shape.segments.count == self.shape.segments.count else { return }
        self.shape = shape
        bus = Self.locate(JourneyCourseProgress.position(of: journey, elapsedSeconds: elapsedSeconds), journey: journey, shape: shape)
        if state.camera == .follow { retarget() }
    }

    func sync(status: JourneyTimerController.Status, elapsedSeconds: Int) {
        if status != state.status { state.timerStatusChanged(status) }
        self.elapsedSeconds = elapsedSeconds
        bus = Self.locate(JourneyCourseProgress.position(of: journey, elapsedSeconds: elapsedSeconds), journey: journey, shape: shape)
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
    func followTapped() { if state.followTapped() { retarget(resetHeading: true) } }
    /// 일시정지 중에도 쓰는 "현재 정류장으로"(R15): 카메라를 버스 위치로 되돌린다.
    func recenter() {
        state.recenter()
        retarget(resetHeading: true)
    }
    func openThemeSheet() { state.openThemeSheet() }
    func dismissThemeSheet() { state.dismissThemeSheet() }
    func select(theme: JourneyMapTheme) { state.select(theme: theme) }
    func setShowsStops(_ on: Bool) { state.setShowsStops(on) }
    func leave() { state.leave() }

    private var busLocation: RouteShape.Location { legLocation(bus.segmentFrom, bus.fraction) }

    private func legLocation(_ segment: Int, _ fraction: Double) -> RouteShape.Location {
        RouteShape.Location(segment: journey.stopsBefore.count + segment, fraction: fraction)
    }

    /// 시간 진도(구간 + 비율)를 노선선 위 점과 접선 방위로 바꾼다. 비율은 그 구간 선 길이의 비율이다.
    /// 방향은 탈 구간 안에서만 보며, 정류장에 서 있으면 다음 구간 방향, 도착하면 마지막 구간 방향이다.
    static func locate(_ position: CourseBusPosition, journey: CourseJourney, shape: RouteShape) -> CourseBusPosition {
        let offset = journey.stopsBefore.count
        let location = RouteShape.Location(segment: offset + position.segmentFrom, fraction: position.fraction)
        let range = shape.distance(at: .init(segment: offset, fraction: 0))...shape.distance(at: .init(segment: offset + journey.totalStops, fraction: 0))
        let heading = shape.heading(at: location, within: range, backward: position.isArrived) ?? position.headingDegrees
        return CourseBusPosition(point: shape.point(at: location), headingDegrees: heading, segmentFrom: position.segmentFrom,
                                 segmentTo: position.segmentTo, fraction: position.fraction, isArrived: position.isArrived)
    }

    /// 따라가는 중 카메라를 버스 진행 방향 위(heading-up)로 맞춘다. 복귀할 때는 직전 방위와 무관하게 진행 방위 그대로.
    private func retarget(resetHeading: Bool = false) {
        cameraTarget = JourneyCameraPolicy.target(bus: bus.point, busHeading: bus.headingDegrees,
                                                  previousHeading: resetHeading ? nil : cameraTarget.headingDegrees,
                                                  reduceMotion: reduceMotion, revision: cameraTarget.revision + 1)
    }
}
