import Foundation
import Observation

@MainActor
protocol CardIssuing: AnyObject {
    func issueCard() -> Bool
    func finishCardIssuance()
}

enum CardIssuanceTiming {
    /// 발급 중 상태 유지 상한(FR-3-9).
    static let standardHold: Duration = .milliseconds(900)
    /// 화면의 슬롯 연출 길이. hold와 분리해 고정한다 — 테스트가 hold를 붙잡아도 애니메이션은 끝나 앱이 idle이 된다.
    static let slotAnimation: TimeInterval = 0.86
    static let hapticDuration: TimeInterval = 0.9
}

/// 카드 1회 발급 상태 머신. ready/failed에서만 발급을 시작하며, 이 검사가 첫 suspension 전에 MainActor에서 일어나 연타가 직렬화된다.
@MainActor @Observable
final class CardIssuanceController {
    enum Phase: Equatable { case ready, issuing, failed, issued }
    enum FocusTarget: Equatable { case continueButton }

    static let issuingAnnouncement = "카드를 발급하고 있어요."
    static let issuedAnnouncement = "카드가 발급됐어요. 출발지를 선택해보세요."
    static let failedAnnouncement = "카드를 발급하지 못했어요. 다시 시도해 주세요."

    private(set) var phase: Phase = .ready
    private(set) var focusTarget: FocusTarget?

    @ObservationIgnored private let issuer: CardIssuing
    @ObservationIgnored private let haptics: IssuanceHaptics
    @ObservationIgnored private let announcer: AccessibilityAnnouncing
    @ObservationIgnored private let standardDuration: Duration
    @ObservationIgnored private let sleep: (Duration) async -> Void

    init(issuer: CardIssuing, haptics: IssuanceHaptics, announcer: AccessibilityAnnouncing,
         standardDuration: Duration = CardIssuanceTiming.standardHold,
         sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.issuer = issuer
        self.haptics = haptics
        self.announcer = announcer
        self.standardDuration = standardDuration
        self.sleep = sleep
    }

    static func holdDuration(reduceMotion: Bool, standard: Duration) -> Duration {
        reduceMotion ? .zero : standard
    }

    @discardableResult
    func issue(reduceMotion: Bool) async -> Bool {
        guard phase == .ready || phase == .failed else { return false }
        phase = .issuing
        announcer.announce(Self.issuingAnnouncement)
        guard issuer.issueCard() else {
            phase = .failed
            announcer.announce(Self.failedAnnouncement)
            return false
        }
        // 진동은 연출 시작과 함께, 동작 줄이기와 무관하게 재생한다.
        if haptics.isSupported { haptics.play(.issuance) }
        let hold = Self.holdDuration(reduceMotion: reduceMotion, standard: standardDuration)
        if hold > .zero { await sleep(hold) }
        phase = .issued
        announcer.announce(Self.issuedAnnouncement)
        focusTarget = .continueButton
        return true
    }

    func proceed() {
        guard phase == .issued else { return }
        issuer.finishCardIssuance()
    }
}
