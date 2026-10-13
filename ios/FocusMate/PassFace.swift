import SwiftUI

/// 발급·승하차·마이페이지가 함께 쓰는 기본 카드(pass-face). 놓인 폭을 채우고 내부는 기준 폭 238 대비 배율로 그린다.
/// 카드 번호는 그리지 않는다. 식별자(`card.face`)는 호출하는 쪽이 붙인다.
struct PassFace: View {
    static let aspectRatio: CGFloat = 85.6 / 53.98
    static let referenceWidth: CGFloat = 238
    static let dotsAssetName = "PassDots"

    init() {}

    var body: some View {
        // 접근성은 바깥 한 요소(이름 + 이미지 특성)만 노출한다. GeometryReader 쪽 children: .ignore는
        // 내부 장식을 숨기지 못해, 그림 전체를 숨긴 overlay로 두고 빈 바탕을 접근성 요소로 쓴다.
        Color.clear
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay { artwork.accessibilityHidden(true) }
            .accessibilityElement()
            .accessibilityLabel(PassIdentity.displayName)
            .accessibilityAddTraits(.isImage)
    }

    private var artwork: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Self.referenceWidth
            let shape = RoundedRectangle(cornerRadius: 16 * scale, style: .continuous)
            ZStack(alignment: .topLeading) {
                Color(red: 0x12 / 255, green: 0x14 / 255, blue: 0x16 / 255)
                Image(Self.dotsAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width * 0.78)
                    .opacity(0.85)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: proxy.size.width * 0.12)
                Text("Focus Mate")
                    .font(.system(size: 10 * scale, weight: .semibold))
                    .tracking(1 * scale)
                    .offset(x: 20 * scale, y: 17 * scale)
                Image(systemName: "wave.3.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22 * scale, height: 22 * scale)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 12 * scale)
                    .padding(.trailing, 16 * scale)
                RoundedRectangle(cornerRadius: 3 * scale, style: .continuous)
                    .fill(Color(red: 0xc5 / 255, green: 0xb9 / 255, blue: 0x98 / 255))
                    .frame(width: proxy.size.width * 0.12, height: proxy.size.height * 0.15)
                    .offset(x: proxy.size.width * 0.075, y: proxy.size.height * 0.43)
                Text(PassIdentity.displayName)
                    .font(.system(size: 19 * scale, weight: .semibold))
                    .offset(x: 20 * scale, y: proxy.size.height - 44 * scale)
            }
            .foregroundStyle(Color(red: 0xf1 / 255, green: 0xf2 / 255, blue: 0xf3 / 255))
            .clipShape(shape)
            .overlay(shape.stroke(Color(red: 0x51 / 255, green: 0x56 / 255, blue: 0x5a / 255), lineWidth: 1))
        }
    }
}
