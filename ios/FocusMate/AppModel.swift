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
