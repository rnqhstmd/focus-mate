import Foundation

/// 카드 이름·번호 표기의 단일 출처. 번호 표기는 지금 어떤 화면에도 노출하지 않는다(BR-4).
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
