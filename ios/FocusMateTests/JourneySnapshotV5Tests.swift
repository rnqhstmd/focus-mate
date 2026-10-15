import Foundation
import XCTest
@testable import FocusMate

/// v5 진행 여정: 표시용 필드를 저장하고, 카탈로그 없이 구조만 검증한다.
final class JourneySnapshotV5Tests: XCTestCase {
    private typealias F = W16bFixtures

    private func assertIssue(
        _ expected: ActiveJourneyValidationIssue, _ journey: JourneySnapshot,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        do {
            try journey.validate(currentCardID: journey.cardID)
            XCTFail("통과함: 기대 \(expected)", file: file, line: line)
        } catch let issue as ActiveJourneyValidationIssue {
            XCTAssertEqual(issue, expected, file: file, line: line)
        } catch {
            XCTFail("다른 에러 \(error)", file: file, line: line)
        }
    }

    // 깨짐: boarding이 새 필드(출발·버스·도착)를 details.journey에서 복사하지 않으면 실패한다.
    func testBoardingCopiesStoredDisplayFieldsFromSelection() {
        let selection = JourneySelection(
            originStopID: "A", originName: "에이", boundLabel: "비 방면", minutes: 25,
            busID: "r-100", busNumber: "100", busKind: "간선",
            destinationStopID: "D", destination: "디", stops: 3, distanceMeters: 1800
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let details = PreparedJourneyDetails(journey: selection, tag: tag, task: "책 읽기", sound: .bus)

        let journey = JourneySnapshot.boarding(details: details, cardID: F.cardID, id: "journey-1", boardedAt: F.boardedAt)

        XCTAssertEqual(journey.originStopID, "A")
        XCTAssertEqual(journey.originName, "에이")
        XCTAssertEqual(journey.minutes, 25)
        XCTAssertEqual(journey.busID, "r-100")
        XCTAssertEqual(journey.busNumber, "100")
        XCTAssertEqual(journey.busKind, "간선")
        XCTAssertEqual(journey.destinationStopID, "D")
        XCTAssertEqual(journey.destinationName, "디")
        XCTAssertEqual(journey.phase, .awaitingDeparture)
        XCTAssertEqual(journey.progress, JourneySnapshot.Progress.start)
    }

    // 깨짐: PreparedJourneyDetails의 표시값이 선택 값에서 오지 않으면 실패한다.
    func testPreparedDetailsDisplayValuesComeFromSelection() {
        let selection = JourneySelection(
            originStopID: "A", originName: "에이", boundLabel: "비 방면", minutes: 25,
            busID: "r-100", busNumber: "100", busKind: "간선",
            destinationStopID: "D", destination: "디", stops: 3, distanceMeters: 1800
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let details = PreparedJourneyDetails(journey: selection, tag: tag, task: "책 읽기", sound: .bus)
        XCTAssertEqual(details.originName, "에이")
        XCTAssertEqual(details.boundLabel, "비 방면")
        XCTAssertEqual(details.distanceText, "1.8km")
    }

    // 깨짐: 새 필드 중 하나라도 인코드/디코드에서 빠지면 왕복 비교가 실패한다.
    func testStoredFieldsRoundTripThroughStore() throws {
        try withTemporaryFile { fileURL in
            let journey = F.journey(
                originName: "출발 이름", busNumber: "N37", busKind: "심야", destinationName: "도착 이름"
            )
            try LocalSnapshotStore(fileURL: fileURL).save(F.appSnapshot(active: journey))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
            XCTAssertEqual(loaded.journey.active, journey)
            XCTAssertEqual(loaded.journey.active?.originName, "출발 이름")
            XCTAssertEqual(loaded.journey.active?.busNumber, "N37")
            XCTAssertEqual(loaded.journey.active?.busKind, "심야")
            XCTAssertEqual(loaded.journey.active?.destinationName, "도착 이름")
        }
    }

    // 깨짐: 인코딩 키 이름이 명세와 다르거나 direction 키가 남아 있으면 실패한다.
    func testEncodedKeysMatchSpec() throws {
        let data = try SnapshotCodec.encode(F.appSnapshot(active: F.journey()))
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let state = try XCTUnwrap(root["state"] as? [String: Any])
        let area = try XCTUnwrap(state["journey"] as? [String: Any])
        let active = try XCTUnwrap(area["active"] as? [String: Any])
        let expected: Set<String> = [
            "id", "cardID", "originStopID", "originName", "minutes", "busID", "busNumber", "busKind",
            "destinationStopID", "destinationName", "tag", "task", "sound", "boardedAt", "phase", "progress", "paused",
        ]
        XCTAssertEqual(Set(active.keys), expected)
    }

    // 깨짐: 카탈로그에 없는 id를 검증이 거절하면 실패한다 (카탈로그 검사 없음).
    func testUnknownIdsPassValidationBecauseCatalogIsNotConsulted() {
        let journey = F.journey(originStopID: "gone-stop", busID: "gone-bus", destinationStopID: "gone-dest")
        XCTAssertNoThrow(try journey.validate(currentCardID: F.cardID))
    }

    // 깨짐: 새 문자열 필드의 빈 값/공백을 필드명과 함께 거절하지 않으면 실패한다.
    func testBlankStringFieldsAreRejectedWithFieldName() {
        let cases: [(String, JourneySnapshot)] = [
            ("originName", F.journey(originName: "  ")),
            ("busID", F.journey(busID: "")),
            ("busNumber", F.journey(busNumber: " ")),
            ("busKind", F.journey(busKind: "")),
            ("destinationStopID", F.journey(destinationStopID: " ")),
            ("destinationName", F.journey(destinationName: "")),
            ("originStopID", F.journey(originStopID: "")),
        ]
        for (name, journey) in cases {
            assertIssue(.emptyField(name), journey)
        }
    }

    // 깨짐: 이름류 길이 상한(UTF-16 500 초과)을 필드별로 검사하지 않으면 실패한다.
    func testNamesOverFiveHundredUTF16UnitsAreRejected() {
        let long = String(repeating: "가", count: 501)
        assertIssue(.nameTooLong("originName"), F.journey(originName: long))
        assertIssue(.nameTooLong("destinationName"), F.journey(destinationName: long))
        assertIssue(.nameTooLong("busNumber"), F.journey(busNumber: long))
        assertIssue(.nameTooLong("busKind"), F.journey(busKind: long))
    }

    // 깨짐: 상한을 500 미만으로 잡거나 이상(>=)으로 비교하면 정확히 500에서 실패한다.
    func testNamesOfExactlyFiveHundredUnitsAreAccepted() {
        let exact = String(repeating: "가", count: 500)
        XCTAssertNoThrow(try F.journey(
            originName: exact, busNumber: exact, busKind: exact, destinationName: exact
        ).validate(currentCardID: F.cardID))
    }

    // 깨짐: 글자 수(Character)로 세면 이모지 251개(UTF-16 502)가 통과해 실패한다.
    func testLengthIsCountedInUTF16UnitsNotCharacters() {
        let emojis = String(repeating: "😀", count: 251)
        XCTAssertEqual(emojis.count, 251)
        assertIssue(.nameTooLong("destinationName"), F.journey(destinationName: emojis))
        XCTAssertNoThrow(try F.journey(destinationName: String(repeating: "😀", count: 250)).validate(currentCardID: F.cardID))
    }

    // 깨짐: 쓰기 경로가 nameTooLong을 저장 거부로 올리지 않으면 실패한다.
    func testWritingTooLongNameIsRejectedAndFileUnchanged() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(F.appSnapshot(active: F.journey()))
            let before = try Data(contentsOf: fileURL)

            let bad = F.journey(destinationName: String(repeating: "가", count: 501))
            assertStorageIssue(.invalidState(.invalidActiveJourney(.nameTooLong("destinationName")))) {
                try store.save(F.appSnapshot(active: bad))
            }
            XCTAssertEqual(try Data(contentsOf: fileURL), before)
        }
    }

    // 깨짐: 새 필드가 빠진 손상 여정을 살려 읽거나, 여정 때문에 파일 전체·카드·정류장을 잃으면 실패한다.
    func testV5FileMissingStoredFieldDropsOnlyTheJourney() throws {
        var root = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try SnapshotCodec.encode(F.appSnapshot(active: F.journey()))) as? [String: Any]
        )
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        var area = try XCTUnwrap(state["journey"] as? [String: Any])
        var active = try XCTUnwrap(area["active"] as? [String: Any])
        active.removeValue(forKey: "destinationName")
        area["active"] = active
        state["journey"] = area
        root["state"] = state
        let data = try JSONSerialization.data(withJSONObject: root)
        let decoded = try SnapshotCodec.decode(data)
        XCTAssertNil(decoded.journey.active)
        XCTAssertEqual(decoded.cards.items.map(\.id), [F.cardID])
        XCTAssertEqual(decoded.currentStation, F.stationA)
        XCTAssertEqual(decoded.initialStation, F.stationA)
    }
}
