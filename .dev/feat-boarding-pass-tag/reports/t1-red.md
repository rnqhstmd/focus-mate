# T1 RED report
최종 경로(오케스트레이터가 이동): ios/FocusMateTests/{BoardingTestDoubles,JourneySnapshotTests,JourneySnapshotStorageTests}.swift (현재 red-staging/)
케이스: JourneySnapshotTests 20, JourneySnapshotStorageTests 13 (미실행)
실패 확인: FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/JourneySnapshotTests.swift ios/FocusMateTests/JourneySnapshotStorageTests.swift
예상 실패: 컴파일 RED (JourneySnapshot, ActiveJourneyFactory, ActiveJourneyValidationIssue, invalidActiveJourney, Codable 아이콘 등 미정의)
참조: design.md, ios/FocusMateTests/{StorageV2Tests,AppSnapshotSectionsTests,PreparationDetailsTests,StorageTestSupport,CardStorageTests}.swift, grep으로 ios/FocusMate/JourneySection.swift·JourneyPlanDraft.swift·PreparationDraft.swift의 init/필드 일부 노출(코드 본문 미검토)
가정: JourneySnapshot memberwise init 순서=설계서 필드 순서, JourneySection(active:), AppSnapshot.updating(journey:), issuingCard, 원점 "성수역", 버스 BusLine.id, 아이콘 raw=case명.

--- 코드 전문 ---
## BoardingTestDoubles.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 승차권·태그 기능 테스트가 함께 쓰는 픽스처.
enum BoardingFixtures {
    static let cardID = "FM-01234567"
    static let boardedAt = Date(timeIntervalSince1970: 1_791_882_000) // 2026-10-13T09:00:00Z

    static var details: PreparedJourneyDetails {
        let journey = JourneySelection(
            origin: StopPosition(index: 0, direction: 1), minutes: 60,
            busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        return PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)
    }

    static func awaiting() -> JourneySnapshot {
        JourneySnapshot.boarding(details: details, cardID: cardID, id: "journey-1", boardedAt: boardedAt)
    }

    /// 한 필드만 바꿔 위반 후보를 만든다. 기본값은 유효한 대기 상태 여정.
    static func journey(
        id: String = "journey-1",
        cardID: String = BoardingFixtures.cardID,
        originStopID: String = "seongsu",
        direction: Int = 1,
        minutes: Int = 60,
        busID: String = "2014",
        destinationStopID: String = "seongsu-dest",
        tag: JourneySnapshot.Tag = JourneySnapshot.Tag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand),
        task: String = "책 읽기",
        phase: JourneySnapshot.Phase = .awaitingDeparture,
        elapsedSeconds: Int = 0
    ) -> JourneySnapshot {
        JourneySnapshot(
            id: id, cardID: cardID, originStopID: originStopID, direction: direction, minutes: minutes,
            busID: busID, destinationStopID: destinationStopID, tag: tag, task: task, sound: .bus,
            boardedAt: boardedAt, phase: phase, progress: JourneySnapshot.Progress(elapsedSeconds: elapsedSeconds)
        )
    }

    static func snapshot(active: JourneySnapshot?) -> AppSnapshot {
        let station = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
        return XCTestCase.stage(true, station, station)
            .issuingCard(CardSnapshot(id: cardID, issuedAt: boardedAt))
            .updating(journey: JourneySection(active: active))
    }
}
```
## JourneySnapshotTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class JourneySnapshotTests: XCTestCase {
    private typealias F = BoardingFixtures

    // MARK: - 생성 (AC-11 저장 내용, AC-19)

    // 깨짐: boarding이 위치·방향·시간·할 일·소리 중 하나라도 빠뜨리거나 잘못 복사하면 실패.
    func testAC11_승차값은_위치_방향_시간_할일_소리를_담는다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.id, "journey-1")
        XCTAssertEqual(journey.cardID, "FM-01234567")
        XCTAssertEqual(journey.originStopID, "seongsu")
        XCTAssertEqual(journey.direction, 1)
        XCTAssertEqual(journey.minutes, 60)
        XCTAssertEqual(journey.busID, "2014")
        XCTAssertEqual(journey.task, "책 읽기")
        XCTAssertEqual(journey.sound, .bus)
        XCTAssertEqual(journey.boardedAt, F.boardedAt)
    }

    // 깨짐: 도착 정류장 id를 계산하지 않거나(빈 값) 출발 정류장과 같게 두면 실패.
    func testAC11_도착정류장은_출발에서_12정류장_이동한_정류장으로_확정된다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.destinationStopID, RouteStops.all[12 % RouteStops.all.count].id)
        XCTAssertNotEqual(journey.destinationStopID, journey.originStopID)
    }

    // 깨짐: 태그 정의(id·이름·아이콘·색) 중 하나라도 복사하지 않으면 실패.
    func testAC11_승차값은_태그_정의_전체를_복사해_담는다() {
        let tag = F.awaiting().tag

        XCTAssertEqual(tag, JourneySnapshot.Tag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand))
    }

    // 깨짐: 초기 phase가 awaitingDeparture가 아니거나 진도가 0이 아니면 실패.
    func testAC19_승차값은_출발확인_전이고_진도0이다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.phase, .awaitingDeparture)
        XCTAssertEqual(journey.progress.elapsedSeconds, 0)
        XCTAssertEqual(journey.progress, JourneySnapshot.Progress.start)
    }

    // MARK: - 출발 확인 (AC-20)

    // 깨짐: confirmingDeparture가 phase를 바꾸지 않으면 실패.
    func testAC20_출발확인은_phase를_departed로_바꾼다() {
        XCTAssertEqual(F.awaiting().confirmingDeparture().phase, .departed)
    }

    // 깨짐: confirmingDeparture가 진도를 올리거나 다른 필드를 바꾸면 실패.
    func testAC20_출발확인은_phase_외_값을_바꾸지_않고_진도는_0이다() {
        let before = F.awaiting()
        let after = before.confirmingDeparture()

        XCTAssertEqual(after.progress.elapsedSeconds, 0)
        XCTAssertEqual(after, F.journey(phase: .departed, elapsedSeconds: 0).withDestination(before.destinationStopID))
    }

    // MARK: - 표시 조회

    // 깨짐: 카탈로그 조회가 이름을 못 돌려주면 실패.
    func testAC11_카탈로그_안의_id는_표시_이름과_버스를_조회한다() {
        let journey = F.awaiting()

        XCTAssertEqual(journey.originName, "성수역")
        XCTAssertEqual(journey.bus?.id, "2014")
    }

    // 깨짐: 카탈로그 밖 id에서 검증이 실패하거나 조회가 nil이 아니면 실패.
    func testAC11_카탈로그_밖_id는_검증을_통과하고_조회는_nil이다() throws {
        let journey = F.journey(originStopID: "gone-stop", busID: "gone-bus", destinationStopID: "gone-dest")

        XCTAssertNoThrow(try journey.validate(currentCardID: F.cardID))
        XCTAssertNil(journey.originName)
        XCTAssertNil(journey.destinationName)
        XCTAssertNil(journey.bus)
    }

    // MARK: - 구조 검증 (설계 A-1)

    // 깨짐: 유효한 대기 상태 여정을 검증이 거절하면 실패.
    func testA1_유효한_여정은_검증을_통과한다() throws {
        XCTAssertNoThrow(try F.awaiting().validate(currentCardID: F.cardID))
        XCTAssertNoThrow(try F.awaiting().confirmingDeparture().validate(currentCardID: F.cardID))
    }

    // 깨짐: 빈 문자열 필드 중 하나라도 검증하지 않으면 실패.
    func testA1_빈_문자열_필드는_emptyField로_거절된다() {
        let candidates: [JourneySnapshot] = [
            F.journey(id: ""),
            F.journey(cardID: ""),
            F.journey(originStopID: ""),
            F.journey(busID: ""),
            F.journey(destinationStopID: ""),
            F.journey(tag: JourneySnapshot.Tag(id: "", name: "독서", icon: .reading, color: .sand)),
        ]
        for (index, candidate) in candidates.enumerated() {
            do {
                try candidate.validate(currentCardID: candidate.cardID)
                XCTFail("후보 \(index) 가 통과함")
            } catch ActiveJourneyValidationIssue.emptyField {
            } catch {
                XCTFail("후보 \(index) 에서 emptyField 대신 \(error)")
            }
        }
    }

    // 깨짐: direction이 ±1 외일 때 거절하지 않으면 실패.
    func testA1_방향이_1이나_음수1이_아니면_거절된다() {
        assertIssue(.invalidDirection(0), F.journey(direction: 0))
        assertIssue(.invalidDirection(2), F.journey(direction: 2))
        XCTAssertNoThrow(try F.journey(direction: -1).validate(currentCardID: F.cardID))
    }

    // 깨짐: minutes <= 0을 통과시키면 실패.
    func testA1_분이_0이하면_거절된다() {
        assertIssue(.invalidMinutes(0), F.journey(minutes: 0))
        assertIssue(.invalidMinutes(-5), F.journey(minutes: -5))
        XCTAssertNoThrow(try F.journey(minutes: 1).validate(currentCardID: F.cardID))
    }

    // 깨짐: 할 일 trim 불일치·빈 값·UTF-16 80 초과 중 하나라도 통과시키면 실패.
    func testA1_할일이_공백포함_빈값_80초과면_거절된다() {
        assertIssue(.invalidTask, F.journey(task: " 책 읽기"))
        assertIssue(.invalidTask, F.journey(task: "책 읽기\n"))
        assertIssue(.invalidTask, F.journey(task: ""))
        assertIssue(.invalidTask, F.journey(task: String(repeating: "a", count: 81)))
        XCTAssertNoThrow(try F.journey(task: String(repeating: "a", count: 80)).validate(currentCardID: F.cardID))
    }

    // 깨짐: 태그 이름 빈값(공백)·20 초과를 통과시키면 실패.
    func testA1_태그이름이_공백뿐이거나_20초과면_거절된다() {
        func tag(_ name: String) -> JourneySnapshot.Tag {
            JourneySnapshot.Tag(id: "t", name: name, icon: .reading, color: .sand)
        }
        assertIssue(.invalidTag, F.journey(tag: tag("   ")))
        assertIssue(.invalidTag, F.journey(tag: tag(String(repeating: "a", count: 21))))
        XCTAssertNoThrow(try F.journey(tag: tag(String(repeating: "a", count: 20))).validate(currentCardID: F.cardID))
    }

    // 깨짐: 음수 elapsedSeconds를 통과시키면 실패.
    func testA1_진도가_음수면_거절된다() {
        assertIssue(.invalidProgress, F.journey(phase: .departed, elapsedSeconds: -1))
        XCTAssertNoThrow(try F.journey(phase: .departed, elapsedSeconds: 0).validate(currentCardID: F.cardID))
    }

    // 깨짐: awaitingDeparture에서 진도 != 0을 통과시키면 실패.
    func testAC19_출발확인_전에_진도가_0이_아니면_거절된다() {
        assertIssue(.invalidProgress, F.journey(phase: .awaitingDeparture, elapsedSeconds: 1))
    }

    // 깨짐: departed에서 진도 양수를 거절하면 실패(대기 상태에만 0 강제).
    func testAC19_출발확인_후에는_진도_양수가_허용된다() {
        XCTAssertNoThrow(try F.journey(phase: .departed, elapsedSeconds: 30).validate(currentCardID: F.cardID))
    }

    // 깨짐: cardID 불일치(다른 카드·카드 없음)를 통과시키면 실패.
    func testA1_카드가_다르거나_없으면_cardMismatch로_거절된다() {
        let journey = F.journey()
        XCTAssertThrowsError(try journey.validate(currentCardID: "FM-76543210")) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, .cardMismatch)
        }
        XCTAssertThrowsError(try journey.validate(currentCardID: nil)) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, .cardMismatch)
        }
    }

    // MARK: - 팩토리

    // 깨짐: 팩토리가 주입한 makeID를 쓰지 않거나 cardID·세부값을 넘기지 않으면 실패.
    func testFactory_주입한_ID로_대기상태_여정을_만든다() {
        let factory = ActiveJourneyFactory(makeID: { "fixed-id" }, now: { F.boardedAt })

        let journey = factory.make(details: F.details, cardID: F.cardID)

        XCTAssertEqual(journey.id, "fixed-id")
        XCTAssertEqual(journey.cardID, F.cardID)
        XCTAssertEqual(journey.phase, .awaitingDeparture)
        XCTAssertEqual(journey.minutes, 60)
    }

    // 깨짐: boardedAt을 초 단위로 내리지 않고 소수 초를 보존하거나 올림하면 실패.
    func testFactory_boardedAt은_초단위로_내림된다() {
        let factory = ActiveJourneyFactory(
            makeID: { "x" },
            now: { Date(timeIntervalSince1970: 1_791_882_000.999) }
        )

        XCTAssertEqual(factory.make(details: F.details, cardID: F.cardID).boardedAt.timeIntervalSince1970, 1_791_882_000)
    }

    // MARK: - helpers

    private func assertIssue(
        _ expected: ActiveJourneyValidationIssue,
        _ journey: JourneySnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try journey.validate(currentCardID: journey.cardID), file: file, line: line) {
            XCTAssertEqual($0 as? ActiveJourneyValidationIssue, expected, file: file, line: line)
        }
    }
}

private extension JourneySnapshot {
    /// 도착 정류장 id만 다른 값으로 바꾼 사본(기대값 구성용).
    func withDestination(_ id: String) -> JourneySnapshot {
        BoardingFixtures.journey(
            id: self.id, cardID: cardID, originStopID: originStopID, direction: direction, minutes: minutes,
            busID: busID, destinationStopID: id, tag: tag, task: task, phase: phase,
            elapsedSeconds: progress.elapsedSeconds
        )
    }
}
```
## JourneySnapshotStorageTests.swift
```swift
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

    // 깨짐: v3 파일의 active가 단일 객체가 아니거나 version이 3이 아니면 실패. (BR-8, currentVersion 3 유지)
    func testBR8_저장된_active는_단일_객체이고_version은_3이다() throws {
        try withTemporaryFile { fileURL in
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: F.awaiting()))

            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 3)
            let state = try XCTUnwrap(root["state"] as? [String: Any])
            let journey = try XCTUnwrap(state["journey"] as? [String: Any])
            let active = try XCTUnwrap(journey["active"] as? [String: Any])
            XCTAssertEqual(active["cardID"] as? String, "FM-01234567")
            XCTAssertEqual(active["phase"] as? String, "awaitingDeparture")
            XCTAssertEqual(active["boardedAt"] as? String, "2026-10-13T09:00:00Z")
            XCTAssertEqual((active["progress"] as? [String: Any])?["elapsedSeconds"] as? Int, 0)
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

    // 깨짐: {} 를 active로 받아들이면 실패 (AppSnapshotSectionsTests 의 손상 계약 유지).
    func testV3_active가_빈_객체면_corrupt다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v3(active: "{}"))

            assertStorageIssue(.corrupt) { _ = try LocalSnapshotStore(fileURL: fileURL).load() }
        }
    }

    // 깨짐: 문자열 active를 받아들이면 실패.
    func testV3_active가_문자열이면_corrupt다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v3(active: #""x""#))

            assertStorageIssue(.corrupt) { _ = try LocalSnapshotStore(fileURL: fileURL).load() }
        }
    }

    // 깨짐: 모르는 태그 아이콘 raw 값을 기본값으로 보정하면 실패.
    func testV3_모르는_아이콘_값은_corrupt다() throws {
        try withTemporaryFile { fileURL in
            try LocalSnapshotStore(fileURL: fileURL).save(F.snapshot(active: F.awaiting()))
            let text = try XCTUnwrap(String(data: Data(contentsOf: fileURL), encoding: .utf8))
            try seed(fileURL, Data(text.replacingOccurrences(of: #""icon":"reading""#, with: #""icon":"no-such-icon""#).utf8))

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

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: fileURL)
    }
}
```
