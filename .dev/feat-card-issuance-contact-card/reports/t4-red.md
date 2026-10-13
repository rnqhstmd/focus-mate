# t4-red

케이스: IssuanceHapticPatternTests 4, CardIssuanceControllerTests 13 (총 17)
명령: python3 scripts/check-ios.py test ios/FocusMateTests/IssuanceHapticPatternTests.swift ios/FocusMateTests/CardIssuanceControllerTests.swift
실패(전 케이스 공통): 빌드 실패 - Cannot find type 'IssuanceHaptics' / 'IssuanceHapticPattern' / 'AccessibilityAnnouncing' / 'CardIssuing' in scope (프로덕션 타입 미정의)
참조: design.md(7,8,13,Testability), CardTestSupport.swift, CardIssuanceModelTests.swift

## CardIssuanceTestDoubles.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 가짜 객체들이 공유하는 호출 순서 기록.
final class EventLog {
    private(set) var events: [String] = []
    func record(_ event: String) { events.append(event) }
}

@MainActor
final class FakeIssuanceHaptics: IssuanceHaptics {
    let isSupported: Bool
    private(set) var patterns: [IssuanceHapticPattern] = []
    var onPlay: (() -> Void)?
    private let log: EventLog?

    init(isSupported: Bool, log: EventLog? = nil) {
        self.isSupported = isSupported
        self.log = log
    }

    func play(_ pattern: IssuanceHapticPattern) {
        patterns.append(pattern)
        log?.record("play")
        onPlay?()
    }
}

@MainActor
final class RecordingAnnouncer: AccessibilityAnnouncing {
    private(set) var messages: [String] = []
    func announce(_ message: String) { messages.append(message) }
}

@MainActor
final class FakeCardIssuer: CardIssuing {
    private var results: [Bool]
    private(set) var issueCalls = 0
    private(set) var finishCalls = 0
    private let log: EventLog?

    init(results: [Bool], log: EventLog? = nil) {
        self.results = results
        self.log = log
    }

    func issueCard() -> Bool {
        issueCalls += 1
        log?.record("issueCard")
        return results.isEmpty ? true : results.removeFirst()
    }

    func finishCardIssuance() {
        finishCalls += 1
        log?.record("finish")
    }
}

/// sleep 진입을 기록하고, resume 될 때까지 멈춰 있는다.
@MainActor
final class SuspendingSleep {
    private(set) var requested: [Duration] = []
    private var continuation: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    func sleep(_ duration: Duration) async {
        requested.append(duration)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            continuation = c
            waiter?.resume()
            waiter = nil
        }
    }

    func untilSuspended() async {
        if continuation != nil { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            waiter = c
        }
    }

    func resume() {
        guard let c = continuation else {
            XCTFail("resume 할 sleep 이 없다")
            return
        }
        continuation = nil
        c.resume()
    }
}
```

## IssuanceHapticPatternTests.swift
```swift
import CoreHaptics
import XCTest
@testable import FocusMate

final class IssuanceHapticPatternTests: XCTestCase {
    // 깨짐 명명: 곡선이 내려가거나 평평하게 바뀌면(시작 >= 끝) 실패.
    func testAC17_세기_곡선은_약하게_시작해_강하게_끝난다() throws {
        let curve = IssuanceHapticPattern.issuance.intensityCurve
        let first = try XCTUnwrap(curve.first)
        let last = try XCTUnwrap(curve.last)

        XCTAssertLessThan(first.intensity, last.intensity)
    }

    // 깨짐 명명: 끝 탭이 없거나 2개 이상이거나 패턴 끝과 다른 시간에 있으면 실패.
    func testAC17_끝_탭은_하나이고_패턴_끝에_있다() throws {
        let pattern = IssuanceHapticPattern.issuance

        XCTAssertEqual(pattern.taps.count, 1)
        XCTAssertEqual(try XCTUnwrap(pattern.taps.first).time, pattern.duration)
    }

    // 깨짐 명명: 패턴 길이가 0.9 가 아니거나 CardIssuanceTiming.hapticDuration 과 어긋나면 실패.
    func testAC17_패턴_길이는_0점9초이고_타이밍_상수와_같다() {
        XCTAssertEqual(IssuanceHapticPattern.issuance.duration, 0.9, accuracy: 0.0001)
        XCTAssertEqual(CardIssuanceTiming.hapticDuration, 0.9, accuracy: 0.0001)
        XCTAssertEqual(IssuanceHapticPattern.issuance.duration, CardIssuanceTiming.hapticDuration, accuracy: 0.0001)
    }

    // 깨짐 명명: 제어점이나 파라미터가 CoreHaptics 가 거부하는 값이면 실패.
    func testAC17_CoreHaptics_패턴으로_변환해도_던지지_않는다() {
        XCTAssertNoThrow(try IssuanceHapticPattern.issuance.makeCHHapticPattern())
    }
}
```

## CardIssuanceControllerTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class CardIssuanceControllerTests: XCTestCase {
    private struct Rig {
        let controller: CardIssuanceController
        let issuer: FakeCardIssuer
        let haptics: FakeIssuanceHaptics
        let announcer: RecordingAnnouncer
        let sleeper: SuspendingSleep
        let log: EventLog
    }

    private func rig(results: [Bool] = [true], supported: Bool = true, standard: Duration? = .milliseconds(900)) -> Rig {
        let log = EventLog()
        let issuer = FakeCardIssuer(results: results, log: log)
        let haptics = FakeIssuanceHaptics(isSupported: supported, log: log)
        let announcer = RecordingAnnouncer()
        let sleeper = SuspendingSleep()
        let controller: CardIssuanceController
        if let standard {
            controller = CardIssuanceController(
                issuer: issuer, haptics: haptics, announcer: announcer,
                standardDuration: standard, sleep: { await sleeper.sleep($0) })
        } else {
            controller = CardIssuanceController(
                issuer: issuer, haptics: haptics, announcer: announcer,
                sleep: { await sleeper.sleep($0) })
        }
        return Rig(controller: controller, issuer: issuer, haptics: haptics, announcer: announcer, sleeper: sleeper, log: log)
    }

    // 깨짐 명명: phase 가드가 없어 발급 중 재호출이 issueCard 를 또 부르거나 true 를 돌려주면 실패.
    func testAC5_발급_중_연타는_모두_거절되고_발급은_한_번만_한다() async {
        let r = rig()
        let first = Task { await r.controller.issue(reduceMotion: false) }
        await r.sleeper.untilSuspended()

        let second = await r.controller.issue(reduceMotion: false)
        let third = await r.controller.issue(reduceMotion: false)

        XCTAssertFalse(second)
        XCTAssertFalse(third)
        XCTAssertEqual(r.issuer.issueCalls, 1)
        XCTAssertEqual(r.controller.phase, .issuing)

        r.sleeper.resume()
        let firstResult = await first.value
        XCTAssertTrue(firstResult)
        XCTAssertEqual(r.controller.phase, .issued)
    }

    // 깨짐 명명: 햅틱을 저장 전에 재생하거나, 패턴이 .issuance 가 아니거나, 2회 이상 재생하면 실패.
    func testAC17_지원_기기는_저장_성공_뒤에_발급_패턴을_한_번_재생한다() async {
        let r = rig()
        let task = Task { await r.controller.issue(reduceMotion: false) }
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        _ = await task.value

        XCTAssertEqual(r.haptics.patterns, [IssuanceHapticPattern.issuance])
        XCTAssertEqual(r.log.events, ["issueCard", "play"])
    }

    // 깨짐 명명: isSupported 를 보지 않고 재생하거나, 미지원일 때 결과/phase 가 달라지면 실패.
    func testAC17_미지원_기기는_재생_없이_발급이_성공한다() async {
        let r = rig(supported: false)
        let task = Task { await r.controller.issue(reduceMotion: false) }
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        let result = await task.value

        XCTAssertTrue(result)
        XCTAssertEqual(r.haptics.patterns.count, 0)
        XCTAssertEqual(r.controller.phase, .issued)
    }

    // 깨짐 명명: 저장 실패인데 햅틱을 재생하거나 phase 가 .failed 가 아니면 실패.
    func testAC17_저장_실패는_재생_없이_failed가_된다() async {
        let r = rig(results: [false])

        let result = await r.controller.issue(reduceMotion: false)

        XCTAssertFalse(result)
        XCTAssertEqual(r.haptics.patterns.count, 0)
        XCTAssertEqual(r.controller.phase, .failed)
    }

    // 깨짐 명명: 상한 상수(900ms)를 넘기거나 0 이하이거나 sleep 을 두 번 이상 부르면 실패.
    func testAC18_동작_줄이기_꺼짐은_0점9초_이하로_한_번_기다린다() async throws {
        let r = rig(standard: nil)
        let task = Task { await r.controller.issue(reduceMotion: false) }
        await r.sleeper.untilSuspended()

        XCTAssertEqual(r.sleeper.requested.count, 1)
        let d = try XCTUnwrap(r.sleeper.requested.first)
        XCTAssertGreaterThan(d, Duration.zero)
        XCTAssertLessThanOrEqual(d, Duration.milliseconds(900))

        r.sleeper.resume()
        let result = await task.value
        XCTAssertTrue(result)
        XCTAssertEqual(r.controller.phase, .issued)
        XCTAssertEqual(r.haptics.patterns.count, 1)
    }

    // 깨짐 명명: 동작 줄이기가 켜졌는데 sleep 을 부르거나 햅틱을 빼먹으면 실패 (sleep 이 걸리면 이 await 가 멈춰 테스트가 실패한다).
    func testAC18_동작_줄이기_켜짐은_기다리지_않고_바로_완료한다() async {
        let r = rig()

        let result = await r.controller.issue(reduceMotion: true)

        XCTAssertTrue(result)
        XCTAssertEqual(r.sleeper.requested, [])
        XCTAssertEqual(r.controller.phase, .issued)
        XCTAssertEqual(r.haptics.patterns.count, 1)
    }

    // 깨짐 명명: 두 분기가 뒤바뀌거나 standard 를 무시하면 실패.
    func testAC18_holdDuration은_켜짐이면_0_꺼짐이면_표준값이다() {
        XCTAssertEqual(CardIssuanceController.holdDuration(reduceMotion: true, standard: .milliseconds(700)), .zero)
        XCTAssertEqual(CardIssuanceController.holdDuration(reduceMotion: false, standard: .milliseconds(700)), .milliseconds(700))
    }

    // 깨짐 명명: 안내 문구/순서가 다르거나 포커스를 주지 않으면 실패.
    func testAC19_성공하면_안내_두_건을_내고_계속_버튼에_포커스를_준다() async {
        let r = rig()

        _ = await r.controller.issue(reduceMotion: true)

        XCTAssertEqual(r.announcer.messages, ["카드를 발급하고 있어요.", "카드가 발급됐어요. 출발지를 선택해보세요."])
        XCTAssertEqual(r.controller.focusTarget, .continueButton)
    }

    // 깨짐 명명: 실패 문구가 다르거나 실패인데 포커스를 옮기면 실패.
    func testAC19_실패하면_실패_안내를_내고_포커스는_없다() async {
        let r = rig(results: [false])

        _ = await r.controller.issue(reduceMotion: true)

        XCTAssertEqual(r.announcer.messages, ["카드를 발급하고 있어요.", "카드를 발급하지 못했어요. 다시 시도해 주세요."])
        XCTAssertNil(r.controller.focusTarget)
    }

    // 깨짐 명명: failed 에서 재시도를 막으면 실패.
    func testAC19_실패_뒤에는_다시_발급할_수_있다() async {
        let r = rig(results: [false, true])
        _ = await r.controller.issue(reduceMotion: true)

        let retry = await r.controller.issue(reduceMotion: true)

        XCTAssertTrue(retry)
        XCTAssertEqual(r.issuer.issueCalls, 2)
        XCTAssertEqual(r.controller.phase, .issued)
    }

    // 깨짐 명명: ready/failed 에서 finishCardIssuance 를 부르면 실패.
    func testProceed_발급_전과_실패_상태에서는_모델을_건드리지_않는다() async {
        let r = rig(results: [false])
        r.controller.proceed()
        _ = await r.controller.issue(reduceMotion: true)
        r.controller.proceed()

        XCTAssertEqual(r.issuer.finishCalls, 0)
    }

    // 깨짐 명명: issued 에서 finishCardIssuance 를 부르지 않으면 실패.
    func testProceed_발급_완료_상태에서는_모델에_완료를_알린다() async {
        let r = rig()
        _ = await r.controller.issue(reduceMotion: true)

        r.controller.proceed()

        XCTAssertEqual(r.issuer.finishCalls, 1)
    }

    // 깨짐 명명: 컨트롤러가 저장 전에 햅틱을 재생하면 재생 시점의 카드 수가 0 이라 실패.
    func testIntegration_실제_AppModel_저장_뒤에_햅틱이_재생된다() async {
        let fake = memoryStore(initial: nil)
        let random = SequenceRandom([12_345_678])
        let model = AppModel(
            store: fake.store,
            cardFactory: CardSnapshotFactory(randomNumber: { random.next() }, now: { Date(timeIntervalSince1970: 1_791_882_000) }))
        model.start()
        let haptics = FakeIssuanceHaptics(isSupported: true)
        var countsAtPlay: [Int] = []
        haptics.onPlay = { countsAtPlay.append(model.snapshot?.cards.items.count ?? -1) }
        let controller = CardIssuanceController(
            issuer: model, haptics: haptics, announcer: RecordingAnnouncer(), sleep: { _ in })

        let result = await controller.issue(reduceMotion: false)

        XCTAssertTrue(result)
        XCTAssertEqual(model.snapshot?.cards.items.count, 1)
        XCTAssertEqual(countsAtPlay, [1])
    }
}
```
