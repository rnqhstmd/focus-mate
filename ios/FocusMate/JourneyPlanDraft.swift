import Foundation

/// 준비 진입점에 넘기는 여정 선택(용어 사전의 "여정 선택"). 저장하지 않는다.
struct JourneySelection: Equatable {
    let origin: StopPosition
    let minutes: Int
    let busID: String
    let busNumber: String
    let destination: String
    let stops: Int
}

enum ProceedState: Equatable {
    case originUnavailable, noCandidates, needsSelection, ready(JourneySelection)

    var title: String {
        switch self {
        case .originUnavailable: "출발 정류장을 확인할 수 없어요"
        case .noCandidates: "이 시간의 도착 후보가 없어요"
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
    private(set) var selectedBusID: String?

    /// 범위 안으로 맞춘 값이 실제로 바뀌면 같은 버스가 새 시간에도 후보여도 선택을 해제한다.
    mutating func setMinutes(_ value: Int) {
        let clamped = JourneyPlanner.clamp(value)
        guard clamped != minutes else { return }
        minutes = clamped
        selectedBusID = nil
    }

    mutating func choose(busID: String, from origin: StopPosition) -> Bool {
        guard candidates(from: origin).contains(where: { $0.bus.id == busID }) else { return false }
        selectedBusID = busID
        return true
    }

    func candidates(from origin: StopPosition) -> [JourneyCandidate] {
        JourneyPlanner.candidates(minutes: minutes, from: origin)
    }

    func selectedCandidate(from origin: StopPosition) -> JourneyCandidate? {
        candidates(from: origin).first { $0.bus.id == selectedBusID }
    }

    func proceedState(from origin: StopPosition) -> ProceedState {
        if let candidate = selectedCandidate(from: origin) {
            return .ready(JourneySelection(origin: origin, minutes: minutes, busID: candidate.bus.id,
                                           busNumber: candidate.bus.number, destination: candidate.destination,
                                           stops: candidate.stops))
        }
        return candidates(from: origin).isEmpty ? .noCandidates : .needsSelection
    }
}
