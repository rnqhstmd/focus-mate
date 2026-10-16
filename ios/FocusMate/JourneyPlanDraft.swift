import Foundation

/// 시간 선택의 출발점. 카탈로그 정류장 색인과 승차 시점 이름을 함께 둔다.
struct RouteOrigin: Equatable {
    let stopIndex: Int
    let stopID: String
    let name: String
    let boundLabel: String?
}

/// 준비 진입점에 넘기는 여정 선택(용어 사전의 "여정 선택"). 저장하지 않는다.
struct JourneySelection: Equatable {
    let originStopID: String
    let originName: String
    let boundLabel: String?
    let minutes: Int
    /// 노선 id(`RouteCandidate.routeID`).
    let busID: String
    let busNumber: String
    let busKind: String
    let destinationStopID: String
    let destination: String
    let stops: Int
    let distanceMeters: Int
}

enum ProceedState: Equatable {
    case routeDataLoading, routeDataFailed, originUnavailable, noCandidates, needsSelection, ready(JourneySelection)

    var title: String {
        switch self {
        case .routeDataLoading: "정류장 정보를 불러오는 중이에요"
        case .routeDataFailed: "정류장 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요"
        case .originUnavailable: "출발 정류장을 확인할 수 없어요"
        case .noCandidates: "이 시간에 맞는 버스가 없어요"
        case .needsSelection: "버스와 도착지를 선택하세요"
        case .ready: "이 여정 준비하기"
        }
    }

    var isEnabled: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// 시간 선택 화면의 상태. 앱 실행 중 메모리에만 둔다.
struct JourneyPlanDraft: Equatable {
    private(set) var minutes: Int = JourneyPlanner.initialMinutes
    private(set) var selectedRouteID: String?

    /// 범위 안으로 맞춘 값이 실제로 바뀌면 같은 노선이 새 시간에도 후보여도 선택을 해제한다.
    mutating func setMinutes(_ value: Int) {
        let clamped = JourneyPlanner.clamp(value)
        guard clamped != minutes else { return }
        minutes = clamped
        selectedRouteID = nil
    }

    mutating func choose(routeID: String, origin: RouteOrigin, catalog: RouteCatalog) -> Bool {
        guard candidates(origin: origin, catalog: catalog).contains(where: { $0.routeID == routeID }) else { return false }
        selectedRouteID = routeID
        return true
    }

    func candidates(origin: RouteOrigin, catalog: RouteCatalog) -> [RouteCandidate] {
        RouteCandidates.candidates(minutes: minutes, originStop: origin.stopIndex, in: catalog)
    }

    func selectedCandidate(origin: RouteOrigin, catalog: RouteCatalog) -> RouteCandidate? {
        candidates(origin: origin, catalog: catalog).first { $0.routeID == selectedRouteID }
    }

    func proceedState(origin: RouteOrigin, catalog: RouteCatalog) -> ProceedState {
        let candidates = candidates(origin: origin, catalog: catalog)
        if let candidate = candidates.first(where: { $0.routeID == selectedRouteID }) {
            return .ready(JourneySelection(
                originStopID: origin.stopID, originName: origin.name, boundLabel: origin.boundLabel,
                minutes: minutes, busID: candidate.routeID, busNumber: candidate.busNumber, busKind: candidate.busKind,
                destinationStopID: candidate.destinationStopID, destination: candidate.destination,
                stops: candidate.stops, distanceMeters: candidate.leg.distanceMeters))
        }
        return candidates.isEmpty ? .noCandidates : .needsSelection
    }
}
