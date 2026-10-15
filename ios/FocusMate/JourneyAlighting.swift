import Foundation

/// 하차 저장을 만들 수 없는 이유. 화면은 실패 안내만 하고 저장본을 바꾸지 않는다.
enum AlightingIssue: Error, Equatable { case noActiveJourney, notArrived, unknownCatalog }

/// 하차 시각과 로컬 날짜의 출처(BR-5). 테스트는 고정 시각·시간대를 주입한다.
struct RecordClock {
    var now: () -> Date
    var timeZone: () -> TimeZone
    static let live = RecordClock(now: { Date() }, timeZone: { TimeZone.current })
}

extension PreparationTagColor {
    /// 웹 프로토타입 tagOptions의 기록 색상.
    var recordHex: String {
        switch self {
        case .sand: "#d7b378"
        case .blue: "#82aaf2"
        case .purple: "#b49ce1"
        case .green: "#91b9ab"
        case .pink: "#d596a6"
        }
    }
}

extension RecordCompletionInput {
    /// 하차한 여정의 완료 기록 입력. 카탈로그 밖 여정이면 nil이다.
    init?(alighting journey: JourneySnapshot, completedAt: Date) {
        guard let bus = journey.bus, let from = journey.originName, let to = journey.destinationName else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.init(id: journey.id, completedAt: formatter.string(from: completedAt), bus: bus.number,
                  tag: journey.tag.name, tagColor: journey.tag.color.recordHex, task: journey.task,
                  minutes: journey.minutes, sound: journey.sound.title, from: from, to: to)
    }
}

extension AppSnapshot {
    /// 기록 생성·도착지 반영·진행 여정 제거를 한 후보로 만든다(BR-3). 이미 기록된 여정이면 기록은 그대로다(BR-2).
    func alightingActiveJourney(completedAt: Date, timeZone: TimeZone) throws -> (snapshot: AppSnapshot, record: RecordCompletionInput) {
        guard let active = journey.active else { throw AlightingIssue.noActiveJourney }
        guard active.isArrived else { throw AlightingIssue.notArrived }
        guard let station = active.reachedStation,
              let record = RecordCompletionInput(alighting: active, completedAt: completedAt) else {
            throw AlightingIssue.unknownCatalog
        }
        let records = try self.records.recordingCompletion(record, outcome: .alighted, timeZone: timeZone)
        return (endingActiveJourney(at: station).updating(records: records), record)
    }
}
