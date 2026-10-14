import Foundation

/// 발급 카드 한 장(glossary: issuedPass). id 형식은 디코딩이 아니라 `AppSnapshot.validate`가 판정해 `.invalidState`로 분류된다.
struct CardSnapshot: Codable, Equatable {
    let id: String
    let issuedAt: Date
    let style: CardStyle

    init(id: String, issuedAt: Date, style: CardStyle = .standard) {
        self.id = id
        self.issuedAt = issuedAt
        self.style = style
    }

    func updating(style: CardStyle) -> CardSnapshot { CardSnapshot(id: id, issuedAt: issuedAt, style: style) }

    /// `FM-` + ASCII 숫자 8자리.
    static func isValidID(_ id: String) -> Bool {
        let bytes = Array(id.utf8)
        guard bytes.count == 11, id.hasPrefix("FM-") else { return false }
        return bytes.dropFirst(3).allSatisfy { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }
    }

    private enum CodingKeys: String, CodingKey { case id, issuedAt, style }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        let text = try c.decode(String.self, forKey: .issuedAt)
        guard let date = try? Date(text, strategy: .iso8601) else {
            throw DecodingError.dataCorruptedError(forKey: .issuedAt, in: c, debugDescription: "issuedAt is not ISO 8601")
        }
        issuedAt = date
        style = try c.decode(CardStyle.self, forKey: .style)
    }
    /// 날짜를 직접 문자열로 써서 인코더의 날짜 전략과 무관하게 같은 바이트를 낸다.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(issuedAt.formatted(.iso8601), forKey: .issuedAt)
        try c.encode(style, forKey: .style)
    }
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
