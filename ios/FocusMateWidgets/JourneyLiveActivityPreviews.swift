#if DEBUG
import ActivityKit
import SwiftUI
import WidgetKit

private let previewJourney = JourneyActivityAttributes(journeyID: "preview", busNumber: "143", busKind: "간선", destinationName: "서울숲")

#Preview("확장 · 운행/정지/장시간", as: .dynamicIsland(.expanded), using: previewJourney) {
    JourneyLiveActivityWidget()
} contentStates: {
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(1122), pausedRemainingSeconds: nil, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 1122, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(135), pausedRemainingSeconds: nil, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .arrived, endDate: nil, pausedRemainingSeconds: nil, totalSeconds: 1800)
}

#Preview("Compact · 시간 경계", as: .dynamicIsland(.compact), using: previewJourney) {
    JourneyLiveActivityWidget()
} contentStates: {
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(5), pausedRemainingSeconds: nil, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 599, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 5999, totalSeconds: 7200)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 7200, totalSeconds: 7200)
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(21600), pausedRemainingSeconds: nil, totalSeconds: 21600)
}

#Preview("Minimal · 상태", as: .dynamicIsland(.minimal), using: previewJourney) {
    JourneyLiveActivityWidget()
} contentStates: {
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(1122), pausedRemainingSeconds: nil, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 1122, totalSeconds: 1800)
    JourneyActivityAttributes.ContentState(status: .arrived, endDate: nil, pausedRemainingSeconds: nil)
}

#Preview("잠금 · 긴 한국어", as: .content, using: JourneyActivityAttributes(journeyID: "long", busNumber: "서울도심순환12345", busKind: "심야광역급행", destinationName: "서울특별시성동구성수동복합문화체육센터정문앞")) {
    JourneyLiveActivityWidget()
} contentStates: {
    JourneyActivityAttributes.ContentState(status: .running, endDate: .now.addingTimeInterval(21600), pausedRemainingSeconds: nil, totalSeconds: 21600)
    JourneyActivityAttributes.ContentState(status: .paused, endDate: nil, pausedRemainingSeconds: 1122, totalSeconds: nil)
}
#endif
