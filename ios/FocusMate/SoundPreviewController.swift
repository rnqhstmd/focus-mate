import Foundation
import Observation

@MainActor protocol SoundPreviewPlaying: AnyObject {
    var volume: Float { get set }
    var numberOfLoops: Int { get set }
    func prepareToPlay() -> Bool
    func play() -> Bool
    func setVolume(_ volume: Float, fadeDuration: TimeInterval)
    func stop()
}

@MainActor @Observable final class SoundPreviewController {
    enum Phase: Equatable { case stopped, loading, playing }
    private(set) var selectedSound: JourneySound
    private(set) var phase: Phase = .stopped
    private(set) var errorMessage: String?
    private let makePlayer: @MainActor (JourneySound) async throws -> any SoundPreviewPlaying
    private let sleep: @MainActor (Duration) async -> Void
    private var player: (any SoundPreviewPlaying)?
    private var stopTask: Task<Void, Never>?
    private var generation = 0
    private var active = true
    init(sound: JourneySound,
         makePlayer: @escaping @MainActor (JourneySound) async throws -> any SoundPreviewPlaying,
         sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        selectedSound = sound
        self.makePlayer = makePlayer
        self.sleep = sleep
    }
    func chooseSound(_ sound: JourneySound) {
        stopPreview()
        selectedSound = sound
        errorMessage = nil
    }
    func togglePreview() async {
        guard phase == .stopped else { stopPreview(); return }
        guard active, selectedSound != .none, !Task.isCancelled else { return }
        generation += 1
        let token = generation
        let sound = selectedSound
        phase = .loading
        errorMessage = nil
        do {
            let candidate = try await makePlayer(sound)
            guard isCurrent(token, sound: sound) else {
                candidate.stop()
                if generation == token { phase = .stopped }
                return
            }
            if let stopTask { await stopTask.value }
            guard isCurrent(token, sound: sound) else {
                candidate.stop()
                if generation == token { phase = .stopped }
                return
            }
            candidate.volume = 0
            candidate.numberOfLoops = -1
            guard candidate.prepareToPlay(), candidate.play() else {
                candidate.stop()
                phase = .stopped
                errorMessage = "소리를 재생하지 못했어요. 선택은 그대로 저장할 수 있어요."
                return
            }
            candidate.setVolume(1, fadeDuration: 0.12)
            player = candidate
            phase = .playing
        } catch {
            guard isCurrent(token, sound: sound) else {
                if generation == token { phase = .stopped }
                return
            }
            phase = .stopped
            errorMessage = "소리를 재생하지 못했어요. 선택은 그대로 저장할 수 있어요."
        }
    }
    func stopPreview() {
        generation += 1
        phase = .stopped
        guard let player else { return }
        self.player = nil
        player.setVolume(0, fadeDuration: 0.06)
        let sleep = self.sleep
        stopTask = Task {
            await sleep(.milliseconds(60))
            player.stop()
        }
    }
    func setActive(_ active: Bool) {
        self.active = active
        if !active { stopPreview() }
    }
    func beginSelection(sound: JourneySound) {
        stopPreview()
        active = true
        selectedSound = sound
        phase = .stopped
        errorMessage = nil
    }

    private func isCurrent(_ token: Int, sound: JourneySound) -> Bool {
        token == generation && active && selectedSound == sound && !Task.isCancelled
    }
}
