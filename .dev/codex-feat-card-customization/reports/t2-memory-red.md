# I-1 memory regression RED handoff

Status: DONE_WITH_CONCERNS — test authoring complete; compilation, execution, platform reference, and RED confirmation pending parent execution. No build/test/compiler execution performed. No production/review file read or edit; existing tests unchanged. No agents, commit, or push.

## Failure named before implementation

Extra original full decode after a bounded thumbnail increases RSS despite a normal compressed input. No source detectors, production instrumentation, or test doubles. The 8192 production test fixes a provisional literal RSS-growth ceiling of 134,217,728 bytes. It also verifies successful 2048×2048 output ≤1,048,576 bytes and independently sampled sRGB color approximately (220,40,80), tolerance 8 per channel, opaque alpha. Separate 4096 production diagnostic verifies successful output with no memory bound.

## Parent execution and classification

Run each selector separately with the parent's established project/scheme/destination arguments, in a fresh xcodebuild test process (and verify a fresh test-host PID). Do not run this suite as a batch or reuse a warmed host. Independent thumbnail-only reference must be measured before interpreting the provisional production assertion.

```sh
xcodebuild test <parent project/scheme/destination arguments> -only-testing:FocusMateTests/CardPhotoMemoryTests/testI1_ImageIOThumbnailOnly8192_memoryDiagnostic
xcodebuild test <parent project/scheme/destination arguments> -only-testing:FocusMateTests/CardPhotoMemoryTests/testI1_FirstProduction8192_preservesImageWithinProvisional128MiBRSSGrowth
xcodebuild test <parent project/scheme/destination arguments> -only-testing:FocusMateTests/CardPhotoMemoryTests/testI1_FirstProduction4096_memoryDiagnosticAndSuccessfulOutput
```

Failure message: NOT EXECUTED; none captured. No claim of RED. A compile error is test-authoring failure, not RED. A successful production run does not prove absence of transient peaks. A provisional resource assertion failure requires comparison against the independent reference. If independent ImageIO thumbnail-only RSS growth intrinsically exceeds 128MiB, report NEEDS_CONTEXT: do not raise the ceiling to obtain PASS or change the product's 2048 pixel cap. Retain reference and production logs, SDK/runtime/device and host PID.

## Fixture provenance

User/parent supplied own, normal lossless WebP fixtures. Parent reports full Pillow decoding and RGB(220,40,80) validation for both; this author did not redo a large-original decode. Author inspected RIFF/WEBP/VP8L prefix bytes, recorded hashes, and verified inline base64 decodes byte-for-byte to the own files. No malformed/corrupted input or absolute runtime resource path is embedded.

| Input | Bytes | SHA-256 |
|---|---:|---|
| `.dev/codex-feat-card-customization/memory-probe/own-red-8192.webp` | 2630 | `9b61e47e82b95b370da907325cd09cb2a44bd6c5ea4c1c44ca0b5d68bae8bc8a` |
| `.dev/codex-feat-card-customization/memory-probe/own-red-4096.webp` | 706 | `f5b9390e4e2ebedc837957d7d227921e8155379829d4e12fd28b972fb6107cc5` |

## Measurement scope and caveats

- Production measured interval encloses only the first `ImageIOCardPhotoProcessor().process(input)` call plus test-side baseline/endpoint/sampler lifecycle overhead. Input base64 decoding and processor construction precede baseline. No processor warmup and no large-original predecode; small-output verification follows sampler cancellation and join.
- Independent reference directly creates a source without caching and uses ImageIO ThumbnailAlways, MaxPixelSize=2048, WithTransform, ShouldCache/ShouldCacheImmediately=true. It has no resource assertion. Its measured interval includes source/thumbnail creation and autoreleasepool teardown. Small draw/color assertions follow measurement.
- Dedicated serial DispatchSourceTimer requests ~1ms with zero leeway; scheduling cannot guarantee this interval. Sampled RSS peak is a lower bound. RSS is process-wide, includes unrelated test host activity, and is not physical footprint.
- TASK_VM_INFO records baseline RSS, maximum successful sampled RSS, endpoint RSS, physical footprint before/after, kernel resident peak before/after, successful timer sample count, and all sampling errors. Kernel peak is process-lifetime and cannot be reset; it is diagnostic only, not a measured interval budget. Growth uses max(sampled RSS, baseline RSS, endpoint RSS) minus baseline.
- TASK_VM_INFO failure or missing physical-footprint fields throws for endpoints; timer errors are recorded and asserted absent. Zero timer samples is an explicit evidence failure. There is no resource-read-error-to-zero fallback.
- NSLock protects recorder state. Timer owns recorder until cancellation; cancel handler signals a DispatchGroup; caller waits for in-flight callbacks/cancel completion, then clears handlers. Lifecycle is single measuring caller, outside the timer queue. Error paths also cancel and join.
- No compile/test evidence yet. Parent must validate Swift SDK import signatures and runtime behavior before classifying RED.

## References read

- `.dev/codex-feat-card-customization/design.md` (public processing contract, thumbnail/storage policies)
- `.dev/codex-feat-card-customization/prd.md` (W10 image acceptance criteria)
- `ios/FocusMateTests/CardPhotoProcessorTests.swift` (XCTest/import/color-output conventions)
- `ios/FocusMateTests/CardPhotoMemoryTests.swift` (newly authored test; inline integrity verification/report inclusion)
- The two own WebP files above
- `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator27.0.sdk/usr/include/mach/task_info.h`
- Same SDK `usr/include/mach/task.h` and `usr/include/mach/mach_init.h`
- Same SDK `System/Library/Frameworks/ImageIO.framework/Headers/CGImageSource.h`
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md` (environment startup instruction; its dispatched-specific-task exception applies)

SDK-header APIs examined: TASK_VM_INFO, task_vm_info_data_t resident_size/resident_size_peak/phys_footprint and revision counts; task_info and mach_task_self_; CGImageSourceShouldCache/ShouldCacheImmediately and thumbnail creation keys/function. No existing production implementation or review artifact was read. File-name inventory used rg only; no project-memory file used.

## Complete authored test

```swift
import Foundation
import CoreGraphics
import Darwin
import Dispatch
import ImageIO
import XCTest
@testable import FocusMate

final class CardPhotoMemoryTests: XCTestCase {
    // Diagnostic reference only: ImageIO's own WebP thumbnail decoder may exceed
    // the provisional budget. Run separately in a fresh test process first.
    func testI1_ImageIOThumbnailOnly8192_memoryDiagnostic() throws {
        let input = try fixture(Self.webp8192)
        let sampler = try MemorySampler()
        let thumbnail: CGImage
        let measurement: MemoryMeasurement
        do {
            thumbnail = try autoreleasepool {
                let source = try XCTUnwrap(CGImageSourceCreateWithData(input as CFData,
                    [kCGImageSourceShouldCache: false] as CFDictionary))
                return try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2048,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCache: true,
                    kCGImageSourceShouldCacheImmediately: true
                ] as CFDictionary))
            }
            measurement = try sampler.finish()
        } catch {
            sampler.cancelAndWait()
            throw error
        }
        print(measurement.description(label: "ImageIO-thumbnail-only-8192"))
        assertReliable(measurement)
        XCTAssertEqual(thumbnail.width, 2048)
        XCTAssertEqual(thumbnail.height, 2048)
        // Small draw forces observable valid pixels AFTER memory measurement.
        assertSourceColor(try sampledRGBA(thumbnail))
    }

    // 깨짐 명명: bounded thumbnail 이후 원본 전체를 추가 decode하면 정상 압축
    // 입력에서도 RSS growth가 증가한다. This budget remains PROVISIONAL until
    // the independent platform reference above has been measured.
    func testI1_FirstProduction8192_preservesImageWithinProvisional128MiBRSSGrowth() async throws {
        let input = try fixture(Self.webp8192)
        // No large-original decode and no processor warmup before this first call.
        let (result, measurement) = try await measuredProcess(input)
        print(measurement.description(label: "production-first-8192-provisional"))
        assertReliable(measurement)
        XCTAssertLessThanOrEqual(measurement.sampledRSSGrowth, 134_217_728,
            "Provisional 128MiB: if independent thumbnail-only exceeds this, report NEEDS_CONTEXT; do not relax to PASS.")
        try assertOutput(result)
    }

    // Diagnostic success at a smaller input size; no memory-bound assertion.
    // 깨짐 명명: empty output / wrong dimensions / replaced color fails this case.
    func testI1_FirstProduction4096_memoryDiagnosticAndSuccessfulOutput() async throws {
        let input = try fixture(Self.webp4096)
        let (result, measurement) = try await measuredProcess(input)
        print(measurement.description(label: "production-first-4096-diagnostic"))
        assertReliable(measurement)
        try assertOutput(result)
    }

    private func measuredProcess(_ input: Data) async throws -> (ProcessedCardPhoto, MemoryMeasurement) {
        let processor = ImageIOCardPhotoProcessor()
        let sampler = try MemorySampler()
        do {
            let result = try await processor.process(input)
            let measurement = try sampler.finish()
            return (result, measurement)
        } catch {
            sampler.cancelAndWait()
            throw error
        }
    }

    private func assertReliable(_ measurement: MemoryMeasurement,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThan(measurement.timerSampleCount, 0,
            "No timer samples: memory evidence is insufficient", file: file, line: line)
        XCTAssertTrue(measurement.errors.isEmpty,
            "TASK_VM_INFO sampling errors: \(measurement.errors)", file: file, line: line)
    }

    private func assertOutput(_ result: ProcessedCardPhoto) throws {
        XCTAssertEqual(result.pixelWidth, 2048)
        XCTAssertEqual(result.pixelHeight, 2048)
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        // Decode only the small output, after the sampler has stopped and joined.
        let source = try XCTUnwrap(CGImageSourceCreateWithData(result.data as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0,
            [kCGImageSourceShouldCacheImmediately: true] as CFDictionary))
        XCTAssertEqual(image.width, 2048)
        XCTAssertEqual(image.height, 2048)
        assertSourceColor(try sampledRGBA(image))
    }

    private func sampledRGBA(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4,
                space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
                    CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes
    }

    private func assertSourceColor(_ rgba: [UInt8]) {
        XCTAssertEqual(Double(rgba[0]), 220, accuracy: 8)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 8)
        XCTAssertEqual(Double(rgba[2]), 80, accuracy: 8)
        XCTAssertEqual(rgba[3], 255)
    }

    private func fixture(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64, options: .ignoreUnknownCharacters))
    }

    // Own lossless WebP fixtures; parent independently verified full Pillow
    // decode and RGB(220, 40, 80). No runtime filesystem/resource dependencies.
    private static let webp8192 = """
    UklGRj4KAABXRUJQVlA4TDIKAAAv/9//BwdQlHIXqv9BExIk+H+7PSISfUFAkvT/fxjR/wQKxN9/FBEZ//nvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//+85///Oc///nP
    f/7zn//85z//+c9//vOf//znP//5z3/+85///Oc///nPf/7zn//85z//+c9//vOf//znP//5z3/+85///Oc///nPf/7zn//85z//
    +c///QM=
    """
    private static let webp4096 = """
    UklGRroCAABXRUJQVlA4TK0CAAAv/8//AwdQlHIXqv9hLCFBgv+32yMi0VtMmqx/ey8hov8TACTJ//9BiIiQ//7z33///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff/8BAA==
    """
}

private struct MemorySnapshot: Sendable {
    let rss: UInt64
    let physicalFootprint: UInt64
    let kernelLifetimePeakRSS: UInt64

    static func read() throws -> MemorySnapshot {
        var info = task_vm_info_data_t()
        let capacity = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        var count = mach_msg_type_number_t(capacity)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: capacity) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { throw MemoryProbeError.taskInfo(status) }
        // REV1 contains physical footprint. Never silently read absent fields as 0.
        let footprintEnd = MemoryLayout<task_vm_info_data_t>.offset(of: \.phys_footprint)! +
            MemoryLayout.size(ofValue: info.phys_footprint)
        guard Int(count) * MemoryLayout<integer_t>.size >= footprintEnd else {
            throw MemoryProbeError.shortTaskInfo(count)
        }
        return MemorySnapshot(rss: UInt64(info.resident_size),
            physicalFootprint: UInt64(info.phys_footprint),
            kernelLifetimePeakRSS: UInt64(info.resident_size_peak))
    }
}

private enum MemoryProbeError: Error {
    case taskInfo(kern_return_t)
    case shortTaskInfo(mach_msg_type_number_t)
}

private struct MemoryMeasurement: Sendable {
    let before: MemorySnapshot
    let after: MemorySnapshot
    let maximumSampleRSS: UInt64
    let timerSampleCount: Int
    let errors: [String]

    var sampledRSSGrowth: UInt64 {
        maximumSampleRSS >= before.rss ? maximumSampleRSS - before.rss : 0
    }

    func description(label: String) -> String {
        "MEMORY_PROBE \(label) baselineRSS=\(before.rss) maxSampleRSS=\(maximumSampleRSS) " +
        "sampledRSSGrowth=\(sampledRSSGrowth) afterRSS=\(after.rss) " +
        "physFootprintBefore=\(before.physicalFootprint) physFootprintAfter=\(after.physicalFootprint) " +
        "kernelLifetimePeakRSSBefore=\(before.kernelLifetimePeakRSS) " +
        "kernelLifetimePeakRSSAfter=\(after.kernelLifetimePeakRSS) " +
        "timerSampleCount=\(timerSampleCount) errors=\(errors) " +
        "sampledPeakIsLowerBound=true kernelPeakIsNotResettable=true"
    }
}

// @unchecked Sendable is confined to this recorder: all mutable sample state is
// protected by NSLock. The serial queue orders callbacks; cancellation is joined
// before reading a report or releasing the timer's strong capture of self.
private final class MemorySampler: @unchecked Sendable {
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "FocusMateTests.CardPhotoMemorySampler", qos: .userInitiated)
    private let cancellation = DispatchGroup()
    private let timer: DispatchSourceTimer
    private let before: MemorySnapshot
    private var maximumSampleRSS: UInt64
    private var timerSampleCount = 0
    private var errors: [String] = []

    init() throws {
        before = try MemorySnapshot.read()
        maximumSampleRSS = before.rss
        timer = DispatchSource.makeTimerSource(queue: queue)
        cancellation.enter()
        let completion = cancellation
        timer.setCancelHandler { completion.leave() }
        timer.setEventHandler { [self] in sample() }
        timer.schedule(deadline: .now(), repeating: .milliseconds(1), leeway: .nanoseconds(0))
        timer.resume()
    }

    private func sample() {
        do {
            let snapshot = try MemorySnapshot.read()
            lock.lock()
            maximumSampleRSS = max(maximumSampleRSS, snapshot.rss)
            timerSampleCount += 1
            lock.unlock()
        } catch {
            lock.lock()
            errors.append(String(describing: error))
            lock.unlock()
        }
    }

    // Only the test's measuring caller invokes lifecycle methods, never the
    // timer queue. Cancel + group wait drains any in-flight callback.
    func cancelAndWait() {
        timer.cancel()
        cancellation.wait()
        timer.setEventHandler {}
        timer.setCancelHandler {}
    }

    func finish() throws -> MemoryMeasurement {
        let after: MemorySnapshot
        do {
            after = try MemorySnapshot.read()
        } catch {
            cancelAndWait()
            throw error
        }
        cancelAndWait()
        lock.lock()
        defer { lock.unlock() }
        return MemoryMeasurement(before: before, after: after,
            maximumSampleRSS: max(maximumSampleRSS, after.rss),
            timerSampleCount: timerSampleCount, errors: errors)
    }
}
```


## Pre-production RED fixture-budget correction (2026-10-14)

Status: DONE_WITH_CONCERNS — requested technical fixture-budget correction authored. Actual production RED has NOT BEEN EXECUTED, per parent dispatch. No production assertion failure preceded this correction; no assertion was relaxed after failure. Earlier provisional budget, selector, and embedded test listing above are historical and superseded by this appendix.

### Why the initial 128MiB candidate is invalid

The independent thumbnail-only reference passed for the same normal 8192 WebP input in a fresh iOS 26.5 process, as reported by the parent. Read-only log inspection confirms `sampledRSSGrowth=300236800` bytes (approximately 286MiB), `timerSampleCount=744`, `errors=[]`, and one test with zero failures. Baseline RSS was 283295744, sampled maximum 583532544, and kernel lifetime peak after 583581696; the kernel peak corroborates the sampled maximum but is not an interval-resettable assertion metric. The macOS thumbnail-only control separately records `kernelPeakGrowth=335642624` bytes; this is a different platform/metric and is supporting context, not the iOS sampled-RSS baseline.

ImageIO's independent thumbnail-only path itself exceeds 134217728 bytes. That candidate cannot distinguish redundant original decoding from the platform's necessary processing of this fixture. The budget is corrected BEFORE any actual production assertion to literal `402653184` bytes (384MiB): measured iOS baseline of approximately 286MiB plus approximately 98MiB for bounded 2048 output, a 16MiB context, and encoding/readback caches. This is a fixture/environment-specific regression budget, not a global limit for all formats or devices, and is not calibrated to a production failure or pass.

### Final test contract and parent handoff

- Selector: `testI1_FirstProduction8192_preservesImageWithoutRedundantOriginalDecodeWithin384MiB`.
- Strict inclusive assertion: `XCTAssertLessThanOrEqual(measurement.sampledRSSGrowth, 402653184, ...)`.
- Same 8192 input and measurement lifecycle; all output, color, sampling/error assertions are unchanged, including the 4096 diagnostic.
- Failure named: an additional full original decode after bounded thumbnail processing increases RSS and can exceed this fixture budget. No new production code, instrumentation, or mocks.
- Only the test file was edited and this report appended. No tests, builds, compiler, agents, commit, or push were invoked. Actual RED assertion remains pending parent execution; no failure message exists yet.

Parent command (documented only; NOT EXECUTED by this author):

```sh
xcodebuild test <parent project/scheme/destination arguments> -only-testing:FocusMateTests/CardPhotoMemoryTests/testI1_FirstProduction8192_preservesImageWithoutRedundantOriginalDecodeWithin384MiB
```

Run in a fresh test-host process using the parent's established iOS 26.5 destination. Preserve the actual production log and classify its result after execution. A compile error is test-authoring failure, not RED; sampled peaks remain lower bounds.

### Files read for this correction

- `ios/FocusMateTests/CardPhotoMemoryTests.swift`
- `reports/t2-memory-red.md`
- `.dev/codex-feat-card-customization/t2-memory-platform-control.log` (selected measurement/result/runtime lines only)
- `.dev/codex-feat-card-customization/memory-probe/mac-control.log`
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md` (startup instruction; dispatched-specific-task exception)

No production implementation was read or edited. File inventory used `rg --files`; no project-memory file used.

### Complete test after correction (supersedes earlier listing)

```swift
import Foundation
import CoreGraphics
import Darwin
import Dispatch
import ImageIO
import XCTest
@testable import FocusMate

final class CardPhotoMemoryTests: XCTestCase {
    // Diagnostic reference only: measure ImageIO's own WebP thumbnail decoder
    // separately in a fresh test process before the production regression test.
    func testI1_ImageIOThumbnailOnly8192_memoryDiagnostic() throws {
        let input = try fixture(Self.webp8192)
        let sampler = try MemorySampler()
        let thumbnail: CGImage
        let measurement: MemoryMeasurement
        do {
            thumbnail = try autoreleasepool {
                let source = try XCTUnwrap(CGImageSourceCreateWithData(input as CFData,
                    [kCGImageSourceShouldCache: false] as CFDictionary))
                return try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2048,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCache: true,
                    kCGImageSourceShouldCacheImmediately: true
                ] as CFDictionary))
            }
            measurement = try sampler.finish()
        } catch {
            sampler.cancelAndWait()
            throw error
        }
        print(measurement.description(label: "ImageIO-thumbnail-only-8192"))
        assertReliable(measurement)
        XCTAssertEqual(thumbnail.width, 2048)
        XCTAssertEqual(thumbnail.height, 2048)
        // Small draw forces observable valid pixels AFTER memory measurement.
        assertSourceColor(try sampledRGBA(thumbnail))
    }

    // 깨짐 명명: bounded thumbnail 이후 원본 전체를 추가 decode하면 정상 압축
    // 입력에서도 RSS growth가 증가한다. Fixture/environment-specific 384MiB budget:
    // fresh iOS 26.5 thumbnail-only measured ~286MiB, plus ~98MiB for bounded
    // 2048 output, a 16MiB context, and encoding/readback caches. This is not
    // a global memory limit for all image formats. Set before production RED execution.
    func testI1_FirstProduction8192_preservesImageWithoutRedundantOriginalDecodeWithin384MiB() async throws {
        let input = try fixture(Self.webp8192)
        // No large-original decode and no processor warmup before this first call.
        let (result, measurement) = try await measuredProcess(input)
        print(measurement.description(label: "production-first-8192-384MiB"))
        assertReliable(measurement)
        XCTAssertLessThanOrEqual(measurement.sampledRSSGrowth, 402653184,
            "8192 WebP fixture on the measured environment must stay within 384MiB RSS growth without redundant original decode; this is not an all-formats limit.")
        try assertOutput(result)
    }

    // Diagnostic success at a smaller input size; no memory-bound assertion.
    // 깨짐 명명: empty output / wrong dimensions / replaced color fails this case.
    func testI1_FirstProduction4096_memoryDiagnosticAndSuccessfulOutput() async throws {
        let input = try fixture(Self.webp4096)
        let (result, measurement) = try await measuredProcess(input)
        print(measurement.description(label: "production-first-4096-diagnostic"))
        assertReliable(measurement)
        try assertOutput(result)
    }

    private func measuredProcess(_ input: Data) async throws -> (ProcessedCardPhoto, MemoryMeasurement) {
        let processor = ImageIOCardPhotoProcessor()
        let sampler = try MemorySampler()
        do {
            let result = try await processor.process(input)
            let measurement = try sampler.finish()
            return (result, measurement)
        } catch {
            sampler.cancelAndWait()
            throw error
        }
    }

    private func assertReliable(_ measurement: MemoryMeasurement,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThan(measurement.timerSampleCount, 0,
            "No timer samples: memory evidence is insufficient", file: file, line: line)
        XCTAssertTrue(measurement.errors.isEmpty,
            "TASK_VM_INFO sampling errors: \(measurement.errors)", file: file, line: line)
    }

    private func assertOutput(_ result: ProcessedCardPhoto) throws {
        XCTAssertEqual(result.pixelWidth, 2048)
        XCTAssertEqual(result.pixelHeight, 2048)
        XCTAssertFalse(result.data.isEmpty)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        // Decode only the small output, after the sampler has stopped and joined.
        let source = try XCTUnwrap(CGImageSourceCreateWithData(result.data as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0,
            [kCGImageSourceShouldCacheImmediately: true] as CFDictionary))
        XCTAssertEqual(image.width, 2048)
        XCTAssertEqual(image.height, 2048)
        assertSourceColor(try sampledRGBA(image))
    }

    private func sampledRGBA(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4,
                space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
                    CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return bytes
    }

    private func assertSourceColor(_ rgba: [UInt8]) {
        XCTAssertEqual(Double(rgba[0]), 220, accuracy: 8)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 8)
        XCTAssertEqual(Double(rgba[2]), 80, accuracy: 8)
        XCTAssertEqual(rgba[3], 255)
    }

    private func fixture(_ base64: String) throws -> Data {
        try XCTUnwrap(Data(base64Encoded: base64, options: .ignoreUnknownCharacters))
    }

    // Own lossless WebP fixtures; parent independently verified full Pillow
    // decode and RGB(220, 40, 80). No runtime filesystem/resource dependencies.
    private static let webp8192 = """
    UklGRj4KAABXRUJQVlA4TDIKAAAv/9//BwdQlHIXqv9BExIk+H+7PSISfUFAkvT/fxjR/wQKxN9/FBEZ//nvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777//
    /vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//++++///7777///vvvv//+85///Oc///nP
    f/7zn//85z//+c9//vOf//znP//5z3/+85///Oc///nPf/7zn//85z//+c9//vOf//znP//5z3/+85///Oc///nPf/7zn//85z//
    +c///QM=
    """
    private static let webp4096 = """
    UklGRroCAABXRUJQVlA4TK0CAAAv/8//AwdQlHIXqv9hLCFBgv+32yMi0VtMmqx/ey8hov8TACTJ//9BiIiQ//7z33///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9999///3333///ffff//9
    999///3333///ffff//9999///3333///ffff/8BAA==
    """
}

private struct MemorySnapshot: Sendable {
    let rss: UInt64
    let physicalFootprint: UInt64
    let kernelLifetimePeakRSS: UInt64

    static func read() throws -> MemorySnapshot {
        var info = task_vm_info_data_t()
        let capacity = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        var count = mach_msg_type_number_t(capacity)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: capacity) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { throw MemoryProbeError.taskInfo(status) }
        // REV1 contains physical footprint. Never silently read absent fields as 0.
        let footprintEnd = MemoryLayout<task_vm_info_data_t>.offset(of: \.phys_footprint)! +
            MemoryLayout.size(ofValue: info.phys_footprint)
        guard Int(count) * MemoryLayout<integer_t>.size >= footprintEnd else {
            throw MemoryProbeError.shortTaskInfo(count)
        }
        return MemorySnapshot(rss: UInt64(info.resident_size),
            physicalFootprint: UInt64(info.phys_footprint),
            kernelLifetimePeakRSS: UInt64(info.resident_size_peak))
    }
}

private enum MemoryProbeError: Error {
    case taskInfo(kern_return_t)
    case shortTaskInfo(mach_msg_type_number_t)
}

private struct MemoryMeasurement: Sendable {
    let before: MemorySnapshot
    let after: MemorySnapshot
    let maximumSampleRSS: UInt64
    let timerSampleCount: Int
    let errors: [String]

    var sampledRSSGrowth: UInt64 {
        maximumSampleRSS >= before.rss ? maximumSampleRSS - before.rss : 0
    }

    func description(label: String) -> String {
        "MEMORY_PROBE \(label) baselineRSS=\(before.rss) maxSampleRSS=\(maximumSampleRSS) " +
        "sampledRSSGrowth=\(sampledRSSGrowth) afterRSS=\(after.rss) " +
        "physFootprintBefore=\(before.physicalFootprint) physFootprintAfter=\(after.physicalFootprint) " +
        "kernelLifetimePeakRSSBefore=\(before.kernelLifetimePeakRSS) " +
        "kernelLifetimePeakRSSAfter=\(after.kernelLifetimePeakRSS) " +
        "timerSampleCount=\(timerSampleCount) errors=\(errors) " +
        "sampledPeakIsLowerBound=true kernelPeakIsNotResettable=true"
    }
}

// @unchecked Sendable is confined to this recorder: all mutable sample state is
// protected by NSLock. The serial queue orders callbacks; cancellation is joined
// before reading a report or releasing the timer's strong capture of self.
private final class MemorySampler: @unchecked Sendable {
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "FocusMateTests.CardPhotoMemorySampler", qos: .userInitiated)
    private let cancellation = DispatchGroup()
    private let timer: DispatchSourceTimer
    private let before: MemorySnapshot
    private var maximumSampleRSS: UInt64
    private var timerSampleCount = 0
    private var errors: [String] = []

    init() throws {
        before = try MemorySnapshot.read()
        maximumSampleRSS = before.rss
        timer = DispatchSource.makeTimerSource(queue: queue)
        cancellation.enter()
        let completion = cancellation
        timer.setCancelHandler { completion.leave() }
        timer.setEventHandler { [self] in sample() }
        timer.schedule(deadline: .now(), repeating: .milliseconds(1), leeway: .nanoseconds(0))
        timer.resume()
    }

    private func sample() {
        do {
            let snapshot = try MemorySnapshot.read()
            lock.lock()
            maximumSampleRSS = max(maximumSampleRSS, snapshot.rss)
            timerSampleCount += 1
            lock.unlock()
        } catch {
            lock.lock()
            errors.append(String(describing: error))
            lock.unlock()
        }
    }

    // Only the test's measuring caller invokes lifecycle methods, never the
    // timer queue. Cancel + group wait drains any in-flight callback.
    func cancelAndWait() {
        timer.cancel()
        cancellation.wait()
        timer.setEventHandler {}
        timer.setCancelHandler {}
    }

    func finish() throws -> MemoryMeasurement {
        let after: MemorySnapshot
        do {
            after = try MemorySnapshot.read()
        } catch {
            cancelAndWait()
            throw error
        }
        cancelAndWait()
        lock.lock()
        defer { lock.unlock() }
        return MemoryMeasurement(before: before, after: after,
            maximumSampleRSS: max(maximumSampleRSS, after.rss),
            timerSampleCount: timerSampleCount, errors: errors)
    }
}
```

## 부모 실제 RED 확인
독립 플랫폼 thumbnail-only1/1PASS, sampledRSSGrowth300236800/744samples/errors0. 이후 수정 전 실제processor1/1FAIL: RSS530186240>고정402653184(384MiB),1072samples/errors0. output내용/치수 실패없음. 컴파일에러0/actual assertion failure1. 로그 t2-memory-actual-red.log exit65. 첫128MiB후보는 actualRED前플랫폼대조로교정했으며RED後예산변경금지.
