# T1 RED report

케이스 9건 (AC-26: 8, AC-30: 1)

실패 확인 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyActivityDisplayTests.swift

실패 메시지: error: cannot find type JourneyActivityStatus in scope / cannot find JourneyActivityDisplay in scope / cannot find JourneyActivityAttributes (컴파일 실패, 미존재 타입)

참조한 파일: ios/FocusMateTests/JourneyTimerDisplayTests.swift (스타일만)

## 테스트 코드
```swift
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
}
```
