import Foundation
@testable import FocusMate

/// 진도 저장 더블. 결과 배열을 순서대로 소비하고 소진되면 true를 반환한다.
/// 성공·실패와 무관하게 호출된 모든 쓰기 시도를 `writes`에 기록한다.
@MainActor
final class FakeProgressSaver: JourneyProgressSaving {
    private var results: [Bool]
    private(set) var writes: [(journeyID: String, elapsed: Int, paused: Bool)] = []

    init(results: [Bool] = []) {
        self.results = results
    }

    func saveJourneyProgress(journeyID: String, elapsedSeconds: Int, paused: Bool) -> Bool {
        writes.append((journeyID: journeyID, elapsed: elapsedSeconds, paused: paused))
        return results.isEmpty ? true : results.removeFirst()
    }
}

/// ManualJourneyClock으로 위임하면서 start 호출 횟수를 센다.
@MainActor
final class CountingTicker: JourneyTicker {
    private let base: JourneyTicker
    private(set) var startCount = 0

    init(base: JourneyTicker) {
        self.base = base
    }

    var isTicking: Bool { base.isTicking }

    func start(_ onTick: @escaping @MainActor () -> Void) {
        startCount += 1
        base.start(onTick)
    }

    func stop() {
        base.stop()
    }
}
