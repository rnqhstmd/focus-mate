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
