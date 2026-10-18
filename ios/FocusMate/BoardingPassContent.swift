import Foundation

/// 승차권(시안 R11)에 보이는 값. 시안을 따라 버스 종류·번호와 여행 시간도 화면에 쓴다.
struct BoardingPassContent: Equatable {
    let originName: String
    let destinationName: String
    /// 노선 배지 왼쪽 작은 글자("지선").
    let busKind: String
    /// 노선 배지 번호("2014").
    let busNumber: String
    /// 여행 시간("25 min").
    let minutesText: String
    let stopsText: String
    /// 이동 거리("2.8 km", 숫자와 단위 사이 공백).
    let distanceText: String
    let tagName: String
    let task: String
    /// 태그·할 일 한 줄("독서 · 책 한 챕터 읽기").
    let taskLine: String
    /// 낭독 라벨에 들어가는 버스 문구("유형 번호번 버스").
    let busText: String
    let routeAccessibilityLabel: String

    init(details: PreparedJourneyDetails) {
        let journey = details.journey
        originName = details.originName
        destinationName = journey.destination
        busKind = journey.busKind
        busNumber = journey.busNumber
        minutesText = "\(journey.minutes) min"
        stopsText = "\(journey.stops)개"
        distanceText = Self.spacedUnit(details.distanceText)
        tagName = details.tag.name
        task = details.task
        taskLine = "\(details.tag.name) · \(details.task)"
        busText = "\(journey.busKind) \(journey.busNumber)번 버스"
        routeAccessibilityLabel = "\(originName)에서 \(destinationName)까지, \(busText), \(journey.minutes)분 여행"
    }

    /// "6.6km" → "6.6 km".
    private static func spacedUnit(_ text: String) -> String {
        guard text.hasSuffix("km"), !text.hasSuffix(" km") else { return text }
        return String(text.dropLast(2)) + " km"
    }
}
