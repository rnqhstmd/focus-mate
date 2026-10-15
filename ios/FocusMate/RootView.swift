import SwiftUI

@MainActor
struct RootView: View {
    @Bindable var model: AppModel
    let issuance: CardIssuanceController
    var services: JourneyServices = .live()
    @State private var customization: CardCustomizationController?
    @State private var showsCustomization = false
    @State private var cardImportTask: Task<Void, Never>?
    @State private var savedCardNotice = false
    @State private var announceSavedCard = false
    @State private var confirmsNewJourney = false
    @State private var mainActionFailed = false
    @AccessibilityFocusState private var cardFocus: Bool
    private enum RecoveryFocus: Hashable { case error, confirmation, failure }
    @AccessibilityFocusState private var recoveryFocus: RecoveryFocus?
    #if DEBUG
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var testBootstrap: UITestBootstrap?
    var testRecorder: UITestFeedbackRecorder?
    var testGate: UITestIssuanceGate?
    var testHoldGate: UITestHoldGate?
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
            .navigationDestination(for: Destination.self) { DestinationScreen(destination: $0, model: model, onCardCustomization: startCardCustomization, services: services) }
            .newJourneyConfirmation(isPresented: $confirmsNewJourney) { apply(model.confirmNewJourney()) }
        }
        .onChange(of: model.path) { _, _ in mainActionFailed = false }
        .safeAreaInset(edge: .bottom) {
            if savedCardNotice {
                Text("카드 외형을 저장했어요.")
                    .accessibilityIdentifier("cardCustomization.savedNotice")
                    .accessibilityFocused($cardFocus)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(.black)
            }
        }
        .fullScreenCover(isPresented: $showsCustomization, onDismiss: {
            endCustomization()
            if announceSavedCard {
                announceSavedCard = false
                savedCardNotice = true
                cardFocus = true
                #if DEBUG
                if let testRecorder { testRecorder.announce("카드 외형을 저장했어요.") }
                else { SystemAccessibilityAnnouncer().announce("카드 외형을 저장했어요.") }
                #else
                SystemAccessibilityAnnouncer().announce("카드 외형을 저장했어요.")
                #endif
            }
        }) {
            if let customization {
                #if DEBUG
                CardCustomizationView(controller: customization, importTask: $cardImportTask, close: dismissCustomization,
                                      saved: saveCompleted, testBootstrap: testBootstrap)
                    .overlay(alignment: .bottomLeading) { testDiagnostics }
                #else
                CardCustomizationView(controller: customization, importTask: $cardImportTask, close: dismissCustomization, saved: saveCompleted)
                #endif
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
            if !showsCustomization { testDiagnostics }
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
            // 여행 화면의 test.failNextSave와 동시에 있으면 여러 개가 일치하므로 메인 전용 식별자·노출 조건을 둔다.
            // 메인 메뉴·발급 해제 버튼을 가리지 않도록 수동 시계 실행(W07 생명주기 테스트)의 메인 화면에서만 둔다.
            if services.testClock != nil, model.presentedRoute == .main, model.path.isEmpty, let failure = services.failNextSave {
                Button { failure.arm() } label: {
                    Text("메인 다음 저장 실패").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).background(Color.black).contentShape(Rectangle())
                }
                .accessibilityLabel("메인 다음 저장 실패")
                .accessibilityIdentifier("test.main.failNextSave")
            }
            if let testHoldGate {
                Button { testHoldGate.release() } label: {
                    Text("승차 유지 해제").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("승차 유지 해제")
                .accessibilityIdentifier("test.releaseBoardingHold")
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("저장된 상태 확인").font(.title.bold()).accessibilityIdentifier("screen.storageError")
                        .accessibilityAddTraits(.isHeader).accessibilityFocused($recoveryFocus, equals: .error)
                    Text(message(for: issue)).accessibilityValue(message(for: issue)).accessibilityIdentifier("storage.error")
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

    @ViewBuilder private var route: some View {
        switch model.presentedRoute {
        case .cardEntry:
            CardIssuanceView(controller: issuance)
        case .initialStationEntry:
            InitialStationSearchView(model: model)
        case .main:
            // 가장 큰 글자에서 진행 여정 안내가 더해져도 모든 메뉴에 닿도록 스크롤한다.
            ScrollView { VStack(alignment: .leading, spacing: 24) { mainContent } }
                // 포기 안내는 바뀌는 순간 한 번만 낭독한다. 안내 뷰의 등장 횟수에 묶지 않는다.
                .onChange(of: model.abandonNotice) { _, name in
                    if let name { services.announcer.announce(JourneyLifecycleText.abandonNotice(stationName: name)) }
                }
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder private var mainContent: some View {
            Text("현재 정류장").foregroundStyle(.secondary).accessibilityIdentifier("screen.main")
            if let station = model.snapshot?.currentStation {
                Text(station.name).font(.largeTitle.bold()).accessibilityValue(station.name).accessibilityIdentifier("main.currentStation")
                Text(station.direction == 1 ? "정방향" : "역방향").foregroundStyle(.secondary)
                    .accessibilityValue(station.direction == 1 ? "정방향" : "역방향").accessibilityIdentifier("main.direction")
            }
            if let stationName = model.abandonNotice {
                MainAbandonNoticeView(stationName: stationName)
            }
            if mainActionFailed {
                Text(JourneyLifecycleText.saveFailure).foregroundStyle(.orange).accessibilityIdentifier("main.saveFailure")
            }
            if let card = model.activeJourneyCard {
                ActiveJourneyCardView(content: card) { apply(model.resumeJourney()) }
            }
            PassFace(style: model.currentCardStyle).frame(maxWidth: 354)
            Button("카드 꾸미기", action: startCardCustomization)
                .buttonStyle(.bordered).accessibilityIdentifier("open.cardCustomization")
            ForEach(Destination.mainMenu, id: \.self) { destination in
                Button(destination == .preparation ? model.mainStartTitle : destination.mainMenuTitle) {
                    if destination != .preparation { model.open(destination.mainMenuTarget) }
                    // 진행 여정은 확인을 거쳐서만 정리한다(W07).
                    else if model.activeJourney != nil { confirmsNewJourney = true }
                    else { model.startTripFromMain() }
                }.buttonStyle(.bordered)
                    .accessibilityIdentifier("open.\(destination.rawValue)")
            }
    }

    /// 메인 동작 실패 안내는 이 화면에만 둔다. 거부(연타 등)는 안내를 바꾸지 않는다.
    private func apply(_ result: LifecycleActionResult) {
        switch result {
        case .done: mainActionFailed = false
        case .saveFailed: mainActionFailed = true
        case .rejected: break
        }
    }

    private func startCardCustomization() {
        guard let session = model.beginCardCustomization() else { return }
        savedCardNotice = false
        customization = session
        showsCustomization = true
    }

    private func endCustomization() {
        // Invalidate generation before cancellation can complete a loader.
        customization?.discard()
        cardImportTask?.cancel()
        cardImportTask = nil
        customization = nil
    }
    private func dismissCustomization() {
        endCustomization()
        showsCustomization = false
    }
    private func saveCompleted() {
        announceSavedCard = true
        endCustomization()
        showsCustomization = false
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
    private var testDiagnostics: some View {
        VStack(spacing: 0) {
            if let testBootstrap {
                Text("상태 진단").accessibilityValue(snapshotJSON).accessibilityIdentifier("test.snapshot")
                Text("파일 진단").accessibilityValue(testBootstrap.persistedBytes).accessibilityIdentifier("test.persistedBytes")
                Text("백업 진단").accessibilityValue(testBootstrap.backupBytes).accessibilityIdentifier("test.backups")
                Text("글자 크기 진단").accessibilityValue(dynamicTypeSize == .accessibility5 ? "accessibility5" : "other").accessibilityIdentifier("test.dynamicTypeSize")
                Text("카드 외형 진단").accessibilityValue(testBootstrap.cardStyleJSON(model: model, controller: customization)).accessibilityIdentifier("test.cardStyleJSON")
                Text("준비 확정 진단").accessibilityValue(preparedPreparationJSON).accessibilityIdentifier("test.preparedPreparation")
                Text("동작 줄이기 진단").accessibilityValue(reduceMotion ? "true" : "false").accessibilityIdentifier("test.reduceMotion")
                Text("쓰기 진단").accessibilityValue("\(testBootstrap.writeCounter.attempts)").accessibilityIdentifier("test.writeAttempts")
            }
            if let testRecorder {
                Text("진동 진단").accessibilityValue("\(testRecorder.playCount)").accessibilityIdentifier("test.hapticCount")
                Text("안내 진단").accessibilityValue(testRecorder.announcements.joined(separator: "\n")).accessibilityIdentifier("test.announcements")
            }
            if let testSetupError { Text(testSetupError).accessibilityIdentifier("test.setupError") }
        }.font(.system(size: 1)).foregroundStyle(.clear).allowsHitTesting(false)
    }
    /// 준비 화면을 벗어난 뒤(승차권 등)에도 확정값을 읽도록 전역에 둔다.
    private var preparedPreparationJSON: String {
        guard let details = model.confirmedPreparation else { return "null" }
        let object: [String: Any] = [
            "journey": ["minutes": details.journey.minutes, "busID": details.journey.busID,
                        "busNumber": details.journey.busNumber, "destination": details.journey.destination,
                        "stops": details.journey.stops],
            "tag": ["id": details.tag.id, "name": details.tag.name, "icon": details.tag.icon.rawValue,
                    "color": details.tag.color.rawValue],
            "task": details.task, "sound": details.sound.rawValue,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else { return "null" }
        return String(decoding: data, as: UTF8.self)
    }
    private var snapshotJSON: String {
        guard let snapshot = model.snapshot else { return "null" }
        let diagnostic = snapshot.updating(cards: CardSection(items: snapshot.cards.items.map { $0.updating(style: CardStyle(background: $0.style.background, photos: [])) }))
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(diagnostic),
              var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return "null" }
        // The legacy state diagnostic keeps actual sections and color, but only metadata for photo bytes.
        if let testBootstrap,
           let metadata = (try? JSONSerialization.jsonObject(with: Data(testBootstrap.cardStyleJSON(model: model, controller: nil).utf8))) as? [String: Any],
           var cards = object["cards"] as? [String: Any], var items = cards["items"] as? [[String: Any]] {
            for index in items.indices {
                if var style = items[index]["style"] as? [String: Any] {
                    style["photos"] = metadata["photos"]
                    items[index]["style"] = style
                }
            }
            cards["items"] = items; object["cards"] = cards
        }
        guard let compact = try? JSONSerialization.data(withJSONObject: object, options: .sortedKeys) else { return "null" }
        return String(decoding: compact, as: UTF8.self)
    }
    #endif
}
