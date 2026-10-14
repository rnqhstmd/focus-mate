 ios/FocusMate/AVSoundPreviewPlayer.swift           |  29 ++
 ios/FocusMate/AppModel.swift                       |  48 ++-
 ios/FocusMate/DestinationScreen.swift              |   6 +-
 ios/FocusMate/FocusMateApp.swift                   |   3 +-
 ios/FocusMate/PreparationDraft.swift               | 142 ++++++
 ios/FocusMate/PreparationView.swift                | 475 +++++++++++++++++++++
 .../Resources/Audio/travel-bus-rain-v2.wav         | Bin 0 -> 7680044 bytes
 ios/FocusMate/Resources/Audio/travel-bus-v2.wav    | Bin 0 -> 7680044 bytes
 ios/FocusMate/Resources/Audio/travel-forest-v2.wav | Bin 0 -> 7680044 bytes
 ios/FocusMate/Resources/Audio/travel-subway-v2.wav | Bin 0 -> 7680044 bytes
 ios/FocusMate/Resources/Fonts/SOURCE.md            |  12 +
 ios/FocusMate/Resources/Fonts/SeoulAlrim-Bold.ttf  | Bin 0 -> 2564272 bytes
 .../Resources/Fonts/SeoulAlrim-Medium.ttf          | Bin 0 -> 2592392 bytes
 ios/FocusMate/SoundPreviewController.swift         | 104 +++++
 ios/FocusMate/TimeSelectionView.swift              |   1 +
 ios/FocusMate/UITestBootstrap.swift                |   9 +
 ios/FocusMateTests/AudioResourceTests.swift        |  49 +++
 ios/FocusMateTests/PreparationDetailsTests.swift   |  18 +
 ios/FocusMateTests/PreparationDraftTests.swift     | 188 ++++++++
 ios/FocusMateTests/PreparationModelTests.swift     | 403 +++++++++++++++++
 .../SoundPreviewControllerTests.swift              | 322 ++++++++++++++
 .../PreparationEditorUITests.swift                 | 308 +++++++++++++
 ios/FocusMateUITests/PreparationFlowUITests.swift  |  15 +-
 23 files changed, 2121 insertions(+), 11 deletions(-)

diff --git a/ios/FocusMate/AVSoundPreviewPlayer.swift b/ios/FocusMate/AVSoundPreviewPlayer.swift
new file mode 100644
index 0000000..bece3c8
--- /dev/null
+++ b/ios/FocusMate/AVSoundPreviewPlayer.swift
@@ -0,0 +1,29 @@
+import Foundation
+import AVFoundation
+
+@MainActor final class AVSoundPreviewPlayer: SoundPreviewPlaying {
+    private enum ResourceIssue: Error { case missingResource }
+    private let player: AVAudioPlayer
+    var volume: Float {
+        get { player.volume }
+        set { player.volume = newValue }
+    }
+    var numberOfLoops: Int {
+        get { player.numberOfLoops }
+        set { player.numberOfLoops = newValue }
+    }
+    init(url: URL) throws { player = try AVAudioPlayer(contentsOf: url) }
+    func prepareToPlay() -> Bool { player.prepareToPlay() }
+    func play() -> Bool { player.play() }
+    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
+        player.setVolume(volume, fadeDuration: fadeDuration)
+    }
+    func stop() { player.stop() }
+    static func make(sound: JourneySound, bundle: Bundle = .main) async throws -> any SoundPreviewPlaying {
+        guard let name = sound.resourceName,
+              let url = bundle.url(forResource: name, withExtension: "wav") else {
+            throw ResourceIssue.missingResource
+        }
+        return try AVSoundPreviewPlayer(url: url)
+    }
+}
diff --git a/ios/FocusMate/AppModel.swift b/ios/FocusMate/AppModel.swift
index c00d42b..8a9e4d8 100644
--- a/ios/FocusMate/AppModel.swift
+++ b/ios/FocusMate/AppModel.swift
@@ -28,6 +28,48 @@ final class AppModel {
     /// 발급 직후 저장 단계는 이미 다음 단계지만, 사용자가 진행할 때까지 발급 완료 화면을 유지한다. 메모리에만 둔다(A3).
     private var isHoldingIssuedCard = false
     var journeyPlan = JourneyPlanDraft()
+    var preparation = PreparationDraft()
+    private var storedConfirmedPreparation: PreparedJourneyDetails?
+    private var storedPreparationRequest: PreparedJourneyDetails?
+    private var currentPreparationDetails: PreparedJourneyDetails? {
+        guard launchState == .ready(.main), let journey = preparedJourney,
+              preparation.isComplete, let tag = preparation.selectedTag else { return nil }
+        return PreparedJourneyDetails(journey: journey, tag: tag,
+                                      task: preparation.trimmedTask, sound: preparation.sound)
+    }
+    var confirmedPreparation: PreparedJourneyDetails? {
+        storedConfirmedPreparation == currentPreparationDetails ? storedConfirmedPreparation : nil
+    }
+    var preparationRequest: PreparedJourneyDetails? {
+        storedPreparationRequest == currentPreparationDetails ? storedPreparationRequest : nil
+    }
+    var canConfirmPreparation: Bool { currentPreparationDetails != nil }
+    @discardableResult func confirmPreparation() -> Bool {
+        guard let details = currentPreparationDetails else {
+            storedConfirmedPreparation = nil
+            storedPreparationRequest = nil
+            return false
+        }
+        storedConfirmedPreparation = details
+        storedPreparationRequest = details
+        return true
+    }
+    func consumePreparationRequest() -> PreparedJourneyDetails? {
+        guard let current = currentPreparationDetails,
+              storedConfirmedPreparation == current else {
+            storedConfirmedPreparation = nil
+            storedPreparationRequest = nil
+            return nil
+        }
+        guard let request = storedPreparationRequest else { return nil }
+        guard request == current else {
+            storedConfirmedPreparation = nil
+            storedPreparationRequest = nil
+            return nil
+        }
+        storedPreparationRequest = nil
+        return request
+    }
     private(set) var recoveryFailure: StorageRecoveryIssue?
     private(set) var isRecovering = false
     private(set) var hasAttemptedCleanup = false
@@ -35,11 +77,15 @@ final class AppModel {
     var isCleanupConfirmationPresented: Bool { cleanupSource != nil }
     private let store: LocalSnapshotStore
     private let cardFactory: CardSnapshotFactory
+    let soundPreview: SoundPreviewController
     @ObservationIgnored private var hasLoaded = false
     @ObservationIgnored private var hasAttemptedSupplement = false
-    init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init()) {
+    init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init(),
+         soundPreview: SoundPreviewController? = nil) {
         self.store = store
         self.cardFactory = cardFactory
+        self.soundPreview = soundPreview ?? SoundPreviewController(sound: .bus,
+            makePlayer: { try await AVSoundPreviewPlayer.make(sound: $0) })
     }
 
     /// 화면 분기는 이 값만 쓴다. `launchState`는 로딩·실패 판단과 모델 내부 가드용이다.
diff --git a/ios/FocusMate/DestinationScreen.swift b/ios/FocusMate/DestinationScreen.swift
index 44ed1a7..ebdb8f1 100644
--- a/ios/FocusMate/DestinationScreen.swift
+++ b/ios/FocusMate/DestinationScreen.swift
@@ -19,6 +19,8 @@ struct DestinationScreen: View {
         Group {
             if destination == .time {
                 TimeSelectionView(model: model)
+            } else if destination == .preparation {
+                PreparationView(model: model)
             } else {
                 VStack(alignment: .leading, spacing: 16) {
                     Text(destination.title).font(.largeTitle.bold())
@@ -28,8 +30,8 @@ struct DestinationScreen: View {
                 }
             }
         }
-        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
-        .navigationTitle(destination.title).navigationBarTitleDisplayMode(.inline)
+        .padding(destination == .preparation ? 0 : 24).frame(maxWidth: .infinity, alignment: .leading)
+        .navigationTitle(destination == .preparation ? "" : destination.title).navigationBarTitleDisplayMode(.inline)
         #if DEBUG
         .overlay(alignment: .bottomLeading) {
             if destination == .preparation {
diff --git a/ios/FocusMate/FocusMateApp.swift b/ios/FocusMate/FocusMateApp.swift
index c8475fe..cdac565 100644
--- a/ios/FocusMate/FocusMateApp.swift
+++ b/ios/FocusMate/FocusMateApp.swift
@@ -20,7 +20,8 @@ struct FocusMateApp: App {
             #if DEBUG
             let bootstrap = try UITestBootstrap(arguments: ProcessInfo.processInfo.arguments, applicationSupport: support)
             testBootstrap = bootstrap
-            let model = AppModel(store: bootstrap?.modelStore ?? LocalSnapshotStore(fileURL: operationalURL))
+            let model = AppModel(store: bootstrap?.modelStore ?? LocalSnapshotStore(fileURL: operationalURL),
+                                 soundPreview: bootstrap?.makeSoundPreview())
             _model = State(initialValue: model)
             if let bootstrap {
                 let recorder = bootstrap.makeFeedbackRecorder()
diff --git a/ios/FocusMate/PreparationDraft.swift b/ios/FocusMate/PreparationDraft.swift
new file mode 100644
index 0000000..f27c3b4
--- /dev/null
+++ b/ios/FocusMate/PreparationDraft.swift
@@ -0,0 +1,142 @@
+import Foundation
+
+enum PreparationTagIcon: String, CaseIterable, Equatable {
+    case reading, work, study, development, writing
+    var title: String {
+        switch self {
+        case .reading: "독서"
+        case .work: "업무"
+        case .study: "공부"
+        case .development: "개발"
+        case .writing: "쓰기"
+        }
+    }
+    var systemImage: String {
+        switch self {
+        case .reading: "book"
+        case .work: "briefcase"
+        case .study: "graduationcap"
+        case .development: "chevron.left.forwardslash.chevron.right"
+        case .writing: "pencil"
+        }
+    }
+}
+enum PreparationTagColor: String, CaseIterable, Equatable {
+    case sand, blue, purple, green, pink
+    var title: String {
+        switch self {
+        case .sand: "모래빛"
+        case .blue: "파랑"
+        case .purple: "보라"
+        case .green: "초록"
+        case .pink: "분홍"
+        }
+    }
+}
+struct PreparationTag: Identifiable, Equatable {
+    let id: String
+    let name: String
+    let icon: PreparationTagIcon
+    let color: PreparationTagColor
+    static let defaults = [
+        PreparationTag(id: "reading", name: "독서", icon: .reading, color: .sand),
+        PreparationTag(id: "study", name: "공부", icon: .study, color: .purple),
+        PreparationTag(id: "work", name: "업무", icon: .work, color: .blue),
+        PreparationTag(id: "rest", name: "휴식", icon: .writing, color: .green),
+    ]
+}
+struct TagEditorDraft: Equatable {
+    var name: String = ""
+    var icon: PreparationTagIcon = .reading
+    var color: PreparationTagColor = .sand
+}
+enum TagNameIssue: Error, Equatable {
+    case empty, tooLong, duplicate
+    var message: String {
+        switch self {
+        case .empty: "태그 이름을 입력해주세요."
+        case .tooLong: "태그 이름은 20자 이내로 입력해주세요."
+        case .duplicate: "이미 있는 태그 이름이에요."
+        }
+    }
+}
+enum JourneySound: String, CaseIterable, Equatable {
+    case bus, rainBus, subway, forest, none
+    var title: String {
+        switch self {
+        case .bus: "버스"
+        case .rainBus: "비 오는 버스"
+        case .subway: "지하철"
+        case .forest: "숲속"
+        case .none: "소리 없음"
+        }
+    }
+    var systemImage: String {
+        switch self {
+        case .bus: "bus"
+        case .rainBus: "cloud.rain"
+        case .subway: "tram"
+        case .forest: "tree"
+        case .none: "speaker.slash"
+        }
+    }
+    var resourceName: String? {
+        switch self {
+        case .bus: "travel-bus-v2"
+        case .rainBus: "travel-bus-rain-v2"
+        case .subway: "travel-subway-v2"
+        case .forest: "travel-forest-v2"
+        case .none: nil
+        }
+    }
+}
+struct PreparationDraft: Equatable {
+    private(set) var tags = PreparationTag.defaults
+    private(set) var selectedTagID: String?
+    private(set) var task = ""
+    private(set) var sound: JourneySound = .bus
+    var selectedTag: PreparationTag? { tags.first { $0.id == selectedTagID } }
+    var trimmedTask: String { task.trimmingCharacters(in: .whitespacesAndNewlines) }
+    var isComplete: Bool { selectedTag != nil && !trimmedTask.isEmpty }
+    @discardableResult mutating func chooseTag(id: String) -> Bool {
+        guard tags.contains(where: { $0.id == id }) else { return false }
+        selectedTagID = id
+        return true
+    }
+    mutating func setTask(_ value: String) {
+        var result = String.UnicodeScalarView()
+        var units = 0
+        for scalar in value.unicodeScalars {
+            let width = scalar.value > 0xFFFF ? 2 : 1
+            guard units + width <= 80 else { break }
+            result.append(scalar)
+            units += width
+        }
+        task = String(result)
+    }
+    mutating func setSound(_ value: JourneySound) { sound = value }
+    @discardableResult mutating func saveTag(_ editor: TagEditorDraft) -> Result<PreparationTag, TagNameIssue> {
+        let name = editor.name.trimmingCharacters(in: .whitespacesAndNewlines)
+        guard !name.isEmpty else { return .failure(.empty) }
+        guard name.utf16.count <= 20 else { return .failure(.tooLong) }
+        let normalized = name.precomposedStringWithCompatibilityMapping.lowercased()
+        guard !tags.contains(where: {
+            $0.name.precomposedStringWithCompatibilityMapping.lowercased() == normalized
+        }) else { return .failure(.duplicate) }
+        let tag = PreparationTag(id: UUID().uuidString,
+                                 name: name,
+                                 icon: editor.icon, color: editor.color)
+        tags.append(tag)
+        selectedTagID = tag.id
+        return .success(tag)
+    }
+}
+struct PreparedJourneyDetails: Equatable {
+    let journey: JourneySelection
+    let tag: PreparationTag
+    let task: String
+    let sound: JourneySound
+    var originName: String { RouteStops.name(at: journey.origin.index) }
+    var boundLabel: String { RouteStops.boundLabel(from: journey.origin) }
+    var distanceText: String { JourneyPlanner.distanceText(stops: journey.stops) }
+}
diff --git a/ios/FocusMate/PreparationView.swift b/ios/FocusMate/PreparationView.swift
new file mode 100644
index 0000000..91564d5
--- /dev/null
+++ b/ios/FocusMate/PreparationView.swift
@@ -0,0 +1,475 @@
+import CoreText
+import SwiftUI
+
+@MainActor
+struct PreparationView: View {
+  @Bindable var model: AppModel
+  @Environment(\.dynamicTypeSize) private var typeSize
+  @State private var taskInput: String
+  @State private var showTagEditor = false
+  @State private var showSoundSelection = false
+  @FocusState private var taskEditing: Bool
+  @AccessibilityFocusState private var soundFocused: Bool
+  @AccessibilityFocusState private var addTagFocused: Bool
+  @ScaledMetric(relativeTo: .body) private var tagHeight = 46.0
+
+  init(model: AppModel) {
+    self.model = model
+    _taskInput = State(initialValue: model.preparation.task)
+    _ = PreparationTypography.registered
+  }
+
+  var body: some View {
+    GeometryReader { geometry in
+      VStack(spacing: 0) {
+        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
+        VStack(spacing: 0) {
+          ScrollViewReader { proxy in
+            ScrollView {
+              VStack(alignment: .leading, spacing: 22) {
+                Text("무엇을 할까요?").font(PreparationTypography.bold(22, relativeTo: .title2))
+                  .accessibilityIdentifier("screen.preparation")
+                ScrollView(.horizontal, showsIndicators: false) {
+                  LazyHGrid(
+                    rows: [GridItem(.fixed(tagHeight)), GridItem(.fixed(tagHeight))], spacing: 10
+                  ) {
+                    ForEach(model.preparation.tags) { tag in
+                      let selected = model.preparation.selectedTagID == tag.id
+                      Button {
+                        model.preparation.chooseTag(id: tag.id)
+                      } label: {
+                        Label(tag.name, systemImage: tag.icon.systemImage)
+                          .font(PreparationTypography.bold(17, relativeTo: .body)).fixedSize()
+                          .padding(.horizontal, 14).frame(height: tagHeight)
+                          .foregroundStyle(selected ? .white : tag.color.tint)
+                          .background(tag.color.tint.opacity(selected ? 0.35 : 0.2), in: Capsule())
+                          .overlay(
+                            Capsule().stroke(
+                              tag.color.tint.opacity(selected ? 1 : 0.45), lineWidth: 1))
+                      }
+                      .buttonStyle(.plain).accessibilityLabel(tag.name)
+                      .accessibilityIdentifier("preparation.tag.\(tag.id)")
+                      .accessibilityAddTraits(selected ? .isSelected : [])
+                    }
+                    Button {
+                      taskEditing = false
+                      showTagEditor = true
+                    } label: {
+                      Image(systemName: "plus").font(.title2)
+                        .frame(width: tagHeight, height: tagHeight)
+                        .background(.white.opacity(0.06), in: Circle())
+                        .overlay(Circle().stroke(.white.opacity(0.16)))
+                    }
+                    .buttonStyle(.plain).accessibilityLabel("태그 추가")
+                    .accessibilityIdentifier("preparation.addTag")
+                    .accessibilityFocused($addTagFocused)
+                  }.padding(.horizontal, 18)
+                }
+                .frame(height: tagHeight * 2 + 10)
+                .accessibilityIdentifier("preparation.tags")
+                .padding(.horizontal, -18)
+                if let tag = model.preparation.selectedTag {
+                  TextField("할 일 한 줄", text: $taskInput)
+                    .onChange(of: taskInput) { _, value in
+                      model.preparation.setTask(value)
+                      taskInput = model.preparation.task
+                    }
+                    .font(PreparationTypography.medium(17, relativeTo: .body)).padding(16)
+                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
+                    .overlay(
+                      RoundedRectangle(cornerRadius: 16).stroke(
+                        taskEditing ? tag.color.tint : .white.opacity(0.15))
+                    )
+                    .focused($taskEditing).autocorrectionDisabled().textInputAutocapitalization(
+                      .never
+                    )
+                    .submitLabel(.done).onSubmit { taskEditing = false }
+                    .accessibilityLabel("할 일 한 줄")
+                    .accessibilityIdentifier("preparation.task")
+                    .id("preparation.input")
+                }
+              }
+              .padding(.horizontal, 18).padding(.top, 18)
+            }
+            .scrollDismissesKeyboard(.interactively)
+            .onChange(of: model.preparation.selectedTagID) { _, id in
+              if id != nil { proxy.scrollTo("preparation.input", anchor: .bottom) }
+            }
+            .onChange(of: taskEditing) { _, editing in
+              if editing { proxy.scrollTo("preparation.input", anchor: .bottom) }
+            }
+            .onChange(of: geometry.size.height) { _, _ in
+              if taskEditing { proxy.scrollTo("preparation.input", anchor: .bottom) }
+            }
+          }
+          Group {
+            if typeSize.isAccessibilitySize {
+              VStack(spacing: 12) {
+                soundButton
+                confirmButton
+              }
+            } else {
+              HStack(spacing: 10) {
+                soundButton
+                confirmButton
+              }
+            }
+          }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 18)
+        }
+        .frame(
+          maxHeight: typeSize.isAccessibilitySize
+            ? geometry.size.height : (model.preparation.selectedTag == nil ? 270 : 350)
+        )
+        .background(Color(white: 0.035), in: RoundedRectangle(cornerRadius: 24))
+        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12)))
+        .padding(.horizontal, 12).padding(.bottom, 12)
+      }
+    }
+    .sheet(isPresented: $showTagEditor, onDismiss: { addTagFocused = true }) {
+      TagEditorView(model: model, onSaved: { taskEditing = true })
+        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(410), .large])
+        .presentationCornerRadius(24).presentationDragIndicator(.hidden).preferredColorScheme(.dark)
+    }
+    .sheet(
+      isPresented: $showSoundSelection,
+      onDismiss: {
+        model.soundPreview.setActive(false)
+        soundFocused = true
+      }
+    ) {
+      SoundSelectionView(model: model)
+        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(440), .large])
+        .presentationCornerRadius(24).presentationDragIndicator(.hidden)
+        .preferredColorScheme(.dark)
+    }
+    .onDisappear { model.soundPreview.setActive(false) }
+    #if DEBUG
+      .overlay(alignment: .topLeading) {
+        VStack {
+          preparationDiagnostic
+          if !showSoundSelection { SoundPreviewDiagnostic(controller: model.soundPreview) }
+        }
+      }
+    #endif
+  }
+
+  private var soundButton: some View {
+    Button {
+      taskEditing = false
+      model.soundPreview.beginSelection(sound: model.preparation.sound)
+      showSoundSelection = true
+    } label: {
+      Label(
+        model.preparation.sound.title,
+        systemImage: model.preparation.sound == .none ? "speaker.slash" : "speaker.wave.2"
+      )
+      .font(PreparationTypography.bold(17, relativeTo: .body)).padding(14)
+      .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
+      .background(.white.opacity(0.06), in: Capsule())
+      .overlay(Capsule().stroke(.white.opacity(0.16)))
+    }
+    .buttonStyle(.plain).accessibilityLabel("소리 선택")
+    .accessibilityValue(model.preparation.sound.title)
+    .accessibilityIdentifier("preparation.sound").accessibilityFocused($soundFocused)
+  }
+  private var confirmButton: some View {
+    Button {
+      taskEditing = false
+      model.confirmPreparation()
+    } label: {
+      Text("승차권 보기").font(PreparationTypography.bold(17, relativeTo: .body)).padding(16)
+        .frame(maxWidth: .infinity)
+        .foregroundStyle(model.canConfirmPreparation ? .black : .white.opacity(0.45))
+        .background(model.canConfirmPreparation ? .white : .white.opacity(0.08), in: Capsule())
+        .overlay(Capsule().stroke(.white.opacity(0.15)))
+    }.buttonStyle(.plain).disabled(!model.canConfirmPreparation)
+      .accessibilityIdentifier("preparation.confirm")
+  }
+
+  #if DEBUG
+    private var preparationDiagnostic: some View {
+      let details = model.confirmedPreparation
+      let object: [String: Any]? = details.map {
+        [
+          "journey": [
+            "minutes": $0.journey.minutes, "busID": $0.journey.busID,
+            "busNumber": $0.journey.busNumber,
+            "destination": $0.journey.destination, "stops": $0.journey.stops,
+          ],
+          "tag": [
+            "id": $0.tag.id, "name": $0.tag.name, "icon": $0.tag.icon.rawValue,
+            "color": $0.tag.color.rawValue,
+          ],
+          "task": $0.task, "sound": $0.sound.rawValue,

전체 diff는 ../diff.txt, 실제 파일 직접 읽기로 보완.
