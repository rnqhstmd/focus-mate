import SwiftUI
import WidgetKit

/// 위젯 확장 진입점. 홈 화면 위젯 없이 여행 Live Activity만 제공한다.
@main
struct FocusMateWidgetsBundle: WidgetBundle {
    var body: some Widget {
        JourneyLiveActivityWidget()
    }
}
