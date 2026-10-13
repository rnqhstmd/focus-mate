import Foundation

/// W00은 완료 기록 원소의 계약을 정하지 않는다. 값이 없으므로 원소가 든 파일은 읽지 않고 보존한다.
enum RecordSnapshot: Codable, Equatable {
    init(from decoder: Decoder) throws {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "record element is not defined yet"))
    }
    func encode(to encoder: Encoder) throws { switch self {} }
}

struct RecordSection: Codable, Equatable {
    let items: [RecordSnapshot]
    static let empty = RecordSection(items: [])
}

extension RecordSection {
    private enum CodingKeys: String, CodingKey { case items }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decode([RecordSnapshot].self, forKey: .items)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(items, forKey: .items)
    }
}
