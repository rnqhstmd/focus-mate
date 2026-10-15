import Foundation
import Observation

@MainActor
protocol DepartureConfirming: AnyObject {
    func confirmDeparture() -> Bool
}

/// 출발 안내. 세 문장을 같은 자리에서 차례로 보여 준 뒤 '시작'을 띄우고, 누르면 출발 확인을 저장한다.
/// 안내 중에는 일시정지·진도·남은 시간이 화면에 없어 출발 확인 전에는 아무것도 흐르지 않는다.
@MainActor @Observable
final class DepartureBriefingController {
    enum FocusTarget: Equatable { case startButton }

    nonisolated static let sentences = ["문을 닫습니다", "자리에 앉아주세요", "버스 출발합니다"]
    nonisolated static let interval: Duration = .milliseconds(1700)

    private(set) var visibleIndex = 0
    private(set) var showsAll = false
    private(set) var showsStart = false
    private(set) var focusTarget: FocusTarget?
    private(set) var isConfirmed = false
    private(set) var showsSaveFailure = false

    @ObservationIgnored private let confirmer: DepartureConfirming
    @ObservationIgnored private let interval: Duration
    @ObservationIgnored private let sleep: (Duration) async -> Void
    @ObservationIgnored private var token = 0

    init(confirmer: DepartureConfirming, interval: Duration = DepartureBriefingController.interval,
         sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.confirmer = confirmer
        self.interval = interval
        self.sleep = sleep
    }

    /// 처음부터 보여 준다. 동작 줄이기면 세 문장과 '시작'을 한꺼번에 보여 준다.
    func begin(reduceMotion: Bool) async {
        token += 1
        let current = token
        visibleIndex = 0
        showsStart = false
        focusTarget = nil
        if reduceMotion {
            showsAll = true
            visibleIndex = Self.sentences.count - 1
            revealStart()
            return
        }
        showsAll = false
        for index in 1..<Self.sentences.count {
            await sleep(interval)
            guard token == current else { return }
            visibleIndex = index
        }
        revealStart()
    }

    /// 앱이 숨겨지면 진행 중인 안내를 버린다. 돌아오면 `begin`으로 처음부터 다시 보여 준다.
    func reset() {
        token += 1
        visibleIndex = 0
        showsAll = false
        showsStart = false
        focusTarget = nil
    }

    @discardableResult
    func confirm() -> Bool {
        guard showsStart, !isConfirmed else { return false }
        guard confirmer.confirmDeparture() else {
            showsSaveFailure = true
            return false
        }
        showsSaveFailure = false
        isConfirmed = true
        return true
    }

    private func revealStart() {
        showsStart = true
        focusTarget = .startButton
    }
}
