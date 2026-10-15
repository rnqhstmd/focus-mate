import Foundation

/// 승차 인식 순간 저장하는 진행 여정. 사용자가 고른 입력과 승차 당시의 표시 이름(출발·도착 정류장, 버스 번호·유형)을 담는다.
/// 이름을 함께 저장하므로 정류장 데이터가 바뀌어도 기록·안내 문구는 승차 당시 값 그대로다. 정류장 수·거리처럼 다시 계산할 값은 저장하지 않는다.
struct JourneySnapshot: Equatable {
    enum Phase: String, Codable { case awaitingDeparture, departed }
    static let maximumMinutes = 360
    /// 기록 from/to/bus의 상한과 같다. 하차 기록 저장이 이름 길이 때문에 막히지 않게 승차 때 보장한다.
    static let maximumNameLength = 500

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
    let originName: String
    let minutes: Int
    let busID: String
    let busNumber: String
    let busKind: String
    let destinationStopID: String
    let destinationName: String
    let tag: Tag
    let task: String
    let sound: JourneySound
    let boardedAt: Date
    let phase: Phase
    let progress: Progress
    /// 출발 뒤 일시정지 여부. 출발 대기에서는 항상 false다.
    let paused: Bool

    static func boarding(details: PreparedJourneyDetails, cardID: String, id: String, boardedAt: Date) -> JourneySnapshot {
        let journey = details.journey
        return JourneySnapshot(
            id: id, cardID: cardID, originStopID: journey.originStopID, originName: journey.originName,
            minutes: journey.minutes, busID: journey.busID, busNumber: journey.busNumber, busKind: journey.busKind,
            destinationStopID: journey.destinationStopID, destinationName: journey.destination,
            tag: Tag(id: details.tag.id, name: details.tag.name, icon: details.tag.icon, color: details.tag.color),
            task: details.task, sound: details.sound, boardedAt: boardedAt,
            phase: .awaitingDeparture, progress: .start, paused: false
        )
    }

    func confirmingDeparture() -> JourneySnapshot { with(phase: .departed, progress: progress, paused: false) }

    var totalSeconds: Int { minutes * 60 }
    var isArrived: Bool { phase == .departed && progress.elapsedSeconds == totalSeconds }

    func updatingProgress(elapsedSeconds: Int, paused: Bool) -> JourneySnapshot {
        with(phase: phase, progress: Progress(elapsedSeconds: elapsedSeconds), paused: paused)
    }

    /// 앱 종료는 여정이 끊긴 것으로 본다. 진행 중이던 여정은 실행 시 일시정지로 읽는다.
    func restingForLaunch() -> JourneySnapshot {
        phase == .departed && !paused ? with(phase: phase, progress: progress, paused: true) : self
    }

    private func with(phase: Phase, progress: Progress, paused: Bool) -> JourneySnapshot {
        JourneySnapshot(id: id, cardID: cardID, originStopID: originStopID, originName: originName, minutes: minutes,
                        busID: busID, busNumber: busNumber, busKind: busKind, destinationStopID: destinationStopID,
                        destinationName: destinationName, tag: tag, task: task, sound: sound,
                        boardedAt: boardedAt, phase: phase, progress: progress, paused: paused)
    }

    /// 구조만 본다(카탈로그 검사 없음). 손상 여정은 `SnapshotCodec.dropInvalidActiveJourney`가 여정만 버린다.
    func validate(currentCardID: String?) throws {
        let required = [("id", id), ("cardID", cardID), ("originStopID", originStopID), ("originName", originName),
                        ("busID", busID), ("busNumber", busNumber), ("busKind", busKind),
                        ("destinationStopID", destinationStopID), ("destinationName", destinationName), ("tag.id", tag.id)]
        if let empty = required.first(where: { $0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            throw ActiveJourneyValidationIssue.emptyField(empty.0)
        }
        let names = [("originName", originName), ("destinationName", destinationName),
                     ("busNumber", busNumber), ("busKind", busKind)]
        if let long = names.first(where: { $0.1.utf16.count > Self.maximumNameLength }) {
            throw ActiveJourneyValidationIssue.nameTooLong(long.0)
        }
        guard cardID == currentCardID else { throw ActiveJourneyValidationIssue.cardMismatch }
        guard (1...Self.maximumMinutes).contains(minutes) else { throw ActiveJourneyValidationIssue.invalidMinutes(minutes) }
        // 준비 초안과 같은 규칙: 할 일은 다듬어진 값 그대로·UTF-16 80 이하, 태그 이름은 20 이하.
        guard task == task.trimmingCharacters(in: .whitespacesAndNewlines), !task.isEmpty, task.utf16.count <= 80
        else { throw ActiveJourneyValidationIssue.invalidTask }
        let tagName = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tagName.isEmpty, tag.name.utf16.count <= 20 else { throw ActiveJourneyValidationIssue.invalidTag }
        guard (0...totalSeconds).contains(progress.elapsedSeconds), phase == .departed || progress.elapsedSeconds == 0
        else { throw ActiveJourneyValidationIssue.invalidProgress }
        guard phase == .departed || !paused else { throw ActiveJourneyValidationIssue.invalidPausedState }
    }
}

enum ActiveJourneyValidationIssue: Error, Equatable {
    case emptyField(String), cardMismatch, invalidMinutes(Int)
    case invalidTask, invalidTag, invalidProgress, invalidPausedState
    case nameTooLong(String)
}

extension JourneySnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, cardID, originStopID, originName, minutes, busID, busNumber, busKind, destinationStopID, destinationName
        case tag, task, sound, boardedAt, phase, progress, paused
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let text = try c.decode(String.self, forKey: .boardedAt)
        guard let date = try? Date(text, strategy: .iso8601) else {
            throw DecodingError.dataCorruptedError(forKey: .boardedAt, in: c, debugDescription: "boardedAt is not ISO 8601")
        }
        self.init(id: try c.decode(String.self, forKey: .id), cardID: try c.decode(String.self, forKey: .cardID),
                  originStopID: try c.decode(String.self, forKey: .originStopID),
                  originName: try c.decode(String.self, forKey: .originName),
                  minutes: try c.decode(Int.self, forKey: .minutes),
                  busID: try c.decode(String.self, forKey: .busID),
                  busNumber: try c.decode(String.self, forKey: .busNumber),
                  busKind: try c.decode(String.self, forKey: .busKind),
                  destinationStopID: try c.decode(String.self, forKey: .destinationStopID),
                  destinationName: try c.decode(String.self, forKey: .destinationName),
                  tag: try c.decode(Tag.self, forKey: .tag), task: try c.decode(String.self, forKey: .task),
                  sound: try c.decode(JourneySound.self, forKey: .sound), boardedAt: date,
                  phase: try c.decode(Phase.self, forKey: .phase), progress: try c.decode(Progress.self, forKey: .progress),
                  paused: try c.decode(Bool.self, forKey: .paused))
    }
    /// 날짜를 직접 문자열로 써서 인코더의 날짜 전략과 무관하게 같은 바이트를 낸다(CardSnapshot과 같은 이유).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(cardID, forKey: .cardID)
        try c.encode(originStopID, forKey: .originStopID)
        try c.encode(originName, forKey: .originName)
        try c.encode(minutes, forKey: .minutes)
        try c.encode(busID, forKey: .busID)
        try c.encode(busNumber, forKey: .busNumber)
        try c.encode(busKind, forKey: .busKind)
        try c.encode(destinationStopID, forKey: .destinationStopID)
        try c.encode(destinationName, forKey: .destinationName)
        try c.encode(tag, forKey: .tag)
        try c.encode(task, forKey: .task)
        try c.encode(sound, forKey: .sound)
        try c.encode(boardedAt.formatted(.iso8601), forKey: .boardedAt)
        try c.encode(phase, forKey: .phase)
        try c.encode(progress, forKey: .progress)
        try c.encode(paused, forKey: .paused)
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
