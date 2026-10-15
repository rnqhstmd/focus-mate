import Foundation

/// 앱 시작 때 이전 실행이 남긴 앱 밖 표시를 저장 상태에 맞춘다. 새로 시작하지는 않는다.
@MainActor
enum JourneyLiveActivityCleanup {
    static func atLaunch(gateway: LiveActivityGateway, journey: JourneySnapshot?) {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: gateway.activeActivities, journey: journey)
        plan.endIDs.forEach(gateway.end(id:))
        if let update = plan.pausedUpdate { gateway.update(id: update.id, request: update.request) }
    }
}
