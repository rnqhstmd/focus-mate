import SwiftUI

@MainActor
struct RecordsAnalyticsView: View {
    @Bindable var model: AppModel
    let onOpenRecord: (String) -> Void
    @State private var browser: RecordsAnalyticsBrowser?
    @State private var observedAt: Date
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss

    init(model: AppModel, selectedDay: String, initialTag: String? = nil, initialKind: AnalyticsPeriodKind? = nil, onOpenRecord: @escaping (String) -> Void) {
        self.model = model
        self.onOpenRecord = onOpenRecord
        let calendar = Calendar(identifier: .gregorian)
        var initial = try? RecordsAnalyticsBrowser(selectedDay: selectedDay, calendar: calendar)
        if let kind = initialKind { try? initial?.setKind(kind, calendar: calendar) }
        if let period = initial?.period,
           case .available(let value) = RecordsAnalyticsAdapter.load(section: model.snapshot?.records, period: period,
               selectedTag: nil, now: model.recordClock.now(), calendar: calendar, timeZone: model.recordClock.timeZone()) {
            initial?.selectTag(initialTag, available: value.computation.report.tags)
        }
        _browser = State(initialValue: initial)
        _observedAt = State(initialValue: model.recordClock.now())
    }

    private var calendar: Calendar { Calendar(identifier: .gregorian) }
    private var timeZone: TimeZone { model.recordClock.timeZone() }
    private var today: String { (try? RecordsAnalytics.today(now: observedAt, calendar: calendar, timeZone: timeZone)) ?? "" }
    private var content: RecordsAnalyticsLoad {
        guard let browser else { return .unavailable }
        return RecordsAnalyticsAdapter.load(section: model.snapshot?.records, period: browser.period, selectedTag: browser.selectedTag,
                                           now: observedAt, calendar: calendar, timeZone: timeZone)
    }

    var body: some View {
        // 시안 R23·R24: 기록 화면과 같은 떠 있는 패널. 기록이 하나도 없으면 패널 높이를 내용에 맞춘다(R24).
        RecordsPanelScreen(model: model, hugsContent: !hasAnyRecords) {
            VStack(alignment: .leading, spacing: 0) {
                Text("여행 분석").font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.analytics")
                RecordsTabBar(tabs: [
                    .init(title: "잔디", selected: false, identifier: "analytics.tab.records") { dismiss() },
                    .init(title: "분석", selected: true, identifier: nil, action: nil),
                ])
                .padding(.top, 17)
                if let browser {
                    toolbar(browser).padding(.top, 20)
                    Text(periodTitle(browser.period)).font(FontCatalog.text(18, weight: .bold, relativeTo: .title3)).accessibilityIdentifier("analytics.range")
                        .padding(.top, 3)
                }
                switch content {
                case .unavailable:
                    Text("기록을 불러올 수 없어요").accessibilityIdentifier("analytics.unavailable").padding(.top, 24)
                    Button("기록으로 돌아가기") { dismiss() }.buttonStyle(FMPrimaryButtonStyle(size: .compact)).padding(.top, 16)
                case .available(let value):
                    analysis(value)
                }
            }
        }
        .foregroundStyle(FMDesign.primary).tint(FMDesign.primary)
        .font(FontCatalog.text(15))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
    }

    private var hasAnyRecords: Bool {
        if case .available(let value) = content { return value.hasAnyEligibleRecords }
        return true
    }

    private func refresh() {
        observedAt = model.recordClock.now()
        if case .available(let value) = content { browser?.reconcileTags(available: value.computation.report.tags) }
    }

    private func editBrowser(_ action: (inout RecordsAnalyticsBrowser) throws -> Void) {
        guard var next = browser else { return }
        do { try action(&next); browser = next } catch { browser = nil }
    }

    /// 시안 R23: 한 줄에 "주간 · 월간"(11pt, 선택 칩 #303B34 반경 8 높이 38)과 오른쪽 "‹ 이번 달 ›"(11pt #CBD6CE).
    private func toolbar(_ state: RecordsAnalyticsBrowser) -> some View {
        let muted = Color(hex: 0xCBD6CE)
        return HStack(spacing: 0) {
            periodButton("주간", kind: .week, state: state)
            periodButton("월간", kind: .month, state: state)
            Spacer(minLength: 8)
            Button { editBrowser { _ = try $0.move(by: -1, today: today, calendar: calendar) } } label: {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .regular)).frame(minWidth: 44, minHeight: 44)
            }.accessibilityLabel("이전 기간").accessibilityIdentifier("analytics.previous")
            Button {
                observedAt = model.recordClock.now()
                editBrowser { try $0.returnToToday(today: today, calendar: calendar) }
            } label: {
                Text(state.period.kind == .week ? "이번 주" : "이번 달").font(FontCatalog.text(11, relativeTo: .caption))
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityIdentifier("analytics.today")
            Button { editBrowser { _ = try $0.move(by: 1, today: today, calendar: calendar) } } label: {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .regular)).frame(minWidth: 44, minHeight: 44)
            }
            .disabled((try? RecordsAnalytics.shift(period: state.period, by: 1, today: today, calendar: calendar)) == nil)
            .accessibilityLabel("다음 기간").accessibilityIdentifier("analytics.next")
        }
        .buttonStyle(.plain)
        .foregroundStyle(muted)
        .padding(.trailing, -10)
    }

    private func periodButton(_ title: String, kind: AnalyticsPeriodKind, state: RecordsAnalyticsBrowser) -> some View {
        let selected = state.period.kind == kind
        return Button { editBrowser { try $0.setKind(kind, calendar: calendar) } } label: {
            Text(title)
                .font(FontCatalog.text(11, relativeTo: .caption))
                .foregroundStyle(selected ? Color.white : Color(hex: 0xCBD6CE))
                .padding(.horizontal, 6).frame(minHeight: 38)
                .background(selected ? Color(hex: 0x303B34) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("analytics.period.\(kind.rawValue)")
    }

    @ViewBuilder private func analysis(_ value: RecordsAnalyticsContent) -> some View {
        let computation = value.computation
        let report = computation.report
        summary(report).padding(.top, 20)
        // 태그 집계는 아직 전체 기간 기준이라 제목의 "전체 기간"을 남긴다(시안은 선택 기간 집계 — 동작 변경이라 보류).
        Text("태그별 여행 시간 · 전체 기간").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            .padding(.top, 18)
        // 시안 R24: 태그가 없어도 빈 고리와 "0 min 합계"를 그린다. 범례는 태그가 있을 때만.
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(alignment: .top, spacing: 26))
        layout {
            donut(report).padding(.top, 14)
            if !report.tags.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(report.topTags, id: \.id) { tag in
                        HStack(alignment: .top, spacing: 8) {
                            Capsule().fill(color(tag.color)).frame(width: 6, height: 20).padding(.top, 6).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tag.name).font(FontCatalog.text(12, relativeTo: .subheadline))
                                    .foregroundStyle(tag.id == .remainder ? FMDesign.secondaryText : Color(hex: 0xE8EEE9))
                                Text("\(ProfileTimeText.display(minutes: tag.minutes)) · \(Int((tag.share * 100).rounded()))%")
                                    .font(FontCatalog.text(10, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 13)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.09)).frame(height: 1) }
                        .padding(.top, 8)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(tag.name), \(tag.minutes)분 · \(tag.count)회 · \(Int((tag.share * 100).rounded()))%")
                        // 표시 전용 행: 직접 그린 라벨로 바꿔도 낭독 종류는 정적 글자로 유지(누를 수 있는 태그 버튼과 구분).
                        .accessibilityAddTraits(.isStaticText)
                        .accessibilityIdentifier(tag.id == .remainder ? "analytics.tag.remainder" : "analytics.composition.\(tag.name)")
                    }
                }
                .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 156)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if report.totals.count == 0 {
            // 시안 R24: 빈 상태 문구는 도넛 아래 13pt.
            Text(value.hasAnyEligibleRecords ? "이 기간에는 마친 여행이 없어요" : "첫 여행을 마치면 태그별 시간과 활동이 여기에 모여요.")
                .font(FontCatalog.text(13, relativeTo: .subheadline))
                .foregroundStyle(FMDesign.secondaryText).accessibilityIdentifier("analytics.empty")
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 28)
        }
        // 시안 R24: 기록이 하나도 없으면 비교·날짜별·인사이트 섹션을 숨긴다.
        if value.hasAnyEligibleRecords { details(value) }
    }

    @ViewBuilder private func details(_ value: RecordsAnalyticsContent) -> some View {
        let computation = value.computation
        let report = computation.report
        Text(comparisonText(report.comparison, kind: browser?.period.kind ?? .month))
            .font(FontCatalog.text(11, relativeTo: .footnote)).foregroundStyle(Color(hex: 0xC3CDC6))
            .padding(.top, 14)
        if !report.tags.isEmpty {
            // 태그로 활동 거르기(시안에는 없음). 거르기 기능을 지우지 않으려고 작게 남긴다.
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(report.tags, id: \.id) { tag in
                        Button { browser?.selectTag(tag.name, available: report.tags) } label: {
                            Text(tag.name).font(FontCatalog.text(11, relativeTo: .caption))
                                .padding(.horizontal, 12).frame(minHeight: 44)
                                .background(color(tag.color).opacity(computation.effectiveTag == tag.name ? 0.35 : 0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(computation.effectiveTag == tag.name ? .isSelected : [])
                        .accessibilityIdentifier("analytics.tag.\(tag.name)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.top, 12)
        }
        HStack {
            Text(computation.effectiveTag.map { "\($0) 여행 시간" } ?? "날짜별 여행 시간").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            Spacer()
            if computation.effectiveTag != nil {
                Button("전체 보기") { browser?.selectTag(nil, available: report.tags) }
                    .font(FontCatalog.text(11, relativeTo: .caption))
                    .accessibilityIdentifier("analytics.clearTag")
            }
        }
        .padding(.top, 20)
        dailyChart(computation.filteredDays).padding(.top, 12)
        VStack(alignment: .leading, spacing: 14) {
            divider
            Text("마친 시간대 · 표시 시간대 기준").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            if computation.insights.needsMoreTimeBandRecords { Text("기록이 더 필요해요").font(FontCatalog.text(11, relativeTo: .footnote)).foregroundStyle(FMDesign.secondaryText) }
            ForEach(computation.insights.timeBands, id: \.band) { band in
                metricRow(bandName(band.band), minutes: band.minutes, count: band.count)
            }
            divider
            Text("자주 탄 노선").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            ForEach(Array(computation.insights.routes.enumerated()), id: \.offset) { _, route in
                metricRow("\(route.bus) · \(route.from) → \(route.to)", minutes: route.minutes, count: route.count)
            }
            divider
            Text("여행 길이").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            ForEach(computation.insights.lengths, id: \.band) { length in
                metricRow(lengthName(length.band), minutes: length.minutes, count: length.count)
            }
            Text("최장 연속 \(computation.insights.longestStreak)일 · 전체 기간").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            divider
            Text("최근 여행").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            ForEach(value.recent.map(RecordsAnalyticsRow.init)) { row in recordButton(row.record, memo: false) }
            divider
            Text("메모 회고 · \(value.memoCount)회").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            ForEach(value.recentMemos.map(RecordsAnalyticsRow.init)) { row in recordButton(row.record, memo: true) }
        }
        .padding(.top, 24)
    }

    private var divider: some View { Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) }

    /// 시안 R23: 세 열(폭 105 / 91 / 나머지), 숫자 17 Bold, 라벨 10pt, 아래 24pt 뒤 흰 14% 구분선.
    private func summary(_ report: RecordsAnalyticsReport) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) { summaryStats(report) }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    let stats = [("완료한 여행", "\(report.totals.count)회", 105.0), ("여행한 날", "\(report.totals.activeDays)일", 91.0),
                                 ("평균 여행 시간", ProfileTimeText.display(minutes: report.totals.averageMinutes), 0)]
                    ForEach(stats, id: \.0) { stat in
                        self.stat(stat.0, stat.1)
                            .frame(width: stat.2 > 0 ? stat.2 : nil, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("전체 기간 \(report.totals.minutes)분 · \(report.totals.count)회 · \(report.totals.activeDays)일 · 평균 \(report.totals.averageMinutes)분")
        .accessibilityIdentifier("analytics.summary")
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) }
    }

    @ViewBuilder private func summaryStats(_ report: RecordsAnalyticsReport) -> some View {
        stat("완료한 여행", "\(report.totals.count)회")
        stat("여행한 날", "\(report.totals.activeDays)일")
        stat("평균 여행 시간", ProfileTimeText.display(minutes: report.totals.averageMinutes))
    }

    private func stat(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(FontCatalog.text(17, weight: .bold, relativeTo: .title3))
            Text(name).font(FontCatalog.text(10, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
        }
    }

    /// 시안 R23: 선 중심 지름 128, 두께 19, 바탕 고리 #27332B, 조각 사이 어두운 틈, 가운데 "16h 35m" 20 Bold + "합계" 11pt.
    private func donut(_ report: RecordsAnalyticsReport) -> some View {
        let gap = report.topTags.count > 1 ? 0.006 : 0
        return ZStack {
            Circle().stroke(Color(hex: 0x27332B), lineWidth: 19)
            ForEach(Array(report.topTags.enumerated()), id: \.offset) { index, tag in
                let start = report.topTags.prefix(index).reduce(0.0) { $0 + $1.share }
                let end = min(1, start + tag.share)
                Circle().trim(from: start + gap, to: max(start + gap, end - gap)).stroke(color(tag.color), lineWidth: 19).rotationEffect(.degrees(-90))
            }
            VStack(spacing: 3) {
                Text(ProfileTimeText.compact(minutes: report.totals.minutes)).font(FontCatalog.text(20, weight: .bold, relativeTo: .headline))
                    .minimumScaleFactor(0.6).lineLimit(1)
                Text("합계").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 128, height: 128).padding(9.5).padding(.leading, 6)
        .accessibilityHidden(true)
    }

    private func dailyChart(_ days: [AnalyticsDayTotal]) -> some View {
        let maximum = max(1, days.map(\.minutes).max() ?? 0)
        return ScrollView(.horizontal) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days, id: \.day) { day in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        VStack(spacing: 0) {
                            if day.minutes == 0 { Capsule().fill(.white.opacity(0.2)).frame(height: 2) }
                            ForEach(day.tags, id: \.id) { tag in
                                Rectangle().fill(color(tag.color)).frame(height: 90 * Double(tag.minutes) / Double(maximum))
                            }
                        }.frame(width: 22)
                        Text(String(day.day.suffix(2))).font(FontCatalog.text(10, relativeTo: .caption2))
                    }
                    .frame(width: 28, height: 120).opacity(day.isFuture ? 0.35 : 1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.day), \(day.minutes)분, \(day.count)회" + (day.isFuture ? ", 미래 날짜" : "") + day.tags.map { ", \($0.name) \($0.minutes)분" }.joined())
                }
            }
        }
    }

    private func metricRow(_ name: String, minutes: Int, count: Int) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) { Text(name); Spacer(minLength: 12); Text("\(minutes)분 · \(count)회").foregroundStyle(FMDesign.secondaryText) }
            VStack(alignment: .leading, spacing: 3) { Text(name); Text("\(minutes)분 · \(count)회").foregroundStyle(FMDesign.secondaryText) }
        }.font(FontCatalog.text(13, relativeTo: .subheadline)).accessibilityElement(children: .ignore).accessibilityLabel("\(name), \(minutes)분, \(count)회")
    }

    private func recordButton(_ record: RecordSnapshot, memo: Bool) -> some View {
        Button { onOpenRecord(record.id) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(memo ? record.memo : record.task).font(FontCatalog.text(13, relativeTo: .subheadline)).multilineTextAlignment(.leading)
                Text("\(record.tag) · \(record.minutes)분 · \(record.date)").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 13)
                .overlay(alignment: .bottom) { Rectangle().fill(FMDesign.primary.opacity(0.14)).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(memo ? record.memo : record.task), \(record.tag), \(record.minutes)분, 기록과 메모 열기")
        .accessibilityIdentifier("analytics.\(memo ? "memo" : "recent").\(record.id)")
    }

    private func periodTitle(_ period: AnalyticsPeriod) -> String {
        period.kind == .month ? String(period.startDay.prefix(7)).replacingOccurrences(of: "-", with: "년 ") + "월" : "\(period.startDay) – \(period.endDay)"
    }
    /// 시안 R23: "지난달 같은 기간보다 25 min 적게 여행했어요."
    private func comparisonText(_ value: AnalyticsComparison, kind: AnalyticsPeriodKind) -> String {
        guard value.changePercent != nil else { return "비교할 이전 기록이 아직 없어요" }
        let previous = kind == .month ? "지난달" : "지난주"
        return value.deltaMinutes == 0 ? "\(previous) 같은 기간과 같아요."
            : "\(previous) 같은 기간보다 \(ProfileTimeText.display(minutes: abs(value.deltaMinutes))) \(value.deltaMinutes > 0 ? "많이" : "적게") 여행했어요."
    }
    private func color(_ hex: String) -> Color {
        let value = UInt32(hex.dropFirst(), radix: 16) ?? 0xBFC6C1
        return Color(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
    private func bandName(_ band: AnalyticsTimeBand) -> String {
        switch band { case .dawn: "새벽 0–5시"; case .morning: "오전 5–12시"; case .afternoon: "오후 12–18시"; case .evening: "저녁 18–24시" }
    }
    private func lengthName(_ band: AnalyticsLengthBand) -> String {
        switch band { case .upTo30: "1–30분"; case .from31To60: "31–60분"; case .from61To120: "61–120분"; case .from121To240: "121–240분"; case .from241To360: "241–360분" }
    }
}


/// 분석 목록에서 원본 기록과 행 식별자를 연결한다.
struct RecordsAnalyticsRow: Identifiable {
    let record: RecordSnapshot
    var id: [UInt16] { Array(record.id.utf16) }
}
