import SwiftUI
import PhotosUI

@MainActor
struct CardCustomizationView: View {
    @Bindable var controller: CardCustomizationController
    @Binding var importTask: Task<Void, Never>?
    let close: () -> Void
    let saved: () -> Void
    /// 카드 번호("FM · 0842 3017"). 미리보기 카드 왼쪽 아래에 보인다(R39·R40).
    var numberText: String? = nil
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var confirmsExit = false
    @State private var gestureOrigin: CardPhoto?
    @State private var gestureTranslation: CGSize = .zero
    @State private var resizing = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var noticeFocused: Bool
    #if DEBUG
    var testBootstrap: UITestBootstrap?
    @State private var importGate = UITestCardImportGate()
    #endif

    private let background = Color(hex: 0x0D0F10)
    private let secondary = FMDesign.secondaryText
    private var locked: Bool { controller.isImporting || controller.isSaving }
    private var selected: CardPhoto? { controller.draft.photos.first { $0.id == controller.selectedPhotoID } }
    private let palette: [(String, String, CardColor)] = [
        ("standard", "기본 검정", .standard),
        ("slate", "슬레이트", CardColor(red: 75 / 255, green: 86 / 255, blue: 97 / 255)),
        ("blue", "짙은 파랑", CardColor(red: 36 / 255, green: 65 / 255, blue: 84 / 255)),
        ("mauve", "모브", CardColor(red: 103 / 255, green: 83 / 255, blue: 100 / 255)),
        ("sand", "샌드", CardColor(red: 217 / 255, green: 205 / 255, blue: 185 / 255)),
        ("ivory", "아이보리", CardColor(red: 241 / 255, green: 238 / 255, blue: 231 / 255))
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    preview.padding(.horizontal, 1)
                    VStack(alignment: .leading, spacing: 2.6) {
                        Text("사진을 자유롭게 배치해보세요.")
                        Text("IC 칩은 고정되고, 카드 밖은 잘려요.")
                    }.font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(Color(hex: 0xB8BFC5))
                        .padding(.top, 14.3)
                    colors.padding(.top, 28)
                    photos.padding(.top, 21)
                    if let selected { tools(selected).padding(.top, 20) }
                    if controller.isImporting {
                        ProgressView("사진을 불러오는 중이에요.").padding(.top, 16)
                    }
                    if let notice = controller.notice {
                        Text(notice.message).font(FontCatalog.text(12, relativeTo: .caption))
                            .foregroundStyle(secondary).padding(.top, 16)
                            .accessibilityIdentifier("cardCustomization.notice")
                            .accessibilityFocused($noticeFocused)
                    }
                    Text("사진은 이 기기에만 저장돼요. 최대 6장까지 넣을 수 있어요.")
                        .font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(Color(hex: 0xB0BAC2)).padding(.top, 18)
                    Button { controller.restoreDefault() } label: {
                        // 시안: 글자 아래 3pt에 1pt 밑줄.
                        Text("기본 검정 카드로 되돌리기")
                            .overlay(alignment: .bottom) { Rectangle().frame(height: 1).offset(y: 1) }
                    }
                        .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(Color(hex: 0xB4BEC6))
                        .frame(minHeight: 44).padding(.top, 26)
                        .disabled(locked).accessibilityIdentifier("cardCustomization.restoreDefault")
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }.accessibilityElement(children: .contain).accessibilityIdentifier("cardCustomization.body")
        }
        .background(background).foregroundStyle(FMDesign.primary).tint(FMDesign.primary)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                #if DEBUG
                testBootstrap?.cardSaveFailure.arm()
                #endif
                if controller.save() { saved() }
            } label: {
                Text("이 카드로 저장하기").frame(maxWidth: .infinity)
            }.buttonStyle(FMPrimaryButtonStyle())
                .disabled(locked).accessibilityIdentifier("cardCustomization.save")
                .padding(.horizontal, 24.5).padding(.top, 12).padding(.bottom, 0).background(background)
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if let testBootstrap, testBootstrap.photoManifestURL != nil {
                Group {
                    if testBootstrap.cardImportManual && controller.isImporting {
                        Button { importGate.release() } label: {
                            Text("사진 입력 해제").font(.system(size: 1)).foregroundStyle(.clear)
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                        }.accessibilityLabel("사진 입력 해제").accessibilityIdentifier("test.releaseCardImport")
                    } else {
                        Button {
                            startImport(testBootstrap.cardPhotoInputs(gate: testBootstrap.cardImportManual ? importGate : nil))
                        } label: {
                            Text("테스트 사진 불러오기").font(.system(size: 1)).foregroundStyle(.clear)
                                .frame(width: 44, height: 44).contentShape(Rectangle())
                        }.disabled(!controller.canAddPhotos).accessibilityLabel("테스트 사진 불러오기")
                            .accessibilityIdentifier("test.cardImportFixture")
                    }
                }.padding(.trailing, 62).padding(.top, 10)
            }
        }
        #endif
        .interactiveDismissDisabled()
        .alert("변경 내용을 버릴까요?", isPresented: $confirmsExit) {
            Button("변경 버리기", role: .destructive) { close() }.accessibilityIdentifier("cardCustomization.discard")
            Button("계속 편집", role: .cancel) { controller.continueEditing() }.accessibilityIdentifier("cardCustomization.continueEditing")
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            startImport(items.map { item in CardPhotoInput { try await item.loadTransferable(type: Data.self) } })
            pickerItems = []
        }
        .onChange(of: controller.notice) { _, notice in
            if let notice {
                noticeFocused = true
                SystemAccessibilityAnnouncer().announce(notice.message)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                if controller.requestExit() == .confirmDiscard { confirmsExit = true } else { close() }
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .regular)).foregroundStyle(Color(hex: 0xF4F4F4))
                    .frame(width: 52, height: 52).overlay(Circle().stroke(.white, lineWidth: 2))
            }.accessibilityLabel("닫기").accessibilityIdentifier("cardCustomization.close")
            Text("카드 꾸미기").font(FontCatalog.text(20, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.cardCustomization")
            Spacer(minLength: 0)
            Button { controller.undo() } label: {
                Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44)
                    .foregroundStyle(Color(hex: controller.canUndo && !locked ? 0xF3F3F3 : 0x54595D))
            }
                .disabled(locked || !controller.canUndo).accessibilityLabel("되돌리기").accessibilityIdentifier("cardCustomization.undo")
        }.buttonStyle(.plain).padding(.leading, 14).padding(.trailing, 18).padding(.top, -2).padding(.bottom, 21)
    }

    private var colors: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("배경색").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline)).accessibilityAddTraits(.isHeader)
            HStack(spacing: 9) {
                ForEach(palette, id: \.0) { entry in
                    let isSelected = entry.2 == controller.draft.background
                    Button { controller.setBackground(entry.2) } label: {
                        // 시안: 39pt 원(#737A80 테두리), 선택하면 바깥 48pt 링. 링은 배치에 영향을 주지 않는다(터치 영역은 44).
                        Circle().fill(entry.2.swiftUIColor).frame(width: 39, height: 39)
                            .overlay(Circle().stroke(Color(hex: 0x737A80), lineWidth: 1))
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color(hex: entry.0 == "sand" || entry.0 == "ivory" ? 0x121416 : 0xF1F2F3))
                                }
                            }
                            .overlay { if isSelected { Circle().stroke(Color(hex: 0xF4F4F4), lineWidth: 2).frame(width: 48, height: 48) } }
                            .contentShape(Circle().inset(by: -2.5))
                    }.buttonStyle(.plain).accessibilityLabel(entry.1)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("cardCustomization.color." + entry.0)
                }
            }
            .padding(.leading, 1).padding(.top, 15)
            customColor.padding(.top, 13)
        }.disabled(locked)
    }

    /// 시안 R39: "직접 고르기" + 사각 견본(현재 배경색). 시스템 ColorPicker는 견본 위에 거의 투명하게 겹쳐 누름만 받는다.
    private var customColor: some View {
        HStack(spacing: 14) {
            Text("직접 고르기").font(FontCatalog.text(12)).foregroundStyle(Color(hex: 0xBDC5CB))
            ZStack {
                Rectangle().fill(Color(hex: 0x111111)).overlay(Color.white.opacity(0x25 / 255))
                    .frame(width: 38, height: 32)
                Rectangle().fill(controller.draft.background.swiftUIColor).frame(width: 28, height: 18)
                    .overlay(Rectangle().stroke(Color(hex: 0x777777), lineWidth: 1))
                ColorPicker("직접 고르기", selection: Binding(get: { controller.draft.background.swiftUIColor }, set: { value in
                    let ui = UIColor(value)
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    if ui.getRed(&r, green: &g, blue: &b, alpha: &a) { controller.setBackground(CardColor(red: r, green: g, blue: b)) }
                }), supportsOpacity: false)
                .labelsHidden()
                .scaleEffect(1.6)
                .frame(width: 44, height: 44)
                .opacity(0.02)
                .accessibilityLabel("직접 고르기")
                .accessibilityIdentifier("cardCustomization.color.custom")
            }
            .frame(width: 44, height: 44)
        }
        .frame(minHeight: 44)
    }

    private var photos: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("사진").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline)).accessibilityAddTraits(.isHeader)
                Spacer()
                PhotosPicker(selection: $pickerItems, maxSelectionCount: CardCustomizationPolicy.maximumPhotos - controller.draft.photos.count,
                             selectionBehavior: .ordered, matching: .images) {
                    Label("사진 추가", systemImage: "plus").font(FontCatalog.text(12)).foregroundStyle(Color(hex: 0xF3F3F3))
                        .padding(.horizontal, 12).frame(minHeight: 43)
                        .background(Color(hex: 0x181D20), in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(hex: 0x555E65)))
                }.disabled(!controller.canAddPhotos).accessibilityIdentifier("cardCustomization.photoPicker")
            }
            if controller.draft.photos.isEmpty {
                Text("좋아하는 풍경, 소중한 순간을 담아보세요.").font(FontCatalog.text(12)).foregroundStyle(Color(hex: 0xAEB5BB))
                    .padding(.top, 22)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 11) {
                        ForEach(Array(controller.draft.photos.enumerated()), id: \.element.id) { index, photo in
                            Button { controller.selectPhoto(photo.id) } label: {
                                if let image = UIImage(data: photo.data) {
                                    // 시안 R40: 53pt 썸네일(#5C6267 테두리), 선택하면 3.5pt 바깥에 60pt 흰 링.
                                    Image(uiImage: image).resizable().scaledToFill().frame(width: 53, height: 53).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x5C6267), lineWidth: 1))
                                        .overlay {
                                            if controller.selectedPhotoID == photo.id {
                                                RoundedRectangle(cornerRadius: 11).stroke(.white, lineWidth: 2).frame(width: 60, height: 60)
                                            }
                                        }
                                }
                            }.buttonStyle(.plain).disabled(locked)
                                .accessibilityLabel("사진 \(index + 1)")
                                .accessibilityAddTraits(controller.selectedPhotoID == photo.id ? .isSelected : [])
                                .accessibilityIdentifier("cardCustomization.photo." + photo.id.uuidString)
                        }
                    }.padding(.vertical, 4).padding(.leading, 5).padding(.trailing, 4)
                }.accessibilityIdentifier("cardCustomization.photos")
                    .padding(.top, 13)
            }
        }
    }

    private func tools(_ photo: CardPhoto) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("사진 크기").foregroundStyle(Color(hex: 0xCCCCCC))
                Spacer()
                Text("\(Int(photo.widthFraction * 100))%").foregroundStyle(Color(hex: 0xC8CFD4))
            }.font(FontCatalog.text(12))
            Slider(value: Binding(get: { selected?.widthFraction ?? photo.widthFraction }, set: { value in
                if let p = selected { place(p, width: value) }
            }), in: CardCustomizationPolicy.widthFractionRange)
                .accessibilityLabel("사진 크기").accessibilityValue("\(Int(photo.widthFraction * 100))퍼센트")
                .accessibilityIdentifier("cardCustomization.width")
            positionControl(photo, axis: "x")
            positionControl(photo, axis: "y")
            ViewThatFits(in: .horizontal) {
                HStack { layerButtons(photo) }
                VStack(alignment: .leading) { layerButtons(photo) }
            }
        }.font(FontCatalog.text(15)).disabled(locked)
    }

    private func positionControl(_ photo: CardPhoto, axis: String) -> some View {
        let x = axis == "x"
        let value = x ? photo.centerX : photo.centerY
        return VStack(alignment: .leading, spacing: 4) {
            if dynamicTypeSize.isAccessibilitySize { Text(x ? "가로 위치" : "세로 위치") }
            HStack {
                if !dynamicTypeSize.isAccessibilitySize { Text(x ? "가로 위치" : "세로 위치") }
                Spacer(minLength: 4)
                Button { place(photo, x: x ? value - 0.05 : nil, y: x ? nil : value - 0.05) } label: { Image(systemName: "minus").frame(width: 44, height: 44) }
                    .accessibilityLabel(x ? "가로 위치 줄이기" : "세로 위치 줄이기").accessibilityIdentifier("cardCustomization.\(axis).decrease")
                    .disabled(value <= -1)
                Text("\(Int((value * 100).rounded()))%").accessibilityValue("\(Int((value * 100).rounded()))퍼센트")
                Button { place(photo, x: x ? value + 0.05 : nil, y: x ? nil : value + 0.05) } label: { Image(systemName: "plus").frame(width: 44, height: 44) }
                    .accessibilityLabel(x ? "가로 위치 늘리기" : "세로 위치 늘리기").accessibilityIdentifier("cardCustomization.\(axis).increase")
                    .disabled(value >= 2)
            }
        }.accessibilityElement(children: .contain).accessibilityIdentifier("cardCustomization." + axis)
    }

    @ViewBuilder private func layerButtons(_ photo: CardPhoto) -> some View {
        Button("앞으로") { controller.moveLayer(photoID: photo.id, direction: .forward) }
            .disabled(controller.draft.photos.last?.id == photo.id).accessibilityIdentifier("cardCustomization.forward").frame(minHeight: 44)
        Button("뒤로") { controller.moveLayer(photoID: photo.id, direction: .backward) }
            .disabled(controller.draft.photos.first?.id == photo.id).accessibilityIdentifier("cardCustomization.backward").frame(minHeight: 44)
        Button("삭제", role: .destructive) { controller.deletePhoto(photo.id) }.accessibilityIdentifier("cardCustomization.delete").frame(minHeight: 44)
    }

    private var preview: some View {
        GeometryReader { canvas in
            let size = canvas.size
            let style = previewStyle(size: size)
            ZStack {
                PassFace(style: style, numberText: numberText).accessibilityHidden(true)
                if let photo = style.photos.first(where: { $0.id == controller.selectedPhotoID }) {
                    let rect = photoRect(photo, size: size)
                    Rectangle().stroke(.white, lineWidth: 1).frame(width: rect.width, height: rect.height)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 12))
                                .frame(width: 32, height: 32).background(.white, in: Circle()).foregroundStyle(.black)
                        }.position(x: rect.midX, y: rect.midY).allowsHitTesting(false).accessibilityHidden(true)
                }
                // All gesture hit testing stays on this bounded canvas, even when a photo is enormous or outside it.
                Color.clear.frame(width: size.width, height: size.height).contentShape(Rectangle())
                    .gesture(DragGesture().onChanged { value in
                        if gestureOrigin == nil {
                            let point = value.startLocation
                            if let selected, handleRect(selected, size: size).contains(point) {
                                gestureOrigin = selected; resizing = true
                            } else if let hit = controller.draft.photos.reversed().first(where: { photoRect($0, size: size).contains(point) }) {
                                gestureOrigin = hit; resizing = false; controller.selectPhoto(hit.id)
                            }
                        }
                        if gestureOrigin != nil { gestureTranslation = value.translation }
                    }.onEnded { value in
                        if let start = gestureOrigin {
                            if resizing { place(start, width: start.widthFraction + value.translation.width / size.width) }
                            else { place(start, x: start.centerX + value.translation.width / size.width, y: start.centerY + value.translation.height / size.height) }
                        }
                        gestureOrigin = nil; gestureTranslation = .zero
                    }.exclusively(before: SpatialTapGesture().onEnded { value in
                        let photo = controller.draft.photos.reversed().first { photoRect($0, size: size).contains(value.location) }
                        controller.selectPhoto(photo?.id)
                    }))
                    .allowsHitTesting(!locked).accessibilityHidden(true)
            }.frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityRepresentation {
                    Color.clear.frame(width: size.width, height: size.height)
                        .accessibilityElement().accessibilityLabel("카드 미리보기")
                        .accessibilityIdentifier("cardCustomization.preview")
                }
        }.aspectRatio(PassFace.aspectRatio, contentMode: .fit)
    }

    private func photoRect(_ photo: CardPhoto, size: CGSize) -> CGRect {
        let width = size.width * photo.widthFraction
        let height = width * Double(photo.pixelHeight) / Double(photo.pixelWidth)
        return CGRect(x: size.width * photo.centerX - width / 2, y: size.height * photo.centerY - height / 2, width: width, height: height)
    }
    private func handleRect(_ photo: CardPhoto, size: CGSize) -> CGRect {
        let rect = photoRect(photo, size: size)
        return CGRect(x: rect.maxX - 38, y: rect.maxY - 38, width: 44, height: 44)
    }

    private func previewStyle(size: CGSize) -> CardStyle {
        var style = controller.draft
        if let start = gestureOrigin, let index = style.photos.firstIndex(where: { $0.id == start.id }) {
            if resizing {
                style.photos[index].widthFraction = min(2.5, max(0.15, start.widthFraction + gestureTranslation.width / size.width))
            } else {
                style.photos[index].centerX = min(2, max(-1, start.centerX + gestureTranslation.width / size.width))
                style.photos[index].centerY = min(2, max(-1, start.centerY + gestureTranslation.height / size.height))
            }
        }
        return style
    }

    private func place(_ photo: CardPhoto, x: Double? = nil, y: Double? = nil, width: Double? = nil) {
        guard let current = controller.draft.photos.first(where: { $0.id == photo.id }) else { return }
        controller.setPlacement(photoID: photo.id, centerX: x ?? current.centerX, centerY: y ?? current.centerY, widthFraction: width ?? current.widthFraction)
    }
    private func startImport(_ inputs: [CardPhotoInput]) {
        guard !locked else { return }
        importTask = Task { await controller.importPhotos(inputs) }
    }
}
