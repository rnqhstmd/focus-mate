import SwiftUI

/// 기록 화면(FR-9): 연 단위 일합계 잔디, 선택 날짜의 기록 목록, 연도 이동, 메모 편집. 실제 완료 기록만 쓴다(FR-11).
@MainActor
struct RecordsView: View {
    @Bindable var model: AppModel
    let services: JourneyServices
    @State private var browser: RecordsBrowser
    @State private var editing: EditingMemo?
    @State private var showsAnalytics = false
    @State private var widgetEntry: WidgetAnalyticsEntry?
    @State private var pendingAnalyticsRecordID: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize

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
            VStack(spacing: 0) {
            SceneMapBackdrop(model: model, showsStationAnnotation: false)
                .frame(height: 120)
            VStack(alignment: .leading, spacing: 20) {
                Text("여행 기록").font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.records")
                HStack(spacing: 4) {
                    Text("잔디").font(FontCatalog.text(13, weight: .bold, relativeTo: .subheadline))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(FMDesign.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityAddTraits(.isSelected)
                    Button("분석 보기") { widgetEntry = nil; refreshBrowserToday(); showsAnalytics = true }
                        .font(FontCatalog.text(13, relativeTo: .subheadline))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("records.analytics.open")
                }
                .padding(3).background(FMDesign.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                yearBar
                Text(RecordsCalendar.summary(year: browser.year, records: records, today: browser.today).text)
                    .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText).accessibilityIdentifier("records.summary")
                heatmap
                dayList
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fmPanel()
            .padding(.horizontal, 12).padding(.vertical, 20)
            }
        }
        .background(FMDesign.background.ignoresSafeArea())
        .foregroundStyle(FMDesign.primary).tint(FMDesign.primary)
        .font(FontCatalog.text(15))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showsAnalytics) {
            RecordsAnalyticsView(model: model, selectedDay: widgetEntry?.day ?? browser.selectedDay.key, initialTag: widgetEntry?.tag, initialKind: widgetEntry?.kind) { id in
                guard records.contains(where: { $0.id.utf16.elementsEqual(id.utf16) }) else { return }
                pendingAnalyticsRecordID = id
                showsAnalytics = false
            }
            .id(widgetEntry.map { "\($0.day)|\($0.kind.rawValue)|\($0.tag ?? "")" } ?? "records")
            .onDisappear { openPendingAnalyticsRecord() }
        }
        .onAppear {
            if let entry = model.consumeWidgetAnalyticsEntry() {
                widgetEntry = entry
                if let day = RecordDay(key: entry.day) { _ = browser.select(day) }
                showsAnalytics = true
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { refreshBrowserToday() } }
        .sheet(item: $editing) { item in
            RecordMemoEditor(model: model, recordID: item.id, memo: item.memo) { editing = nil }
        }
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            if services.failNextSave != nil { diagnostics }
        }
        #endif
    }

    private func refreshBrowserToday() {
        let today = RecordDay.from(model.recordClock.now(), timeZone: timeZone)
        guard today != browser.today else { return }
        var updated = RecordsBrowser(today: today)
        updated.select(min(browser.selectedDay, today))
        browser = updated
    }

    private func openPendingAnalyticsRecord() {
        guard let id = pendingAnalyticsRecordID else { return }
        pendingAnalyticsRecordID = nil
        guard let record = records.first(where: { $0.id.utf16.elementsEqual(id.utf16) }),
              let day = RecordDay(key: record.date) else { return }
        refreshBrowserToday()
        guard browser.select(day) else { return }
        let dated = RecordsCalendar.records(on: day, in: records)
        if let index = dated.firstIndex(where: { $0.id.utf16.elementsEqual(id.utf16) }) {
            while browser.listLimit <= index { browser.showMore() }
        }
        editing = EditingMemo(id: record.id, memo: record.memo)
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
                Text("\(String(browser.year))년").font(FontCatalog.text(18, weight: .bold, relativeTo: .title3))
                    .padding(.horizontal, 14).frame(minHeight: 44)
                    .foregroundStyle(FMDesign.panel)
                    .background(FMDesign.primary, in: RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityIdentifier("records.year.picker")
            Button { browser.moveYear(by: 1, records: records) } label: {
                Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!browser.canGoNextYear)
            .accessibilityLabel("다음 연도").accessibilityIdentifier("records.year.next")
        }.buttonStyle(.plain)
    }

    private var heatmap: some View {
        let cells = RecordsCalendar.cells(year: browser.year, records: records, today: browser.today)
        let blanks = RecordsCalendar.leadingBlanks(year: browser.year)
        let selected = cells.first { $0.day == browser.selectedDay }
        let weeks = (cells.count + blanks + 6) / 7
        return GeometryReader { geometry in
            let gap: CGFloat = typeSize.isAccessibilitySize ? 3 : 1.5
            let side: CGFloat = typeSize.isAccessibilitySize ? 14 : max(2, (geometry.size.width - 20 - CGFloat(weeks - 1) * gap) / CGFloat(weeks))
            let gridWidth = CGFloat(weeks) * side + CGFloat(weeks - 1) * gap
            ScrollView(.horizontal, showsIndicators: typeSize.isAccessibilitySize) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").font(FontCatalog.text(8, relativeTo: .caption2))
                                .frame(width: gridWidth / 12, alignment: .leading)
                        }
                    }.padding(.leading, 20)
                    HStack(alignment: .top, spacing: 5) {
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                Text(row == 1 ? "월" : row == 3 ? "수" : row == 5 ? "금" : "")
                                    .font(FontCatalog.text(8, relativeTo: .caption2))
                                    .frame(width: 15, height: side)
                            }
                        }
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(side), spacing: gap), count: 7), spacing: gap) {
                            ForEach(0..<blanks, id: \.self) { _ in Color.clear.frame(width: side, height: side) }
                            ForEach(cells) { cell in
                                RoundedRectangle(cornerRadius: min(3, side / 4))
                                    .fill(Self.color(level: cell.level).opacity(cell.isFuture ? 0.3 : 1))
                                    .overlay(RoundedRectangle(cornerRadius: min(3, side / 4))
                                        .stroke(cell.day == browser.selectedDay ? FMDesign.primary : .clear, lineWidth: 1))
                                    .frame(width: side, height: side)
                                    .onTapGesture { browser.select(cell.day) }
                            }
                        }
                    }
                    HStack(spacing: 4) {
                        Text("하루 여행 시간")
                        Spacer(minLength: 8)
                        Text("적음")
                        ForEach(0..<5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 1).fill(Self.color(level: level)).frame(width: 8, height: 8)
                        }
                        Text("많음")
                    }
                    .font(FontCatalog.text(9, relativeTo: .caption2))
                    .frame(width: gridWidth + 20)
                }
                .foregroundStyle(FMDesign.secondaryText)
                .padding(.vertical, 4)
            }
        }
        .frame(height: typeSize.isAccessibilitySize ? 180 : 100)
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
            Text("\(browser.selectedDay.month)월 \(browser.selectedDay.day)일").font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
            if let empty = browser.emptyState(records: records) {
                Text(empty == .noRecords ? "첫 여행을 마치면 잔디에 색이 채워져요. 하루하루 나만의 시간을 모아보세요."
                                         : "이날은 완료한 여행이 없어요.")
                    .foregroundStyle(FMDesign.secondaryText).accessibilityIdentifier("records.empty")
            }
            ForEach(visible, id: \.id) { record in item(record) }
            if browser.hasMore(in: records) {
                Button("더 보기") { browser.showMore() }.buttonStyle(FMSecondaryButtonStyle())
                    .accessibilityIdentifier("records.more")
            }
        }
    }

    private func item(_ record: RecordSnapshot) -> some View {
        let content = RecordListItemContent(record: record, timeZone: timeZone)
        return VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.task).font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
                Text("\(content.timeText) · \(content.minutesText) · \(content.tag)").font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                Text(content.routeText).font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                if !content.memo.isEmpty { Text(content.memo) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("records.item.\(record.id)")
            Button(content.memoButtonTitle) { editing = EditingMemo(id: record.id, memo: record.memo) }
                .buttonStyle(.plain).font(FontCatalog.text(12, relativeTo: .caption))
                .frame(minHeight: 44)
                .accessibilityIdentifier("records.memo.\(record.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) { Rectangle().fill(FMDesign.primary.opacity(0.14)).frame(height: 1) }
    }

    private static func color(level: Int) -> Color {
        switch level {
        case 0: Color(red: 27 / 255, green: 33 / 255, blue: 30 / 255)
        case 1: Color(red: 14 / 255, green: 68 / 255, blue: 41 / 255)
        case 2: Color(red: 0, green: 109 / 255, blue: 50 / 255)
        case 3: Color(red: 38 / 255, green: 166 / 255, blue: 65 / 255)
        default: Color(red: 57 / 255, green: 211 / 255, blue: 83 / 255)
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
                        .frame(width: 44, height: 44).background(Color.black.opacity(0.02)).contentShape(Rectangle())
                }
                .accessibilityLabel("다음 저장 실패").accessibilityIdentifier("test.records.failNextSave")
            }
        }
    }

    private func debugButton(_ label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 1)).foregroundStyle(.clear)
                .frame(width: 44, height: 44).background(Color.black.opacity(0.02)).contentShape(Rectangle())
        }
        .accessibilityLabel(label).accessibilityIdentifier(id)
    }
    #endif
}
