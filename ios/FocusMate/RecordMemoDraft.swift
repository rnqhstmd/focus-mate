import Foundation

/// 메모 길이 규칙(BR-4): UTF-16 200 이하, 유니코드 스칼라를 쪼개지 않는다.
enum RecordMemoLimit {
    static let maxUTF16 = 200

    static func prefix(_ text: String) -> String {
        var limited = ""
        var length = 0
        for scalar in text.unicodeScalars {
            let width = scalar.value <= 0xffff ? 1 : 2
            guard length + width <= maxUTF16 else { break }
            limited.unicodeScalars.append(scalar)
            length += width
        }
        return limited
    }
}

/// 메모 입력 중의 값. 입력은 길이만 자르고, 저장값은 앞뒤 공백을 지운다.
struct RecordMemoDraft: Equatable {
    private(set) var text: String

    init(text: String = "") { self.text = RecordMemoLimit.prefix(text) }

    mutating func update(_ input: String) { text = RecordMemoLimit.prefix(input) }

    var counterText: String { "\(text.utf16.count) / \(RecordMemoLimit.maxUTF16)" }
    var savedValue: String { RecordMemoLimit.prefix(text.trimmingCharacters(in: .whitespacesAndNewlines)) }
    var isBlank: Bool { savedValue.isEmpty }
}
