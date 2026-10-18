import SwiftUI

/// 시안 R14 정류장 진행 패널: 최근 도달 → 다음 정류장(강조) → 남은 정류장 몇 개 → 도착.
/// 왼쪽 세로선으로 이어 진행 순서를 보인다. 노선 버튼으로 열고 닫는다.
struct JourneyStopPanel: View {
    let map: JourneyMapController
    /// 다음 정류장과 도착 사이에 이름을 보일 정류장 수. 나머지는 개수로 줄인다.
    static let middleLimit = 2

    private var stops: [CourseStop] { map.journey.stops }
    private var next: Int { min(max(map.nextStopIndex, 1), stops.count - 1) }
    private var last: Int { stops.count - 1 }
    private var middle: ArraySlice<CourseStop> { next + 1 < last ? stops[(next + 1)..<last] : [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            row(marker: Circle().fill(Color(hex: 0x737B84)).frame(width: 5, height: 5)) {
                caption(next - 1 == 0 ? "출발" : "최근 도달", color: Color(hex: 0x8C949E))
                Text(stops[next - 1].name).font(FontCatalog.text(10, relativeTo: .caption2))
                    .foregroundStyle(Color(hex: 0xA5ADB7))
            }
            if next < last {
                row(marker: Circle().fill(FMDesign.routeColor(kind: map.journey.routeKind)).frame(width: 12, height: 12)
                        .overlay(Circle().strokeBorder(Color(hex: 0x0A0D10), lineWidth: 1))
                        .padding(4).background(Color.white.opacity(0.07), in: Circle())) {
                    caption("다음 정류장", color: Color(hex: 0xC2C9D0))
                    Text(stops[next].name).font(FontCatalog.text(15, weight: .bold, relativeTo: .headline))
                        .foregroundStyle(.white)
                }
                .padding(.top, 18)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(middle.prefix(Self.middleLimit), id: \.id) { stop in
                        caption("\(stop.index) · \(stop.name)", color: Color(hex: 0x929BA6))
                    }
                    if middle.count > Self.middleLimit {
                        caption("외 \(middle.count - Self.middleLimit)개", color: Color(hex: 0x929BA6))
                    }
                }
                .padding(.leading, 23).padding(.top, middle.isEmpty ? 0 : 20)
            }
            row(marker: Image(systemName: "flag").font(.system(size: 12)).foregroundStyle(Color(hex: 0xC9D0D7))) {
                caption("도착", color: Color(hex: 0x929BA6))
                Text(stops[last].name).font(FontCatalog.text(11, relativeTo: .caption))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)
        }
        .padding(.leading, 8).padding(.trailing, 16).padding(.vertical, 16)
        .background(alignment: .leading) {
            // 점들을 잇는 세로선(시안 x=33, 흰 13%).
            Rectangle().fill(Color.white.opacity(0.13)).frame(width: 1).padding(.vertical, 22).padding(.leading, 17)
        }
        .frame(minWidth: 128, maxWidth: 200, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22).fill(Color(hex: 0x090B0E).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.125)))
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("journey.stopPanel")
    }

    private func caption(_ text: String, color: Color) -> some View {
        Text(text).font(FontCatalog.text(9, relativeTo: .caption2)).foregroundStyle(color).lineLimit(1)
    }

    private func row(marker: some View, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 3) {
            marker.frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 5) { content() }
        }
    }
}
