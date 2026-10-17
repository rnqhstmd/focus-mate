# W18 T1 RED 사전작성 — 공용 snapshot/store/link/presentation

Status: DONE_WITH_CONCERNS. 작성 완료, 실행 증거 없음.

## 범위와 실행
테스트4개파일(8/6/7/7함수) + 값픽스처 WidgetFixtures.swift를 신규작성했다. 총28개 테스트 함수. production파일을 읽거나수정하지 않았다. 기존 W17/W09b잠긴테스트 변경없음.
부모가 API/DTO의 최소선언과 notImplemented/default 몸체를 제공한 뒤 직접focused실행한다. 현재 W09b UI 작업중 사전작성으로서 테스트·빌드·시뮬레이터·브라우저 실행없음. 컴파일결과/실제실패메시지 미확보.
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/WidgetSnapshotTests.swift ios/FocusMateTests/WidgetSnapshotStoreTests.swift ios/FocusMateTests/WidgetLinkTests.swift ios/FocusMateTests/WidgetPresentationTests.swift
```
부모러너 인자해석에따라 파일별focused로실행가능. 한빌드만실행. 전체검증은사용자지시대로W18뒤.

## 예상 RED/호환 구분
총28개 중 **RED 예상22**, **통과 예상 호환6**.
- Snapshot8: RED7 / malformed 불일치검사1호환. encode2건은unexpected throw, unsupported2는malformed불일치, Freshness4건은unavailable불일치.
- Store6: RED4 / 주입read실패·container없음읽기2호환. write정상은unexpected throw, write실패2건은기대오류종류불일치, 유효파일read는unavailable불일치.
- Link7: RED5 / unknownpath·future발급2호환. makeURLnil을XCTUnwrap하여 assertion실패. 정적parseinvalid가이미통과하는것을새RED로세지않는다.
- Presentation7: RED6 / 오류3상태1호환. 오류기본모델/nextRefreshnow가snapshot·progress·날짜기댓값을충족하지못하여assertion실패예상.
숫자는전달받은bootstrap동작에근거한예상이며실제실패수확정아님. 컴파일오류/fatalError/프로세스trap을RED로쓰지않는다.

## 고정 값·깨짐 명명
WidgetFixtures는생산타입을정의하지않고승인DTO의테스트값만생성한다. version1/generatedAt2026-10-16T12:00:00Z(1792152000),basis10-16,0오프셋시간대(identifier GMT),주10-12~18,일별[30,0,30,0,0,0,0],60분/3회,today0/0,독서60/3. 정상paused여정total1800/elapsed678.
기대날짜·수치·비율은literal. API로기댓값계산하지않음. codec 검증용 malformed/Store선행bytes는테스트의JSONEncoder를사용하여codec.encode를우회하고독립입력으로제공한다. 각테스트앞 깨짐명명. 스타일assert/문구상수전수검사/전체렌더snapshot/대용량없음.

## 시나리오
### WidgetSnapshotTests 8
1. encode/decode 왕복이7일분석·태그·여정을보존.
2. 공유JSON에cardID/task/memo/recordIDs/report/recent/routes/insights없음. journeyID/태그id허용.
3. {version:2}만있어도unsupportedVersion2로우선판정.
4. weekMinutes61과합60불일치/중복day비연속은malformed(호환).
5. validEmpty도paused현재여정보존.
6. 1799초valid/1800초stale.
7. 자정또는시간대변경stale(이전snapshot보존).
8. generatedAt보다now1초이전이면malformed.

### WidgetSnapshotStoreTests 6
1. 실제임시컨테이너에정상본쓰기→빈분석본으로원자교체,정상읽기/단일목적파일.
2. 주입atomicWrite throw시oldbytes그대로/오류전파.
3. 미리존재한유효파일read→valid.
4. 주입readData throw→unavailable(호환).
5. containerURLnil→readunavailable(호환).
6. containerURLnil→writecontainerUnavailable,Documentsfallback없음.
실제temp파일은테스트실행시만생성되고addTeardownBlock으로삭제한다. agent가실행한것은아니다.

### WidgetLinkTests 7
1. 한글/구분자여정ID왕복.
2. analytics day/tag/kindweek보존(v2우선).
3. TTL86399초valid/86400초expired.
4. unknownpathinvalid(호환).
5. 생성된링크query를중복추가하면invalid.
6. futureissuedAtinvalid(호환).
7. newJourney 링크issuedAt원본1792152000유지/24시간뒤expired,렌더시각세탁금지.
query의비명세필드이름은추측하지않고makeURL결과를왕복/변형한다.

### WidgetPresentationTests 7
1. validEmpty도snapshot/currentpaused여정및전체목적지접근성보존.
2. stale은이전60분/기준10-16유지,업데이트필요.
3. unavailable/malformed/unsupported는snapshot/progressnil/0분없음(호환).
4. 저장elapsed678/total1800→정적0.3766667(오차0.000001),저장기준안내.
5. fresh생성12시/관찰12:10→다음12:30,now부터30분연장금지.
6. stale/오류는now+900초,즉시loop금지.
7. UTC23:55→다음00:00,NY DST적용2026-03-09T03:55Z→04:00Z자정우선.

## 참조한 파일 전체
- .dev/codex-system-surfaces-w18/prd.md
- .dev/codex-system-surfaces-w18/design.md (v2확정보완우선)
- .dev/codex-system-surfaces-w09b/design.md (앞선작업에서읽은AnalyticsTagID계약재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (동일agent역할재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (동일agent규칙재사용)
- ios/FocusMateTests/WidgetSnapshotTests.swift (신규)
- ios/FocusMateTests/WidgetSnapshotStoreTests.swift (신규)
- ios/FocusMateTests/WidgetLinkTests.swift (신규)
- ios/FocusMateTests/WidgetPresentationTests.swift (신규)
- ios/FocusMateTests/WidgetFixtures.swift (신규)

## 검증 한계
위젯갤러리/4조합실제렌더/서명AppGroup/장치등록/실제VO/앱최신상태진입은T2/T3의별도증거다. 이순수공용계약테스트로완료주장하지않는다. SnapshotFixture에금지원문을추가하여productionDTO를오염시키지않았다.

## 테스트 전문

### ios/FocusMateTests/WidgetSnapshotTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetSnapshotTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 깨짐: 공유7일/태그/저장여정이 codec 왕복에서 사라지거나 바뀐다.
    func testW18_최소공유본은_7일과_저장여정을_왕복보존한다() throws {
        let snapshot = F.snapshot()
        let encoded = try WidgetSnapshotCodec.encode(snapshot)
        XCTAssertEqual(WidgetSnapshotCodec.decode(encoded), .valid(snapshot))
    }

    // 깨짐: codec가 원본ID목록/메모/할일/카드/전체report를 공유한다.
    func testW18_공유JSON은_최소투영만_허용한다() throws {
        let data = try WidgetSnapshotCodec.encode(F.snapshot())
        let object = try JSONSerialization.jsonObject(with: data)
        func keys(_ value: Any) -> [String] {
            if let map = value as? [String: Any] { return Array(map.keys) + map.values.flatMap(keys) }
            if let list = value as? [Any] { return list.flatMap(keys) }
            return []
        }
        XCTAssertTrue(Set(keys(object).map { $0.lowercased() }).isDisjoint(with: ["cardid", "task", "memo", "recordid", "recordids", "scopedrecordids", "report", "recent", "routes", "insights"]))
        // journeyID와 named/remainder 태그id는 승인된 최소 식별자다.
    }

    // 깨짐: version만읽어도 판별할수있는2를 malformed로 낮춘다.
    func testW18_버전2는_나머지필드없이도_미지원으로_구분한다() {
        XCTAssertEqual(WidgetSnapshotCodec.decode(Data(#"{"version":2}"#.utf8)), .unsupportedVersion(2))
    }

    // 호환 회귀. 깨짐: 분합계/날짜연속성이 어긋난 공유본을 보정하여 정상화한다.
    func testW18_합계와_날짜불일치는_malformed다() throws {
        let wrongTotal = try JSONEncoder().encode(F.snapshot(total: 61))
        XCTAssertEqual(WidgetSnapshotCodec.decode(wrongTotal), .malformed)
        var days = F.snapshot().analytics.days
        days[1] = WidgetDay(day: "2026-10-12", minutes: 0, count: 0)
        let wrongDay = try JSONEncoder().encode(F.replacingDays(days))
        XCTAssertEqual(WidgetSnapshotCodec.decode(wrongDay), .malformed)
    }

    // 깨짐: 분석0건을 이유로 진행여정을 지우거나 validEmpty를 unavailable로 바꾼다.
    func testW18_validEmpty도_정지여정을_유지한다() {
        let snapshot = F.snapshot(empty: true)
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.generated, timeZone: F.utc), .validEmpty(snapshot))
    }

    // 깨짐:30분경계가포함되거나1799초에 조기만료된다.
    func testW18_1799초는_valid_1800초는_stale이다() {
        let snapshot = F.snapshot()
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-16T12:29:59Z"), timeZone: F.utc), .valid(snapshot))
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-16T12:30:00Z"), timeZone: F.utc), .stale(snapshot))
    }

    // 깨짐: 날짜또는표시시간대변경후에도 오늘현재값으로 설명한다.
    func testW18_자정또는_시간대변경은_stale이다() throws {
        let snapshot = F.snapshot()
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-17T00:00:00Z"), timeZone: F.utc), .stale(snapshot))
        let seoul = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.generated, timeZone: seoul), .stale(snapshot))
    }

    // 깨짐: 생성시각이미래인데 fresh/stale 공유정보로 허용한다.
    func testW18_미래생성시각은_malformed다() {
        XCTAssertEqual(WidgetFreshness.classify(.valid(F.snapshot()), now: F.date("2026-10-16T11:59:59Z"), timeZone: F.utc), .malformed)
    }
}

```

### ios/FocusMateTests/WidgetSnapshotStoreTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetSnapshotStoreTests: XCTestCase {
    private typealias F = WidgetFixtures
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("w18-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        return url
    }
    private func file(_ directory: URL) -> URL {
        directory.appendingPathComponent("widget-snapshot-v1.json")
    }

    // 깨짐: 유효공유본을 실제파일로 쓰지않거나 두번째쓰기를기존파일에 덧붙인다.
    func testW18_실제임시파일은_두번째공유본으로_원자교체된다() throws {
        let directory = try folder()
        let store = WidgetSnapshotStore(containerURL: { directory })
        try store.write(F.snapshot())
        try store.write(F.snapshot(empty: true))
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .validEmpty(F.snapshot(empty: true)))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["widget-snapshot-v1.json"])
    }

    // 깨짐: write실패전에 목적파일을 지워 이전공유본을 잃거나 실패를 삼킨다.
    func testW18_주입쓰기실패는_이전bytes를_보존한다() throws {
        let directory = try folder()
        let old = try JSONEncoder().encode(F.snapshot())
        try old.write(to: file(directory), options: .atomic)
        let store = WidgetSnapshotStore(
            containerURL: { directory }, atomicWrite: { _, _ in throw WidgetDataIssue.writeFailed }
        )
        XCTAssertThrowsError(try store.write(F.snapshot(empty: true))) {
            XCTAssertEqual($0 as? WidgetDataIssue, .writeFailed)
        }
        XCTAssertEqual(try Data(contentsOf: file(directory)), old)
    }

    // 깨짐: 올바른파일을읽지않거나 decode된정상값을 unavailable로 삼킨다.
    func testW18_기존유효파일을_정상공유상태로_읽는다() throws {
        let directory = try folder()
        let snapshot = F.snapshot()
        try JSONEncoder().encode(snapshot).write(to: file(directory), options: .atomic)
        let store = WidgetSnapshotStore(containerURL: { directory })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .valid(snapshot))
    }

    // 호환 회귀. 깨짐: 읽기실패를 정상0으로 위장한다.
    func testW18_주입읽기실패는_unavailable이다() throws {
        let directory = try folder()
        let store = WidgetSnapshotStore(containerURL: { directory }, readData: { _ in throw WidgetDataIssue.readFailed })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .unavailable)
    }

    // 호환 회귀. 깨짐: AppGroup없음을 정상빈공유본으로 대체한다.
    func testW18_공유컨테이너없으면_읽기는_unavailable이다() {
        let store = WidgetSnapshotStore(containerURL: { nil })
        XCTAssertEqual(store.read(now: F.generated, timeZone: F.utc), .unavailable)
    }

    // 깨짐: AppGroup없을때 쓰기를성공처리하거나 Documents로 우회한다.
    func testW18_공유컨테이너없으면_쓰기는_containerUnavailable이다() {
        let store = WidgetSnapshotStore(containerURL: { nil })
        XCTAssertThrowsError(try store.write(F.snapshot())) {
            XCTAssertEqual($0 as? WidgetDataIssue, .containerUnavailable)
        }
    }
}

```

### ios/FocusMateTests/WidgetLinkTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetLinkTests: XCTestCase {
    private typealias F = WidgetFixtures
    private func url(_ target: WidgetLinkTarget = .journey(expectedID: "journey-독서")) throws -> URL {
        try XCTUnwrap(WidgetLinkCodec.makeURL(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐: 한글·구분자를포함한원본여정ID를분해하거나 다른ID로복원한다.
    func testW18_여정링크는_원본ID를_왕복한다() throws {
        let target = WidgetLinkTarget.journey(expectedID: "여정/독서?1&2")
        let value = try url(target)
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .valid(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐: 위젯주간맥락을앱월간으로바꾸거나 태그/날짜를잃는다.
    func testW18_분석링크는_날짜태그와_week종류를_보존한다() throws {
        let target = WidgetLinkTarget.analytics(day: "2026-10-14", tag: "독서", kind: .week)
        XCTAssertEqual(WidgetLinkCodec.parse(try url(target), now: F.generated), .valid(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐:24시간정각을허용하거나 만료1초전에 차단한다.
    func testW18_TTL86399초는_유효하고86400초는_만료다() throws {
        let value = try url()
        let link = WidgetLink(issuedAt: F.generated, target: .journey(expectedID: "journey-독서"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T11:59:59Z")), .valid(link))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }

    // 호환 회귀. 깨짐: 알수없는경로를기본여정으로 해석한다.
    func testW18_알수없는경로는_invalid다() throws {
        let value = try XCTUnwrap(URL(string: "focusmate://widget/unknown?v=1&issuedAt=1792152000"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .invalid)
    }

    // 깨짐: 중복query값중하나를 임의선택하여 권한없는입력을 허용한다.
    func testW18_중복query는_invalid다() throws {
        var components = try XCTUnwrap(URLComponents(url: url(), resolvingAgainstBaseURL: false))
        let first = try XCTUnwrap(components.queryItems?.first)
        components.queryItems = (components.queryItems ?? []) + [first]
        XCTAssertEqual(WidgetLinkCodec.parse(try XCTUnwrap(components.url), now: F.generated), .invalid)
    }

    // 호환 회귀. 깨짐: 미래발급시각을 유효TTL로 받아들인다.
    func testW18_미래발급링크는_invalid다() throws {
        let value = try XCTUnwrap(URL(string: "focusmate://widget/analytics?v=1&issuedAt=1792152001&period=week"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .invalid)
    }

    // 깨짐: 링크생성때옛snapshot발급시각을현재렌더시각으로 세탁한다.
    func testW18_링크발급시각은_공유본원본시각을_유지한다() throws {
        let value = try url(.newJourney(expectedID: nil))
        let components = try XCTUnwrap(URLComponents(url: value, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems?.first { $0.name == "issuedAt" }?.value, "1792152000")
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }
}

```

### ios/FocusMateTests/WidgetPresentationTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class WidgetPresentationTests: XCTestCase {
    private typealias F = WidgetFixtures

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
}

```

### ios/FocusMateTests/WidgetFixtures.swift
```swift
import Foundation
@testable import FocusMate

/// W18 테스트 값만 제공한다. 생산 타입·함수는 정의하지 않는다.
enum WidgetFixtures {
    static let utc = TimeZone(secondsFromGMT: 0)!
    static func date(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text)!
    }
    static var generated: Date { date("2026-10-16T12:00:00Z") }
    static var journey: WidgetJourney {
        WidgetJourney(phase: .paused, journeyID: "journey-독서", busNumber: "2014", destination: "성동구민체육센터", totalSeconds: 1800, elapsedSeconds: 678)
    }
    static func snapshot(empty: Bool = false, version: Int = 1, total: Int? = nil) -> WidgetSnapshot {
        let days = [
            WidgetDay(day: "2026-10-12", minutes: empty ? 0 : 30, count: empty ? 0 : 2),
            WidgetDay(day: "2026-10-13", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-14", minutes: empty ? 0 : 30, count: empty ? 0 : 1),
            WidgetDay(day: "2026-10-15", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-16", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-17", minutes: 0, count: 0),
            WidgetDay(day: "2026-10-18", minutes: 0, count: 0)
        ]
        return WidgetSnapshot(
            version: version, generatedAt: generated, basisDay: "2026-10-16", timeZoneID: "GMT",
            journey: journey,
            analytics: WidgetAnalytics(
                today: WidgetDay(day: "2026-10-16", minutes: 0, count: 0),
                weekStart: "2026-10-12", weekEnd: "2026-10-18",
                weekMinutes: total ?? (empty ? 0 : 60), weekCount: empty ? 0 : 3,
                days: days,
                tags: empty ? [] : [WidgetTag(id: .named("독서"), name: "독서", color: "#12ABef", minutes: 60, count: 3)]
            )
        )
    }
    static func replacingDays(_ days: [WidgetDay]) -> WidgetSnapshot {
        let s = snapshot()
        return WidgetSnapshot(
            version: s.version, generatedAt: s.generatedAt, basisDay: s.basisDay, timeZoneID: s.timeZoneID,
            journey: s.journey,
            analytics: WidgetAnalytics(today: s.analytics.today, weekStart: s.analytics.weekStart, weekEnd: s.analytics.weekEnd, weekMinutes: 60, weekCount: 3, days: days, tags: s.analytics.tags)
        )
    }
}

```
