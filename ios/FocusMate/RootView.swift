import SwiftUI

@MainActor
struct RootView: View {
    @Bindable var model: AppModel
    private enum RecoveryFocus: Hashable { case error, confirmation, failure }
    @AccessibilityFocusState private var recoveryFocus: RecoveryFocus?
    #if DEBUG
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var testBootstrap: UITestBootstrap?
    var testSetupError: String?
    #endif

    var body: some View {
        NavigationStack(path: $model.path) {
            VStack(alignment: .leading, spacing: 24) {
                content
                if model.saveFailure != nil {
                    Text("저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요.")
                        .accessibilityIdentifier("storage.saveFailure").foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle("Focus Mate").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                VStack(alignment: .leading, spacing: 16) {
                    Text(destination.title).font(.largeTitle.bold())
                        .accessibilityIdentifier("screen.\(destination.rawValue)")
                    if destination == .records { Text("아직 여행 기록이 없어요.").foregroundStyle(.secondary) }
                    Spacer()
                }
                .padding(24).frame(maxWidth: .infinity, alignment: .leading)
                .navigationTitle(destination.title).navigationBarTitleDisplayMode(.inline)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: model.isCleanupConfirmationPresented) { _, presented in
            if case .failed = model.launchState { recoveryFocus = presented ? .confirmation : .error }
            else { recoveryFocus = nil }
        }
        .onChange(of: model.recoveryFailure) { _, issue in
            if issue != nil { recoveryFocus = .failure }
            else if case .failed = model.launchState { recoveryFocus = .error }
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                if let testBootstrap {
                    Text("상태 진단").accessibilityValue(snapshotJSON).accessibilityIdentifier("test.snapshot")
                    Text("파일 진단").accessibilityValue(testBootstrap.persistedBytes).accessibilityIdentifier("test.persistedBytes")
                    Text("백업 진단").accessibilityValue(testBootstrap.backupBytes).accessibilityIdentifier("test.backups")
                    Text("글자 크기 진단").accessibilityValue(dynamicTypeSize == .accessibility5 ? "accessibility5" : "other").accessibilityIdentifier("test.dynamicTypeSize")
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
            Text("최초 정류장 설정").font(.largeTitle.bold()).accessibilityIdentifier("screen.initialStationEntry")
            Text("여행을 시작할 정류장을 골라요.").foregroundStyle(.secondary)
        case .ready(.main):
            Text("현재 정류장").foregroundStyle(.secondary).accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Text(station.name).font(.largeTitle.bold()).accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                Text(station.direction == 1 ? "정방향" : "역방향").foregroundStyle(.secondary)
                    .accessibilityValue(station.direction == 1 ? "정방향" : "역방향").accessibilityIdentifier("main.direction")
            }
            ForEach(Destination.allCases, id: \.self) { destination in
                Button(destination.title) { model.open(destination) }.buttonStyle(.bordered)
                    .accessibilityIdentifier("open.\(destination.rawValue)")
            }
        case let .failed(issue):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("저장된 상태 확인").font(.title.bold()).accessibilityIdentifier("screen.storageError")
                        .accessibilityAddTraits(.isHeader).accessibilityFocused($recoveryFocus, equals: .error)
                    Text(message(for: issue)).accessibilityIdentifier("storage.error")
                    if model.isCleanupConfirmationPresented {
                        Text("저장 데이터 정리").font(.headline).accessibilityIdentifier("storage.cleanupConfirmation")
                            .accessibilityAddTraits(.isHeader).accessibilityFocused($recoveryFocus, equals: .confirmation)
                        Text("카드, 여행, 기록 데이터가 초기화돼요.")
                        Text("같은 원본을 앱 내부에 보존한 뒤 정리해요.")
                        Button("원본 보존 후 정리", role: .destructive) { model.confirmCleanup() }
                            .buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("storage.confirmCleanup")
                        Button("취소") { model.cancelCleanup() }
                            .buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("storage.cancelCleanup")
                    } else {
                        if let failure = model.recoveryFailure {
                            Text(recoveryMessage(for: failure)).accessibilityIdentifier("storage.recoveryFailure")
                                .accessibilityFocused($recoveryFocus, equals: .failure)
                        } else {
                            Text(model.hasAttemptedCleanup
                                 ? "다시 시도하거나 저장 데이터 정리를 선택해주세요."
                                 : "기존 데이터는 변경하지 않았어요.").foregroundStyle(.secondary)
                        }
                        Button("다시 시도") {
                            model.retryLoad()
                            if case .failed = model.launchState { recoveryFocus = .error }
                        }.buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("storage.retry")
                        Button("저장 데이터 정리") { model.requestCleanup() }
                            .buttonStyle(.bordered).frame(minHeight: 44).accessibilityIdentifier("storage.cleanup")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).disabled(model.isRecovering)
            }
        }
    }

    private func message(for issue: StorageIssue) -> String {
        switch issue {
        case .corrupt: "저장된 데이터 형식을 읽을 수 없어요."
        case .unsupportedVersion: "이 버전의 앱에서 열 수 없는 데이터예요."
        case .invalidState(.inconsistentStage): "저장된 데이터 내용이 현재 단계와 맞지 않아요."
        case .invalidState: "저장된 이용 상태를 확인할 수 없어요."
        default: "저장된 데이터를 읽을 수 없어요."
        }
    }

    private func recoveryMessage(for issue: StorageRecoveryIssue) -> String {
        switch issue {
        case .backupFailed: "원본을 보존하지 못해 저장 데이터 정리를 완료하지 못했어요."
        case .cleanupFailed: "원본을 내부에 보존했지만 저장 데이터 정리 완료를 확인하지 못했어요."
        case .sourceChanged: "확인하는 동안 데이터가 변경되어 정리하지 않았어요. 다시 시도해 최신 상태를 확인해주세요."
        case .sourceMissing: "저장된 파일이 없어 정리하지 않았어요. 다시 시도해 최신 상태를 확인해주세요."
        case .notRequired: "데이터를 읽을 수 있어 정리하지 않았어요. 다시 시도해 저장된 상태를 불러오세요."
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
