import SwiftUI

/// 승차권(시안 TUNX2). 지도 배경 위 티켓 카드와 하단 '버스에 탑승하기'. 버스 번호·여행 시간은 낭독 라벨에만 있다.
@MainActor
struct BoardingPassView: View {
    @Bindable var model: AppModel

    var body: some View {
        GeometryReader { geometry in
          ZStack {
            // The approved ticket uses this artwork; constrain its intrinsic size to the viewport.
            Image("BoardMap").resizable().scaledToFill()
                .frame(width: geometry.size.width,
                       height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                .clipped()
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35).ignoresSafeArea())
                .accessibilityHidden(true)
            if let details = model.confirmedPreparation {
                let content = BoardingPassContent(details: details, now: .now, timeZone: .current)
                VStack {
                    Text("\(details.originName) → \(details.journey.destination)")
                        .font(FontCatalog.style(.caption))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(FMDesign.panel.opacity(0.8), in: Capsule())
                        .padding(.top, 12).padding(.horizontal, 24)
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 24)
                        ticket(content)
                    }
                    .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 12)
                    .frame(minHeight: max(0, geometry.size.height - 100), alignment: .bottom)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom) { boardButton }
            } else {
                Text("준비를 다시 확인해주세요").font(FontCatalog.style(.headline, weight: .semibold)).padding(24)
                    .accessibilityIdentifier("board.unavailable")
            }
          }
          .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.board")
        .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }

    private func ticket(_ content: BoardingPassContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 버스 번호·여행 시간은 화면 글자가 아니라 낭독 요소로만 둔다.
            Color.clear.frame(width: 1, height: 1).accessibilityElement()
                .accessibilityLabel(content.routeAccessibilityLabel).accessibilityIdentifier("board.route")
            row(("출발", content.originName, "board.origin"), ("도착", content.destinationName, "board.destination"),
                valueFont: FontCatalog.text(min(content.stationFontSize, 24), weight: .bold, relativeTo: .title2), lineLimit: 2)
            row(("정류장", content.stopsText, "board.stops"), ("거리", content.distanceText, "board.distance"),
                valueFont: FontCatalog.style(.subheadline, weight: .semibold).monospacedDigit())
            row(("탑승", content.boardingText, "board.boarding"), ("날짜", content.dateText, "board.date"),
                valueFont: FontCatalog.style(.subheadline, weight: .semibold).monospacedDigit())
            row(("태그", content.tagName, "board.tag"), ("할 일", content.task, "board.task"),
                valueFont: FontCatalog.style(.subheadline, weight: .semibold), lineLimit: 3)
                .padding(.top, 18)
        }
        .padding(22)
        .background {
            ZStack {
                Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
                Image("TicketDots").resizable().scaledToFit().opacity(0.28).padding(36)
            }
            .clipShape(TicketShape(), style: FillStyle(eoFill: true))
            .accessibilityHidden(true)
        }
    }

    private func row(_ left: (String, String, String), _ right: (String, String, String),
                     valueFont: Font, lineLimit: Int = 1) -> some View {
        HStack(alignment: .top, spacing: 16) {
            cell(left, valueFont: valueFont, lineLimit: lineLimit, alignment: .leading)
            cell(right, valueFont: valueFont, lineLimit: lineLimit, alignment: .trailing)
        }
    }

    private func cell(_ item: (label: String, value: String, id: String), valueFont: Font, lineLimit: Int,
                      alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(item.label).font(FontCatalog.style(.footnote)).foregroundStyle(.secondary)
            Text(item.value).font(valueFont).lineLimit(lineLimit).minimumScaleFactor(0.7)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                .accessibilityValue(item.value).accessibilityIdentifier(item.id)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private var boardButton: some View {
        Button { model.openBoarding() } label: {
            Text("버스에 탑승하기 →")
        }
        .buttonStyle(FMPrimaryButtonStyle(size: .compact))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityLabel("버스에 탑승하기").accessibilityIdentifier("board.boardBus")
        .padding(.horizontal, 24).padding(.bottom, 12)
    }
}

/// 절취선 없이 양옆 노치만 남긴 티켓 모양.
private struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 24, notch: CGFloat = 12, notchY = rect.height * 0.62
        var path = Path(roundedRect: rect, cornerRadius: radius)
        path.addEllipse(in: CGRect(x: rect.minX - notch, y: notchY - notch, width: notch * 2, height: notch * 2))
        path.addEllipse(in: CGRect(x: rect.maxX - notch, y: notchY - notch, width: notch * 2, height: notch * 2))
        return path
    }
}
