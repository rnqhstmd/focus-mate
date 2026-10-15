import Foundation
import Observation

/// 출발 뒤 실제 분 타이머. 진도는 단조 시계 차이로 계산하고 틱은 화면 갱신·체크포인트 계기일 뿐이다.
/// 앱이 살아 있는 동안(비활성·백그라운드 포함)은 시간이 흐르고, 백그라운드 진입 시 진행 상태로 즉시 저장한다.
/// 모든 전환은 동기다. 저장자는 결과를 Bool로 돌려주고, 실패하면 사용자가 알 수 있게 표시한다(BR-7).
@MainActor @Observable
final class JourneyTimerController {
    enum Status: Equatable { case running, paused, arrived }

    private(set) var status: Status
    private(set) var elapsedSeconds = 0
    private(set) var remainingSeconds = 0
    private(set) var remainingMinutes = 0
    private(set) var showsTransitionFailure = false
    private(set) var showsSaveWarning = false

    @ObservationIgnored private let journeyID: String
    @ObservationIgnored private let totalSeconds: Int
    @ObservationIgnored private let checkpointInterval: Int
    @ObservationIgnored private let saver: JourneyProgressSaving
    @ObservationIgnored private let clock: JourneyClock
    @ObservationIgnored private let ticker: JourneyTicker
    @ObservationIgnored private let announcer: AccessibilityAnnouncing
    /// 마지막 정지·재개 시점까지의 정밀 진도.
    @ObservationIgnored private var baseElapsed: Duration
    /// 진행 중일 때만 있는 기준 시각. `status == .running`과 함께 움직인다.
    @ObservationIgnored private var runAnchor: Duration?
    @ObservationIgnored private var lastSavedElapsed: Int
    @ObservationIgnored private var arrivalPersisted = false

    /// `autoStart`는 같은 화면이 '시작'을 직접 본 경우에만 true다. 저장된 paused=false만으로는 자동 시작하지 않는다.
    init(journey: JourneySnapshot, autoStart: Bool, saver: JourneyProgressSaving, clock: JourneyClock,
         ticker: JourneyTicker, announcer: AccessibilityAnnouncing, checkpointInterval: Int = 10) {
        journeyID = journey.id
        totalSeconds = journey.totalSeconds
        self.checkpointInterval = checkpointInterval
        self.saver = saver
        self.clock = clock
        self.ticker = ticker
        self.announcer = announcer
        baseElapsed = .seconds(journey.progress.elapsedSeconds)
        lastSavedElapsed = journey.progress.elapsedSeconds
        if journey.isArrived {
            status = .arrived
            arrivalPersisted = true
        } else if autoStart, !journey.paused {
            status = .running
            runAnchor = clock.now
        } else {
            status = .paused
        }
        refresh()
    }

    /// 화면과 함께 해제되면 틱도 멈춘다(틱 클로저는 약하게 잡는다).
    deinit {
        MainActor.assumeIsolated { ticker.stop() }
    }

    /// 여러 번 불려도 기준 시각을 다시 잡지 않는다(진도 손실 방지).
    func appear() {
        switch status {
        case .running: if !ticker.isTicking { startTicking() }
        case .paused: break
        case .arrived: retryArrivalIfNeeded()
        }
        refresh()
    }

    func tick() {
        guard status == .running else { return }
        if reachedTotal { return arrive() }
        refresh()
        let elapsed = currentSeconds
        guard elapsed - lastSavedElapsed >= checkpointInterval else { return }
        if !save(elapsed, paused: false) { stopForSaveFailure() }
    }

    func pause() {
        guard status == .running else { return }
        if reachedTotal { return arrive() }
        let elapsed = currentSeconds
        guard save(elapsed, paused: true) else {
            showsTransitionFailure = true
            return
        }
        halt()
        showsTransitionFailure = false
        announcer.announce(JourneyTimerDisplay.pausedAnnouncement)
    }

    func resume() {
        guard status == .paused else { return }
        guard save(currentSeconds, paused: false) else {
            if !showsSaveWarning { showsTransitionFailure = true }
            return
        }
        status = .running
        runAnchor = clock.now
        startTicking()
        showsSaveWarning = false
        showsTransitionFailure = false
        refresh()
        announcer.announce(JourneyTimerDisplay.resumedAnnouncement)
    }

    /// 백그라운드에서도 시간은 흐른다. 상태는 바꾸지 않고 그 시점 진도만 즉시 저장한다.
    func enterBackground() {
        switch status {
        case .running:
            if reachedTotal { return arrive() }
            refresh()
            if !save(currentSeconds, paused: false) { stopForSaveFailure() }
        case .paused: break
        case .arrived: retryArrivalIfNeeded()
        }
    }

    /// 복귀하면 그 사이 흐른 시간을 바로 반영한다. 일시정지는 자동 재개하지 않는다.
    func returnToForeground() { tick() }

    /// 정상 경로에서는 불리지 않는다(여행 화면에서 메인으로 갈 수 없다). 재생성 시 일시정지 규칙과 저장을 맞추는 방어다.
    func leave() {
        switch status {
        case .running:
            if reachedTotal { return arrive() }
            let elapsed = currentSeconds
            halt()
            _ = save(elapsed, paused: true)
        case .paused: ticker.stop()
        case .arrived: retryArrivalIfNeeded()
        }
    }

    // MARK: 내부

    private var current: Duration {
        min(.seconds(totalSeconds), baseElapsed + (runAnchor.map { clock.now - $0 } ?? .zero))
    }
    private var currentSeconds: Int { Int(current.components.seconds) }
    private var reachedTotal: Bool { current >= .seconds(totalSeconds) }

    private func startTicking() { ticker.start { [weak self] in self?.tick() } }

    /// 진도를 고정하고 정지한다.
    private func halt() {
        baseElapsed = current
        runAnchor = nil
        ticker.stop()
        status = .paused
        refresh()
    }

    private func stopForSaveFailure() {
        halt()
        showsTransitionFailure = false
        showsSaveWarning = true
        announcer.announce(JourneyTimerDisplay.checkpointWarningText)
    }

    private func arrive() {
        guard status != .arrived else { return }
        baseElapsed = .seconds(totalSeconds)
        runAnchor = nil
        ticker.stop()
        status = .arrived
        showsTransitionFailure = false
        refresh()
        arrivalPersisted = save(totalSeconds, paused: true)
        showsSaveWarning = !arrivalPersisted
    }

    private func retryArrivalIfNeeded() {
        guard !arrivalPersisted else { return }
        arrivalPersisted = save(totalSeconds, paused: true)
        showsSaveWarning = !arrivalPersisted
    }

    private func save(_ elapsed: Int, paused: Bool) -> Bool {
        guard saver.saveJourneyProgress(journeyID: journeyID, elapsedSeconds: elapsed, paused: paused) else { return false }
        lastSavedElapsed = elapsed
        return true
    }

    private func refresh() {
        elapsedSeconds = currentSeconds
        remainingSeconds = totalSeconds - elapsedSeconds
        remainingMinutes = JourneyTimerDisplay.remainingMinutes(totalSeconds: totalSeconds, elapsedSeconds: elapsedSeconds)
    }
}
