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
        // 시안 R19: 지도 위 떠 있는 패널. 순서는 제목 → 탭 → 안내 → 연도 머리줄 → 요약 → 연도 칩 → 잔디 상자 → 범례 → 구분선 → 날짜 목록.
        // 간격은 시안 글자 위끝 기준에서 Noto 줄 높이(1.45em)를 뺀 값이다.
        RecordsPanelScreen(model: model) {
            VStack(alignment: .leading, spacing: 0) {
                Text("여행 기록").font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.records")
                RecordsTabBar(tabs: [
                    .init(title: "잔디", selected: true, identifier: nil, action: nil),
                    .init(title: "분석", selected: false, identifier: "records.analytics.open") {
                        widgetEntry = nil; refreshBrowserToday(); showsAnalytics = true
                    },
                ])
                .padding(.top, 17)
                Text("날짜를 눌러 둘러보세요.").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                    .padding(.top, 13)
                yearBar.padding(.top, 23)
                Text(RecordsCalendar.summary(year: browser.year, records: records, today: browser.today).text)
                    .font(FontCatalog.text(12, relativeTo: .caption)).foregroundStyle(Color(hex: 0xC3CDC6)).accessibilityIdentifier("records.summary")
                    .padding(.top, 15)
                yearChips.padding(.top, 16)
                heatmap.padding(.top, 22)
                legend.padding(.top, 8)
                Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1).padding(.top, 28)
                dayList.padding(.top, 15)
            }
        }
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

    /// 시안 R19: 왼쪽 "2026년의 여행" 18 Bold, 오른쪽 "‹ 올해 ›"(갈매기 흰색, "올해" 11pt #D2DDD6).
    private var yearBar: some View {
        HStack(spacing: 0) {
            Text("\(String(browser.year))년의 여행").font(FontCatalog.text(18, weight: .bold, relativeTo: .title3))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button { browser.moveYear(by: -1, records: records) } label: {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .regular)).frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!browser.canGoPreviousYear)
            .accessibilityLabel("이전 연도").accessibilityIdentifier("records.year.previous")
            Button { browser.selectYear(browser.today.year, records: records) } label: {
                Text("올해").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(Color(hex: 0xD2DDD6))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityIdentifier("records.year.current")
            Button { browser.moveYear(by: 1, records: records) } label: {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .regular)).frame(minWidth: 44, minHeight: 44)
            }
            .disabled(!browser.canGoNextYear)
            .accessibilityLabel("다음 연도").accessibilityIdentifier("records.year.next")
        }
        .buttonStyle(.plain)
        .padding(.trailing, -10)
        .frame(height: 26)
    }

    /// 시안 R19 연도 칩: 64x44, 선택 #F3F6F3 반경 8 + 12pt #0A0A0A, 비선택 12pt #C5CDC7.
    private var yearChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(RecordsCalendar.yearOptions(records: records, today: browser.today, selectedYear: browser.year),
                        id: \.self) { year in
                    let selected = year == browser.year
                    Button { browser.selectYear(year, records: records) } label: {
                        Text(String(year)).font(FontCatalog.text(12, relativeTo: .caption))
                            .foregroundStyle(selected ? FMDesign.panel : Color(hex: 0xC5CDC7))
                            .padding(.horizontal, 8)
                            .frame(minWidth: 64, minHeight: 44)
                            .background(selected ? Color(hex: 0xF3F6F3) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(String(year))년")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("records.year.\(year)")
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// 시안 R19 잔디 상자: 332x85 #0B100D, 흰 15% 테두리, 반경 6. 월 라벨은 상자 안 위, 칸 4pt·간격 1.5.
    private var heatmap: some View {
        let cells = RecordsCalendar.cells(year: browser.year, records: records, today: browser.today)
        let blanks = RecordsCalendar.leadingBlanks(year: browser.year)
        let selected = cells.first { $0.day == browser.selectedDay }
        let weeks = (cells.count + blanks + 6) / 7
        let large = typeSize.isAccessibilitySize
        let gap: CGFloat = large ? 3 : 1.5
        let labelColor = Color(hex: 0xBFC8C1)
        return GeometryReader { geometry in
            // 상자 안쪽: 왼쪽 요일 열까지 32, 오른쪽 10.
            let side: CGFloat = large ? 14 : max(2, (geometry.size.width - 42 - CGFloat(weeks - 1) * gap) / CGFloat(weeks))
            let pitch = side + gap
            let gridWidth = CGFloat(weeks) * side + CGFloat(weeks - 1) * gap
            ScrollView(.horizontal, showsIndicators: large) {
                VStack(alignment: .leading, spacing: large ? 8 : 10) {
                    ZStack(alignment: .topLeading) {
                        ForEach(1...12, id: \.self) { month in
                            let index = cells.firstIndex { $0.day.month == month } ?? 0
                            Text("\(month)월").font(FontCatalog.text(8, relativeTo: .caption2))
                                .fixedSize()
                                .offset(x: CGFloat((index + blanks) / 7) * pitch)
                        }
                    }
                    .frame(width: gridWidth, alignment: .leading)
                    .padding(.leading, 32)
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                Text(row == 1 ? "월" : row == 3 ? "수" : row == 5 ? "금" : "")
                                    .font(FontCatalog.text(8, relativeTo: .caption2))
                                    .fixedSize()
                                    .frame(width: 8, height: side)
                            }
                        }
                        .padding(.leading, 7).frame(width: 32, alignment: .leading)
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(side), spacing: gap), count: 7), spacing: gap) {
                            ForEach(0..<blanks, id: \.self) { _ in Color.clear.frame(width: side, height: side) }
                            ForEach(cells) { cell in
                                RoundedRectangle(cornerRadius: min(1, side / 4))
                                    .fill(Self.color(level: cell.level).opacity(cell.isFuture ? 0.3 : 1))
                                    .frame(width: side, height: side)
                                    // 시안: 선택 날짜는 칸보다 1.5pt씩 큰 흰 테두리.
                                    .overlay {
                                        if cell.day == browser.selectedDay {
                                            RoundedRectangle(cornerRadius: 2).stroke(.white, lineWidth: 1)
                                                .frame(width: side + 3, height: side + 3)
                                        }
                                    }
                                    .onTapGesture { browser.select(cell.day) }
                            }
                        }
                    }
                }
                .foregroundStyle(labelColor)
                .padding(.top, 13).padding(.bottom, 12).padding(.trailing, 10)
            }
        }
        .frame(height: large ? 180 : 85)
        .background(Color(hex: 0x0B100D), in: RoundedRectangle(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.15), lineWidth: 1) }
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

    /// 시안 R19 범례: 상자 아래 10pt #B8C4BC, 왼쪽 "하루 여행 시간", 오른쪽 9x9 칸 5개(간격 3) + "적음 → 많음".
    private var legend: some View {
        HStack(spacing: 0) {
            Text("하루 여행 시간")
            Spacer(minLength: 8)
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 1).fill(Self.color(level: level)).frame(width: 9, height: 9)
                }
            }
            .accessibilityHidden(true)
            Text("적음 → 많음").padding(.leading, 5)
        }
        .font(FontCatalog.text(10, relativeTo: .caption2))
        .foregroundStyle(Color(hex: 0xB8C4BC))
    }

    @ViewBuilder private var dayList: some View {
        let visible = browser.visibleRecords(in: records)
        let dated = RecordsCalendar.records(on: browser.selectedDay, in: records)
        VStack(alignment: .leading, spacing: 0) {
            // 시안 R19: "10월 12일 월요일" 16 Bold, 오른쪽 "2회 · 1 h 15 min" 11pt #C3CDC6.
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(browser.selectedDay.month)월 \(browser.selectedDay.day)일 \(browser.selectedDay.weekdayName)")
                    .font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
                Spacer(minLength: 0)
                if !dated.isEmpty {
                    Text("\(dated.count)회 · \(ProfileTimeText.display(minutes: dated.reduce(0) { $0 + $1.minutes }))")
                        .font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(Color(hex: 0xC3CDC6))
                }
            }
            if let empty = browser.emptyState(records: records) {
                Text(empty == .noRecords ? "첫 여행을 마치면 잔디에 색이 채워져요. 하루하루 나만의 시간을 모아보세요."
                                         : "이날은 완료한 여행이 없어요.")
                    .font(FontCatalog.text(13, relativeTo: .subheadline))
                    .foregroundStyle(FMDesign.secondaryText).accessibilityIdentifier("records.empty")
                    .padding(.top, 14)
            }
            ForEach(visible, id: \.id) { record in item(record) }
            if browser.hasMore(in: records) {
                Button("더 보기") { browser.showMore() }.buttonStyle(FMSecondaryButtonStyle())
                    .accessibilityIdentifier("records.more")
                    .padding(.top, 12)
            }
        }
    }

    /// 시안 R19 기록 줄: 할 일 16 Bold → "출발 → 도착" 11pt #BFC6C1 → "태그 · 25 min · 버스" 11pt 태그 색.
    private func item(_ record: RecordSnapshot) -> some View {
        let content = RecordListItemContent(record: record, timeZone: timeZone)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(content.task).font(FontCatalog.text(16, weight: .bold, relativeTo: .headline))
                Text("\(record.from) → \(record.to)").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                    .padding(.top, 6)
                Text("\(content.tag) · \(content.minutesText) · \(record.bus)").font(FontCatalog.text(11, relativeTo: .caption))
                    .foregroundStyle(Color(hexString: record.tagColor))
                    .padding(.top, 7)
                if !content.memo.isEmpty {
                    Text(content.memo).font(FontCatalog.text(13, relativeTo: .subheadline)).padding(.top, 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(content.task), \(content.timeText) · \(content.minutesText) · \(content.tag), \(content.routeText)"
                                + (content.memo.isEmpty ? "" : ", \(content.memo)"))
            .accessibilityIdentifier("records.item.\(record.id)")
            // 시안에는 메모 버튼이 없지만 기록 메모를 고치는 유일한 길이라 작게 남긴다.
            Button(content.memoButtonTitle) { editing = EditingMemo(id: record.id, memo: record.memo) }
                .buttonStyle(.plain).font(FontCatalog.text(11, relativeTo: .caption))
                .foregroundStyle(Color(hex: 0xDDDDDD))
                .frame(minHeight: 44)
                .accessibilityIdentifier("records.memo.\(record.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 17)
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
