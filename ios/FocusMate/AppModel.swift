import Foundation
import Observation

enum LaunchState: Equatable { case loading, ready(LaunchRoute), failed(StorageIssue) }
enum Destination: String, Hashable, CaseIterable {
    case preparation, records, settings, profile, time
    var title: String {
        switch self {
        case .time: "시간 선택"
        case .preparation: "여행 준비"
        case .records: "기록"
        case .settings: "설정"
        case .profile: "마이페이지"
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
    private(set) var recoveryFailure: StorageRecoveryIssue?
    private(set) var isRecovering = false
    private(set) var hasAttemptedCleanup = false
    private var cleanupSource: RecoverySource?
    var isCleanupConfirmationPresented: Bool { cleanupSource != nil }
    private let store: LocalSnapshotStore
    private let cardFactory: CardSnapshotFactory
    let soundPreview: SoundPreviewController
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var hasAttemptedSupplement = false
    init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init(),
         soundPreview: SoundPreviewController? = nil) {
        self.store = store
        self.cardFactory = cardFactory
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
            let restored = try store.load() ?? .empty
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

    @discardableResult
    func saveRecordMemo(_ memo: String, forJourneyID id: String) -> Bool {
        guard let original = snapshotForRecordChange() else { return false }
        do {
            let records = try original.records.updatingMemo(memo, forJourneyID: id)
            // Swift String의 정규화 동등성 대신 저장 원문의 코드 단위를 비교한다.
            let unchanged = zip(original.records.items, records.items).allSatisfy {
                $0.memo.utf16.elementsEqual($1.memo.utf16)
            }
            guard !unchanged else { saveFailure = nil; return true }
            return save(original.updating(records: records))
        } catch let issue as RecordValidationIssue {
            saveFailure = .invalidState(.invalidRecords(issue))
        } catch { saveFailure = .writeFailed }
        return false
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
        path.append(destination)
    }
    func goBack() {
        guard launchState == .ready(.main), !path.isEmpty else { return }
        path.removeLast()
    }
}
extension AppModel: CardIssuing {}

extension AppModel: CardCustomizationSaving {
    func beginCardCustomization() -> CardCustomizationController? {
        guard case .ready = launchState, let snapshot, snapshot.cardIssued,
              let card = snapshot.currentCard else { return nil }
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
