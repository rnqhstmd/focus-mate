import Foundation

/// 출발 정류장을 다시 골라야 하는 이유(BR-13, BR-16, 옛 형식 이전).
enum StationResetReason: Equatable {
    case routeDataReplaced, stationRemoved

    var text: String {
        switch self {
        case .routeDataReplaced: "정류장 데이터가 서울 전체로 바뀌어 출발 정류장을 다시 골라 주세요"
        case .stationRemoved: "저장된 출발 정류장이 서울 버스 데이터에서 사라져 다시 골라 주세요"
        }
    }
}

/// 첫 출발지 저장과 시간·버스·도착지 선택. 저장은 최신 `snapshot`에서 `updating…`으로 후보를 만들어 `save`로 한다.
extension AppModel {
    var routeAvailability: RouteDataAvailability { routeData.availability }
    var routeCatalog: RouteCatalog? { routeData.catalog }

    /// 정류장 데이터를 백그라운드에서 읽는다. 끝나면 저장된 현재 정류장이 데이터에 없는지 한 번 확인한다(BR-16).
    @discardableResult
    func startRouteData() -> Task<Void, Never> {
        let loading = routeData.startLoading()
        return Task { [weak self] in
            await loading.value
            self?.resolveStationAfterRouteDataReady()
        }
    }

    /// 진행 여정이 없을 때만 본다. 진행 여정은 포기·새 여정에서 따로 정한다(BR-13).
    private func resolveStationAfterRouteDataReady() {
        guard let catalog = routeCatalog, let snapshot, snapshot.journey.active == nil,
              let station = snapshot.currentStation, catalog.stopIndex(id: station.id) == nil else { return }
        restartStationSelection(reason: .stationRemoved)
    }

    /// 정류장·여정을 비워 저장하고 최초 정류장 설정으로 보낸다. 카드·기록은 그대로다.
    @discardableResult
    func restartStationSelection(reason: StationResetReason) -> Bool {
        guard case .ready = launchState, let snapshot else { return false }
        guard saveHandlingFailure(snapshot.clearingStationsAndJourney()) else { return false }
        stationResetNotice = reason
        return true
    }

    /// 카탈로그가 준비됐고 현재 정류장이 그 안에 있을 때의 출발점.
    var journeyOrigin: RouteOrigin? {
        guard let catalog = routeCatalog, let station = snapshot?.currentStation,
              let index = catalog.stopIndex(id: station.id) else { return nil }
        return RouteOrigin(stopIndex: index, stopID: station.id, name: catalog.stops[index].name,
                           boundLabel: catalog.boundLabel(stopIndex: index))
    }

    /// 메인에 보이는 현재 정류장 방면. 로딩·실패·데이터에 없는 정류장이면 nil이다.
    var currentStationBound: String? { journeyOrigin?.boundLabel }

    var journeyCandidates: [RouteCandidate] {
        guard let catalog = routeCatalog, let origin = journeyOrigin else { return [] }
        return journeyPlan.candidates(origin: origin, catalog: catalog)
    }

    var journeyProceedState: ProceedState {
        switch routeAvailability {
        case .loading: return .routeDataLoading
        case .failed: return .routeDataFailed
        case let .ready(catalog):
            guard let origin = journeyOrigin else { return .originUnavailable }
            return journeyPlan.proceedState(origin: origin, catalog: catalog)
        }
    }

    @discardableResult
    func chooseJourneyRoute(_ routeID: String) -> Bool {
        guard let catalog = routeCatalog, let origin = journeyOrigin else { return false }
        return journeyPlan.choose(routeID: routeID, origin: origin, catalog: catalog)
    }

    var preparedJourney: JourneySelection? {
        if case let .ready(selection) = journeyProceedState { return selection }
        return nil
    }

    /// 최초 정류장 설정 화면에서만 한 번 저장한다. 성공하면 메인 위에 시간 선택을 연다.
    @discardableResult
    func confirmInitialStation(_ option: StopSearchOption) -> Bool {
        guard launchState == .ready(.initialStationEntry), let current = snapshot else { return false }
        let station = option.snapshot
        guard save(current.updatingStage(cardIssued: current.cardIssued,
                                         initialStation: station, currentStation: station)) else { return false }
        stationResetNotice = nil
        // 다른 정류장에서 고른 노선·시간이 새 출발지에 남지 않게 한다.
        journeyPlan = JourneyPlanDraft()
        path = [.time]
        return true
    }

    /// 선택이 끝났을 때만 준비 진입점을 연다. 연달아 눌러도 한 번만 쌓인다.
    @discardableResult
    func proceedToPreparation() -> Bool {
        guard preparedJourney != nil else { return false }
        if path.last != .preparation { open(.preparation) }
        return true
    }
}

extension Destination {
    static var mainMenu: [Destination] { [.preparation, .records, .settings, .profile] }

    /// 메인 "여행 시작하기"는 시간 선택을 거쳐 준비로 간다.
    var mainMenuTarget: Destination { self == .preparation ? .time : self }

    /// 메인 버튼 글자. 준비 목적지의 화면 제목("여행 준비")과 따로 둔다.
    var mainMenuTitle: String { self == .preparation ? "여행 시작하기" : title }
}
