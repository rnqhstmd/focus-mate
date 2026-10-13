import Foundation
import Observation

enum LaunchState: Equatable { case loading, ready(LaunchRoute), failed(StorageIssue) }
enum Destination: String, Hashable, CaseIterable {
    case preparation, records, settings, profile
    var title: String {
        switch self {
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
    private let store: LocalSnapshotStore
    private let cardFactory: CardSnapshotFactory
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var hasAttemptedSupplement = false
    init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init()) {
        self.store = store
        self.cardFactory = cardFactory
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

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            let restored = try store.load() ?? .empty
            let route = try restored.launchRoute()
            snapshot = restored
            launchState = .ready(route)
        } catch let issue as StorageIssue {
            snapshot = nil; path = []; launchState = .failed(issue)
        } catch {
            snapshot = nil; path = []; launchState = .failed(.unreadable)
        }
    }

    @discardableResult
    func save(_ candidate: AppSnapshot) -> Bool {
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
