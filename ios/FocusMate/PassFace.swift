import SwiftUI

/// Shared saved or draft artwork. Editing affordances belong to the editor, never the saved card.
/// 시안(R27·R38 등)에는 서울 점지도가 없고, 모든 카드 왼쪽 아래에 카드 번호가 있다(BR-4는 시안 우선으로 변경).
struct PassFace: View {
    /// 요소 배치 기준. 시안은 화면마다 카드 비율과 글자 위치를 따로 정해 두었다.
    struct Layout: Equatable {
        let referenceWidth: CGFloat
        let aspectRatio: CGFloat
        let cornerRadius: CGFloat
        let brand: CGPoint
        let title: CGPoint
        let subtitle: CGPoint
        let number: CGPoint
        let chip: CGRect
        let wave: CGRect
        /// 글자 크기(referenceWidth 기준). 발급 화면은 카드가 작아도 글자를 줄이지 않는다(R36·R37).
        var brandSize: CGFloat = 10
        var titleSize: CGFloat = 18
        var subtitleSize: CGFloat = 9
        var numberSize: CGFloat = 7

        /// 마이페이지·발급·꾸미기(352 x 221).
        static let wide = Layout(referenceWidth: 352, aspectRatio: 352 / 221.1875, cornerRadius: 16,
                                 brand: CGPoint(x: 20, y: 17), title: CGPoint(x: 84.47, y: 89.16),
                                 subtitle: CGPoint(x: 84.47, y: 137.08), number: CGPoint(x: 20, y: 198),
                                 chip: CGRect(x: 26.78, y: 96.25, width: 40.68, height: 30.68),
                                 wave: CGRect(x: 320, y: 15, width: 12, height: 19))
        /// 승차·하차 태그(R27·R12·R42·R28·R29, 270 x 158).
        static let ticket = Layout(referenceWidth: 270, aspectRatio: 270 / 158, cornerRadius: 14,
                                   brand: CGPoint(x: 21, y: 18), title: CGPoint(x: 65, y: 64),
                                   subtitle: CGPoint(x: 65, y: 98), number: CGPoint(x: 21, y: 134),
                                   chip: CGRect(x: 22, y: 69, width: 30, height: 22),
                                   wave: CGRect(x: 236, y: 16, width: 12, height: 19))
        /// 카드 발급(R36·R37, 292 x 184). 제목 23·부제 10·번호 8pt로 같은 카드보다 글자가 크다.
        static let issue = Layout(referenceWidth: 292, aspectRatio: 292 / 184, cornerRadius: 16,
                                  brand: CGPoint(x: 21, y: 18), title: CGPoint(x: 71, y: 76),
                                  subtitle: CGPoint(x: 71, y: 114), number: CGPoint(x: 21, y: 157),
                                  chip: CGRect(x: 24, y: 81, width: 34, height: 25),
                                  wave: CGRect(x: 258, y: 15, width: 12, height: 19),
                                  titleSize: 23, subtitleSize: 10, numberSize: 8)
    }

    static let aspectRatio: CGFloat = Layout.wide.aspectRatio
    static let referenceWidth: CGFloat = Layout.wide.referenceWidth
    /// 예전 점지도 에셋 이름. 시안에서 빠져 더는 그리지 않는다(에셋은 남겨 둠).
    static let dotsAssetName = "PassDots"
    static let textColor = Color(hex: 0xF1F2F3)
    static let strokeColor = Color(hex: 0x51565A)
    static let chipFill = Color(hex: 0xC5B998)
    static let chipStroke = Color(hex: 0x80775D)

    var style: CardStyle = .standard
    var layout: Layout = .wide
    /// "FM · 0842 3017". 없으면(발급 전) 번호 줄을 그리지 않는다.
    var numberText: String? = nil

    var body: some View {
        Color.clear
            .aspectRatio(layout.aspectRatio, contentMode: .fit)
            .overlay { artwork.environment(\.dynamicTypeSize, .large).accessibilityHidden(true).allowsHitTesting(false) }
            .accessibilityElement()
            .accessibilityLabel(PassIdentity.displayName)
            .accessibilityAddTraits(.isImage)
            .allowsHitTesting(false)
    }

    private var artwork: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / layout.referenceWidth
            let shape = RoundedRectangle(cornerRadius: layout.cornerRadius * s, style: .continuous)
            ZStack(alignment: .topLeading) {
                style.background.swiftUIColor
                if style.isStandard {
                    Text(PassIdentity.displayName).font(FontCatalog.text(layout.titleSize * s, weight: .bold))
                        .offset(x: layout.title.x * s, y: Self.frameTop(glyphTop: layout.title.y * s, size: layout.titleSize * s))
                    Text("나를 위한 시간, 한 장으로.").font(FontCatalog.text(layout.subtitleSize * s))
                        .offset(x: layout.subtitle.x * s, y: Self.frameTop(glyphTop: layout.subtitle.y * s, size: layout.subtitleSize * s))
                }
                ForEach(style.photos) { photo in
                    if let image = UIImage(data: photo.data) {
                        Image(uiImage: image).resizable()
                            .frame(width: proxy.size.width * photo.widthFraction,
                                   height: proxy.size.width * photo.widthFraction * Double(photo.pixelHeight) / Double(photo.pixelWidth))
                            .position(x: proxy.size.width * photo.centerX, y: proxy.size.height * photo.centerY)
                    }
                }
                label("Focus Mate", size: layout.brandSize * s, weight: .bold, at: layout.brand, pillTop: layout.brand.y, scale: s)
                if let numberText {
                    label(numberText, size: layout.numberSize * s, weight: .regular, at: layout.number, pillTop: layout.number.y - 4, scale: s)
                }
                chip.frame(width: layout.chip.width * s, height: layout.chip.height * s)
                    .offset(x: layout.chip.minX * s, y: layout.chip.minY * s)
                Image(systemName: "wave.3.right").resizable().scaledToFit()
                    .frame(width: layout.wave.width * s, height: layout.wave.height * s)
                    .foregroundStyle(style.isStandard ? Color(hex: 0xD5DED7) : .white)
                    .offset(x: layout.wave.minX * s, y: layout.wave.minY * s)
            }
            .foregroundStyle(Self.textColor)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Self.strokeColor, lineWidth: 1))
        }
    }

    /// 기본 카드는 글자만, 꾸민 카드는 사진 위에서도 읽히도록 어두운 알약(#080B0C 80%) 위에 둔다.
    @ViewBuilder
    private func label(_ text: String, size: CGFloat, weight: FMFontWeight, at point: CGPoint, pillTop: CGFloat,
                       scale s: CGFloat) -> some View {
        if style.isStandard {
            Text(text).font(FontCatalog.text(size, weight: weight))
                .offset(x: point.x * s, y: Self.frameTop(glyphTop: point.y * s, size: size))
        } else {
            // 시안 알약: Focus Mate 70x16(위 = brand.y), 번호 65x12(위 = number.y - 4).
            Text(text).font(FontCatalog.text(size, weight: weight)).foregroundStyle(Color(hex: 0xD3D6D8))
                .padding(.horizontal, 5 * s).padding(.vertical, 0.8 * s)
                .background(Color(hex: 0x080B0C).opacity(0.8), in: RoundedRectangle(cornerRadius: 3 * s))
                .offset(x: point.x * s, y: pillTop * s)
        }
    }

    /// 시안 좌표는 글자 상자(줄 높이 = 글자 크기) 위끝이다. Noto Sans KR 줄 높이는 1.448배라 프레임 위끝을 그만큼 올린다.
    static func frameTop(glyphTop: CGFloat, size: CGFloat) -> CGFloat {
        glyphTop - size * 0.224
    }

    private var chip: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            RoundedRectangle(cornerRadius: 6).fill(Self.chipFill)
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h / 3)); path.addLine(to: CGPoint(x: w, y: h / 3))
                        path.move(to: CGPoint(x: 0, y: h * 2 / 3)); path.addLine(to: CGPoint(x: w, y: h * 2 / 3))
                        path.move(to: CGPoint(x: w / 2, y: 0)); path.addLine(to: CGPoint(x: w / 2, y: h))
                        for x in [CGFloat(0), w] {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: w / 2, y: h / 2))
                            path.move(to: CGPoint(x: x, y: h)); path.addLine(to: CGPoint(x: w / 2, y: h / 2))
                        }
                    }.stroke(Self.chipStroke, lineWidth: 1)
                    RoundedRectangle(cornerRadius: 3).fill(Self.chipFill)
                        .frame(width: w / 3, height: h / 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Self.chipStroke))
                }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Self.chipStroke, lineWidth: 1.5))
        }
    }
}
