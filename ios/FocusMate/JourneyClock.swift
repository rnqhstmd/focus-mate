import Foundation

/// 여행 진도를 재는 단조 시계. 벽시계(`Date`)를 쓰지 않으므로 기기 시계를 바꿔도 진도가 달라지지 않는다.
@MainActor
protocol JourneyClock: AnyObject {
    var now: Duration { get }
}

/// 화면 갱신과 체크포인트 판정을 일으키는 계기. 진도 자체는 시계 차이로 계산하므로 틱이 늦거나 빠져도 오차가 쌓이지 않는다.
@MainActor
protocol JourneyTicker: AnyObject {
    /// 구독자는 하나다. 다시 부르면 기존 구독을 교체한다.
    func start(_ onTick: @escaping @MainActor () -> Void)
    func stop()
    var isTicking: Bool { get }
}

/// 시스템 잠자기 시간을 포함하는 `ContinuousClock` 기준. 앱이 백그라운드에서 멈춰 있어도 복귀 후 첫 계산에 그 시간이 들어간다.
final class ContinuousJourneyClock: JourneyClock {
    private let clock = ContinuousClock()
    private let origin: ContinuousClock.Instant

    init() { origin = clock.now }

    var now: Duration { origin.duration(to: clock.now) }
}

final class TaskJourneyTicker: JourneyTicker {
    private let interval: Duration
    private let sleep: (Duration) async -> Void
    private(set) var loop: Task<Void, Never>?

    init(interval: Duration = .seconds(1), sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.interval = interval
        self.sleep = sleep
    }

    deinit { loop?.cancel() }

    var isTicking: Bool { loop.map { !$0.isCancelled } ?? false }

    func start(_ onTick: @escaping @MainActor () -> Void) {
        loop?.cancel()
        let interval = interval, sleep = sleep
        loop = Task { @MainActor in
            while !Task.isCancelled {
                await sleep(interval)
                guard !Task.isCancelled else { return }
                onTick()
            }
        }
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }
}

#if DEBUG
/// 테스트·UI 테스트용. 시계와 틱을 한 객체가 맡아 시간을 손으로 진행시킨다.
final class ManualJourneyClock: JourneyClock, JourneyTicker {
    private(set) var now: Duration = .zero
    private var onTick: (@MainActor () -> Void)?
    private var armed: Duration?

    var isTicking: Bool { onTick != nil }

    func start(_ onTick: @escaping @MainActor () -> Void) { self.onTick = onTick }
    func stop() { onTick = nil }

    func advance(by duration: Duration, notify: Bool = true) {
        now += duration
        if notify { onTick?() }
    }

    /// 백그라운드에 있는 동안 흐른 시간을 재현한다. 다음 포그라운드 복귀 직전에 한 번 적용된다.
    func armForegroundAdvance(by duration: Duration) { armed = duration }

    func applyArmedForegroundAdvance() {
        guard let armed else { return }
        now += armed
        self.armed = nil
    }
}
#endif
