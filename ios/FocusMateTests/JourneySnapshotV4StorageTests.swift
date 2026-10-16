import Foundation
import XCTest
@testable import FocusMate

/// 저장 형식 v5 진행 여정: 검증(분·경과·paused), 왕복. (v3·v4 읽기와 카탈로그 대조 테스트는 W16b에서 삭제됨) 모킹 없이 실제 LocalSnapshotStore를 쓴다.
final class JourneySnapshotV4StorageTests: XCTestCase {
    private typealias F = BoardingFixtures

    private func departed(
        minutes: Int = 25, elapsed: Int = 0, paused: Bool = true,
        originStopID: String = "seoulForest", busID: String = "2014", destinationStopID: String = "seongdongSportsCenter"
    ) -> JourneySnapshot {
        F.journey(
            originStopID: originStopID, originName: "서울숲", minutes: minutes, busID: busID, destinationStopID: destinationStopID,
            phase: .departed, elapsedSeconds: elapsed, paused: paused
        )
    }

    // MARK: - 쓰기 거부 (AC-20 ~ AC-22, 이후 파일 바이트 불변)

    // 깨짐: 분 하한/상한(1...360)을 쓰기에서 검증하지 않으면 0·361이 저장되어 실패. (AC-20)
    func testAC20_분_0과_361은_쓰기가_거부되고_파일이_바뀌지_않는다() throws {
        for (minutes, issue) in [(0, ActiveJourneyValidationIssue.invalidMinutes(0)), (361, .invalidMinutes(361))] {
            try withTemporaryFile { fileURL in
                let store = LocalSnapshotStore(fileURL: fileURL)
                try store.save(F.snapshot(active: F.awaiting()))
                let before = try Data(contentsOf: fileURL)

                assertStorageIssue(.invalidState(.invalidActiveJourney(issue))) {
                    try store.save(F.snapshot(active: self.departed(minutes: minutes)))
                }
                XCTAssertEqual(try Data(contentsOf: fileURL), before)
            }
        }
    }

    // 깨짐: 상한을 360 미만(예: 359)이나 하한을 2로 잘못 잡으면 1·360 저장이 거절되어 실패. (AC-20)
    func testAC20_분_1과_360은_쓰기가_허용된다() throws {
        for minutes in [1, 360] {
            try withTemporaryFile { fileURL in
                try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: departed(minutes: minutes)))

                let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
                XCTAssertEqual(loaded.journey.active?.minutes, minutes)
            }
        }
    }

    // 깨짐: 경과 상한(분×60)·하한(0)을 쓰기에서 검증하지 않으면 -1·1501이 저장되어 실패. (AC-21)
    func testAC21_경과_음수1과_1501은_쓰기가_거부되고_파일이_바뀌지_않는다() throws {
        for elapsed in [-1, 1501] {
            try withTemporaryFile { fileURL in
                let store = LocalSnapshotStore(fileURL: fileURL)
                try store.save(F.snapshot(active: departed()))
                let before = try Data(contentsOf: fileURL)

                assertStorageIssue(.invalidState(.invalidActiveJourney(.invalidProgress))) {
                    try store.save(F.snapshot(active: self.departed(elapsed: elapsed)))
                }
                XCTAssertEqual(try Data(contentsOf: fileURL), before)
            }
        }
    }

    // 깨짐: 경계를 미만(<)으로 검증해 0·1500이 거절되면 실패. (AC-21)
    func testAC21_경과_0과_1500은_쓰기가_허용된다() throws {
        for elapsed in [0, 1500] {
            try withTemporaryFile { fileURL in
                try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: departed(elapsed: elapsed)))

                let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
                XCTAssertEqual(loaded.journey.active?.progress.elapsedSeconds, elapsed)
            }
        }
    }

    // 깨짐: 출발 대기인데 paused=true를 통과시키면 실패. (BR-5 계열 검증, invalidPausedState)
    func testPaused_출발대기_여정에_paused_true는_쓰기가_거부된다() throws {
        try assertWriteRejected(
            F.journey(phase: .awaitingDeparture, elapsedSeconds: 0, paused: true), .invalidPausedState
        )
    }

    // MARK: - 읽기: 여정만 버림 (AC-20 ~ AC-22)

    // 깨짐: 분 361 파일을 읽어 살리거나 파일 전체를 거절/카드까지 버리면 실패. (AC-20)
    func testAC20_분_361_파일은_여정만_버리고_카드는_유지된다() throws {
        try assertReadDropsJourneyOnly(patch: { $0["minutes"] = 361 })
    }

    // 깨짐: 분 0 파일을 읽어 살리면 실패. (AC-20)
    func testAC20_분_0_파일은_여정만_버리고_카드는_유지된다() throws {
        try assertReadDropsJourneyOnly(patch: { $0["minutes"] = 0 })
    }

    // 깨짐: 경과 1501(25분 초과) 파일을 읽어 살리면 실패. (AC-21)
    func testAC21_경과_1501_파일은_여정만_버리고_카드는_유지된다() throws {
        try assertReadDropsJourneyOnly(patch: {
            $0["minutes"] = 25
            $0["progress"] = ["elapsedSeconds": 1501]
        }, departedPaused: true)
    }

    // 깨짐: 경과 음수 파일을 읽어 살리면 실패. (AC-21)
    func testAC21_경과_음수_파일은_여정만_버리고_카드는_유지된다() throws {
        try assertReadDropsJourneyOnly(patch: { $0["progress"] = ["elapsedSeconds": -1] }, departedPaused: true)
    }

    // 깨짐: 출발 대기 + paused=true 파일을 읽어 살리면 실패. (invalidPausedState)
    func testPaused_출발대기_paused_true_파일은_여정만_버린다() throws {
        try assertReadDropsJourneyOnly(patch: { $0["paused"] = true })
    }

    // 깨짐: v5에서 paused 키 누락을 기본값으로 채워 살리거나 파일 전체를 corrupt로 던지면 실패. (BR-9)
    func testBR9_v5에서_paused_키가_없으면_여정만_버리고_카드는_유지된다() throws {
        try assertReadDropsJourneyOnly(patch: { $0.removeValue(forKey: "paused") })
    }

    // MARK: - v5 왕복 (AC-23)

    // 깨짐: paused 또는 경과를 인코드/디코드에서 빠뜨리면 실패. (AC-23)
    func testAC23_paused_true_경과300은_버전5로_저장되고_같은_값으로_읽힌다() throws {
        try withTemporaryFile { fileURL in
            let journey = departed(elapsed: 300, paused: true)
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: journey))

            let root = try rootObject(fileURL)
            XCTAssertEqual(root["version"] as? Int, 5)
            XCTAssertEqual(try activeObject(fileURL)["paused"] as? Bool, true)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
            XCTAssertEqual(loaded.journey.active, journey)
            XCTAssertEqual(loaded.journey.active?.progress.elapsedSeconds, 300)
            XCTAssertEqual(loaded.journey.active?.paused, true)
        }
    }

    // 깨짐: paused=false를 true로 바꿔 읽으면(phase로 추정) 실패. (AC-23)
    func testAC23_paused_false_경과300은_그대로_읽힌다() throws {
        try withTemporaryFile { fileURL in
            let journey = departed(elapsed: 300, paused: false)
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: journey))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
            XCTAssertEqual(loaded.journey.active?.paused, false)
        }
    }

    // MARK: - helpers

    private func assertWriteRejected(
        _ journey: JourneySnapshot, _ issue: ActiveJourneyValidationIssue,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(F.snapshot(active: F.awaiting()))
            let before = try Data(contentsOf: fileURL)

            assertStorageIssue(.invalidState(.invalidActiveJourney(issue)), file: file, line: line) {
                try store.save(F.snapshot(active: journey))
            }
            XCTAssertEqual(try Data(contentsOf: fileURL), before, file: file, line: line)
        }
    }

    /// 유효한 v5 파일을 저장한 뒤 active를 patch로 손상시키고, 읽으면 여정만 버려지는지 확인한다.
    private func assertReadDropsJourneyOnly(
        patch: (inout [String: Any]) -> Void, departedPaused: Bool = false,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        try withTemporaryFile { fileURL in
            let source = departedPaused ? departed(minutes: 25, elapsed: 0, paused: true) : F.awaiting()
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: source))
            try rewriteActive(fileURL, version: nil, patch: patch)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load(), file: file, line: line)

            XCTAssertNil(loaded.journey.active, file: file, line: line)
            XCTAssertEqual(loaded.cards.items.map(\.id), [F.cardID], file: file, line: line)
            XCTAssertEqual(loaded.currentStation, StationSnapshot(id: "seongsu", name: "성수"), file: file, line: line)
        }
    }

    private func rewriteActive(_ fileURL: URL, version: Int?, patch: (inout [String: Any]) -> Void) throws {
        var root = try rootObject(fileURL)
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        var journey = try XCTUnwrap(state["journey"] as? [String: Any])
        var active = try XCTUnwrap(journey["active"] as? [String: Any])
        patch(&active)
        journey["active"] = active
        state["journey"] = journey
        root["state"] = state
        if let version { root["version"] = version }
        try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]).write(to: fileURL)
    }

    private func rootObject(_ fileURL: URL) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
    }

    private func activeObject(_ fileURL: URL) throws -> [String: Any] {
        let state = try XCTUnwrap(try rootObject(fileURL)["state"] as? [String: Any])
        let journey = try XCTUnwrap(state["journey"] as? [String: Any])
        return try XCTUnwrap(journey["active"] as? [String: Any])
    }
}
