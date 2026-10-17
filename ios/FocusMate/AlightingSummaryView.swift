import SwiftUI

/// 하차 후 요약. 한 일·시간·도착 정류장과 200자 선택 메모(FR-6). 뒤로가기 없이 '메인으로'로만 끝낸다.
@MainActor
struct AlightingSummaryView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    @State private var draft = RecordMemoDraft()
    /// 입력 칸의 원문. 같은 값을 다시 넣으면 SwiftUI가 칸을 갱신하지 않아, 잘린 값으로 바뀔 때만 되돌려 쓴다.
    @State private var memoInput = ""
    @State private var showsFailure = false
    @State private var sheetHeight: CGFloat = 0
    @State private var bodyHeight: CGFloat = 0
    @State private var actionHeight: CGFloat = 0
    @FocusState private var memoFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if let summary = model.alightingSummary { content(summary) }
            else { Color.clear }
        }
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(NavigationPopBlocker())
    }

    /// 시안 R17·R30 패널: 화면 바닥 20pt 위, 반경 26, 안쪽 여백 위 31·좌우 27, 메모를 펼치면 위끝이 y=124까지 올라간다.
    /// 간격 값은 시안 줄 위끝 간격에서 Noto 줄 높이(1.45em)의 위아래 여유를 뺀 것이다.
    private func content(_ summary: AlightingSummary) -> some View {
        GeometryReader { proxy in
            let maxPanel = max(240, proxy.size.height + proxy.safeAreaInsets.bottom - 20
                               - max(0, 124 - proxy.safeAreaInsets.top))
            ZStack(alignment: .bottom) {
                SceneMapBackdrop(model: model, bottomInset: sheetHeight + 24, routeID: summary.routeID,
                                 showsStationAnnotation: summary.legStops == nil,
                                 leg: summary.legStops, finished: summary.legStops != nil)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Label {
                            Text("하차 완료")
                        } icon: {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
                        }
                        .labelStyle(SummaryCheckLabelStyle())
                        .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(Color(hex: 0xA6CCAF))
                        Text("나를 위한 \(summary.minutesText)")
                            .font(FontCatalog.text(26, weight: .bold, relativeTo: .title))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("screen.alightingSummary")
                            .padding(.top, 14.5)
                        Text("여행을 마쳤어요.")
                            .font(FontCatalog.text(13, relativeTo: .subheadline)).foregroundStyle(Color(hex: 0x9FA6A0))
                            .padding(.top, 12)
                        divider.padding(.top, 28)
                        if let record = record(summary) {
                            Text(record.tag).font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(tagColor(record.tagColor))
                                .padding(.top, 21)
                        }
                        Text(summary.task).font(FontCatalog.text(21, weight: .bold, relativeTo: .title3))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("summary.task")
                            .padding(.top, record(summary) == nil ? 21 : 8.5)
                        Text("이번 여행에서 한 일").font(FontCatalog.text(11, relativeTo: .caption2)).foregroundStyle(Self.labelColor)
                            .padding(.top, 8.5)
                        divider.padding(.top, 21.5)
                        let details = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                            : AnyLayout(HStackLayout(alignment: .top, spacing: 0))
                        details {
                            row("여행 시간", summary.minutesText, id: "summary.minutes")
                                .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 139, alignment: .leading)
                            row("도착 정류장", summary.destinationName, id: "summary.destination")
                        }
                        .padding(.top, 14.5)
                        if let record = record(summary) {
                            Text("\(record.bus)번 · \(record.from) → \(record.to)")
                                .font(FontCatalog.text(11, relativeTo: .caption2)).foregroundStyle(Color(hex: 0x8F9892))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 19)
                        }
                        divider.padding(.top, 25.5)
                        memo.padding(.top, 22)
                        if showsFailure {
                            Text(JourneyTimerDisplay.transitionFailureText).foregroundStyle(.orange)
                                .accessibilityIdentifier("summary.saveFailure")
                                .padding(.top, 12)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 28).padding(.horizontal, 27)
                    .background(GeometryReader { body in
                        Color.clear.preference(key: SummaryBodyHeightKey.self, value: body.size.height)
                    })
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button { finish() } label: {
                        Text(draft.isBlank ? "여정 마치기" : "메모 저장하고 마치기")
                    }
                    .buttonStyle(FMPrimaryButtonStyle(size: .compact))
                    .accessibilityIdentifier("summary.home")
                    .padding(.horizontal, 26).padding(.bottom, 24).padding(.top, 24)
                    .background(FMDesign.panel)
                    .background(GeometryReader { action in
                        Color.clear.preference(key: SummaryActionHeightKey.self, value: action.size.height)
                    })
                }
                .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 26))
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay { RoundedRectangle(cornerRadius: 26).strokeBorder(FMDesign.panelStroke, lineWidth: 1) }
                .frame(height: min(maxPanel, bodyHeight > 0 && actionHeight > 0 ? bodyHeight + actionHeight : maxPanel))
                .background(GeometryReader { sheet in
                    Color.clear.preference(key: SummarySheetHeightKey.self, value: sheet.size.height)
                })
                .padding(.horizontal, 12).padding(.bottom, 20)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .onPreferenceChange(SummarySheetHeightKey.self) { sheetHeight = $0 }
            .onPreferenceChange(SummaryBodyHeightKey.self) { bodyHeight = $0 }
            .onPreferenceChange(SummaryActionHeightKey.self) { actionHeight = $0 }
        }
        .foregroundStyle(FMDesign.primary)
        .background(FMDesign.background)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if let failure = services.failNextSave {
                Button { failure.arm() } label: {
                    Text("다음 저장 실패").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).background(Color.white.opacity(0.001)).contentShape(Rectangle())
                }
                .accessibilityLabel("다음 저장 실패").accessibilityIdentifier("test.summary.failNextSave")
            }
        }
        #endif
    }

    private static let labelColor = Color(hex: 0x929B95)

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1).accessibilityHidden(true)
    }

    /// 시안 R30(펼친 메모): 칸 위 라벨, #151A16 칸(반경 12, #5C655F 테두리), 입력 중 금색 바깥 테두리, 13pt 글자.
    /// 접기·"메모 저장" 별도 동작은 새 동작이라 두지 않는다(펼친 모양만 시안대로).
    private var memo: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("메모 남기기").font(FontCatalog.text(14, relativeTo: .subheadline)).foregroundStyle(.white)
                Text("선택").font(FontCatalog.text(11, relativeTo: .caption2)).foregroundStyle(Color(hex: 0x858E87))
            }
            Text("기억하고 싶은 생각").font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(Color(hex: 0xCCCCCC))
                .padding(.top, 16)
                .accessibilityHidden(true)
            TextField("", text: $memoInput, axis: .vertical)
                .font(FontCatalog.text(13, relativeTo: .body))
                .lineSpacing(1)
                .lineLimit(2...6)
                .focused($memoFocused)
                .padding(.horizontal, 12).padding(.vertical, 15)
                .frame(maxWidth: .infinity, minHeight: 91, alignment: .topLeading)
                // 칸의 빈 아래쪽을 눌러도 입력을 시작한다(글자 영역 밖 터치).
                .background { Color.clear.contentShape(Rectangle()).onTapGesture { memoFocused = true } }
                .background(Color(hex: 0x151A16), in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: 0x5C655F), lineWidth: 1) }
                .overlay {
                    if memoFocused {
                        RoundedRectangle(cornerRadius: 15).strokeBorder(Color(hex: 0xD7B378), lineWidth: 2).padding(-3)
                    }
                }
                .accessibilityLabel("메모")
                .accessibilityIdentifier("summary.memo")
                .onChange(of: memoInput) { _, input in
                    draft.update(input)
                    if draft.text != input { memoInput = draft.text }
                }
                .padding(.top, 7)
            Text(draft.counterText).font(FontCatalog.text(10, relativeTo: .caption2)).foregroundStyle(Self.labelColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(draft.counterText)
                .accessibilityIdentifier("summary.memoCounter")
                .padding(.top, 3)
        }
    }

    private func row(_ title: String, _ value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(FontCatalog.text(11, relativeTo: .caption2)).foregroundStyle(Self.labelColor).accessibilityHidden(true)
            Text(value).font(FontCatalog.text(15, weight: .bold, relativeTo: .body))
                .foregroundStyle(.white)
                .accessibilityLabel(value).accessibilityIdentifier(id)
        }
    }

    private func record(_ summary: AlightingSummary) -> RecordSnapshot? {
        model.snapshot?.records.items.first { $0.id == summary.recordID }
    }

    private func tagColor(_ hex: String) -> Color {
        guard let rgb = UInt32(hex.dropFirst(), radix: 16) else { return FMDesign.secondaryText }
        return Color(red: Double((rgb >> 16) & 255) / 255,
                     green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
    }

    private func finish() {
        showsFailure = model.finishAlightingSummary(memo: draft.text) == .saveFailed
    }
}

private struct SummarySheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct SummaryBodyHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct SummaryActionHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// "하차 완료": 체크 11pt, 글자와 10pt 간격(시안 R17).
private struct SummaryCheckLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) { configuration.icon; configuration.title }
    }
}
