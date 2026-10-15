import Foundation
import Observation

/// W07 여정 동작의 결과. 가드 거부는 안내하지 않고, 저장 실패만 "저장하지 못했어요"로 안내한다(BR-7).
enum LifecycleActionResult: Equatable { case done, rejected, saveFailed }

/// 포기 확정 경계. AppModel이 채택한다. 일시정지 여부는 런타임 진도의 주인인 타이머 컨트롤러 상태를 넘긴다(BR-6).
@MainActor
protocol JourneyAbandoning: AnyObject {
    func abandonJourney(timerPaused: Bool) -> LifecycleActionResult
}

/// 포기 확인 흐름. 확정은 `isConfirming`에 의존하지 않는다 — alert 바인딩 해제와 버튼 동작의 호출 순서가 보장되지 않기 때문이다.
@MainActor @Observable
final class JourneyAbandonController {
    enum FocusTarget: Equatable { case abandonButton }

    private(set) var isConfirming = false
    private(set) var showsFailure = false
    private(set) var hasFinished = false
    /// 대화상자가 닫힌 뒤 낭독 초점을 돌려 둘 곳.
    private(set) var focusTarget: FocusTarget?

    @ObservationIgnored private let abandoner: JourneyAbandoning

    init(abandoner: JourneyAbandoning) { self.abandoner = abandoner }

    func request(isPaused: Bool) {
        guard isPaused, !hasFinished, !isConfirming else { return }
        showsFailure = false
        focusTarget = nil
        isConfirming = true
    }

    func cancel() {
        isConfirming = false
        if !hasFinished { focusTarget = .abandonButton }
    }

    @discardableResult
    func confirm(isPaused: Bool) -> LifecycleActionResult {
        guard !hasFinished else { return .rejected }
        isConfirming = false
        let result = abandoner.abandonJourney(timerPaused: isPaused)
        switch result {
        case .done:
            hasFinished = true
            focusTarget = nil
        case .saveFailed:
            showsFailure = true
            focusTarget = .abandonButton
        case .rejected:
            break
        }
        return result
    }

    func clearFailure() { showsFailure = false }
}
