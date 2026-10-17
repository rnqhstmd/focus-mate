# W18 T3 RED — 공용 타임라인·위젯 진입 링크

Status: DONE_WITH_CONCERNS — 테스트 작성 완료, 실행 증거 없음.

## 범위·실행 상태
신규 WidgetTimelinePlanTests.swift4건 + WidgetEntryLinksTests.swift4건 = **8건**. 기존 테스트 수정 없음. 생산 파일 읽기/쓰기 및 테스트·빌드·시뮬레이터·브라우저 실행 없음.
부모가 승인된 선언을 추가한 후 API 컴파일 점검/focused 실행한다. 의도한 RED는 타임라인 누락/잘못된상태·날짜와 링크nil/잘못된대상에 대한 assertion 실패다. 빈entries/nil링크 scaffold라면 **8건 RED 예상**, 별도 통과 예상 호환 테스트 없음. 실제 stub 반환과 컴파일/실패 메시지는 아직 미확보이므로 실패수를 확정하지 않는다. 컴파일 오류나 trap을 RED 증거로 쓰지 않는다.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/WidgetTimelinePlanTests.swift ios/FocusMateTests/WidgetEntryLinksTests.swift
```

## 승인 인터페이스
- WidgetTimelineValue(date:Date,state:WidgetReadState), Equatable.
- WidgetTimelinePlan.entries(state:WidgetReadState,now:Date,timeZone:TimeZone)->[WidgetTimelineValue], 항상2개.
- WidgetEntryLinks.focus(state:WidgetReadState)->URL?.
- WidgetEntryLinks.analytics(state:WidgetReadState,day:String?=nil,tag:WidgetTag?=nil)->URL?.
부모 디스패치의 추가 승인 계약을 사용했다. WidgetPresentation.nextRefreshDate/WidgetFreshness.classify는 생산 구현을 읽지 않고 앞선 설계와 승인 계약만 참조한다. 기대 entries는 helper로 계산하지 않고 독립 literal로 지정한다.

## 시나리오·깨짐 명명
1. fresh12:00→현재valid +12:30stale, 같은snapshot/저장진도.
2. 23:50생성본/23:55관찰→다음00:00stale,기준일10-16/주[30,0,30,0,0,0,0]/elapsed678그대로. 자정재집계·진도외삽금지.
3. 이미stale12:30→현재와12:45 동일stale. 즉시루프/fresh부활금지.
4. unavailable/malformed/unsupported2→현재와15분뒤 같은오류2entry. 정상0대체금지.
5. focus stale공유본→journey expectedID 'journey-독서'/issuedAt원본12:00 보존,24h정각expired.
6. snapshot없는오류3상태의focus/analytics→정확한safehomeURL focusmate://widget,샘플대상없음.
7. named독서/선택10-14분석→day10-14/tag독서/kindweek/원본발급.
8. remainder기타/기본날짜분석→이전basis10-16/tag nil/kindweek/원본발급/24h정각expired.
각 함수앞 깨짐주석. 모의·sleep·스타일assert 없음. URL은 문자열query를추측하지않고 기존codec.parse결과로 대상·발급시각 계약을 관찰한다. safehome URL만 승인 문자열과 비교한다.

## 참조한 파일 전체
- .dev/codex-system-surfaces-w18/prd.md (동일agent 앞선T2에서읽은AC3/5/6재사용)
- .dev/codex-system-surfaces-w18/design.md (동일agent 앞선T2에서읽은v2계약재사용,추가계약은부모메시지)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (역할재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (규칙재사용)
- ios/FocusMateTests/WidgetFixtures.swift (이번재열람)
- ios/FocusMateTests/WidgetTimelinePlanTests.swift (신규)
- ios/FocusMateTests/WidgetEntryLinksTests.swift (신규)

## 외부 검증 분리
실제Provider타임라인연결/4조합UI/갤러리등록/서명/실제캡처·VO는 부모의 빌드 및 장치/시각 검증 범위다. 이순수값테스트로 완료 주장하지 않는다.

## 테스트 전문

### ios/FocusMateTests/WidgetTimelinePlanTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetTimelinePlanTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 깨짐:30분경계entry를누락하거나같은snapshot의저장진도를시간만큼외삽한다.
    func testW18_fresh공유본은_현재와30분stale_두entry를_제공한다() {
        let snapshot = F.snapshot()
        let entries = WidgetTimelinePlan.entries(state: .valid(snapshot), now: F.generated, timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T12:00:00Z"), state: .valid(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-16T12:30:00Z"), state: .stale(snapshot))
        ])
    }

    // 깨짐:자정entry에서지난날분석을재계산하거나기준일과저장경과678을바꾼다.
    func testW18_30분보다빠른자정은_같은공유본을_stale로만_바꾼다() throws {
        let base = F.snapshot()
        let snapshot = WidgetSnapshot(
            version: base.version, generatedAt: F.date("2026-10-16T23:50:00Z"),
            basisDay: base.basisDay, timeZoneID: base.timeZoneID, journey: base.journey, analytics: base.analytics
        )
        let entries = WidgetTimelinePlan.entries(state: .valid(snapshot), now: F.date("2026-10-16T23:55:00Z"), timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T23:55:00Z"), state: .valid(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-17T00:00:00Z"), state: .stale(snapshot))
        ])
        let next = try XCTUnwrap(entries.last)
        guard case .stale(let retained) = next.state else { return XCTFail("다음 entry는 stale이어야 한다") }
        XCTAssertEqual(retained.journey.elapsedSeconds, 678)
        XCTAssertEqual(retained.analytics.days.map(\.minutes), [30, 0, 30, 0, 0, 0, 0])
        XCTAssertEqual(retained.basisDay, "2026-10-16")
    }

    // 깨짐:이미stale인자료를즉시재요청하거나fresh로되살린다.
    func testW18_stale공유본은_15분뒤에도_같은값으로_stale이다() {
        let snapshot = F.snapshot()
        let entries = WidgetTimelinePlan.entries(state: .stale(snapshot), now: F.date("2026-10-16T12:30:00Z"), timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T12:30:00Z"), state: .stale(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-16T12:45:00Z"), state: .stale(snapshot))
        ])
    }

    // 깨짐:오류상태를다음entry에서정상0으로대체하거나오류종류를잃는다.
    func testW18_오류타임라인도_두entry에서_같은오류를_유지한다() {
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2)]
        for state in states {
            let entries = WidgetTimelinePlan.entries(state: state, now: F.generated, timeZone: F.utc)
            XCTAssertEqual(entries, [
                WidgetTimelineValue(date: F.date("2026-10-16T12:00:00Z"), state: state),
                WidgetTimelineValue(date: F.date("2026-10-16T12:15:00Z"), state: state)
            ])
        }
    }
}

```

### ios/FocusMateTests/WidgetEntryLinksTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetEntryLinksTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 깨짐:집중위젯링크가공유여정ID를누락하거나발급시각을렌더시각으로세탁한다.
    func testW18_집중링크는_공유여정ID와_원본발급시각을_보존한다() throws {
        let snapshot = F.snapshot()
        let url = try XCTUnwrap(WidgetEntryLinks.focus(state: .stale(snapshot)))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .journey(expectedID: "journey-독서")
        )))
        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }

    // 깨짐:공유본없음을샘플여정/분석링크로꾸미거나앱열기경로를제공하지않는다.
    func testW18_오류상태의_두위젯링크는_안전기본URL이다() throws {
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2)]
        for state in states {
            let focus = try XCTUnwrap(WidgetEntryLinks.focus(state: state))
            let analytics = try XCTUnwrap(WidgetEntryLinks.analytics(state: state))
            XCTAssertEqual(focus.absoluteString, "focusmate://widget")
            XCTAssertEqual(analytics.absoluteString, "focusmate://widget")
        }
    }

    // 깨짐:태그선택분석링크가위젯주간맥락이나선택날짜/태그이름을잃는다.
    func testW18_named태그분석링크는_선택날짜와_week를_전달한다() throws {
        let snapshot = F.snapshot()
        let tag = try XCTUnwrap(snapshot.analytics.tags.first)
        let url = try XCTUnwrap(WidgetEntryLinks.analytics(state: .valid(snapshot), day: "2026-10-14", tag: tag))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .analytics(day: "2026-10-14", tag: "독서", kind: .week)
        )))
    }

    // 깨짐:묶음기타를실제기타태그로필터하거나기본day를현재시각으로바꾼다.
    func testW18_remainder분석링크는_이전기준일과_전체태그를_전달한다() throws {
        let remainder = WidgetTag(id: .remainder, name: "기타", color: "#BFC6C1", minutes: 10, count: 1)
        let url = try XCTUnwrap(WidgetEntryLinks.analytics(state: .stale(F.snapshot()), tag: remainder))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .analytics(day: "2026-10-16", tag: nil, kind: .week)
        )))
        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }
}

```
