import Foundation

/// 타이머 컨트롤러가 진도를 저장하는 경계. AppModel이 채택한다.
@MainActor
protocol JourneyProgressSaving: AnyObject {
    func saveJourneyProgress(journeyID: String, elapsedSeconds: Int, paused: Bool) -> Bool
}

/// 타이머 진도 저장. 컨트롤러가 런타임 진도의 주인이고, 모델은 마지막으로 저장에 성공한 값을 갖는다.
extension AppModel {
    var hasDepartedJourney: Bool { activeJourney?.phase == .departed }

    /// 출발한 같은 여정에만 쓴다. 범위 밖 값은 저장 검증이 거부한다. 기록(records)은 건드리지 않는다.
    func saveJourneyProgress(journeyID: String, elapsedSeconds: Int, paused: Bool) -> Bool {
        guard launchState == .ready(.main), let snapshot, let active = snapshot.journey.active,
              active.id == journeyID, active.phase == .departed else { return false }
        let candidate = active.updatingProgress(elapsedSeconds: elapsedSeconds, paused: paused)
        return save(snapshot.updating(journey: JourneySection(active: candidate)))
    }
}
