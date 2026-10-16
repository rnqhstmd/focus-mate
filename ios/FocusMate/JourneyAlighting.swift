import Foundation

/// 하차 저장을 만들 수 없는 이유. 화면은 실패 안내만 하고 저장본을 바꾸지 않는다.
enum AlightingIssue: Error, Equatable { case noActiveJourney, notArrived }

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
    /// 하차한 여정의 완료 기록 입력. 버스·정류장 이름은 승차 때 저장한 값이다.
    init(alighting journey: JourneySnapshot, completedAt: Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.init(id: journey.id, completedAt: formatter.string(from: completedAt), bus: journey.busNumber,
                  tag: journey.tag.name, tagColor: journey.tag.color.recordHex, task: journey.task,
                  minutes: journey.minutes, sound: journey.sound.title, from: journey.originName, to: journey.destinationName)
    }
}

extension AppSnapshot {
    /// 기록 생성·도착지 반영·진행 여정 제거를 한 후보로 만든다(BR-3). 이미 기록된 여정이면 기록은 그대로다(BR-2).
    func alightingActiveJourney(completedAt: Date, timeZone: TimeZone) throws -> (snapshot: AppSnapshot, record: RecordCompletionInput) {
        guard let active = journey.active else { throw AlightingIssue.noActiveJourney }
        guard let station = active.arrivedStation else { throw AlightingIssue.notArrived }
        let record = RecordCompletionInput(alighting: active, completedAt: completedAt)
        let records = try self.records.recordingCompletion(record, outcome: .alighted, timeZone: timeZone)
        return (endingActiveJourney(at: station).updating(records: records), record)
    }
}
