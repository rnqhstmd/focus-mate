import Foundation

struct StationSnapshot: Codable, Equatable {
    let id: String
    let name: String
    let direction: Int
}

enum LaunchRoute: Equatable { case cardEntry, initialStationEntry, main }
enum SnapshotValidationIssue: Error, Equatable {
    case inconsistentStage, emptyStationID, emptyStationName, invalidDirection(Int)
}

struct AppSnapshot: Codable, Equatable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    static let empty = AppSnapshot(cardIssued: false, initialStation: nil, currentStation: nil)

    func validate() throws {
        let noStations = initialStation == nil && currentStation == nil
        let bothStations = initialStation != nil && currentStation != nil
        guard noStations || (cardIssued && bothStations) else { throw SnapshotValidationIssue.inconsistentStage }
        for station in [initialStation, currentStation].compactMap({ $0 }) {
            guard !station.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SnapshotValidationIssue.emptyStationID }
            guard !station.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SnapshotValidationIssue.emptyStationName }
            guard station.direction == 1 || station.direction == -1 else { throw SnapshotValidationIssue.invalidDirection(station.direction) }
        }
    }

    func launchRoute() throws -> LaunchRoute {
        try validate()
        if !cardIssued { return .cardEntry }
        return currentStation == nil ? .initialStationEntry : .main
    }

    private enum CodingKeys: String, CodingKey { case cardIssued, initialStation, currentStation }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(cardIssued, forKey: .cardIssued)
        if let initialStation { try c.encode(initialStation, forKey: .initialStation) }
        else { try c.encodeNil(forKey: .initialStation) }
        if let currentStation { try c.encode(currentStation, forKey: .currentStation) }
        else { try c.encodeNil(forKey: .currentStation) }
    }
}
