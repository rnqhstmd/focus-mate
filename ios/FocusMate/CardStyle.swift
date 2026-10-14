import Foundation

enum CardCustomizationPolicy {
    static let inputByteLimit = 8_388_608
    static let maximumPhotos = 6
    static let photoByteLimit = 1_048_576
    static let totalPhotoByteLimit = 6_291_456
    static let aspectRatioRange = 0.1...10.0
    static let widthFractionRange = 0.15...2.5
    static let centerRange = -1.0...2.0
    static let undoLimit = 20
}

struct CardColor: Codable, Equatable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    static let standard = CardColor(red: 18.0 / 255.0, green: 20.0 / 255.0, blue: 22.0 / 255.0)

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

struct CardPhoto: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int
    var centerX: Double
    var centerY: Double
    var widthFraction: Double

    init(id: UUID, data: Data, pixelWidth: Int, pixelHeight: Int,
         centerX: Double, centerY: Double, widthFraction: Double) {
        self.id = id
        self.data = data
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.centerX = centerX
        self.centerY = centerY
        self.widthFraction = widthFraction
    }
}

enum CardStyleValidationIssue: Error, Equatable {
    case invalidColor, tooManyPhotos(Int), duplicatePhotoID
    case emptyPhotoData(UUID), invalidDimensions(UUID), invalidPlacement(UUID)
    case photoTooLarge(UUID), totalPhotosTooLarge
}

struct CardStyle: Codable, Equatable, Sendable {
    var background: CardColor
    var photos: [CardPhoto]
    static let standard = CardStyle(background: .standard, photos: [])

    var isStandard: Bool { background == .standard && photos.isEmpty }

    init(background: CardColor, photos: [CardPhoto]) {
        self.background = background
        self.photos = photos
    }

    func validate() throws {
        guard [background.red, background.green, background.blue].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            throw CardStyleValidationIssue.invalidColor
        }
        guard photos.count <= CardCustomizationPolicy.maximumPhotos else {
            throw CardStyleValidationIssue.tooManyPhotos(photos.count)
        }
        guard Set(photos.map(\.id)).count == photos.count else { throw CardStyleValidationIssue.duplicatePhotoID }
        var total = 0
        for photo in photos {
            guard photo.data.count <= CardCustomizationPolicy.totalPhotoByteLimit - total else {
                throw CardStyleValidationIssue.totalPhotosTooLarge
            }
            total += photo.data.count
        }
        for photo in photos {
            guard !photo.data.isEmpty else { throw CardStyleValidationIssue.emptyPhotoData(photo.id) }
            guard photo.data.count <= CardCustomizationPolicy.photoByteLimit else { throw CardStyleValidationIssue.photoTooLarge(photo.id) }
            guard photo.pixelWidth > 0, photo.pixelHeight > 0,
                  CardCustomizationPolicy.aspectRatioRange.contains(Double(photo.pixelWidth) / Double(photo.pixelHeight)) else {
                throw CardStyleValidationIssue.invalidDimensions(photo.id)
            }
            guard photo.centerX.isFinite, photo.centerY.isFinite, photo.widthFraction.isFinite,
                  CardCustomizationPolicy.centerRange.contains(photo.centerX),
                  CardCustomizationPolicy.centerRange.contains(photo.centerY),
                  CardCustomizationPolicy.widthFractionRange.contains(photo.widthFraction) else {
                throw CardStyleValidationIssue.invalidPlacement(photo.id)
            }
        }
    }
}
