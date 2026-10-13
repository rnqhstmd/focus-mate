import SwiftUI

@MainActor
struct RootView: View {
    @Bindable var model: AppModel
    let issuance: CardIssuanceController
    #if DEBUG
    var testBootstrap: UITestBootstrap?
    var testRecorder: UITestFeedbackRecorder?
    var testGate: UITestIssuanceGate?
    var testSetupError: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                if let testBootstrap {
                    Text("상태 진단").accessibilityValue(snapshotJSON).accessibilityIdentifier("test.snapshot")
                    Text("파일 진단").accessibilityValue(testBootstrap.persistedBytes).accessibilityIdentifier("test.persistedBytes")
                    Text("글자 크기 진단").accessibilityValue(String(describing: dynamicTypeSize)).accessibilityIdentifier("test.dynamicTypeSize")
                }
                if let testRecorder {
                    Text("진동 진단").accessibilityValue("\(testRecorder.playCount)").accessibilityIdentifier("test.hapticCount")
                    Text("안내 진단").accessibilityValue(testRecorder.announcements.joined(separator: "\n")).accessibilityIdentifier("test.announcements")
                }
                if let testSetupError { Text(testSetupError).accessibilityIdentifier("test.setupError") }
            }
            .font(.system(size: 1)).foregroundStyle(.clear)
        }
        // 상단 모서리는 상태 표시줄이 터치를 가져가므로, 하단 버튼과도 겹치지 않는 오른쪽 가운데에 둔다.
        .overlay(alignment: .trailing) {
            if let testGate {
                // 거의 투명한 opacity는 SwiftUI 히트 테스트에서 빠질 수 있어, 불투명 뷰에 글자만 투명하게 두고 터치 영역을 명시한다.
                Button { testGate.release() } label: {
                    Text("발급 해제").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("발급 해제")
                    .accessibilityIdentifier("test.releaseIssuance")
            }
        }
        #endif
    }

    /// 화면 분기는 `presentedRoute`만 쓴다. `launchState`는 로딩·실패 판단에만 쓴다.
    @ViewBuilder private var content: some View {
        switch model.launchState {
        case .loading:
            Text("불러오는 중").accessibilityIdentifier("screen.loading")
        case .ready:
            route
        case let .failed(issue):
            Text("저장된 상태 확인").font(.title.bold()).accessibilityIdentifier("screen.storageError")
            Text(message(for: issue)).accessibilityValue(message(for: issue)).accessibilityIdentifier("storage.error")
            Text("기존 데이터는 변경하지 않았어요.").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var route: some View {
        switch model.presentedRoute {
        case .cardEntry:
            CardIssuanceView(controller: issuance)
        case .initialStationEntry:
            Text("최초 정류장 설정").font(.largeTitle.bold()).accessibilityIdentifier("screen.initialStationEntry")
            Text("여행을 시작할 정류장을 골라요.").foregroundStyle(.secondary)
        case .main:
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
        case nil:
            EmptyView()
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
