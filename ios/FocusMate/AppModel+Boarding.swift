import Foundation

/// 승차권 진입·승차 저장·여행 전환·출발 확인·메인 폐기. 저장은 최신 `snapshot`에서 `updating(journey:)`로 후보를 만들어 `save`로 한다.
/// 진행 여정은 최대 1건이다. 새 승차는 기존 값을 교체하고, 어떤 경로도 완료 기록(records)을 만들지 않는다.
extension AppModel {
    var activeJourney: JourneySnapshot? { snapshot?.journey.active }

    /// 준비를 확정하고 승차권을 연다. 미완성이면 이동하지 않는다. 연달아 눌러도 한 번만 쌓인다.
    @discardableResult
    func showBoardingPass() -> Bool {
        // 출발한 여정은 재승차로 덮어쓰지 않는다(확정값도 건드리지 않는다).
        guard !hasDepartedJourney, confirmPreparation() else { return false }
        if path.last != .board { open(.board) }
        return true
    }

    /// 승차권에서 승차 태그로 간다. 저장하지 않는다.
    @discardableResult
    func openBoarding() -> Bool {
        guard path.last == .board, confirmedPreparation != nil, !hasDepartedJourney else { return false }
        open(.boarding)
        return true
    }

    /// 접촉 인식 순간 진행 여정을 저장한다. 실패하면 snapshot은 그대로이고 `saveFailure`가 남는다.
    func boardJourney() -> Bool {
        guard launchState == .ready(.main), !hasDepartedJourney, let snapshot, let card = snapshot.currentCard,
              let details = boardingDetails else { return false }
        let journey = journeyFactory.make(details: details, cardID: card.id)
        return save(snapshot.updating(journey: JourneySection(active: journey)))
    }

    /// 인식 연출이 끝나면 승차 태그·승차권·준비·시간 선택을 경로에서 지우고 여행만 남긴다. 뒤로가기는 메인으로 간다.
    func finishBoardingTransition() {
        guard path.last == .boarding, activeJourney != nil else { return }
        path = [.journey]
    }

    /// 출발 안내의 '시작'. 이미 출발 확인됐으면 쓰지 않는다.
    @discardableResult
    func confirmDeparture() -> Bool {
        guard let snapshot, let active = snapshot.journey.active else { return false }
        guard active.phase == .awaitingDeparture else { return true }
        guard save(snapshot.updating(journey: JourneySection(active: active.confirmingDeparture()))) else { return false }
        // 재승차의 근원인 남은 확정값을 출발과 함께 정리한다.
        discardConfirmedPreparation()
        return true
    }

    /// 메인 '여행 시작하기'. 진행 여정이 있으면 거부한다 — 여정 정리는 확인을 거친 `confirmNewJourney`만 한다(W07).
    @discardableResult
    func startTripFromMain() -> Bool {
        guard snapshot?.journey.active == nil else { return false }
        // 남아 있던 확정값으로 뒤늦게 승차가 저장되지 않도록 버린다.
        discardConfirmedPreparation()
        open(Destination.preparation.mainMenuTarget)
        return true
    }
}
