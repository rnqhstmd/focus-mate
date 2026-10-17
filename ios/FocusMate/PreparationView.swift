import SwiftUI

/// 여행 준비(시안 R07·R08). 지도 위에 떠 있는 고정 높이 시트와, 같은 자리에 뜨는 태그 만들기(R09)·소리 선택(R10) 시트.
@MainActor
struct PreparationView: View {
  @Bindable var model: AppModel
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var taskInput: String
  @State private var showTagEditor = false
  @State private var showSoundSelection = false
  @State private var panelHeight: CGFloat = 0
  @FocusState private var taskEditing: Bool
  @AccessibilityFocusState private var soundFocused: Bool
  @AccessibilityFocusState private var addTagFocused: Bool
  @ScaledMetric(relativeTo: .body) private var tagHeight = 40.0
  @ScaledMetric(relativeTo: .body) private var rowHeight = 52.0

  /// 시안 시트 높이(R07·R08 443, R09·R10 403).
  static let sheetHeight: CGFloat = 443

  init(model: AppModel) {
    self.model = model
    _taskInput = State(initialValue: model.preparation.task)
  }

  private var overlayShown: Bool { showTagEditor || showSoundSelection }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
        sheet
          .opacity(overlayShown ? 0 : 1)
          .allowsHitTesting(!overlayShown)
          .accessibilityHidden(overlayShown)
      }
      if showTagEditor {
        TagEditorView(model: model, onClose: closeTagEditor, onSaved: {
          closeTagEditor()
          taskEditing = true
        })
      }
      if showSoundSelection {
        SoundSelectionView(model: model, onClose: closeSoundSelection)
      }
    }
    .ignoresSafeArea(.container, edges: .bottom)
    .background {
      if showTagEditor {
        Color.black.ignoresSafeArea()
      } else if taskEditing {
        FMDesign.background.ignoresSafeArea()
      } else {
        SceneMapBackdrop(model: model, bottomInset: panelHeight + 20,
                         routeID: model.preparedJourney?.busID, leg: legStopIndices)
          .ignoresSafeArea()
          .allowsHitTesting(false)
      }
    }
    .onPreferenceChange(PreparationPanelHeightKey.self) { panelHeight = $0 }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .onDisappear { model.soundPreview.setActive(false) }
    #if DEBUG
      .overlay(alignment: .topLeading) {
        VStack {
          if !showSoundSelection { SoundPreviewDiagnostic(controller: model.soundPreview) }
        }
      }
    #endif
  }

  /// 시간 화면에서 고른 구간(R06과 같은 노선선·정류장 점·버스 표식).
  private var legStopIndices: [Int]? {
    model.preparedJourney.flatMap { model.legStopIndices(for: $0) }
  }

  private func closeTagEditor() {
    showTagEditor = false
    addTagFocused = true
  }

  private func closeSoundSelection() {
    model.soundPreview.setActive(false)
    showSoundSelection = false
    soundFocused = true
  }

  private var sheet: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
              Text("무엇을 할까요?").font(FontCatalog.text(22, weight: .bold, relativeTo: .title2))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("screen.preparation")
              Spacer(minLength: 0)
              Button {
                taskEditing = false
                model.goBack()
              } label: {
                Image(systemName: "xmark").font(.system(size: 18, weight: .regular))
                  .frame(width: 22, height: 22)
                  .frame(width: 44, height: 44).contentShape(Rectangle())
              }
              .buttonStyle(.plain).padding(.trailing, -11).padding(.vertical, -6)
              .accessibilityLabel("닫기").accessibilityIdentifier("preparation.close")
            }
            .frame(minHeight: 32)
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(model.preparation.tags) { tag in
                  tagChip(tag)
                }
                Button {
                  taskEditing = false
                  showTagEditor = true
                } label: {
                  Image(systemName: "plus").font(.system(size: 18, weight: .regular))
                    .frame(width: tagHeight, height: tagHeight)
                    .background(FMDesign.chipFill, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.33), lineWidth: 1))
                }
                .buttonStyle(.plain).accessibilityLabel("태그 추가")
                .accessibilityIdentifier("preparation.addTag")
                .accessibilityFocused($addTagFocused)
              }
            }
            .frame(height: tagHeight)
            .accessibilityIdentifier("preparation.tags")
            if let tag = model.preparation.selectedTag {
              TextField("할 일 한 줄", text: $taskInput)
                .onChange(of: taskInput) { _, value in
                  model.preparation.setTask(value)
                  taskInput = model.preparation.task
                }
                .font(FontCatalog.text(16, relativeTo: .body))
                .padding(.horizontal, 16).frame(minHeight: 48)
                .background(Color(hex: 0x141414), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                  RoundedRectangle(cornerRadius: 14).strokeBorder(
                    tag.color.tint, lineWidth: taskEditing ? 1.5 : 1)
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
          .padding(.horizontal, 17).padding(.top, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: model.preparation.selectedTagID) { _, id in
          if id != nil { proxy.scrollTo("preparation.input", anchor: .bottom) }
        }
        .onChange(of: taskEditing) { _, editing in
          if editing { proxy.scrollTo("preparation.input", anchor: .bottom) }
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
      }.padding(.horizontal, 17).padding(.top, 16).padding(.bottom, 28)
    }
    .frame(maxHeight: typeSize.isAccessibilitySize ? .infinity : Self.sheetHeight)
    .background {
      GeometryReader { panel in
        Color.clear.preference(key: PreparationPanelHeightKey.self, value: panel.size.height)
      }
    }
    .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
    .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1))
    .padding(.horizontal, 12).padding(.bottom, 20)
  }

  private func tagChip(_ tag: PreparationTag) -> some View {
    let selected = model.preparation.selectedTagID == tag.id
    return Button {
      model.preparation.chooseTag(id: tag.id)
    } label: {
      HStack(spacing: 6) {
        Image(systemName: tag.icon.systemImage).font(.system(size: 14, weight: .regular))
          .frame(width: 16, height: 16).foregroundStyle(tag.color.tint)
        Text(tag.name).font(FontCatalog.text(14, weight: .semibold, relativeTo: .subheadline))
          .foregroundStyle(.white).fixedSize()
      }
      .padding(.horizontal, 14).frame(height: tagHeight)
      .background(tag.color.tint.opacity(selected ? 0.33 : 0.13), in: Capsule())
      .overlay(Capsule().strokeBorder(tag.color.tint.opacity(selected ? 1 : 0.53), lineWidth: 1))
    }
    .buttonStyle(.plain).accessibilityLabel(tag.name)
    .accessibilityIdentifier("preparation.tag.\(tag.id)")
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var soundButton: some View {
    Button {
      taskEditing = false
      model.soundPreview.beginSelection(sound: model.preparation.sound)
      showSoundSelection = true
    } label: {
      HStack(spacing: 6) {
        SoundIcon(sound: model.preparation.sound, size: 18, chip: true)
        Text(model.preparation.sound.title).font(FontCatalog.text(14, relativeTo: .subheadline))
          .fixedSize()
      }
      .foregroundStyle(.white)
      .padding(.horizontal, 14).frame(minHeight: rowHeight)
      .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
      .background(FMDesign.chipFill, in: Capsule())
      .overlay(Capsule().strokeBorder(FMDesign.panelStroke, lineWidth: 1))
    }
    .buttonStyle(.plain).accessibilityLabel("소리 선택")
    .accessibilityValue(model.preparation.sound.title)
    .accessibilityIdentifier("preparation.sound").accessibilityFocused($soundFocused)
  }
  private var confirmButton: some View {
    Button {
      taskEditing = false
      model.showBoardingPass()
    } label: {
      Text("승차권 보기").font(FontCatalog.text(16, weight: .semibold, relativeTo: .body))
        .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: rowHeight)
        .foregroundStyle(model.canConfirmPreparation ? Color(hex: 0x0A0A0A) : Color(hex: 0x888888))
        .background(model.canConfirmPreparation ? Color.white : Color(hex: 0x252525), in: Capsule())
    }.buttonStyle(.plain).disabled(!model.canConfirmPreparation)
      .accessibilityIdentifier("preparation.confirm")
  }
}

private struct PreparationPanelHeightKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

/// 준비 화면 위에 뜨는 시트 틀(R09·R10): 좌우 12, 아래 20 띄움, 반경 28, 흰 20% 테두리. 낭독은 모달로 묶는다.
private struct FloatingSheet<Content: View>: View {
  var fill: Color = FMDesign.panel
  var stroke: Color = FMDesign.panelStroke
  let onClose: () -> Void
  @ViewBuilder let content: Content
  @Environment(\.dynamicTypeSize) private var typeSize

  var body: some View {
    VStack(spacing: 0) {
      if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
      content
        .frame(maxHeight: typeSize.isAccessibilitySize ? .infinity : 403)
        .background(fill, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(stroke, lineWidth: 1))
        .padding(.horizontal, 12).padding(.bottom, 20)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

/// 소리 아이콘. 소리 없음은 시안의 스피커+×(lucide volume-x)를 직접 그린다.
private struct SoundIcon: View {
  let sound: JourneySound
  let size: CGFloat
  var chip = false

  var body: some View {
    Group {
      if sound == .none {
        VolumeXShape().stroke(style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
      } else {
        Image(systemName: chip ? "speaker.wave.2" : sound.systemImage)
          .font(.system(size: size * 0.82, weight: .light))
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

/// lucide `volume-x`(24 격자): 스피커 다각형과 ×.
private struct VolumeXShape: Shape {
  func path(in rect: CGRect) -> Path {
    let s = min(rect.width, rect.height) / 24
    let o = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
    var path = Path()
    path.move(to: p(11, 5))
    path.addLine(to: p(6, 9)); path.addLine(to: p(2, 9)); path.addLine(to: p(2, 15))
    path.addLine(to: p(6, 15)); path.addLine(to: p(11, 19)); path.closeSubpath()
    path.move(to: p(22, 9)); path.addLine(to: p(16, 15))
    path.move(to: p(16, 9)); path.addLine(to: p(22, 15))
    return path
  }
}

/// 태그 만들기(시안 R09). 순검정 화면 위 떠 있는 시트.
@MainActor
private struct TagEditorView: View {
  @Bindable var model: AppModel
  let onClose: () -> Void
  let onSaved: () -> Void
  @State private var draft = TagEditorDraft()
  @State private var issue: TagNameIssue?
  @FocusState private var nameEditing: Bool
  @ScaledMetric(relativeTo: .body) private var cellHeight = 43.0
  @ScaledMetric(relativeTo: .body) private var fieldHeight = 47.0

  var body: some View {
    FloatingSheet(fill: .black, stroke: .white.opacity(0.19), onClose: onClose) {
      VStack(spacing: 0) {
        HStack(alignment: .center) {
          Text("태그 만들기").font(FontCatalog.text(20, weight: .bold, relativeTo: .title3))
            .accessibilityAddTraits(.isHeader)
          Spacer()
          Button(action: onClose) {
            Image(systemName: "xmark").font(.system(size: 17, weight: .light))
              .frame(width: 23, height: 23)
              .frame(width: 44, height: 44).contentShape(Rectangle())
          }.buttonStyle(.plain).padding(.trailing, -10.5).padding(.vertical, -10)
            .accessibilityLabel("취소").accessibilityIdentifier("tagEditor.cancel")
        }.padding(.leading, 15).padding(.trailing, 20).padding(.top, 22)
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
              Image(systemName: draft.icon.systemImage).font(.system(size: 21, weight: .light))
              Text(previewName).font(FontCatalog.text(19, weight: .bold, relativeTo: .title3)).lineLimit(1)
            }
            .foregroundStyle(draft.color.swatch).padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 57)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.19), lineWidth: 1))
            .accessibilityHidden(true)
            label("이름").padding(.top, 6)
            TextField("", text: $draft.name, prompt: Text("태그 이름").foregroundStyle(Color(hex: 0x757575)))
              .font(FontCatalog.text(15, relativeTo: .body)).tint(draft.color.swatch)
              .padding(.horizontal, 13).frame(minHeight: fieldHeight)
              .background(FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 20))
              .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(draft.color.swatch, lineWidth: 2))
              .focused($nameEditing).autocorrectionDisabled().textInputAutocapitalization(.never)
              .accessibilityLabel("태그 이름").accessibilityIdentifier("tagEditor.name")
              .padding(.top, 8)
            if let issue {
              Text(issue.message).font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(.red)
                .accessibilityIdentifier("tagEditor.error").padding(.top, 4)
            }
            label("아이콘").padding(.top, 2)
            grid {
              ForEach(PreparationTagIcon.allCases, id: \.self) { icon in
                Button {
                  draft.icon = icon
                  nameEditing = false
                } label: {
                  Image(systemName: icon.systemImage).font(.system(size: 19, weight: .light))
                    .frame(maxWidth: .infinity, minHeight: cellHeight)
                    .modifier(EditorCell(selected: draft.icon == icon))
                }.buttonStyle(.plain).accessibilityLabel(icon.title)
                  .accessibilityIdentifier("tagEditor.icon.\(icon.rawValue)")
                  .accessibilityAddTraits(draft.icon == icon ? .isSelected : [])
              }
            }.padding(.top, 2)
            label("색").padding(.top, 2)
            grid {
              ForEach(PreparationTagColor.allCases, id: \.self) { color in
                Button {
                  draft.color = color
                  nameEditing = false
                } label: {
                  Circle().fill(color.swatch).frame(width: 23, height: 23)
                    .frame(maxWidth: .infinity, minHeight: cellHeight)
                    .modifier(EditorCell(selected: draft.color == color))
                }.buttonStyle(.plain).accessibilityLabel(color.title)
                  .accessibilityIdentifier("tagEditor.color.\(color.rawValue)")
                  .accessibilityAddTraits(draft.color == color ? .isSelected : [])
              }
            }.padding(.top, 2)
          }.padding(.leading, 18).padding(.trailing, 17).padding(.top, 19)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityIdentifier("tagEditor.fields").scrollDismissesKeyboard(.immediately)
        Button {
          switch model.preparation.saveTag(draft) {
          case .success:
            onSaved()
          case .failure(let failure):
            issue = failure
            nameEditing = true
          }
        } label: {
          Text("태그 저장")
        }
        .buttonStyle(FMPrimaryButtonStyle(size: .compact))
        .accessibilityIdentifier("tagEditor.save")
        .padding(.horizontal, 16).padding(.top, 15).padding(.bottom, 15)
      }
    }
  }

  private func label(_ text: String) -> some View {
    Text(text).font(FontCatalog.text(11, relativeTo: .caption2)).foregroundStyle(FMDesign.hintText)
      .padding(.leading, -1)
  }

  private func grid<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6, content: content)
  }

  private var previewName: String {
    let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? "새 태그" : name
  }
}

/// R09 아이콘·색 칸: 선택 흰 9% 채움 + 흰 테두리, 미선택 #111111 + #444444.
private struct EditorCell: ViewModifier {
  let selected: Bool
  func body(content: Content) -> some View {
    content
      .background(selected ? Color.white.opacity(0.09) : FMDesign.rowFill, in: RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Color.white : FMDesign.ctaStroke, lineWidth: 1))
  }
}

/// 소리 선택(시안 R10). 지도 위 떠 있는 시트.
@MainActor
private struct SoundSelectionView: View {
  @Bindable var model: AppModel
  let onClose: () -> Void
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var previewTask: Task<Void, Never>?
  @ScaledMetric(relativeTo: .body) private var cellHeight = 84.0

  var body: some View {
    FloatingSheet(onClose: close) {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          HStack {
            Text("소리 선택").font(FontCatalog.text(20, weight: .bold, relativeTo: .title3))
              .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
              close()
            } label: {
              Image(systemName: "xmark").font(.system(size: 18, weight: .regular))
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).padding(.trailing, -11).padding(.vertical, -8)
            .accessibilityLabel("취소").accessibilityIdentifier("sound.cancel")
          }.frame(minHeight: 29)
          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: 10),
              count: typeSize.isAccessibilitySize ? 1 : 3), spacing: 14
          ) {
            ForEach(JourneySound.allCases, id: \.self) { sound in
              let selected = model.soundPreview.selectedSound == sound
              Button {
                previewTask?.cancel()
                model.soundPreview.chooseSound(sound)
              } label: {
                VStack(spacing: 8) {
                  SoundIcon(sound: sound, size: 22)
                  Text(sound.title).font(FontCatalog.text(13, relativeTo: .footnote))
                }.frame(maxWidth: .infinity, minHeight: cellHeight)
                  .foregroundStyle(.white)
                  .background(selected ? Color(hex: 0x262626) : Color(hex: 0x141414),
                              in: RoundedRectangle(cornerRadius: 16))
                  .overlay(
                    RoundedRectangle(cornerRadius: 16).strokeBorder(
                      selected ? .white : .white.opacity(0.13), lineWidth: selected ? 2 : 1))
              }.buttonStyle(.plain).accessibilityLabel(sound.title)
                .accessibilityIdentifier("sound.option.\(sound.rawValue)")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
          }
          if let error = model.soundPreview.errorMessage {
            Text(error).font(FontCatalog.text(13, relativeTo: .footnote)).foregroundStyle(
              .red
            ).accessibilityIdentifier("sound.error")
          }
          Button {
            previewTask?.cancel()
            previewTask = Task { await model.soundPreview.togglePreview() }
          } label: {
            Text(model.soundPreview.phase == .stopped ? "선택한 소리 미리 듣기" : "미리 듣기 중지")
              .font(FontCatalog.text(15, relativeTo: .body))
              .foregroundStyle(model.soundPreview.selectedSound == .none ? FMDesign.hintText : .white)
              .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 44)
              .overlay(Capsule().strokeBorder(FMDesign.panelStroke, lineWidth: 1))
              .contentShape(Capsule())
          }.buttonStyle(.plain).disabled(model.soundPreview.selectedSound == .none)
            .accessibilityIdentifier("sound.preview").accessibilityValue(
              phaseName(model.soundPreview.phase))
          Button {
            model.preparation.setSound(model.soundPreview.selectedSound)
            close()
          } label: {
            Text("소리 저장").font(FontCatalog.text(15, weight: .semibold, relativeTo: .body))
              .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52)
              .foregroundStyle(Color(hex: 0x0A0A0A)).background(.white, in: Capsule())
          }.buttonStyle(.plain).accessibilityIdentifier("sound.save")
        }
        .padding(.top, 22).padding(.horizontal, 17).padding(.bottom, 28)
      }
      .scrollBounceBehavior(.basedOnSize)
    }
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
    onClose()
  }
}

extension PreparationTagColor {
  /// 준비 칩 강조색(R07 시안 4색). 분홍은 시안 칩에 없어 기존 값을 쓴다.
  fileprivate var tint: Color {
    switch self {
    case .sand: FMDesign.tagReading
    case .blue: FMDesign.tagWork
    case .purple: FMDesign.tagStudy
    case .green: FMDesign.tagRest
    case .pink: Color(red: 0.90, green: 0.66, blue: 0.77)
    }
  }
  /// 태그 만들기 색 견본(R09 시안 값). 칩 강조색보다 채도가 낮다.
  fileprivate var swatch: Color {
    switch self {
    case .sand: Color(hex: 0xD7B378)
    case .blue: Color(hex: 0x82AAF2)
    case .purple: Color(hex: 0xB49CE1)
    case .green: Color(hex: 0x91B9AB)
    case .pink: Color(hex: 0xD596A6)
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

