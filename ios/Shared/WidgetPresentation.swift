import Foundation

struct WidgetDisplayContent: Equatable {
    let title: String
    let subtitle: String
    let actionTitle: String
    let basisText: String
    let axSummary: String
    let snapshot: WidgetSnapshot?
    let isStale: Bool
    let progress: Double?
}
enum WidgetPresentation {
    static func content(state: WidgetReadState) -> WidgetDisplayContent {
        let snapshot: WidgetSnapshot
        let stale: Bool
        switch state {
        case .valid(let value), .validEmpty(let value): snapshot = value; stale = false
        case .stale(let value): snapshot = value; stale = true
        case .unavailable, .malformed, .unsupportedVersion:
            return WidgetDisplayContent(title: "정보를 불러올 수 없어요", subtitle: "", actionTitle: "앱 열기", basisText: "",
                                        axSummary: "정보를 불러올 수 없어요", snapshot: nil, isStale: false, progress: nil)
        }
        let title: String, action: String
        switch snapshot.journey.phase {
        case .setup: title = "설정을 마쳐주세요"; action = "설정 확인"
        case .ready: title = "집중할 시간을 골라보세요"; action = "앱에서 준비"
        case .awaitingDeparture: title = "출발을 기다리고 있어요"; action = "출발 안내"
        case .running: title = "진행 중인 여정이 있어요"; action = "여정 확인"
        case .paused: title = "잠시 쉬고 있어요"; action = "여정 확인"
        case .arrived: title = "목적지에 도착했어요"; action = "하차 안내"
        }
        let subtitle = [snapshot.journey.busNumber, snapshot.journey.destination].compactMap { $0 }.joined(separator: " · ")
        let basis = "기준일 \(snapshot.basisDay) · " + (stale ? "업데이트 필요" : "저장된 정보")
        let progress: Double?
        if let total = snapshot.journey.totalSeconds, total > 0, let elapsed = snapshot.journey.elapsedSeconds {
            progress = min(1, max(0, Double(elapsed) / Double(total)))
        } else { progress = nil }
        let analytics = snapshot.analytics
        let summary = [title, subtitle, progress.map { "저장된 진행 \(Int(($0 * 100).rounded()))%" } ?? "", basis,
                       "\(stale ? "기준일" : "오늘") \(analytics.today.minutes)분 \(analytics.today.count)회",
                       "\(stale ? "해당 주" : "이번 주") \(analytics.weekMinutes)분 \(analytics.weekCount)회"].filter { !$0.isEmpty }.joined(separator: ", ")
        return WidgetDisplayContent(title: title, subtitle: subtitle, actionTitle: action, basisText: basis,
                                    axSummary: summary, snapshot: snapshot, isStale: stale, progress: progress)
    }
    static func nextRefreshDate(state: WidgetReadState, now: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(900)
        let candidate: Date
        switch state {
        case .valid(let snapshot), .validEmpty(let snapshot):
            let expiry = snapshot.generatedAt.addingTimeInterval(1800)
            candidate = expiry > now ? expiry : now.addingTimeInterval(900)
        default: candidate = now.addingTimeInterval(900)
        }
        let next = min(candidate, midnight)
        return next > now ? next : now.addingTimeInterval(900)
    }
}
