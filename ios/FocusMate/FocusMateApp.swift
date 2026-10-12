import SwiftUI

@main @MainActor
struct FocusMateApp: App {
    @State private var model: AppModel
    @State private var hasStarted = false
    #if DEBUG
    private let testBootstrap: UITestBootstrap?
    @State private var testSetupError: String?
    #endif

    init() {
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: false)
            let operationalURL = support.appendingPathComponent("FocusMate", isDirectory: true).appendingPathComponent("app-state.json")
            #if DEBUG
            let bootstrap = try UITestBootstrap(arguments: ProcessInfo.processInfo.arguments, applicationSupport: support)
            testBootstrap = bootstrap
            _model = State(initialValue: AppModel(store: bootstrap?.modelStore ?? LocalSnapshotStore(fileURL: operationalURL)))
            #else
            _model = State(initialValue: AppModel(store: LocalSnapshotStore(fileURL: operationalURL)))
            #endif
        } catch {
            // This store never reads or writes a fallback location.
            let unavailable = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unavailable-focusmate-state"),
                readData: { _ in throw StorageIssue.unreadable })
            _model = State(initialValue: AppModel(store: unavailable))
            #if DEBUG
            testBootstrap = nil
            if ProcessInfo.processInfo.arguments.contains("--fm-ui-test-id") {
                _testSetupError = State(initialValue: String(describing: error))
            }
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            RootView(model: model, testBootstrap: testBootstrap, testSetupError: testSetupError).task { start() }
            #else
            RootView(model: model).task { start() }
            #endif
        }
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        #if DEBUG
        guard testSetupError == nil else { return }
        do { try testBootstrap?.prepare() }
        catch { testSetupError = String(describing: error); return }
        #endif
        model.loadIfNeeded()
        #if DEBUG
        do { try testBootstrap?.applySaveScenario(to: model) }
        catch { testSetupError = String(describing: error) }
        #endif
    }
}
