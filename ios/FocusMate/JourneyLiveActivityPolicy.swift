import Foundation

/// 앱 밖 표시에 보낼 내용. 게이트웨이 입력이자 기록기의 기록 단위다.
struct JourneyActivityRequest: Equatable {
    let state: JourneyActivityAttributes.ContentState
    let staleDate: Date?
}

/// 시스템에 남아 있는 앱 밖 표시 하나.
struct LiveActivityHandle: Equatable {
    let id: String
    let journeyID: String
}

/// 앱 시작 때 남은 표시를 맞추는 계획. 끝낼 표시와 일시정지로 맞출 표시(최대 1개).
struct JourneyLaunchPlan: Equatable {
    struct PausedUpdate: Equatable {
        let id: String
        let request: JourneyActivityRequest
    }

    let endIDs: [String]
    let pausedUpdate: PausedUpdate?
}

/// 앱 밖 표시 규칙. 진도는 계산하지 않고 타이머가 준 남은 초만 쓴다(앱 시작 정리만 저장값에서 남은 초를 구한다).
enum JourneyLiveActivityPolicy {
    /// 도착지는 저장된 이름을 그대로 쓴다(지도 일관성 규칙과 무관, AC-31). 버스·도착지를 모르면 표시하지 않는다.
    static func attributes(for journey: JourneySnapshot) -> JourneyActivityAttributes? {
        guard let bus = journey.bus, let destination = journey.destinationName else { return nil }
        return JourneyActivityAttributes(journeyID: journey.id, busNumber: bus.number, busKind: bus.kind,
                                         destinationName: destination)
    }

    /// 운행 중은 종료 시각에 만료되고, 일시정지는 만료가 없다(BR-5). 도착은 종료 대상이라 요청이 없다.
    static func request(status: JourneyTimerController.Status, remainingSeconds: Int, now: Date) -> JourneyActivityRequest? {
        switch status {
        case .running:
            let endDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
            return JourneyActivityRequest(state: .init(status: .running, endDate: endDate, pausedRemainingSeconds: nil),
                                          staleDate: endDate)
        case .paused: return pausedRequest(remainingSeconds: remainingSeconds)
        case .arrived: return nil
        }
    }

    static func pausedRequest(remainingSeconds: Int) -> JourneyActivityRequest {
        JourneyActivityRequest(state: .init(status: .paused, endDate: nil, pausedRemainingSeconds: max(0, remainingSeconds)),
                               staleDate: nil)
    }

    /// 화면 진입: 같은 여행의 첫 표시는 다시 쓰고, 나머지는 끝낸다.
    static func appearPlan(existing: [LiveActivityHandle], journeyID: String) -> (reuseID: String?, endIDs: [String]) {
        let reuseID = existing.first { $0.journeyID == journeyID }?.id
        return (reuseID, existing.map(\.id).filter { $0 != reuseID })
    }

    /// 앱 시작: 출발·미도착 여행만 남은 표시 1개를 일시정지로 맞춘다(재실행하면 진행 중 여행은 일시정지로 읽힌다).
    static func launchPlan(existing: [LiveActivityHandle], journey: JourneySnapshot?) -> JourneyLaunchPlan {
        guard let journey, journey.phase == .departed, !journey.isArrived else {
            return JourneyLaunchPlan(endIDs: existing.map(\.id), pausedUpdate: nil)
        }
        let (reuseID, endIDs) = appearPlan(existing: existing, journeyID: journey.id)
        let remaining = journey.totalSeconds - journey.progress.elapsedSeconds
        return JourneyLaunchPlan(endIDs: endIDs,
                                 pausedUpdate: reuseID.map { .init(id: $0, request: pausedRequest(remainingSeconds: remaining)) })
    }
}
