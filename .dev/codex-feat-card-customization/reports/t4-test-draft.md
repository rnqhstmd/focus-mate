# T4 AppModel 통합 테스트 — PENDING DRAFT ONLY

Status: NEEDS_CONTEXT

## 산출물과 실행 상태
- draft: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/drafts/CardCustomizationAppModelTests.swift`
- 15개 테스트 메서드. live `ios/FocusMateTests`로 복사하지 않았다.
- 실패 확인 명령: 실행하지 않음 — 사용자 DRAFT ONLY 지시.
- 실패 메시지 / 실패 사유: 없음. build/test/agent/commit 미실행. RED 확인이나 T4 완료로 승격하지 않는다.
- 프로덕션 파일 내용 읽기·검색·수정 없음. 작성 파일은 지정된 draft/report 두 개뿐이다.
- using-superpowers SKILL.md를 작업 시작에 확인했다. 사용자 지정 RED-writer 역할과 DRAFT ONLY 제한을 우선했다.

## 테스트 집합
| # | 시나리오 | 잡는 변이 |
|---|---|---|
| 1 | AC01 ready/발급/card 존재인 main·initialStationEntry 진입, 저장 외형 복제, 무쓰기 | 기본 초안 초기화 / main으로만 제한 / 카드 재발급 |
| 2 | AC02 미발급 진입·저장 거부, cardEntry 유지 | 발급 가드 누락 / 파일 생성 |
| 3 | load 전 진입·저장 거부, notReady | 준비상태 가드 누락 |
| 4 | loadIfNeeded로 보충 전 issued/currentCard 없음, notReady | cardIssued만 보고 저장 |
| 5 | 전달 ID 불일치, notReady, 실제 파일 보존 | ID 가드 누락 |
| 6 | 진입 후 public save로 정류장 변경, saveRecordMemo로 기록 변경 후 controller save | 진입 snapshot 재사용 / 기록 초기화 |
| 7 | 진입 후 public save로 현재 카드 교체, 이전 controller 저장 거부 | 저장 시 최신 ID 검증 누락 |
| 8 | 미저장 초안·버리기는 currentCardStyle/재진입 저장값 유지 | draft가 공통 외형으로 유출 |
| 9 | AC24 실제 파일 6장 독립 PNG·색·배치·순서·ID·발급시각, 새 store/model 복원 | 사진 일부 누락 / 순서 뒤집기 / 배치 초기화 |
| 10 | 무효 RGB 후보 → invalidState(invalidCardStyle(invalidColor)) | 후보 검증 생략 / 성공 오보고 |
| 11 | 실제 손상 PNG 후보 → invalidState(invalidCardPhoto), 사진 원본 보존 | 실제 이미지 검증 생략 |
| 12 | corrupt/unsupported launch → writeBlocked(원인), 원본 보존 | failed를 notReady로 잘못 분류 |
| 13 | 정상 진입 뒤 실제 원본 손상 → writeBlocked(corrupt), 초안 유지 | 원본 재읽기 누락 / 덮어쓰기 |
| 14 | AC26 LocalSnapshotStore writeData 경계 1회 throw, 초안/선택/undo/실파일 보존, 실제 atomic 재시도·재실행 | 실패를 성공 처리 / 실패 때 baseline 갱신 / 재시도 차단 |
| 15 | AC29 AppModel start/begin은 v2 원본 유지, controller save에서만 v3, 재실행 이용상태 유지 | 진입 시 자동 마이그레이션 쓰기 / save 시 버전 누락 |

## NEEDS_CONTEXT / 계약 제한
1. **설계서 인터페이스 불충분: 비어 있지 않은 여정 생성·변경 계약.** 허용된 설계와 기존 테스트에서 유효한 active journey 생성자/JSON/공개 변경 API가 없다. #6은 실제로 진입 후 정류장과 기록을 변경하고 최신 `journey.active == nil`을 보존한다. **진입 후 비어 있지 않은 여정 변경 보존은 아직 검증하지 않는다.** active 객체·setter를 추측하거나 이 한계를 전체 journey 보존 증거로 취급하지 않는다. 유효한 생성 계약과 public mutation 또는 existing AppModel.save용 snapshot fixture를 받아 보강해야 한다.
2. 선언 미완성은 사용자 제공 상태다. 프로덕션을 확인하지 않았다. T2/T3/T4 선언 준비 후 정상 RED 단계에서 컴파일 진단과 행동 실패를 구분해야 한다. 현재 파일은 컴파일/실패/통과 어느 것도 확인하지 않았다.
3. loading 상태는 생성 직후(load 전) 공개 경계로 다룬다. 동기 load 중 reentrancy 상태를 만들 setter/seam을 발명하지 않았다.
4. 실제 쓰기 실패는 real LocalSnapshotStore + 지원된 writeData closure 주입이다. 파일시스템 용량/권한 장애 자체를 재현한 시험은 아니다. 읽기·후보 검증·원본 보호·재시도 저장은 실제 파일 경로다.
5. #9는 AppModel.saveCardStyle → 실제 저장 → 새 모델 복원 경계다. controller 저장 성공/실패 경계는 #6/#14/#15에서 연결한다. T3 전체 controller 시험을 중복하지 않는다.

## 중복 회피와 증거 경계
- v1 읽기 무쓰기/변환은 CardStyleStorageTests·StorageV2Tests, v1 카드 자동 보충/재발급 방지는 CardSupplementTests에 이미 있으므로 별도 반복하지 않았다. #4의 v1은 missing-card 가드를 만들기 위한 loadIfNeeded fixture다.
- v2 #15는 기존 store 단위 migration과 달리 AppModel start/begin/save 연결을 검증한다.
- 보관함 독립 AC25 단독 store 시험은 CardStyleStorageTests에 있으므로 반복하지 않았다. #9 입력은 로컬 PNG Data이며 재실행에 source/processor/seed를 재사용하지 않는다. 실제 PhotosPicker·보관함 삭제 UI 증거는 아니다.
- Independent fixture: CardPhotoTestFixtures.image의 CoreGraphics/ImageIO PNG; 기대 색/치수/ID/배치/alpha는 리터럴. 프로덕션 processor로 기대값을 만들지 않았다. 전체 snapshot equality는 실패 보존용이며, 성공 주요 필드는 리터럴로 따로 assert한다.
- actual 이미지 validator를 no-op 처리하지 않았다. 임시 실제 파일은 기존 withTemporaryFile을 사용한다.
- 모든 테스트에 G/W/T와 깨짐 명명을 넣었다. 변이 점검은 설계상의 정적 점검이며 실행한 mutation test가 아니다.
- 후속 단계: 계약 보완 → T2/T3 준비 확인 → 독점 T4 단계에서 live target 편입 및 정상 RED 실행. 지금은 자동 복사·실행·GREEN 인계 없음.

## 참조 파일
Read/sed로 내용을 확인한 입력:
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/prd.md`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/design.md`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardStyleStorageTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardIssuanceModelTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardTestSupport.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardPhotoTestFixtures.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/AppFoundationTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/RecordStorageTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/JourneyStartModelTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardSupplementTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StorageTestSupport.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/AppSnapshotSectionsTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StorageV2Tests.swift`

작업 절차 확인용 (프로덕션 아님):
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md`

파일명 inventory: `.dev/codex-feat-card-customization` 및 `ios/FocusMateTests`의 rg --files. 다른 .dev 파일 내용은 읽지 않았다. T3 45개 draft 관련 정보는 사용자 입력만 사용했으며 T3 draft 파일은 읽지 않았다.

Grep 참조: `JourneySnapshot|JourneySection\(|active:|"active":\{` 계약 검색을 다음 기존 테스트 파일 집합에만 실행했다 (검색 대상 전체 목록):
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/AppFoundationTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/AppRecoveryTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/AppSnapshotSectionsTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardIssuanceControllerTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardIssuanceModelTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardIssuanceTestDoubles.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardPhotoIntegrityTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardPhotoMemoryTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardPhotoProcessorTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardPhotoTestFixtures.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardStorageTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardStyleStorageTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardStyleTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardSupplementTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/CardTestSupport.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/HarnessTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/IssuanceHapticPatternTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/JourneyPlanDraftTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/JourneyPlannerTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/JourneyStartModelTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/PassFaceAssetTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/PassIdentityTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/RecordSectionTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/RecordStorageTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/RecoveryBootstrapTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/RecoveryHistoryTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/SnapshotCodecTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StationCatalogTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StationSearchStateTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StorageRecoveryTests.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StorageTestSupport.swift`
- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateTests/StorageV2Tests.swift`

자체 작성 draft를 report에 전문 포함하기 위해 다시 읽었다. production search 없음.

## 테스트 코드 전문
```swift
import Foundation
import XCTest
@testable import FocusMate

// PENDING DRAFT ONLY. Not in the live test target; no RED/build/test evidence.
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
            // NEEDS_CONTEXT: no valid nonempty JourneySection contract exists in allowed inputs.
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

## 2026-10-14 저장 여정 제한 해소와 메모리 여정 회귀 보강

`t4-journey-contract.md`로 기존 NEEDS_CONTEXT를 해소했다. 현재 `JourneySnapshot`은 case가 없는 enum이어서 유효한 저장 여정은 `JourneySection(active: nil)`뿐이다. 기존 #6은 편집 진입 뒤 공개 `AppModel.save`로 정류장을 변경하고 `saveRecordMemo`로 기록을 변경한 다음 controller 저장·실파일 재로드에서 최신 records와 `journey.active == nil`을 보존하므로 현재 계층의 저장 여정 계약에 유효하다. draft 안의 stale NEEDS_CONTEXT 주석은 “현재 저장 여정 계약은 active nil만 표현 가능하여 nil 보존만 검증한다”로 바꿨다. nonempty 저장 여정 타입·setter·mock seam은 추가하지 않았다.

16번째 `testAC30_외형저장은_메모리preparedJourney선택을_그대로유지한다`를 추가했다. 기존 `JourneyStartModelTests`의 공개 API와 생성자 리터럴을 그대로 사용한다: `StationSnapshot(id: "seongsu", name: "성수역", direction: 1)`을 `AppSnapshot.updatingStage`와 `model.save`로 적용하고, `open(.time)`, `journeyPlan.setMinutes(60)`, `choose(busID: "2014", from: StopPosition(index: 0, direction: 1)) == true`, `proceedToPreparation() == true`를 거친다. 카드 외형 저장 전후 기대값은 다음 독립 리터럴과 같다.

```swift
JourneySelection(
    origin: StopPosition(index: 0, direction: 1),
    minutes: 60,
    busID: "2014",
    busNumber: "2014",
    destination: "성동구민체육센터",
    stops: 12
)
```

외형 저장 후 `preparedJourney`, currentStation, currentCardStyle을 확인한다. 이 테스트는 같은 실행의 메모리 상태 보존만 다루며 `preparedJourney`의 재실행 영속성을 주장하지 않는다. 기존 15개 기대는 변경하거나 약화하지 않았다.

현재 상태는 **16 authored / 0 compiled / 0 executed / promotion pending T3 gate**다. actual `ios/FocusMateTests`에는 복사하지 않았고 production/T3 source를 읽거나 수정하지 않았다. build/test/agent/commit도 실행하지 않았다. 새 API alias나 setter를 추측하지 않았으며 추가 NEEDS_CONTEXT는 없다.
