import Foundation

/// 여행 화면 한 세션의 앱 밖 표시 동기화. 타이머 알림을 받아 시작·갱신·종료를 요청한다.
/// 저장자·타이머를 갖지 않으므로 표시 때문에 진도나 저장이 바뀔 경로가 없다(BR-6).
@MainActor
final class JourneyLiveActivitySync: JourneyTimerObserving {
    /// 같은 상태가 반복되면 다시 보내지 않는다. 운행 중 종료 시각은 호출 시각에 따라 달라지는 파생값이라 비교하지 않는다.
    private struct SentKey: Equatable {
        let status: JourneyActivityStatus
        let pausedRemainingSeconds: Int?
    }

    private let totalSeconds: Int
    private let attributes: JourneyActivityAttributes
    private let gateway: LiveActivityGateway
    private let now: @MainActor () -> Date
    private var activityID: String?
    private var didReconcile = false
    /// 시작이 거부되면 이 화면 세션에서는 다시 요청하지 않는다(FR-7).
    private var startFailed = false
    private var lastSent: SentKey?

    init(journey: JourneySnapshot, gateway: LiveActivityGateway, now: @escaping @MainActor () -> Date = { Date() }) {
        totalSeconds = journey.totalSeconds
        attributes = JourneyLiveActivityPolicy.attributes(for: journey)
        self.gateway = gateway
        self.now = now
    }

    func timerDidChange(status: JourneyTimerController.Status, remainingSeconds: Int) {
        reconcileOnce()
        guard !startFailed else { return }
        guard let request = JourneyLiveActivityPolicy.request(status: status, remainingSeconds: remainingSeconds, now: now(), totalSeconds: totalSeconds) else {
            if let activityID { gateway.end(id: activityID) }
            activityID = nil
            return
        }
        let key = SentKey(status: request.state.status, pausedRemainingSeconds: request.state.pausedRemainingSeconds)
        if let activityID {
            guard key != lastSent else { return }
            gateway.update(id: activityID, request: request)
        } else {
            activityID = gateway.start(attributes: attributes, request: request)
            startFailed = activityID == nil
        }
        lastSent = key
    }

    /// 이전 실행이 남긴 표시를 한 번만 맞춘다. 같은 여행의 첫 표시는 다시 쓰고(갱신), 나머지는 끝낸다.
    private func reconcileOnce() {
        guard !didReconcile else { return }
        didReconcile = true
        let plan = JourneyLiveActivityPolicy.appearPlan(existing: gateway.activeActivities, journeyID: attributes.journeyID)
        plan.endIDs.forEach(gateway.end(id:))
        activityID = plan.reuseID
    }
}
