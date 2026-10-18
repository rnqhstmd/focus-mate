import CoreGraphics
import Foundation

/// 승차 태그의 순수 기하 규칙. 화면 좌표(카드 기준 위치·태그 영역)만 받아 겹침·끌기 범위·터치 판정을 정한다.
struct BoardingGeometry {
    /// 시안 R27·R28 단말기 안 태그 영역(149x76).
    var tagAreaSize = CGSize(width: 149, height: 76)
    /// 겹친 면적 ÷ 태그 영역 면적이 이 값 이상이면 접촉이다(BR-7).
    var threshold: CGFloat = 0.30
    var maxHorizontal: CGFloat = 26
    var maxDown: CGFloat = 20
    /// 이 거리 미만으로 움직이고 놓으면 끌기가 아니라 터치다.
    var tapSlop: CGFloat = 8
    /// 낭독기·키보드 활성화 위치가 임계를 확실히 넘도록 더하는 여유 높이.
    var activationMargin: CGFloat = 8
    /// 시안 R27·R28 태그 화면의 카드 폭(270x158).
    var cardWidth: CGFloat = 270

    /// 좌우는 ±maxHorizontal, 위로는 카드 위쪽이 태그 영역 위쪽에 닿을 때까지, 아래로는 maxDown까지만 움직인다.
    func clampedOffset(_ translation: CGSize, cardRest: CGRect, tagArea: CGRect) -> CGSize {
        CGSize(width: min(max(translation.width, -maxHorizontal), maxHorizontal),
               height: min(max(translation.height, tagArea.minY - cardRest.minY), maxDown))
    }

    func overlapRatio(card: CGRect, tagArea: CGRect) -> CGFloat {
        let overlap = card.intersection(tagArea)
        guard !overlap.isNull, tagArea.width > 0, tagArea.height > 0 else { return 0 }
        return (overlap.width * overlap.height) / (tagArea.width * tagArea.height)
    }

    func isContact(card: CGRect, tagArea: CGRect) -> Bool { overlapRatio(card: card, tagArea: tagArea) >= threshold }

    func isTap(_ translation: CGSize) -> Bool { hypot(translation.width, translation.height) < tapSlop }

    /// 카드가 태그 영역 아래쪽 가장자리에 걸치면서 겹침이 임계를 넘는 위치. 카드 폭이 달라도 임계를 넘도록 높이를 계산한다.
    func activationOffset(cardRest: CGRect, tagArea: CGRect) -> CGSize {
        let overlapWidth = min(cardRest.width, tagArea.width)
        guard overlapWidth > 0 else { return .zero }
        let overlapHeight = threshold * tagArea.width * tagArea.height / overlapWidth + activationMargin
        return CGSize(width: tagArea.midX - cardRest.midX, height: tagArea.maxY - overlapHeight - cardRest.minY)
    }
}

/// 승차 연출 시간. 동작 줄이기에서는 접촉 이동·페이드를 생략하고 인식 유지 시간만 남긴다.
struct BoardingTiming {
    var contact: Duration = .milliseconds(300)
    var hold: Duration = .milliseconds(1400)
    var fade: Duration = .milliseconds(450)
    var terminalEntrance: TimeInterval = 0.12
    var cardEntrance: TimeInterval = 0.38
    static let standard = BoardingTiming()

    func contact(reduceMotion: Bool) -> Duration { reduceMotion ? .zero : contact }
    func fade(reduceMotion: Bool) -> Duration { reduceMotion ? .zero : fade }
}

/// 단말기 LCD의 현재 시각(24시간 HH:mm).
enum BoardingClock {
    static func text(for date: Date, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
