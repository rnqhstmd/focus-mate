import ActivityKit
import Foundation

/// 앱 밖 표시(잠금 화면·다이나믹 아일랜드)의 상태. 위젯 확장은 타이머 컨트롤러를 모르므로 따로 둔다.
enum JourneyActivityStatus: String, Codable, Hashable {
    case running, paused, arrived
}

/// 앱 밖 표시 데이터. 여행 구분자·버스·도착지와 시각·상태만 담는다(카드·할 일·태그·출발지 없음, FR-9).
struct JourneyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: JourneyActivityStatus
        /// 운행 중에만 있다. 시스템이 이 시각까지 카운트다운한다.
        var endDate: Date?
        /// 일시정지에만 있다. 멈춘 남은 초.
        var pausedRemainingSeconds: Int?
    }

    let journeyID: String
    let busNumber: String
    let busKind: String
    let destinationName: String
}
