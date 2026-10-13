import SwiftUI

/// 메인 위에 쌓이는 목적지 화면.
@MainActor
struct DestinationScreen: View {
    let destination: Destination
    @Bindable var model: AppModel

    var body: some View {
        Group {
            if destination == .time {
                TimeSelectionView(model: model)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text(destination.title).font(.largeTitle.bold())
                        .accessibilityIdentifier("screen.\(destination.rawValue)")
                    if destination == .records { Text("아직 여행 기록이 없어요.").foregroundStyle(.secondary) }
                    Spacer()
                }
            }
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .navigationTitle(destination.title).navigationBarTitleDisplayMode(.inline)
        #if DEBUG
        .overlay(alignment: .bottomLeading) {
            if destination == .preparation {
                Text("여정 선택 진단").accessibilityValue(journeySelectionJSON).accessibilityIdentifier("test.journeySelection")
                    .font(.system(size: 1)).foregroundStyle(.clear)
            }
        }
        #endif
    }

    #if DEBUG
    /// 준비 화면이 받은 여정 선택(W03 전까지 화면에 쓰지 않는 값)을 UI 테스트가 확인하도록 내보낸다.
    private var journeySelectionJSON: String {
        guard let selection = model.preparedJourney else { return "null" }
        let object: [String: Any] = ["busID": selection.busID, "busNumber": selection.busNumber,
                                     "destination": selection.destination, "minutes": selection.minutes,
                                     "stops": selection.stops]
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "null" }
        return json
    }
    #endif
}
