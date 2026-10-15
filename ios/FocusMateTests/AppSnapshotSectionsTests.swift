import Foundation
import XCTest
@testable import FocusMate

final class AppSnapshotSectionsTests: XCTestCase {
    private static let initialStation = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let currentStation = StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)

    private static var readySnapshot: AppSnapshot { stage(true, initialStation, currentStation) }

    // MARK: - 구조 보장 (FR-4)

    // 깨짐: empty의 영역 중 하나라도 비어 있지 않게 초기화하면 실패
    func testEmptySnapshotHasEmptyCardJourneyAndRecordSections() {
        XCTAssertEqual(AppSnapshot.empty.cards.items.count, 0)
        XCTAssertNil(AppSnapshot.empty.journey.active)
        XCTAssertEqual(AppSnapshot.empty.records.items.count, 0)
    }

    // 깨짐: updatingStage가 단계 필드를 무시하거나 순서를 바꾸면 실패
    func testUpdatingStageReplacesTheThreeStageFields() {
        let updated = AppSnapshot.empty.updatingStage(
            cardIssued: true,
            initialStation: Self.initialStation,
            currentStation: Self.currentStation
        )

        XCTAssertTrue(updated.cardIssued)
        XCTAssertEqual(updated.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        XCTAssertEqual(updated.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
    }

    // 깨짐: updatingStage가 영역을 .empty로 새로 만들어 원본 영역을 버리면(동등성 비교로는 W00에서 못 잡지만 영역 필드 교체 시) 실패
    func testUpdatingStageKeepsTheOriginalSections() {
        let updated = Self.readySnapshot.updatingStage(
            cardIssued: false,
            initialStation: nil,
            currentStation: nil
        )

        XCTAssertEqual(updated.cards, Self.readySnapshot.cards)
        XCTAssertEqual(updated.journey, Self.readySnapshot.journey)
        XCTAssertEqual(updated.records, Self.readySnapshot.records)
    }

    // 깨짐: updatingStage가 검증을 수행해 불일치 상태에서 throw/거부하거나 값을 보정하면 실패
    func testUpdatingStageDoesNotValidateInconsistentStage() {
        let inconsistent = Self.stage(false, Self.initialStation, nil)

        XCTAssertFalse(inconsistent.cardIssued)
        XCTAssertEqual(inconsistent.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        XCTAssertNil(inconsistent.currentStation)
    }

    // 깨짐: updating(cards:)가 단계 필드를 초기화(empty 기반 재생성)하면 실패
    func testUpdatingCardsKeepsTheStageFields() {
        let updated = Self.readySnapshot.updating(cards: CardSection.empty)

        XCTAssertTrue(updated.cardIssued)
        XCTAssertEqual(updated.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        XCTAssertEqual(updated.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
    }

    // 깨짐: updating(journey:)가 단계 필드를 초기화하면 실패
    func testUpdatingJourneyKeepsTheStageFields() {
        let updated = Self.readySnapshot.updating(journey: JourneySection.empty)

        XCTAssertTrue(updated.cardIssued)
        XCTAssertEqual(updated.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        XCTAssertEqual(updated.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
    }

    // 깨짐: updating(records:)가 단계 필드를 초기화하면 실패
    func testUpdatingRecordsKeepsTheStageFields() {
        let updated = Self.readySnapshot.updating(records: RecordSection.empty)

        XCTAssertTrue(updated.cardIssued)
        XCTAssertEqual(updated.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
        XCTAssertEqual(updated.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1))
    }

    // 깨짐: updating(cards:)가 다른 두 영역을 건드리면 실패
    func testUpdatingCardsKeepsTheJourneyAndRecordSections() {
        let updated = Self.readySnapshot.updating(cards: CardSection.empty)

        XCTAssertNil(updated.journey.active)
        XCTAssertEqual(updated.records.items.count, 0)
    }

    // MARK: - 인코딩 (AC-2)

    // 깨짐: 영역 키(cards/journey/records) 중 하나라도 인코딩에서 빠지거나, nil 정류장 키가 생략되면 실패
    func testSnapshotEncodesExactlyTheSixStateKeysEvenWhenStationsAreNil() throws {
        let data = try JSONEncoder().encode(AppSnapshot.empty)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(
            Set(object.keys),
            ["cardIssued", "cards", "currentStation", "initialStation", "journey", "records"]
        )
    }

    // 깨짐: nil 정류장을 키 생략으로 인코딩하면 실패
    func testNilStationsAreEncodedAsNullValues() throws {
        let data = try JSONEncoder().encode(AppSnapshot.empty)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertTrue(object["initialStation"] is NSNull)
        XCTAssertTrue(object["currentStation"] is NSNull)
    }

    // 깨짐: CardSection 인코딩 형태(키 이름 items·빈 배열)가 바뀌면 실패
    func testEmptyCardSectionEncodesAsEmptyItemsArray() throws {
        XCTAssertEqual(try sortedJSON(CardSection.empty), #"{"items":[]}"#)
    }

    // 깨짐: JourneySection이 active 키를 생략하거나 키 이름을 바꾸면 실패
    func testEmptyJourneySectionEncodesActiveAsNull() throws {
        XCTAssertEqual(try sortedJSON(JourneySection.empty), #"{"active":null}"#)
    }

    // 깨짐: RecordSection 인코딩 형태가 바뀌면 실패
    func testEmptyRecordSectionEncodesAsEmptyItemsArray() throws {
        XCTAssertEqual(try sortedJSON(RecordSection.empty), #"{"items":[]}"#)
    }

    // MARK: - 디코딩 정책

    // 깨짐: items 누락을 빈 배열로 관대하게 처리하면 실패
    func testCardSectionWithoutItemsKeyFailsToDecode() {
        XCTAssertThrowsError(try decode(CardSection.self, "{}"))
    }

    // 깨짐: items가 배열이 아닐 때 무시하면 실패
    func testCardSectionWithNonArrayItemsFailsToDecode() {
        XCTAssertThrowsError(try decode(CardSection.self, #"{"items":"x"}"#))
    }

    // 깨짐: 영역 값이 객체가 아닌 경우(배열)를 통과시키면 실패
    func testCardSectionAsArrayFailsToDecode() {
        XCTAssertThrowsError(try decode(CardSection.self, "[]"))
    }

    // 깨짐: 영역 값이 null일 때 empty로 대체하면 실패
    func testRecordSectionAsNullFailsToDecode() {
        XCTAssertThrowsError(try decode(RecordSection.self, "null"))
    }

    // 깨짐: 원소를 빈 객체로 받아 통과시키면 실패
    func testCardSectionWithObjectElementFailsToDecode() {
        XCTAssertThrowsError(try decode(CardSection.self, #"{"items":[{}]}"#))
    }

    // 깨짐: 원소를 숫자로 받아 통과시키면 실패
    func testRecordSectionWithScalarElementFailsToDecode() {
        XCTAssertThrowsError(try decode(RecordSection.self, #"{"items":[1]}"#))
    }

    // 깨짐: 모르는 키가 있을 때 오류를 던지면(엄격 모드) 실패
    func testCardSectionIgnoresUnknownKeys() throws {
        let section = try decode(CardSection.self, #"{"items":[],"extra":1}"#)

        XCTAssertEqual(section.items.count, 0)
    }

    // 깨짐: active 키 누락을 nil로 관대하게 처리하면 실패
    func testJourneySectionWithoutActiveKeyFailsToDecode() {
        XCTAssertThrowsError(try decode(JourneySection.self, "{}"))
    }

    // 깨짐: active:null을 오류로 처리하면 실패
    func testJourneySectionWithNullActiveDecodesToNil() throws {
        let section = try decode(JourneySection.self, #"{"active":null}"#)

        XCTAssertNil(section.active)
    }

    // 깨짐: 손상된 빈 객체 active에서 던지면(영역 전체 손상 처리) 실패 (F1 여정만 버리기)
    func testJourneySectionWithEmptyObjectActiveDecodesToNil() throws {
        let section = try decode(JourneySection.self, #"{"active":{}}"#)

        XCTAssertNil(section.active)
    }

    // 깨짐: 손상된 문자열 active에서 던지면 실패
    func testJourneySectionWithStringActiveDecodesToNil() throws {
        let section = try decode(JourneySection.self, #"{"active":"x"}"#)

        XCTAssertNil(section.active)
    }

    // MARK: - helpers

    private func sortedJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }
}
