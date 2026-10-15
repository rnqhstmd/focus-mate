import Foundation

/// 진행 여정은 없거나(null) 최대 1건이다. 새 승차는 기존 값을 교체한다.
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
        // 진행 여정은 언제든 버릴 수 있는 임시 값이다. 손상되면 여정만 없던 것으로 읽고 카드·기록은 지킨다.
        active = try c.decodeNil(forKey: .active) ? nil : try? c.decode(JourneySnapshot.self, forKey: .active)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let active { try c.encode(active, forKey: .active) } else { try c.encodeNil(forKey: .active) }
    }
}
