import SwiftUI

/// 기록 메모 편집 시트(FR-10). 200자 제한은 요약 화면과 같은 `RecordMemoDraft`를 쓴다.
@MainActor
struct RecordMemoEditor: View {
    @Bindable var model: AppModel
    let recordID: String
    let onClose: () -> Void
    @State private var draft: RecordMemoDraft
    /// 입력 칸 원문. 잘린 값으로 바뀔 때만 되돌려 써야 칸이 갱신된다.
    @State private var input: String
    @State private var showsFailure = false
    @FocusState private var memoFocused: Bool

    init(model: AppModel, recordID: String, memo: String, onClose: @escaping () -> Void) {
        self.model = model
        self.recordID = recordID
        self.onClose = onClose
        let initial = RecordMemoDraft(text: memo)
        _draft = State(initialValue: initial)
        _input = State(initialValue: initial.text)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("이번 여행은 어땠나요?")
                    .font(FontCatalog.text(18, bold: true, relativeTo: .headline))
                    .accessibilityAddTraits(.isHeader)
                TextField("이번 여행을 한 줄로 남겨보세요", text: $input)
                    .textFieldStyle(.plain)
                    .font(FontCatalog.text(16))
                    .padding(16).frame(minHeight: 56)
                    .background(Color(red: 20 / 255, green: 27 / 255, blue: 22 / 255), in: RoundedRectangle(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).stroke(memoFocused ? Color(red: 0.82, green: 0.76, blue: 0.58) : FMDesign.primary.opacity(0.3)) }
                    .focused($memoFocused)
                    .accessibilityLabel("메모")
                    .accessibilityIdentifier("recordMemo.field")
                    .onChange(of: input) { _, value in
                        draft.update(value)
                        if draft.text != value { input = draft.text }
                    }
                Text(draft.counterText).font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                    .accessibilityLabel(draft.counterText).accessibilityIdentifier("recordMemo.counter")
                if showsFailure {
                    Text(JourneyTimerDisplay.transitionFailureText).foregroundStyle(.orange)
                        .accessibilityIdentifier("recordMemo.saveFailure")
                }
                Spacer()
            }
            .padding(24)
            .background(FMDesign.background.ignoresSafeArea())
            .foregroundStyle(FMDesign.primary)
            .tint(FMDesign.primary)
            .navigationTitle("메모").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onClose).font(FontCatalog.text(15)).accessibilityIdentifier("recordMemo.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save).font(FontCatalog.text(15, bold: true)).accessibilityIdentifier("recordMemo.save")
                }
            }
        }
    }

    private func save() {
        if model.updateRecordMemo(draft.text, forJourneyID: recordID) == .done { onClose() }
        else { showsFailure = true }
    }
}
