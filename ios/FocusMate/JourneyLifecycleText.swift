import Foundation

/// W07 포기·이어가기·새 여정 문구. 웹 프로토타입 원문을 따른다(PRD FR-1~6, FR-12).
enum JourneyLifecycleText {
    static let resumableTitle = "잠시 멈춘 여정이 있어요."
    static let arrivedTitle = "마지막 태그가 남았어요."
    /// 도착 카드 버스 줄 오른쪽 상태(시안 R34).
    static let awaitingAlightTag = "하차 태그 대기"
    static func remaining(minutes: Int) -> String { JourneyTimerDisplay.text(minutes: minutes) + " 남음" }
    static func route(tag: String, destination: String) -> String { "\(tag) · \(destination)까지" }
    static let resumeButton = "이전 여정 이어가기 →"
    /// 낭독에서는 화살표를 읽지 않는다.
    static let resumeButtonLabel = "이전 여정 이어가기"
    static let newJourneyButton = "새 여정 시작"
    /// 도착 여정 카드의 하차 동작. 시안 R34대로 이어가기와 같은 문구를 보이고, 누르면 하차 흐름으로 간다(W09).
    static let alightButton = resumeButton
    static let alightButtonLabel = resumeButtonLabel

    static let newJourneyTitle = "새 여정을 시작할까요?"
    static let newJourneyMessage = "이전 여정은 그만두고 새 여행을 준비해요. 완료 기록은 남기지 않아요."
    static let keepJourney = "이전 여정 유지하기"

    static let abandonTitle = "여행을 그만둘까요?"
    static let abandonMessage = "지금 도달한 정류장에서 다음 여행을 시작할 수 있어요. 완료 기록은 남기지 않습니다."
    /// 확인 창(R16)은 두 문장을 줄을 나눠 보인다. 낭독은 `abandonMessage` 그대로다.
    static let abandonMessageLines = "지금 도달한 정류장에서 다음 여행을 시작할 수 있어요.\n완료 기록은 남기지 않습니다."
    static let continueTrip = "계속 여행"
    static let quitTrip = "그만두기"
    static let abandonButton = "포기하기"
    static func abandonNotice(stationName: String) -> String {
        "\(stationName)에서 여행을 마쳤어요. 완료 기록은 남기지 않았어요."
    }

    static let resumeAnnouncement = "이전 여정을 남은 시간부터 이어갑니다."
    static let saveFailure = JourneyTimerDisplay.transitionFailureText
}
