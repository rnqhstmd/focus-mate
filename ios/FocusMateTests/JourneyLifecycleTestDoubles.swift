import Foundation
@testable import FocusMate

/// 포기 처리 더블. 결과 배열을 순서대로 소비하고 소진되면 마지막 값(없으면 .rejected)을 반환한다.
/// 호출 때 받은 timerPaused 인자를 모두 `calls`에 기록한다.
@MainActor
final class FakeJourneyAbandoner: JourneyAbandoning {
    private var results: [LifecycleActionResult]
    private var last: LifecycleActionResult = .rejected
    private(set) var calls: [Bool] = []
    /// JourneyAbandoning.canEndActiveJourney. 테스트에서 바꿔 로딩 중(false) 상황을 만든다.
    var canEndActiveJourney = true

    init(results: [LifecycleActionResult]) {
        self.results = results
    }

    func abandonJourney(timerPaused: Bool) -> LifecycleActionResult {
        calls.append(timerPaused)
        if !results.isEmpty { last = results.removeFirst() }
        return last
    }
}

/// 저장 시도를 센다. attempts는 실패한 시도까지, writes는 성공한 바이트만 담는다 (R1).
final class LifecycleProbe {
    enum Failure: Error { case expected }

    private(set) var attempts = 0
    private(set) var writes: [Data] = []
    var shouldFail = false

    func record(_ data: Data) throws {
        attempts += 1
        if shouldFail { throw Failure.expected }
        writes.append(data)
    }
}
