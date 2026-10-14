import AVFoundation
import CryptoKit
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class AudioResourceTests: XCTestCase {
    // 깨짐: 앱 번들 리소스 누락, WAV 대신 다른 bytes 포함, 손상된 WAV, adapter의 URL 매핑 오류.
    func testAC17_네_샘플은_실제앱번들의_goldenWAV이며_decode와_adapter준비가_성공한다() async throws {
        let samples: [(JourneySound, String)] = [
            (.bus, "eb580967c70cb86d709ecb0122d45c771343e37d834b45201be315ff9d5fb1be"),
            (.rainBus, "6efc8b0c2e2f16fbc491eac7cad5ad1da80ef138f20d1349150ef2bfbb45b8bb"),
            (.subway, "f938cfb97a5d0ae7a9cb91df9c4ff2d3e54ddd0dab4802ccb2452aaa31d235f1"),
            (.forest, "9391f1d2024588f505ccefc4f53907dde3aaabdc76115dcef53c3af5090a5cc8")
        ]
        for (sound, golden) in samples {
            let name = try XCTUnwrap(sound.resourceName, "\(sound) resource name")
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "wav"), "\(sound) bundled WAV")
            let actual = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, golden, "\(sound) actual bundle bytes")
            let decoder = try AVAudioPlayer(contentsOf: url)
            XCTAssertTrue(decoder.prepareToPlay(), "\(sound) actual WAV decode")
            decoder.stop()
            let adapter = try await AVSoundPreviewPlayer.make(sound: sound)
            XCTAssertTrue(adapter.prepareToPlay(), "\(sound) actual adapter")
            adapter.stop()
        }
    }
    // 깨짐: none을 직접 factory에 넘겼는데 player를 반환한다.
    func testAC19_none을_adapterfactory에_직접_넘기면_throw한다() async {
        do {
            let unexpected = try await AVSoundPreviewPlayer.make(sound: .none)
            unexpected.stop()
            XCTFail("none factory must throw")
        } catch { }
    }
    // 깨짐: 리소스 없는 주입 bundle을 무시하고 main/sourcepath로 fallback한다.
    func testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다() async {
        let emptyBundle = Bundle(for: AudioResourceTests.self)
        for sound in [JourneySound.bus, .rainBus, .subway, .forest] {
            do {
                let unexpected = try await AVSoundPreviewPlayer.make(sound: sound, bundle: emptyBundle)
                unexpected.stop()
                XCTFail("\(sound): missing bundle resource must throw")
            } catch { }
        }
    }
}
