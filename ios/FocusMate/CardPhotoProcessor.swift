import Foundation
import ImageIO
import UniformTypeIdentifiers
import zlib

struct ProcessedCardPhoto: Equatable, Sendable {
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int

    init(data: Data, pixelWidth: Int, pixelHeight: Int) {
        self.data = data
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

enum CardPhotoProcessingIssue: Error, Equatable {
    case inputTooLarge, unreadable, unsupportedAspectRatio
    case encodingFailed, cannotMeetStorageLimit
}

protocol CardPhotoProcessing: Sendable {
    func process(_ data: Data) async throws -> ProcessedCardPhoto
}

struct ImageIOCardPhotoProcessor: CardPhotoProcessing {
    private static let maximumPixelSize = 2048
    private static let minimumPixelSize = 64
    private static let jpegQualities = [0.85, 0.7, 0.55, 0.4]

    func process(_ data: Data) async throws -> ProcessedCardPhoto {
        guard data.count <= CardCustomizationPolicy.inputByteLimit else { throw CardPhotoProcessingIssue.inputTooLarge }
        let source = try Self.completeSource(data)
        let dimensions = try Self.dimensions(source)
        guard CardCustomizationPolicy.aspectRatioRange.contains(Double(dimensions.width) / Double(dimensions.height)) else {
            throw CardPhotoProcessingIssue.unsupportedAspectRatio
        }
        var maximum = min(Self.maximumPixelSize, max(dimensions.width, dimensions.height))
        while true {
            let image = try Self.thumbnail(source, maximum: maximum)
            let hasAlpha = Self.hasAlpha(image)
            for quality in hasAlpha ? [1.0] : Self.jpegQualities {
                let bytes = try Self.encode(image, hasAlpha: hasAlpha, quality: quality)
                if bytes.count <= CardCustomizationPolicy.photoByteLimit {
                    let outputSource = try Self.completeSource(bytes)
                    let outputDimensions = try Self.dimensions(outputSource)
                    guard outputDimensions.orientation == 1,
                          max(outputDimensions.width, outputDimensions.height) <= Self.maximumPixelSize,
                          CardCustomizationPolicy.aspectRatioRange.contains(Double(outputDimensions.width) / Double(outputDimensions.height)) else {
                        throw CardPhotoProcessingIssue.encodingFailed
                    }
                    let decoded = try Self.thumbnail(outputSource, maximum: Self.maximumPixelSize)
                    guard decoded.width == outputDimensions.width, decoded.height == outputDimensions.height else {
                        throw CardPhotoProcessingIssue.encodingFailed
                    }
                    return ProcessedCardPhoto(data: bytes, pixelWidth: decoded.width, pixelHeight: decoded.height)
                }
            }
            guard maximum > Self.minimumPixelSize else { throw CardPhotoProcessingIssue.cannotMeetStorageLimit }
            maximum = max(Self.minimumPixelSize, Int(Double(maximum) * 0.75))
        }
    }

    static func validateStoredPhoto(_ photo: CardPhoto) throws {
        do {
            guard !photo.data.isEmpty, photo.data.count <= CardCustomizationPolicy.photoByteLimit else {
                throw SnapshotValidationIssue.invalidCardPhoto
            }
            let source = try completeSource(photo.data)
            let size = try dimensions(source)
            guard size.orientation == 1, size.width == photo.pixelWidth, size.height == photo.pixelHeight,
                  max(size.width, size.height) <= maximumPixelSize,
                  CardCustomizationPolicy.aspectRatioRange.contains(Double(size.width) / Double(size.height)) else {
                throw SnapshotValidationIssue.invalidCardPhoto
            }
            let image = try thumbnail(source, maximum: maximumPixelSize)
            guard image.width == photo.pixelWidth, image.height == photo.pixelHeight else {
                throw SnapshotValidationIssue.invalidCardPhoto
            }
        } catch { throw SnapshotValidationIssue.invalidCardPhoto }
    }

    static func validateStoredStyle(_ style: CardStyle) throws {
        for photo in style.photos { try validateStoredPhoto(photo) }
    }

    private static func completeSource(_ data: Data) throws -> CGImageSource {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetCount(source) > 0,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw CardPhotoProcessingIssue.unreadable
        }
        if CGImageSourceGetType(source) == UTType.png.identifier as CFString {
            try CardPhotoIntegrity.validatePNG(data)
        }
        try CardPhotoIntegrity.validateWebPPrefix(data)
        return source
    }

    private static func dimensions(_ source: CGImageSource) throws -> (width: Int, height: Int, orientation: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int, width > 0, height > 0 else {
            throw CardPhotoProcessingIssue.unreadable
        }
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        return (width: (5...8).contains(orientation) ? height : width,
                height: (5...8).contains(orientation) ? width : height, orientation: orientation)
    }

    private static func hasAlpha(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly: return true
        default: return false
        }
    }

    private static func thumbnail(_ source: CGImageSource, maximum: Int) throws -> CGImage {
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maximum, kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCache: true, kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              image.width > 0, image.height > 0, max(image.width, image.height) <= maximum,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete,
              let context = CGContext(data: nil, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: image.colorSpace?.model == .rgb ? image.colorSpace! : CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CardPhotoProcessingIssue.unreadable
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard context.data != nil, context.makeImage() != nil,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw CardPhotoProcessingIssue.unreadable
        }
        return image
    }

    private static func encode(_ image: CGImage, hasAlpha: Bool, quality: Double) throws -> Data {
        let data = NSMutableData()
        let type = hasAlpha ? UTType.png : UTType.jpeg
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil) else {
            throw CardPhotoProcessingIssue.encodingFailed
        }
        CGImageDestinationAddImage(destination, image,
            [kCGImageDestinationLossyCompressionQuality: quality, kCGImagePropertyOrientation: 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CardPhotoProcessingIssue.encodingFailed }
        return data as Data
    }
}


// Integrity checks never materialize the original raster. ImageIO still owns pixel decoding.
private enum CardPhotoIntegrity {
    private static let inflateBufferSize = 64 * 1024

    static func validatePNG(_ data: Data) throws {
        try data.withUnsafeBytes { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            guard bytes.count >= 8, Array(bytes.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10] else {
                throw CardPhotoProcessingIssue.unreadable
            }
            var stream = z_stream()
            guard inflateInit_(&stream, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
                throw CardPhotoProcessingIssue.unreadable
            }
            defer { inflateEnd(&stream) }
            var output = [UInt8](repeating: 0, count: inflateBufferSize)
            var rows: PNGScanlines?
            var colorType: UInt8 = 0
            var depth: UInt8 = 0
            var paletteSeen = false
            var idatSeen = false
            var idatClosed = false
            var streamEnded = false
            var offset = 8
            while offset <= bytes.count - 12 {
                let length = Int(bigEndian32(bytes, offset))
                guard length <= 0x7fff_ffff, length <= bytes.count - offset - 12 else {
                    throw CardPhotoProcessingIssue.unreadable
                }
                let payload = offset + 8
                let end = payload + length
                let type = bigEndian32(bytes, offset + 4)
                let checksum = crc32(0, bytes.baseAddress!.advanced(by: offset + 4), uInt(length + 4))
                guard UInt32(checksum) == bigEndian32(bytes, end),
                      bytes[(offset + 4)..<(offset + 8)].allSatisfy({ (65...90).contains($0) || (97...122).contains($0) }),
                      bytes[offset + 6] & 0x20 == 0 else {
                    throw CardPhotoProcessingIssue.unreadable
                }
                if rows == nil && type != 0x49484452 { throw CardPhotoProcessingIssue.unreadable }
                if idatSeen && type != 0x49444154 { idatClosed = true }
                switch type {
                case 0x49484452: // IHDR
                    guard rows == nil, offset == 8, length == 13 else { throw CardPhotoProcessingIssue.unreadable }
                    let width = UInt64(bigEndian32(bytes, payload))
                    let height = UInt64(bigEndian32(bytes, payload + 4))
                    depth = bytes[payload + 8]
                    colorType = bytes[payload + 9]
                    let channels: UInt64
                    let depths: [UInt8]
                    switch colorType {
                    case 0: channels = 1; depths = [1, 2, 4, 8, 16]
                    case 2: channels = 3; depths = [8, 16]
                    case 3: channels = 1; depths = [1, 2, 4, 8]
                    case 4: channels = 2; depths = [8, 16]
                    case 6: channels = 4; depths = [8, 16]
                    default: throw CardPhotoProcessingIssue.unreadable
                    }
                    guard width > 0, height > 0, width <= 0x7fff_ffff, height <= 0x7fff_ffff,
                          depths.contains(depth), bytes[payload + 10] == 0, bytes[payload + 11] == 0,
                          bytes[payload + 12] <= 1 else { throw CardPhotoProcessingIssue.unreadable }
                    rows = try PNGScanlines(width: width, height: height, bitsPerPixel: channels * UInt64(depth),
                                            interlaced: bytes[payload + 12] == 1)
                case 0x504c5445: // PLTE
                    guard !paletteSeen, !idatSeen, colorType != 0, colorType != 4,
                          length > 0, length % 3 == 0, length <= 768,
                          colorType != 3 || length / 3 <= (1 << Int(depth)) else {
                        throw CardPhotoProcessingIssue.unreadable
                    }
                    paletteSeen = true
                case 0x49444154: // IDAT: one zlib stream across arbitrary chunk boundaries.
                    guard !idatClosed, colorType != 3 || paletteSeen else { throw CardPhotoProcessingIssue.unreadable }
                    idatSeen = true
                    if !streamEnded {
                        stream.next_in = UnsafeMutablePointer(mutating: bytes.baseAddress!.advanced(by: payload))
                        stream.avail_in = uInt(length)
                        try output.withUnsafeMutableBufferPointer { buffer in
                            repeat {
                                let previousInput = stream.avail_in
                                stream.next_out = buffer.baseAddress!
                                stream.avail_out = uInt(buffer.count)
                                let status = inflate(&stream, Z_NO_FLUSH)
                                let produced = buffer.count - Int(stream.avail_out)
                                try rows!.consume(UnsafeBufferPointer(start: buffer.baseAddress, count: produced))
                                if status == Z_STREAM_END {
                                    guard rows!.isComplete else { throw CardPhotoProcessingIssue.unreadable }
                                    streamEnded = true
                                    break // PNG permits unused compressed bytes after the zlib end.
                                }
                                guard status == Z_OK || status == Z_BUF_ERROR else { throw CardPhotoProcessingIssue.unreadable }
                                if produced == 0 && previousInput == stream.avail_in {
                                    guard stream.avail_in == 0 else { throw CardPhotoProcessingIssue.unreadable }
                                    break
                                }
                            } while stream.avail_in > 0 || stream.avail_out == 0
                        }
                    }
                case 0x49454e44: // IEND
                    guard length == 0, end + 4 == bytes.count, idatSeen, streamEnded, rows!.isComplete else {
                        throw CardPhotoProcessingIssue.unreadable
                    }
                    return
                default:
                    guard bytes[offset + 4] & 0x20 != 0 else { throw CardPhotoProcessingIssue.unreadable }
                }
                offset = end + 4
            }
            throw CardPhotoProcessingIssue.unreadable
        }
    }

    private struct PNGScanlines {
        private var passes: [(bytes: UInt64, rows: UInt64)] = []
        private var pass = 0
        private var remainingInRow: UInt64 = 0
        private var remainingTotal: UInt64 = 0

        init(width: UInt64, height: UInt64, bitsPerPixel: UInt64, interlaced: Bool) throws {
            let patterns: [(UInt64, UInt64, UInt64, UInt64)] = interlaced
                ? [(0, 0, 8, 8), (4, 0, 8, 8), (0, 4, 4, 8), (2, 0, 4, 4),
                   (0, 2, 2, 4), (1, 0, 2, 2), (0, 1, 1, 2)] : [(0, 0, 1, 1)]
            for (x, y, dx, dy) in patterns where width > x && height > y {
                let columns = (width - x + dx - 1) / dx
                let rowCount = (height - y + dy - 1) / dy
                let rowBytes = (columns * bitsPerPixel + 7) / 8
                let size = (rowBytes + 1).multipliedReportingOverflow(by: rowCount)
                let total = remainingTotal.addingReportingOverflow(size.partialValue)
                guard !size.overflow, !total.overflow else { throw CardPhotoProcessingIssue.unreadable }
                remainingTotal = total.partialValue
                passes.append((rowBytes, rowCount))
            }
        }

        var isComplete: Bool { remainingTotal == 0 }

        mutating func consume(_ bytes: UnsafeBufferPointer<UInt8>) throws {
            guard UInt64(bytes.count) <= remainingTotal else { throw CardPhotoProcessingIssue.unreadable }
            var offset = 0
            while offset < bytes.count {
                if remainingInRow == 0 {
                    while pass < passes.count && passes[pass].rows == 0 { pass += 1 }
                    guard pass < passes.count, bytes[offset] <= 4 else { throw CardPhotoProcessingIssue.unreadable }
                    passes[pass].rows -= 1
                    remainingInRow = passes[pass].bytes
                    offset += 1
                }
                let skipped = min(remainingInRow, UInt64(bytes.count - offset))
                remainingInRow -= skipped
                offset += Int(skipped)
            }
            remainingTotal -= UInt64(bytes.count)
        }
    }

    // This is a required-prefix check, not a strict decoder for the entire VP8L body.
    // Google WebP lossless specification: the first transform's fixed fields precede its image data.
    static func validateWebPPrefix(_ data: Data) throws {
        try data.withUnsafeBytes { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            guard bytes.count >= 12, bigEndian32(bytes, 0) == 0x52494646,
                  bigEndian32(bytes, 8) == 0x57454250 else { return }
            let riffEnd = Int(littleEndian32(bytes, 4)) + 8
            guard riffEnd >= 12, riffEnd <= bytes.count else { throw CardPhotoProcessingIssue.unreadable }
            var offset = 12
            while offset <= riffEnd - 8 {
                let length = Int(littleEndian32(bytes, offset + 4))
                let payload = offset + 8
                guard length <= riffEnd - payload, length + (length & 1) <= riffEnd - payload else {
                    throw CardPhotoProcessingIssue.unreadable
                }
                if bigEndian32(bytes, offset) == 0x5650384c { // VP8L
                    guard length >= 5, bytes[payload] == 0x2f, bytes[payload + 4] >> 5 == 0 else {
                        throw CardPhotoProcessingIssue.unreadable
                    }
                    var bits = LosslessPrefixBits(bytes: bytes, bit: (payload + 5) * 8, end: (payload + length) * 8)
                    if try bits.read(1) == 1 {
                        switch try bits.read(2) {
                        case 0, 1: _ = try bits.read(3) // block-size bits before the transform image
                        case 2: _ = try bits.read(1) // subtract-green has no data; next transform flag is required
                        case 3: _ = try bits.read(8) // color_table_size - 1, before the palette image
                        default: break
                        }
                    }
                }
                offset = payload + length + (length & 1)
            }
            guard offset == riffEnd else { throw CardPhotoProcessingIssue.unreadable }
        }
    }

    private struct LosslessPrefixBits {
        let bytes: UnsafeBufferPointer<UInt8>
        var bit: Int
        let end: Int

        mutating func read(_ count: Int) throws -> UInt8 {
            guard count <= end - bit else { throw CardPhotoProcessingIssue.unreadable }
            var value: UInt8 = 0
            for shift in 0..<count {
                value |= ((bytes[bit / 8] >> (bit % 8)) & 1) << shift
                bit += 1
            }
            return value
        }
    }

    private static func bigEndian32(_ bytes: UnsafeBufferPointer<UInt8>, _ offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24) | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8) | UInt32(bytes[offset + 3])
    }

    private static func littleEndian32(_ bytes: UnsafeBufferPointer<UInt8>, _ offset: Int) -> UInt32 {
        UInt32(bytes[offset]) | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16) | (UInt32(bytes[offset + 3]) << 24)
    }
}
