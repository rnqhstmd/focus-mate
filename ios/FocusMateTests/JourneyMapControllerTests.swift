import Foundation
import XCTest
@testable import FocusMate

/// 지도 컨트롤러 (T3). 타이머 컨트롤러·시계·저장 더블을 실제로 엮어 위치·카메라·상태를 검증한다.
@MainActor
final class JourneyMapControllerTests: XCTestCase {
    private let accuracy = 1e-9

    private let catalog = BoardingFixtures.uiCatalog()

    private func course(route routeID: String, origin: String, minutes: Int = 25) -> CourseJourney {
        let route = catalog.routeIndex(id: routeID)!
        let stop = catalog.stopIndex(id: origin)!
        let leg = RouteLegFinder.leg(route: route, originStop: stop, minutes: minutes, in: catalog)!
        return CourseJourney(leg: leg, catalog: catalog)
    }

    /// 성수 정방향 25분 2014(구간 300초) — 코스 위치 0...5, 도착 정류장은 코스 위치 5.
    private var forwardJourney: CourseJourney { course(route: "2014", origin: "seongsu") }

    /// 서울숲 역방향 25분 2014-r — 코스 위치 0...5, 도착 정류장은 성수사거리 역방향.
    private var reverseJourney: CourseJourney { course(route: "2014-r", origin: "seoulForest-r") }

    private func makeMap(
        _ journey: CourseJourney? = nil,
        status: JourneyTimerController.Status = .running,
        elapsed: Int = 0,
        reduceMotion: Bool = false
    ) -> JourneyMapController {
        JourneyMapController(
            journey: journey ?? forwardJourney, status: status, elapsedSeconds: elapsed, reduceMotion: reduceMotion
        )
    }

    private struct TimerRig {
        let timer: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
    }

    private func makeTimerRig() -> TimerRig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver()
        let snapshot = BoardingFixtures.journey(
            minutes: 25, destinationStopID: "seoulForestGate", destinationName: "서울숲 입구",
            phase: .departed, elapsedSeconds: 0, paused: false
        )
        let timer = JourneyTimerController(
            journey: snapshot, autoStart: true, saver: saver, clock: clock, ticker: clock, announcer: RecordingAnnouncer()
        )
        timer.appear()
        return TimerRig(timer: timer, clock: clock, saver: saver)
    }

    private func assertPoint(
        _ p: CoursePoint, equals q: CoursePoint,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(p.latitude, q.latitude, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(p.longitude, q.longitude, accuracy: accuracy, file: file, line: line)
    }

    // MARK: AC-10 일시정지·재개

    // 깨짐: 일시정지 중 sync가 버스를 옮기거나, 재개 후 정지 지점이 아닌 곳에서 이어가면 실패한다.
    func test1_AC10_일시정지_중에는_버스가_멈추고_재개하면_멈춘_지점부터_이어간다() {
        let rig = makeTimerRig()
        let map = makeMap(status: .running, elapsed: 0)

        rig.clock.advance(by: .seconds(600))
        map.sync(status: rig.timer.status, elapsedSeconds: rig.timer.elapsedSeconds)
        assertPoint(map.bus.point, equals: forwardJourney.stops[2].point)

        rig.timer.pause()
        rig.clock.advance(by: .seconds(300))
        map.sync(status: rig.timer.status, elapsedSeconds: rig.timer.elapsedSeconds)
        assertPoint(map.bus.point, equals: forwardJourney.stops[2].point)

        rig.timer.resume()
        rig.clock.advance(by: .seconds(300))
        map.sync(status: rig.timer.status, elapsedSeconds: rig.timer.elapsedSeconds)
        assertPoint(map.bus.point, equals: forwardJourney.stops[3].point)
    }

    // MARK: AC-11 도착

    // 깨짐: 도착 시 버스가 도착 정류장 좌표에 놓이지 않거나 isArrived가 꺼져 있으면 실패한다.
    func test2_AC11_도착하면_버스가_도착_정류장에_놓이고_도착_표시가_켜진다() {
        let map = makeMap()

        map.sync(status: .arrived, elapsedSeconds: 1500)

        assertPoint(map.bus.point, equals: forwardJourney.stops[5].point)
        XCTAssertTrue(map.bus.isArrived)
    }

    // MARK: AC-12 정류장 표시

    // 깨짐: 정류장 표시를 끄면 도착 정류장 좌표까지 사라지거나, 표시 개수·경로 점 수가 어긋나면 실패한다.
    func test3_AC12_정류장_표시를_꺼도_도착_정류장_좌표와_경로는_유지된다() {
        let map = makeMap()
        XCTAssertEqual(map.visibleStops.count, 6)

        map.setShowsStops(false)

        XCTAssertEqual(map.visibleStops.count, 0)
        XCTAssertEqual(map.routePoints.count, 6)
        XCTAssertNotEqual(map.routePoints.last, map.routePoints.first)
        assertPoint(map.destinationStop.point, equals: forwardJourney.stops[5].point)
    }

    // MARK: AC-13 초기 카메라

    // 깨짐: 초기 카메라가 follow가 아니거나 pitch가 0이거나 버스 위치가 아닌 곳을 가리키면 실패한다.
    func test4_AC13_생성_직후_카메라는_버스를_기울여_따라간다() {
        let map = makeMap(elapsed: 300)

        XCTAssertEqual(map.state.camera, .follow)
        XCTAssertGreaterThan(map.cameraTarget.pitchDegrees, 0)
        assertPoint(map.cameraTarget.focus, equals: map.bus.point)
        XCTAssertEqual(map.cameraTarget.headingDegrees, map.bus.headingDegrees, accuracy: accuracy)
    }

    // MARK: AC-14 앱 갱신

    // 깨짐: 앱의 sync 갱신이 카메라를 explore로 바꾸면 실패한다.
    func test5_AC14_따라가는_중_앱_갱신을_반복해도_follow가_유지된다() {
        let map = makeMap()

        map.sync(status: .running, elapsedSeconds: 100)
        map.sync(status: .running, elapsedSeconds: 200)
        map.sync(status: .running, elapsedSeconds: 300)

        XCTAssertEqual(map.state.camera, .follow)
    }

    // MARK: AC-15 탐색·복귀

    // 깨짐: 조작이 explore로 바꾸지 않거나, 복귀 버튼이 현재 버스 위치로 새 목표를 내지 않으면 실패한다.
    func test6_AC15_사용자가_움직이면_탐색이고_따라가기를_누르면_현재_버스로_복귀한다() {
        let map = makeMap()
        map.userMovedCamera()
        XCTAssertEqual(map.state.camera, .explore)
        map.sync(status: .running, elapsedSeconds: 600)
        let revisionBefore = map.cameraTarget.revision

        map.followTapped()

        XCTAssertEqual(map.state.camera, .follow)
        assertPoint(map.cameraTarget.focus, equals: forwardJourney.stops[2].point)
        XCTAssertEqual(map.cameraTarget.headingDegrees, map.bus.headingDegrees, accuracy: accuracy)
        XCTAssertGreaterThan(map.cameraTarget.revision, revisionBefore)
    }

    // MARK: AC-17 탐색 중 갱신

    // 깨짐: explore 중 sync가 카메라 목표를 새로 내거나 버스 위치를 갱신하지 않으면 실패한다.
    func test7_AC17_탐색_중_갱신은_버스만_움직이고_카메라_목표는_그대로다() {
        let map = makeMap()
        map.userMovedCamera()
        let busBefore = map.bus.point
        let targetBefore = map.cameraTarget

        map.sync(status: .running, elapsedSeconds: 300)

        XCTAssertNotEqual(map.bus.point, busBefore)
        assertPoint(map.bus.point, equals: forwardJourney.stops[1].point)
        XCTAssertEqual(map.cameraTarget.revision, targetBefore.revision)
        XCTAssertEqual(map.cameraTarget.center, targetBefore.center)
    }

    // MARK: AC-27 기본값 초기화

    // 깨짐: 설정이 인스턴스 밖으로 새어 새 컨트롤러가 이전 값을 물려받으면 실패한다.
    func test8_AC27_새_컨트롤러는_이전_인스턴스의_변경과_무관하게_기본값으로_시작한다() {
        let old = makeMap()
        old.userMovedCamera()
        old.select(theme: .dark)
        old.setShowsStops(false)
        old.openThemeSheet()

        let fresh = makeMap()

        XCTAssertEqual(fresh.state.camera, .follow)
        XCTAssertEqual(fresh.state.theme, .satellite)
        XCTAssertTrue(fresh.state.showsStops)
        XCTAssertFalse(fresh.state.isThemeSheetPresented)
    }

    // MARK: AC-28 지도 조작은 진도에 영향 없음

    // 깨짐: 지도 조작이 저장을 일으키거나 타이머 경과·상태를 바꾸면 실패한다.
    func test9_AC28_지도_조작만으로는_저장이_늘지_않고_타이머가_변하지_않는다() {
        let rig = makeTimerRig()
        rig.clock.advance(by: .seconds(300))
        let map = makeMap(status: rig.timer.status, elapsed: rig.timer.elapsedSeconds)
        let writesBefore = rig.saver.writes.count
        let elapsedBefore = rig.timer.elapsedSeconds
        let statusBefore = rig.timer.status

        map.userMovedCamera()
        map.select(theme: .dark)
        map.setShowsStops(false)
        map.openThemeSheet()
        map.dismissThemeSheet()
        map.followTapped()

        XCTAssertEqual(rig.saver.writes.count, writesBefore)
        XCTAssertEqual(rig.timer.elapsedSeconds, elapsedBefore)
        XCTAssertEqual(rig.timer.status, statusBefore)
    }

    // MARK: AC-30 / 31 움직임 줄이기

    // 깨짐: 움직임 줄이기를 무시하고 애니메이션 카메라를 내거나, 진행 방위(heading-up)를 따르지 않으면 실패한다.
    func test10_AC30_움직임_줄이기가_켜지면_카메라는_애니메이션_없이_진행_방위로_바뀐다() {
        let map = makeMap(elapsed: 300, reduceMotion: true)
        XCTAssertFalse(map.cameraTarget.animated)
        XCTAssertEqual(map.cameraTarget.headingDegrees, map.bus.headingDegrees, accuracy: accuracy)

        map.sync(status: .running, elapsedSeconds: 450)

        XCTAssertFalse(map.cameraTarget.animated)
        XCTAssertEqual(JourneyCameraPolicy.shortestDelta(from: map.cameraTarget.headingDegrees, to: map.bus.headingDegrees),
                       0, accuracy: JourneyCameraPolicy.headingThresholdDegrees)
    }

    // 깨짐: 기본은 애니메이션이 아니거나, 설정 변경이 이후 목표에 반영되지 않으면 실패한다.
    func test11_AC31_움직임_줄이기를_중간에_켜면_다음_목표부터_애니메이션이_꺼진다() {
        let map = makeMap(reduceMotion: false)
        XCTAssertTrue(map.cameraTarget.animated)

        map.setReduceMotion(true)
        map.sync(status: .running, elapsedSeconds: 300)

        XCTAssertFalse(map.cameraTarget.animated)
    }

    // MARK: AC-32 상태 동일성

    // 깨짐: 움직임 줄이기 여부가 카메라 모드·테마·시트 등 상태 전이를 달라지게 하면 실패한다.
    func test12_AC32_같은_이벤트_열은_움직임_줄이기와_무관하게_같은_상태를_만든다() {
        let on = makeMap(reduceMotion: true)
        let off = makeMap(reduceMotion: false)

        for map in [on, off] {
            map.userMovedCamera()
            map.followTapped()
            map.openThemeSheet()
            map.sync(status: .paused, elapsedSeconds: 300)
            map.sync(status: .running, elapsedSeconds: 300)
            map.select(theme: .dark)
            map.setShowsStops(false)
            map.leave()
        }

        XCTAssertEqual(on.state, off.state)
    }

    // MARK: AC-22 / 24 시트·도구

    // 깨짐: 일시정지에서 시트가 닫히지 않거나 도구가 잠기지 않으면, 혹은 재개·도착에서 도구가 풀리지 않으면 실패한다.
    func test13_AC22_일시정지는_시트를_닫고_도구를_잠그며_재개와_도착에서_풀린다() {
        let map = makeMap()
        map.openThemeSheet()

        map.sync(status: .paused, elapsedSeconds: 300)
        XCTAssertFalse(map.state.isThemeSheetPresented)
        XCTAssertFalse(map.state.toolsEnabled)

        map.sync(status: .running, elapsedSeconds: 300)
        XCTAssertTrue(map.state.toolsEnabled)

        map.openThemeSheet()
        map.sync(status: .arrived, elapsedSeconds: 1500)
        XCTAssertFalse(map.state.isThemeSheetPresented)
        XCTAssertTrue(map.state.toolsEnabled)
    }

    // MARK: 남은 값

    // 깨짐: 남은 정류장 수·다음 정류장 계산이 틀리면 실패한다. (역방향 노선도 코스 위치로 센다)
    func test14_남은값_서울숲_역방향_90초_경과는_남은_5정류장_다음_1번이다() {
        let map = makeMap(reverseJourney, elapsed: 90)

        XCTAssertEqual(map.remainingStops, 5)
        XCTAssertEqual(map.nextStopIndex, 1)
    }

    // 깨짐: 역방향 코스의 정류장 id·마지막 정류장이 카탈로그 노선 순서가 아니면 실패한다.
    func test14b_역방향_코스는_서울숲_역방향에서_성수사거리_역방향으로_끝난다() {
        let stops = reverseJourney.stops
        XCTAssertEqual(stops.first?.id, "seoulForest-r")
        XCTAssertEqual(stops.last?.id, "seongsuIntersection-r")
        assertPoint(makeMap(reverseJourney).destinationStop.point, equals: stops[5].point)
    }

    // MARK: init?(journey:catalog:)

    private func snapshot(
        origin: String = "seoulForest-r", busID: String = "2014-r", minutes: Int = 25,
        destination: String = "seongsuIntersection-r"
    ) -> JourneySnapshot {
        BoardingFixtures.journey(
            originStopID: origin, originName: "서울숲역", minutes: minutes, busID: busID,
            destinationStopID: destination, destinationName: "성수사거리", phase: .departed
        )
    }

    // 깨짐: 저장 값에서 노선·출발·분으로 코스를 다시 만들지 못하면 실패한다.
    func test15_init_정상_스냅샷은_코스_여정으로_변환된다() throws {
        let journey = try XCTUnwrap(CourseJourney(journey: snapshot(), catalog: catalog))

        XCTAssertEqual(journey.stops.count, 6)
        XCTAssertEqual(journey.stops.first?.id, "seoulForest-r")
        XCTAssertEqual(journey.stops.last?.id, "seongsuIntersection-r")
        XCTAssertEqual(journey.totalSeconds, 1500)
    }

    // 깨짐: 저장된 도착 정류장이 계산값과 달라도 변환이 성공하면 실패한다. (BR-12)
    func test16_init_저장된_도착_정류장이_계산값과_다르면_nil이다() {
        XCTAssertNil(CourseJourney(journey: snapshot(destination: "seongdongSportsCenter"), catalog: catalog))
    }

    // 깨짐: 구간 시간으로 맞는 정류장 수가 없는 분을 허용하면 실패한다.
    func test17_init_맞는_도착_정류장이_없는_분이면_nil이다() {
        XCTAssertNil(CourseJourney(journey: snapshot(minutes: 27), catalog: catalog))
    }

    // 깨짐: 카탈로그에 없는 노선을 허용하면 실패한다.
    func test18_init_알_수_없는_노선은_nil이다() {
        XCTAssertNil(CourseJourney(journey: snapshot(busID: "unknown-bus"), catalog: catalog))
    }

    // 깨짐: 카탈로그에 없는 출발 정류장을 허용하면 실패한다.
    func test19_init_알_수_없는_출발_정류장은_nil이다() {
        XCTAssertNil(CourseJourney(journey: snapshot(origin: "gone-stop"), catalog: catalog))
    }

    // MARK: 시안 노선선(지나온/남은 구간·지난 정류장)

    // 깨짐: 지나온·남은 구간이 버스 위치에서 끊기지 않거나, 지난 정류장 판정이 다음 정류장과 어긋나거나, 노선 종류가 빠지면 실패한다.
    func test20_노선선은_버스_위치에서_지나온_구간과_남은_구간으로_나뉜다() {
        let map = makeMap(elapsed: 450)  // 구간 1의 절반(구간 300초)
        let stops = forwardJourney.stops

        XCTAssertEqual(map.journey.routeKind, "지선")
        XCTAssertEqual(map.travelledPoints, [stops[0].point, stops[1].point, map.bus.point])
        XCTAssertEqual(map.remainingPoints, [map.bus.point] + stops[2...].map(\.point))
        XCTAssertEqual(stops.map(map.isPassed), [true, true, false, false, false, false])
    }
}
