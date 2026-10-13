import Foundation

/// 발급과 기존 사용자 보충이 함께 쓰는 카드 생성기. 난수·시계를 주입해 테스트에서 결정적으로 만든다.
struct CardSnapshotFactory {
    private let randomNumber: () -> UInt32
    private let now: () -> Date

    init(randomNumber: @escaping () -> UInt32 = { .random(in: 0..<100_000_000) },
         now: @escaping () -> Date = Date.init) {
        self.randomNumber = randomNumber
        self.now = now
    }

    func make() -> CardSnapshot {
        let digits = String(format: "%08u", randomNumber() % 100_000_000)
        // 저장 형식이 초 단위라 내려 두어야 저장·로드 왕복 값이 같다.
        let issuedAt = Date(timeIntervalSince1970: now().timeIntervalSince1970.rounded(.down))
        return CardSnapshot(id: "FM-" + digits, issuedAt: issuedAt)
    }
}
