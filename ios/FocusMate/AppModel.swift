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
    private let store: LocalSnapshotStore
    @ObservationIgnored private var hasLoaded = false
    init(store: LocalSnapshotStore) { self.store = store }

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
        guard case let .ready(previousRoute) = launchState else {
            if case let .failed(issue) = launchState { saveFailure = .writeBlocked(issue) }
            else { saveFailure = .notReady }
            return false
        }
        do {
            let nextRoute = try candidate.launchRoute()
            try store.save(candidate)
            snapshot = candidate; launchState = .ready(nextRoute); saveFailure = nil
            if previousRoute != nextRoute { path = [] }
            return true
        } catch let issue as SnapshotValidationIssue { saveFailure = .invalidState(issue) }
        catch let issue as StorageIssue { saveFailure = issue }
        catch { saveFailure = .writeFailed }
        return false
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
