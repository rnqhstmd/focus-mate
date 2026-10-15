import Foundation

/// 첫 출발지 저장과 시간·버스·도착지 선택. 저장은 최신 `snapshot`에서 `updating…`으로 후보를 만들어 `save`로 한다.
extension AppModel {
    var journeyOrigin: StopPosition? {
        snapshot?.currentStation.flatMap(RouteStops.position(of:))
    }

    var journeyCandidates: [JourneyCandidate] {
        journeyOrigin.map(journeyPlan.candidates(from:)) ?? []
    }

    var journeyProceedState: ProceedState {
        journeyOrigin.map(journeyPlan.proceedState(from:)) ?? .originUnavailable
    }

    var preparedJourney: JourneySelection? {
        if case let .ready(selection) = journeyProceedState { return selection }
        return nil
    }

    /// 최초 정류장 설정 화면에서만 한 번 저장한다. 성공하면 메인 위에 시간 선택을 연다.
    @discardableResult
    func confirmInitialStation(_ option: StationOption) -> Bool {
        guard launchState == .ready(.initialStationEntry), let current = snapshot else { return false }
        let station = option.snapshot
        guard save(current.updatingStage(cardIssued: current.cardIssued,
                                         initialStation: station, currentStation: station)) else { return false }
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
