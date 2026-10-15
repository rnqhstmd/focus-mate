import Foundation
import Observation

/// 도착 안내의 '확인' 경계. AppModel이 채택하며 저장본이 도착 상태일 때만 하차 태그로 보낸다.
@MainActor
protocol ArrivalConfirming: AnyObject {
    func confirmArrival(timerArrived: Bool) -> LifecycleActionResult
}

/// 도착 저장의 주인(타이머). 확인을 누를 때 저장이 실패해 있으면 한 번 더 시도한다.
@MainActor
protocol ArrivalProgress: AnyObject {
    var isArrived: Bool { get }
    func ensureArrivalSaved() -> Bool
}

/// 도착 안내 문구. 정류장 이름이 들어가므로 여정마다 만든다.
struct ArrivalBriefingContent: Equatable {
    let routeText: String
    let sentences: [String]

    /// 저장된 이름만 쓰므로 지도 일관성(BR-12)과 무관하게 늘 만든다.
    init(journey: JourneySnapshot) {
        let destination = journey.destinationName
        routeText = "\(journey.busNumber) · \(destination) 도착"
        sentences = ["곧 \(destination)에 도착합니다", "버스가 멈추면 일어나주세요", "카드를 찍고 내려주세요"]
    }
}

/// 도착 안내. 출발 안내와 같은 규칙으로 세 문장을 차례로 보여 준 뒤 '확인'을 띄운다.
/// 확인은 저장하지 않는다 — 도착 저장은 타이머가, 하차 태그 진입은 모델이 판단한다.
@MainActor @Observable
final class ArrivalBriefingController {
    enum FocusTarget: Equatable { case confirmButton }

    let content: ArrivalBriefingContent
    private(set) var visibleIndex = 0
    private(set) var showsAll = false
    private(set) var showsConfirm = false
    private(set) var showsSaveFailure = false
    private(set) var focusTarget: FocusTarget?

    @ObservationIgnored private let progress: ArrivalProgress
    @ObservationIgnored private let confirmer: ArrivalConfirming
    @ObservationIgnored private let interval: Duration
    @ObservationIgnored private let sleep: (Duration) async -> Void
    @ObservationIgnored private var token = 0

    init(content: ArrivalBriefingContent, progress: ArrivalProgress, confirmer: ArrivalConfirming,
         interval: Duration = DepartureBriefingController.interval,
         sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.content = content
        self.progress = progress
        self.confirmer = confirmer
        self.interval = interval
        self.sleep = sleep
    }

    /// 처음부터 보여 준다. 동작 줄이기면 세 문장과 '확인'을 한꺼번에 보여 준다.
    func begin(reduceMotion: Bool) async {
        token += 1
        let current = token
        visibleIndex = 0
        showsConfirm = false
        focusTarget = nil
        if reduceMotion {
            showsAll = true
            visibleIndex = content.sentences.count - 1
            revealConfirm()
            return
        }
        showsAll = false
        for index in 1..<content.sentences.count {
            await sleep(interval)
            guard token == current else { return }
            visibleIndex = index
        }
        revealConfirm()
    }

    /// 앱이 숨겨지면 진행 중인 안내를 버린다. 돌아오면 `begin`으로 처음부터 다시 보여 준다.
    func reset() {
        token += 1
        visibleIndex = 0
        showsAll = false
        showsConfirm = false
        focusTarget = nil
    }

    @discardableResult
    func confirm() -> LifecycleActionResult {
        guard showsConfirm else { return .rejected }
        _ = progress.ensureArrivalSaved()
        let result = confirmer.confirmArrival(timerArrived: progress.isArrived)
        showsSaveFailure = result == .saveFailed
        return result
    }

    private func revealConfirm() {
        showsConfirm = true
        focusTarget = .confirmButton
    }
}

extension JourneyTimerController: ArrivalProgress {
    var isArrived: Bool { status == .arrived }
}
