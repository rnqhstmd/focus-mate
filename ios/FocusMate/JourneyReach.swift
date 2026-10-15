import Foundation

/// 포기·새 여정에서 다음 출발 정류장이 되는 '도달 정류장' 규칙(BR-1, BR-2). 정류장 이름은 카탈로그 이름, 방향은 여정 방향 그대로다.
enum JourneyReach {
    /// 저장된 경과로 지난 정류장 칸 수. 몫이며 총 정류장 수를 넘지 않는다.
    static func reachedStops(elapsedSeconds: Int, minutes: Int, minutesPerStop: Int) -> Int {
        min(elapsedSeconds / (minutesPerStop * 60), minutes / minutesPerStop)
    }

    /// 출발 정류장에서 방향대로 `stops`칸 간 순환 정류장. 출발지가 카탈로그 밖이면 nil이다.
    static func station(originStopID: String, direction: Int, stops: Int) -> StationSnapshot? {
        guard let origin = RouteStops.all.firstIndex(where: { $0.id == originStopID }) else { return nil }
        let stop = RouteStops.all[RouteStops.wrap(origin + direction * stops)]
        return StationSnapshot(id: stop.id, name: stop.name, direction: direction)
    }
}

extension JourneySnapshot {
    /// 도착한 여정은 저장된 도착지, 그 밖(출발 대기 포함)은 저장된 경과로 계산한 정류장이다.
    var reachedStation: StationSnapshot? {
        if isArrived {
            guard let name = destinationName else { return nil }
            return StationSnapshot(id: destinationStopID, name: name, direction: direction)
        }
        guard let bus else { return nil }
        let stops = JourneyReach.reachedStops(elapsedSeconds: progress.elapsedSeconds, minutes: minutes,
                                              minutesPerStop: bus.minutesPerStop)
        return JourneyReach.station(originStopID: originStopID, direction: direction, stops: stops)
    }
}

extension AppSnapshot {
    /// 현재 정류장 변경과 여정 삭제를 한 후보로 만든다(BR-4). 카드·기록·최초 정류장은 그대로다(BR-3).
    func endingActiveJourney(at station: StationSnapshot) -> AppSnapshot {
        updatingStage(cardIssued: cardIssued, initialStation: initialStation, currentStation: station)
            .updating(journey: .empty)
    }
}
