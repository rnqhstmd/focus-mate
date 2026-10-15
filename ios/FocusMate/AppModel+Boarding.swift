import Foundation

/// 승차권 진입·승차 저장·여행 전환·출발 확인·메인 폐기. 저장은 최신 `snapshot`에서 `updating(journey:)`로 후보를 만들어 `save`로 한다.
/// 진행 여정은 최대 1건이다. 새 승차는 기존 값을 교체하고, 어떤 경로도 완료 기록(records)을 만들지 않는다.
extension AppModel {
    var activeJourney: JourneySnapshot? { snapshot?.journey.active }

    /// 준비를 확정하고 승차권을 연다. 미완성이면 이동하지 않는다. 연달아 눌러도 한 번만 쌓인다.
    @discardableResult
    func showBoardingPass() -> Bool {
        guard confirmPreparation() else { return false }
        if path.last != .board { open(.board) }
        return true
    }

    /// 승차권에서 승차 태그로 간다. 저장하지 않는다.
    @discardableResult
    func openBoarding() -> Bool {
        guard path.last == .board, confirmedPreparation != nil else { return false }
        open(.boarding)
        return true
    }

    /// 접촉 인식 순간 진행 여정을 저장한다. 실패하면 snapshot은 그대로이고 `saveFailure`가 남는다.
    func boardJourney() -> Bool {
        guard launchState == .ready(.main), let snapshot, let card = snapshot.currentCard,
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
        return save(snapshot.updating(journey: JourneySection(active: active.confirmingDeparture())))
    }

    /// 메인 '여행 시작하기'. 진행 여정이 있으면 기록 없이 정리한 뒤 시간 선택으로 간다(W07 이어가기 전 임시 동작).
    /// 정리 저장에 실패하면 이동하지 않는다 — 정리됐다고 믿은 채 새 여행을 시작하는 불일치를 막는다.
    @discardableResult
    func startTripFromMain() -> Bool {
        if let snapshot, snapshot.journey.active != nil {
            guard save(snapshot.updating(journey: .empty)) else { return false }
        }
        // 정리 직전에 인식된 승차가 뒤늦게 저장되지 않도록 확정값도 버린다.
        discardConfirmedPreparation()
        open(Destination.preparation.mainMenuTarget)
        return true
    }
}
