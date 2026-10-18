import Foundation
import XCTest
@testable import FocusMate

final class JourneyMapStateTests: XCTestCase {
    private let seongsu = CoursePoint(latitude: 37.5446, longitude: 127.0559)

    // MARK: - 초기값

    // 깨짐: 초기 카메라/테마/정차역/시트 기본값 중 하나라도 바뀌면 실패
    func test1_AC13_초기값은_따라가기_일반지도_정차역표시_시트닫힘이다() {
        let state = JourneyMapState(status: .running)

        XCTAssertEqual(state.camera, .follow)
        XCTAssertEqual(state.theme, .dark)
        XCTAssertTrue(state.showsStops)
        XCTAssertFalse(state.isThemeSheetPresented)
        XCTAssertTrue(state.toolsEnabled)
    }

    // 깨짐: 도착 상태에서 도구를 잠그면 실패
    func test2_BR4_도착_상태로_시작하면_도구가_활성이다() {
        XCTAssertTrue(JourneyMapState(status: .arrived).toolsEnabled)
    }

    // MARK: - 카메라 모드

    // 깨짐: 사용자 이동이 explore로 전환하지 않으면 실패
    func test3_AC14_사용자가_지도를_움직이면_탐색_모드가_된다() {
        var state = JourneyMapState(status: .running)
        state.userMovedCamera()
        XCTAssertEqual(state.camera, .explore)
    }

    // 깨짐: 일시정지 중 이동을 무시하면 실패
    func test4_BR3_일시정지_중에도_사용자_이동은_탐색_모드가_된다() {
        var state = JourneyMapState(status: .paused)
        state.userMovedCamera()
        XCTAssertEqual(state.camera, .explore)
    }

    // 깨짐: followTapped가 follow 복귀/true 반환을 안 하면 실패
    func test5_AC15_탐색_모드에서_따라가기를_누르면_따라가기로_돌아가고_재정렬을_요청한다() {
        var state = JourneyMapState(status: .running)
        state.userMovedCamera()

        let needsRecenter = state.followTapped()

        XCTAssertEqual(state.camera, .follow)
        XCTAssertTrue(needsRecenter)
    }

    // 깨짐: follow에서 followTapped가 모드를 바꾸면 실패
    func test6_AC16_따라가기_모드에서_따라가기를_눌러도_따라가기가_유지된다() {
        var state = JourneyMapState(status: .running)
        state.followTapped()
        XCTAssertEqual(state.camera, .follow)
    }

    // 깨짐: 일시정지 중 followTapped가 동작하면 실패
    func test7_BR4_일시정지_중_따라가기_탭은_무시된다() {
        var state = JourneyMapState(status: .paused)
        state.userMovedCamera()

        let needsRecenter = state.followTapped()

        XCTAssertEqual(state.camera, .explore)
        XCTAssertFalse(needsRecenter)
    }

    // 깨짐: 상태 변경 시 카메라 모드를 건드리면 실패
    func test8_AC18_탐색_모드에서_일시정지_후_재개해도_탐색이_유지된다() {
        var state = JourneyMapState(status: .running)
        state.userMovedCamera()

        state.timerStatusChanged(.paused)
        state.timerStatusChanged(.running)

        XCTAssertEqual(state.camera, .explore)
    }

    // MARK: - 테마 시트

    // 깨짐: 일시정지 중 시트가 열리면 실패
    func test9_AC25_일시정지_중에는_테마_시트가_열리지_않는다() {
        var state = JourneyMapState(status: .paused)
        state.openThemeSheet()
        XCTAssertFalse(state.isThemeSheetPresented)
    }

    // 깨짐: leave가 시트를 닫지 않으면 실패
    func test10_AC23_시트가_열린_채_떠나면_시트가_닫힌다() {
        var state = JourneyMapState(status: .running)
        state.openThemeSheet()
        XCTAssertTrue(state.isThemeSheetPresented)

        state.leave()

        XCTAssertFalse(state.isThemeSheetPresented)
    }

    // 깨짐: 일시정지 시 시트/도구 잠금 또는 재개 시 해제가 빠지면 실패
    func test11_AC22_시트가_열린_채_일시정지되면_닫히고_도구가_잠기며_재개하면_풀린다() {
        var state = JourneyMapState(status: .running)
        state.openThemeSheet()

        state.timerStatusChanged(.paused)
        XCTAssertFalse(state.isThemeSheetPresented)
        XCTAssertFalse(state.toolsEnabled)

        state.timerStatusChanged(.running)
        XCTAssertTrue(state.toolsEnabled)
    }

    // 깨짐: 도착 시 시트가 닫히지 않거나 도구가 잠기면 실패
    func test12_AC24_시트가_열린_채_도착하면_닫히지만_도구는_활성이다() {
        var state = JourneyMapState(status: .running)
        state.openThemeSheet()

        state.timerStatusChanged(.arrived)

        XCTAssertFalse(state.isThemeSheetPresented)
        XCTAssertTrue(state.toolsEnabled)
    }

    // 깨짐: running 전환이 시트를 닫으면 실패
    func test13_running으로_바뀌어도_열린_시트는_유지된다() {
        var state = JourneyMapState(status: .running)
        state.openThemeSheet()

        state.timerStatusChanged(.running)

        XCTAssertTrue(state.isThemeSheetPresented)
    }

    // MARK: - 테마·정차역

    // 깨짐: select가 테마를 반영하지 않으면 실패
    func test14_AC20_테마를_선택하면_해당_테마로_바뀐다() {
        var state = JourneyMapState(status: .running)

        state.select(theme: .dark)
        XCTAssertEqual(state.theme, .dark)

        state.select(theme: .satellite)
        XCTAssertEqual(state.theme, .satellite)
    }

    // 깨짐: setShowsStops가 값을 반영하지 않으면 실패
    func test15_AC21_정차역_표시를_껐다_켤_수_있다() {
        var state = JourneyMapState(status: .running)

        state.setShowsStops(false)
        XCTAssertFalse(state.showsStops)

        state.setShowsStops(true)
        XCTAssertTrue(state.showsStops)
    }

    // MARK: - 카메라 정책

    private func target(heading: Double = 0, previous: Double? = nil, reduceMotion: Bool = false,
                        revision: Int = 1) -> JourneyCameraTarget {
        JourneyCameraPolicy.target(bus: seongsu, busHeading: heading, previousHeading: previous,
                                   reduceMotion: reduceMotion, revision: revision)
    }

    // 깨짐: 동작 줄이기에서 애니메이션하거나 진행 방위(heading-up)를 따르지 않으면 실패
    func test16_AC30_동작_줄이기_켜짐이면_애니메이션_없이_진행_방위로_바꾼다() {
        let t = target(heading: 120, reduceMotion: true, revision: 3)

        XCTAssertFalse(t.animated)
        XCTAssertEqual(t.headingDegrees, 120)
    }

    // 깨짐: reduceMotion false일 때 animated가 true가 아니면 실패
    func test17_AC31_동작_줄이기_꺼짐이면_애니메이션한다() {
        XCTAssertTrue(target(revision: 3).animated)
    }

    // 깨짐: pitch가 0 이하(평면)면 실패
    func test18_AC13_카메라는_기울어진_시점이다() {
        let t = target()
        XCTAssertGreaterThan(t.pitchDegrees, 0)
        XCTAssertEqual(t.pitchDegrees, JourneyCameraPolicy.pitchDegrees)
        XCTAssertEqual(t.distanceMeters, JourneyCameraPolicy.distanceMeters)
    }

    // 깨짐: focus/revision을 다른 값으로 전달하면 실패
    func test19_카메라_목표는_버스_위치와_리비전을_그대로_담는다() {
        let t = target(revision: 42)

        XCTAssertEqual(t.focus, seongsu)
        XCTAssertEqual(t.revision, 42)
    }

    // 깨짐: 카메라 방위가 버스 진행 방위가 아니면(북쪽 위 고정이면) 실패
    func test19a_heading_up_카메라_방위는_버스_진행_방위다() {
        XCTAssertEqual(target(heading: 75).headingDegrees, 75)
    }

    // 깨짐: 중심을 진행 방향 앞으로 옮기지 않으면(버스가 화면 가운데) 실패
    func test19b_카메라_중심은_진행_방향으로_앞서_버스가_화면_아래쪽에_온다() {
        let t = target(heading: 90)
        XCTAssertEqual(RouteShape.meters(t.focus, t.center), JourneyCameraPolicy.leadMeters, accuracy: 0.5)
        XCTAssertEqual(try XCTUnwrap(RouteShape.bearing(t.focus, t.center)), 90, accuracy: 0.5)
    }

    // 깨짐: 5° 미만 흔들림에도 지도가 돌면 실패
    func test19c_방위_변화가_5도_미만이면_직전_방위를_유지한다() {
        XCTAssertEqual(target(heading: 94, previous: 90).headingDegrees, 90)
        XCTAssertEqual(target(heading: 2, previous: 358).headingDegrees, 358)
        XCTAssertEqual(target(heading: 96, previous: 90).headingDegrees, 96)
    }

    // 깨짐: 350°→10°를 반대로(340° 회전) 돌면 실패
    func test19d_방위는_최단_각도로_이어_붙인다() {
        XCTAssertEqual(target(heading: 10, previous: 350).headingDegrees, 370)
        XCTAssertEqual(target(heading: 350, previous: 10).headingDegrees, -10)
        XCTAssertEqual(JourneyCameraPolicy.shortestDelta(from: 90, to: 270 + 1), -179)
    }

    // MARK: - 문구

    // 깨짐: 접근성 값 문구가 바뀌면 실패
    func test20_AC34_카메라_모드_접근성_값_문구는_정해진_한국어다() {
        XCTAssertEqual(JourneyMapDisplay.followValue(.follow), "따라가는 중")
        XCTAssertEqual(JourneyMapDisplay.followValue(.explore), "자유 탐색 중")
    }
}
