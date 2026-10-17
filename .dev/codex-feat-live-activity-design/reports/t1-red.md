# W17 T1 RED 작성 보고

Status: DONE_WITH_CONCERNS — 테스트 작성 완료, 실행 증거 없음.

## 실행 상태
사용자 지시로 테스트·빌드·시뮬레이터를 실행하지 않았다. 부모가 W18 완료 전 focused만 한 빌드씩 직접 실행한다.
실패 메시지: 미확보. assertion RED 예상은 실행 확인을 뜻하지 않는다. 생산 소스는 읽거나 수정하지 않았다.

부모 실행용 focused 명령:
```sh
python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift ios/FocusMateTests/JourneyLiveActivitySyncTests.swift ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift ios/FocusMateTests/JourneyActivityContentStateCodableTests.swift
```

## 작성 범위·예상 결과
신규 testW17_ 10건. 예상 assertion RED 8건, legacy JSON 호환 2건은 통과 예상(신규 호환 계약의 특성화 검사). 미실행이므로 컴파일 및 실제 실패 수 미확정.
- Sync 4건: 30분 실행 시작, 일시정지, 300초 뒤 재개에서 총1800초 전달 / 기존 활동 재사용에서 총3600초 보강.
- Policy 1건: launch 계획이 남은1122초와 구분해 총1800초 전달.
- Cleanup 1건: launch cleanup 갱신이 총3600초 전달.
- Codable 2건 RED: 총1800초 running / 총3600초 paused JSON 왕복 보존.
- Codable 2건 호환: total 누락/null인 legacy JSON의 기존 상태·시간 보존.

신규 totalSeconds 속성을 직접 참조하지 않고, 기존 API가 낸 request.state를 JSONEncoder→JSONSerialization으로 관찰한다. Codable 신규 total 포함 literal JSON도 기존 decode API로 전달하므로 새 API가 없어 생기는 컴파일 오류를 RED로 사용하지 않는다. 기대값은 독립 literal 1800/3600/1122와 고정 Date다.
각 케이스 위의 ‘깨짐’ 주석에 누락·잔여값 오전달·정지시간 포함·왕복 손실을 명명했다. 게이트웨이는 기존 경계 double을 그대로 사용하고 실제 Sync/Policy/cleanup 결과를 관찰한다.

## 기존 회귀 유지 및 경계
- Sync Rig minutes:Int=60 인자만 추가하여 기존60분 사례를 보존한다.
- 기존 launch 계획 테스트의 expected를 생산 pausedRequest로 계산하던 전체 동등 비교는 id/status/end/stale/잔여의 직접 관찰로 변경했다. 총시간 보강 후 default nil 요청과 비교해 생길 불필요한 회귀를 피하며 기존 의미는 유지한다.
- 매초 추가 요청 없음·pause/resume 종료시각·도착 즉시 종료·취소/중복/다른 활동 cleanup 회귀는 기존 테스트에서 유지하며 억지 신규 RED로 복제하지 않았다.
- JourneyActivityDisplayTests.swift는 T2 소유. 읽기만 했고 수정하지 않았다. 승인 totalSeconds 추가 후 민감 필드 제한 7→8 및 totalSeconds만 허용하는 변경은 T2에서 필요하다.
- 없는 BoardingFixtures.swift 읽기를 한 번 시도한 뒤 검색으로 BoardingTestDoubles.swift를 찾아 참조했다. 생산 파일 접근은 없었다.

## 참조한 파일 전체
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md
- .dev/codex-feat-live-activity-design/prd.md
- .dev/codex-feat-live-activity-design/design.md
- .dev/codex-feat-live-activity-design/rgr-tasks.md
- ios/FocusMateTests/BoardingTestDoubles.swift
- ios/FocusMateTests/JourneyActivityDisplayTests.swift
- ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift
- ios/FocusMateTests/JourneyLiveActivitySyncTests.swift
- ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift
- ios/FocusMateTests/JourneyActivityContentStateCodableTests.swift

## 테스트 파일 전체

### ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// Live Activity 정책: 속성·요청·appear/launch 계획 (AC-10, 11, 31~34, BR-1, BR-5).
final class JourneyLiveActivityPolicyTests: XCTestCase {
    private typealias F = BoardingFixtures
    private let now = Date(timeIntervalSince1970: 1_791_882_000)

    private func handle(_ id: String, _ journeyID: String) -> LiveActivityHandle {
        LiveActivityHandle(id: id, journeyID: journeyID)
    }

    private func departed(id: String = "j-1", elapsed: Int = 600) -> JourneySnapshot {
        F.journey(id: id, phase: .departed, elapsedSeconds: elapsed)
    }

    // MARK: attributes(for:)

    // 깨짐: journeyID/버스 번호/종류/도착지 이름을 저장된 여정 값이 아닌 곳에서 가져오면 실패한다.
    func testV15_AC31_속성은_저장된_번호_종류_도착지_이름을_쓴다() {
        let snapshot = F.journey(
            busID: "421", busNumber: "343", busKind: "간선",
            destinationStopID: "seongsuIntersection", destinationName: "성수사거리", phase: .departed
        )

        let attrs = JourneyLiveActivityPolicy.attributes(for: snapshot)

        XCTAssertEqual(attrs.journeyID, "journey-1")
        XCTAssertEqual(attrs.busNumber, "343")
        XCTAssertEqual(attrs.busKind, "간선")
        XCTAssertEqual(attrs.destinationName, "성수사거리")
    }

    // 깨짐: 카탈로그 밖 id인 여정에서 속성을 만들지 않으면(non-optional 계약 위반) 실패한다.
    func testV15_카탈로그_밖_id여도_속성이_만들어진다() {
        let attrs = JourneyLiveActivityPolicy.attributes(
            for: F.journey(busID: "gone-bus", busNumber: "N37", destinationStopID: "gone-dest", destinationName: "사라진 곳")
        )
        XCTAssertEqual(attrs.busNumber, "N37")
        XCTAssertEqual(attrs.destinationName, "사라진 곳")
    }

    // MARK: request

    // 깨짐: endDate를 now + 남은 초로 계산하지 않거나 staleDate가 endDate와 다르면 실패한다.
    func testV15_정책_진행중_요청은_종료시각과_stale이_같다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .running, remainingSeconds: 3000, now: now))

        XCTAssertEqual(req.state.status, .running)
        XCTAssertEqual(req.state.endDate, Date(timeIntervalSince1970: 1_791_885_000))
        XCTAssertNil(req.state.pausedRemainingSeconds)
        XCTAssertEqual(req.staleDate, Date(timeIntervalSince1970: 1_791_885_000))
    }

    // 깨짐: 일시정지에 endDate/stale을 남기거나 남은 초를 담지 않으면 실패한다.
    func testV15_정책_일시정지_요청은_남은초만_담는다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: 1200, now: now))

        XCTAssertEqual(req.state.status, .paused)
        XCTAssertNil(req.state.endDate)
        XCTAssertEqual(req.state.pausedRemainingSeconds, 1200)
        XCTAssertNil(req.staleDate)
    }

    // 깨짐: 음수 남은 초를 0으로 올리지 않으면 실패한다.
    func testV15_정책_일시정지_음수_남은초는_0이다() throws {
        let req = try XCTUnwrap(JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: -5, now: now))

        XCTAssertEqual(req.state.pausedRemainingSeconds, 0)
    }

    // 깨짐: 도착 상태에서 요청을 만들면 실패한다.
    func testV15_정책_도착_요청은_nil이다() {
        XCTAssertNil(JourneyLiveActivityPolicy.request(status: .arrived, remainingSeconds: 0, now: now))
    }

    // 깨짐: pausedRequest가 paused 요청과 다르면 실패한다.
    func testV15_정책_pausedRequest는_일시정지_요청과_같다() {
        let expected = JourneyLiveActivityPolicy.request(status: .paused, remainingSeconds: 3000, now: now)

        XCTAssertNotNil(expected)
        XCTAssertEqual(JourneyLiveActivityPolicy.pausedRequest(remainingSeconds: 3000), expected)
    }

    // MARK: appearPlan

    // 깨짐: 같은 여정의 첫 handle을 재사용하지 않거나 나머지를 종료하지 않으면 실패한다.
    func testV15_정책_appear는_같은_여정_첫_handle을_재사용하고_나머지를_종료한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(
            existing: [handle("old-1", "j-1"), handle("old-2", "j-1")], journeyID: "j-1"
        )

        XCTAssertEqual(plan.reuseID, "old-1")
        XCTAssertEqual(plan.endIDs, ["old-2"])
    }

    // 깨짐: 다른 여정 handle을 재사용하면 실패한다.
    func testV15_정책_appear는_다른_여정_handle을_종료한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(existing: [handle("x-1", "other")], journeyID: "j-1")

        XCTAssertNil(plan.reuseID)
        XCTAssertEqual(plan.endIDs, ["x-1"])
    }

    // 깨짐: 빈 입력에서 무언가 반환하면 실패한다.
    func testV15_정책_appear는_기존이_없으면_비어_있다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(existing: [], journeyID: "j-1")

        XCTAssertNil(plan.reuseID)
        XCTAssertEqual(plan.endIDs, [])
    }

    // 깨짐: 다른 여정과 같은 여정이 섞일 때 입력 순서를 잃으면 실패한다.
    func testV15_정책_appear는_종료_목록의_입력_순서를_유지한다() {
        let plan = JourneyLiveActivityPolicy.appearPlan(
            existing: [handle("a", "other"), handle("b", "j-1"), handle("c", "other"), handle("d", "j-1")],
            journeyID: "j-1"
        )

        XCTAssertEqual(plan.reuseID, "b")
        XCTAssertEqual(plan.endIDs, ["a", "c", "d"])
    }

    // MARK: launchPlan

    // 깨짐: 여정이 없는데 기존 activity를 남기면 실패한다 (AC-10).
    func testV15_AC10_여정이_없으면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1"), handle("b", "j-2")], journey: nil
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a", "b"], pausedUpdate: nil))
    }

    // 깨짐: 출발 전 여정에 activity를 남기면 실패한다 (AC-10).
    func testV15_AC10_출발_전이면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .awaitingDeparture)
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a"], pausedUpdate: nil))
    }

    // 깨짐: 도착한 여정에 activity를 남기면 실패한다 (AC-11).
    func testV15_AC11_도착했으면_전부_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: departed(elapsed: 3600)
        )

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["a"], pausedUpdate: nil))
    }

    // 깨짐: 같은 여정 첫 handle을 일시정지로 갱신하지 않거나 남은 초(3600-600)를 잘못 계산하면 실패한다 (AC-32).
    func testV15_AC32_출발_미도착이면_첫_handle을_일시정지로_갱신한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [handle("a", "j-1")], journey: departed())

        XCTAssertEqual(plan.endIDs, [])
        XCTAssertEqual(plan.pausedUpdate?.id, "a")
        XCTAssertEqual(plan.pausedUpdate?.request.state.status, .paused)
        XCTAssertNil(plan.pausedUpdate?.request.state.endDate)
        XCTAssertNil(plan.pausedUpdate?.request.staleDate)
        XCTAssertEqual(plan.pausedUpdate?.request.state.pausedRemainingSeconds, 3000)
    }

    // 깨짐: 중복 activity와 다른 여정 activity를 종료하지 않으면 실패한다 (AC-33).
    func testV15_AC33_중복과_다른_여정은_종료한다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("x", "other"), handle("a", "j-1"), handle("b", "j-1")], journey: departed()
        )

        XCTAssertEqual(plan.endIDs, ["x", "b"])
        XCTAssertEqual(plan.pausedUpdate?.id, "a")
    }

    // 깨짐: 같은 여정 activity가 없는데 갱신을 만들면 실패한다.
    func testV15_정책_같은_여정이_없으면_다른_여정만_종료하고_갱신은_없다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [handle("x", "other")], journey: departed())

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: ["x"], pausedUpdate: nil))
    }

    // 깨짐: 기존이 없는데 계획이 비어 있지 않으면 실패한다 (AC-34).
    func testV15_AC34_기존이_없으면_계획이_비어_있다() {
        let plan = JourneyLiveActivityPolicy.launchPlan(existing: [], journey: departed())

        XCTAssertEqual(plan, JourneyLaunchPlan(endIDs: [], pausedUpdate: nil))
    }

    // 깨짐: journey.paused 값에 따라 계획이 달라지면 실패한다.
    func testV15_정책_저장된_paused_값은_계획에_영향을_주지_않는다() {
        let running = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .departed, elapsedSeconds: 600, paused: false)
        )
        let paused = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: F.journey(id: "j-1", phase: .departed, elapsedSeconds: 600, paused: true)
        )

        XCTAssertEqual(running, paused)
        XCTAssertEqual(running.pausedUpdate?.request.state.pausedRemainingSeconds, 3000)
    }
    // 깨짐: launch 계획이 잔여 1122초를 총 시간으로 쓰거나 총 시간을 누락한다.
    func testW17_launch계획은_30분여정의_총1800초를_전달한다() throws {
        let journey = F.journey(id: "j-1", minutes: 30, phase: .departed, elapsedSeconds: 678)

        let plan = JourneyLiveActivityPolicy.launchPlan(
            existing: [handle("a", "j-1")], journey: journey
        )

        let request = try XCTUnwrap(plan.pausedUpdate?.request)
        let data = try JSONEncoder().encode(request.state)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["totalSeconds"] as? Int, 1800)
    }

}

```

### ios/FocusMateTests/JourneyLiveActivitySyncTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 타이머 상태 변화가 Live Activity 게이트웨이 요청으로 정확히 옮겨지는지 검증한다.
@MainActor
final class JourneyLiveActivitySyncTests: XCTestCase {
    let base = Date(timeIntervalSince1970: 1_791_882_000)

    @MainActor struct Rig {
        let controller: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
        let gateway: RecordingLiveActivityGateway
        let sync: JourneyLiveActivitySync
        let journey: JourneySnapshot
        let base: Date

        /// 시계 현재 시각 (정수 초).
        var currentDate: Date { base.addingTimeInterval(TimeInterval(clock.now.components.seconds)) }
    }

    func makeRig(
        existing: [LiveActivityHandle] = [],
        minutes: Int = 60,
        elapsed: Int = 0,
        paused: Bool = false,
        autoStart: Bool = true,
        results: [Bool] = []
    ) throws -> Rig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver(results: results)
        let gateway = RecordingLiveActivityGateway(existing: existing)
        let journey = BoardingFixtures.journey(
            minutes: minutes, busID: "421", busNumber: "343", busKind: "간선", phase: .departed, elapsedSeconds: elapsed, paused: paused
        )
        let start = base
        let sync = try XCTUnwrap(JourneyLiveActivitySync(
            journey: journey, gateway: gateway,
            now: { start.addingTimeInterval(TimeInterval(clock.now.components.seconds)) }
        ))
        let controller = JourneyTimerController(
            journey: journey, autoStart: autoStart, saver: saver, clock: clock,
            ticker: clock, announcer: RecordingAnnouncer(), observer: sync
        )
        return Rig(controller: controller, clock: clock, saver: saver, gateway: gateway,
                   sync: sync, journey: journey, base: start)
    }

    // MARK: W17 총 시간 전달

    private func totalSecondsJSON(_ request: JourneyActivityRequest) throws -> Int? {
        let data = try JSONEncoder().encode(request.state)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return object["totalSeconds"] as? Int
    }

    // 깨짐: 실행 요청에서 총 시간을 누락하거나 잔여 1122초를 총 시간으로 전달한다.
    func testW17_실행_시작은_30분의_총1800초를_전달한다() throws {
        let rig = try makeRig(minutes: 30, elapsed: 678)

        rig.controller.appear()

        let request = try XCTUnwrap(rig.gateway.entries.first?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(try totalSecondsJSON(request), 1800)
    }

    // 깨짐: 일시정지 요청에서 총 시간을 버리거나 잔여 시간으로 덮어쓴다.
    func testW17_일시정지는_남은1122초와_총1800초를_전달한다() throws {
        let rig = try makeRig(minutes: 30)
        rig.controller.appear()
        rig.clock.advance(by: .seconds(678), notify: false)

        rig.controller.pause()

        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 1122)
        XCTAssertEqual(try totalSecondsJSON(request), 1800)
    }

    // 깨짐: 재개 요청에서 총 시간을 누락하거나 일시정지 300초를 총 시간에 더한다.
    func testW17_300초_정지후_재개도_총1800초를_전달한다() throws {
        let rig = try makeRig(minutes: 30)
        rig.controller.appear()
        rig.clock.advance(by: .seconds(678), notify: false)
        rig.controller.pause()
        rig.clock.advance(by: .seconds(300), notify: false)

        rig.controller.resume()

        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, Date(timeIntervalSince1970: 1_791_884_100))
        XCTAssertEqual(try totalSecondsJSON(request), 1800)
    }

    // 깨짐: 기존 활동 재사용 갱신에 총 시간을 보강하지 않는다.
    func testW17_기존활동_재사용은_60분의_총3600초를_보강한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")],
            minutes: 60, elapsed: 600
        )

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.entries.last?.op, .update)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(try totalSecondsJSON(request), 3600)
    }

    // MARK: AC-1

    // 깨짐: 진입 시 start를 안 하거나 2번 하거나, endDate/staleDate/속성(버스·종류·목적지·journeyID)이 틀리면 실패한다.
    func testV15_AC1_진행_중_진입하면_종료시각이_정해진_실행_카드를_1회_시작한다() throws {
        let rig = try makeRig()
        let t = rig.currentDate

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        let request = try XCTUnwrap(rig.gateway.entries.first?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t.addingTimeInterval(3600))
        XCTAssertEqual(request.staleDate, t.addingTimeInterval(3600))
        let attributes = try XCTUnwrap(rig.gateway.lastStartAttributes)
        XCTAssertEqual(attributes.busNumber, "343")
        XCTAssertEqual(attributes.busKind, "간선")
        XCTAssertEqual(attributes.destinationName, rig.journey.destinationName)
        XCTAssertEqual(attributes.journeyID, rig.journey.id)
    }

    // MARK: AC-2

    // 깨짐: pause에서 update를 안 보내거나, 남은 3000초 대신 다른 값을 쓰거나, endDate/staleDate를 남기면 실패한다.
    func testV15_AC2_일시정지하면_남은초를_담은_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)

        rig.controller.pause()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(rig.gateway.entries.last?.op, .update)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // MARK: AC-4

    // 깨짐: 재개 시 종료 시각을 시작 시점 기준(T+3600)으로 두거나 start를 다시 호출하면 실패한다.
    func testV15_AC4_재개하면_현재_시각_기준으로_종료시각을_다시_계산해_갱신한다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        rig.clock.advance(by: .seconds(300), notify: false)
        let t2 = rig.currentDate

        rig.controller.resume()

        XCTAssertEqual(rig.gateway.count(.update), 2)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t2.addingTimeInterval(3000))
        XCTAssertEqual(request.staleDate, t2.addingTimeInterval(3000))
    }

    // MARK: AC-5

    // 깨짐: 재개 저장이 실패했는데도 게이트웨이에 running 갱신을 보내면 실패한다.
    func testV15_AC5_재개_저장이_실패하면_게이트웨이_요청이_늘지_않는다() throws {
        let rig = try makeRig(results: [true, false])
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        let before = rig.gateway.entries.count

        rig.controller.resume()

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // MARK: AC-6

    // 깨짐: 도착 시 end를 안 보내거나 2번 보내거나, 도착 뒤 start/update가 또 나가면 실패한다.
    func testV15_AC6_도착하면_종료를_1회만_보내고_이후_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()

        rig.clock.advance(by: .seconds(3600))
        XCTAssertEqual(rig.controller.status, .arrived)
        rig.controller.returnToForeground()
        rig.controller.tick()

        XCTAssertEqual(rig.gateway.count(.end), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // MARK: AC-7

    // 깨짐: 이미 도착한 여정 진입에서 start(또는 end/update)를 보내면 실패한다.
    func testV15_AC7_도착_상태로_진입하면_어떤_요청도_보내지_않는다() throws {
        let rig = try makeRig(elapsed: 3600)

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        XCTAssertEqual(rig.gateway.count(.end), 0)
    }

    // MARK: AC-8

    // 깨짐: 일시정지 진입에서 start를 안 하거나 running 카드로 시작하거나 endDate/staleDate를 넣으면 실패한다.
    func testV15_AC8_일시정지_상태로_진입하면_정지_카드를_1회_시작한다() throws {
        let rig = try makeRig(elapsed: 600, paused: true, autoStart: false)

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.first?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // MARK: AC-9

    // 깨짐: 정지 진입 뒤 재개에서 start를 또 하거나 종료 시각을 T3+3000으로 계산하지 않으면 실패한다.
    func testV15_AC9_일시정지로_시작한_뒤_재개하면_start_없이_갱신한다() throws {
        let rig = try makeRig(elapsed: 600, paused: true, autoStart: false)
        rig.controller.appear()
        rig.clock.advance(by: .seconds(120), notify: false)
        let t3 = rig.currentDate

        rig.controller.resume()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t3.addingTimeInterval(3000))
        XCTAssertEqual(request.staleDate, t3.addingTimeInterval(3000))
    }

    // MARK: 이전 실행이 남긴 표시 정리 (AC-11~15)

    // 깨짐: 도착한 여행 화면에서 남은 표시를 안 끝내거나 2번 끝내거나 start/update를 보내면 실패한다.
    func testV15_AC11_도착한_여행_화면에_들어오면_남은_표시를_1회_끝낸다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")], elapsed: 3600
        )

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["old-1"])
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 남은 표시를 재사용하지 않고 start 하거나, 종료 시각을 현재 시각 기준으로 계산하지 않으면 실패한다.
    func testV15_AC12_진행_중_진입하면_남은_표시를_새로_만들지_않고_현재_시각_기준으로_갱신한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )
        rig.clock.advance(by: .seconds(100), notify: false)
        let t4 = rig.currentDate

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .running)
        XCTAssertEqual(request.state.endDate, t4.addingTimeInterval(TimeInterval(rig.controller.remainingSeconds)))
        XCTAssertEqual(request.staleDate, request.state.endDate)
    }

    // 깨짐: 일시정지 진입에서 남은 표시를 재사용하지 않거나 정지 카드에 endDate/staleDate를 넣으면 실패한다.
    func testV15_AC13_일시정지_진입하면_남은_표시를_정지_카드로_갱신한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")],
            elapsed: 600, paused: true, autoStart: false
        )

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 중복 표시를 정리하지 않거나 첫 표시 대신 마지막 표시를 재사용하면 실패한다.
    func testV15_AC14_같은_여행_표시가_2개면_첫째를_갱신하고_나머지를_끝낸다() throws {
        let rig = try makeRig(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "old-2", journeyID: "journey-1")
        ])

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["old-2"])
        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .update }.compactMap(\.activityID), ["old-1"])
        XCTAssertEqual(rig.gateway.count(.start), 0)
        XCTAssertEqual(rig.gateway.activeActivities.map(\.id), ["old-1"])
    }

    // 깨짐: 다른 여행의 표시를 안 끝내거나, 현재 여행 표시를 새로 시작하지 않으면 실패한다.
    func testV15_AC15_다른_여행_표시는_끝내고_현재_여행을_새로_시작한다() throws {
        let rig = try makeRig(
            existing: [LiveActivityHandle(id: "other-1", journeyID: "other-journey")]
        )

        rig.controller.appear()

        XCTAssertEqual(rig.gateway.entries.filter { $0.op == .end }.compactMap(\.activityID), ["other-1"])
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.activeActivities.count, 1)
        XCTAssertEqual(rig.gateway.activeActivities.first?.journeyID, rig.journey.id)
    }

    // MARK: 요청 억제·실패·종료 (AC-3, 16~25)

    func tickSeconds(_ rig: Rig, _ n: Int) {
        for _ in 0..<n { rig.clock.advance(by: .seconds(1), notify: true) }
    }

    // 깨짐: 일시정지 중 복귀·appear를 반복할 때마다 같은 정지 카드를 다시 보내면 실패한다.
    func testV15_AC3_일시정지_뒤_복귀와_appear를_반복해도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        rig.clock.advance(by: .seconds(300), notify: false)
        let before = rig.gateway.entries.count

        for _ in 0..<3 { rig.controller.returnToForeground() }
        for _ in 0..<3 { rig.controller.appear() }

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.controller.remainingSeconds, 3000)
    }

    // 깨짐: start 실패 때 컨트롤러 흐름이 바뀌거나 저장 기록이 달라지거나 오류 표시가 켜지면 실패한다.
    func testV15_AC16_표시_시작이_실패해도_타이머와_저장은_성공_때와_같다() throws {
        func run(failing: Bool) throws -> (Rig, [JourneyTimerController.Status]) {
            let rig = try makeRig()
            rig.gateway.failsStart = failing
            var statuses: [JourneyTimerController.Status] = []
            rig.controller.appear(); statuses.append(rig.controller.status)
            rig.controller.pause(); statuses.append(rig.controller.status)
            rig.controller.resume(); statuses.append(rig.controller.status)
            rig.clock.advance(by: .seconds(3600)); statuses.append(rig.controller.status)
            return (rig, statuses)
        }
        let (failed, failedStatuses) = try run(failing: true)
        let (normal, _) = try run(failing: false)

        XCTAssertEqual(failedStatuses, [.running, .paused, .running, .arrived])
        XCTAssertEqual(failed.saver.writes.map(\.elapsed), normal.saver.writes.map(\.elapsed))
        XCTAssertEqual(failed.saver.writes.map(\.paused), normal.saver.writes.map(\.paused))
        XCTAssertFalse(failed.controller.showsTransitionFailure)
        XCTAssertFalse(failed.controller.showsSaveWarning)
    }

    // 깨짐: start 실패 뒤 update·end나 start 재시도를 보내면 실패한다.
    func testV15_AC17_표시_시작이_실패하면_그_세션에서_더_이상_요청하지_않는다() throws {
        let rig = try makeRig()
        rig.gateway.failsStart = true

        rig.controller.appear()
        rig.controller.pause()
        rig.controller.resume()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(3600))

        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
        XCTAssertEqual(rig.gateway.count(.end), 0)
    }

    // 깨짐: 상태 변화 없는 tick·복귀·appear마다 같은 내용의 갱신을 보내면 실패한다.
    func testV15_AC18_상태가_그대로면_tick과_복귀와_appear를_반복해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        let before = rig.gateway.entries.count

        tickSeconds(rig, 10)
        for _ in 0..<3 { rig.controller.returnToForeground() }
        for _ in 0..<3 { rig.controller.appear() }

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 체크포인트 저장 성공마다 갱신을 보내면 실패한다.
    func testV15_AC19_체크포인트_저장이_성공해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()

        tickSeconds(rig, 180)

        XCTAssertGreaterThanOrEqual(rig.saver.writes.count, 3)
        XCTAssertEqual(rig.gateway.entries.count, 1)
    }

    // 깨짐: 저장 실패로 멈춘 뒤 정지 카드 갱신이 없거나 남은 초가 다르거나 endDate/staleDate가 남으면 실패한다.
    func testV15_AC20_체크포인트_저장이_실패해_멈추면_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig(elapsed: 120, results: [false])
        rig.controller.appear()

        var guardCount = 0
        while !rig.controller.showsSaveWarning && guardCount < 200 {
            tickSeconds(rig, 1)
            guardCount += 1
        }

        XCTAssertTrue(rig.controller.showsSaveWarning)
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.gateway.count(.update), 1)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, rig.controller.remainingSeconds)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 백그라운드 진입 저장 성공이 요청을 보내면 실패한다.
    func testV15_AC21_백그라운드_진입_저장이_성공해도_요청이_늘지_않는다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        let before = rig.gateway.entries.count

        rig.controller.enterBackground()

        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // 깨짐: running 요청의 staleDate가 endDate와 다르거나 paused 요청에 staleDate가 있으면 실패한다.
    func testV15_AC22_모든_기록에서_running은_staleDate가_endDate이고_paused는_nil이다() throws {
        var rigs: [Rig] = []
        let r1 = try makeRig(); r1.controller.appear(); rigs.append(r1)
        let r4 = try makeRig(); r4.controller.appear()
        r4.clock.advance(by: .seconds(600), notify: false); r4.controller.pause()
        r4.clock.advance(by: .seconds(300), notify: false); r4.controller.resume(); rigs.append(r4)
        let r8 = try makeRig(elapsed: 600, paused: true, autoStart: false); r8.controller.appear(); rigs.append(r8)
        let r12 = try makeRig(existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")])
        r12.clock.advance(by: .seconds(100), notify: false); r12.controller.appear(); rigs.append(r12)
        let r13 = try makeRig(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")],
            elapsed: 600, paused: true, autoStart: false
        ); r13.controller.appear(); rigs.append(r13)
        let r20 = try makeRig(elapsed: 120, results: [false]); r20.controller.appear()
        var n = 0
        while !r20.controller.showsSaveWarning && n < 200 { tickSeconds(r20, 1); n += 1 }
        rigs.append(r20)

        var checked = 0
        for rig in rigs {
            for entry in rig.gateway.entries {
                guard let request = entry.request else { continue }
                checked += 1
                switch request.state.status {
                case .running: XCTAssertEqual(request.staleDate, request.state.endDate)
                case .paused: XCTAssertNil(request.staleDate)
                default: break
                }
            }
        }
        // 깨짐: 기록 수가 9가 아니면(누락·중복) 실패 — r1 1 + r4 3 + r8 1 + r12 1 + r13 1 + r20 2
        XCTAssertEqual(checked, 9)
    }

    // 깨짐: 총 시간 초과 뒤 복귀·appear 반복에서 end를 여러 번 보내거나 안 보내면 실패한다.
    func testV15_AC23_백그라운드_중_총시간을_넘기면_복귀_뒤_end가_총_1회다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.controller.enterBackground()
        rig.clock.armForegroundAdvance(by: .seconds(3700))
        rig.clock.applyArmedForegroundAdvance()

        rig.controller.returnToForeground()
        rig.controller.appear()
        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.gateway.count(.end), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.update), 0)
    }

    // 깨짐: 화면을 떠날 때 정지 카드 갱신이 없거나 남은 초(2700)·endDate/staleDate가 틀리거나 end를 보내면 실패한다.
    func testV15_AC24_진행_중_화면을_떠나면_정지_카드로_1회_갱신한다() throws {
        let rig = try makeRig(elapsed: 900)
        rig.controller.appear()

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.count(.update), 1)
        XCTAssertEqual(rig.gateway.count(.start), 1)
        XCTAssertEqual(rig.gateway.count(.end), 0)
        let request = try XCTUnwrap(rig.gateway.entries.last?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 2700)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 이미 정지된 상태에서 떠날 때 같은 정지 카드를 또 보내면 실패한다.
    func testV15_AC25a_일시정지_상태에서_떠나도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.pause()
        let before = rig.gateway.entries.count

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.entries.count, before)
    }

    // 깨짐: 도착으로 표시가 끝난 뒤 떠날 때 요청을 더 보내면 실패한다.
    func testV15_AC25b_도착해_표시가_끝난_뒤_떠나도_추가_요청이_없다() throws {
        let rig = try makeRig()
        rig.controller.appear()
        rig.clock.advance(by: .seconds(3600))
        let before = rig.gateway.entries.count

        rig.controller.leave()

        XCTAssertEqual(rig.gateway.entries.count, before)
        XCTAssertEqual(rig.gateway.count(.end), 1)
    }
}

```

### ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 앱 시작 때 저장 상태 기준으로 이전 실행이 남긴 표시를 맞추는 동작을 게이트웨이 결과로 검증한다.
@MainActor
final class JourneyLiveActivityCleanupTests: XCTestCase {
    func endIDs(_ gateway: RecordingLiveActivityGateway) -> [String] {
        gateway.entries.filter { $0.op == .end }.compactMap(\.activityID)
    }

    func updateIDs(_ gateway: RecordingLiveActivityGateway) -> [String] {
        gateway.entries.filter { $0.op == .update }.compactMap(\.activityID)
    }

    // 깨짐: 저장 여행이 없는데 남은 표시를 끝내지 않거나 새로 start/update 하면 실패한다.
    func testV15_AC10_저장된_여행이_없으면_남은_표시를_끝낸다() {
        let gateway = RecordingLiveActivityGateway(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: nil)

        XCTAssertEqual(endIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
    }

    // 깨짐: 도착한 여행의 남은 표시를 끝내지 않거나 2번 끝내거나 update 하면 실패한다.
    func testV15_AC11_저장된_여행이_도착_상태면_남은_표시를_1회_끝낸다() {
        let gateway = RecordingLiveActivityGateway(
            existing: [LiveActivityHandle(id: "old-1", journeyID: "journey-1")]
        )
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 3600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
    }

    // 깨짐: 다른 여행 표시를 안 끝내거나, 같은 여행 표시를 정지 카드(3000초, endDate/staleDate nil)로 갱신하지 않으면 실패한다.
    func testV15_AC32_출발_뒤_진행_중이면_다른_여행은_끝내고_같은_여행은_일시정지로_갱신한다() throws {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "other-1", journeyID: "other-journey")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["other-1"])
        XCTAssertEqual(updateIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        let request = try XCTUnwrap(gateway.entries.first { $0.op == .update }?.request)
        XCTAssertEqual(request.state.status, .paused)
        XCTAssertEqual(request.state.pausedRemainingSeconds, 3000)
        XCTAssertNil(request.state.endDate)
        XCTAssertNil(request.staleDate)
    }

    // 깨짐: 중복 표시를 정리하지 않거나 첫 표시 대신 마지막 표시를 남기면 실패한다.
    func testV15_AC33_같은_여행_표시가_2개면_첫째만_일시정지로_남기고_나머지를_끝낸다() {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "old-2", journeyID: "journey-1")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(endIDs(gateway), ["old-2"])
        XCTAssertEqual(updateIDs(gateway), ["old-1"])
        XCTAssertEqual(gateway.activeActivities.map(\.id), ["old-1"])
    }

    // 깨짐: 남은 표시가 없는데 start/update/end 중 하나라도 보내면 실패한다.
    func testV15_AC34_남은_표시가_없으면_어떤_요청도_보내지_않는다() {
        let gateway = RecordingLiveActivityGateway()
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(gateway.entries.count, 0)
    }

    // 깨짐: 미출발 여행인데 남은 표시를 일부라도 남기거나 start 하면 실패한다.
    func testV15_AC32b_미출발_여행이면_남은_표시를_전부_끝낸다() {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1"),
            LiveActivityHandle(id: "other-1", journeyID: "other-journey")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .awaitingDeparture)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        XCTAssertEqual(Set(endIDs(gateway)), ["old-1", "other-1"])
        XCTAssertEqual(gateway.count(.start), 0)
        XCTAssertEqual(gateway.count(.update), 0)
        XCTAssertEqual(gateway.activeActivities.count, 0)
    }
    // 깨짐: 재실행 정리의 일시정지 갱신에서 저장 여정의 총 시간을 누락한다.
    func testW17_재실행_정리는_기존활동에_총3600초를_보강한다() throws {
        let gateway = RecordingLiveActivityGateway(existing: [
            LiveActivityHandle(id: "old-1", journeyID: "journey-1")
        ])
        let journey = BoardingFixtures.journey(minutes: 60, phase: .departed, elapsedSeconds: 600)

        JourneyLiveActivityCleanup.atLaunch(gateway: gateway, journey: journey)

        let request = try XCTUnwrap(gateway.entries.first { $0.op == .update }?.request)
        let data = try JSONEncoder().encode(request.state)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["totalSeconds"] as? Int, 3600)
    }

}

```

### ios/FocusMateTests/JourneyActivityContentStateCodableTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class JourneyActivityContentStateCodableTests: XCTestCase {
    private func roundTrip(_ json: String) throws -> [String: Any] {
        let state = try JSONDecoder().decode(
            JourneyActivityAttributes.ContentState.self, from: Data(json.utf8)
        )
        let data = try JSONEncoder().encode(state)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // 깨짐: 실행 상태의 총 시간을 디코딩 또는 인코딩 중 버린다.
    func testW17_실행_JSON왕복은_총1800초를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"running","endDate":813576522,"totalSeconds":1800}"#
        )

        XCTAssertEqual(object["totalSeconds"] as? Int, 1800)
        XCTAssertEqual(object["status"] as? String, "running")
    }

    // 깨짐: 일시정지 상태의 총 시간을 누락하거나 고정 잔여로 대체한다.
    func testW17_일시정지_JSON왕복은_총3600초를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"paused","pausedRemainingSeconds":1122,"totalSeconds":3600}"#
        )

        XCTAssertEqual(object["totalSeconds"] as? Int, 3600)
        XCTAssertEqual(object["pausedRemainingSeconds"] as? Int, 1122)
    }

    // 깨짐: 총 시간이 없는 이전 실행 상태를 복원하지 못하거나 임의 총 시간을 만든다.
    func testW17_legacy_총시간누락_JSON은_시간과_상태를_보존한다() throws {
        let object = try roundTrip(#"{"status":"running","endDate":813576522}"#)

        XCTAssertEqual(object["status"] as? String, "running")
        XCTAssertEqual(object["endDate"] as? Double, 813576522)
        XCTAssertTrue(object["totalSeconds"] == nil || object["totalSeconds"] is NSNull)
    }

    // 깨짐: 명시적 null 총 시간의 이전 정지 상태를 거절하거나 잔여 시간을 잃는다.
    func testW17_legacy_총시간null_JSON은_정지잔여를_보존한다() throws {
        let object = try roundTrip(
            #"{"status":"paused","pausedRemainingSeconds":1122,"totalSeconds":null}"#
        )

        XCTAssertEqual(object["status"] as? String, "paused")
        XCTAssertEqual(object["pausedRemainingSeconds"] as? Int, 1122)
        XCTAssertTrue(object["totalSeconds"] == nil || object["totalSeconds"] is NSNull)
    }
}

```

## 부모 직접 실행 증거
전용 시뮬레이터에서 위 focused 명령 exit65. 60건 중 신규 assertion 실패8건, 호환 포함52건 통과. 컴파일 오류0. 로그: t1-red-run.log. 생산 파일 열람 없는 RED 확인.
