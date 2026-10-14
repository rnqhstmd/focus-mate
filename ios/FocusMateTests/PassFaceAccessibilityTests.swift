import CryptoKit
import SwiftUI
import UIKit
import XCTest
@testable import FocusMate

@MainActor
final class PassFaceAccessibilityTests: XCTestCase {
    func testDecorativeCardCompositionIsInvariantAtAccessibilityTextSize() throws {
        // Regression: inherited Dynamic Type enlarges the fixed card's lettering into overlap/clipping.
        // This component is one accessibility image; surrounding editor text must still scale.
        FontCatalog.register()
        let regular = try render(.large)
        let repeatedRegular = try render(.large)
        let accessibility = try render(.accessibility5)

        for (name, image) in [("large", regular), ("accessibility5", accessibility)] {
            let attachment = XCTAttachment(image: UIImage(cgImage: image))
            attachment.name = "PassFace fixed composition " + name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        let regularPixels = try rgbaPixels(regular)
        XCTAssertTrue(regularPixels.contains { $0 != 0 }, "A blank render cannot establish composition invariance")
        XCTAssertEqual(digest(regularPixels), digest(try rgbaPixels(repeatedRegular)),
                       "Repeated rendering at the same text size must be deterministic")
        XCTAssertEqual(accessibility.width, regular.width)
        XCTAssertEqual(accessibility.height, regular.height)
        XCTAssertEqual(digest(try rgbaPixels(accessibility)), digest(regularPixels),
                       "The fixed decorative card composition must stay identical from large to accessibility5")
    }

    private func render(_ textSize: DynamicTypeSize) throws -> CGImage {
        let content = PassFace(style: .standard)
            .environment(\.dynamicTypeSize, textSize)
            .environment(\.colorScheme, .dark)
            .environment(\.locale, Locale(identifier: "ko_KR"))
            .frame(width: 352, height: 221.1875)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 352, height: 221.1875)
        return try XCTUnwrap(renderer.cgImage, "The actual PassFace must render")
    }

    private func rgbaPixels(_ image: CGImage) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return Data(bytes)
    }

    private func digest(_ pixels: Data) -> String {
        SHA256.hash(data: pixels).map { String(format: "%02x", $0) }.joined()
    }
}
