# T5 PassFace accessibility composition RED

Status: **DONE / ASSERTION RED CONFIRMED / BUILD-TEST SLOT RELEASED**

## Scope and independent product oracle

The parent clarified that PassFace is a fixed decorative credit-card graphic, exposed as one accessibility image with the full card name. Its 352 × 221.1875 composition must remain identical and legible across Dynamic Type. Surrounding editor text/tools retain full Dynamic Type. The independently reviewed normal and XXXL screenshots show enlarged graphic lettering overlapping and clipping right at XXXL. The disputed layer-row delete clipping was not treated as confirmed or tested here.

New file only: `ios/FocusMateTests/PassFaceAccessibilityTests.swift`. Existing 19 locked test files were not edited; all 19 computed Git-blob SHA1 hashes equal the parent manifest `t5-test-hashes.json` after execution. No production file was read or edited. No implementation strings, layout formulas, mocks, stubs, or golden screenshot were used as expected values.

The test renders the actual `PassFace(style: .standard)` at the literal contract size, once at `.accessibility5` and twice at `.large`. Fixed dark color scheme and Korean locale remove unrelated environment variation. Scale=1 and RGBA/sRGB normalization remove provider/padding representation differences. SHA256 equality compares actual canonical pixel data without dumping hundreds of kilobytes into failure output. The second regular render is a determinism control, not a private expected image. The test retains both size outputs as native image attachments.

The observable failure mutation is inherited Dynamic Type scaling inside the fixed graphic. A fixed graphic whose pixels change solely with external text size must fail. This test is a component-level metamorphic invariant, not a whole-app snapshot. It does not independently establish graphic legibility at the baseline size, the accessibility image label, photo styles, or surrounding editor Dynamic Type; existing UI cases and direct visual/accessibility review retain those responsibilities.

Apple official API sources: [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer), [proposedSize](https://developer.apple.com/documentation/swiftui/imagerenderer/proposedsize), [scale](https://developer.apple.com/documentation/swiftui/imagerenderer/scale). ImageRenderer renders a SwiftUI view into bitmap data; proposedSize sets the root view proposal; scale is the point-to-pixel ratio. These sources support only the renderer mechanism, while the invariance oracle comes from the independently clarified product contract.

## Exact case and actual RED

Case: `FocusMateTests/PassFaceAccessibilityTests/testDecorativeCardCompositionIsInvariantAtAccessibilityTextSize`.

Execution log: DEV `t5-passface-accessibility-red.log`.

Command:

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=88EC0B32-40D7-4592-A34F-E09C051CECFA' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test \
  CODE_SIGNING_ALLOWED=NO -collect-test-diagnostics never \
  '-only-testing:FocusMateTests/PassFaceAccessibilityTests/testDecorativeCardCompositionIsInvariantAtAccessibilityTextSize'
```

Actual **exit65 / 1 test / 1 assertion failure / 0 unexpected**, 0.950 seconds. New test compiled; this is not a compiler-error RED. The same-size determinism control, nonblank check, and output width/height comparisons passed before the final comparison failed.

```text
PassFaceAccessibilityTests.swift:30: XCTAssertEqual failed:
("0d1357d5ecd678b8453b8128c54b48b3a421c0ca40cc330d56865442592abf94")
is not equal to
("9bf82852e3120288c7710698ce6d5ba0b5fa829ef6ebbbfa949fb00ab8333657")
The fixed decorative card composition must stay identical from large to accessibility5
Executed 1 test, with 1 failure (0 unexpected)
** TEST FAILED **
```

Result bundle: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-34-57-+0900.xcresult`. Both component images are retained there. Existing font-registration diagnostic messages were emitted because the app had already registered the same fonts; they were not test failures.

New-file SHA256: `ac1e87497640ae2892c13b9ac35da1c61eef7b1613bb1112d6ac3ba9b9c786c4`.
New-file Git-blob SHA1: `28390c0ddba5b2414bfc94ca43935f24c779f4e1`.

Owned26.5 simulator only was booted, without erase. Disk check showed 62GiB free. One build/test ran; no other simulator, app-data reset, worktree or Git action occurred. All logs/results remain available. Build/test slot is released and no child process remains active. Parent can hand this RED case and hash to the source executor for a bounded graphic-only fix; surrounding editor/body/tools must continue scaling.

## Complete test source

```swift
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
```

References read: role `agents/red-writer.md`; supplied production declarations only; parent clarification; normal/XXXL final screenshot images; Apple renderer API documentation; locked test hash manifest and existing test bytes solely for hash verification. Production source not read.
