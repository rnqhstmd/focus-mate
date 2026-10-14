import CoreText
import SwiftUI

@MainActor
struct PreparationView: View {
  @Bindable var model: AppModel
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var taskInput: String
  @State private var showTagEditor = false
  @State private var showSoundSelection = false
  @FocusState private var taskEditing: Bool
  @AccessibilityFocusState private var soundFocused: Bool
  @AccessibilityFocusState private var addTagFocused: Bool
  @ScaledMetric(relativeTo: .body) private var tagHeight = 46.0

  init(model: AppModel) {
    self.model = model
    _taskInput = State(initialValue: model.preparation.task)
    _ = PreparationTypography.registered
  }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        VStack(spacing: 0) {
          ScrollViewReader { proxy in
            ScrollView {
              VStack(alignment: .leading, spacing: 22) {
                Text("무엇을 할까요?").font(PreparationTypography.bold(22, relativeTo: .title2))
                  .accessibilityIdentifier("screen.preparation")
                ScrollView(.horizontal, showsIndicators: false) {
                  LazyHGrid(
                    rows: [GridItem(.fixed(tagHeight)), GridItem(.fixed(tagHeight))], spacing: 10
                  ) {
                    ForEach(model.preparation.tags) { tag in
                      let selected = model.preparation.selectedTagID == tag.id
                      Button {
                        model.preparation.chooseTag(id: tag.id)
                      } label: {
                        Label(tag.name, systemImage: tag.icon.systemImage)
                          .font(PreparationTypography.bold(17, relativeTo: .body)).fixedSize()
                          .padding(.horizontal, 14).frame(height: tagHeight)
                          .foregroundStyle(selected ? .white : tag.color.tint)
                          .background(tag.color.tint.opacity(selected ? 0.35 : 0.2), in: Capsule())
                          .overlay(
                            Capsule().stroke(
                              tag.color.tint.opacity(selected ? 1 : 0.45), lineWidth: 1))
                      }
                      .buttonStyle(.plain).accessibilityLabel(tag.name)
                      .accessibilityIdentifier("preparation.tag.\(tag.id)")
                      .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    Button {
                      taskEditing = false
                      showTagEditor = true
                    } label: {
                      Image(systemName: "plus").font(.title2)
                        .frame(width: tagHeight, height: tagHeight)
                        .background(.white.opacity(0.06), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.16)))
                    }
                    .buttonStyle(.plain).accessibilityLabel("태그 추가")
                    .accessibilityIdentifier("preparation.addTag")
                    .accessibilityFocused($addTagFocused)
                  }.padding(.horizontal, 18)
                }
                .frame(height: tagHeight * 2 + 10)
                .accessibilityIdentifier("preparation.tags")
                .padding(.horizontal, -18)
                if let tag = model.preparation.selectedTag {
                  TextField("할 일 한 줄", text: $taskInput)
                    .onChange(of: taskInput) { _, value in
                      model.preparation.setTask(value)
                      taskInput = model.preparation.task
                    }
                    .font(PreparationTypography.medium(17, relativeTo: .body)).padding(16)
                    .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                      RoundedRectangle(cornerRadius: 16).stroke(
                        taskEditing ? tag.color.tint : .white.opacity(0.15))
                    )
                    .focused($taskEditing).autocorrectionDisabled().textInputAutocapitalization(
                      .never
                    )
                    .submitLabel(.done).onSubmit { taskEditing = false }
                    .accessibilityLabel("할 일 한 줄")
                    .accessibilityIdentifier("preparation.task")
                    .id("preparation.input")
                }
              }
              .padding(.horizontal, 18).padding(.top, 18)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.preparation.selectedTagID) { _, id in
              if id != nil { proxy.scrollTo("preparation.input", anchor: .bottom) }
            }
            .onChange(of: taskEditing) { _, editing in
              if editing { proxy.scrollTo("preparation.input", anchor: .bottom) }
            }
            .onChange(of: geometry.size.height) { _, _ in
              if taskEditing { proxy.scrollTo("preparation.input", anchor: .bottom) }
            }
          }
          Group {
            if typeSize.isAccessibilitySize {
              VStack(spacing: 12) {
                soundButton
                confirmButton
              }
            } else {
              HStack(spacing: 10) {
                soundButton
                confirmButton
              }
            }
          }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 18)
        }
        .frame(
          maxHeight: typeSize.isAccessibilitySize
            ? geometry.size.height : (model.preparation.selectedTag == nil ? 270 : 350)
        )
        .background(Color(white: 0.035), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12)))
        .padding(.horizontal, 12).padding(.bottom, 12)
      }
    }
    .sheet(isPresented: $showTagEditor, onDismiss: { addTagFocused = true }) {
      TagEditorView(model: model, onSaved: { taskEditing = true })
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(410), .large])
        .presentationCornerRadius(24).presentationDragIndicator(.hidden).preferredColorScheme(.dark)
    }
    .sheet(
      isPresented: $showSoundSelection,
      onDismiss: {
        model.soundPreview.setActive(false)
        soundFocused = true
      }
    ) {
      SoundSelectionView(model: model)
        .presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.height(440), .large])
        .presentationCornerRadius(24).presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
    }
    .onDisappear { model.soundPreview.setActive(false) }
    #if DEBUG
      .overlay(alignment: .topLeading) {
        VStack {
          preparationDiagnostic
          if !showSoundSelection { SoundPreviewDiagnostic(controller: model.soundPreview) }
        }
      }
    #endif
  }

  private var soundButton: some View {
    Button {
      taskEditing = false
      model.soundPreview.beginSelection(sound: model.preparation.sound)
      showSoundSelection = true
    } label: {
      Label(
        model.preparation.sound.title,
        systemImage: model.preparation.sound == .none ? "speaker.slash" : "speaker.wave.2"
      )
      .font(PreparationTypography.bold(17, relativeTo: .body)).padding(14)
      .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
      .background(.white.opacity(0.06), in: Capsule())
      .overlay(Capsule().stroke(.white.opacity(0.16)))
    }
    .buttonStyle(.plain).accessibilityLabel("소리 선택")
    .accessibilityValue(model.preparation.sound.title)
    .accessibilityIdentifier("preparation.sound").accessibilityFocused($soundFocused)
  }
  private var confirmButton: some View {
    Button {
      taskEditing = false
      model.confirmPreparation()
    } label: {
      Text("승차권 보기").font(PreparationTypography.bold(17, relativeTo: .body)).padding(16)
        .frame(maxWidth: .infinity)
        .foregroundStyle(model.canConfirmPreparation ? .black : .white.opacity(0.45))
        .background(model.canConfirmPreparation ? .white : .white.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15)))
    }.buttonStyle(.plain).disabled(!model.canConfirmPreparation)
      .accessibilityIdentifier("preparation.confirm")
  }

  #if DEBUG
    private var preparationDiagnostic: some View {
      let details = model.confirmedPreparation
      let object: [String: Any]? = details.map {
        [
          "journey": [
            "minutes": $0.journey.minutes, "busID": $0.journey.busID,
            "busNumber": $0.journey.busNumber,
            "destination": $0.journey.destination, "stops": $0.journey.stops,
          ],
          "tag": [
            "id": $0.tag.id, "name": $0.tag.name, "icon": $0.tag.icon.rawValue,
            "color": $0.tag.color.rawValue,
          ],
          "task": $0.task, "sound": $0.sound.rawValue,
        ]
      }
      return Text("준비 확정 진단").font(.system(size: 1)).foregroundStyle(.clear)
        .accessibilityValue(diagnosticJSON(object)).accessibilityIdentifier(
          "test.preparedPreparation")
    }
  #endif
}

@MainActor
private struct TagEditorView: View {
  @Bindable var model: AppModel
  let onSaved: () -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var draft = TagEditorDraft()
  @State private var issue: TagNameIssue?
  @FocusState private var nameEditing: Bool

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("태그 만들기").font(PreparationTypography.bold(20, relativeTo: .title3))
        Spacer()
        Button {
          dismiss()
        } label: {
          Image(systemName: "xmark").font(.system(size: 20)).padding(4)
        }.buttonStyle(.plain).accessibilityLabel("취소").accessibilityIdentifier("tagEditor.cancel")
      }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)
      ScrollView {
        VStack(alignment: .leading, spacing: 8) {
          Label(previewName, systemImage: draft.icon.systemImage)
            .font(PreparationTypography.medium(17, relativeTo: .body))
            .foregroundStyle(draft.color.tint).padding(14).frame(maxWidth: .infinity, minHeight: 56)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.16)))
            .accessibilityHidden(true)
          VStack(alignment: .leading, spacing: 4) {
            Text("이름").font(PreparationTypography.medium(12, relativeTo: .caption))
            TextField("태그 이름", text: $draft.name)
              .font(PreparationTypography.medium(17, relativeTo: .body)).padding(12)
              .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
              .overlay(RoundedRectangle(cornerRadius: 14).stroke(draft.color.tint))
              .focused($nameEditing).autocorrectionDisabled().textInputAutocapitalization(.never)
              .accessibilityLabel("태그 이름").accessibilityIdentifier("tagEditor.name")
            if let issue {
              Text(issue.message).font(.body).foregroundStyle(.red).accessibilityIdentifier(
                "tagEditor.error")
            }
          }
          VStack(alignment: .leading, spacing: 4) {
            Text("아이콘").font(PreparationTypography.medium(12, relativeTo: .caption))
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6
            ) {
              ForEach(PreparationTagIcon.allCases, id: \.self) { icon in
                Button {
                  draft.icon = icon
                  nameEditing = false
                } label: {
                  Image(systemName: icon.systemImage).font(.system(size: 22))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                      RoundedRectangle(cornerRadius: 12).stroke(
                        draft.icon == icon ? .white : .white.opacity(0.15)))
                }.buttonStyle(.plain).accessibilityLabel(icon.title)
                  .accessibilityIdentifier("tagEditor.icon.\(icon.rawValue)")
                  .accessibilityAddTraits(draft.icon == icon ? .isSelected : [])
              }
            }
          }
          VStack(alignment: .leading, spacing: 4) {
            Text("색").font(PreparationTypography.medium(12, relativeTo: .caption))
            LazyVGrid(
              columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6
            ) {
              ForEach(PreparationTagColor.allCases, id: \.self) { color in
                Button {
                  draft.color = color
                  nameEditing = false
                } label: {
                  Circle().fill(color.tint).frame(width: 24, height: 24)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                      RoundedRectangle(cornerRadius: 12).stroke(
                        draft.color == color ? .white : .white.opacity(0.15)))
                }.buttonStyle(.plain).accessibilityLabel(color.title)
                  .accessibilityIdentifier("tagEditor.color.\(color.rawValue)")
                  .accessibilityAddTraits(draft.color == color ? .isSelected : [])
              }
            }
          }
        }.padding(.horizontal, 20)
      }.accessibilityIdentifier("tagEditor.fields").scrollDismissesKeyboard(.immediately)
      Button {
        switch model.preparation.saveTag(draft) {
        case .success:
          dismiss()
          onSaved()
        case .failure(let failure):
          issue = failure
          nameEditing = true
        }
      } label: {
        Text("태그 저장").font(PreparationTypography.bold(17, relativeTo: .body))
          .padding(16).frame(maxWidth: .infinity).foregroundStyle(.black).background(
            .white, in: Capsule())
      }.buttonStyle(.plain).accessibilityIdentifier("tagEditor.save")
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
    }.background(Color(white: 0.035))
  }

  private var previewName: String {
    let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? "새 태그" : name
  }
}

@MainActor
private struct SoundSelectionView: View {
  @Bindable var model: AppModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var previewTask: Task<Void, Never>?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("소리 선택").font(PreparationTypography.bold(22, relativeTo: .title2))
          Spacer()
          Button {
            close()
          } label: {
            Image(systemName: "xmark").font(.title2).padding(8)
          }
          .buttonStyle(.plain).accessibilityLabel("취소").accessibilityIdentifier("sound.cancel")
        }
        LazyVGrid(
          columns: Array(
            repeating: GridItem(.flexible(), spacing: 10),
            count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 10
        ) {
          ForEach(JourneySound.allCases, id: \.self) { sound in
            let selected = model.soundPreview.selectedSound == sound
            Button {
              previewTask?.cancel()
              model.soundPreview.chooseSound(sound)
            } label: {
              VStack(spacing: 10) {
                Image(systemName: sound.systemImage).font(.title2).accessibilityHidden(true)
                Text(sound.title).font(PreparationTypography.medium(15, relativeTo: .subheadline))
              }.frame(maxWidth: .infinity).padding(.vertical, 16)
                .foregroundStyle(selected ? .white : .white.opacity(0.8))
                .background(
                  .white.opacity(selected ? 0.1 : 0.035), in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 20).stroke(
                    selected ? .white : .white.opacity(0.12)))
            }.buttonStyle(.plain).accessibilityLabel(sound.title)
              .accessibilityIdentifier("sound.option.\(sound.rawValue)")
              .accessibilityAddTraits(selected ? .isSelected : [])
          }
        }
        if let error = model.soundPreview.errorMessage {
          Text(error).font(PreparationTypography.medium(17, relativeTo: .body)).foregroundStyle(
            .red
          ).accessibilityIdentifier("sound.error")
        }
        VStack(spacing: 3) {
          Button {
            previewTask?.cancel()
            previewTask = Task { await model.soundPreview.togglePreview() }
          } label: {
            Text(model.soundPreview.phase == .stopped ? "선택한 소리 미리 듣기" : "미리 듣기 중지")
              .font(PreparationTypography.bold(17, relativeTo: .body)).padding(16).frame(
                maxWidth: .infinity
              )
              .overlay(Capsule().stroke(.white.opacity(0.2)))
          }.buttonStyle(.plain).disabled(model.soundPreview.selectedSound == .none)
            .accessibilityIdentifier("sound.preview").accessibilityValue(
              phaseName(model.soundPreview.phase))
          Button {
            model.preparation.setSound(model.soundPreview.selectedSound)
            close()
          } label: {
            Text("소리 저장").font(PreparationTypography.bold(17, relativeTo: .body)).padding(16).frame(
              maxWidth: .infinity
            )
            .foregroundStyle(.black).background(.white, in: Capsule())
          }.buttonStyle(.plain).accessibilityIdentifier("sound.save")
        }
      }.padding(20)
    }.background(Color(white: 0.035))
      .onChange(of: scenePhase) { _, phase in model.soundPreview.setActive(phase == .active) }
      .onDisappear {
        previewTask?.cancel()
        model.soundPreview.setActive(false)
      }
      #if DEBUG
        .overlay(alignment: .topLeading) { SoundPreviewDiagnostic(controller: model.soundPreview) }
      #endif
  }
  private func close() {
    previewTask?.cancel()
    model.soundPreview.setActive(false)
    dismiss()
  }
}

extension PreparationTagColor {
  fileprivate var tint: Color {
    switch self {
    case .sand: Color(red: 0.84, green: 0.70, blue: 0.47)
    case .blue: Color(red: 0.53, green: 0.67, blue: 0.96)
    case .purple: Color(red: 0.71, green: 0.60, blue: 0.87)
    case .green: Color(red: 0.55, green: 0.73, blue: 0.67)
    case .pink: Color(red: 0.90, green: 0.66, blue: 0.77)
    }
  }
}

private func phaseName(_ phase: SoundPreviewController.Phase) -> String {
  switch phase {
  case .stopped: "stopped"
  case .loading: "loading"
  case .playing: "playing"
  }
}

#if DEBUG
  @MainActor
  private struct SoundPreviewDiagnostic: View {
    let controller: SoundPreviewController
    var body: some View {
      let object: [String: Any] = [
        "selectedSound": controller.selectedSound.rawValue,
        "phase": phaseName(controller.phase),
        "errorMessage": controller.errorMessage as Any? ?? NSNull(),
      ]
      Text("소리 미리듣기 진단")
        .font(.system(size: 1)).foregroundStyle(.clear)
        .accessibilityValue(diagnosticJSON(object)).accessibilityIdentifier("test.soundPreview")
    }
  }
  private func diagnosticJSON(_ object: [String: Any]?) -> String {
    guard let object,
      let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    else { return "null" }
    return String(decoding: data, as: UTF8.self)
  }
#endif

@MainActor
private enum PreparationTypography {
  static let registered: Void = {
    for name in ["SeoulAlrim-Bold", "SeoulAlrim-Medium"] {
      if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
      }
    }
  }()
  static func bold(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
    .custom("SeoulAlrimTTF-Bold", size: size, relativeTo: style)
  }
  static func medium(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
    .custom("SeoulAlrimTTF-Medium", size: size, relativeTo: style)
  }
}
