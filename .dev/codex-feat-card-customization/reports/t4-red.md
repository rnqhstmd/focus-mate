# T4 RED — AppModel 카드 꾸미기 통합

## Status

- **AUTHORED_NOT_PASS**
- actual target 테스트: 16개 작성
- actual compile RED: pending
- build/test 실행: 부모의 declaration-ready 신호 이후로 보류
- 생산 코드·병행 AppModel extension scaffold 열람/검색/수정: 없음
- agent 추가 실행·commit: 없음

상위 오케스트레이터가 제공한 T3 게이트 증거는 cumulative 231/231 PASS(229 unit + 2 UI), 17 test hash 동일, production Controller 1 file, no fix다. 이 증거를 T4 승격 허가로 사용했으며 이 역할에서 재실행하지 않았다.

## 승격 결과

- 파일: `ios/FocusMateTests/CardCustomizationAppModelTests.swift`
- 승인 draft에서 `PENDING DRAFT ONLY` 주석 한 줄만 제거했다.
- 나머지 helper·테스트 본문·기대값은 filtered `cmp`로 byte-identical을 확인했다.
- XCTest 메서드 수는 16개다.

병행 declaration-only producer의 신규 API가 현재 nil/false/`.standard`를 반환하는 것은 GREEN 구현이 아니라 compile scaffold다. 부모가 focused 실행에서 컴파일 성공과 실제 assertion RED를 분리해 기록해야 한다. 이 역할은 producer 소스를 읽지 않았다.

## 저장 여정 계약 제한

현재 `JourneySnapshot`은 case가 없는 enum이며 저장 계층에서 표현 가능한 여정은 `JourneySection(active: nil)`뿐이다. 기존 최신 snapshot 보존 테스트는 정류장과 기록을 실제 공개 API로 바꾼 후 외형 저장·재로드에서 records와 `active == nil`을 보존한다. nonempty 저장 여정 값, setter, mock seam을 발명하지 않는다.

별도 16번째 경계는 같은 실행의 메모리 `journeyPlan`과 계산된 `preparedJourney`가 외형 저장 뒤 유지되는지 확인한다. 기대는 origin index 0/direction 1, minutes 60, busID/number 2014, destination 성동구민체육센터, stops 12의 독립 리터럴이다. 재실행 `preparedJourney` 영속성을 주장하지 않는다. 따라서 이전 NEEDS_CONTEXT는 해소됐고 현재 계층 제한으로 문서화됐다.

## 16개 AC 매트릭스

| # | 테스트 | AC | 관찰 계약 | 잡히는 잘못된 변경 |
|---|---|---|---|---|
| 1 | `testAC01_ready발급카드는_저장외형으로_진입하고_정체성과_파일을_유지한다` | AC01 | ready 발급 카드의 main·initialStationEntry 진입, 저장 외형 복제, 무쓰기 | ready 발급 카드의 진입을 거절하거나 draft를 기본값으로 만들면 실패. |
| 2 | `testAC02_미발급은_초안없이_cardEntry를_유지하고_저장을_거부한다` | AC02 | 미발급은 controller·저장을 거부하고 cardEntry·무파일을 유지 | 미발급 진입이 controller를 만들거나 save가 파일을 생성하면 실패. |
| 3 | `test로드전은_진입과_저장을_거부하고_notReady를_반환한다` | AC02 | load 전 진입·저장을 notReady로 거부하고 기존 파일을 보존 | load 전 저장이 준비상태 가드 없이 실행되면 실패. |
| 4 | `test발급플래그만_있고_카드가_없으면_notReady로_거부한다` | AC02/29 | issued 플래그만 있고 currentCard가 없으면 진입·저장 거부 | cardIssued만 보고 카드가 없는 상태에서 초안 생성/저장을 허용하면 실패. |
| 5 | `testID불일치는_notReady이고_기존카드를_유지한다` | AC30 | 전달 cardID 불일치를 notReady로 거부하고 기존 파일 보존 | 전달 CardID 검사를 제거하면 다른 카드용 외형이 저장되어 실패. |
| 6 | `testAC30_진입후_바뀐_최신정류장과_기록을_외형저장이_보존한다` | AC30 | 진입 뒤 최신 정류장·기록 변경을 controller 외형 저장과 재로드에서 보존 | 진입 snapshot을 저장에 재사용하면 이후 정류장/메모 변경이 소실되어 실패. |
| 7 | `testAC30_외형저장은_메모리preparedJourney선택을_그대로유지한다` | AC30 | 외형 저장 전후 실행 중 preparedJourney 리터럴과 currentStation 보존 | 카드 외형 저장이 journeyPlan 또는 preparedJourney를 초기화하면 실행 중 준비 선택이 소실되어 실패. |
| 8 | `test진입후_현재카드가_바뀌면_이전세션_저장을_거부한다` | AC30 | 진입 뒤 현재 카드 ID가 바뀌면 이전 controller 저장 거부 | 저장 때 최신 CardID를 확인하지 않으면 새 카드 외형을 덮어써 실패. |
| 9 | `testAC30_공통외형은_초안수정과_버리기에_저장값을_공급한다` | AC30 | 미저장 draft·discard가 currentCardStyle 저장값에 유출되지 않음 | 저장 성공 전 currentCardStyle이 draft를 공급하면 실패. |
| 10 | `testAC24_실제파일_저장후_새모델은_여섯사진과_색_배치_순서를_복원한다` | AC24/25 | 실제 파일에 사진 6장 색·배치·순서를 저장하고 새 store/model로 복원 | 외형만/일부 사진만 저장하거나 순서/배치를 잃으면 새 AppModel 검증이 실패. |
| 11 | `test무효후보색은_saveFailure를_반환하고_저장상태를_보존한다` | AC26 | 무효 RGB 후보를 invalidCardStyle로 거부하고 원본 보존 | 무효 RGB 후보를 성공 처리하면 오류 분류와 원본 비교에서 실패. |
| 12 | `test손상사진_후보는_invalidCardPhoto이고_실제원본을_보존한다` | AC28 | 실제 손상 PNG 후보를 invalidCardPhoto로 거부하고 원본 보존 | actual PNG 후보 검증을 생략하면 손상 사진 저장을 성공 처리하여 실패. |
| 13 | `test읽기실패_시작은_진입을_막고_writeBlocked로_원본을_보존한다` | AC28 | corrupt/unsupported launch를 writeBlocked 원인으로 유지하고 원본 보존 | failed launch를 notReady로 축소하거나 원본을 덮어쓰면 실패. |
| 14 | `test진입후_원본이_손상되면_저장은_writeBlocked이고_초안을_유지한다` | AC26/28 | 진입 뒤 손상된 실제 원본을 writeBlocked로 거부하고 draft 유지 | 저장 시 원본 재검사를 생략하면 진입 후 손상된 원본을 덮어써 실패. |
| 15 | `testAC26_실제쓰기실패는_초안과_원본을_유지하고_재시도후에만_복원된다` | AC26 | writeData 1회 실패에서 draft·선택·undo·파일 보존 후 실제 재시도 성공 | 쓰기 실패 때 baseline/selection/history를 지우거나 재시도를 막으면 실패. |
| 16 | `testAC29_v2진입은_쓰기없고_외형저장때만_v3로_전환한다` | AC29 | v2 begin은 무쓰기, controller save에서만 v3 전환하고 이용 상태 보존 | begin이 v2를 쓰거나 saveCardStyle가 v3 변환/이용상태를 잃으면 실패. |

## 컴파일·RED 상태

명령과 실패 메시지는 아직 없다. 부모가 declaration-ready 뒤 focused 테스트를 1회 실행한다. assertion 실패 전 테스트 자체 컴파일 오류가 있으면 이 역할은 테스트 파일만 최소 수정하며, 생산 scaffold 구현은 담당하지 않는다. 현 상태를 PASS 또는 actual RED로 보고하지 않는다.

## 참조한 파일

- `.dev/codex-feat-card-customization/drafts/CardCustomizationAppModelTests.swift`
- `.dev/codex-feat-card-customization/reports/t4-test-draft.md`
- `.dev/codex-feat-card-customization/reports/t4-journey-contract.md`
- `.dev/codex-feat-card-customization/design.md`
- `ios/FocusMateTests/JourneyStartModelTests.swift`

생산 소스와 T3 target/source는 참조하지 않았다.

## 전체 코드

```swift
import Foundation
import XCTest
@testable import FocusMate

// T2/T3/T4 declarations must be available before promotion. Never add production setters.
@MainActor
final class CardCustomizationAppModelTests: XCTestCase {
    private enum ProbeError: Error { case write }
    private static let cardID = "FM-01234567"
    private static let issuedAt = Date(timeIntervalSince1970: 1_791_882_000)
    private static let editedColor = CardColor(red: 0.2, green: 0.3, blue: 0.4)
    private static let recordJSON = ##"{"id":"journey-001","completedAt":"2026-10-13T01:00:00Z","date":"2026-10-13","bus":"버스2014","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","minutes":25,"sound":"빗소리","from":"성수역","to":"서울숲 입구","memo":"첫 메모"}"##
    private static let legacyV2 = Data(#"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"}]},"journey":{"active":null},"records":{"items":[\#(recordJSON)]}}}"#.utf8)

    private func snapshot(style: CardStyle = .standard, id: String = Self.cardID) throws -> AppSnapshot {
        let base = try SnapshotCodec.decode(Self.legacyV2)
        let cards = Self.stage(true, nil, nil).issuingCard(
            CardSnapshot(id: id, issuedAt: Self.issuedAt, style: style)).cards
        return base.updating(cards: cards)
    }

    private func seed(_ url: URL, style: CardStyle = .standard) throws {
        try LocalSnapshotStore(fileURL: url).save(snapshot(style: style))
    }

    private func loadedModel(_ url: URL) -> AppModel {
        let model = AppModel(store: LocalSnapshotStore(fileURL: url))
        model.loadIfNeeded()
        return model
    }

    private func assertIdentity(_ snapshot: AppSnapshot?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(snapshot?.cards.items.count, 1, file: file, line: line)
        XCTAssertEqual(snapshot?.currentCard?.id, "FM-01234567", file: file, line: line)
        XCTAssertEqual(snapshot?.currentCard?.issuedAt, Date(timeIntervalSince1970: 1_791_882_000), file: file, line: line)
    }

    private func assertOriginalUsage(_ snapshot: AppSnapshot?, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(snapshot?.cardIssued, true, file: file, line: line)
        XCTAssertEqual(snapshot?.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1), file: file, line: line)
        XCTAssertEqual(snapshot?.currentStation, StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1), file: file, line: line)
        XCTAssertNotNil(snapshot, file: file, line: line)
        XCTAssertNil(snapshot?.journey.active, file: file, line: line)
        XCTAssertEqual(snapshot?.records.items.count, 1, file: file, line: line)
        XCTAssertEqual(snapshot?.records.items.first?.id, "journey-001", file: file, line: line)
        XCTAssertEqual(snapshot?.records.items.first?.minutes, 25, file: file, line: line)
        XCTAssertEqual(snapshot?.records.items.first?.memo, "첫 메모", file: file, line: line)
    }

    // 깨짐 명명: ready 발급 카드의 진입을 거절하거나 draft를 기본값으로 만들면 실패.
    func testAC01_ready발급카드는_저장외형으로_진입하고_정체성과_파일을_유지한다() throws {
        // Given: saved color/photo, both ready routes (main and initial station entry).
        let style = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())])
        for hasStation in [true, false] {
            try withTemporaryFile { url in
                var original = try snapshot(style: style)
                if !hasStation {
                    original = original.updatingStage(cardIssued: true, initialStation: nil, currentStation: nil)
                }
                try LocalSnapshotStore(fileURL: url).save(original)
                let bytes = try Data(contentsOf: url)
                let model = loadedModel(url)
                // When
                let controller = try XCTUnwrap(model.beginCardCustomization())
                // Then
                XCTAssertEqual(controller.draft, style)
                XCTAssertEqual(model.currentCardStyle, style)
                XCTAssertFalse(controller.hasChanges)
                assertIdentity(model.snapshot)
                XCTAssertEqual(model.snapshot, original)
                XCTAssertEqual(try Data(contentsOf: url), bytes)
            }
        }
    }

    // 깨짐 명명: 미발급 진입이 controller를 만들거나 save가 파일을 생성하면 실패.
    func testAC02_미발급은_초안없이_cardEntry를_유지하고_저장을_거부한다() throws {
        try withTemporaryFile { url in
            // Given: missing file becomes ready/unissued on load.
            let model = loadedModel(url)
            XCTAssertEqual(model.launchState, .ready(.cardEntry))
            // When / Then
            XCTAssertNil(model.beginCardCustomization())
            XCTAssertFalse(model.saveCardStyle(.standard, forCardID: Self.cardID))
            XCTAssertEqual(model.saveFailure, .notReady)
            XCTAssertEqual(model.presentedRoute, .cardEntry)
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(model.snapshot, .empty)
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // 깨짐 명명: load 전 저장이 준비상태 가드 없이 실행되면 실패.
    func test로드전은_진입과_저장을_거부하고_notReady를_반환한다() throws {
        try withTemporaryFile { url in
            // Given: store has a valid card but model is not loaded.
            try seed(url)
            let bytes = try Data(contentsOf: url)
            let model = AppModel(store: LocalSnapshotStore(fileURL: url))
            // When / Then
            XCTAssertNil(model.beginCardCustomization())
            XCTAssertFalse(model.saveCardStyle(.standard, forCardID: Self.cardID))
            XCTAssertEqual(model.saveFailure, .notReady)
            XCTAssertNil(model.snapshot)
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: cardIssued만 보고 카드가 없는 상태에서 초안 생성/저장을 허용하면 실패.
    func test발급플래그만_있고_카드가_없으면_notReady로_거부한다() throws {
        try withTemporaryFile { url in
            // Given: loadIfNeeded avoids start's automatic card supplementation.
            let bytes = Data(#"{"version":1,"state":{"cardIssued":true,"initialStation":null,"currentStation":null}}"#.utf8)
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let model = loadedModel(url)
            XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
            XCTAssertNil(model.snapshot?.currentCard)
            // When / Then
            XCTAssertNil(model.beginCardCustomization())
            XCTAssertFalse(model.saveCardStyle(.standard, forCardID: Self.cardID))
            XCTAssertEqual(model.saveFailure, .notReady)
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 전달 CardID 검사를 제거하면 다른 카드용 외형이 저장되어 실패.
    func testID불일치는_notReady이고_기존카드를_유지한다() throws {
        try withTemporaryFile { url in
            // Given
            try seed(url)
            let bytes = try Data(contentsOf: url)
            let model = loadedModel(url)
            let original = model.snapshot
            // When
            XCTAssertFalse(model.saveCardStyle(CardStyle(background: Self.editedColor, photos: []), forCardID: "FM-99999999"))
            // Then
            XCTAssertEqual(model.saveFailure, .notReady)
            XCTAssertEqual(model.snapshot, original)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 진입 snapshot을 저장에 재사용하면 이후 정류장/메모 변경이 소실되어 실패.
    func testAC30_진입후_바뀐_최신정류장과_기록을_외형저장이_보존한다() throws {
        try withTemporaryFile { url in
            // Given: editor opened before unrelated mutations.
            try seed(url)
            let model = loadedModel(url)
            let controller = try XCTUnwrap(model.beginCardCustomization())
            let latest = try XCTUnwrap(model.snapshot).updatingStage(cardIssued: true,
                initialStation: StationSnapshot(id: "seongsu", name: "성수", direction: 1),
                currentStation: StationSnapshot(id: "seongsu", name: "성수역", direction: -1))
            XCTAssertTrue(model.save(latest)) // Existing public API; no snapshot setter.
            XCTAssertTrue(model.saveRecordMemo("진입 후 메모", forJourneyID: "journey-001"))
            let latestRecords = try XCTUnwrap(model.snapshot).records
            let latestJourney = try XCTUnwrap(model.snapshot).journey
            // When
            controller.setBackground(Self.editedColor)
            XCTAssertTrue(controller.save())
            // Then: handwritten expected state + full section preservation.
            let restored = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            assertIdentity(restored)
            XCTAssertEqual(restored.initialStation, StationSnapshot(id: "seongsu", name: "성수", direction: 1))
            XCTAssertEqual(restored.currentStation, StationSnapshot(id: "seongsu", name: "성수역", direction: -1))
            XCTAssertEqual(restored.records.items.count, 1)
            XCTAssertEqual(restored.records.items.first?.minutes, 25)
            XCTAssertEqual(restored.records.items.first?.memo, "진입 후 메모")
            XCTAssertEqual(restored.records, latestRecords)
            XCTAssertEqual(restored.journey, latestJourney)
            XCTAssertNil(restored.journey.active)
            XCTAssertEqual(model.currentCardStyle, CardStyle(background: Self.editedColor, photos: []))
            // 현재 저장 여정 계약은 active nil만 표현 가능하므로 이 계층은 nil 보존만 검증한다.
        }
    }

    // 깨짐 명명: 카드 외형 저장이 journeyPlan 또는 preparedJourney를 초기화하면 실행 중 준비 선택이 소실되어 실패.
    func testAC30_외형저장은_메모리preparedJourney선택을_그대로유지한다() throws {
        try withTemporaryFile { url in
            // Given: 기존 공개 저장 API로 현재 정류장을 성수 정방향으로 만들고 여정 준비를 완료한다.
            try seed(url)
            let model = loadedModel(url)
            let controller = try XCTUnwrap(model.beginCardCustomization())
            let seongsuForward = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)
            let current = try XCTUnwrap(model.snapshot)
            XCTAssertTrue(model.save(current.updatingStage(
                cardIssued: true,
                initialStation: current.initialStation,
                currentStation: seongsuForward
            )))
            model.open(.time)
            model.journeyPlan.setMinutes(60)
            XCTAssertTrue(model.journeyPlan.choose(
                busID: "2014",
                from: StopPosition(index: 0, direction: 1)
            ))
            XCTAssertTrue(model.proceedToPreparation())
            let expected = JourneySelection(
                origin: StopPosition(index: 0, direction: 1),
                minutes: 60,
                busID: "2014",
                busNumber: "2014",
                destination: "성동구민체육센터",
                stops: 12
            )
            XCTAssertEqual(model.preparedJourney, expected)

            // When
            controller.setBackground(Self.editedColor)
            XCTAssertTrue(controller.save())

            // Then: 같은 실행의 메모리 선택만 보존하며 재실행 영속성을 주장하지 않는다.
            XCTAssertEqual(model.preparedJourney, expected)
            XCTAssertEqual(model.snapshot?.currentStation, seongsuForward)
            XCTAssertEqual(model.currentCardStyle, CardStyle(background: Self.editedColor, photos: []))
        }
    }

    // 깨짐 명명: 저장 때 최신 CardID를 확인하지 않으면 새 카드 외형을 덮어써 실패.
    func test진입후_현재카드가_바뀌면_이전세션_저장을_거부한다() throws {
        try withTemporaryFile { url in
            // Given: public save replaces the current card after entry.
            try seed(url)
            let model = loadedModel(url)
            let controller = try XCTUnwrap(model.beginCardCustomization())
            XCTAssertTrue(model.save(try snapshot(id: "FM-87654321")))
            let bytes = try Data(contentsOf: url)
            // When
            controller.setBackground(Self.editedColor)
            XCTAssertFalse(controller.save())
            // Then
            XCTAssertEqual(model.saveFailure, .notReady)
            XCTAssertEqual(controller.notice, .saveFailed(.notReady))
            XCTAssertFalse(controller.didSave)
            XCTAssertEqual(model.snapshot?.currentCard?.id, "FM-87654321")
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 저장 성공 전 currentCardStyle이 draft를 공급하면 실패.
    func testAC30_공통외형은_초안수정과_버리기에_저장값을_공급한다() throws {
        try withTemporaryFile { url in
            // Given
            try seed(url)
            let bytes = try Data(contentsOf: url)
            let model = loadedModel(url)
            let controller = try XCTUnwrap(model.beginCardCustomization())
            // When
            controller.setBackground(Self.editedColor)
            // Then
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(controller.requestExit(), .confirmDiscard)
            controller.discard()
            XCTAssertEqual(try XCTUnwrap(model.beginCardCustomization()).draft, .standard)
            assertOriginalUsage(model.snapshot)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 외형만/일부 사진만 저장하거나 순서/배치를 잃으면 새 AppModel 검증이 실패.
    func testAC24_실제파일_저장후_새모델은_여섯사진과_색_배치_순서를_복원한다() throws {
        try withTemporaryFile { url in
            // Given: independent ImageIO PNG, no production processor for fixtures/expectations.
            try seed(url)
            let png = try CardPhotoTestFixtures.image(alpha: true)
            let photos = (1...6).map { index in
                CardPhotoTestFixtures.photo(data: png,
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index))!,
                    x: 0.25, y: 0.75, fraction: 0.3)
            }
            let model = loadedModel(url)
            // When
            XCTAssertTrue(model.saveCardStyle(CardStyle(background: Self.editedColor, photos: photos), forCardID: Self.cardID))
            // Then: new store + model, without fixture reseeding on relaunch.
            let restarted = loadedModel(url)
            let style = restarted.currentCardStyle
            XCTAssertEqual(style.background, CardColor(red: 0.2, green: 0.3, blue: 0.4))
            XCTAssertEqual(style.photos.count, 6)
            XCTAssertEqual(style.photos.map(\.id.uuidString), [
                "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002",
                "00000000-0000-0000-0000-000000000003", "00000000-0000-0000-0000-000000000004",
                "00000000-0000-0000-0000-000000000005", "00000000-0000-0000-0000-000000000006"])
            XCTAssertEqual(style.photos.map(\.centerX), [0.25, 0.25, 0.25, 0.25, 0.25, 0.25])
            XCTAssertEqual(style.photos.map(\.centerY), [0.75, 0.75, 0.75, 0.75, 0.75, 0.75])
            XCTAssertEqual(style.photos.map(\.widthFraction), [0.3, 0.3, 0.3, 0.3, 0.3, 0.3])
            for photo in style.photos {
                XCTAssertEqual(photo.data, png)
                XCTAssertEqual(photo.pixelWidth, 40)
                XCTAssertEqual(photo.pixelHeight, 20)
                let decoded = try CardPhotoTestFixtures.completeDecoded(photo.data)
                XCTAssertEqual(decoded.width, 40)
                XCTAssertEqual(decoded.height, 20)
                XCTAssertEqual(Double(try CardPhotoTestFixtures.rgba(photo.data)[3]), 128, accuracy: 1)
            }
            assertIdentity(restarted.snapshot)
            assertOriginalUsage(restarted.snapshot)
            XCTAssertEqual(try XCTUnwrap(restarted.beginCardCustomization()).draft, style)
            XCTAssertNil(model.saveFailure)
        }
    }

    // 깨짐 명명: 무효 RGB 후보를 성공 처리하면 오류 분류와 원본 비교에서 실패.
    func test무효후보색은_saveFailure를_반환하고_저장상태를_보존한다() throws {
        try withTemporaryFile { url in
            // Given
            try seed(url)
            let bytes = try Data(contentsOf: url)
            let model = loadedModel(url)
            let before = model.snapshot
            // When
            XCTAssertFalse(model.saveCardStyle(CardStyle(background: CardColor(red: 1.1, green: 0, blue: 0), photos: []), forCardID: Self.cardID))
            // Then
            XCTAssertEqual(model.saveFailure, .invalidState(.invalidCardStyle(.invalidColor)))
            XCTAssertEqual(model.snapshot, before)
            XCTAssertEqual(model.currentCardStyle, .standard)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: actual PNG 후보 검증을 생략하면 손상 사진 저장을 성공 처리하여 실패.
    func test손상사진_후보는_invalidCardPhoto이고_실제원본을_보존한다() throws {
        try withTemporaryFile { url in
            // Given
            let originalStyle = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())])
            try seed(url, style: originalStyle)
            let bytes = try Data(contentsOf: url)
            let model = loadedModel(url)
            let before = model.snapshot
            let invalid = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody())])
            // When
            XCTAssertFalse(model.saveCardStyle(invalid, forCardID: Self.cardID))
            // Then
            XCTAssertEqual(model.saveFailure, .invalidState(.invalidCardPhoto))
            XCTAssertEqual(model.snapshot, before)
            XCTAssertEqual(model.currentCardStyle, originalStyle)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), before)
        }
    }

    // 깨짐 명명: failed launch를 notReady로 축소하거나 원본을 덮어쓰면 실패.
    func test읽기실패_시작은_진입을_막고_writeBlocked로_원본을_보존한다() throws {
        let cases: [(bytes: Data, issue: StorageIssue)] = [
            (Data("{broken".utf8), .corrupt),
            (Data(#"{"version":999,"state":null}"#.utf8), .unsupportedVersion(999))
        ]
        for item in cases {
            try withTemporaryFile { url in
                // Given
                try CardPhotoTestFixtures.seed(item.bytes, at: url)
                let model = loadedModel(url)
                XCTAssertEqual(model.launchState, .failed(item.issue))
                // When / Then
                XCTAssertNil(model.beginCardCustomization())
                XCTAssertFalse(model.saveCardStyle(.standard, forCardID: Self.cardID))
                XCTAssertEqual(model.saveFailure, .writeBlocked(item.issue))
                XCTAssertNil(model.snapshot)
                XCTAssertEqual(try Data(contentsOf: url), item.bytes)
            }
        }
    }

    // 깨짐 명명: 저장 시 원본 재검사를 생략하면 진입 후 손상된 원본을 덮어써 실패.
    func test진입후_원본이_손상되면_저장은_writeBlocked이고_초안을_유지한다() throws {
        try withTemporaryFile { url in
            // Given: real file becomes corrupt after a valid launch/entry.
            try seed(url)
            let model = loadedModel(url)
            let before = model.snapshot
            let controller = try XCTUnwrap(model.beginCardCustomization())
            controller.setBackground(Self.editedColor)
            let corrupt = Data("{broken-after-entry".utf8)
            try corrupt.write(to: url)
            // When
            XCTAssertFalse(controller.save())
            // Then
            XCTAssertEqual(model.saveFailure, .writeBlocked(.corrupt))
            XCTAssertEqual(controller.notice, .saveFailed(.writeBlocked(.corrupt)))
            XCTAssertEqual(controller.draft, CardStyle(background: Self.editedColor, photos: []))
            XCTAssertFalse(controller.didSave)
            XCTAssertTrue(controller.canUndo)
            XCTAssertEqual(model.snapshot, before)
            XCTAssertEqual(try Data(contentsOf: url), corrupt)
        }
    }

    // 깨짐 명명: 쓰기 실패 때 baseline/selection/history를 지우거나 재시도를 막으면 실패.
    func testAC26_실제쓰기실패는_초안과_원본을_유지하고_재시도후에만_복원된다() throws {
        try withTemporaryFile { url in
            // Given: real LocalSnapshotStore; only write boundary throws once.
            let original = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(alpha: true))])
            try seed(url, style: original)
            let bytes = try Data(contentsOf: url)
            var writes = 0
            let store = LocalSnapshotStore(fileURL: url, writeData: { data, target in
                writes += 1
                if writes == 1 { throw ProbeError.write }
                try data.write(to: target, options: .atomic)
            })
            let model = AppModel(store: store)
            model.loadIfNeeded()
            let before = model.snapshot
            let controller = try XCTUnwrap(model.beginCardCustomization())
            controller.selectPhoto(CardPhotoTestFixtures.photoID)
            controller.setBackground(CardColor(red: 0.6, green: 0.5, blue: 0.4))
            let expected = CardStyle(background: CardColor(red: 0.6, green: 0.5, blue: 0.4), photos: original.photos)
            // When: first save fails.
            XCTAssertFalse(controller.save())
            // Then
            XCTAssertEqual(writes, 1)
            XCTAssertEqual(model.saveFailure, .writeFailed)
            XCTAssertEqual(controller.notice, .saveFailed(.writeFailed))
            XCTAssertEqual(controller.draft, expected)
            XCTAssertEqual(controller.selectedPhotoID, UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
            XCTAssertTrue(controller.canUndo)
            XCTAssertTrue(controller.hasChanges)
            XCTAssertFalse(controller.didSave)
            XCTAssertEqual(model.snapshot, before)
            XCTAssertEqual(model.currentCardStyle, original)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), before)
            // When: retry performs an actual atomic write, without reseeding.
            XCTAssertTrue(controller.save())
            // Then
            XCTAssertEqual(writes, 2)
            XCTAssertNil(model.saveFailure)
            XCTAssertNil(controller.notice)
            XCTAssertTrue(controller.didSave)
            XCTAssertFalse(controller.canUndo)
            XCTAssertFalse(controller.hasChanges)
            let restarted = loadedModel(url)
            XCTAssertEqual(restarted.currentCardStyle, expected)
            assertIdentity(restarted.snapshot)
            assertOriginalUsage(restarted.snapshot)
            XCTAssertEqual(try XCTUnwrap(restarted.currentCardStyle.photos.first).data, original.photos[0].data)
        }
    }

    // 깨짐 명명: begin이 v2를 쓰거나 saveCardStyle가 v3 변환/이용상태를 잃으면 실패.
    func testAC29_v2진입은_쓰기없고_외형저장때만_v3로_전환한다() throws {
        try withTemporaryFile { url in
            // Given: hand-authored legacy envelope, independent of encoder.
            try CardPhotoTestFixtures.seed(Self.legacyV2, at: url)
            let model = AppModel(store: LocalSnapshotStore(fileURL: url))
            model.start()
            let controller = try XCTUnwrap(model.beginCardCustomization())
            XCTAssertEqual(controller.draft, .standard)
            XCTAssertEqual(try Data(contentsOf: url), Self.legacyV2)
            // When
            controller.setBackground(Self.editedColor)
            XCTAssertTrue(controller.save())
            // Then: no seed on relaunch.
            let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 3)
            let restarted = loadedModel(url)
            XCTAssertEqual(restarted.currentCardStyle, CardStyle(background: Self.editedColor, photos: []))
            assertIdentity(restarted.snapshot)
            assertOriginalUsage(restarted.snapshot)
        }
    }
}
```

## 2026-10-14 author compile defect 수리

부모의 최초 actual compile은 생산 동작 RED에 도달하기 전에 테스트 helper 문법에서 차단됐다. 유일한 진단은 두 architecture 모두 `CardCustomizationAppModelTests.swift:15:70: covariant 'Self' type cannot be referenced from a default argument expression`이었다.


`snapshot(style:id:)`의 기본 인자 `Self.cardID`만 `CardCustomizationAppModelTests.cardID`로 바꿨다. 값은 같은 고정 문자열 `FM-01234567`이며 helper 본문, 테스트 기대값, API 의미, 16개 케이스는 바뀌지 않았다. 이는 **AUTHOR_COMPILE_DEFECT** 수리이며 actual RED/PASS 증거가 아니다. 생산/scaffold 소스는 읽거나 수정하지 않았고 빌드·테스트는 부모가 다시 실행한다.

## 부모 actual RED
저자defaultarg Self사용컴파일결함1개를기대값변경없이수리후컴파일성공. 실제16test/26failures(1unexpected=XCTAssertEqual내optionalunwrapthrewerror)/exit65. 미구현begin nil/currentStyle standard/savefalse로계약assert/unwrap 실패, 타깃16개전부실행. t4-parent-red-actual.log. hash18파일기록.
