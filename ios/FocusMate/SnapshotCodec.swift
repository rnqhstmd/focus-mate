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

struct LegacySnapshotV2: Decodable {
    struct Cards: Decodable { let items: [LegacyCardV2DTO] }
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    let cards: Cards
    let journey: JourneySection
    let records: RecordSection
}

/// 저장 파일 바이트와 `AppSnapshot` 사이의 변환. 판정 순서는 헤더 → 버전 → 구조 → 내용이다.
enum SnapshotCodec {
    static let currentVersion = 3

    private struct VersionHeader: Decodable { let version: Int }
    private struct EnvelopeV2: Decodable { let state: LegacySnapshotV2 }
    private struct EnvelopeV1: Decodable { let state: LegacySnapshotV1 }
    private struct Envelope: Codable { let version: Int; let state: AppSnapshot }

    static func decode(_ data: Data) throws -> AppSnapshot {
        let header: VersionHeader
        do { header = try JSONDecoder().decode(VersionHeader.self, from: data) }
        catch { throw StorageIssue.corrupt }
        let state: AppSnapshot
        do {
            switch header.version {
            case 1: state = migrateV1(try JSONDecoder().decode(EnvelopeV1.self, from: data).state)
            case 2: state = migrateV2(try JSONDecoder().decode(EnvelopeV2.self, from: data).state)
            case currentVersion: state = try JSONDecoder().decode(Envelope.self, from: data).state
            default: throw StorageIssue.unsupportedVersion(header.version)
            }
        } catch let issue as StorageIssue { throw issue }
        catch { throw StorageIssue.corrupt }
        do { try state.validate() }
        catch let issue as SnapshotValidationIssue { throw StorageIssue.invalidState(issue) }
        return state.updating(records: state.records.sortedNewestFirst())
    }

    static func encode(_ snapshot: AppSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(version: currentVersion, state: snapshot))
    }

    static func migrateV2(_ legacy: LegacySnapshotV2) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
            .updating(cards: CardSection(items: legacy.cards.items.map { CardSnapshot(id: $0.id, issuedAt: $0.issuedAt) }))
            .updating(journey: legacy.journey)
            .updating(records: legacy.records)
    }

    static func migrateV1(_ legacy: LegacySnapshotV1) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
    }
}
