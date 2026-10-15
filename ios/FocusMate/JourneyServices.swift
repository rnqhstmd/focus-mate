import Foundation

/// 승차·출발 안내 화면에 넘기는 의존성 묶음. 운영은 실제 햅틱·낭독·대기, UI 테스트는 기록기·게이트·동작 줄이기 강제를 넣는다.
@MainActor
struct JourneyServices {
    var haptics: IssuanceHaptics
    var announcer: AccessibilityAnnouncing
    var sleep: (Duration) async -> Void
    /// 인식 유지(1400ms)만 따로 붙잡을 때 쓴다(UI 테스트 게이트).
    var boardingHoldSleep: ((Duration) async -> Void)?
    /// 시스템 설정과 OR로 합친다. DEBUG 인자로만 켜진다.
    var forcedReduceMotion: Bool
    var makeBoarder: (AppModel) -> JourneyBoarding

    static func live() -> JourneyServices {
        JourneyServices(haptics: CoreHapticsIssuancePlayer(), announcer: SystemAccessibilityAnnouncer(),
                        sleep: { try? await Task.sleep(for: $0) }, boardingHoldSleep: nil,
                        forcedReduceMotion: false, makeBoarder: { $0 })
    }

    func reduceMotion(system: Bool) -> Bool { system || forcedReduceMotion }
}

extension AppModel: JourneyBoarding, DepartureConfirming {}
