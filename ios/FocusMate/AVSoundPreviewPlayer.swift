import Foundation
import AVFoundation

@MainActor final class AVSoundPreviewPlayer: SoundPreviewPlaying {
    private enum ResourceIssue: Error { case missingResource }
    private let player: AVAudioPlayer
    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    var numberOfLoops: Int {
        get { player.numberOfLoops }
        set { player.numberOfLoops = newValue }
    }
    init(url: URL) throws { player = try AVAudioPlayer(contentsOf: url) }
    func prepareToPlay() -> Bool { player.prepareToPlay() }
    func play() -> Bool { player.play() }
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) {
        player.setVolume(volume, fadeDuration: fadeDuration)
    }
    func stop() { player.stop() }
    static func make(sound: JourneySound, bundle: Bundle = .main) async throws -> any SoundPreviewPlaying {
        guard let name = sound.resourceName,
              let url = bundle.url(forResource: name, withExtension: "wav") else {
            throw ResourceIssue.missingResource
        }
        return try AVSoundPreviewPlayer(url: url)
    }
}
