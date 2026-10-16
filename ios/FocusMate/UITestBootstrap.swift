#if DEBUG
import Foundation
import Observation
import CryptoKit
import UIKit

struct UITestBootstrap {
    let photoManifestURL: URL?
    let cardImportManual: Bool
    let cardSaveFailure: UITestCardSaveFailure
    let fileURL: URL
    let seed: String?
    let shouldFailSound: Bool
    let shouldFailSave: Bool
    let issueHold: IssueHold
    let boardingHoldManual: Bool
    let forcedReduceMotion: Bool
    let route: String?
    let boardingSaveFailure: UITestCardSaveFailure
    let manualClock: Bool
    /// `--fm-ui-route-data`: fixture(기본, `RouteCatalog.uiTestFixture()`)·bundled(번들 서울 전체)·pending(로딩이 끝나지 않음)·failed.
    let routeDataMode: String
    let nextSaveFailure = UITestNextSaveFailure()
    let writeCounter = UITestWriteCounter()
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
        let manifest = try argument("--fm-ui-card-photo-manifest")
        let support = applicationSupport.standardizedFileURL.resolvingSymlinksInPath()
        if let manifest {
            let url = (manifest.hasPrefix("/") ? URL(fileURLWithPath: manifest) : support.appendingPathComponent(manifest)).standardizedFileURL.resolvingSymlinksInPath()
            guard url.path.hasPrefix(support.path + "/") else { throw SetupIssue.invalidArguments }
            photoManifestURL = url
            Self.stagePhotoFixtures(support: support)
        } else { photoManifestURL = nil }
        let cardHold = try argument("--fm-ui-card-import-hold")
        guard cardHold == nil || cardHold == "manual" else { throw SetupIssue.invalidArguments }
        cardImportManual = cardHold == "manual"
        let cardSave = try argument("--fm-ui-card-save")
        guard cardSave == nil || cardSave == "fail-once" else { throw SetupIssue.invalidArguments }
        cardSaveFailure = UITestCardSaveFailure(enabled: cardSave == "fail-once")
        seed = try argument("--fm-ui-seed")
        guard seed == nil || Self.seeds.contains(seed!) else { throw SetupIssue.invalidArguments }
        let save = try argument("--fm-ui-save")
        guard save == nil || save == "fail" || save == "fail-once-boarding" else { throw SetupIssue.invalidArguments }
        shouldFailSave = save == "fail"
        boardingSaveFailure = UITestCardSaveFailure(enabled: save == "fail-once-boarding")
        let boardingHold = try argument("--fm-ui-boarding-hold")
        guard boardingHold == nil || boardingHold == "manual" else { throw SetupIssue.invalidArguments }
        boardingHoldManual = boardingHold == "manual"
        let reduce = try argument("--fm-ui-reduce-motion")
        guard reduce == nil || reduce == "on" else { throw SetupIssue.invalidArguments }
        forcedReduceMotion = reduce == "on"
        route = try argument("--fm-ui-route")
        guard route == nil || (route == "boarding" && seed == "ready") || route == "journey" else { throw SetupIssue.invalidArguments }
        let clock = try argument("--fm-ui-clock")
        guard clock == nil || clock == "manual" else { throw SetupIssue.invalidArguments }
        manualClock = clock == "manual"
        let sound = try argument("--fm-ui-sound")
        guard sound == nil || sound == "fail" else { throw SetupIssue.invalidArguments }
        shouldFailSound = sound == "fail"
        let hold = try argument("--fm-ui-issue-hold")
        guard hold == nil || hold == "manual" else { throw SetupIssue.invalidArguments }
        issueHold = hold == "manual" ? .manual : .standard
        routeDataMode = try argument("--fm-ui-route-data") ?? "fixture"
        guard ["fixture", "bundled", "pending", "failed"].contains(routeDataMode) else { throw SetupIssue.invalidArguments }
        recoveryScenario = try argument("--fm-ui-recovery")
        guard recoveryScenario == nil || ["readOnce", "readAlways", "backupFail", "backupMismatch", "cleanupFail"].contains(recoveryScenario!) else { throw SetupIssue.invalidArguments }
        fileURL = applicationSupport.appendingPathComponent("FocusMate/UITests", isDirectory: true)
            .appendingPathComponent(uuid.uuidString, isDirectory: true).appendingPathComponent("app-state.json")
    }

    /// UI 테스트용 사진 픽스처를 앱 컨테이너에 직접 만든다. 시뮬레이터마다 수동 배치하던 방식은 새 기기에서 재현되지 않았다.
    /// 이미 있는 파일은 덮어쓰지 않는다.
    private static func stagePhotoFixtures(support: URL) {
        let base = support.appendingPathComponent("FocusMate", isDirectory: true)
        let directory = base.appendingPathComponent("UITestPhotoFixtures", isDirectory: true)
        let manager = FileManager.default
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        func png(_ width: Int, _ height: Int, hue: CGFloat, alpha: Bool = false) -> Data {
            let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = !alpha
            return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).pngData { context in
                UIColor(hue: hue, saturation: 0.6, brightness: 0.9, alpha: 1).setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
                UIColor(hue: hue, saturation: 0.9, brightness: 0.4, alpha: alpha ? 0.25 : 1).setFill()
                context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height / 2))
            }
        }
        func manifest(_ names: [String]) -> Data {
            Data(("{\"items\":[" + names.map { "{\"path\":\"\($0)\"}" }.joined(separator: ",") + "]}").utf8)
        }
        var files: [(URL, Data)] = [
            (base.appendingPathComponent("escape.png"), png(48, 32, hue: 0.9)),
            (directory.appendingPathComponent("a.png"), png(120, 80, hue: 0.1)),
            (directory.appendingPathComponent("b.png"), png(80, 120, hue: 0.5, alpha: true)),
            (directory.appendingPathComponent("unreadable.bin"), Data("not an image: unreadable fixture for card photo import".utf8)),
            (directory.appendingPathComponent("valid2.json"), manifest(["a.png", "b.png"])),
            (directory.appendingPathComponent("mixed.json"), manifest(["unreadable.bin", "a.png"])),
            (directory.appendingPathComponent("invalidPaths.json"), manifest(["../escape.png", "missing.png"])),
            (directory.appendingPathComponent("hold.json"), manifest(["a.png"])),
            (directory.appendingPathComponent("seven.json"), manifest((1...7).map { "p\($0).png" }))]
        for n in 1...7 { files.append((directory.appendingPathComponent("p\(n).png"), png(100 + n, 80, hue: CGFloat(n) / 8))) }
        for (url, data) in files where !manager.fileExists(atPath: url.path) { try? data.write(to: url, options: .atomic) }
    }

    @MainActor func cardPhotoInputs(gate: UITestCardImportGate?) -> [CardPhotoInput] {
        guard let manifest = photoManifestURL else { return [] }
        struct Manifest: Decodable { struct Item: Decodable { let path: String }; let items: [Item] }
        guard let bytes = try? Data(contentsOf: manifest), let entries = try? JSONDecoder().decode(Manifest.self, from: bytes) else {
            return [CardPhotoInput { throw CardPhotoProcessingIssue.unreadable }]
        }
        let token = gate?.arm()
        let directory = manifest.deletingLastPathComponent().standardizedFileURL.resolvingSymlinksInPath()
        return entries.items.enumerated().map { index, item in
            CardPhotoInput {
                if index == 0, let gate, let token { try await gate.wait(token) }
                try Task.checkCancellation()
                let lexical = directory.appendingPathComponent(item.path).standardizedFileURL
                let resolved = lexical.resolvingSymlinksInPath()
                guard !item.path.hasPrefix("/"), lexical.path.hasPrefix(directory.path + "/"),
                      resolved.path.hasPrefix(directory.path + "/") else { throw CardPhotoProcessingIssue.unreadable }
                return try Data(contentsOf: resolved)
            }
        }
    }

    @MainActor func cardStyleJSON(model: AppModel, controller: CardCustomizationController?) -> String {
        func color(_ c: CardColor) -> [String: Double] { ["red": c.red, "green": c.green, "blue": c.blue] }
        func photos(_ style: CardStyle) -> [[String: Any]] {
            style.photos.map { ["id": $0.id.uuidString, "pixelWidth": $0.pixelWidth, "pixelHeight": $0.pixelHeight,
                "centerX": $0.centerX, "centerY": $0.centerY, "widthFraction": $0.widthFraction,
                "byteCount": $0.data.count, "sha256": SHA256.hash(data: $0.data).map { String(format: "%02x", $0) }.joined()] }
        }
        let saved = model.currentCardStyle
        let json: [String: Any] = ["cardID": model.snapshot?.currentCard?.id ?? "", "background": color(saved.background),
            "photos": photos(saved), "draft": controller.map { ["background": color($0.draft.background), "photos": photos($0.draft)] as [String: Any] } ?? NSNull(),
            "selectedPhotoID": controller?.selectedPhotoID?.uuidString as Any? ?? NSNull(),
            "isImporting": controller?.isImporting ?? false, "canUndo": controller?.canUndo ?? false, "didSave": controller?.didSave ?? false]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: .sortedKeys) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }

    private static let seeds: Set<String> = Set(["none", "cardOnly", "ready", "issuedWithoutCard", "activeJourney",
                                                 "legacyV4Stations", "invalidMinutesJourney", "stationGone"])
        .union(rawSeeds.keys).union(timerSeeds.keys).union(v3Seeds).union(lifecycleSeeds.keys).union(recordSeeds)

    func prepare() throws {
        guard let seed else { return }
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { throw SetupIssue.existingSeed }
        switch seed {
        case "none": break
        case "cardOnly": try LocalSnapshotStore(fileURL: fileURL).save(AppSnapshot.empty.issuingCard(Self.fixedCard))
        case "ready": try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot.issuingCard(Self.fixedCard))
        case "issuedWithoutCard": try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot)
        case "activeJourney":
            guard let journey = Self.seededJourney else { throw SetupIssue.invalidArguments }
            try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot.issuingCard(Self.fixedCard)
                .updating(journey: JourneySection(active: journey)))
        case let name where Self.timerSeeds[name] != nil:
            guard let snapshot = Self.timerSnapshot(Self.timerSeeds[name]!) else { throw SetupIssue.invalidArguments }
            try LocalSnapshotStore(fileURL: fileURL).save(snapshot)
        case let name where Self.lifecycleSeeds[name] != nil || Self.recordSeeds.contains(name):
            guard let snapshot = Self.lifecycleSnapshot(name) else { throw SetupIssue.invalidArguments }
            try LocalSnapshotStore(fileURL: fileURL).save(snapshot)
        case let name where Self.v3Seeds.contains(name):
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.v3Bytes(name).write(to: fileURL, options: .atomic)
        case "legacyV4Stations", "invalidMinutesJourney":
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try (seed == "legacyV4Stations" ? Self.legacyV4Bytes() : Self.invalidMinutesBytes()).write(to: fileURL, options: .atomic)
        case "stationGone": try LocalSnapshotStore(fileURL: fileURL).save(Self.stationGoneSnapshot)
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
        let cardFailure = cardSaveFailure
        let boardingFailure = boardingSaveFailure
        let nextFailure = nextSaveFailure
        let counter = writeCounter
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
            // 실패 주입보다 먼저 세어 실패한 시도도 포함한다(test.writeAttempts).
            counter.record()
            if failSave || cardFailure.consume() || boardingFailure.consume() || nextFailure.consume() { throw StorageIssue.writeFailed }
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
                                          currentStation: StationSnapshot(id: "ttukseom", name: "뚝섬")))
    }

    /// `--fm-ui-route boarding`: 저장 없이 준비를 확정하고 승차 태그 화면까지 경로를 쌓는다(시드 ready 전용).
    @MainActor func applyRoute(to model: AppModel) throws {
        if route == "journey" {
            // 진단용 진입(autoStart 없음). 실제 이어가기는 `resumeJourney`다.
            guard model.launchState == .ready(.main), model.activeJourney != nil else { throw SetupIssue.invalidSaveState }
            model.open(.journey)
            return
        }
        guard route == "boarding" else { return }
        guard model.launchState == .ready(.main), model.journeyOrigin != nil else { throw SetupIssue.invalidSaveState }
        model.journeyPlan.setMinutes(60)
        // ready 시드의 현재 정류장은 역방향 승강장(seoulForest-r)이라 2014번 역방향 노선이다(60분 → 성수동).
        guard model.chooseJourneyRoute("2014-r") else { throw SetupIssue.invalidSaveState }
        model.preparation.chooseTag(id: "reading")
        model.preparation.setTask("라우트 할 일")
        guard model.confirmPreparation() else { throw SetupIssue.invalidSaveState }
        model.path = [.time, .preparation, .board, .boarding]
    }

    @MainActor func makeJourneyServices(recorder: UITestFeedbackRecorder) -> (JourneyServices, UITestHoldGate?) {
        let gate = boardingHoldManual ? UITestHoldGate() : nil
        var services = JourneyServices.live()
        services.haptics = recorder
        services.announcer = recorder
        services.boardingHoldSleep = gate.map { gate in { await gate.wait($0) } }
        services.forcedReduceMotion = forcedReduceMotion
        let failure = boardingSaveFailure
        services.makeBoarder = { ArmingBoarder(base: $0, failure: failure) }
        services.failNextSave = nextSaveFailure
        // 기존 UI 테스트가 시뮬레이터에 실제 카드를 띄우지 않도록 항상 기록기를 쓴다.
        services.liveActivities = RecordingLiveActivityGateway()
        if manualClock {
            let clock = ManualJourneyClock()
            services.clock = clock
            services.makeTicker = { clock }
            services.beforeForeground = { clock.applyArmedForegroundAdvance() }
            services.testClock = clock
        }
        return (services, gate)
    }

    /// 정류장 데이터 저장소. pending은 로딩을 시작하지 않으므로 앱은 `startRouteData`를 부르지 않는다.
    @MainActor func makeRouteCatalogStore() -> RouteCatalogStore {
        switch routeDataMode {
        case "bundled": RouteCatalogStore(load: { try RouteCatalogLoader.bundled() })
        case "failed": RouteCatalogStore(load: { throw RouteCatalogIssue.malformed })
        case "pending": RouteCatalogStore(load: { throw RouteCatalogIssue.malformed })
        default: RouteCatalogStore(load: { try RouteCatalog.uiTestFixture() })
        }
    }

    var startsRouteData: Bool { routeDataMode != "pending" }

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

    private static let seedTag = JourneySnapshot.Tag(id: "reading", name: "독서", icon: .reading, color: .sand)
    private static let seedBoardedAt = Date(timeIntervalSince1970: 1_791_882_000)

    /// UI 픽스처 카탈로그로 여정 시드를 만든다. 노선·출발 정류장이 데이터에 없으면(*Gone 시드) 도착지는 `override`, 이름은 고정 문구를 쓴다.
    private static func seedJourney(id: String, origin: String, route: String, minutes: Int, task: String,
                                    phase: JourneySnapshot.Phase, elapsed: Int, paused: Bool,
                                    destination override: StationSnapshot? = nil) -> JourneySnapshot? {
        guard let catalog = try? RouteCatalog.uiTestFixture() else { return nil }
        let originIndex = catalog.stopIndex(id: origin)
        let routeIndex = catalog.routeIndex(id: route)
        let leg = originIndex.flatMap { o in
            routeIndex.flatMap { RouteLegFinder.leg(route: $0, originStop: o, minutes: minutes, in: catalog) }
        }
        let computed = leg.map { catalog.stops[$0.stopIndices[$0.stopIndices.count - 1]] }
            .map { StationSnapshot(id: $0.id, name: $0.name) }
        guard let destination = override ?? computed else { return nil }
        let bus = routeIndex.map { catalog.routes[$0] }
        return JourneySnapshot(
            id: id, cardID: fixedCard.id, originStopID: origin,
            originName: originIndex.map { catalog.stops[$0].name } ?? "사라진 정류장", minutes: minutes,
            busID: route, busNumber: bus?.number ?? "999", busKind: bus?.kind ?? "지선",
            destinationStopID: destination.id, destinationName: destination.name,
            tag: seedTag, task: task, sound: .bus, boardedAt: seedBoardedAt,
            phase: phase, progress: JourneySnapshot.Progress(elapsedSeconds: elapsed), paused: paused)
    }

    /// 승차 직후(출발 확인 전) 진행 여정 1건. 성수역에서 2014번 60분(12정류장) → 성동구민체육센터.
    private static var seededJourney: JourneySnapshot? {
        seedJourney(id: "seed-journey", origin: "seongsu", route: "2014", minutes: 60, task: "시드 여정",
                    phase: .awaitingDeparture, elapsed: 0, paused: false)
    }

    /// 타이머 시드: 25분, 서울숲역 출발, 출발 완료·일시정지. 값은 경과 초.
    private static let timerSeeds: [String: Int] = ["timerPaused90": 90, "timerNearArrival": 1440, "timerArrived": 1500]
    /// 옛 형식(v3) 시드. 읽으면 이전되어 정류장·여정이 비워진다.
    private static let v3Seeds: Set<String> = ["v3Awaiting", "v3Departed", "v3InvalidMinutes", "v3UnknownStop"]

    /// 서울숲역(역방향 승강장)에서 2014번 역방향 5정류장 = 성수사거리.
    private static func timerJourney(phase: JourneySnapshot.Phase, elapsed: Int, paused: Bool) -> JourneySnapshot? {
        seedJourney(id: "seed-timer", origin: "seoulForest-r", route: "2014-r", minutes: 25, task: "타이머 시드",
                    phase: phase, elapsed: elapsed, paused: paused)
    }

    private static func timerSnapshot(_ elapsed: Int) -> AppSnapshot? {
        timerJourney(phase: .departed, elapsed: elapsed, paused: true).map {
            readySnapshot.issuingCard(fixedCard).updating(journey: JourneySection(active: $0))
        }
    }

    /// W07 시드: 재실행된 상태(출발 후 일시정지)의 25분 여정. 현재 정류장은 출발 정류장이고 완료 기록 1건이 있다.
    /// W09 alight* 시드는 할 일 "논문"·기록 0건이고, `destination`이 있으면 계산 도착지 대신 그 값을 저장한다.
    /// W16 *Gone 시드는 UI 픽스처에 없는 노선·정류장을 저장한다(BR-13).
    private struct LifecycleSeed {
        let originStopID: String; let routeID: String; let elapsed: Int?
        var task = "생명주기 시드"; var withRecord = true; var destination: StationSnapshot?
    }
    private static let goneDestination = StationSnapshot(id: "gone-dest", name: "사라진 도착지")
    private static let lifecycleSeeds: [String: LifecycleSeed] = [
        "lifePaused90": .init(originStopID: "seongsu", routeID: "2014", elapsed: 90),
        "lifePaused600": .init(originStopID: "seongsu", routeID: "2014", elapsed: 600),
        "lifePaused0": .init(originStopID: "seongsu", routeID: "2014", elapsed: 0),
        "lifePaused299": .init(originStopID: "seongsu", routeID: "2014", elapsed: 299),
        "lifePaused300": .init(originStopID: "seongsu", routeID: "2014", elapsed: 300),
        "lifePaused1499": .init(originStopID: "seongsu", routeID: "2014", elapsed: 1499),
        "lifeReverse300": .init(originStopID: "seongsu-r", routeID: "2014-r", elapsed: 300),
        "lifeWrap900": .init(originStopID: "seongsuBridgeNorth", routeID: "2014", elapsed: 900),
        "lifeArrived": .init(originStopID: "seongsu", routeID: "2014", elapsed: 1500),
        "lifeAwaiting": .init(originStopID: "seongsu", routeID: "2014", elapsed: nil),
        "lifeRouteGone700": .init(originStopID: "seongsu", routeID: "gone-route", elapsed: 700, destination: goneDestination),
        "lifeOriginGone700": .init(originStopID: "gone-stop", routeID: "gone-route", elapsed: 700, destination: goneDestination),
        "alightPaused1499": .init(originStopID: "seongsu", routeID: "2014", elapsed: 1499, task: "논문", withRecord: false),
        "alightArrived": .init(originStopID: "seongsu", routeID: "2014", elapsed: 1500, task: "논문", withRecord: false),
        "alightMismatchArrived": .init(originStopID: "seongsu", routeID: "2014", elapsed: 1500, task: "논문",
                                       withRecord: false, destination: StationSnapshot(id: "ttukseom", name: "뚝섬역")),
    ]
    private static let lifecycleRecord = RecordSnapshot(
        id: "seed-record-1", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", bus: "버스2014", tag: "독서",
        tagColor: "#12ABef", task: "책 한 챕터 읽기", minutes: 25, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: "")

    /// W09 기록 화면 시드. 실행한 날의 정오(로컬)를 기준으로 만들어 날짜 경계에 흔들리지 않는다. 진행 여정은 없다.
    private static let recordSeeds: Set<String> = ["recordsMemo", "recordsTwoYears", "analytics", "analyticsManyTags"]

    private static func recordSnapshot(_ name: String) -> AppSnapshot? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let now = Date()
        guard let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now),
              let year = calendar.dateComponents([.year], from: now).year else { return nil }
        func record(_ id: String, at date: Date, memo: String = "") -> RecordSnapshot? {
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            let key = RecordDay.from(date, timeZone: .current).key
            return RecordSnapshot(id: id, completedAt: formatter.string(from: date), date: key, bus: "2014", tag: "독서",
                                  tagColor: PreparationTagColor.sand.recordHex, task: "책 한 챕터 읽기", minutes: 25,
                                  sound: "버스", from: "성수역", to: "서울숲 입구", memo: memo)
        }
        let items: [RecordSnapshot?]
        switch name {
        case "analyticsManyTags":
            let start = calendar.startOfDay(for: now)
            let formatter = ISO8601DateFormatter()
            items = [("A", 40), ("B", 30), ("C", 20), ("D", 10)].map { tag, minutes in
                RecordSnapshot(id: "analytics-many-\(tag)", completedAt: formatter.string(from: start),
                    date: RecordDay.from(start, timeZone: .current).key, bus: "2014", tag: tag,
                    tagColor: "#D7B378", task: "집중 \(tag)", minutes: minutes,
                    sound: "버스", from: "성수역", to: "서울숲 입구", memo: "")
            }
        case "analytics":
            let start = calendar.startOfDay(for: now)
            let formatter = ISO8601DateFormatter()
            items = (0..<6).map { index in
                RecordSnapshot(id: "analytics-\(index)", completedAt: formatter.string(from: start),
                    date: RecordDay.from(start, timeZone: .current).key, bus: "2014", tag: index.isMultiple(of: 2) ? "독서" : "공부",
                    tagColor: index.isMultiple(of: 2) ? "#D7B378" : "#B49CE1", task: "집중 기록 \(index)", minutes: 25,
                    sound: "버스", from: "성수역", to: "서울숲 입구", memo: (1...4).contains(index) ? "회고 \(index)" : "")
            }
        case "recordsMemo":
            items = (0..<12).map { record("records-memo-\($0)", at: noon.addingTimeInterval(Double(-60 * $0)),
                                          memo: $0 == 1 ? "집중 잘됨" : "") }
        case "recordsTwoYears":
            func lastYear(_ month: Int, _ day: Int) -> Date? {
                calendar.date(from: DateComponents(year: year - 1, month: month, day: day, hour: 12))
            }
            items = [record("records-year-0", at: noon),
                     lastYear(6, 20).flatMap { record("records-year-1", at: $0) },
                     lastYear(3, 10).flatMap { record("records-year-2", at: $0) }]
        default: return nil
        }
        let records = items.compactMap { $0 }
        guard records.count == items.count else { return nil }
        return readySnapshot.issuingCard(fixedCard).updating(records: RecordSection(items: records))
    }

    static func lifecycleSnapshot(_ name: String) -> AppSnapshot? {
        if recordSeeds.contains(name) { return recordSnapshot(name) }
        guard let seed = lifecycleSeeds[name],
              let journey = seedJourney(id: "seed-life", origin: seed.originStopID, route: seed.routeID, minutes: 25,
                                        task: seed.task, phase: seed.elapsed == nil ? .awaitingDeparture : .departed,
                                        elapsed: seed.elapsed ?? 0, paused: seed.elapsed != nil,
                                        destination: seed.destination) else { return nil }
        let origin = StationSnapshot(id: journey.originStopID, name: journey.originName)
        return AppSnapshot.empty.updatingStage(cardIssued: true, initialStation: origin, currentStation: origin)
            .issuingCard(fixedCard)
            .updating(records: RecordSection(items: seed.withRecord ? [lifecycleRecord] : []))
            .updating(journey: JourneySection(active: journey))
    }

    /// v4로 만든 뒤 version을 3으로 바꾸고 paused 키를 지운다. 손상 시드는 그 위에서 값만 바꾼다.
    private static func v3Bytes(_ name: String) throws -> Data {
        guard let journey = timerJourney(phase: name == "v3Awaiting" ? .awaitingDeparture : .departed, elapsed: 0,
                                         paused: name != "v3Awaiting") else { throw SetupIssue.invalidSaveState }
        let data = try SnapshotCodec.encode(readySnapshot.issuingCard(fixedCard).updating(journey: JourneySection(active: journey)))
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var state = root["state"] as? [String: Any], var section = state["journey"] as? [String: Any],
              var active = section["active"] as? [String: Any] else { throw SetupIssue.invalidSaveState }
        active.removeValue(forKey: "paused")
        if name == "v3InvalidMinutes" { active["minutes"] = 361 }
        if name == "v3UnknownStop" { active["originStopID"] = "gone-stop" }
        section["active"] = active; state["journey"] = section; root["state"] = state; root["version"] = 3
        return try JSONSerialization.data(withJSONObject: root, options: .sortedKeys)
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
        initialStation: StationSnapshot(id: "seongsu", name: "성수"),
        currentStation: StationSnapshot(id: "seoulForest-r", name: "서울숲"))

    /// 여정 없이 현재 정류장만 데이터에서 사라진 상태(BR-16).
    private static var stationGoneSnapshot: AppSnapshot {
        let gone = StationSnapshot(id: "gone-stop", name: "사라진 정류장")
        return AppSnapshot.empty.updatingStage(cardIssued: true, initialStation: gone, currentStation: gone).issuingCard(fixedCard)
    }

    /// 마이페이지 UI 테스트: 카드 번호 FM-12345678과 완료 기록 3건(25·25·15분, 합 65분). 옛 형식이면 이전 때문에 메인이 아니라
    /// 최초 정류장 화면으로 가므로 현재 버전으로 만든다.
    private static var profileSnapshot: AppSnapshot {
        let record = { (id: String, at: String, minutes: Int) in
            RecordSnapshot(id: id, completedAt: at, date: "2026-10-13", bus: "버스2014", tag: "독서", tagColor: "#12ABef",
                           task: "책 한 챕터 읽기", minutes: minutes, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: "")
        }
        return readySnapshot.issuingCard(CardSnapshot(id: "FM-12345678", issuedAt: fixedCard.issuedAt))
            .updating(records: RecordSection(items: [record("journey-a", "2026-10-13T03:00:00Z", 25),
                                                     record("journey-b", "2026-10-13T02:00:00Z", 25),
                                                     record("journey-c", "2026-10-13T01:00:00Z", 15)]))
    }

    /// 현재 버전 파일의 손상 여정(361분). 읽으면 여정만 버리고 카드·정류장은 남는다(메인, 진행 카드 없음).
    private static func invalidMinutesBytes() throws -> Data {
        guard let journey = timerJourney(phase: .departed, elapsed: 0, paused: true) else { throw SetupIssue.invalidSaveState }
        let data = try SnapshotCodec.encode(readySnapshot.issuingCard(fixedCard).updating(journey: JourneySection(active: journey)))
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var state = root["state"] as? [String: Any], var section = state["journey"] as? [String: Any],
              var active = section["active"] as? [String: Any] else { throw SetupIssue.invalidSaveState }
        active["minutes"] = 361
        section["active"] = active; state["journey"] = section; root["state"] = state
        return try JSONSerialization.data(withJSONObject: root, options: .sortedKeys)
    }

    /// v4 시절 형식: 현재 버전으로 만든 뒤 정류장·여정에 direction을 넣고 version을 4로 바꾼다. 진행 여정·카드 1장·기록 3건.
    private static func legacyV4Bytes() throws -> Data {
        let base = profileSnapshot
        guard let journey = lifecycleSnapshot("lifePaused600")?.journey.active
        else { throw SetupIssue.invalidSaveState }
        let data = try SnapshotCodec.encode(base.updating(cards: CardSection(items: [fixedCard]))
            .updating(journey: JourneySection(active: journey)))
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var state = root["state"] as? [String: Any], var section = state["journey"] as? [String: Any],
              var active = section["active"] as? [String: Any],
              var initial = state["initialStation"] as? [String: Any], var current = state["currentStation"] as? [String: Any]
        else { throw SetupIssue.invalidSaveState }
        initial["direction"] = 1; current["direction"] = -1; active["direction"] = 1
        section["active"] = active; state["journey"] = section
        state["initialStation"] = initial; state["currentStation"] = current
        root["state"] = state; root["version"] = 4
        return try JSONSerialization.data(withJSONObject: root, options: .sortedKeys)
    }

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
        "profileRecords": (try? SnapshotCodec.encode(profileSnapshot)).map { String(decoding: $0, as: UTF8.self) } ?? "",
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
/// `--fm-ui-boarding-hold manual`: 인식 유지(1400ms)를 테스트가 해제할 때까지 붙잡는다. 여러 대기자를 모두 받고, 해제는 지금 기다리는 것만 푼다.
@MainActor @Observable
final class UITestHoldGate {
    @ObservationIgnored private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait(_ duration: Duration) async { await withCheckedContinuation { waiters.append($0) } }
    func release() {
        let pending = waiters
        waiters = []
        pending.forEach { $0.resume() }
    }
}

/// 여행 화면의 `test.failNextSave`: 누를 때마다 다음 쓰기 1건을 실패시킨다. 수동 시계에는 자율 쓰기가 없어 실패 대상이 결정적이다.
final class UITestNextSaveFailure {
    private var pending = 0
    func arm() { pending += 1 }
    func consume() -> Bool {
        guard pending > 0 else { return false }
        pending -= 1
        return true
    }
}

/// `test.writeAttempts`: 이 프로세스에서 앱 저장소에 시도한 쓰기 수(실패 포함). 재실행마다 0부터다.
@Observable
final class UITestWriteCounter {
    private(set) var attempts = 0
    func record() { attempts += 1 }
}

/// `--fm-ui-save fail-once-boarding`: 승차 저장 직전에만 한 번 실패를 건다.
@MainActor
final class ArmingBoarder: JourneyBoarding {
    private let base: JourneyBoarding
    private let failure: UITestCardSaveFailure
    init(base: JourneyBoarding, failure: UITestCardSaveFailure) { self.base = base; self.failure = failure }
    func boardJourney() -> Bool {
        failure.arm()
        defer { _ = failure.consume() }
        return base.boardJourney()
    }
}

/// Only the editor Save action arms this shared box; bootstrap and unrelated saves never arm it.
final class UITestCardSaveFailure {
    private let enabled: Bool
    private var used = false
    private var armed = false
    init(enabled: Bool) { self.enabled = enabled }
    func arm() { if enabled && !used { armed = true } }
    func consume() -> Bool {
        guard armed else { return false }
        armed = false; used = true
        return true
    }
}

@MainActor
final class UITestCardImportGate {
    private var token = UUID()
    private var waiter: CheckedContinuation<Void, Error>?
    private var released = false
    func arm() -> UUID {
        cancel(token)
        token = UUID(); released = false
        return token
    }
    func wait(_ expected: UUID) async throws {
        try Task.checkCancellation()
        guard expected == token else { throw CancellationError() }
        if released { return }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { waiter = $0 }
        } onCancel: {
            Task { @MainActor in self.cancel(expected) }
        }
    }
    func release() {
        released = true
        let continuation = waiter; waiter = nil
        continuation?.resume()
    }
    private func cancel(_ expected: UUID) {
        guard expected == token else { return }
        let continuation = waiter; waiter = nil
        continuation?.resume(throwing: CancellationError())
    }
}
#endif
