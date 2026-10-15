import CoreGraphics
import Foundation
import Observation

@MainActor
protocol JourneyBoarding: AnyObject {
    func boardJourney() -> Bool
}

/// 하차 접촉 커밋 경계. AppModel이 채택한다.
@MainActor
protocol JourneyAlighting: AnyObject {
    func alightJourney() -> Bool
}

/// 승차·하차 태그의 낭독 문구.
struct CardTagCopy: Equatable {
    let recognizedAnnouncement, failedAnnouncement: String
    static let boarding = CardTagCopy(recognizedAnnouncement: "집중동행카드 인식됨, 승차했습니다",
                                      failedAnnouncement: "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요.")
    static let alighting = CardTagCopy(recognizedAnnouncement: "집중동행카드 인식됨, 하차했습니다",
                                       failedAnnouncement: JourneyTimerDisplay.transitionFailureText)
}

/// 하차 저장 뒤 중단된 태그 화면의 출구 규칙. 저장 여부는 컨트롤러 phase가 아니라 모델 상태로 판단한다.
enum AlightingTagRecovery {
    /// 하차가 저장됐고 늦은 전환(접촉·유지·페이드)이 진행 중이 아니면 바로 요약으로 간다.
    static func shouldFinish(phase: BoardingTagController.Phase, alightingSaved: Bool) -> Bool {
        alightingSaved && ![.contacting, .held, .fading].contains(phase)
    }
}

/// 승차 태그 상태 기계. 끌어서 태그 영역과 30% 이상 겹치는 순간(손을 떼기 전) 인식하고, 접촉 이동 뒤 진행 여정을 1회 저장한 다음
/// 인식 유지·페이드를 거쳐 여행으로 넘긴다. 저장(recognitionID)과 전환(transitionToken)은 서로 다른 토큰이라 전환 취소가 저장을 막지 않는다.
@MainActor @Observable
final class BoardingTagController {
    enum Phase: Equatable { case ready, dragging, contacting, held, fading, finished, failed, abandoned }
    enum LCDState: Equatable { case ready, recognized }

    static let recognizedAnnouncement = CardTagCopy.boarding.recognizedAnnouncement
    static let failedAnnouncement = CardTagCopy.boarding.failedAnnouncement

    private(set) var phase: Phase = .ready
    private(set) var cardOffset: CGSize = .zero
    private(set) var showsTapHint = false
    private(set) var tapBounceCount = 0
    private(set) var showsSaveFailure = false

    var isRecognized: Bool { [.contacting, .held, .fading, .finished, .abandoned].contains(phase) }
    var lcd: LCDState { isRecognized ? .recognized : .ready }

    /// 테스트가 늦은 저장·전환을 결정적으로 기다리도록 노출한다.
    @ObservationIgnored private(set) var pendingSave: Task<Void, Never>?
    @ObservationIgnored private(set) var pendingTransition: Task<Void, Never>?

    /// 접촉 커밋(승차 또는 하차 저장).
    @ObservationIgnored private let save: () -> Bool
    @ObservationIgnored private let copy: CardTagCopy
    @ObservationIgnored private let haptics: IssuanceHaptics
    @ObservationIgnored private let announcer: AccessibilityAnnouncing
    @ObservationIgnored private let geometry: BoardingGeometry
    @ObservationIgnored private let timing: BoardingTiming
    @ObservationIgnored private let sleep: (Duration) async -> Void
    @ObservationIgnored private let holdSleep: ((Duration) async -> Void)?
    @ObservationIgnored private let onFinished: () -> Void

    @ObservationIgnored private var cardRest: CGRect = .zero
    @ObservationIgnored private var tagArea: CGRect = .zero
    @ObservationIgnored private var recognitionID = 0
    @ObservationIgnored private var transitionToken = 0
    @ObservationIgnored private var transitionCancelled = false
    @ObservationIgnored private var resetWhenSettled = false
    /// 이번 손가락 동작이 터치 한계를 넘어 끌기가 된 적이 있는지.
    @ObservationIgnored private var hasDragged = false
    /// 저장 실패 뒤에는 손을 뗄 때까지 같은 동작으로 다시 인식하지 않는다(실패 안내 반복 방지).
    @ObservationIgnored private var awaitingRelease = false

    convenience init(boarder: JourneyBoarding, haptics: IssuanceHaptics, announcer: AccessibilityAnnouncing,
                     geometry: BoardingGeometry = .init(), timing: BoardingTiming = .standard,
                     sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) },
                     holdSleep: ((Duration) async -> Void)? = nil,
                     onFinished: @escaping () -> Void) {
        self.init(save: { boarder.boardJourney() }, copy: .boarding, haptics: haptics, announcer: announcer,
                  geometry: geometry, timing: timing, sleep: sleep, holdSleep: holdSleep, onFinished: onFinished)
    }

    /// 하차 태그. 조작·기하·타이밍은 승차와 같고 저장과 문구만 다르다.
    convenience init(alighter: JourneyAlighting, haptics: IssuanceHaptics, announcer: AccessibilityAnnouncing,
                     geometry: BoardingGeometry = .init(), timing: BoardingTiming = .standard,
                     sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) },
                     holdSleep: ((Duration) async -> Void)? = nil,
                     onFinished: @escaping () -> Void) {
        self.init(save: { alighter.alightJourney() }, copy: .alighting, haptics: haptics, announcer: announcer,
                  geometry: geometry, timing: timing, sleep: sleep, holdSleep: holdSleep, onFinished: onFinished)
    }

    private init(save: @escaping () -> Bool, copy: CardTagCopy, haptics: IssuanceHaptics,
                 announcer: AccessibilityAnnouncing, geometry: BoardingGeometry, timing: BoardingTiming,
                 sleep: @escaping (Duration) async -> Void, holdSleep: ((Duration) async -> Void)?,
                 onFinished: @escaping () -> Void) {
        self.save = save
        self.copy = copy
        self.haptics = haptics
        self.announcer = announcer
        self.geometry = geometry
        self.timing = timing
        self.sleep = sleep
        self.holdSleep = holdSleep
        self.onFinished = onFinished
    }

    func updateLayout(cardRest: CGRect, tagArea: CGRect) {
        self.cardRest = cardRest
        self.tagArea = tagArea
    }

    func dragChanged(translation: CGSize, reduceMotion: Bool) {
        switch phase {
        case .ready, .failed:
            guard !awaitingRelease, !geometry.isTap(translation) else { return }
            hasDragged = true
            showsTapHint = false
            phase = .dragging
            fallthrough
        case .dragging:
            cardOffset = geometry.clampedOffset(translation, cardRest: cardRest, tagArea: tagArea)
            // 놓기를 기다리지 않고 겹치는 순간 인식한다.
            if geometry.isContact(card: cardRest.offsetBy(dx: cardOffset.width, dy: cardOffset.height), tagArea: tagArea) {
                recognize(reduceMotion: reduceMotion)
            }
        default:
            return
        }
    }

    /// 손을 뗄 때는 절대 인식하지 않는다. 인식은 `dragChanged`와 `activate`에서만 일어난다.
    func dragEnded(translation: CGSize, reduceMotion: Bool) {
        defer { hasDragged = false; awaitingRelease = false }
        switch phase {
        case .ready, .failed:
            guard !hasDragged else { return }
            tapBounceCount += 1
            showsTapHint = true
        case .dragging:
            cardOffset = .zero
            phase = .ready
        default:
            return
        }
    }

    /// 낭독기·키보드 활성화: 카드를 태그 영역 아래쪽 가장자리에 걸쳐 올리고 바로 인식한다.
    func activate(reduceMotion: Bool) {
        guard phase == .ready || phase == .failed else { return }
        showsTapHint = false
        cardOffset = geometry.activationOffset(cardRest: cardRest, tagArea: tagArea)
        recognize(reduceMotion: reduceMotion)
    }

    /// 화면이 사라지거나 앱이 백그라운드로 가면 늦은 전환만 취소한다. 이미 인식된 저장은 예정대로 한다.
    func cancelPendingTransition() {
        transitionToken += 1
        switch phase {
        case .contacting: transitionCancelled = true
        case .held, .fading: phase = .abandoned
        case .dragging:
            cardOffset = .zero
            phase = .ready
        default: break
        }
    }

    /// 백그라운드에서 돌아오면 다시 태그할 수 있게 되돌린다. 저장된 진행 여정은 그대로다.
    func returnToForeground() {
        switch phase {
        case .abandoned: resetToReady()
        case .contacting where transitionCancelled: resetWhenSettled = true
        default: break
        }
    }

    private func resetToReady() {
        phase = .ready
        cardOffset = .zero
        showsTapHint = false
        showsSaveFailure = false
    }

    private func recognize(reduceMotion: Bool) {
        recognitionID += 1
        transitionToken += 1
        transitionCancelled = false
        resetWhenSettled = false
        showsSaveFailure = false
        phase = .contacting
        // 발급과 달리 승차는 동작 줄이기에서 진동도 생략한다(PRD FR-16).
        if !reduceMotion, haptics.isSupported { haptics.play(.boardingContact) }
        let id = recognitionID
        let contact = timing.contact(reduceMotion: reduceMotion)
        if contact == .zero {
            commit(id, reduceMotion: reduceMotion)
        } else {
            pendingSave = Task { [weak self] in
                guard let self else { return }
                await self.sleep(contact)
                self.commit(id, reduceMotion: reduceMotion)
            }
        }
    }

    private func commit(_ id: Int, reduceMotion: Bool) {
        guard recognitionID == id, phase == .contacting else { return }
        guard save() else {
            awaitingRelease = hasDragged
            phase = .failed
            cardOffset = .zero
            showsSaveFailure = true
            announcer.announce(copy.failedAnnouncement)
            return
        }
        announcer.announce(copy.recognizedAnnouncement)
        if transitionCancelled {
            if resetWhenSettled { resetToReady() } else { phase = .abandoned }
            return
        }
        phase = .held
        let token = transitionToken
        let fade = timing.fade(reduceMotion: reduceMotion)
        pendingTransition = Task { [weak self] in
            guard let self else { return }
            await (self.holdSleep ?? self.sleep)(self.timing.hold)
            guard self.transitionToken == token, self.phase == .held else { return }
            self.phase = .fading
            if fade > .zero { await self.sleep(fade) }
            guard self.transitionToken == token, self.phase == .fading else { return }
            self.phase = .finished
            self.onFinished()
        }
    }
}
