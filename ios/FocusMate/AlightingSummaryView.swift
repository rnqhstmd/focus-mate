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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("오늘의 여행").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("screen.alightingSummary")
                row("한 일", summary.task, id: "summary.task")
                row("여행 시간", summary.minutesText, id: "summary.minutes")
                row("도착 정류장", summary.destinationName, id: "summary.destination")
                VStack(alignment: .leading, spacing: 8) {
                    Text("메모 (선택)").font(.headline)
                    TextField("이번 여행을 한 줄로 남겨보세요", text: $memoInput, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("메모")
                        .accessibilityIdentifier("summary.memo")
                        .onChange(of: memoInput) { _, input in
                            draft.update(input)
                            if draft.text != input { memoInput = draft.text }
                        }
                    Text(draft.counterText).font(.footnote).foregroundStyle(.secondary)
                        .accessibilityLabel(draft.counterText)
                        .accessibilityIdentifier("summary.memoCounter")
                }
                if showsFailure {
                    Text(JourneyTimerDisplay.transitionFailureText).foregroundStyle(.orange)
                        .accessibilityIdentifier("summary.saveFailure")
                }
                Button { finish() } label: {
                    Text("메인으로").frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("summary.home")
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            if let failure = services.failNextSave {
                Button { failure.arm() } label: {
                    Text("다음 저장 실패").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).background(Color.black).contentShape(Rectangle())
                }
                .accessibilityLabel("다음 저장 실패").accessibilityIdentifier("test.summary.failNextSave")
            }
        }
        #endif
    }

    private func row(_ title: String, _ value: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(value).font(.title3.bold()).accessibilityLabel(value).accessibilityIdentifier(id)
        }
    }

    private func finish() {
        showsFailure = model.finishAlightingSummary(memo: draft.text) == .saveFailed
    }
}
