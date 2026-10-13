import SwiftUI

@MainActor
struct RootView: View {
    @Bindable var model: AppModel
    #if DEBUG
    var testBootstrap: UITestBootstrap?
    var testSetupError: String?
    #endif

    var body: some View {
        NavigationStack(path: $model.path) {
            VStack(alignment: .leading, spacing: 24) {
                content
                if model.saveFailure != nil && model.launchState != .ready(.initialStationEntry) {
                    Text("저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요.")
                        .accessibilityIdentifier("storage.saveFailure").foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Focus Mate").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { DestinationScreen(destination: $0, model: model) }
        }
        .preferredColorScheme(.dark)
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                if let testBootstrap {
                    Text("상태 진단").accessibilityValue(snapshotJSON).accessibilityIdentifier("test.snapshot")
                    Text("파일 진단").accessibilityValue(testBootstrap.persistedBytes).accessibilityIdentifier("test.persistedBytes")
                }
                if let testSetupError { Text(testSetupError).accessibilityIdentifier("test.setupError") }
            }
            .font(.system(size: 1)).foregroundStyle(.clear)
        }
        #endif
    }

    @ViewBuilder private var content: some View {
        switch model.launchState {
        case .loading:
            Text("불러오는 중").accessibilityIdentifier("screen.loading")
        case .ready(.cardEntry):
            Text("집중동행카드").font(.largeTitle.bold()).accessibilityIdentifier("screen.cardEntry")
            Text("나만의 카드로 함께 떠나요.").foregroundStyle(.secondary)
        case .ready(.initialStationEntry):
            InitialStationSearchView(model: model)
        case .ready(.main):
            Text("현재 정류장").foregroundStyle(.secondary).accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Text(station.name).font(.largeTitle.bold()).accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                Text(station.direction == 1 ? "정방향" : "역방향").foregroundStyle(.secondary)
                    .accessibilityValue(station.direction == 1 ? "정방향" : "역방향").accessibilityIdentifier("main.direction")
            }
            ForEach(Destination.mainMenu, id: \.self) { destination in
                Button(destination.title) { model.open(destination.mainMenuTarget) }.buttonStyle(.bordered)
                    .accessibilityIdentifier("open.\(destination.rawValue)")
            }
        case let .failed(issue):
            Text("저장된 상태 확인").font(.title.bold()).accessibilityIdentifier("screen.storageError")
            Text(message(for: issue)).accessibilityIdentifier("storage.error")
            Text("기존 데이터는 변경하지 않았어요.").foregroundStyle(.secondary)
        }
    }

    private func message(for issue: StorageIssue) -> String {
        switch issue {
        case .corrupt: "저장된 데이터 형식을 읽을 수 없어요."
        case .unsupportedVersion: "이 버전의 앱에서 열 수 없는 데이터예요."
        case .invalidState: "저장된 이용 상태를 확인할 수 없어요."
        default: "저장된 데이터를 읽지 못했어요."
        }
    }

    #if DEBUG
    private var snapshotJSON: String {
        guard let snapshot = model.snapshot else { return "null" }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(snapshot), let json = String(data: data, encoding: .utf8) else { return "null" }
        return json
    }
    #endif
}
