import Foundation
import XCTest
@testable import FocusMate

final class WidgetPresentationTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 회귀: 지난 기준일의 합계를 현재 오늘/이번 주라고 낭독하지 않는다.
    func testW18_stale접근성은_기준일과_해당주를_명시한다() {
        let result = WidgetPresentation.content(state: .stale(F.snapshot()))
        XCTAssertTrue(result.axSummary.contains("기준일 2026-10-16"))
        XCTAssertTrue(result.axSummary.contains("업데이트 필요"))
        XCTAssertFalse(result.axSummary.contains("오늘"))
        XCTAssertFalse(result.axSummary.contains("이번 주"))
        XCTAssertTrue(result.axSummary.contains("해당 주"))
        XCTAssertTrue(result.axSummary.contains("60분 3회"))
    }

    // 깨짐: 분석0건상태를 이유로 현재여정과 저장진행을 지운다.
    func testW18_정상빈분석도_현재정지여정과_공유값을_유지한다() {
        let snapshot = F.snapshot(empty: true)
        let result = WidgetPresentation.content(state: .validEmpty(snapshot))
        XCTAssertEqual(result.snapshot, snapshot)
        XCTAssertFalse(result.isStale)
        XCTAssertTrue(result.subtitle.contains("성동구민체육센터"))
        XCTAssertTrue(result.axSummary.contains("성동구민체육센터"))
    }

    // 깨짐: stale공유본의옛값을버리거나 오늘현재값으로 설명한다.
    func testW18_stale는_이전기준일과_이전분석값을_유지한다() {
        let snapshot = F.snapshot()
        let result = WidgetPresentation.content(state: .stale(snapshot))
        XCTAssertEqual(result.snapshot?.analytics.weekMinutes, 60)
        XCTAssertEqual(result.snapshot?.basisDay, "2026-10-16")
        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.basisText, "기준일 2026-10-16 · 업데이트 필요")
    }

    // 호환 회귀. 깨짐: 읽기/손상/미지원오류를 정상0분공유상태로 바꾼다.
    func testW18_오류3상태는_0분데이터나_진행률을_제공하지_않는다() {
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2)]
        for state in states {
            let result = WidgetPresentation.content(state: state)
            XCTAssertNil(result.snapshot)
            XCTAssertNil(result.progress)
            XCTAssertFalse(result.isStale)
            XCTAssertEqual(result.basisText, "")
            XCTAssertFalse(result.axSummary.contains("0분"))
        }
    }

    // 깨짐: 공유진행을 실시간카운트다운으로외삽하거나 elapsed/total을뒤집는다.
    func testW18_저장진행678초는_정적0점3766667이다() throws {
        let result = WidgetPresentation.content(state: .valid(F.snapshot()))
        XCTAssertEqual(try XCTUnwrap(result.progress), 0.3766667, accuracy: 0.000001)
        XCTAssertEqual(result.snapshot?.journey.elapsedSeconds, 678)
        XCTAssertTrue(result.basisText.contains("저장된 정보"))
    }

    // 깨짐: fresh공유본만료를 현재시각부터30분씩미루어 만료를영원히연장한다.
    func testW18_fresh다음갱신은_생성시각부터1800초다() {
        let result = WidgetPresentation.nextRefreshDate(
            state: .valid(F.snapshot()), now: F.date("2026-10-16T12:10:00Z"), timeZone: F.utc
        )
        XCTAssertEqual(result, F.date("2026-10-16T12:30:00Z"))
    }

    // 깨짐: 이미stale인자료를 now로 재예약해 즉시갱신루프를 만든다.
    func testW18_stale와오류는_900초뒤로_완만하게_재요청한다() {
        let states: [WidgetReadState] = [.stale(F.snapshot()), .unavailable]
        for state in states {
            let result = WidgetPresentation.nextRefreshDate(state: state, now: F.generated, timeZone: F.utc)
            XCTAssertEqual(result, F.date("2026-10-16T12:15:00Z"))
        }
    }

    // 깨짐: 다음자정을고정24시간/고정UTC오프셋으로잡아 DST뒤기준일이 늦게바뀐다.
    func testW18_자정이900초보다빠르면_UTC와DST현지자정을_택한다() throws {
        let utc = WidgetPresentation.nextRefreshDate(
            state: .stale(F.snapshot()), now: F.date("2026-10-16T23:55:00Z"), timeZone: F.utc
        )
        XCTAssertEqual(utc, F.date("2026-10-17T00:00:00Z"))
        let newYork = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let dst = WidgetPresentation.nextRefreshDate(
            state: .stale(F.snapshot()), now: F.date("2026-03-09T03:55:00Z"), timeZone: newYork
        )
        XCTAssertEqual(dst, F.date("2026-03-09T04:00:00Z"))
    }
    // 깨짐: children.ignore 표면의 요약이 저장진행숫자를누락하거나 시각38%와다르게버림한다.
    func testW18_접근성요약은_저장진행678초를_38퍼센트로_제공한다() {
        let states: [WidgetReadState] = [
            .valid(F.snapshot()), .stale(F.snapshot()), .validEmpty(F.snapshot(empty: true))
        ]
        for state in states {
            let result = WidgetPresentation.content(state: state)
            XCTAssertTrue(result.axSummary.contains("저장된 진행 38%"), result.axSummary)
        }
    }

    // 호환회귀. 깨짐: 진도없는오류/새준비상태를 저장진행0%로꾸며낭독한다.
    func testW18_진도없는_오류와ready는_저장진행숫자를_제공하지않는다() {
        let base = F.snapshot(empty: true)
        let ready = WidgetSnapshot(
            version: base.version, generatedAt: base.generatedAt, basisDay: base.basisDay,
            timeZoneID: base.timeZoneID,
            journey: WidgetJourney(phase: .ready, journeyID: nil, busNumber: nil, destination: nil, totalSeconds: nil, elapsedSeconds: nil),
            analytics: base.analytics
        )
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2), .validEmpty(ready)]
        for state in states {
            let result = WidgetPresentation.content(state: state)
            XCTAssertNil(result.progress)
            XCTAssertNil(result.axSummary.range(of: "저장된 진행[[:space:]]*[0-9]+%", options: .regularExpression), result.axSummary)
        }
    }

}
