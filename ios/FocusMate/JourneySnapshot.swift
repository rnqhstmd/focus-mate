import Foundation

/// 승차 인식 순간 저장하는 진행 여정. 사용자가 고른 입력만 담고, 정류장 이름·정류장 수·거리처럼 다시 계산할 수 있는 값은 저장하지 않는다.
/// 정류장·버스 id는 W04 시점 `RouteStops`/`BusLine` 카탈로그 기준 값이다. 카탈로그가 바뀌어도 저장은 유효하며, 표시 조회는 실패하면 nil이다.
struct JourneySnapshot: Equatable {
    enum Phase: String, Codable { case awaitingDeparture, departed }

    /// 준비 초안의 태그는 메모리에만 있으므로 정의 전체를 복사해 둔다.
    struct Tag: Codable, Equatable {
        let id: String
        let name: String
        let icon: PreparationTagIcon
        let color: PreparationTagColor
    }

    struct Progress: Codable, Equatable {
        let elapsedSeconds: Int
        static let start = Progress(elapsedSeconds: 0)
    }

    let id: String
    let cardID: String
    let originStopID: String
    let direction: Int
    let minutes: Int
    let busID: String
    let destinationStopID: String
    let tag: Tag
    let task: String
    let sound: JourneySound
    let boardedAt: Date
    let phase: Phase
    let progress: Progress

    static func boarding(details: PreparedJourneyDetails, cardID: String, id: String, boardedAt: Date) -> JourneySnapshot {
        let origin = details.journey.origin
        let destination = RouteStops.all[RouteStops.wrap(origin.index + origin.direction * details.journey.stops)]
        return JourneySnapshot(
            id: id, cardID: cardID, originStopID: RouteStops.all[RouteStops.wrap(origin.index)].id,
            direction: origin.direction, minutes: details.journey.minutes, busID: details.journey.busID,
            destinationStopID: destination.id,
            tag: Tag(id: details.tag.id, name: details.tag.name, icon: details.tag.icon, color: details.tag.color),
            task: details.task, sound: details.sound, boardedAt: boardedAt,
            phase: .awaitingDeparture, progress: .start
        )
    }

    func confirmingDeparture() -> JourneySnapshot {
        JourneySnapshot(id: id, cardID: cardID, originStopID: originStopID, direction: direction, minutes: minutes,
                        busID: busID, destinationStopID: destinationStopID, tag: tag, task: task, sound: sound,
                        boardedAt: boardedAt, phase: .departed, progress: progress)
    }

    var originName: String? { RouteStops.all.first { $0.id == originStopID }?.name }
    var destinationName: String? { RouteStops.all.first { $0.id == destinationStopID }?.name }
    var bus: BusLine? { BusLine.all.first { $0.id == busID } }

    /// 구조만 본다. 카탈로그 대조를 넣으면 노선 데이터가 바뀔 때 임시 데이터 때문에 저장 파일 전체가 막힌다.
    func validate(currentCardID: String?) throws {
        let required = [("id", id), ("cardID", cardID), ("originStopID", originStopID), ("busID", busID),
                        ("destinationStopID", destinationStopID), ("tag.id", tag.id)]
        if let empty = required.first(where: { $0.1.isEmpty }) { throw ActiveJourneyValidationIssue.emptyField(empty.0) }
        guard cardID == currentCardID else { throw ActiveJourneyValidationIssue.cardMismatch }
        guard direction == 1 || direction == -1 else { throw ActiveJourneyValidationIssue.invalidDirection(direction) }
        guard minutes > 0 else { throw ActiveJourneyValidationIssue.invalidMinutes(minutes) }
        // 준비 초안과 같은 규칙: 할 일은 다듬어진 값 그대로·UTF-16 80 이하, 태그 이름은 20 이하.
        guard task == task.trimmingCharacters(in: .whitespacesAndNewlines), !task.isEmpty, task.utf16.count <= 80
        else { throw ActiveJourneyValidationIssue.invalidTask }
        let tagName = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tagName.isEmpty, tag.name.utf16.count <= 20 else { throw ActiveJourneyValidationIssue.invalidTag }
        guard progress.elapsedSeconds >= 0, phase == .departed || progress.elapsedSeconds == 0
        else { throw ActiveJourneyValidationIssue.invalidProgress }
    }
}

enum ActiveJourneyValidationIssue: Error, Equatable {
    case emptyField(String), cardMismatch, invalidDirection(Int), invalidMinutes(Int)
    case invalidTask, invalidTag, invalidProgress
}

extension JourneySnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, cardID, originStopID, direction, minutes, busID, destinationStopID, tag, task, sound, boardedAt, phase, progress
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let text = try c.decode(String.self, forKey: .boardedAt)
        guard let date = try? Date(text, strategy: .iso8601) else {
            throw DecodingError.dataCorruptedError(forKey: .boardedAt, in: c, debugDescription: "boardedAt is not ISO 8601")
        }
        self.init(id: try c.decode(String.self, forKey: .id), cardID: try c.decode(String.self, forKey: .cardID),
                  originStopID: try c.decode(String.self, forKey: .originStopID),
                  direction: try c.decode(Int.self, forKey: .direction), minutes: try c.decode(Int.self, forKey: .minutes),
                  busID: try c.decode(String.self, forKey: .busID),
                  destinationStopID: try c.decode(String.self, forKey: .destinationStopID),
                  tag: try c.decode(Tag.self, forKey: .tag), task: try c.decode(String.self, forKey: .task),
                  sound: try c.decode(JourneySound.self, forKey: .sound), boardedAt: date,
                  phase: try c.decode(Phase.self, forKey: .phase), progress: try c.decode(Progress.self, forKey: .progress))
    }
    /// 날짜를 직접 문자열로 써서 인코더의 날짜 전략과 무관하게 같은 바이트를 낸다(CardSnapshot과 같은 이유).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(cardID, forKey: .cardID)
        try c.encode(originStopID, forKey: .originStopID)
        try c.encode(direction, forKey: .direction)
        try c.encode(minutes, forKey: .minutes)
        try c.encode(busID, forKey: .busID)
        try c.encode(destinationStopID, forKey: .destinationStopID)
        try c.encode(tag, forKey: .tag)
        try c.encode(task, forKey: .task)
        try c.encode(sound, forKey: .sound)
        try c.encode(boardedAt.formatted(.iso8601), forKey: .boardedAt)
        try c.encode(phase, forKey: .phase)
        try c.encode(progress, forKey: .progress)
    }
}

/// 승차 저장값 생성기. ID·시계를 주입해 테스트에서 결정적으로 만든다.
struct ActiveJourneyFactory {
    private let makeID: () -> String
    private let now: () -> Date

    init(makeID: @escaping () -> String = { UUID().uuidString }, now: @escaping () -> Date = Date.init) {
        self.makeID = makeID
        self.now = now
    }

    func make(details: PreparedJourneyDetails, cardID: String) -> JourneySnapshot {
        // 저장 형식이 초 단위라 내려 두어야 저장·로드 왕복 값이 같다.
        let boardedAt = Date(timeIntervalSince1970: now().timeIntervalSince1970.rounded(.down))
        return .boarding(details: details, cardID: cardID, id: makeID(), boardedAt: boardedAt)
    }
}
