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
    /// 카드는 한 요소로 읽힌다. 이어가기 버튼은 따로 읽힌다.
    var accessibilityLabel: String {
        [title, task, busText, remainingText, routeText].compactMap { $0 }.joined(separator: ", ")
    }

    init?(journey: JourneySnapshot) {
        guard let bus = journey.bus, let destination = journey.destinationName else { return nil }
        kind = journey.isArrived ? .arrived : .resumable
        title = kind == .arrived ? JourneyLifecycleText.arrivedTitle : JourneyLifecycleText.resumableTitle
        task = journey.task
        busText = "\(bus.kind) \(bus.number)"
        routeText = JourneyLifecycleText.route(tag: journey.tag.name, destination: destination)
        remainingText = kind == .arrived ? nil : JourneyLifecycleText.remaining(
            minutes: JourneyTimerDisplay.remainingMinutes(totalSeconds: journey.totalSeconds,
                                                          elapsedSeconds: journey.progress.elapsedSeconds))
    }
}
