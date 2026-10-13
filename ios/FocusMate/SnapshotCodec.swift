import Foundation

/// 버전 1 저장 계약. 이후 `AppSnapshot`이 바뀌어도 고치지 않는다.
struct LegacySnapshotV1: Decodable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
}

/// 저장 파일 바이트와 `AppSnapshot` 사이의 변환. 판정 순서는 헤더 → 버전 → 구조 → 내용이다.
enum SnapshotCodec {
    static let currentVersion = 2

    private struct VersionHeader: Decodable { let version: Int }
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

    static func migrateV1(_ legacy: LegacySnapshotV1) -> AppSnapshot {
        AppSnapshot.empty.updatingStage(cardIssued: legacy.cardIssued,
                                        initialStation: legacy.initialStation,
                                        currentStation: legacy.currentStation)
    }
}
