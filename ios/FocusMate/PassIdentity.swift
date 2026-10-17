import Foundation

/// 카드 이름·번호 표기의 단일 출처. 번호는 시안대로 카드 앞면 왼쪽 아래와 태그 LCD에 보인다(BR-4 시안 우선 변경).
struct PassIdentity: Equatable {
    static let displayName = "집중동행카드"

    let name: String
    let numberText: String

    init(card: CardSnapshot) {
        name = Self.displayName
        let digits = card.id.dropFirst(3)
        numberText = "FM · \(digits.prefix(4)) \(digits.suffix(4))"
    }

    static func current(in snapshot: AppSnapshot?) -> PassIdentity? {
        snapshot?.currentCard.map(PassIdentity.init(card:))
    }
}
