import Foundation

/// 앱 밖 표시의 한국어 문구. 남은 시간은 시스템 카운트다운(분:초)이라 앱 안 "N min"과 단위가 다르다(BR-7).
enum JourneyActivityDisplay {
    static let expiredText = "도착했어요"

    static func statusName(_ status: JourneyActivityStatus) -> String {
        switch status {
        case .running: "운행 중"
        case .paused: "일시정지"
        case .arrived: "도착"
        }
    }

    /// "M:SS". 분은 자릿수 제한이 없고 초는 두 자리다.
    static func pausedTime(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return "\(clamped / 60):" + String(format: "%02d", clamped % 60)
    }

    /// 운행 중에는 남은 시간을 넣지 않는다. 시스템 카운트다운 요소가 따로 읽힌다.
    static func accessibilityDescription(busNumber: String, busKind: String, destination: String,
                                         status: JourneyActivityStatus, pausedRemainingSeconds: Int?) -> String {
        let base = "\(busNumber)번 \(busKind) 버스, 도착지 \(destination), \(statusName(status))"
        guard status == .paused else { return base }
        let remaining = max(0, pausedRemainingSeconds ?? 0)
        return base + ", 남은 시간 \(remaining / 60)분 \(remaining % 60)초"
    }
}

/// 위젯의 시간 칸에 그릴 내용. 분기를 위젯 밖에 두어 단위 테스트한다.
enum JourneyActivityTimeContent: Equatable {
    /// 시스템 카운트다운(`Text(timerInterval:countsDown:)`) 범위.
    case countdown(ClosedRange<Date>)
    /// 정적 문자열(일시정지 "M:SS" 또는 만료 문구).
    case fixed(String)
}

extension JourneyActivityDisplay {
    /// 일시정지는 만료가 없으므로 stale이어도 멈춘 시간을 보여준다. 운행 중 범위의 하한은 종료 시각을 넘지 않는다(범위 트랩 방지).
    static func timeContent(state: JourneyActivityAttributes.ContentState, isStale: Bool, now: Date) -> JourneyActivityTimeContent {
        if state.status == .paused { return .fixed(pausedTime(seconds: state.pausedRemainingSeconds ?? 0)) }
        guard !isStale, state.status == .running, let endDate = state.endDate else { return .fixed(expiredText) }
        return .countdown(min(now, endDate)...endDate)
    }

    static func busTitle(busNumber: String, busKind: String) -> String { "\(busNumber) \(busKind)" }

    static func compactAccessibilityLabel(busNumber: String) -> String { "\(busNumber)번 버스" }

    /// 만료된 운행 중 카드는 도착으로 보인다. 일시정지는 만료가 없으므로 그대로다.
    static func displayStatus(state: JourneyActivityAttributes.ContentState, isStale: Bool) -> JourneyActivityStatus {
        state.status == .running && isStale ? .arrived : state.status
    }

    /// 카드 전체 설명. 만료된 운행 중 카드는 도착으로 읽는다.
    static func accessibilityLabel(attributes: JourneyActivityAttributes,
                                   state: JourneyActivityAttributes.ContentState, isStale: Bool) -> String {
        let status = displayStatus(state: state, isStale: isStale)
        return accessibilityDescription(busNumber: attributes.busNumber, busKind: attributes.busKind,
                                        destination: attributes.destinationName, status: status,
                                        pausedRemainingSeconds: state.pausedRemainingSeconds)
    }
}
