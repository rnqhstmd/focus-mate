import SwiftUI
import PhotosUI

@MainActor
struct CardCustomizationView: View {
    @Bindable var controller: CardCustomizationController
    @Binding var importTask: Task<Void, Never>?
    let close: () -> Void
    let saved: () -> Void
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

    private let background = FMDesign.background
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
                    preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("사진을 자유롭게 배치해보세요.")
                        Text("IC 칩은 고정되고, 카드 밖은 잘려요.")
                    }.font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(secondary)
                        .padding(.top, 16)
                    colors.padding(.top, 30)
                    photos.padding(.top, 10)
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
                        .font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(secondary).padding(.top, 18)
                    Button { controller.restoreDefault() } label: {
                        Text("기본 검정 카드로 되돌리기").underline()
                    }
                        .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(secondary)
                        .frame(minHeight: 44).padding(.top, 22)
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
                Text("이 카드로 저장하기").font(FontCatalog.text(15, relativeTo: .headline))
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
            }.foregroundStyle(.black).background(.white, in: Capsule())
                .disabled(locked).accessibilityIdentifier("cardCustomization.save")
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 3).background(background)
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
        HStack(spacing: 14) {
            Button {
                if controller.requestExit() == .confirmDiscard { confirmsExit = true } else { close() }
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 22))
                    .frame(width: 52, height: 52).overlay(Circle().stroke(.white, lineWidth: 2))
            }.accessibilityLabel("닫기").accessibilityIdentifier("cardCustomization.close")
            Text("카드 꾸미기").font(FontCatalog.text(20, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.cardCustomization")
            Spacer(minLength: 0)
            Button { controller.undo() } label: { Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44) }
                .disabled(locked || !controller.canUndo).accessibilityLabel("되돌리기").accessibilityIdentifier("cardCustomization.undo")
        }.buttonStyle(.plain).padding(.leading, 14).padding(.trailing, 14).padding(.top, 0).padding(.bottom, 20)
    }

    private var colors: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("배경색").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline)).accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                ForEach(palette, id: \.0) { entry in
                    let isSelected = entry.2 == controller.draft.background
                    Button { controller.setBackground(entry.2) } label: {
                        Circle().fill(entry.2.swiftUIColor).frame(width: 39, height: 39)
                            .overlay(Circle().stroke(secondary.opacity(0.6), lineWidth: 1))
                            .overlay { if isSelected { Image(systemName: "checkmark").foregroundStyle(entry.0 == "sand" || entry.0 == "ivory" ? .black : .white) } }
                            .frame(width: 48, height: 48)
                            .overlay { if isSelected { Circle().stroke(.white, lineWidth: 2) } }
                    }.buttonStyle(.plain).accessibilityLabel(entry.1)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("cardCustomization.color." + entry.0)
                }
            }
            ColorPicker("직접 고르기", selection: Binding(get: { controller.draft.background.swiftUIColor }, set: { value in
                let ui = UIColor(value)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                if ui.getRed(&r, green: &g, blue: &b, alpha: &a) { controller.setBackground(CardColor(red: r, green: g, blue: b)) }
            }), supportsOpacity: false)
            .font(FontCatalog.text(12)).foregroundStyle(secondary).frame(maxWidth: 110, minHeight: 44)
            .accessibilityIdentifier("cardCustomization.color.custom")
        }.disabled(locked)
    }

    private var photos: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("사진").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline)).accessibilityAddTraits(.isHeader)
                Spacer()
                PhotosPicker(selection: $pickerItems, maxSelectionCount: CardCustomizationPolicy.maximumPhotos - controller.draft.photos.count,
                             selectionBehavior: .ordered, matching: .images) {
                    Label("사진 추가", systemImage: "plus").font(FontCatalog.text(12))
                        .padding(.horizontal, 14).frame(minHeight: 43)
                        .background(Color(red: 24 / 255, green: 29 / 255, blue: 32 / 255), in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(secondary.opacity(0.5)))
                }.disabled(!controller.canAddPhotos).accessibilityIdentifier("cardCustomization.photoPicker")
            }
            if controller.draft.photos.isEmpty {
                Text("좋아하는 풍경, 소중한 순간을 담아보세요.").font(FontCatalog.text(12)).foregroundStyle(secondary)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(Array(controller.draft.photos.enumerated()), id: \.element.id) { index, photo in
                            Button { controller.selectPhoto(photo.id) } label: {
                                if let image = UIImage(data: photo.data) {
                                    Image(uiImage: image).resizable().scaledToFill().frame(width: 58, height: 58).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(controller.selectedPhotoID == photo.id ? .white : .clear, lineWidth: 2))
                                }
                            }.buttonStyle(.plain).disabled(locked)
                                .accessibilityLabel("사진 \(index + 1)")
                                .accessibilityAddTraits(controller.selectedPhotoID == photo.id ? .isSelected : [])
                                .accessibilityIdentifier("cardCustomization.photo." + photo.id.uuidString)
                        }
                    }.padding(3)
                }.accessibilityIdentifier("cardCustomization.photos")
            }
        }
    }

    private func tools(_ photo: CardPhoto) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Text("사진 크기"); Spacer(); Text("\(Int(photo.widthFraction * 100))%") }
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
                PassFace(style: style, dotsOpacity: 0.25).accessibilityHidden(true)
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
