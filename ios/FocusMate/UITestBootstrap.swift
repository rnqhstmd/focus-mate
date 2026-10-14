#if DEBUG
import Foundation
import Observation

struct UITestBootstrap {
    let fileURL: URL
    let seed: String?
    let shouldFailSound: Bool
    let shouldFailSave: Bool
    let issueHold: IssueHold
    enum IssueHold { case standard, manual }
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
        guard seed == nil || Self.seeds.contains(seed!) else { throw SetupIssue.invalidArguments }
        let save = try argument("--fm-ui-save")
        guard save == nil || save == "fail" else { throw SetupIssue.invalidArguments }
        shouldFailSave = save == "fail"
        let sound = try argument("--fm-ui-sound")
        guard sound == nil || sound == "fail" else { throw SetupIssue.invalidArguments }
        shouldFailSound = sound == "fail"
        let hold = try argument("--fm-ui-issue-hold")
        guard hold == nil || hold == "manual" else { throw SetupIssue.invalidArguments }
        issueHold = hold == "manual" ? .manual : .standard
        recoveryScenario = try argument("--fm-ui-recovery")
        guard recoveryScenario == nil || ["readOnce", "readAlways", "backupFail", "backupMismatch", "cleanupFail"].contains(recoveryScenario!) else { throw SetupIssue.invalidArguments }
        fileURL = applicationSupport.appendingPathComponent("FocusMate/UITests", isDirectory: true)
            .appendingPathComponent(uuid.uuidString, isDirectory: true).appendingPathComponent("app-state.json")
    }

    private static let seeds: Set<String> = Set(["none", "cardOnly", "ready", "issuedWithoutCard"]).union(rawSeeds.keys)

    func prepare() throws {
        guard let seed else { return }
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { throw SetupIssue.existingSeed }
        switch seed {
        case "none": break
        case "cardOnly": try LocalSnapshotStore(fileURL: fileURL).save(AppSnapshot.empty.issuingCard(Self.fixedCard))
        case "ready": try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot.issuingCard(Self.fixedCard))
        case "issuedWithoutCard": try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot)
        default:
            guard let raw = Self.rawSeeds[seed] else { throw SetupIssue.invalidArguments }
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(raw.utf8).write(to: fileURL, options: .atomic)
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

    /// `fail`은 모든 쓰기를 실패시킨다. 메인에서는 정류장 저장 시나리오를 적용하고, 발급 화면에서는 발급이 실패 저장소를 타게 둔다.
    @MainActor func applySaveScenario(to model: AppModel) throws {
        // 쓰기 실패 저장소는 모든 진입 상태에 주입된다. 시드 실패 저장 1회는 메인에서만 일으킨다(발급 화면은 발급이 실패 저장소를 탄다).
        guard shouldFailSave, model.launchState == .ready(.main) else { return }
        guard let original = model.snapshot else { throw SetupIssue.invalidSaveState }
        model.save(original.updatingStage(cardIssued: original.cardIssued, initialStation: original.initialStation,
                                          currentStation: StationSnapshot(id: "ttukseom", name: "뚝섬", direction: 1)))
    }

    @MainActor func makeSoundPreview() -> SoundPreviewController? {
        guard shouldFailSound else { return nil }
        return SoundPreviewController(sound: .bus, makePlayer: { _ in throw SetupIssue.invalidArguments })
    }

    @MainActor func makeFeedbackRecorder() -> UITestFeedbackRecorder { UITestFeedbackRecorder() }
    @MainActor func makeGate() -> UITestIssuanceGate? { issueHold == .manual ? UITestIssuanceGate() : nil }

    var persistedBytes: String {
        do { return try Data(contentsOf: fileURL).base64EncodedString() }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return "absent" }
        catch { return "unreadable" }
    }

    private static let fixedCard = CardSnapshot(id: "FM-20261013", issuedAt: Date(timeIntervalSince1970: 1_791_882_000))

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

    private static let stations = #""currentStation":{"direction":-1,"id":"seoulForest","name":"서울숲"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"}"#
    private static let card = #"{"id":"FM-20261013","issuedAt":"2026-10-13T09:00:00Z"}"#
    private static func state(issued: Bool = true, cards: String, records: String = "", stations: String = stations) -> String {
        #"{"state":{"cardIssued":\#(issued),"cards":{"items":[\#(cards)]},\#(stations),"journey":{"active":null},"records":{"items":[\#(records)]}},"version":2}"#
    }
    /// 파일에 그대로 쓰는 원본 바이트 시드.
    static let rawSeeds: [String: String] = [
        "corrupt": "{broken",
        "unsupported": #"{"version":999,"state":null}"#,
        "invalidState": #"{"version":1,"state":{"cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":null}}"#,
        "invalidCardShortId": state(cards: #"{"id":"FM-1234","issuedAt":"2026-10-13T09:00:00Z"}"#),
        "invalidCardPrefix": state(cards: #"{"id":"NS-12345678","issuedAt":"2026-10-13T09:00:00Z"}"#),
        "invalidCardIssuedAt": state(cards: #"{"id":"FM-20261013","issuedAt":"어제"}"#),
        "duplicateCards": state(cards: card + "," + #"{"id":"FM-20261014","issuedAt":"2026-10-13T09:00:00Z"}"#),
        "cardWithoutIssuance": state(issued: false, cards: card, stations: #""currentStation":null,"initialStation":null"#),
        "undefinedRecord": state(cards: "", records: #"{"kind":"x"}"#),
        // 마이페이지 UI 테스트: 카드 번호 FM-12345678과 완료 기록 3건(25·25·15분, 합 65분).
        // 버전 2 형식이다. 카드 꾸미기(W10)가 합류하면 버전 3 변환(카드 style 기본값)을 거쳐 읽힌다.
        "profileRecords": state(cards: #"{"id":"FM-12345678","issuedAt":"2026-10-13T09:00:00Z"}"#,
                                records: ##"{"bus":"버스2014","completedAt":"2026-10-13T03:00:00Z","date":"2026-10-13","from":"성수역","id":"journey-a","memo":"","minutes":25,"sound":"빗소리","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","to":"서울숲 입구"},{"bus":"버스2014","completedAt":"2026-10-13T02:00:00Z","date":"2026-10-13","from":"성수역","id":"journey-b","memo":"","minutes":25,"sound":"빗소리","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","to":"서울숲 입구"},{"bus":"버스2014","completedAt":"2026-10-13T01:00:00Z","date":"2026-10-13","from":"성수역","id":"journey-c","memo":"","minutes":15,"sound":"빗소리","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","to":"서울숲 입구"}"##),
    ]
}

/// UI 테스트에서 햅틱·안내를 기록한다. 햅틱 지원은 항상 true로 두어 "0회" 단언이 의미를 갖게 한다.
@MainActor @Observable
final class UITestFeedbackRecorder: IssuanceHaptics, AccessibilityAnnouncing {
    let isSupported = true
    private(set) var playCount = 0
    private(set) var patterns: [IssuanceHapticPattern] = []
    private(set) var announcements: [String] = []
    @ObservationIgnored private let system = SystemAccessibilityAnnouncer()

    func play(_ pattern: IssuanceHapticPattern) { playCount += 1; patterns.append(pattern) }
    func announce(_ message: String) { announcements.append(message); system.announce(message) }
}

/// `--fm-ui-issue-hold manual`: 테스트가 해제할 때까지 발급 중 상태를 붙잡는다.
@MainActor @Observable
final class UITestIssuanceGate {
    @ObservationIgnored private var waiter: CheckedContinuation<Void, Never>?
    @ObservationIgnored private var releasedEarly = false

    func wait(_ duration: Duration) async {
        if releasedEarly { releasedEarly = false; return }
        await withCheckedContinuation { waiter = $0 }
    }

    func release() {
        guard let waiter else { releasedEarly = true; return }
        self.waiter = nil
        waiter.resume()
    }
}
#endif
