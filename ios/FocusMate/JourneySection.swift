import Foundation

/// W00은 진행 여정의 계약을 정하지 않는다. 값이 없으므로 진행 여정이 든 파일은 읽지 않고 보존한다.
enum JourneySnapshot: Codable, Equatable {
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "journey element is not defined yet"))
    }
    func encode(to encoder: Encoder) throws { switch self {} }
}

struct JourneySection: Codable, Equatable {
    let active: JourneySnapshot?
    static let empty = JourneySection(active: nil)
}

extension JourneySection {
    private enum CodingKeys: String, CodingKey { case active }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard c.contains(.active) else {
            throw DecodingError.keyNotFound(CodingKeys.active, .init(codingPath: c.codingPath, debugDescription: "journey.active is required"))
        }
        active = try c.decodeNil(forKey: .active) ? nil : c.decode(JourneySnapshot.self, forKey: .active)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let active { try c.encode(active, forKey: .active) } else { try c.encodeNil(forKey: .active) }
    }
}
