import SwiftUI

@main @MainActor
struct FocusMateApp: App {
    @State private var model: AppModel
    @State private var issuance: CardIssuanceController
    @State private var hasStarted = false
    #if DEBUG
    private let testBootstrap: UITestBootstrap?
    private let testRecorder: UITestFeedbackRecorder?
    private let testGate: UITestIssuanceGate?
    private let testServices: JourneyServices?
    private let testHoldGate: UITestHoldGate?
    @State private var testSetupError: String?
    #endif

    init() {
        FontCatalog.register()
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: false)
            let operationalURL = support.appendingPathComponent("FocusMate", isDirectory: true).appendingPathComponent("app-state.json")
            #if DEBUG
            let bootstrap = try UITestBootstrap(arguments: ProcessInfo.processInfo.arguments, applicationSupport: support)
            testBootstrap = bootstrap
            let model = bootstrap.map {
                AppModel(store: $0.modelStore, soundPreview: $0.makeSoundPreview(), routeData: $0.makeRouteCatalogStore())
            } ?? AppModel(store: LocalSnapshotStore(fileURL: operationalURL))
            _model = State(initialValue: model)
            if let bootstrap {
                let recorder = bootstrap.makeFeedbackRecorder()
                let gate = bootstrap.makeGate()
                testRecorder = recorder
                testGate = gate
                let made = bootstrap.makeJourneyServices(recorder: recorder)
                testServices = made.0
                testHoldGate = made.1
                _issuance = State(initialValue: gate.map {
                    CardIssuanceController(issuer: model, haptics: recorder, announcer: recorder, sleep: $0.wait)
                } ?? CardIssuanceController(issuer: model, haptics: recorder, announcer: recorder))
            } else {
                testRecorder = nil
                testGate = nil
                testServices = nil
                testHoldGate = nil
                _issuance = State(initialValue: Self.makeIssuance(for: model))
            }
            #else
            let model = AppModel(store: LocalSnapshotStore(fileURL: operationalURL))
            _model = State(initialValue: model)
            _issuance = State(initialValue: Self.makeIssuance(for: model))
            #endif
        } catch {
            // This store never reads or writes a fallback location.
            let unavailable = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unavailable-focusmate-state"),
                readData: { _ in throw StorageIssue.unreadable })
            let model = AppModel(store: unavailable)
            _model = State(initialValue: model)
            _issuance = State(initialValue: Self.makeIssuance(for: model))
            #if DEBUG
            testBootstrap = nil
            testRecorder = nil
            testGate = nil
            testServices = nil
            testHoldGate = nil
            if ProcessInfo.processInfo.arguments.contains("--fm-ui-test-id") {
                _testSetupError = State(initialValue: String(describing: error))
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            RootView(model: model, issuance: issuance, services: journeyServices, testBootstrap: testBootstrap, testRecorder: testRecorder,
                     testGate: testGate, testHoldGate: testHoldGate, testSetupError: testSetupError).task { await start() }
            #else
            RootView(model: model, issuance: issuance).task { await start() }
            #endif
        }
    }

    #if DEBUG
    /// UI 테스트면 진동·낭독을 기록기로 바꿔 진단에 노출한다.
    private var journeyServices: JourneyServices { testServices ?? .live() }
    #endif

    private static func makeIssuance(for model: AppModel) -> CardIssuanceController {
        CardIssuanceController(issuer: model, haptics: CoreHapticsIssuancePlayer(), announcer: SystemAccessibilityAnnouncer())
    }

    private func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        #if DEBUG
        guard testSetupError == nil else { return }
        do { try testBootstrap?.prepare() }
        catch { testSetupError = String(describing: error); return }
        #endif
        model.start()
        #if DEBUG
        let routeLoading = testBootstrap?.startsRouteData == false ? nil : model.startRouteData()
        #else
        model.startRouteData()
        #endif
        cleanUpLiveActivities()
        #if DEBUG
        do {
            try testBootstrap?.applySaveScenario(to: model)
            // 승차 경로는 시간 선택 후보가 필요하므로 정류장 데이터를 다 읽은 뒤 쌓는다.
            if testBootstrap?.route == "boarding" { await routeLoading?.value }
            try testBootstrap?.applyRoute(to: model)
        } catch { testSetupError = String(describing: error) }
        #endif
    }

    /// 이전 실행이 남긴 앱 밖 표시를 저장 상태에 맞춘다. 읽기 실패는 "여행 없음"이 아니므로 건드리지 않는다.
    private func cleanUpLiveActivities() {
        guard case .ready = model.launchState else { return }
        #if DEBUG
        let services = journeyServices
        #else
        let services = JourneyServices.live()
        #endif
        JourneyLiveActivityCleanup.atLaunch(gateway: services.liveActivities, journey: model.activeJourney)
    }
}
