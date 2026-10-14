import Foundation
import Observation

struct CardPhotoInput {
    let load: @MainActor () async throws -> Data?

    init(load: @escaping @MainActor () async throws -> Data?) {
        self.load = load
    }
}

enum CardLayerDirection {
    case forward, backward
}

enum CardCustomizationExitDecision: Equatable {
    case dismiss, confirmDiscard
}

@MainActor
protocol CardCustomizationSaving: AnyObject {
    func saveCardStyle(_ style: CardStyle, forCardID id: String) -> Bool
    var saveFailure: StorageIssue? { get }
}

enum CardCustomizationNotice: Equatable {
    case maximumPhotos
    case importFailed([CardPhotoProcessingIssue])
    case partialImport(failures: [CardPhotoProcessingIssue], omittedCount: Int)
    case saveFailed(StorageIssue)

    var message: String {
        switch self {
        case .maximumPhotos: "사진은 최대 6장까지 넣을 수 있어요."
        case .importFailed: "사진을 읽지 못했어요. 사진 추가로 다시 선택해주세요."
        case let .partialImport(failures, omittedCount):
            omittedCount > 0 ? "사진은 최대 6장까지 넣을 수 있어요. 일부 사진은 추가하지 않았어요." : "사진 \(failures.count)장을 읽지 못했어요. 사진 추가로 다시 선택해주세요."
        case .saveFailed: "카드 외형을 저장하지 못했어요. 초안은 유지돼요. 저장 버튼으로 다시 시도해주세요."
        }
    }
}

@MainActor @Observable
final class CardCustomizationController {
    private(set) var draft: CardStyle
    private(set) var selectedPhotoID: UUID?
    private(set) var isImporting = false
    private(set) var isSaving = false
    private(set) var didSave = false
    private(set) var notice: CardCustomizationNotice?

    private var baseline: CardStyle
    private var history: [CardStyle] = []
    private var isActive = true
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private let cardID: String
    @ObservationIgnored private let saver: any CardCustomizationSaving
    @ObservationIgnored private let processor: any CardPhotoProcessing
    @ObservationIgnored private let makeID: () -> UUID

    init(card: CardSnapshot, saver: any CardCustomizationSaving,
         processor: any CardPhotoProcessing = ImageIOCardPhotoProcessor(),
         makeID: @escaping () -> UUID = UUID.init) {
        cardID = card.id
        baseline = card.style
        draft = card.style
        self.saver = saver
        self.processor = processor
        self.makeID = makeID
    }

    var hasChanges: Bool { draft != baseline }
    var canUndo: Bool { !history.isEmpty }
    var canAddPhotos: Bool {
        canMutate && draft.photos.count < CardCustomizationPolicy.maximumPhotos
    }
    private var canMutate: Bool { isActive && !isImporting && !isSaving }

    func selectPhoto(_ id: UUID?) {
        guard isActive, !isSaving else { return }
        if let id, !draft.photos.contains(where: { $0.id == id }) { return }
        selectedPhotoID = id
    }

    func setBackground(_ color: CardColor) {
        guard canMutate,
              [color.red, color.green, color.blue].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else { return }
        var next = draft
        next.background = color
        apply(next)
    }

    func setPlacement(photoID: UUID, centerX: Double, centerY: Double, widthFraction: Double) {
        guard canMutate, centerX.isFinite, centerY.isFinite, widthFraction.isFinite,
              let index = draft.photos.firstIndex(where: { $0.id == photoID }) else { return }
        var next = draft
        let centers = CardCustomizationPolicy.centerRange
        let widths = CardCustomizationPolicy.widthFractionRange
        next.photos[index].centerX = min(centers.upperBound, max(centers.lowerBound, centerX))
        next.photos[index].centerY = min(centers.upperBound, max(centers.lowerBound, centerY))
        next.photos[index].widthFraction = min(widths.upperBound, max(widths.lowerBound, widthFraction))
        apply(next)
    }

    func moveLayer(photoID: UUID, direction: CardLayerDirection) {
        guard canMutate, let index = draft.photos.firstIndex(where: { $0.id == photoID }) else { return }
        let destination = index + (direction == .forward ? 1 : -1)
        guard draft.photos.indices.contains(destination) else { return }
        var next = draft
        next.photos.swapAt(index, destination)
        apply(next)
    }

    func deletePhoto(_ id: UUID) {
        guard canMutate, let index = draft.photos.firstIndex(where: { $0.id == id }) else { return }
        var next = draft
        next.photos.remove(at: index)
        apply(next)
    }

    func undo() {
        guard canMutate, let previous = history.popLast() else { return }
        draft = previous
        clearMissingSelection()
    }

    func restoreDefault() {
        guard canMutate else { return }
        apply(.standard)
    }

    // A batch is committed once; failed inputs leave slots available to later inputs.
    func importPhotos(_ inputs: [CardPhotoInput]) async {
        guard canMutate, !inputs.isEmpty else { return }
        let available = CardCustomizationPolicy.maximumPhotos - draft.photos.count
        guard available > 0 else {
            notice = .maximumPhotos
            return
        }
        generation += 1
        let token = generation
        isImporting = true
        defer {
            if isCurrentImport(token) { isImporting = false }
        }
        var photos: [CardPhoto] = []
        var failures: [CardPhotoProcessingIssue] = []
        var omittedCount = 0
        for input in inputs {
            if photos.count == available {
                omittedCount += 1
                continue
            }
            let data: Data
            do {
                let loaded = try await input.load()
                guard isCurrentImport(token) else { return }
                guard let loaded else {
                    failures.append(.unreadable)
                    continue
                }
                data = loaded
            } catch {
                guard isCurrentImport(token) else { return }
                failures.append(.unreadable)
                continue
            }
            do {
                let processed = try await processor.process(data)
                guard isCurrentImport(token) else { return }
                photos.append(CardPhoto(id: makeID(), data: processed.data,
                                        pixelWidth: processed.pixelWidth, pixelHeight: processed.pixelHeight,
                                        centerX: 0.5, centerY: 0.5, widthFraction: 0.6))
            } catch {
                guard isCurrentImport(token) else { return }
                failures.append(error as? CardPhotoProcessingIssue ?? .unreadable)
            }
        }
        guard isCurrentImport(token) else { return }
        if let last = photos.last {
            var next = draft
            next.photos.append(contentsOf: photos)
            apply(next)
            selectedPhotoID = last.id
            notice = failures.isEmpty && omittedCount == 0
                ? nil : .partialImport(failures: failures, omittedCount: omittedCount)
        } else {
            notice = .importFailed(failures)
        }
    }

    func requestExit() -> CardCustomizationExitDecision {
        guard isActive else { return .dismiss }
        return hasChanges || isImporting ? .confirmDiscard : .dismiss
    }

    func continueEditing() {}

    func discard() {
        guard isActive, !isSaving else { return }
        generation += 1
        isActive = false
        draft = baseline
        history.removeAll()
        selectedPhotoID = nil
        isImporting = false
        isSaving = false
        didSave = false
        notice = nil
    }

    @discardableResult
    func save() -> Bool {
        guard canMutate else { return false }
        isSaving = true
        defer { isSaving = false }
        guard saver.saveCardStyle(draft, forCardID: cardID) else {
            notice = .saveFailed(saver.saveFailure ?? .writeFailed)
            return false
        }
        baseline = draft
        history.removeAll()
        didSave = true
        notice = nil
        return true
    }

    private func isCurrentImport(_ token: Int) -> Bool {
        isActive && generation == token
    }

    private func apply(_ next: CardStyle) {
        guard next != draft else { return }
        history.append(draft)
        if history.count > CardCustomizationPolicy.undoLimit { history.removeFirst() }
        draft = next
        clearMissingSelection()
    }

    private func clearMissingSelection() {
        if let selectedPhotoID, !draft.photos.contains(where: { $0.id == selectedPhotoID }) {
            self.selectedPhotoID = nil
        }
    }
}
