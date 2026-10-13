import Foundation

struct StationSnapshot: Codable, Equatable {
    let id: String
    let name: String
    let direction: Int
}

enum LaunchRoute: Equatable { case cardEntry, initialStationEntry, main }
enum SnapshotValidationIssue: Error, Equatable {
    case inconsistentStage, emptyStationID, emptyStationName, invalidDirection(Int)
    case multipleCards(Int), cardWithoutIssuance, invalidCardID
}

struct AppSnapshot: Codable, Equatable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    let cards: CardSection
    let journey: JourneySection
    let records: RecordSection
    static let empty = AppSnapshot(cardIssued: false, initialStation: nil, currentStation: nil,
                                   cards: .empty, journey: .empty, records: .empty)

    /// 전체 생성자는 막아 두고, 바꾸려는 부분만 고르는 `updating…`으로 다른 영역을 실수로 비우지 않게 한다.
    private init(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?,
                 cards: CardSection, journey: JourneySection, records: RecordSection) {
        self.cardIssued = cardIssued
        self.initialStation = initialStation
        self.currentStation = currentStation
        self.cards = cards
        self.journey = journey
        self.records = records
    }

    func updatingStage(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?) -> AppSnapshot {
        AppSnapshot(cardIssued: cardIssued, initialStation: initialStation, currentStation: currentStation,
                    cards: cards, journey: journey, records: records)
    }
    func updating(cards: CardSection) -> AppSnapshot {
        AppSnapshot(cardIssued: cardIssued, initialStation: initialStation, currentStation: currentStation,
                    cards: cards, journey: journey, records: records)
    }
    func updating(journey: JourneySection) -> AppSnapshot {
        AppSnapshot(cardIssued: cardIssued, initialStation: initialStation, currentStation: currentStation,
                    cards: cards, journey: journey, records: records)
    }
    func updating(records: RecordSection) -> AppSnapshot {
        AppSnapshot(cardIssued: cardIssued, initialStation: initialStation, currentStation: currentStation,
                    cards: cards, journey: journey, records: records)
    }

    var currentCard: CardSnapshot? { cards.items.first }
    /// 발급은 됐지만 카드 원소가 없는 기존 사용자(버전 1, W00 버전 2). 유효한 상태이며 시작 단계에서 보충한다.
    var needsCardSupplement: Bool { cardIssued && cards.items.isEmpty }
    func issuingCard(_ card: CardSnapshot) -> AppSnapshot {
        updatingStage(cardIssued: true, initialStation: initialStation, currentStation: currentStation)
            .updating(cards: CardSection(items: [card]))
    }

    func validate() throws {
        let noStations = initialStation == nil && currentStation == nil
        let bothStations = initialStation != nil && currentStation != nil
        guard noStations || (cardIssued && bothStations) else { throw SnapshotValidationIssue.inconsistentStage }
        for station in [initialStation, currentStation].compactMap({ $0 }) {
            guard !station.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SnapshotValidationIssue.emptyStationID }
            guard !station.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SnapshotValidationIssue.emptyStationName }
            guard station.direction == 1 || station.direction == -1 else { throw SnapshotValidationIssue.invalidDirection(station.direction) }
        }
        guard cards.items.count <= 1 else { throw SnapshotValidationIssue.multipleCards(cards.items.count) }
        guard cards.items.isEmpty || cardIssued else { throw SnapshotValidationIssue.cardWithoutIssuance }
        guard cards.items.allSatisfy({ CardSnapshot.isValidID($0.id) }) else { throw SnapshotValidationIssue.invalidCardID }
    }

    func launchRoute() throws -> LaunchRoute {
        try validate()
        if !cardIssued { return .cardEntry }
        return currentStation == nil ? .initialStationEntry : .main
    }

    private enum CodingKeys: String, CodingKey { case cardIssued, initialStation, currentStation, cards, journey, records }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(cardIssued, forKey: .cardIssued)
        if let initialStation { try c.encode(initialStation, forKey: .initialStation) }
        else { try c.encodeNil(forKey: .initialStation) }
        if let currentStation { try c.encode(currentStation, forKey: .currentStation) }
        else { try c.encodeNil(forKey: .currentStation) }
        try c.encode(cards, forKey: .cards)
        try c.encode(journey, forKey: .journey)
        try c.encode(records, forKey: .records)
    }
}
