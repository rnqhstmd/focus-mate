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
