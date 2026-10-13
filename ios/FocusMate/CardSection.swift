import Foundation

/// W00은 카드 원소의 계약을 정하지 않는다. 값이 없으므로 원소가 든 파일은 읽지 않고 보존한다.
enum CardSnapshot: Codable, Equatable {
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "card element is not defined yet"))
    }
    func encode(to encoder: Encoder) throws { switch self {} }
}

struct CardSection: Codable, Equatable {
    let items: [CardSnapshot]
    static let empty = CardSection(items: [])
}

extension CardSection {
    private enum CodingKeys: String, CodingKey { case items }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decode([CardSnapshot].self, forKey: .items)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(items, forKey: .items)
    }
}
