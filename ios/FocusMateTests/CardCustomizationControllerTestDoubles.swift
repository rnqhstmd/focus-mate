import Foundation
@testable import FocusMate

@MainActor
final class DraftCardSaver: CardCustomizationSaving {
    struct Call { let style: CardStyle; let cardID: String }
    var calls: [Call] = []
    var result = true
    var saveFailure: StorageIssue?
    var onSave: (@MainActor () -> Void)?
    func saveCardStyle(_ style: CardStyle, forCardID id: String) -> Bool {
        calls.append(Call(style: style, cardID: id))
        onSave?()
        return result
    }
}

// Immutable Sendable boundary double: outcomes are fixtures, not controller state.
struct DraftPhotoProcessor: CardPhotoProcessing {
    func process(_ data: Data) async throws -> ProcessedCardPhoto {
        switch data.first {
        case 90: throw CardPhotoProcessingIssue.encodingFailed
        case 91: throw CardPhotoProcessingIssue.unsupportedAspectRatio
        default: return ProcessedCardPhoto(data: data, pixelWidth: 40, pixelHeight: 20)
        }
    }
}

// Explicit start signal and release. Cancellation deliberately does not release:
// the late-return generation tests must exercise a boundary ignoring cancellation.
actor DraftGate<Value: Sendable> {
    private var started = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var pending: CheckedContinuation<Value, Error>?
    func run() async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            started = true
            let waiters = startWaiters
            startWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }
    }
    func waitForStart() async {
        if started { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }
    func release(_ result: Result<Value, Error>) {
        precondition(pending != nil, "release only after start")
        let continuation = pending
        pending = nil
        continuation?.resume(with: result)
    }
}

struct DraftHeldProcessor: CardPhotoProcessing {
    let gate: DraftGate<ProcessedCardPhoto>
    func process(_ data: Data) async throws -> ProcessedCardPhoto { try await gate.run() }
}

@MainActor
final class DraftLoadCounter {
    var calls = 0
    func input(_ value: Data?) -> CardPhotoInput {
        CardPhotoInput(load: { self.calls += 1; return value })
    }
}

@MainActor
final class DraftIDs {
    private var next = 101
    func make() -> UUID {
        defer { next += 1 }
        return UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", next))!
    }
}
