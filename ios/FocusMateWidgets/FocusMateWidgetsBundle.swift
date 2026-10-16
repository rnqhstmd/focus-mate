import SwiftUI
import WidgetKit

/// Live Activity와 두 종류의 홈 위젯을 함께 제공한다.
@main
struct FocusMateWidgetsBundle: WidgetBundle {
    var body: some Widget {
        JourneyLiveActivityWidget()
        FocusPromptWidget()
        AnalyticsHomeWidget()
    }
}
