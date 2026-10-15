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
    /// 여행 진도 시계. 화면이 다시 그려져도 같은 기준점을 쓰도록 컨트롤러가 생성 시점에 붙잡는다.
    var clock: JourneyClock
    /// 컨트롤러마다 따로 갖는다. `.live()`가 다시 평가될 수 있어 공유 인스턴스를 두지 않는다.
    var makeTicker: @MainActor () -> JourneyTicker
    /// 포그라운드 복귀 처리 직전에 부른다(UI 테스트가 백그라운드 경과를 재현한다).
    var beforeForeground: @MainActor () -> Void
    /// 앱 밖 표시(Live Activity) 요청 창구. UI 테스트는 기록기로 바꾼다.
    var liveActivities: LiveActivityGateway = ActivityKitLiveActivityGateway()
    #if DEBUG
    var testClock: ManualJourneyClock?
    var failNextSave: UITestNextSaveFailure?
    #endif

    static func live() -> JourneyServices {
        JourneyServices(haptics: CoreHapticsIssuancePlayer(), announcer: SystemAccessibilityAnnouncer(),
                        sleep: { try? await Task.sleep(for: $0) }, boardingHoldSleep: nil,
                        forcedReduceMotion: false, makeBoarder: { $0 },
                        clock: ContinuousJourneyClock(), makeTicker: { TaskJourneyTicker() }, beforeForeground: {})
    }

    func reduceMotion(system: Bool) -> Bool { system || forcedReduceMotion }
}

extension AppModel: JourneyBoarding, DepartureConfirming, JourneyProgressSaving {}
