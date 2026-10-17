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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("여행 분석").font(FontCatalog.text(23, weight: .bold, relativeTo: .title2)).accessibilityAddTraits(.isHeader).accessibilityIdentifier("screen.analytics")
                if let browser {
                    toolbar(browser)
                    Text(periodTitle(browser.period)).font(FontCatalog.text(18, weight: .bold, relativeTo: .title3)).accessibilityIdentifier("analytics.range")
                }
                switch content {
                case .unavailable:
                    Text("기록을 불러올 수 없어요").accessibilityIdentifier("analytics.unavailable")
                    Button("기록으로 돌아가기") { dismiss() }.buttonStyle(FMPrimaryButtonStyle(size: .compact))
                case .available(let value):
                    analysis(value)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fmPanel()
            .padding(.horizontal, 12).padding(.vertical, 20)
        }
        .background(FMDesign.background.ignoresSafeArea())
        .foregroundStyle(FMDesign.primary).tint(FMDesign.primary)
        .font(FontCatalog.text(15))
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
        .onAppear { refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
    }

    private func refresh() {
        observedAt = model.recordClock.now()
        if case .available(let value) = content { browser?.reconcileTags(available: value.computation.report.tags) }
    }

    private func editBrowser(_ action: (inout RecordsAnalyticsBrowser) throws -> Void) {
        guard var next = browser else { return }
        do { try action(&next); browser = next } catch { browser = nil }
    }

    private func toolbar(_ state: RecordsAnalyticsBrowser) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                periodButton("주간", kind: .week, state: state)
                periodButton("월간", kind: .month, state: state)
                Spacer(minLength: 0)
            }
            HStack {
                Button { editBrowser { _ = try $0.move(by: -1, today: today, calendar: calendar) } } label: {
                    Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel("이전 기간").accessibilityIdentifier("analytics.previous")
                Spacer()
                Button(state.period.kind == .week ? "이번 주" : "이번 달") {
                    observedAt = model.recordClock.now()
                    editBrowser { try $0.returnToToday(today: today, calendar: calendar) }
                }.frame(minHeight: 44).accessibilityIdentifier("analytics.today")
                Spacer()
                Button { editBrowser { _ = try $0.move(by: 1, today: today, calendar: calendar) } } label: {
                    Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
                }
                .disabled((try? RecordsAnalytics.shift(period: state.period, by: 1, today: today, calendar: calendar)) == nil)
                .accessibilityLabel("다음 기간").accessibilityIdentifier("analytics.next")
            }.buttonStyle(.plain)
        }
    }

    private func periodButton(_ title: String, kind: AnalyticsPeriodKind, state: RecordsAnalyticsBrowser) -> some View {
        Button { editBrowser { try $0.setKind(kind, calendar: calendar) } } label: {
            Text(title)
                .font(FontCatalog.text(13, weight: state.period.kind == kind ? .bold : .regular, relativeTo: .subheadline))
                .padding(.horizontal, 15).frame(minHeight: 44)
                .foregroundStyle(state.period.kind == kind ? FMDesign.primary : FMDesign.secondaryText)
                .background(state.period.kind == kind ? FMDesign.primary.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
            .buttonStyle(.plain)
            .accessibilityAddTraits(state.period.kind == kind ? .isSelected : [])
            .accessibilityIdentifier("analytics.period.\(kind.rawValue)")
    }

    @ViewBuilder private func analysis(_ value: RecordsAnalyticsContent) -> some View {
        let computation = value.computation
        let report = computation.report
        summary(report)
        if report.totals.count == 0 {
            Text(value.hasAnyEligibleRecords ? "이 기간에는 마친 여행이 없어요" : "첫 여행을 마치면 집중 기록을 분석해드려요")
                .foregroundStyle(FMDesign.secondaryText).accessibilityIdentifier("analytics.empty")
        }
        Text("태그별 여행 시간 · 전체 기간").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        if !report.tags.isEmpty {
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(alignment: .center, spacing: 18))
            layout {
                donut(report)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(report.topTags, id: \.id) { tag in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(color(tag.color)).frame(width: 6, height: 6).padding(.top, 6).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tag.name).font(FontCatalog.text(13, relativeTo: .subheadline))
                                Text("\(tag.minutes)분 · \(tag.count)회 · \(Int((tag.share * 100).rounded()))%")
                                    .font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
                            }
                        }
                        .foregroundStyle(tag.id == .remainder ? FMDesign.secondaryText : FMDesign.primary)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier(tag.id == .remainder ? "analytics.tag.remainder" : "analytics.composition.\(tag.name)")
                    }
                }

            }
        }
        if !report.tags.isEmpty {
            Text("태그로 활동 보기").font(FontCatalog.text(13, relativeTo: .subheadline)).foregroundStyle(FMDesign.secondaryText)
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(report.tags, id: \.id) { tag in
                        Button { browser?.selectTag(tag.name, available: report.tags) } label: {
                            Text(tag.name).padding(.horizontal, 14).frame(minHeight: 44)
                                .background(color(tag.color).opacity(computation.effectiveTag == tag.name ? 0.35 : 0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(computation.effectiveTag == tag.name ? .isSelected : [])
                        .accessibilityIdentifier("analytics.tag.\(tag.name)")
                    }
                }
            }
        }
        Text(comparisonText(report.comparison)).font(FontCatalog.text(11, relativeTo: .footnote)).foregroundStyle(FMDesign.secondaryText)
        HStack {
            Text(computation.effectiveTag.map { "\($0) 활동" } ?? "전체 활동").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
            Spacer()
            if computation.effectiveTag != nil {
                Button("전체 보기") { browser?.selectTag(nil, available: report.tags) }
                    .accessibilityIdentifier("analytics.clearTag")
            }
        }
        dailyChart(computation.filteredDays)
        Divider()
        Text("마친 시간대 · 표시 시간대 기준").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        if computation.insights.needsMoreTimeBandRecords { Text("기록이 더 필요해요").font(FontCatalog.text(11, relativeTo: .footnote)).foregroundStyle(FMDesign.secondaryText) }
        ForEach(computation.insights.timeBands, id: \.band) { band in
            metricRow(bandName(band.band), minutes: band.minutes, count: band.count)
        }
        Divider()
        Text("자주 탄 노선").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        ForEach(Array(computation.insights.routes.enumerated()), id: \.offset) { _, route in
            metricRow("\(route.bus) · \(route.from) → \(route.to)", minutes: route.minutes, count: route.count)
        }
        Divider()
        Text("여행 길이").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        ForEach(computation.insights.lengths, id: \.band) { length in
            metricRow(lengthName(length.band), minutes: length.minutes, count: length.count)
        }
        Text("최장 연속 \(computation.insights.longestStreak)일 · 전체 기간").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        Divider()
        Text("최근 여행").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        ForEach(value.recent.map(RecordsAnalyticsRow.init)) { row in recordButton(row.record, memo: false) }
        Divider()
        Text("메모 회고 · \(value.memoCount)회").font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
        ForEach(value.recentMemos.map(RecordsAnalyticsRow.init)) { row in recordButton(row.record, memo: true) }
    }

    private func summary(_ report: RecordsAnalyticsReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 220 : 90), alignment: .leading)], alignment: .leading, spacing: 16) {
                stat("완료한 여행", "\(report.totals.count)회")
                stat("여행한 날", "\(report.totals.activeDays)일")
                stat("평균 여행 시간", "\(report.totals.averageMinutes)분")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("전체 기간 \(report.totals.minutes)분 · \(report.totals.count)회 · \(report.totals.activeDays)일 · 평균 \(report.totals.averageMinutes)분")
        .accessibilityIdentifier("analytics.summary")
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rectangle().fill(FMDesign.primary.opacity(0.14)).frame(height: 1) }
    }

    private func stat(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) { Text(value).font(FontCatalog.text(17, weight: .bold, relativeTo: .title3)); Text(name).font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText) }
    }

    private func donut(_ report: RecordsAnalyticsReport) -> some View {
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 17)
            ForEach(Array(report.topTags.enumerated()), id: \.offset) { index, tag in
                let start = report.topTags.prefix(index).reduce(0.0) { $0 + $1.share }
                Circle().trim(from: start, to: min(1, start + tag.share)).stroke(color(tag.color), lineWidth: 17).rotationEffect(.degrees(-90))
            }
            VStack(spacing: 3) {
                Text(ProfileTimeText.display(minutes: report.totals.minutes)).font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
                Text("합계").font(FontCatalog.text(11, relativeTo: .caption)).foregroundStyle(FMDesign.secondaryText)
            }
        }.frame(width: 140, height: 140).padding(9).accessibilityHidden(true)
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
    private func comparisonText(_ value: AnalyticsComparison) -> String {
        guard value.changePercent != nil else { return "비교할 이전 기록이 아직 없어요" }
        return value.deltaMinutes == 0 ? "이전 같은 기간과 같아요" : "이전 같은 기간보다 \(abs(value.deltaMinutes))분 \(value.deltaMinutes > 0 ? "더" : "덜") 집중했어요"
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
