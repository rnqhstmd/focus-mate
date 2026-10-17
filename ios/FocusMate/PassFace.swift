import SwiftUI

/// Shared saved or draft artwork. Editing affordances belong to the editor, never the saved card.
struct PassFace: View {
    static let aspectRatio: CGFloat = 352 / 221.1875
    static let referenceWidth: CGFloat = 352
    static let dotsAssetName = "PassDots"
    var style: CardStyle = .standard
    var dotsOpacity: Double = 0.85

    var body: some View {
        Color.clear
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .overlay { artwork.environment(\.dynamicTypeSize, .large).accessibilityHidden(true).allowsHitTesting(false) }
            .accessibilityElement()
            .accessibilityLabel(PassIdentity.displayName)
            .accessibilityAddTraits(.isImage)
            .allowsHitTesting(false)
    }

    private var artwork: some View {
        GeometryReader { proxy in
            let s = proxy.size.width / Self.referenceWidth
            let shape = RoundedRectangle(cornerRadius: 16 * s, style: .continuous)
            ZStack(alignment: .topLeading) {
                style.background.swiftUIColor
                if style.isStandard {
                    Image(Self.dotsAssetName).resizable().scaledToFit()
                        .frame(width: proxy.size.width * 0.78)
                        .opacity(dotsOpacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .offset(x: proxy.size.width * 0.12)
                    Text("Focus Mate").font(FontCatalog.text(11 * s, weight: .bold))
                        .offset(x: 20 * s, y: 17.2 * s)
                    Text(PassIdentity.displayName).font(FontCatalog.text(20 * s, weight: .bold))
                        .offset(x: 84.47 * s, y: 89.16 * s)
                    Text("나를 위한 시간, 한 장으로.").font(FontCatalog.text(9 * s))
                        .offset(x: 84.47 * s, y: 137.08 * s)
                }
                ForEach(style.photos) { photo in
                    if let image = UIImage(data: photo.data) {
                        Image(uiImage: image).resizable()
                            .frame(width: proxy.size.width * photo.widthFraction,
                                   height: proxy.size.width * photo.widthFraction * Double(photo.pixelHeight) / Double(photo.pixelWidth))
                            .position(x: proxy.size.width * photo.centerX, y: proxy.size.height * photo.centerY)
                    }
                }
                chip.frame(width: 40.68 * s, height: 30.68 * s)
                    .offset(x: 26.78 * s, y: 96.25 * s)
                Image(systemName: "wave.3.right").resizable().scaledToFit()
                    .frame(width: 18 * s, height: 22 * s)
                    .offset(x: 319 * s, y: 14.65 * s)
            }
            .foregroundStyle(.white)
            .clipShape(shape)
            .overlay(shape.stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private var chip: some View {
        GeometryReader { p in
            let w = p.size.width, h = p.size.height
            RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.77, green: 0.73, blue: 0.60))
                .overlay {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h / 3)); path.addLine(to: CGPoint(x: w, y: h / 3))
                        path.move(to: CGPoint(x: 0, y: h * 2 / 3)); path.addLine(to: CGPoint(x: w, y: h * 2 / 3))
                        path.move(to: CGPoint(x: w / 2, y: 0)); path.addLine(to: CGPoint(x: w / 2, y: h))
                        for x in [CGFloat(0), w] {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: w / 2, y: h / 2))
                            path.move(to: CGPoint(x: x, y: h)); path.addLine(to: CGPoint(x: w / 2, y: h / 2))
                        }
                    }.stroke(Color(red: 0.53, green: 0.50, blue: 0.39), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.77, green: 0.73, blue: 0.60))
                        .frame(width: w / 3, height: h / 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(red: 0.53, green: 0.50, blue: 0.39)))
                }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 0.53, green: 0.50, blue: 0.39), lineWidth: 1.5))
        }
    }
}
