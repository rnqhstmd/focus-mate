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
            let model = AppModel(store: bootstrap?.modelStore ?? LocalSnapshotStore(fileURL: operationalURL),
                                 soundPreview: bootstrap?.makeSoundPreview())
            _model = State(initialValue: model)
            if let bootstrap {
                let recorder = bootstrap.makeFeedbackRecorder()
                let gate = bootstrap.makeGate()
                testRecorder = recorder
                testGate = gate
                _issuance = State(initialValue: gate.map {
                    CardIssuanceController(issuer: model, haptics: recorder, announcer: recorder, sleep: $0.wait)
                } ?? CardIssuanceController(issuer: model, haptics: recorder, announcer: recorder))
            } else {
                testRecorder = nil
                testGate = nil
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
            if ProcessInfo.processInfo.arguments.contains("--fm-ui-test-id") {
                _testSetupError = State(initialValue: String(describing: error))
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            RootView(model: model, issuance: issuance, testBootstrap: testBootstrap, testRecorder: testRecorder,
                     testGate: testGate, testSetupError: testSetupError).task { start() }
            #else
            RootView(model: model, issuance: issuance).task { start() }
            #endif
        }
    }

    private static func makeIssuance(for model: AppModel) -> CardIssuanceController {
        CardIssuanceController(issuer: model, haptics: CoreHapticsIssuancePlayer(), announcer: SystemAccessibilityAnnouncer())
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        #if DEBUG
        guard testSetupError == nil else { return }
        do { try testBootstrap?.prepare() }
        catch { testSetupError = String(describing: error); return }
        #endif
        model.start()
        #if DEBUG
        do { try testBootstrap?.applySaveScenario(to: model) }
        catch { testSetupError = String(describing: error) }
        #endif
    }
}
