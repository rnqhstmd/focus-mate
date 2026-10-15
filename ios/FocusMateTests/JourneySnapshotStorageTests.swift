import Foundation
import XCTest
@testable import FocusMate

final class JourneySnapshotStorageTests: XCTestCase {
    private typealias F = BoardingFixtures

    private static let v2WithActive = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":{"id":"j"}},"records":{"items":[]}},"version":2}"#.utf8
    )
    private static let v2NullActive = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#.utf8
    )

    // 깨짐: active 객체를 저장 때 누락하거나 읽을 때 다른 값으로 복원하면 실패. (AC-24, BR-8)
    func testAC24_진행여정_1건을_저장하고_다시_읽으면_같은_값이다() throws {
        try withTemporaryFile { fileURL in
            let snapshot = F.snapshot(active: F.awaiting())
            try LocalSnapshotStore(fileURL: fileURL).save(snapshot)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertEqual(loaded.journey.active, F.awaiting())
            XCTAssertEqual(loaded, snapshot)
        }
    }

    // 깨짐: 출발 확인 후 phase가 저장되지 않으면 실패.
    func testAC24_출발확인된_여정도_왕복해서_같은_값이다() throws {
        try withTemporaryFile { fileURL in
            let confirmed = F.awaiting().confirmingDeparture()
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: confirmed))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertEqual(loaded.journey.active, confirmed)
            XCTAssertEqual(loaded.journey.active?.phase, .departed)
        }
    }

    // 깨짐: v4 파일의 active가 단일 객체가 아니거나 version이 4가 아니거나 paused가 없으면 실패. (BR-8, BR-9)
    func testBR8_저장된_active는_단일_객체이고_version은_4이며_paused는_false다() throws {
        try withTemporaryFile { fileURL in
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: F.awaiting()))

            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 4)
            let state = try XCTUnwrap(root["state"] as? [String: Any])
            let journey = try XCTUnwrap(state["journey"] as? [String: Any])
            let active = try XCTUnwrap(journey["active"] as? [String: Any])
            XCTAssertEqual(active["cardID"] as? String, "FM-01234567")
            XCTAssertEqual(active["phase"] as? String, "awaitingDeparture")
            XCTAssertEqual(active["boardedAt"] as? String, "2026-10-13T09:00:00Z")
            XCTAssertEqual((active["progress"] as? [String: Any])?["elapsedSeconds"] as? Int, 0)
            XCTAssertEqual(active["paused"] as? Bool, false)
            XCTAssertNil(active["stops"])
        }
    }

    // 깨짐: v2 파일의 active 객체를 읽어 버리면(corrupt로 막지 않으면) 실패.
    func testV2_active가_객체인_파일은_corrupt다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v2WithActive)

            assertStorageIssue(.corrupt) {
                _ = try LocalSnapshotStore(fileURL: fileURL).load()
            }
        }
    }

    // 깨짐: v2 null active 마이그레이션이 깨지면 실패.
    func testV2_active가_null인_파일은_진행여정_없이_읽힌다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v2NullActive)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
        }
    }

    // 깨짐: active 손상 때 파일 전체를 .corrupt로 던지거나 active를 살려두면 실패. (F1 여정만 버리기)
    func testV3_active가_빈_객체면_진행여정만_버리고_읽힌다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v3(active: "{}"))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.currentStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        }
    }

    // 깨짐: 문자열 active 때 파일 전체를 .corrupt로 던지면 실패.
    func testV3_active가_문자열이면_진행여정만_버리고_읽힌다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v3(active: #""x""#))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.currentStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        }
    }

    // 깨짐: 모르는 아이콘 때 .corrupt로 던지거나 카드를 함께 버리면 실패.
    func testV3_모르는_아이콘_값이면_진행여정만_버리고_카드는_유지된다() throws {
        try withTemporaryFile { fileURL in
            try saveThenRewrite(fileURL, replacing: #""icon":"reading""#, with: #""icon":"no-such-icon""#)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.cards.items.map(\.id), [F.cardID])
        }
    }

    // 깨짐: 카드가 다른 active를 검증 실패로 파일 전체 거절하거나 active를 살리면 실패.
    func testV3_카드_불일치_active_파일은_진행여정만_버리고_카드와_기록은_그대로다() throws {
        try withTemporaryFile { fileURL in
            try saveThenRewrite(fileURL, replacing: #""cardID":"FM-01234567""#, with: #""cardID":"FM-76543210""#)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.cards.items.map(\.id), [F.cardID])
            XCTAssertEqual(loaded.records.items.count, 0)
        }
    }

    // 깨짐: awaiting인데 진도 5인 active를 읽어 살리거나 파일 전체를 거절하면 실패.
    func testV3_대기_상태인데_진도가_5인_active는_버려진다() throws {
        try withTemporaryFile { fileURL in
            try saveThenRewrite(fileURL, replacing: #""elapsedSeconds":0"#, with: #""elapsedSeconds":5"#)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.cards.items.map(\.id), [F.cardID])
        }
    }

    // 깨짐: journey 객체에 active 키가 없는 파일을 정상으로 읽으면 실패 (키 누락은 여전히 손상).
    func testV3_journey에_active_키가_없으면_corrupt다() throws {
        try withTemporaryFile { fileURL in
            let bytes = Data(#"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{},"records":{"items":[]}},"version":3}"#.utf8)
            try seed(fileURL, bytes)

            assertStorageIssue(.corrupt) { _ = try LocalSnapshotStore(fileURL: fileURL).load() }
        }
    }

    // 깨짐: 검증 위반 후보를 그대로 쓰거나 다른 오류로 분류하면 실패.
    func testA1_검증위반_후보는_invalidState로_거절된다() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)

            assertStorageIssue(.invalidState(.invalidActiveJourney(.invalidMinutes(0)))) {
                try store.save(F.snapshot(active: F.journey(minutes: 0)))
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    // 깨짐: 거절된 저장이 기존 파일을 건드리면 바이트가 달라져 실패.
    func testA1_거절된_저장은_기존_파일_바이트를_바꾸지_않는다() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(F.snapshot(active: F.awaiting()))
            let before = try Data(contentsOf: fileURL)

            assertStorageIssue(.invalidState(.invalidActiveJourney(.invalidProgress))) {
                try store.save(F.snapshot(active: F.journey(phase: .awaitingDeparture, elapsedSeconds: 5)))
            }

            XCTAssertEqual(try Data(contentsOf: fileURL), before)
        }
    }

    // 깨짐: 카드가 다른 active를 통과시키면 실패.
    func testA1_현재_카드와_다른_cardID의_여정은_거절된다() throws {
        try withTemporaryFile { fileURL in
            assertStorageIssue(.invalidState(.invalidActiveJourney(.cardMismatch))) {
                try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: F.journey(cardID: "FM-76543210")))
            }
        }
    }

    // 깨짐: active가 null인 기존 v3 파일을 재저장할 때 바이트가 달라지면 실패.
    func testV3_active_null인_기존_파일은_재저장해도_바이트가_같다() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(F.snapshot(active: nil))
            let first = try Data(contentsOf: fileURL)
            XCTAssertTrue(String(decoding: first, as: UTF8.self).contains(#""journey":{"active":null}"#))

            let loaded = try XCTUnwrap(try store.load())
            try store.save(loaded)

            XCTAssertEqual(try Data(contentsOf: fileURL), first)
        }
    }

    // 깨짐: 팩토리가 만든 소수 초 boardedAt이 저장 왕복 후 달라지면(내림 누락) 실패.
    func testFactory_소수초_시각도_저장_왕복_후_같다() throws {
        try withTemporaryFile { fileURL in
            let factory = ActiveJourneyFactory(makeID: { "id-1" }, now: { Date(timeIntervalSince1970: 1_791_882_000.75) })
            let made = factory.make(details: F.details, cardID: F.cardID)
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: made))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertEqual(loaded.journey.active, made)
            XCTAssertEqual(loaded.journey.active?.boardedAt.timeIntervalSince1970, 1_791_882_000)
        }
    }

    // MARK: - helpers

    private static func v3(active: String) -> Data {
        Data(#"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":\#(active)},"records":{"items":[]}},"version":3}"#.utf8)
    }

    private func saveThenRewrite(_ fileURL: URL, replacing target: String, with replacement: String) throws {
        try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: F.awaiting()))
        let text = try XCTUnwrap(String(data: Data(contentsOf: fileURL), encoding: .utf8))
        XCTAssertTrue(text.contains(target))
        try seed(fileURL, Data(text.replacingOccurrences(of: target, with: replacement).utf8))
    }

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: fileURL)
    }
}
