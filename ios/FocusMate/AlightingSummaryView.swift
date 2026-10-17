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

    private func content(_ summary: AlightingSummary) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                SceneMapBackdrop(model: model, bottomInset: sheetHeight + 24)
                    .overlay(alignment: .top) {
                        Color.black.opacity(0.3).allowsHitTesting(false)
                    }
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("하차 완료", systemImage: "checkmark.circle")
                            .font(.caption).foregroundStyle(Color(red: 0.65, green: 0.8, blue: 0.69))
                        Text("나를 위한 \(summary.minutesText)")
                            .font(.system(.title, weight: .bold))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("screen.alightingSummary")
                        Text("이번 여행을 기록했어요.")
                            .font(.subheadline).foregroundStyle(FMDesign.secondaryText)
                        Divider().overlay(.white.opacity(0.15))
                        VStack(alignment: .leading, spacing: 8) {
                            if let record = record(summary) {
                                Text(record.tag).font(.caption).foregroundStyle(tagColor(record.tagColor))
                            }
                            Text(summary.task).font(.system(.title3, weight: .semibold))
                                .accessibilityIdentifier("summary.task")
                            Text("이번 여행에서 한 일").font(.caption).foregroundStyle(FMDesign.secondaryText)
                        }
                        Divider().overlay(.white.opacity(0.15))
                        let details = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                            : AnyLayout(HStackLayout(alignment: .top, spacing: 24))
                        details {
                            row("여행 시간", summary.minutesText, id: "summary.minutes")
                            row("도착 정류장", summary.destinationName, id: "summary.destination")
                        }
                        if let record = record(summary) {
                            Text("\(record.bus) · \(record.from) → \(record.to)")
                                .font(.caption).foregroundStyle(FMDesign.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Divider().overlay(.white.opacity(0.15))
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("메모 남기기").font(.subheadline)
                                Text("선택").font(.caption).foregroundStyle(FMDesign.secondaryText)
                            }
                            TextField("기억하고 싶은 생각", text: $memoInput, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Color(red: 21 / 255, green: 26 / 255, blue: 22 / 255),
                                            in: RoundedRectangle(cornerRadius: 10))
                                .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.3)) }
                                .accessibilityLabel("메모")
                                .accessibilityIdentifier("summary.memo")
                                .onChange(of: memoInput) { _, input in
                                    draft.update(input)
                                    if draft.text != input { memoInput = draft.text }
                                }
                            Text(draft.counterText).font(.caption2).foregroundStyle(FMDesign.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .accessibilityLabel(draft.counterText)
                                .accessibilityIdentifier("summary.memoCounter")
                        }
                        if showsFailure {
                            Text(JourneyTimerDisplay.transitionFailureText).foregroundStyle(.orange)
                                .accessibilityIdentifier("summary.saveFailure")
                        }
                    }
                    .padding(22)
                    .background(GeometryReader { body in
                        Color.clear.preference(key: SummaryBodyHeightKey.self, value: body.size.height)
                    })
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button { finish() } label: {
                        Text(draft.isBlank ? "여정 마치기" : "메모 저장하고 마치기")
                    }
                    .buttonStyle(FMPrimaryButtonStyle())
                    .accessibilityIdentifier("summary.home")
                    .padding(.horizontal, 22).padding(.bottom, 22).padding(.top, 12)
                    .background(FMDesign.panel)
                    .background(GeometryReader { action in
                        Color.clear.preference(key: SummaryActionHeightKey.self, value: action.size.height)
                    })
                }
                .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 22))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .frame(height: min(max(0, proxy.size.height - 90),
                                   bodyHeight > 0 && actionHeight > 0 ? bodyHeight + actionHeight : proxy.size.height - 90))
                .background(GeometryReader { sheet in
                    Color.clear.preference(key: SummarySheetHeightKey.self, value: sheet.size.height)
                })
                .padding(.horizontal, 12).padding(.bottom, 12)
            }
            .onPreferenceChange(SummarySheetHeightKey.self) { sheetHeight = $0 }
            .onPreferenceChange(SummaryBodyHeightKey.self) { bodyHeight = $0 }
            .onPreferenceChange(SummaryActionHeightKey.self) { actionHeight = $0 }
        }
        .foregroundStyle(FMDesign.primary)
        .background(FMDesign.background)
        .toolbar(.hidden, for: .navigationBar)
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

    private func row(_ title: String, _ value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(FMDesign.secondaryText).accessibilityHidden(true)
            Text(value).font(.system(.body, weight: .semibold)).accessibilityLabel(value).accessibilityIdentifier(id)
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
