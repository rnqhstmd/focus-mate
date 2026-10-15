import Foundation

/// 포기·새 여정에서 다음 출발 정류장을 정한 결과(BR-1, BR-2, BR-12, BR-13).
enum ReachResolution: Equatable {
    /// 저장 경과로 계산한 정류장(도착이면 저장된 도착지).
    case station(StationSnapshot)
    /// 노선·구간을 다시 만들 수 없어 출발 정류장에 남는다.
    case stayAtOrigin(StationSnapshot)
    /// 출발 정류장도 데이터에 없어 정류장을 다시 골라야 한다.
    case reselectStation
}

extension ReachResolution {
    /// 다음 현재 정류장. 다시 골라야 하면 nil이다.
    var station: StationSnapshot? {
        switch self {
        case let .station(station), let .stayAtOrigin(station): station
        case .reselectStation: nil
        }
    }
}

enum ReachAttempt: Equatable { case notLoaded, resolved(ReachResolution) }

extension JourneySnapshot {
    /// 도착한 여정의 정류장. 저장값만 쓰므로 정류장 데이터 상태와 무관하다(AC-78, AC-79).
    var arrivedStation: StationSnapshot? {
        isArrived ? StationSnapshot(id: destinationStopID, name: destinationName) : nil
    }

    func reachedStation(in availability: RouteDataAvailability) -> ReachAttempt {
        if let arrivedStation { return .resolved(.station(arrivedStation)) }
        switch availability {
        case .loading: return .notLoaded
        case .failed: return .resolved(.stayAtOrigin(StationSnapshot(id: originStopID, name: originName)))
        case let .ready(catalog):
            if let course = CourseJourney(journey: self, catalog: catalog) {
                let elapsed = progress.elapsedSeconds
                let reached = course.cumulativeSeconds.lastIndex { $0 <= elapsed } ?? 0
                let stop = course.stops[reached]
                return .resolved(.station(StationSnapshot(id: stop.id, name: stop.name)))
            }
            guard let origin = catalog.stopIndex(id: originStopID) else { return .resolved(.reselectStation) }
            return .resolved(.stayAtOrigin(StationSnapshot(id: originStopID, name: catalog.stops[origin].name)))
        }
    }
}

extension AppSnapshot {
    /// 현재 정류장 변경과 여정 삭제를 한 후보로 만든다(BR-4). 카드·기록·최초 정류장은 그대로다(BR-3).
    func endingActiveJourney(at station: StationSnapshot) -> AppSnapshot {
        updatingStage(cardIssued: cardIssued, initialStation: initialStation, currentStation: station)
            .updating(journey: .empty)
    }

    /// 최초·현재 정류장과 진행 여정을 비운다. 카드·기록은 그대로다(옛 형식 이전, BR-13, BR-16).
    func clearingStationsAndJourney() -> AppSnapshot {
        updatingStage(cardIssued: cardIssued, initialStation: nil, currentStation: nil)
            .updating(journey: .empty)
    }
}
