import Foundation
import XCTest
@testable import FocusMate

/// 가짜 객체들이 공유하는 호출 순서 기록.
final class EventLog {
    private(set) var events: [String] = []
    func record(_ event: String) { events.append(event) }
}

@MainActor
final class FakeIssuanceHaptics: IssuanceHaptics {
    let isSupported: Bool
    private(set) var patterns: [IssuanceHapticPattern] = []
    var onPlay: (() -> Void)?
    private let log: EventLog?

    init(isSupported: Bool, log: EventLog? = nil) {
        self.isSupported = isSupported
        self.log = log
    }

    func play(_ pattern: IssuanceHapticPattern) {
        patterns.append(pattern)
        log?.record("play")
        onPlay?()
    }
}

@MainActor
final class RecordingAnnouncer: AccessibilityAnnouncing {
    private(set) var messages: [String] = []
    func announce(_ message: String) { messages.append(message) }
}

@MainActor
final class FakeCardIssuer: CardIssuing {
    private var results: [Bool]
    private(set) var issueCalls = 0
    private(set) var finishCalls = 0
    private let log: EventLog?

    init(results: [Bool], log: EventLog? = nil) {
        self.results = results
        self.log = log
    }

    func issueCard() -> Bool {
        issueCalls += 1
        log?.record("issueCard")
        return results.isEmpty ? true : results.removeFirst()
    }

    func finishCardIssuance() {
        finishCalls += 1
        log?.record("finish")
    }
}

/// sleep 진입을 기록하고, resume 될 때까지 멈춰 있는다.
@MainActor
final class SuspendingSleep {
    private(set) var requested: [Duration] = []
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    func sleep(_ duration: Duration) async {
        requested.append(duration)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            continuation = c
            waiter?.resume()
            waiter = nil
        }
    }

    func untilSuspended() async {
        if continuation != nil { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            waiter = c
        }
    }

    func resume() {
        guard let c = continuation else {
            XCTFail("resume 할 sleep 이 없다")
            return
        }
        continuation = nil
        c.resume()
    }
}
