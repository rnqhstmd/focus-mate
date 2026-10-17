# W09b T2 RED — 앱 어댑터·분석 탐색 상태

Status: DONE_WITH_CONCERNS. 테스트 작성 완료, 실행 증거 없음.

## 실행·실패 예상
총22함수: Adapter13 + Browser9. 예상 RED19 / 별도 통과 예상 호환3.
- Adapter 정상 validatedContent9건: bootstrap notImplemented unexpected throw assertion failure 예상.
- Adapter 정상 load(empty)1건: unavailable을 반환하여 available 기대 assertion 실패 예상.
- Browser9건: throwing init이 notImplemented를 던져 unexpected throw assertion failure 예상. init 구현 후 각 함수의 실제 상태전이 assertion으로 이어진다.
- nil load/손상1건 load/중복 load3건은 현재 unavailable bootstrap에서도 통과 예상이다. 이를 새 RED 증거로 세지 않는다.

테스트·빌드·시뮬레이터·브라우저 실행 없음. 부모가 bootstrap 선언 후 직접focused 실행한다. 실제 컴파일/실패메시지는 미확보이며 컴파일오류·trap을 RED로 사용하지 않는다.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/RecordsAnalyticsAdapterTests.swift ios/FocusMateTests/RecordsAnalyticsBrowserTests.swift
```
부모 소유 focused 명령 인자 해석에 맞춰 파일별로 실행할 수 있다. 전체검증은 W18 이후 사용자지시를 유지한다.

## 동작 시나리오
### Adapter13
1. nil 구역→unavailable (호환).
2. 빈 RecordSection→검증정상0/최근0/메모0/hasAnyEligible false.
3. load 빈구역→available 정상0.
4. 유효항목+201UTF16 메모손상1건→전체unavailable (호환).
5. 동일UTF16 ID중복→전체unavailable (호환).
6. 집계후저장원문과최근/메모의RecordSnapshot 보존,저장date권위 유지.
7. 완료6회→최근5회 r5...r1.
8. 메모4회→전체수4/최신3개 r3,r2,r1 및원문보존.
9. 동시각 z-first/a-second→입력순서보존.
10. composed é/decomposed e+combining acute→UTF16[233]/[101,769] 원본ID와각메모매칭.
11. report JSON 원본ID/메모/할일키·원문제외. 승인태그id허용.
12. 과거기간밖기록은 hasAnyEligible true,현재기간합계0/최근0으로 첫기록전과구분.
13. now+1초 미래완료만있으면 hasAnyEligible false/최근·메모0.

### Browser9
1. 10-14 init→10월전체/anchor10-14/tag nil.
2. 월→주10-12~18→월,anchor10-14유지/전환태그해제.
3. 미래주이동거절→period/anchor/selectedTag 전체값보존.
4. 이전주이동→10-05~11/anchor10-05/tag nil.
5. 과거주→오늘복귀,주종류유지/10-12~18/anchor10-16/tag nil.
6. 같은태그재선택→전체toggle.
7. 없는태그선택→전체fallback.
8. reconcile 삭제선택태그→nil.
9. reconcile 존재태그→선택유지.

## 작성 원칙·한계
모든테스트에 깨짐명명. 고정 now2026-10-16T23:00:00Z/UTC. 주입픽스처는 RecordSnapshot 전체필드를 명시하고 실제 RecordSection을 사용한다. 생산소스/모의/저장호출 추가 없음.
기댓값은 literal이며 UTF16 원문동등성을 명시해 Swift canonical equality로인한거짓통과를피한다. 앱전용 RecordsAnalyticsContent는직렬화하지않고 report만JSON으로검증한다.
기존완료저장 제외·재완료멱등·메모저장실패 계약은 기존회귀로 유지하고 복제하지않는다. 실제UI pop/메모sheet연결은T3. 기존잠긴T1/W17테스트수정없음.

## 참조한 파일 전체
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (같은agent에서읽은역할재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (같은agent에서읽은규칙재사용)
- .dev/codex-system-surfaces-w09b/prd.md (T1에서읽은AC재사용)
- .dev/codex-system-surfaces-w09b/design.md (T2재열람)
- .dev/codex-system-surfaces-w09b/codemap.md (T1에서읽은범위재사용)
- ios/FocusMateTests/RecordSectionTests.swift
- ios/FocusMateTests/RecordsBrowserTests.swift
- ios/FocusMateTests/RecordsAnalyticsAdapterTests.swift (신규)
- ios/FocusMateTests/RecordsAnalyticsBrowserTests.swift (신규)
rg로 Record 계열 테스트의 파일명·fixture 선언만 검색했다. 생산 파일은 읽지 않았다.

## 테스트 전문

### ios/FocusMateTests/RecordsAnalyticsAdapterTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsAdapterTests: XCTestCase {
    private var zone: TimeZone { TimeZone(secondsFromGMT: 0)! }
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = zone
        return value
    }
    private var period: AnalyticsPeriod {
        AnalyticsPeriod(kind: .month, startDay: "2026-10-01", endDay: "2026-10-31")
    }
    private func now() throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-16T23:00:00Z"))
    }
    private func record(
        _ id: String, day: String = "2026-10-14",
        completed: String = "2026-10-14T12:00:00Z", memo: String = "",
        task: String = "원문 할 일", minutes: Int = 25
    ) -> RecordSnapshot {
        RecordSnapshot(
            id: id, completedAt: completed, date: day,
            bus: "버스2014", tag: "독서", tagColor: "#12ABef",
            task: task, minutes: minutes, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: memo
        )
    }
    private func content(_ section: RecordSection) throws -> RecordsAnalyticsContent {
        try RecordsAnalyticsAdapter.validatedContent(
            section: section, period: period, selectedTag: nil, now: now(), calendar: calendar, timeZone: zone
        )
    }
    private func load(_ section: RecordSection?) throws -> RecordsAnalyticsLoad {
        RecordsAnalyticsAdapter.load(
            section: section, period: period, selectedTag: nil, now: try now(), calendar: calendar, timeZone: zone
        )
    }
    private func six() -> RecordSection {
        RecordSection(items: (0..<6).map { index in
            record("r\(index)", completed: String(format: "2026-10-14T%02d:00:00Z", index + 1), memo: index < 4 ? "메모\(index)" : "")
        })
    }

    // 호환 회귀. 깨짐: nil저장구역을 정상빈기록으로 바꾸어 손실을 숨긴다.
    func testW09b_nil구역은_unavailable이다() throws {
        XCTAssertEqual(try load(nil), .unavailable)
    }

    // 깨짐: 실제 빈구역을 접근불가로 처리하거나 hasAnyEligible를true로 만든다.
    func testW09b_빈구역의_검증결과는_정상0이다() throws {
        let result = try content(.empty)
        XCTAssertEqual(result.computation.report.totals.minutes, 0)
        XCTAssertEqual(result.computation.report.totals.count, 0)
        XCTAssertFalse(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
    }

    // 깨짐: load wrapper가 정상빈구역도 unavailable로 삼킨다.
    func testW09b_load는_빈구역도_available로_반환한다() throws {
        let result = try load(.empty)
        guard case .available(let value) = result else {
            XCTFail("정상 빈구역은 available이어야 한다")
            return
        }
        XCTAssertEqual(value.computation.report.totals.minutes, 0)
        XCTAssertFalse(value.hasAnyEligibleRecords)
    }

    // 호환 회귀. 깨짐: 손상메모1건을 건너뛰어 정상항목만 부분집계한다.
    func testW09b_손상1건이면_전체_unavailable이다() throws {
        let section = RecordSection(items: [record("ok"), record("bad", memo: String(repeating: "가", count: 201))])
        XCTAssertEqual(try load(section), .unavailable)
    }

    // 호환 회귀. 깨짐: 동일UTF16 ID중복을 제거하여 성공으로 돌려준다.
    func testW09b_중복ID구역은_전체_unavailable이다() throws {
        let section = RecordSection(items: [record("same"), record("same", minutes: 30)])
        XCTAssertEqual(try load(section), .unavailable)
    }

    // 깨짐: 집계 과정이 저장date나원문메모·할일·색을 바꾸거나 원본을 잃는다.
    func testW09b_집계후에도_원본기록값을_보존한다() throws {
        let original = record("original", day: "2026-10-12", memo: "저장된 메모", task: "저장된 할 일")
        let section = RecordSection(items: [original])

        let result = try content(section)

        XCTAssertEqual(section.items, [original])
        XCTAssertEqual(result.recent, [original])
        XCTAssertEqual(result.recentMemos, [original])
        XCTAssertEqual(result.computation.report.days.first { $0.day == "2026-10-12" }?.minutes, 25)
    }

    // 깨짐: 최근기록이6개모두이거나 오래된순서로 반환된다.
    func testW09b_6회중_최근5회만_최신순으로_반환한다() throws {
        let result = try content(six())
        XCTAssertEqual(result.recent.map(\.id), ["r5", "r4", "r3", "r2", "r1"])
    }

    // 깨짐: 최근5회만으로 메모수를 세거나 최신메모3개를 넘긴다.
    func testW09b_메모4회는_전체수4와_최신3개를_반환한다() throws {
        let result = try content(six())
        XCTAssertEqual(result.memoCount, 4)
        XCTAssertEqual(result.recentMemos.map(\.id), ["r3", "r2", "r1"])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["메모3", "메모2", "메모1"])
    }

    // 깨짐: 동시각기록을 ID순으로 재정렬하여 입력순서를 잃는다.
    func testW09b_완료시각동률은_입력순서를_보존한다() throws {
        let result = try content(RecordSection(items: [record("z-first", memo: "첫째"), record("a-second", memo: "둘째")]))
        XCTAssertEqual(result.recent.map(\.id), ["z-first", "a-second"])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["첫째", "둘째"])
    }

    // 깨짐: Swift canonical equality로 원본ID를 매칭해 서로다른기록의메모를 덮는다.
    func testW09b_canonical동등하지만_UTF16다른ID는_각원본에_매칭한다() throws {
        let section = RecordSection(items: [record("\u{00E9}", memo: "조합형"), record("e\u{301}", memo: "분해형")])
        let result = try content(section)
        XCTAssertEqual(result.recent.map { Array($0.id.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["조합형", "분해형"])
        XCTAssertEqual(result.computation.scopedRecordIDs.map { Array($0.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(result.computation.report.totals.count, 2)
    }

    // 깨짐: 앱전용원문이나원본ID가 report 투영에 섞인다.
    func testW09b_report는_메모할일원본ID를_직렬화하지_않는다() throws {
        let result = try content(RecordSection(items: [record("private-record-id", memo: "민감 메모 원문", task: "민감 할 일 원문")]))
        let data = try JSONEncoder().encode(result.computation.report)
        let object = try JSONSerialization.jsonObject(with: data)
        func keys(_ value: Any) -> [String] {
            if let map = value as? [String: Any] { return Array(map.keys) + map.values.flatMap(keys) }
            if let list = value as? [Any] { return list.flatMap(keys) }
            return []
        }
        XCTAssertTrue(Set(keys(object).map { $0.lowercased() }).isDisjoint(with: ["task", "memo", "recordid", "recordids", "scopedrecordids"]))
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(text.contains("private-record-id"))
        XCTAssertFalse(text.contains("민감 메모 원문"))
        XCTAssertFalse(text.contains("민감 할 일 원문"))
    }

    // 깨짐: 선택기간에0건이면 전체기록도 없다고 오판한다.
    func testW09b_기간밖과거기록이있으면_빈기간과_첫기록전을_구분한다() throws {
        let section = RecordSection(items: [record("old", day: "2026-09-01", completed: "2026-09-01T12:00:00Z")])
        let result = try content(section)
        XCTAssertTrue(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.computation.report.totals.count, 0)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
    }

    // 깨짐: 미래기록을 전체적격존재나최근·메모에 포함한다.
    func testW09b_미래완료만있으면_적격기록없음이다() throws {
        let section = RecordSection(items: [record("future", day: "2026-10-16", completed: "2026-10-16T23:00:01Z", memo: "미래")])
        let result = try content(section)
        XCTAssertFalse(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
        XCTAssertEqual(result.computation.report.totals.count, 0)
    }
}

```

### ios/FocusMateTests/RecordsAnalyticsBrowserTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsBrowserTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private var tags: [AnalyticsTagTotal] {
        [AnalyticsTagTotal(id: .named("독서"), name: "독서", color: "#12ABef", minutes: 25, count: 1, share: 1)]
    }

    // 깨짐: 선택일대신 오늘이나월초를 초기anchor로 쓴다.
    func testW09b_10월14일진입은_해당월과_anchor를_보존한다() throws {
        let browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .month, startDay: "2026-10-01", endDay: "2026-10-31"))
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 월초를기준으로 주전환하여10-14가없는주를고르거나 태그를유지한다.
    func testW09b_월주왕복은_선택일anchor를_유지하고_태그를_해제한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        try browser.setKind(.week, calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .week, startDay: "2026-10-12", endDay: "2026-10-18"))
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
        XCTAssertNil(browser.selectedTag)
        try browser.setKind(.month, calendar: calendar)
        XCTAssertEqual(browser.period.startDay, "2026-10-01")
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
    }

    // 깨짐: 거부된 미래이동이 태그·anchor·기간 중 일부를 바꾼다.
    func testW09b_미래주이동거부는_전체상태를_보존한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        let before = browser
        XCTAssertFalse(try browser.move(by: 1, today: "2026-10-16", calendar: calendar))
        XCTAssertEqual(browser, before)
        XCTAssertEqual(browser.selectedTag, "독서")
    }

    // 깨짐: 기간이동후기존anchor/태그를유지하여 다음종류전환이 이전기간으로돌아간다.
    func testW09b_이전주이동은_새기간시작anchor와_태그해제를_적용한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        XCTAssertTrue(try browser.move(by: -1, today: "2026-10-16", calendar: calendar))
        XCTAssertEqual(browser.period.startDay, "2026-10-05")
        XCTAssertEqual(browser.period.endDay, "2026-10-11")
        XCTAssertEqual(browser.anchorDay, "2026-10-05")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 오늘복귀가 최초선택일로돌아가거나 기간종류/태그를잘못바꾼다.
    func testW09b_오늘복귀는_현재종류의_오늘기간과_anchor로_돌아간다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-09-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        try browser.returnToToday(today: "2026-10-16", calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .week, startDay: "2026-10-12", endDay: "2026-10-18"))
        XCTAssertEqual(browser.anchorDay, "2026-10-16")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 같은태그재선택이 해제되지않거나 첫선택이 무시된다.
    func testW09b_같은태그_재선택은_전체로_토글한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        XCTAssertEqual(browser.selectedTag, "독서")
        browser.selectTag("독서", available: tags)
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 없는태그를선택상태로남겨 하위분석을거짓빈값으로만든다.
    func testW09b_없는태그선택은_전체로_복귀한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.selectTag("없는태그", available: tags)
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 갱신후사라진태그를 선택상태로 유지한다.
    func testW09b_reconcile은_삭제된선택태그를_해제한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.reconcileTags(available: [])
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 기록갱신때 존재하는선택태그까지 무조건해제한다.
    func testW09b_reconcile은_아직존재하는태그선택을_유지한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.reconcileTags(available: tags)
        XCTAssertEqual(browser.selectedTag, "독서")
    }
}

```

## 부모 실행
관련22건중19테스트실패/3호환통과. notImplemented throw 및실제available 기대assertion 실패,컴파일오류0. t2-red-run.log exit65.
