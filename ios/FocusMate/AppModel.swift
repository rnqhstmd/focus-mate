import Foundation
import Observation

enum LaunchState: Equatable { case loading, ready(LaunchRoute), failed(StorageIssue) }
enum Destination: String, Hashable, CaseIterable {
    case preparation, records, settings, profile, time, board, boarding, journey, alighting, alightingSummary
    var title: String {
        switch self {
        case .time: "시간 선택"
        case .board: "승차권"
        case .boarding: "승차 태그"
        case .journey: "여행"
        case .preparation: "여행 준비"
        case .records: "기록"
        case .settings: "설정"
        case .profile: "마이페이지"
        case .alighting: "하차 태그"
        case .alightingSummary: "요약"
        }
    }
}

@MainActor @Observable
final class AppModel {
    private(set) var launchState: LaunchState = .loading
    private(set) var snapshot: AppSnapshot?
    var path: [Destination] = []
    private(set) var saveFailure: StorageIssue?
    /// 기존 사용자 카드 보충의 실패. 화면에 표시하지 않고 다음 실행에서 다시 시도한다(BR-8).
    private(set) var supplementFailure: StorageIssue?
    /// 발급 직후 저장 단계는 이미 다음 단계지만, 사용자가 진행할 때까지 발급 완료 화면을 유지한다. 메모리에만 둔다(A3).
    private var isHoldingIssuedCard = false
    var journeyPlan = JourneyPlanDraft()
    var preparation = PreparationDraft()
    private var storedConfirmedPreparation: PreparedJourneyDetails?
    private var storedPreparationRequest: PreparedJourneyDetails?
    private var currentPreparationDetails: PreparedJourneyDetails? {
        guard launchState == .ready(.main), let journey = preparedJourney,
              preparation.isComplete, let tag = preparation.selectedTag else { return nil }
        return PreparedJourneyDetails(journey: journey, tag: tag,
                                      task: preparation.trimmedTask, sound: preparation.sound)
    }
    var confirmedPreparation: PreparedJourneyDetails? {
        storedConfirmedPreparation == currentPreparationDetails ? storedConfirmedPreparation : nil
    }
    var preparationRequest: PreparedJourneyDetails? {
        storedPreparationRequest == currentPreparationDetails ? storedPreparationRequest : nil
    }
    var canConfirmPreparation: Bool { currentPreparationDetails != nil }
    /// 승차권 보기로 확정한 준비 값. 승차 저장은 이 값을 쓴다(인식 뒤 초안이 바뀌어도 확정 당시 값).
    var boardingDetails: PreparedJourneyDetails? { storedConfirmedPreparation }
    func discardConfirmedPreparation() {
        storedConfirmedPreparation = nil
        storedPreparationRequest = nil
    }
    @discardableResult func confirmPreparation() -> Bool {
        guard let details = currentPreparationDetails else {
            storedConfirmedPreparation = nil
            storedPreparationRequest = nil
            return false
        }
        storedConfirmedPreparation = details
        storedPreparationRequest = details
        return true
    }
    func consumePreparationRequest() -> PreparedJourneyDetails? {
        guard let current = currentPreparationDetails,
              storedConfirmedPreparation == current else {
            storedConfirmedPreparation = nil
            storedPreparationRequest = nil
            return nil
        }
        guard let request = storedPreparationRequest else { return nil }
        guard request == current else {
            storedConfirmedPreparation = nil
            storedPreparationRequest = nil
            return nil
        }
        storedPreparationRequest = nil
        return request
    }
    /// 포기한 정류장 이름. 메인 안내용 메모리 값이며 다른 화면으로 가면 지운다(BR-10). 설정은 lifecycle 확장에서만 한다.
    var abandonNotice: String?
    /// 이번 실행에서 이어가기 저장에 성공한 여정 id. 타이머가 한 번 소비한다.
    @ObservationIgnored var resumeEntryJourneyID: String?
    /// 방금 하차한 여정의 요약. 메모리 전용이라 재실행하면 사라진다(AC-13). 설정은 Alighting 확장에서만 한다.
    var alightingSummary: AlightingSummary?
    private(set) var recoveryFailure: StorageRecoveryIssue?
    private(set) var isRecovering = false
    private(set) var hasAttemptedCleanup = false
    private var cleanupSource: RecoverySource?
    var isCleanupConfirmationPresented: Bool { cleanupSource != nil }
    private let store: LocalSnapshotStore
    private let cardFactory: CardSnapshotFactory
    let journeyFactory: ActiveJourneyFactory
    let soundPreview: SoundPreviewController
    /// 하차 시각·로컬 날짜, 기록 화면의 '오늘'.
    let recordClock: RecordClock
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var hasAttemptedSupplement = false
    init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init(),
         soundPreview: SoundPreviewController? = nil, journeyFactory: ActiveJourneyFactory = .init(),
         recordClock: RecordClock = .live) {
        self.store = store
        self.recordClock = recordClock
        self.cardFactory = cardFactory
        self.journeyFactory = journeyFactory
        self.soundPreview = soundPreview ?? SoundPreviewController(sound: .bus,
            makePlayer: { try await AVSoundPreviewPlayer.make(sound: $0) })
    }

    /// 화면 분기는 이 값만 쓴다. `launchState`는 로딩·실패 판단과 모델 내부 가드용이다.
    var presentedRoute: LaunchRoute? {
        guard case let .ready(route) = launchState else { return nil }
        return isHoldingIssuedCard ? .cardEntry : route
    }

    /// 읽기(`loadIfNeeded`)와 보충 쓰기를 분리해 둔다 — 읽기는 쓰지 않는다.
    func start() {
        loadIfNeeded()
        supplementCardIfNeeded()
    }

    func supplementCardIfNeeded() {
        guard !hasAttemptedSupplement, case .ready = launchState,
              let snapshot, snapshot.needsCardSupplement else { return }
        hasAttemptedSupplement = true
        let candidate = snapshot.updating(cards: CardSection(items: [cardFactory.make()]))
        do {
            try store.save(candidate)
            self.snapshot = candidate
        } catch let issue as StorageIssue { supplementFailure = issue }
        catch { supplementFailure = .writeFailed }
    }

    @discardableResult
    func issueCard() -> Bool {
        guard launchState == .ready(.cardEntry), let snapshot, !snapshot.cardIssued else { return false }
        guard persist(snapshot.issuingCard(cardFactory.make())) == nil else { return false }
        isHoldingIssuedCard = true
        return true
    }

    func finishCardIssuance() { isHoldingIssuedCard = false }

    func retryLoad() {
        guard case .failed = launchState, cleanupSource == nil, !isRecovering else { return }
        recoveryFailure = nil
        isRecovering = true
        defer { isRecovering = false }
        loadSnapshot()
    }

    func requestCleanup() {
        guard case .failed = launchState, cleanupSource == nil, !isRecovering else { return }
        recoveryFailure = nil
        isRecovering = true
        defer { isRecovering = false }
        cleanupSource = store.recoverySource()
    }

    func cancelCleanup() {
        guard !isRecovering else { return }
        cleanupSource = nil
    }

    @discardableResult func confirmCleanup() -> Bool {
        guard case .failed = launchState, let source = cleanupSource, !isRecovering else { return false }
        cleanupSource = nil
        hasAttemptedCleanup = true
        isRecovering = true
        defer { isRecovering = false }
        do {
            _ = try store.backupAndClear(expectedSource: source)
            snapshot = .empty
            launchState = .ready(.cardEntry)
            path = []
            saveFailure = nil
            recoveryFailure = nil
            return true
        } catch let issue as StorageRecoveryIssue { recoveryFailure = issue }
        catch { recoveryFailure = .backupFailed }
        return false
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadSnapshot()
    }

    private func loadSnapshot() {
        do {
            let loaded = try store.load() ?? .empty
            // 앱 종료는 여정이 끊긴 것으로 본다. 진행 중이던 여정은 메모리에서만 일시정지로 두고 파일은 다음 저장 때 바뀐다.
            let restored = loaded.journey.active.map { loaded.updating(journey: JourneySection(active: $0.restingForLaunch())) } ?? loaded
            let route = try restored.launchRoute()
            snapshot = restored
            launchState = .ready(route)
            path = []
            saveFailure = nil
        } catch let issue as StorageIssue {
            snapshot = nil; path = []; launchState = .failed(issue)
        } catch {
            snapshot = nil; path = []; launchState = .failed(.unreadable)
        }
    }

    @discardableResult
    func save(_ candidate: AppSnapshot) -> Bool {
        guard !isRecovering else { return false }
        saveFailure = persist(candidate)
        return saveFailure == nil
    }

    /// 실패를 호출자가 그 화면에서 직접 안내하는 저장(W07). 실패해도 상태가 바뀌지 않았으므로 일반 `saveFailure`를 남기지 않는다.
    func saveHandlingFailure(_ candidate: AppSnapshot) -> Bool {
        guard !isRecovering, persist(candidate) == nil else { return false }
        saveFailure = nil
        return true
    }

    /// 저장에 성공하면 snapshot·경로를 바꾸고 nil, 실패하면 아무것도 바꾸지 않고 원인을 돌려준다.
    private func persist(_ candidate: AppSnapshot) -> StorageIssue? {
        guard case let .ready(previousRoute) = launchState else {
            if case let .failed(issue) = launchState { return .writeBlocked(issue) }
            return .notReady
        }
        do {
            let nextRoute = try candidate.launchRoute()
            try store.save(candidate)
            snapshot = candidate; launchState = .ready(nextRoute)
            if previousRoute != nextRoute { path = [] }
            return nil
        } catch let issue as SnapshotValidationIssue { return .invalidState(issue) }
        catch let issue as StorageIssue { return issue }
        catch { return .writeFailed }
    }

    @discardableResult
    func recordCompletion(_ input: RecordCompletionInput, outcome: RecordCompletionOutcome,
                          isExample: Bool = false, timeZone: TimeZone) -> Bool {
        guard let original = snapshotForRecordChange() else { return false }
        do {
            let records = try original.records.recordingCompletion(input, outcome: outcome,
                isExample: isExample, timeZone: timeZone)
            guard outcome == .alighted, !isExample else { saveFailure = nil; return false }
            guard records.items.count != original.records.items.count else { saveFailure = nil; return true }
            return save(original.updating(records: records))
        } catch let issue as RecordValidationIssue {
            saveFailure = .invalidState(.invalidRecords(issue))
        } catch { saveFailure = .writeFailed }
        return false
    }

    /// 기록 메모 저장. 화면이 실패를 직접 안내하므로 일반 `saveFailure`를 남기지 않는다(W07 규칙).
    @discardableResult
    func updateRecordMemo(_ memo: String, forJourneyID id: String) -> LifecycleActionResult {
        guard let original = snapshotForRecordChange() else { return .rejected }
        guard let records = try? original.records.updatingMemo(memo, forJourneyID: id) else { return .saveFailed }
        // Swift String의 정규화 동등성 대신 저장 원문의 코드 단위를 비교한다.
        let unchanged = zip(original.records.items, records.items).allSatisfy {
            $0.memo.utf16.elementsEqual($1.memo.utf16)
        }
        guard !unchanged else { return .done }
        return saveHandlingFailure(original.updating(records: records)) ? .done : .saveFailed
    }

    private func snapshotForRecordChange() -> AppSnapshot? {
        guard case .ready = launchState, let snapshot else {
            if case let .failed(issue) = launchState { saveFailure = .writeBlocked(issue) }
            else { saveFailure = .notReady }
            return nil
        }
        return snapshot
    }

    func open(_ destination: Destination) {
        guard launchState == .ready(.main) else { return }
        abandonNotice = nil
        // 승차권·승차 태그는 확정된 준비가 있을 때만 열린다(어떤 경로로도 미완성 준비로 들어가지 않는다).
        if destination == .board || destination == .boarding, confirmedPreparation == nil || hasDepartedJourney { return }
        if destination == .journey, activeJourney == nil { return }
        // 하차 화면은 모델 메서드로만 열고, 도착 여정이 남아 있으면 새 여정 경로를 막는다(BR-6).
        if destination == .alighting || destination == .alightingSummary { return }
        if activeJourney?.isArrived == true, [.time, .preparation, .board, .boarding].contains(destination) { return }
        path.append(destination)
    }
    func goBack() {
        guard launchState == .ready(.main), !path.isEmpty else { return }
        // 출발한 여행 화면에서 메인으로 가는 길은 포기뿐이다(W07, FR-10).
        if path.last == .journey, hasDepartedJourney { return }
        if path.last == .alighting || path.last == .alightingSummary { return }
        path.removeLast()
    }
}
extension AppModel: CardIssuing {}

extension AppModel: CardCustomizationSaving {
    func beginCardCustomization() -> CardCustomizationController? {
        guard case .ready = launchState, let snapshot, snapshot.cardIssued,
              let card = snapshot.currentCard else { return nil }
        // 꾸미기 화면은 `open`을 거치지 않으므로 포기 안내를 여기서 지운다(BR-10).
        abandonNotice = nil
        return CardCustomizationController(card: card, saver: self)
    }

    func saveCardStyle(_ style: CardStyle, forCardID id: String) -> Bool {
        guard case .ready = launchState, let snapshot, snapshot.cardIssued,
              let card = snapshot.currentCard, card.id == id else {
            if case let .failed(issue) = launchState { saveFailure = .writeBlocked(issue) }
            else { saveFailure = .notReady }
            return false
        }
        let cards = CardSection(items: snapshot.cards.items.map {
            $0.id == id ? $0.updating(style: style) : $0
        })
        return save(snapshot.updating(cards: cards))
    }

    var currentCardStyle: CardStyle { snapshot?.currentCard?.style ?? .standard }
}
