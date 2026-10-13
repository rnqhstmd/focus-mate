#if DEBUG
import Foundation

struct UITestBootstrap {
    let fileURL: URL
    let seed: String?
    let shouldFailSave: Bool
    private let recoveryScenario: String?
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
        guard seed == nil || ["none", "cardOnly", "ready", "corrupt", "unsupported", "invalidState"].contains(seed!) else { throw SetupIssue.invalidArguments }
        let save = try argument("--fm-ui-save")
        guard save == nil || save == "fail" else { throw SetupIssue.invalidArguments }
        shouldFailSave = save == "fail"
        recoveryScenario = try argument("--fm-ui-recovery")
        guard recoveryScenario == nil || ["readOnce", "readAlways", "backupFail", "backupMismatch", "cleanupFail"].contains(recoveryScenario!) else { throw SetupIssue.invalidArguments }
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
        case "invalidState":
            let raw = #"{"version":1,"state":{"cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":null}}"#
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(raw.utf8).write(to: fileURL, options: .atomic)
        default: throw SetupIssue.invalidArguments
        }
    }

    var modelStore: LocalSnapshotStore {
        let activeURL = fileURL
        let scenario = recoveryScenario
        let failSave = shouldFailSave
        var activeReads = 0
        return LocalSnapshotStore(fileURL: activeURL, readData: { url in
            if url == activeURL {
                activeReads += 1
                if scenario == "readAlways" || (scenario == "readOnce" && activeReads == 1) {
                    throw CocoaError(.fileReadNoPermission)
                }
            }
            return try Data(contentsOf: url)
        }, writeData: { data, url in
            if failSave { throw StorageIssue.writeFailed }
            try data.write(to: url, options: .atomic)
        }, writeBackup: { data, url in
            if scenario == "backupFail" { throw StorageRecoveryIssue.backupFailed }
            let bytes = scenario == "backupMismatch" ? data + Data([0]) : data
            try bytes.write(to: url, options: .withoutOverwriting)
        }, removeData: { url in
            if scenario == "cleanupFail" { throw StorageRecoveryIssue.cleanupFailed }
            try FileManager.default.removeItem(at: url)
        })
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

    var backupBytes: String {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: fileURL.deletingLastPathComponent(), includingPropertiesForKeys: nil)
            var values: [String: String] = [:]
            for url in files where url.lastPathComponent.hasPrefix("app-state.recovery-") && url.pathExtension == "backup" {
                values[url.lastPathComponent] = try Data(contentsOf: url).base64EncodedString()
            }
            let data = try JSONSerialization.data(withJSONObject: values, options: .sortedKeys)
            return String(decoding: data, as: UTF8.self)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile { return "{}" }
        catch { return "unreadable" }
    }

    private static let readySnapshot = AppSnapshot.empty.updatingStage(cardIssued: true,
        initialStation: StationSnapshot(id: "seongsu", name: "성수", direction: 1),
        currentStation: StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
}
#endif
