import CoreGraphics
import Foundation

/// 승차권에 보이는 값. 버스 번호와 여행 시간은 화면에 쓰지 않고 낭독 라벨에만 넣는다.
struct BoardingPassContent: Equatable {
    let originName: String
    let destinationName: String
    let stopsText: String
    let distanceText: String
    let boardingText: String
    let dateText: String
    let tagName: String
    let task: String
    /// 낭독 라벨에 들어가는 버스 문구("유형 번호번 버스").
    let busText: String
    /// 두 정류장 이름 중 긴 쪽 글자 수로 정하는 같은 크기(프로토타입 규칙: 4자 이하 28, 6자 이하 24, 9자 이하 20, 그 외 17).
    let stationFontSize: CGFloat
    let routeAccessibilityLabel: String

    init(details: PreparedJourneyDetails, now: Date, timeZone: TimeZone) {
        let journey = details.journey
        originName = details.originName
        destinationName = journey.destination
        stopsText = "\(journey.stops)개"
        distanceText = details.distanceText
        boardingText = "지금"
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = calendar.dateComponents([.year, .month, .day], from: now)
        dateText = String(format: "%04d/%02d/%02d", day.year ?? 0, day.month ?? 0, day.day ?? 0)
        tagName = details.tag.name
        task = details.task
        stationFontSize = Self.fontSize(longest: max(originName.count, destinationName.count))
        busText = "\(journey.busKind) \(journey.busNumber)번 버스"
        routeAccessibilityLabel = "\(originName)에서 \(destinationName)까지, \(busText), \(journey.minutes)분 여행"
    }

    private static func fontSize(longest: Int) -> CGFloat {
        switch longest {
        case ...4: 28
        case ...6: 24
        case ...9: 20
        default: 17
        }
    }
}
