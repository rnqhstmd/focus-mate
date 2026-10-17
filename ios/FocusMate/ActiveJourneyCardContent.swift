import Foundation

/// 메인 진행 여정 카드에 보일 값. 도착한 여정은 이어가기 대신 하차하기만 보인다.
struct ActiveJourneyCardContent: Equatable {
    enum Kind: Equatable { case resumable, arrived }

    let kind: Kind
    let title: String
    let task: String
    let busText: String
    let routeText: String
    let remainingText: String?

    var showsResume: Bool { kind == .resumable }
    /// 도착한 여정의 유일한 동작은 하차다(W09 FR-8).
    var showsAlight: Bool { kind == .arrived }
    /// 버스 줄 오른쪽 상태. 도착 여정은 "하차 태그 대기"(시안 R34), 멈춘 여정은 남은 시간(시안 R31).
    var statusText: String? { kind == .arrived ? JourneyLifecycleText.awaitingAlightTag : remainingText }
    /// 카드는 한 요소로 읽힌다. 이어가기 버튼은 따로 읽힌다.
    var accessibilityLabel: String {
        [title, task, busText, statusText, routeText].compactMap { $0 }.joined(separator: ", ")
    }

    init(journey: JourneySnapshot) {
        kind = journey.isArrived ? .arrived : .resumable
        title = kind == .arrived ? JourneyLifecycleText.arrivedTitle : JourneyLifecycleText.resumableTitle
        task = journey.task
        busText = "\(journey.busKind) \(journey.busNumber)"
        routeText = JourneyLifecycleText.route(tag: journey.tag.name, destination: journey.destinationName)
        remainingText = kind == .arrived ? nil : JourneyLifecycleText.remaining(
            minutes: JourneyTimerDisplay.remainingMinutes(totalSeconds: journey.totalSeconds,
                                                          elapsedSeconds: journey.progress.elapsedSeconds))
    }
}
