import SwiftUI

/// 기록 화면(FR-9): 연 단위 일합계 잔디, 선택 날짜의 기록 목록, 연도 이동, 메모 편집. 실제 완료 기록만 쓴다(FR-11).
@MainActor
struct RecordsView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    @State private var browser: RecordsBrowser
    @State private var editing: EditingMemo?

    private struct EditingMemo: Identifiable { let id: String; let memo: String }

    init(model: AppModel, services: JourneyServices) {
        self.model = model
        self.services = services
        _browser = State(initialValue: RecordsBrowser(today: RecordDay.from(model.recordClock.now(),
                                                                            timeZone: model.recordClock.timeZone())))
    }

    private var records: [RecordSnapshot] { model.snapshot?.records.items ?? [] }
    private var timeZone: TimeZone { model.recordClock.timeZone() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("기록").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.records")
                yearBar
                Text(RecordsCalendar.summary(year: browser.year, records: records, today: browser.today).text)
                    .foregroundStyle(.secondary).accessibilityIdentifier("records.summary")
                heatmap
                dayList
            }
            .padding(24)
        }
        .navigationTitle("기록").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { item in
            RecordMemoEditor(model: model, recordID: item.id, memo: item.memo) { editing = nil }
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) { diagnostics }
        #endif
    }

    private var yearBar: some View {
        HStack(spacing: 12) {
            Button { browser.moveYear(by: -1, records: records) } label: {
                Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!browser.canGoPreviousYear)
            .accessibilityLabel("이전 연도").accessibilityIdentifier("records.year.previous")
            Menu {
                ForEach(RecordsCalendar.yearOptions(records: records, today: browser.today, selectedYear: browser.year),
                        id: \.self) { year in
                    Button("\(String(year))년") { browser.selectYear(year, records: records) }
                }
            } label: {
                Text("\(String(browser.year))년").font(.title2.bold()).frame(minHeight: 44)
            }
            .accessibilityIdentifier("records.year.picker")
            Button { browser.moveYear(by: 1, records: records) } label: {
                Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!browser.canGoNextYear)
            .accessibilityLabel("다음 연도").accessibilityIdentifier("records.year.next")
        }
    }

    private var heatmap: some View {
        let cells = RecordsCalendar.cells(year: browser.year, records: records, today: browser.today)
        let blanks = RecordsCalendar.leadingBlanks(year: browser.year)
        let selected = cells.first { $0.day == browser.selectedDay }
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(14), spacing: 3), count: 7), spacing: 3) {
                ForEach(0..<blanks, id: \.self) { _ in Color.clear.frame(width: 14, height: 14) }
                ForEach(cells) { cell in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Self.color(level: cell.level).opacity(cell.isFuture ? 0.3 : 1))
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(cell.day == browser.selectedDay ? Color.primary : .clear, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                        .onTapGesture { browser.select(cell.day) }
                }
            }
            .padding(.vertical, 4)
        }
        // 칸 365개를 하나씩 넘기지 않도록 격자 전체를 조정 가능한 요소 하나로 읽는다.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(String(browser.year))년 날짜별 여행 시간")
        .accessibilityValue(selected?.accessibilityLabel ?? "")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: browser.stepDay(by: 1)
            case .decrement: browser.stepDay(by: -1)
            @unknown default: break
            }
        }
        .accessibilityIdentifier("records.heatmap")
    }

    @ViewBuilder private var dayList: some View {
        let visible = browser.visibleRecords(in: records)
        VStack(alignment: .leading, spacing: 12) {
            Text("\(browser.selectedDay.month)월 \(browser.selectedDay.day)일").font(.headline)
            if let empty = browser.emptyState(records: records) {
                Text(empty == .noRecords ? "첫 여행을 마치면 잔디에 색이 채워져요. 하루하루 나만의 시간을 모아보세요."
                                         : "이날은 완료한 여행이 없어요.")
                    .foregroundStyle(.secondary).accessibilityIdentifier("records.empty")
            }
            ForEach(visible, id: \.id) { record in item(record) }
            if browser.hasMore(in: records) {
                Button("더 보기") { browser.showMore() }.buttonStyle(.bordered)
                    .accessibilityIdentifier("records.more")
            }
        }
    }

    private func item(_ record: RecordSnapshot) -> some View {
        let content = RecordListItemContent(record: record, timeZone: timeZone)
        return VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.task).font(.headline)
                Text("\(content.timeText) · \(content.minutesText) · \(content.tag)").foregroundStyle(.secondary)
                Text(content.routeText).foregroundStyle(.secondary)
                if !content.memo.isEmpty { Text(content.memo) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("records.item.\(record.id)")
            Button(content.memoButtonTitle) { editing = EditingMemo(id: record.id, memo: record.memo) }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("records.memo.\(record.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }

    private static func color(level: Int) -> Color {
        switch level {
        case 0: Color.secondary.opacity(0.15)
        case 1: Color.green.opacity(0.3)
        case 2: Color.green.opacity(0.5)
        case 3: Color.green.opacity(0.75)
        default: Color.green
        }
    }

    #if DEBUG
    private var diagnostics: some View {
        let object: [String: Any] = ["year": browser.year, "selected": browser.selectedDay.key,
                                     "visibleCount": browser.visibleRecords(in: records).count,
                                     "hasMore": browser.hasMore(in: records),
                                     "canNext": browser.canGoNextYear, "canPrevious": browser.canGoPreviousYear]
        let json = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
            .map { String(decoding: $0, as: UTF8.self) } ?? "null"
        return VStack(spacing: 0) {
            Text("기록 진단").font(.system(size: 1)).foregroundStyle(.clear)
                .accessibilityValue(json).accessibilityIdentifier("test.records")
            // XCUITest는 조정 가능 요소를 슬라이더가 아니면 움직이지 못한다. VoiceOver 조정과 같은 동작을 대신 부른다.
            debugButton("다음 날", id: "test.records.nextDay") { browser.stepDay(by: 1) }
            debugButton("전날", id: "test.records.previousDay") { browser.stepDay(by: -1) }
            if let failure = services.failNextSave {
                Button { failure.arm() } label: {
                    Text("다음 저장 실패").font(.system(size: 1)).foregroundStyle(.clear)
                        .frame(width: 44, height: 44).background(Color.black).contentShape(Rectangle())
                }
                .accessibilityLabel("다음 저장 실패").accessibilityIdentifier("test.records.failNextSave")
            }
        }
    }

    private func debugButton(_ label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 44, height: 44).background(Color.black).contentShape(Rectangle())
        }
        .accessibilityLabel(label).accessibilityIdentifier(id)
    }
    #endif
}
