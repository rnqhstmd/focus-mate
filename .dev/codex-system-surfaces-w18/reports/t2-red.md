# W18 T2 RED — 앱 투영·게시·안전 진입

Status: DONE_WITH_CONCERNS — 테스트 작성 완료, 실제 실행 증거 없음.

## 작성·실행 상태
신규 WidgetPublicationTests.swift16함수 + WidgetNavigationTests.swift16함수 = **32개**. 테스트전용 closure probe 및 실제 AppModel/Projection/Publisher/Policy를 사용한다. 생산 타입 정의·생산 파일 읽기/쓰기·기존 잠긴 테스트 수정 없음. 테스트·빌드·시뮬레이터·브라우저 실행 안 함.
부모가 선언 bootstrap과 AppModel optional widgetPublisher/init·메서드stub을 추가했다고 통지했으며 부모가 API 컴파일 점검과 focused 실행을 담당한다. 컴파일 오류를 RED 증거로 삼지 않는다. 실제 컴파일·실패 메시지는 아직 미확보다.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/WidgetPublicationTests.swift ios/FocusMateTests/WidgetNavigationTests.swift
```
부모 러너 인자해석에 맞춰 파일별 focused 실행 가능. 한 빌드만 실행, 전체검증은 W18 이후.

## intended RED와 회귀 구분
Projection notImplemented throw, publisher false, Navigation safeHome/inert stub 기준 **예상 RED28 / 통과 예상 호환4**. T2 stub의 정확한 기본반환은 parent compile/run에서 확인하므로 실제 실패 수는 미확정.
- Publication16 중15건은 정상 투영/게시/후속 성공의 긍정 기대를 포함하여 throw 또는 누락 부작용 assertion RED 의도.
- Publication 정리실패1건은 이전bytes·0게시 유지 호환. 이 단독 음성 검사를 RED로 세지 않는다.
- Navigation16 중13건은 defer/alreadyOpen/setup/phase/confirm/analytics/pending/AppModel 적용 기대가 있어 assertion RED 의도.
- 순수 mismatched/nil ID, UTF16 canonical mismatch, invalid/expired safeHome3건은 현재 safeHome stub에서도 통과 가능한 방어 회귀. RED 수에 세지 않는다.
- AppModel pending TTL 테스트는 최초 defer와 이후 명시consume 및 두번째nil을 함께 관찰한다. bootstrap에서 초기 defer 누락만으로도 실패할 수 있으므로, GREEN 때 실제 만료/일회소비 assertions까지 모두 통과해야 한다.

## 승인·확인한 모호성
1. v2가 v1보다 우선: running/paused는 showActiveJourney이고 resumeJourney 자동호출 금지. 순수정책과 AppModel에서 저장0/resume token0/path유지를 검사한다.
2. AppModel URL 현재시각·시간대는 기존 **RecordClock.now()/timeZone()** DI를 사용한다고 부모가 명시 승인. 새 initializer 인자를 추측하지 않았다.
3. load/start는 pending rawURL을 자동 소비하지 않고 Root UI가 ready 후 **explicit consumePendingWidgetURL**을 호출하는 계약을 부모가 명시 확인. 테스트는 handle(pre-ready)→clock 24h 경계→load→consume safeHome→consume nil 순서다.
4. publisher 중복 publish의 Bool 의미는 별도 확정되지 않아 두번째 반환값은 assert하지 않고 실제 write/reload 없음만 검사한다.

## AC 매핑·시나리오
### Publication16 — AC1/2/3/6
- W09b60분/3회,7일[30,0,30,0,0,0,0],today0/태그60 투영.
- awaiting/running/paused/arrived 저장경과0/678/678/1800·총1800 보존.
- setup와ready 구분.
- 원본cardID/recordID/task/memo 원문 공유제외.
- 게시성공 share→reload,동일payload+1초 중복없음.
- 동일payload라도 generatedAt+1800 만료 재게시.
- share실패 이전bytes/reload횟수유지.
- 성공복원 paused678 게시.
- 원본resume 저장실패 후보미게시,재시도성공 local→share→reload.
- share실패여도 원본resume 저장은 done이며 paused해제 원본 유지.
- 읽기실패0게시/이전값보존, retryLoad 성공후게시.
- migration v4 저장실패→foreground 미게시, 후속 confirmInitialStation persist성공후게시복구.
- foreground자정 공유basis10-17 갱신/원본추가저장0.
- 실제임시원본 corrupt backup+clear성공→empty setup/0공유.
- backup실패→이전공유본유지/0게시(호환).
- 기존발급상태 cards누락 supplementCard 직접save성공→공유성공경계.

### Navigation16 — AC5/6
- !ready가 invalid보다우선 defer.
- 다른열린흐름이 invalid/설정보다우선 alreadyOpen.
- needsSetup showSetup.
- ready prepare,awaiting showDeparture,running/paused showActiveJourney,arrived alight.
- old/nil ID로new활동진입차단(호환).
- composed/decomposed ID UTF16불일치 safeHome(호환).
- 동일여정이미열림 alreadyOpen.
- newJourney는 confirmNewJourney만.
- 미래/누락분석일 today기본,week/month 맥락보존.
- invalid/expired safeHome(호환).
- 실제AppModel paused링크 원본/path/write/resume-token 불변.
- 실제AppModel new확인결정 기존원본/write/path 불변.
- rawURL pending consume시86400초TTL재검증/일회소비.
- pending oldID를복원최신newID와재검증.
- blocked 현재records흐름 path/write불변.
- 최신report에없는분석태그해제/week종류보존/entry한번소비/쓰기0.

## 픽스처와 품질
시각기본2026-10-16T12:00:00Z/UTC, 필요시정확한자정/24h시각을수동주입한다. 저장경과는시계외삽하지않는다. expectations는literal/독립픽스처이며 생산함수로expected를산출하지않는다. 각 테스트 앞 깨짐명명.
IO는 LocalSnapshotStore 및 WidgetSnapshotStore의 기존 closure DI만대체한다. 실제 Projection/Publisher/Model/Policy결과와 원본/공유bytes·reload·write이벤트를 관찰한다. 복구정리2건만 실제temp파일을 테스트실행시 생성하고 teardown삭제한다. agent가실행한것은아니다.

## 참조한 파일 전체
- .dev/codex-system-surfaces-w18/prd.md
- .dev/codex-system-surfaces-w18/design.md (v2우선)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (동일agent역할재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (동일agent규칙재사용)
- ios/FocusMateTests/JourneyLifecycleModelTests.swift
- ios/FocusMateTests/JourneyLifecycleTestDoubles.swift
- ios/FocusMateTests/AppRecoveryTests.swift
- ios/FocusMateTests/RouteDataMigrationTests.swift
- ios/FocusMateTests/BoardingTestDoubles.swift
- ios/FocusMateTests/RouteDataLifecycleModelTests.swift (관련부분)
- ios/FocusMateTests/W16bTestSupport.swift
- ios/FocusMateTests/JourneyStartModelTests.swift
- ios/FocusMateTests/CardIssuanceModelTests.swift
- ios/FocusMateTests/CardIssuanceControllerTests.swift (관련부분)
- ios/FocusMateTests/CardTestSupport.swift
- ios/FocusMateTests/AlightingModelTests.swift (RecordClock DI관련부분)
- ios/FocusMateTests/RecordsCalendarTests.swift (앞선동일agent작업에서읽은record fixture 재사용)
- ios/FocusMateTests/WidgetFixtures.swift (동일agent T1고정시간/UTC 재사용)
- ios/FocusMateTests/WidgetPublicationTests.swift (신규)
- ios/FocusMateTests/WidgetNavigationTests.swift (신규)
기존 tests 파일명/관련선언 rg 검색만 수행, production탐색 없음.

## 외부 검증 범위
4조합UI/Root confirmation실제취소/갤러리/AppGroup서명/실기기실행·VO는별도다. T2단위검사가OS즉시반영·실제앱진입완료를증명하지않는다.

## 테스트 전문

### ios/FocusMateTests/WidgetPublicationTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 실제 저장소 경계의 closure만 대체한다. AppModel/Projection/Publisher는 실제 대상을 사용한다.
@MainActor
final class WidgetAppProbe {
    var now = WidgetFixtures.generated
    var disk: Data?
    var shared: Data?
    var writes = 0
    var shareAttempts = 0
    var sharedWrites = 0
    var reloads = 0
    var localFails = false
    var shareFails = false
    var readFails = false
    var events: [String] = []
}

@MainActor
enum WidgetAppTestFixtures {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = WidgetFixtures.utc
        return value
    }
    static func source(active: JourneySnapshot? = nil) -> AppSnapshot {
        BoardingFixtures.snapshot(active: active)
    }
    static func make(
        snapshot: AppSnapshot, probe: WidgetAppProbe, legacy: Data? = nil,
        overrideStore: LocalSnapshotStore? = nil
    ) throws -> (AppModel, WidgetSnapshotPublisher) {
        probe.disk = try legacy ?? SnapshotCodec.encode(snapshot)
        let sharedStore = WidgetSnapshotStore(
            containerURL: { URL(fileURLWithPath: "/unused/widget-group", isDirectory: true) },
            readData: { _ in
                guard let bytes = probe.shared else { throw WidgetDataIssue.readFailed }
                return bytes
            },
            atomicWrite: { bytes, _ in
                probe.shareAttempts += 1
                if probe.shareFails { throw WidgetDataIssue.writeFailed }
                probe.shared = bytes
                probe.sharedWrites += 1
                probe.events.append("share")
            }
        )
        let publisher = WidgetSnapshotPublisher(
            store: sharedStore, now: { probe.now }, calendar: calendar,
            timeZone: { WidgetFixtures.utc }, reload: { probe.reloads += 1; probe.events.append("reload") }
        )
        let localStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                if probe.readFails { throw CocoaError(.fileReadNoPermission) }
                guard let bytes = probe.disk else { throw CocoaError(.fileReadNoSuchFile) }
                return bytes
            },
            createDirectory: { _ in },
            writeData: { bytes, _ in
                probe.writes += 1
                if probe.localFails { throw WidgetDataIssue.writeFailed }
                probe.disk = bytes
                probe.events.append("local")
            }
        )
        let model = AppModel(
            store: overrideStore ?? localStore,
            recordClock: RecordClock(now: { probe.now }, timeZone: { WidgetFixtures.utc }),
            routeData: BoardingFixtures.readyRouteData(), widgetPublisher: publisher
        )
        return (model, publisher)
    }
    static func initialOption() throws -> StopSearchOption {
        guard case let .results(options, _) = StationSearch.search("성수역", in: BoardingFixtures.uiCatalog()) else {
            throw WidgetDataIssue.invalidSnapshot
        }
        return try XCTUnwrap(options.first { $0.id == "seongsu" })
    }
}

@MainActor
final class WidgetPublicationTests: XCTestCase {
    private typealias F = WidgetAppTestFixtures

    // 깨짐: 공용주결과대신 위젯전용집계를 사용하여 날짜·태그합이 달라진다.
    func testW18_원본투영은_60분3회와_주7일을_보존한다() throws {
        let records = [
            RecordsCalendarTests.record(id: "a", date: "2026-10-12", minutes: 10),
            RecordsCalendarTests.record(id: "b", date: "2026-10-12", minutes: 20),
            RecordsCalendarTests.record(id: "c", date: "2026-10-14", minutes: 30)
        ]
        let source = F.source().updating(records: RecordSection(items: records))
        let result = try WidgetSnapshotProjection.make(snapshot: source, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        XCTAssertEqual(result.analytics.days.map(\.minutes), [30, 0, 30, 0, 0, 0, 0])
        XCTAssertEqual(result.analytics.weekMinutes, 60)
        XCTAssertEqual(result.analytics.weekCount, 3)
        XCTAssertEqual(result.analytics.today.minutes, 0)
        XCTAssertEqual(result.analytics.tags.map(\.minutes), [60])
    }

    // 깨짐: 진행/정지/도착을모두같게투영하거나 복원할때경과값을시계로외삽한다.
    func testW18_여정상태와_저장경과를_그대로_투영한다() throws {
        let examples: [(JourneySnapshot, WidgetJourneyPhase, Int)] = [
            (BoardingFixtures.journey(minutes: 30, phase: .awaitingDeparture), .awaitingDeparture, 0),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: false), .running, 678),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: true), .paused, 678),
            (BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 1800, paused: true), .arrived, 1800)
        ]
        for (journey, expectedPhase, expectedElapsed) in examples {
            let result = try WidgetSnapshotProjection.make(snapshot: F.source(active: journey), now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
            XCTAssertEqual(result.journey.phase, expectedPhase)
            XCTAssertEqual(result.journey.elapsedSeconds, expectedElapsed)
            XCTAssertEqual(result.journey.totalSeconds, 1800)
        }
    }

    // 깨짐: 설정전과완료후여정없음을구별하지않는다.
    func testW18_설정전과_새준비를_서로다르게_투영한다() throws {
        let setup = try WidgetSnapshotProjection.make(snapshot: .empty, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        let ready = try WidgetSnapshotProjection.make(snapshot: F.source(), now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        XCTAssertEqual(setup.journey.phase, .setup)
        XCTAssertEqual(ready.journey.phase, .ready)
    }

    // 깨짐: 원본카드ID/완료기록ID/할일/메모를 공유DTO로투영한다.
    func testW18_원본투영은_금지원문을_공유JSON에_넣지않는다() throws {
        let source = F.source().updating(records: RecordSection(items: [RecordsCalendarTests.record(id: "private-record", date: "2026-10-14", minutes: 30, memo: "private-memo")]))
        let result = try WidgetSnapshotProjection.make(snapshot: source, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
        let text = String(decoding: try JSONEncoder().encode(result), as: UTF8.self)
        XCTAssertFalse(text.contains("private-record"))
        XCTAssertFalse(text.contains("private-memo"))
        XCTAssertFalse(text.contains("FM-01234567"))
        XCTAssertFalse(text.contains("책 한 챕터 읽기"))
    }

    // 깨짐: 정상게시후reload를생략하거나 동일payload를반복쓰기한다.
    func testW18_성공게시만_reload하고_동일payload는_중복게시하지않는다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.events, ["share", "reload"])
        probe.now = WidgetFixtures.date("2026-10-16T12:00:01Z")
        _ = publisher.publish(snapshot: F.source())
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 동일값이라는이유로30분지난공유본을갱신하지않는다.
    func testW18_동일payload라도_30분만료면_재게시한다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        probe.now = WidgetFixtures.date("2026-10-16T12:30:00Z")
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.sharedWrites, 2)
        XCTAssertEqual(probe.reloads, 2)
    }

    // 깨짐: 공유쓰기실패때이전bytes를잃거나실패후reload한다.
    func testW18_공유실패는_이전공유본과_reload횟수를_보존한다() throws {
        let probe = WidgetAppProbe()
        let (_, publisher) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertTrue(publisher.publish(snapshot: F.source()))
        let before = probe.shared
        probe.shareFails = true
        probe.now = WidgetFixtures.date("2026-10-17T00:00:00Z")
        XCTAssertFalse(publisher.publish(snapshot: F.source()))
        XCTAssertEqual(probe.shared, before)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 성공복원된paused원본을공유하지않거나경과를재시작한다.
    func testW18_성공복원은_정지저장진행을_게시한다() throws {
        let probe = WidgetAppProbe()
        let source = F.source(active: BoardingFixtures.journey(minutes: 30, phase: .departed, elapsedSeconds: 678, paused: true))
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.loadIfNeeded()
        XCTAssertEqual(probe.sharedWrites, 1)
        let decoded = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared))
        guard case .valid(let result) = decoded else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(result.journey.phase, .paused)
        XCTAssertEqual(result.journey.elapsedSeconds, 678)
    }

    // 깨짐: 원본저장실패후후보를게시하거나성공재시도게시를누락한다.
    func testW18_저장실패후보는_미게시하고_성공재시도뒤만_게시한다() throws {
        let probe = WidgetAppProbe()
        let source = F.source(active: BoardingFixtures.journey(phase: .departed, elapsedSeconds: 600, paused: true))
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.loadIfNeeded()
        let before = probe.shared
        let sharedBefore = probe.sharedWrites
        probe.localFails = true
        XCTAssertEqual(model.resumeJourney(), .saveFailed)
        XCTAssertEqual(probe.sharedWrites, sharedBefore)
        XCTAssertEqual(probe.shared, before)
        probe.localFails = false
        XCTAssertEqual(model.resumeJourney(), .done)
        XCTAssertEqual(probe.sharedWrites, sharedBefore + 1)
        XCTAssertEqual(Array(probe.events.suffix(3)), ["local", "share", "reload"])
    }

    // 깨짐: 공유실패를앱원본저장실패로전파한다.
    func testW18_공유실패여도_앱저장은_성공한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(active: BoardingFixtures.journey(phase: .departed, paused: true)), probe: probe)
        model.loadIfNeeded()
        let sharedBefore = probe.shared
        let reloadBefore = probe.reloads
        probe.shareFails = true
        XCTAssertEqual(model.resumeJourney(), .done)
        XCTAssertFalse(try XCTUnwrap(model.snapshot?.journey.active).paused)
        XCTAssertEqual(probe.shared, sharedBefore)
        XCTAssertEqual(probe.reloads, reloadBefore)
    }

    // 깨짐: 읽기실패를0으로게시하거나 retry복원성공후게시하지않는다.
    func testW18_원본읽기실패는_0공유본을_게시하지않는다() throws {
        let probe = WidgetAppProbe()
        probe.shared = Data("previous-share".utf8)
        probe.readFails = true
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        model.loadIfNeeded()
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shared, Data("previous-share".utf8))
        XCTAssertEqual(probe.shareAttempts, 0)
        XCTAssertEqual(probe.reloads, 0)
        probe.readFails = false
        model.retryLoad()
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: migration저장실패후foreground가미확정이전결과를게시한다.
    func testW18_마이그레이션실패는_foreground도_미게시하고_후속저장성공으로_복구한다() throws {
        let probe = WidgetAppProbe()
        probe.localFails = true
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, legacy: W16bFixtures.legacyData(version: 4))
        model.start()
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shareAttempts, 0)
        probe.localFails = false
        XCTAssertTrue(model.confirmInitialStation(try F.initialOption()))
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
    }

    // 깨짐: 자정foreground때원본을다시저장하거나공유기준일을갱신하지않는다.
    func testW18_foreground자정갱신은_원본추가저장없이_새기준을_게시한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        model.loadIfNeeded()
        let originalWrites = probe.writes
        probe.now = WidgetFixtures.date("2026-10-17T00:00:00Z")
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.writes, originalWrites)
        XCTAssertEqual(probe.sharedWrites, 2)
        guard case .valid(let value) = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared)) else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(value.basisDay, "2026-10-17")
    }
    private func cleanupStore(failBackup: Bool) throws -> LocalSnapshotStore {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("w18-cleanup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("app-state.json")
        try Data("{broken".utf8).write(to: file)
        return LocalSnapshotStore(fileURL: file, writeBackup: { bytes, url in
            if failBackup { throw WidgetDataIssue.writeFailed }
            try bytes.write(to: url, options: .atomic)
        })
    }

    // 깨짐: 원본정리성공후에도이전공유값을유지하거나정상빈설정상태를게시하지않는다.
    func testW18_복구정리성공은_확정empty원본을_게시한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, overrideStore: cleanupStore(failBackup: false))
        model.loadIfNeeded()
        model.requestCleanup()
        XCTAssertTrue(model.confirmCleanup())
        XCTAssertEqual(probe.sharedWrites, 1)
        guard case .valid(let result) = WidgetSnapshotCodec.decode(try XCTUnwrap(probe.shared)) else { return XCTFail("정상 공유본 필요") }
        XCTAssertEqual(result.journey.phase, .setup)
        XCTAssertEqual(result.analytics.weekMinutes, 0)
        XCTAssertEqual(result.analytics.weekCount, 0)
    }

    // 호환회귀. 깨짐: 실패한정리후보empty를게시하여이전공유본을덮는다.
    func testW18_복구정리실패는_이전공유본을_보존한다() throws {
        let probe = WidgetAppProbe()
        probe.shared = Data("previous-share".utf8)
        let (model, _) = try F.make(snapshot: F.source(), probe: probe, overrideStore: cleanupStore(failBackup: true))
        model.loadIfNeeded()
        model.requestCleanup()
        XCTAssertFalse(model.confirmCleanup())
        model.refreshWidgetSnapshotIfEligible()
        XCTAssertEqual(probe.shared, Data("previous-share".utf8))
        XCTAssertEqual(probe.shareAttempts, 0)
        XCTAssertEqual(probe.reloads, 0)
    }

    // 깨짐: supplementCard의직접save성공을공유성공경계에서빠뜨린다.
    func testW18_기존발급상태의_카드보충성공도_저장뒤_게시한다() throws {
        let probe = WidgetAppProbe()
        let station = StationSnapshot(id: "seongsu", name: "성수역")
        let source = XCTestCase.stage(true, station, station)
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.start()
        XCTAssertEqual(model.snapshot?.cards.items.count, 1)
        XCTAssertEqual(probe.writes, 1)
        XCTAssertEqual(probe.sharedWrites, 1)
        XCTAssertEqual(probe.reloads, 1)
        XCTAssertEqual(Array(probe.events.suffix(3)), ["local", "share", "reload"])
    }

}

```

### ios/FocusMateTests/WidgetNavigationTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class WidgetNavigationTests: XCTestCase {
    private typealias F = WidgetAppTestFixtures
    private func state(
        ready: Bool = true, setup: Bool = false, id: String? = "journey-1",
        phase: WidgetJourneyPhase = .paused, open: Bool = false, blocked: Bool = false
    ) -> WidgetNavigationState {
        WidgetNavigationState(isReady: ready, needsSetup: setup, activeJourneyID: id, phase: phase, isJourneyOpen: open, hasOtherOpenFlow: blocked)
    }
    private func link(_ target: WidgetLinkTarget = .journey(expectedID: "journey-1")) -> WidgetLinkParseResult {
        .valid(WidgetLink(issuedAt: WidgetFixtures.generated, target: target))
    }
    private func decide(_ link: WidgetLinkParseResult, _ state: WidgetNavigationState) -> WidgetNavigationDecision {
        WidgetNavigationPolicy.decide(link: link, state: state, now: WidgetFixtures.generated, calendar: F.calendar, timeZone: WidgetFixtures.utc)
    }
    private func url(_ target: WidgetLinkTarget, issued: Date = WidgetFixtures.generated) throws -> URL {
        try XCTUnwrap(WidgetLinkCodec.makeURL(WidgetLink(issuedAt: issued, target: target)))
    }

    // 깨짐: ready이전에링크를버리거나현재빈상태로결정한다.
    func testW18_ready이전에는_invalid링크도_판정보류한다() {
        XCTAssertEqual(decide(.invalid, state(ready: false)), .deferUntilReady)
    }

    // 깨짐: 다른열린편집흐름을invalid/설정링크로강제로닫는다.
    func testW18_열린다른흐름은_링크판정보다_우선보존한다() {
        XCTAssertEqual(decide(.invalid, state(setup: true, blocked: true)), .alreadyOpen)
    }

    // 깨짐: 설정전인데여정진입이나준비를바로실행한다.
    func testW18_설정필요하면_기존설정을_안내한다() {
        XCTAssertEqual(decide(link(.journey(expectedID: nil)), state(setup: true, id: nil, phase: .setup)), .showSetup)
    }

    // 깨짐: 진행/정지링크를자동resume으로해석하거나대기/도착경로를혼동한다.
    func testW18_상태별진입은_준비_출발안내_확인_하차로_구분한다() {
        let examples: [(WidgetJourneyPhase, String?, WidgetNavigationDecision)] = [
            (.ready, nil, .prepare), (.awaitingDeparture, "journey-1", .showDeparture),
            (.running, "journey-1", .showActiveJourney), (.paused, "journey-1", .showActiveJourney),
            (.arrived, "journey-1", .alight)
        ]
        for (phase, id, expected) in examples {
            XCTAssertEqual(decide(link(.journey(expectedID: id)), state(id: id, phase: phase)), expected)
        }
    }

    // 깨짐: 이전여정ID나nil링크를새활동여정에매칭하여덮어쓴다.
    func testW18_이전ID와_nil은_새활동여정에_진입하지않는다() {
        XCTAssertEqual(decide(link(.journey(expectedID: "old")), state(id: "new")), .safeHome)
        XCTAssertEqual(decide(link(.journey(expectedID: nil)), state(id: "new")), .safeHome)
    }

    // 깨짐: canonical동등하지만원문이다른여정ID를동일활동으로판정한다.
    func testW18_여정ID는_UTF16원문으로_비교한다() {
        XCTAssertEqual(decide(link(.journey(expectedID: "\u{00E9}")), state(id: "e\u{301}")), .safeHome)
    }

    // 깨짐: 이미열린여정에중복경로를추가한다.
    func testW18_이미열린동일여정은_alreadyOpen이다() {
        XCTAssertEqual(decide(link(), state(open: true)), .alreadyOpen)
    }

    // 깨짐: 새여정링크가확인없이기존여정을포기한다.
    func testW18_진행중새여정은_확인결정만_반환한다() {
        XCTAssertEqual(decide(link(.newJourney(expectedID: "journey-1")), state()), .confirmNewJourney)
    }

    // 깨짐: 미래분석날짜를허용하거나주간링크를월간으로바꾼다.
    func testW18_분석미래날짜는_오늘기본으로_주간종류를_유지한다() {
        XCTAssertEqual(decide(link(.analytics(day: "2026-10-17", tag: "독서", kind: .week)), state(id: nil, phase: .ready)), .analytics(day: "2026-10-16", tag: "독서", kind: .week))
        XCTAssertEqual(decide(link(.analytics(day: nil, tag: nil, kind: .month)), state(id: nil, phase: .ready)), .analytics(day: "2026-10-16", tag: nil, kind: .month))
    }

    // 호환회귀. 깨짐: invalid/expired를안전기본대신여정동작으로해석한다.
    func testW18_잘못되거나만료된링크는_safeHome이다() {
        XCTAssertEqual(decide(.invalid, state()), .safeHome)
        XCTAssertEqual(decide(.expired, state()), .safeHome)
    }

    // 깨짐: 정지여정링크를열때resume저장/토큰/타이머경로가추가된다.
    func testW18_AppModel_정지여정링크는_저장이나_resume없이_카드만_확인한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(active: BoardingFixtures.journey(phase: .departed, elapsedSeconds: 678, paused: true)), probe: probe)
        model.loadIfNeeded()
        let writes = probe.writes
        let before = model.snapshot
        XCTAssertEqual(model.handleWidgetURL(try url(.journey(expectedID: "journey-1"))), .showActiveJourney)
        XCTAssertEqual(probe.writes, writes)
        XCTAssertEqual(model.snapshot, before)
        XCTAssertEqual(model.path, [])
        XCTAssertFalse(model.consumeResumeEntry(journeyID: "journey-1"))
    }

    // 깨짐: 새여정URL이 사용자확인전에 저장된여정을 삭제한다.
    func testW18_AppModel_새여정확인결정은_기존원본을_바꾸지않는다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(active: BoardingFixtures.journey(phase: .departed, paused: true)), probe: probe)
        model.loadIfNeeded()
        let before = model.snapshot
        let writes = probe.writes
        XCTAssertEqual(model.handleWidgetURL(try url(.newJourney(expectedID: "journey-1"))), .confirmNewJourney)
        XCTAssertEqual(model.snapshot, before)
        XCTAssertEqual(probe.writes, writes)
        XCTAssertEqual(model.path, [])
    }

    // 깨짐: ready이전의TTL판정을고정하여 실제소비때 재검증하지않는다.
    func testW18_pendingURL는_ready후소비시_TTL을_재검증하고_한번만_소비한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        XCTAssertEqual(model.handleWidgetURL(try url(.analytics(day: "2026-10-14", tag: nil, kind: .week))), .deferUntilReady)
        probe.now = WidgetFixtures.date("2026-10-17T12:00:00Z")
        model.loadIfNeeded()
        XCTAssertEqual(model.consumePendingWidgetURL(), .safeHome)
        XCTAssertNil(model.consumePendingWidgetURL())
        XCTAssertEqual(probe.writes, 0)
        XCTAssertNil(model.widgetAnalyticsEntry)
    }

    // 깨짐:대기중최신여정이바뀌어도 옛링크로새여정을연다.
    func testW18_pendingURL는_복원뒤_최신여정ID로_판정한다() throws {
        let probe = WidgetAppProbe()
        let current = BoardingFixtures.journey(id: "new", phase: .departed, paused: true)
        let (model, _) = try F.make(snapshot: F.source(active: current), probe: probe)
        XCTAssertEqual(model.handleWidgetURL(try url(.journey(expectedID: "old"))), .deferUntilReady)
        model.loadIfNeeded()
        XCTAssertEqual(model.consumePendingWidgetURL(), .safeHome)
        XCTAssertEqual(model.snapshot?.journey.active?.id, "new")
        XCTAssertEqual(probe.writes, 0)
    }

    // 깨짐: 다른입력흐름열림중URL를강제적용하여메모/확인흐름을닫는다.
    func testW18_AppModel_열린흐름은_경로와_저장을_유지한다() throws {
        let probe = WidgetAppProbe()
        let (model, _) = try F.make(snapshot: F.source(), probe: probe)
        model.loadIfNeeded()
        model.open(.records)
        model.setWidgetEntryBlocked(true)
        let path = model.path
        let writes = probe.writes
        XCTAssertEqual(model.handleWidgetURL(try url(.journey(expectedID: nil))), .alreadyOpen)
        XCTAssertEqual(model.path, path)
        XCTAssertEqual(probe.writes, writes)
    }

    // 깨짐: 최신분석에없는태그를유지하거나위젯week맥락/일회소비를잃는다.
    func testW18_AppModel_분석진입은_없는태그를해제하고_week를_한번_전달한다() throws {
        let probe = WidgetAppProbe()
        let source = F.source().updating(records: RecordSection(items: [RecordsCalendarTests.record(id: "a", date: "2026-10-14", minutes: 30)]))
        let (model, _) = try F.make(snapshot: source, probe: probe)
        model.loadIfNeeded()
        XCTAssertEqual(model.handleWidgetURL(try url(.analytics(day: "2026-10-14", tag: "없는태그", kind: .week))), .analytics(day: "2026-10-14", tag: nil, kind: .week))
        XCTAssertEqual(model.consumeWidgetAnalyticsEntry(), WidgetAnalyticsEntry(day: "2026-10-14", tag: nil, kind: .week))
        XCTAssertNil(model.consumeWidgetAnalyticsEntry())
        XCTAssertEqual(probe.writes, 0)
    }
}

```
