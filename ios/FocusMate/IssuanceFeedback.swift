import CoreHaptics
import UIKit

@MainActor
protocol IssuanceHaptics: AnyObject {
    var isSupported: Bool { get }
    func play(_ pattern: IssuanceHapticPattern)
}

@MainActor
protocol AccessibilityAnnouncing: AnyObject {
    func announce(_ message: String)
}

/// 지원 판단과 재생을 모두 CoreHaptics로 한다. 엔진·재생 오류는 조용히 무시한다(발급 흐름을 막지 않는다).
@MainActor
final class CoreHapticsIssuancePlayer: IssuanceHaptics {
    let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?

    func play(_ pattern: IssuanceHapticPattern) {
        guard isSupported, let engine = engine ?? makeEngine() else { return }
        do {
            try engine.start()
            let player = try engine.makePlayer(with: pattern.makeCHHapticPattern())
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            self.engine = nil
        }
    }

    private func makeEngine() -> CHHapticEngine? {
        guard let engine = try? CHHapticEngine() else { return nil }
        // 발급은 한 번뿐이라 재생이 끝나면 엔진을 스스로 내리게 해 전력을 아낀다. 다음 재생 때 다시 켜진다.
        engine.isAutoShutdownEnabled = true
        engine.stoppedHandler = { [weak self] _ in Task { @MainActor in self?.engine = nil } }
        engine.resetHandler = { [weak self] in Task { @MainActor in self?.engine = nil } }
        self.engine = engine
        return engine
    }
}

@MainActor
final class SystemAccessibilityAnnouncer: AccessibilityAnnouncing {
    func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
