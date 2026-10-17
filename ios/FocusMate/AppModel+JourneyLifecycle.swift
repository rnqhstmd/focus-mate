import Foundation

/// W07 이어가기·새 여정·포기. 각 동작은 한 번만 저장하고, 실패하면 아무것도 바꾸지 않은 채 `.saveFailed`를 돌려준다(BR-4, BR-7).
/// 연타는 시간이 아니라 상태(path·active)로 막는다(BR-8).
extension AppModel: JourneyAbandoning {
    var activeJourneyCard: ActiveJourneyCardContent? { activeJourney.map(ActiveJourneyCardContent.init(journey:)) }

    var mainStartTitle: String {
        activeJourney == nil ? Destination.preparation.mainMenuTitle : JourneyLifecycleText.newJourneyButton
    }

    /// 출발한 여정은 (저장 경과, 진행 중)으로 저장한 뒤 바로 흐르게 연다. 출발 대기는 저장 없이 출발 안내부터 다시 연다.
    @discardableResult
    func resumeJourney() -> LifecycleActionResult {
        guard launchState == .ready(.main), path.isEmpty, let snapshot, let active = snapshot.journey.active,
              !active.isArrived else { return .rejected }
        if active.phase == .departed {
            let running = active.updatingProgress(elapsedSeconds: active.progress.elapsedSeconds, paused: false)
            guard saveHandlingFailure(snapshot.updating(journey: JourneySection(active: running))) else { return .saveFailed }
            resumeEntryJourneyID = active.id
        }
        open(.journey)
        return .done
    }

    /// 이어가기로 연 같은 여정이면 한 번만 true를 돌려준다. 타이머 자동 진행·낭독의 근거다.
    func consumeResumeEntry(journeyID: String) -> Bool {
        guard resumeEntryJourneyID == journeyID else { return false }
        resumeEntryJourneyID = nil
        return true
    }

    /// 정류장 데이터를 읽는 중에는 도달 정류장을 정할 수 없어 포기·새 여정을 막는다(AC-43, AC-44).
    var canEndActiveJourney: Bool { routeAvailability != .loading }

    /// 메인 '새 여정 시작' 확정. 도달 정류장을 현재 정류장으로 두고 여정을 지운 뒤 시간 선택으로 간다.
    /// 도착한 여정도 시안 R34대로 새 여정으로 끝낼 수 있다(AC-21 시안 우선 변경). 도달 정류장은 도착 정류장이고 기록은 남기지 않는다.
    @discardableResult
    func confirmNewJourney() -> LifecycleActionResult {
        guard launchState == .ready(.main), path.isEmpty, let snapshot, let active = snapshot.journey.active,
              case let .resolved(resolution) = active.reachedStation(in: routeAvailability)
        else { return .rejected }
        guard let station = resolution.station else {
            // 정리 직전에 인식된 승차가 뒤늦게 저장되지 않도록 확정값도 버린다.
            guard restartStationSelection(reason: .stationRemoved) else { return .saveFailed }
            discardConfirmedPreparation()
            return .done
        }
        guard saveHandlingFailure(snapshot.endingActiveJourney(at: station)) else { return .saveFailed }
        discardConfirmedPreparation()
        open(Destination.preparation.mainMenuTarget)
        return .done
    }

    /// 일시정지 중인 출발 후 여정만 포기한다(BR-6). 도달 정류장은 마지막으로 저장된 경과로 정한다(BR-1).
    @discardableResult
    func abandonJourney(timerPaused: Bool) -> LifecycleActionResult {
        guard timerPaused, launchState == .ready(.main), path.last == .journey, let snapshot,
              let active = snapshot.journey.active, active.phase == .departed, !active.isArrived,
              case let .resolved(resolution) = active.reachedStation(in: routeAvailability) else { return .rejected }
        guard let station = resolution.station else {
            guard restartStationSelection(reason: .stationRemoved) else { return .saveFailed }
            abandonNotice = nil
            return .done
        }
        guard saveHandlingFailure(snapshot.endingActiveJourney(at: station)) else { return .saveFailed }
        path = []
        abandonNotice = station.name
        return .done
    }
}
