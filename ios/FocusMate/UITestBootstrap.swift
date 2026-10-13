#if DEBUG
import Foundation

struct UITestBootstrap {
    let fileURL: URL
    let seed: String?
    let shouldFailSave: Bool
    enum SetupIssue: Error { case invalidArguments, existingSeed, invalidSaveState }

    init?(arguments: [String], applicationSupport: URL) throws {
        func argument(_ key: String) throws -> String? {
            guard let index = arguments.firstIndex(of: key) else { return nil }
            guard index + 1 < arguments.count else { throw SetupIssue.invalidArguments }
            return arguments[index + 1]
        }
        guard let id = try argument("--fm-ui-test-id") else { return nil }
        guard let uuid = UUID(uuidString: id) else { throw SetupIssue.invalidArguments }
        seed = try argument("--fm-ui-seed")
        guard seed == nil || ["none", "cardOnly", "ready", "corrupt", "unsupported"].contains(seed!) else { throw SetupIssue.invalidArguments }
        let save = try argument("--fm-ui-save")
        guard save == nil || save == "fail" else { throw SetupIssue.invalidArguments }
        shouldFailSave = save == "fail"
        fileURL = applicationSupport.appendingPathComponent("FocusMate/UITests", isDirectory: true)
            .appendingPathComponent(uuid.uuidString, isDirectory: true).appendingPathComponent("app-state.json")
    }

    func prepare() throws {
        guard let seed else { return }
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { throw SetupIssue.existingSeed }
        switch seed {
        case "none": break
        case "cardOnly": try LocalSnapshotStore(fileURL: fileURL).save(AppSnapshot.empty.updatingStage(cardIssued: true, initialStation: nil, currentStation: nil))
        case "ready": try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot)
        case "corrupt", "unsupported":
            let raw = seed == "corrupt" ? "{broken" : #"{"version":999,"state":null}"#
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(raw.utf8).write(to: fileURL, options: .atomic)
        default: throw SetupIssue.invalidArguments
        }
    }

    var modelStore: LocalSnapshotStore {
        if shouldFailSave { return LocalSnapshotStore(fileURL: fileURL, writeData: { _, _ in throw StorageIssue.writeFailed }) }
        return LocalSnapshotStore(fileURL: fileURL)
    }

    @MainActor func applySaveScenario(to model: AppModel) throws {
        // 쓰기 실패 저장소는 모든 진입 상태에 주입된다. 시드 실패 저장 1회는 메인에서만 일으킨다.
        guard shouldFailSave, model.launchState == .ready(.main) else { return }
        guard let original = model.snapshot else { throw SetupIssue.invalidSaveState }
        model.save(original.updatingStage(cardIssued: original.cardIssued, initialStation: original.initialStation,
                                          currentStation: StationSnapshot(id: "ttukseom", name: "뚝섬", direction: 1)))
    }

    var persistedBytes: String {
        do { return try Data(contentsOf: fileURL).base64EncodedString() }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return "absent" }
        catch { return "unreadable" }
    }

    private static let readySnapshot = AppSnapshot.empty.updatingStage(cardIssued: true,
        initialStation: StationSnapshot(id: "seongsu", name: "성수", direction: 1),
        currentStation: StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
}
#endif
