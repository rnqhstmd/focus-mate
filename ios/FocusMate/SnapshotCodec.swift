import Foundation

/// 버전 1 저장 계약. 이후 `AppSnapshot`이 바뀌어도 고치지 않는다.
struct LegacySnapshotV1: Decodable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
}

/// v2 카드에서는 이후 추가된 style 키를 해석하지 않는다.
struct LegacyCardV2DTO: Decodable {
    let id: String
    let issuedAt: Date
    private enum CodingKeys: String, CodingKey { case id, issuedAt }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        let text = try c.decode(String.self, forKey: .issuedAt)
        guard let date = try? Date(text, strategy: .iso8601) else {
            throw DecodingError.dataCorruptedError(forKey: .issuedAt, in: c, debugDescription: "issuedAt is not ISO 8601")
        }
        issuedAt = date
    }
}

/// v2 시절 진행 여정은 정의되지 않아 null만 있을 수 있다. 객체가 들어 있으면 손상으로 본다.
struct LegacyJourneySectionV2: Decodable {
    private enum CodingKeys: String, CodingKey { case active }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard c.contains(.active), try c.decodeNil(forKey: .active) else {
            throw DecodingError.dataCorrupted(.init(codingPath: c.codingPath, debugDescription: "v2 journey.active must be null"))
        }
    }
}

struct LegacySnapshotV2: Decodable {
    struct Cards: Decodable { let items: [LegacyCardV2DTO] }
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    let cards: Cards
    let journey: LegacyJourneySectionV2
    let records: RecordSection
}

/// v3·v4 진행 여정은 예시 노선 기준이라 내용을 해석하지 않는다. 있었는지만 본다.
struct LegacyJourneyPresence: Decodable {
    let isPresent: Bool
    private enum CodingKeys: String, CodingKey { case active }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard c.contains(.active) else {
            throw DecodingError.keyNotFound(CodingKeys.active, .init(codingPath: c.codingPath, debugDescription: "journey.active is required"))
        }
        isPresent = try !c.decodeNil(forKey: .active)
    }
}

/// v3·v4 저장 계약. 카드·기록 형식은 v5와 같다.
struct LegacySnapshotV3V4: Decodable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    let cards: CardSection
    let journey: LegacyJourneyPresence
    let records: RecordSection
}

/// 옛 형식(v1~v4)을 읽으며 예시 데이터 정류장·여정을 비웠다는 보고.
enum SnapshotMigration: Equatable { case routeDataReset }

/// 저장 파일 바이트와 `AppSnapshot` 사이의 변환. 판정 순서는 헤더 → 버전 → 구조 → 내용이다.
enum SnapshotCodec {
    static let currentVersion = 5

    private struct VersionHeader: Decodable { let version: Int }
    private struct EnvelopeV3V4: Decodable { let state: LegacySnapshotV3V4 }
    private struct EnvelopeV2: Decodable { let state: LegacySnapshotV2 }
    private struct EnvelopeV1: Decodable { let state: LegacySnapshotV1 }
    private struct Envelope: Codable { let version: Int; let state: AppSnapshot }

    static func decode(_ data: Data) throws -> AppSnapshot { try decodeReport(data).snapshot }

    static func decodeReport(_ data: Data) throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?) {
        let header: VersionHeader
        do { header = try JSONDecoder().decode(VersionHeader.self, from: data) }
        catch { throw StorageIssue.corrupt }
        let state: AppSnapshot
        var legacyJourney = false
        do {
            switch header.version {
            case 1: state = migrateV1(try JSONDecoder().decode(EnvelopeV1.self, from: data).state)
            case 2: state = migrateV2(try JSONDecoder().decode(EnvelopeV2.self, from: data).state)
            case 3, 4:
                let legacy = try JSONDecoder().decode(EnvelopeV3V4.self, from: data).state
                legacyJourney = legacy.journey.isPresent
                state = migrateV3V4(legacy)
            case currentVersion: state = try JSONDecoder().decode(Envelope.self, from: data).state
            default: throw StorageIssue.unsupportedVersion(header.version)
            }
        } catch let issue as StorageIssue { throw issue }
        catch { throw StorageIssue.corrupt }
        let readable = dropInvalidActiveJourney(state)
        do { try readable.validate() }
        catch let issue as SnapshotValidationIssue { throw StorageIssue.invalidState(issue) }
        let sorted = readable.updating(records: readable.records.sortedNewestFirst())
        guard header.version < currentVersion else { return (sorted, nil) }
        // 손상 판정을 지킨 뒤(validate 먼저) 예시 데이터 정류장·여정을 비운다. 카드·기록은 그대로다.
        let hadRouteData = sorted.initialStation != nil || sorted.currentStation != nil || legacyJourney
        return (sorted.clearingStationsAndJourney(), hadRouteData ? .routeDataReset : nil)
    }

    /// 읽기 전용 완화: 검증을 통과하지 못하는 진행 여정만 버린다. 쓰기(`LocalSnapshotStore.save`)는 그대로 엄격하다.
    private static func dropInvalidActiveJourney(_ state: AppSnapshot) -> AppSnapshot {
        guard let active = state.journey.active else { return state }
        let valid = state.currentStation != nil && (try? active.validate(currentCardID: state.currentCard?.id)) != nil
        return valid ? state : state.updating(journey: .empty)
    }

    static func encode(_ snapshot: AppSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(version: currentVersion, state: snapshot))
    }

    static func migrateV3V4(_ legacy: LegacySnapshotV3V4) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
            .updating(cards: legacy.cards)
            .updating(records: legacy.records)
    }

    static func migrateV2(_ legacy: LegacySnapshotV2) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
            .updating(cards: CardSection(items: legacy.cards.items.map { CardSnapshot(id: $0.id, issuedAt: $0.issuedAt) }))
            .updating(journey: .empty)
            .updating(records: legacy.records)
    }

    static func migrateV1(_ legacy: LegacySnapshotV1) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
    }
}
