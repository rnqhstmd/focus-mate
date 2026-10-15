import Foundation
import XCTest
@testable import FocusMate

/// 라이브 액티비티 한국어 문구(AC-26)와 표시 데이터 최소화(AC-30). 기댓값은 PRD가 정한 리터럴이다.
final class JourneyActivityDisplayTests: XCTestCase {
    private func accessibilityText(
        status: JourneyActivityStatus, paused: Int? = nil
    ) -> String {
        JourneyActivityDisplay.accessibilityDescription(
            busNumber: "343", busKind: "간선", destination: "서울역",
            status: status, pausedRemainingSeconds: paused
        )
    }

    // 깨짐: 상태 이름 문구가 바뀌거나 case가 서로 뒤바뀌면 실패한다.
    func testV15_AC26_세_상태의_이름이_정해진_문구다() {
        XCTAssertEqual(JourneyActivityDisplay.statusName(.running), "운행 중")
        XCTAssertEqual(JourneyActivityDisplay.statusName(.paused), "일시정지")
        XCTAssertEqual(JourneyActivityDisplay.statusName(.arrived), "도착")
    }

    // 깨짐: 만료 안내 문구가 "도착했어요"와 달라지면 실패한다.
    func testV15_AC26_만료_안내_문구는_도착했어요다() {
        XCTAssertEqual(JourneyActivityDisplay.expiredText, "도착했어요")
    }

    // 깨짐: 분:초 계산·0 패딩이 틀리면(3000, 65, 0, 3600) 실패한다.
    func testV15_AC26_일시정지_시간은_분_콜론_초_형식이다() {
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 3000), "50:00")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 65), "1:05")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 0), "0:00")
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: 3600), "60:00")
    }

    // 깨짐: 음수를 0으로 보정하지 않으면 "-1:-5" 등이 나와 실패한다.
    func testV15_AC26_음수_초는_0으로_표기한다() {
        XCTAssertEqual(JourneyActivityDisplay.pausedTime(seconds: -5), "0:00")
    }

    // 깨짐: 번호·종류·도착지·상태 조합 문구 형식이 바뀌면 실패한다.
    func testV15_AC26_운행_중_접근성_설명() {
        XCTAssertEqual(accessibilityText(status: .running), "343번 간선 버스, 도착지 서울역, 운행 중")
    }

    // 깨짐: 남은 시간을 "분 초"로 풀어쓰지 않거나 3000초를 50분 0초로 계산하지 못하면 실패한다.
    func testV15_AC26_일시정지_3000초_접근성_설명() {
        XCTAssertEqual(
            accessibilityText(status: .paused, paused: 3000),
            "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 50분 0초"
        )
    }

    // 깨짐: 65초를 1분 5초가 아닌 형식(예: 01분 05초, 65초)으로 쓰면 실패한다.
    func testV15_AC26_일시정지_65초_접근성_설명() {
        XCTAssertEqual(
            accessibilityText(status: .paused, paused: 65),
            "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 1분 5초"
        )
    }

    // 깨짐: 도착 상태에도 남은 시간 문구를 붙이면 실패한다.
    func testV15_AC26_도착_접근성_설명() {
        XCTAssertEqual(accessibilityText(status: .arrived), "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: 모델에 카드 id·이름·할 일·태그·소리·출발지·progress 같은 필드를 추가하거나 7개 중 하나를 빼면 실패한다.
    func testV15_AC30_표시_데이터_모델_필드는_정확히_7가지다() {
        let attributes = JourneyActivityAttributes(
            journeyID: "j-1", busNumber: "343", busKind: "간선", destinationName: "서울역"
        )
        let state = JourneyActivityAttributes.ContentState(
            status: .running, endDate: nil, pausedRemainingSeconds: nil
        )
        let labels = Set(Mirror(reflecting: attributes).children.compactMap(\.label))
            .union(Mirror(reflecting: state).children.compactMap(\.label))
        XCTAssertEqual(
            labels,
            ["journeyID", "busNumber", "busKind", "destinationName",
             "status", "endDate", "pausedRemainingSeconds"]
        )
    }

    // MARK: - T8 위젯 시간 콘텐츠 / 접근성 라벨

    private let widgetNow = Date(timeIntervalSince1970: 1_791_882_000)

    private func widgetState(
        _ status: JourneyActivityStatus, endDate: Date? = nil, paused: Int? = nil
    ) -> JourneyActivityAttributes.ContentState {
        JourneyActivityAttributes.ContentState(
            status: status, endDate: endDate, pausedRemainingSeconds: paused
        )
    }

    private var widgetAttributes: JourneyActivityAttributes {
        JourneyActivityAttributes(
            journeyID: "j-1", busNumber: "343", busKind: "간선", destinationName: "서울역"
        )
    }

    // 깨짐: 일시정지에서 남은 초를 "M:SS"로 고정 표기하지 않으면 실패한다.
    func testV15_위젯_일시정지는_고정_분초_문자열이다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.paused, paused: 3000), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("50:00"))
    }

    // 깨짐: stale을 paused보다 먼저 검사해 만료 문구를 내면 실패한다.
    func testV15_위젯_stale이어도_일시정지가_우선한다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.paused, paused: 3000), isStale: true, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("50:00"))
    }

    // 깨짐: stale 운행을 카운트다운으로 두면 실패한다.
    func testV15_위젯_stale_운행은_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: true, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: arrived인데 카운트다운을 내면 실패한다.
    func testV15_위젯_도착_상태는_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.arrived), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: 범위 시작을 now가 아닌 값으로 잡거나 endDate를 틀리게 쓰면 실패한다.
    func testV15_위젯_운행_중은_지금부터_종료까지_카운트다운이다() {
        let end = widgetNow.addingTimeInterval(3000)
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: end), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .countdown(widgetNow...end))
    }

    // 깨짐: now > endDate로 ClosedRange를 만들어 트랩하거나 범위를 보정하지 않으면 실패한다.
    func testV15_위젯_종료시각이_과거여도_트랩_없이_종료시각_범위다() {
        let end = widgetNow.addingTimeInterval(-10)
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running, endDate: end), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .countdown(end...end))
    }

    // 깨짐: endDate가 없을 때 카운트다운을 만들려 하거나 빈 문자열을 내면 실패한다.
    func testV15_위젯_운행_중인데_종료시각이_없으면_만료_문구다() {
        let content = JourneyActivityDisplay.timeContent(
            state: widgetState(.running), isStale: false, now: widgetNow
        )
        XCTAssertEqual(content, .fixed("도착했어요"))
    }

    // 깨짐: 일시정지 라벨에 남은 시간 문구가 빠지면 실패한다.
    func testV15_위젯_일시정지_접근성_라벨은_남은_시간을_읽는다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.paused, paused: 3000), isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 50분 0초")
    }

    // 깨짐: stale이 일시정지 라벨을 "도착"으로 덮으면 실패한다.
    func testV15_위젯_stale이어도_일시정지_접근성_라벨은_같다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.paused, paused: 3000), isStale: true
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 일시정지, 남은 시간 50분 0초")
    }

    // 깨짐: stale 운행이 "운행 중"으로 읽히면 실패한다.
    func testV15_위젯_stale_접근성_라벨은_도착이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes,
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: true
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: arrived가 "도착"으로 읽히지 않으면 실패한다.
    func testV15_위젯_도착_상태_접근성_라벨은_도착이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes, state: widgetState(.arrived), isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 도착")
    }

    // 깨짐: 정상 운행 라벨이 "운행 중"이 아니면 실패한다.
    func testV15_위젯_운행_중_접근성_라벨은_운행_중이다() {
        let label = JourneyActivityDisplay.accessibilityLabel(
            attributes: widgetAttributes,
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)),
            isStale: false
        )
        XCTAssertEqual(label, "343번 간선 버스, 도착지 서울역, 운행 중")
    }

    // MARK: - 리뷰 fix R1: 위젯 리터럴을 순수 함수로 이동

    // 깨짐: 번호와 종류 순서·구분 공백이 바뀌면 실패한다.
    func testV15_위젯_카드_제목은_번호_공백_종류다() {
        XCTAssertEqual(JourneyActivityDisplay.busTitle(busNumber: "343", busKind: "간선"), "343 간선")
    }

    // 깨짐: "번 버스" 접미 문구가 바뀌면 실패한다.
    func testV15_위젯_축약_접근성_라벨은_번호번_버스다() {
        XCTAssertEqual(JourneyActivityDisplay.compactAccessibilityLabel(busNumber: "343"), "343번 버스")
    }

    // 깨짐: stale 운행을 운행 중으로 두면 실패한다.
    func testV15_위젯_stale_운행의_표시_상태는_도착이다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)), isStale: true
        )
        XCTAssertEqual(status, .arrived)
    }

    // 깨짐: 정상 운행을 도착으로 바꾸면 실패한다.
    func testV15_위젯_정상_운행의_표시_상태는_운행_중이다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.running, endDate: widgetNow.addingTimeInterval(3000)), isStale: false
        )
        XCTAssertEqual(status, .running)
    }

    // 깨짐: stale이 일시정지를 덮어쓰면 실패한다.
    func testV15_위젯_stale_일시정지의_표시_상태는_일시정지다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.paused, paused: 3000), isStale: true
        )
        XCTAssertEqual(status, .paused)
    }

    // 깨짐: 일시정지를 다른 상태로 바꾸면 실패한다.
    func testV15_위젯_정상_일시정지의_표시_상태는_일시정지다() {
        let status = JourneyActivityDisplay.displayStatus(
            state: widgetState(.paused, paused: 3000), isStale: false
        )
        XCTAssertEqual(status, .paused)
    }

    // 깨짐: 도착 상태를 그대로 두지 않으면 실패한다.
    func testV15_위젯_도착_상태의_표시_상태는_도착이다() {
        let status = JourneyActivityDisplay.displayStatus(state: widgetState(.arrived), isStale: false)
        XCTAssertEqual(status, .arrived)
    }
}
