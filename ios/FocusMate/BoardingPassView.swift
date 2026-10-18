import SwiftUI

/// 승차권(시안 R11). 지도 위 떠 있는 시트에 노선 배지, 출발·도착, 여행 시간·정류장·이동 거리, 태그·할 일, '버스에 탑승하기'.
@MainActor
struct BoardingPassView: View {
    @Bindable var model: AppModel
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var sheetHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            if let details = model.confirmedPreparation {
                let content = BoardingPassContent(details: details)
                SceneMapBackdrop(model: model, stationID: details.journey.originStopID,
                                 bottomInset: sheetHeight + 20,
                                 routeID: details.journey.busID, leg: legStopIndices(details.journey))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    sheet(content)
                }
            } else {
                FMDesign.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    backButton
                    Text("준비를 다시 확인해주세요").font(FontCatalog.style(.headline, weight: .semibold))
                        .accessibilityIdentifier("board.unavailable")
                    Spacer()
                }
                .padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onPreferenceChange(BoardSheetHeightKey.self) { sheetHeight = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.board")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func legStopIndices(_ journey: JourneySelection) -> [Int]? {
        model.legStopIndices(for: journey)
    }

    private var backButton: some View {
        Button { model.goBack() } label: {
            Image(systemName: "chevron.left").font(.system(size: 18, weight: .regular))
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로").accessibilityIdentifier("board.back")
    }

    private func sheet(_ content: BoardingPassContent) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    backButton.padding(.leading, -4)
                    Text("승차권").font(FontCatalog.text(20, weight: .bold, relativeTo: .title3))
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                }
                // 화면에는 배지·칸으로 나뉘어 보이는 값을 한 문장으로도 읽어준다.
                Color.clear.frame(width: 1, height: 1).accessibilityElement()
                    .accessibilityLabel(content.routeAccessibilityLabel).accessibilityIdentifier("board.route")
                routeBadge(content).padding(.top, 12)
                HStack(alignment: .top, spacing: 0) {
                    cell("출발", content.originName, id: "board.origin", valueSize: 16)
                    cell("도착", content.destinationName, id: "board.destination", valueSize: 16)
                }
                .padding(.top, 11)
                divider(0.09).padding(.top, 23)
                HStack(alignment: .top, spacing: 0) {
                    cell("여행 시간", content.minutesText, id: "board.minutes", valueSize: 13)
                    cell("정류장", content.stopsText, id: "board.stops", valueSize: 13)
                    cell("이동 거리", content.distanceText, id: "board.distance", valueSize: 13)
                }
                .padding(.top, 10)
                divider(0.12).padding(.top, 20)
                Text(content.taskLine).font(FontCatalog.text(15, relativeTo: .body))
                    .lineLimit(3).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                    .padding(.top, 19.5)
                    .overlay(alignment: .topLeading) {
                        // 테스트·낭독 도구가 태그와 할 일을 따로 읽도록 값만 담은 요소를 둔다.
                        hiddenValue(content.tagName, id: "board.tag")
                        hiddenValue(content.task, id: "board.task")
                    }
                Button { model.openBoarding() } label: {
                    Text("버스에 탑승하기 →")
                }
                .buttonStyle(FMPrimaryButtonStyle(size: .compact))
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .accessibilityLabel("버스에 탑승하기").accessibilityIdentifier("board.boardBus")
                .padding(.horizontal, -1).padding(.top, 30)
            }
            .padding(.horizontal, 17).padding(.top, 13).padding(.bottom, 17)
        }
        .scrollBounceBehavior(.basedOnSize)
        .fixedSize(horizontal: false, vertical: !typeSize.isAccessibilitySize)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: BoardSheetHeightKey.self, value: proxy.size.height)
            }
        }
        .background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(FMDesign.panelStroke, lineWidth: 1))
        .padding(.horizontal, 12).padding(.bottom, 20)
    }

    /// 시안 노선 배지: 노선 종류 색 120x40 캡슐, 버스 아이콘 18 · 종류 10pt #B5B5BA · 번호 20 Bold.
    private func routeBadge(_ content: BoardingPassContent) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bus").font(.system(size: 17, weight: .light)).frame(width: 24, height: 24)
            Text(content.busKind).font(FontCatalog.text(10, relativeTo: .caption2)).foregroundStyle(FMDesign.tertiaryText)
            Text(content.busNumber).font(FontCatalog.text(20, weight: .bold, relativeTo: .title3)).lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).frame(minWidth: 120, minHeight: 40)
        .background(FMDesign.routeColor(kind: content.busKind), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(content.busKind) \(content.busNumber)")
        .accessibilityIdentifier("board.bus")
    }

    private func cell(_ label: String, _ value: String, id: String, valueSize: CGFloat) -> some View {
        VStack(spacing: 3) {
            Text(label).font(FontCatalog.text(10, relativeTo: .caption2)).foregroundStyle(FMDesign.tertiaryText)
            Text(value).font(FontCatalog.text(valueSize, weight: .bold, relativeTo: valueSize > 14 ? .headline : .footnote))
                .monospacedDigit()
                .lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center)
                .accessibilityValue(value).accessibilityIdentifier(id)
        }
        .frame(maxWidth: .infinity)
    }

    private func divider(_ opacity: Double) -> some View {
        Rectangle().fill(.white.opacity(opacity)).frame(height: 1).accessibilityHidden(true)
    }

    private func hiddenValue(_ value: String, id: String) -> some View {
        Color.clear.frame(width: 1, height: 1).accessibilityElement()
            .accessibilityLabel(value).accessibilityValue(value).accessibilityIdentifier(id)
    }
}

private struct BoardSheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
