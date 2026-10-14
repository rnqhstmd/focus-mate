# T2 RED no-overlap 강화

Status: DONE_WITH_CONCERNS — 테스트 작성 완료, 실행·변이 검증은 부모 담당으로 미실행.

## 깨짐 명명

이전 player의 중지 완료를 기다리는 barrier를 제거하면 새 player가 이전 player의 중지 gate가 열린 뒤에만 재생해야 한다는 계약을 위반한다. 직접 선택 변경(AC18)과 동일 controller close/reopen(AC22)의 기존 두 케이스가 이를 관찰한다. 이는 설계의 최대 한 개 재생 계약에 대한 선언적 변이이며 실제 구현을 조회하지 않았다.

## 변경

- 기존 두 테스트의 이름 및 개수 유지. 추가 케이스 없음; T2 총 25개 유지 대상.
- `assertNoOverlap`에서 A의 주입 sleep gate를 계속 잡은 채 B factory 도착을 기다리고 B 후보 player를 반환한다.
- B.play를 inverted expectation으로 0.1초의 bounded fulfillment 구간에 관찰한다. 고정 sleep/yield 없음.
- gate가 여전히 잡힌 시점에 A.stop 0 / B.play 0도 확인한다.
- 관찰 종료 후 fake의 observer를 제거하고 A gate를 해제한다. A.stop 및 B 요청 완료 후 이벤트 순서 A.stop < B.play 확인과 종료 정리를 유지한다.
- 테스트 fake에 선택적 play expectation observer만 추가. 공개 설계의 player.play 경계에서 호출을 관찰한다. 제품 API 추가 없음.

변경 위치: `ios/FocusMateTests/SoundPreviewControllerTests.swift` helper 시작 138행, fake observer 274행.

## 실행 근거

지시대로 테스트를 실행하지 않았다. 실패 메시지·native 통과·변이 실패 결과는 아직 없다. 부모가 통제된 barrier 대기 제거 변이에서 두 케이스 실패를 확인하고 정확한 제품 원본 복구 후 전체 67개 통과를 확인할 예정이다. 본 보고서는 그 결과를 선취하지 않는다.

## 참조한 파일 (전부)

- `ios/FocusMateTests/SoundPreviewControllerTests.swift` (기존 테스트 코드)
- `.dev/codex-feat-preparation-tags-sound/design.md` (controller/player API, no-overlap, close/reopen, continuation gate 계약)
- `.dev/codex-feat-preparation-tags-sound/prd.md` (AC18/22, BR8/9)
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md`

프로덕션 read/search/edit 및 구현 report/diff 조회 없음.

## 강화 후 테스트 코드 전문

```swift
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class SoundPreviewControllerTests: XCTestCase {
    private struct Rig {
        let controller: SoundPreviewController
        let factory: PreviewFactoryGate
        let sleeper: PreviewSleepGate
        let log: PreviewEventLog
    }
    private func rig(sound: JourneySound = .bus) -> Rig {
        let log = PreviewEventLog()
        let factory = PreviewFactoryGate()
        let sleeper = PreviewSleepGate()
        return Rig(controller: SoundPreviewController(sound: sound,
            makePlayer: { try await factory.make($0) }, sleep: { await sleeper.sleep($0) }),
            factory: factory, sleeper: sleeper, log: log)
    }
    private func start(_ r: Rig, player: PreviewPlayer, index: Int = 0) async -> Task<Void, Never> {
        let task = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(index)], timeout: 1)
        r.factory.resolve(index, .success(player))
        await task.value
        return task
    }
    private func finishStop(_ r: Rig, player: PreviewPlayer) async {
        await fulfillment(of: [r.sleeper.arrival], timeout: 1)
        r.sleeper.releaseAll()
        await fulfillment(of: [player.stopped], timeout: 1)
    }

    // 깨짐: 시트 진입이 player를 만들거나 임시 선택을 확정값으로 초기화하지 않는다.
    func testAC14_beginSelection은_확정소리로_열고_재생을_시작하지_않는다() {
        let r = rig()
        let model = AppModel(store: memoryStore(initial: nil).store, soundPreview: r.controller)
        XCTAssertTrue(model.soundPreview === r.controller)
        r.controller.beginSelection(sound: .rainBus)
        XCTAssertEqual(r.controller.selectedSound, .rainBus)
        XCTAssertEqual(r.controller.phase, .stopped)
        XCTAssertNil(r.controller.errorMessage)
        XCTAssertEqual(r.factory.sounds, [])
    }
    // 깨짐: 선택 이벤트가 factory를 호출하여 자동 재생한다.
    func testAC14_소리_선택만으로는_factory를_호출하지_않는다() {
        let r = rig()
        r.controller.chooseSound(.forest)
        XCTAssertEqual(r.controller.selectedSound, .forest)
        XCTAssertEqual(r.factory.sounds, [])
    }
    // 깨짐: 취소한 임시 선택이 다음 시트의 선택으로 남는다.
    func testAC15_취소후_재진입은_이전_확정소리로_임시선택을_되돌린다() {
        let r = rig()
        r.controller.chooseSound(.forest)
        r.controller.stopPreview()
        r.controller.beginSelection(sound: .bus)
        XCTAssertEqual(r.controller.selectedSound, .bus)
        XCTAssertEqual(r.factory.sounds, [])
    }
    // 깨짐: 저장한 선택이 PreparationDraft에 반영되지 않거나 재진입에 초기값이 사용된다.
    func testAC16_저장한_임시소리가_초안과_다음_선택에_반영된다() {
        let r = rig()
        var draft = PreparationDraft()
        r.controller.chooseSound(.rainBus)
        draft.setSound(r.controller.selectedSound)
        r.controller.stopPreview()
        r.controller.beginSelection(sound: draft.sound)
        XCTAssertEqual(draft.sound, .rainBus)
        XCTAssertEqual(r.controller.selectedSound, .rainBus)
        XCTAssertEqual(r.factory.sounds, [])
    }
    // 깨짐: 샘플 분기가 누락되거나 volume/loop/prepare/play/fade 순서와 시작 fade가 틀린다.
    func testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다() async {
        for sound in [JourneySound.bus, .rainBus, .subway, .forest] {
            let r = rig(sound: sound)
            let p = PreviewPlayer("A", log: r.log)
            _ = await start(r, player: p)
            XCTAssertEqual(r.factory.sounds, [sound], "\(sound)")
            XCTAssertEqual(r.controller.phase, .playing, "\(sound)")
            XCTAssertEqual(r.log.events, ["A.volume=0.0", "A.loops=-1", "A.prepare", "A.play", "A.fade=1.0:0.12"], "\(sound)")
            r.controller.stopPreview()
            await finishStop(r, player: p)
        }
    }
    // 깨짐: loading이 누락되거나 factory 완료 전에 playing으로 바뀐다.
    func testAC17_factory_완료전에는_loading이다() async {
        let r = rig(); let p = PreviewPlayer("A", log: r.log)
        let task = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(0)], timeout: 1)
        XCTAssertEqual(r.controller.phase, .loading)
        XCTAssertEqual(p.playCalls, 0)
        r.factory.resolve(0, .success(p)); await task.value
        r.controller.stopPreview(); await finishStop(r, player: p)
    }
    // 깨짐: 중지 fade가 생략되거나 60ms가 지나기 전에 stop한다.
    func testAC18_다시누르면_60ms페이드_완료후_중지한다() async {
        let r = rig(); let p = PreviewPlayer("A", log: r.log)
        _ = await start(r, player: p)
        await r.controller.togglePreview()
        await fulfillment(of: [r.sleeper.arrival], timeout: 1)
        XCTAssertEqual(r.controller.phase, .stopped)
        XCTAssertEqual(r.sleeper.durations, [.milliseconds(60)])
        XCTAssertEqual(r.log.events.last, "A.fade=0.0:0.06")
        XCTAssertEqual(p.stopCalls, 0)
        r.sleeper.releaseAll(); await fulfillment(of: [p.stopped], timeout: 1)
        XCTAssertEqual(p.stopCalls, 1)
    }
    // 깨짐: 선택 변경이 기존 재생을 끄지 않거나 새 소리를 자동 재생한다.
    func testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다() async {
        let r = rig(); let p = PreviewPlayer("A", log: r.log)
        _ = await start(r, player: p)
        r.controller.chooseSound(.forest)
        XCTAssertEqual(r.controller.selectedSound, .forest)
        XCTAssertEqual(r.controller.phase, .stopped)
        await finishStop(r, player: p)
        XCTAssertEqual(r.factory.sounds, [.bus])
        XCTAssertEqual(p.playCalls, 1)
    }
    // 깨짐: 여러 stop이 같은 player의 종료 task를 취소하거나 fade/stop을 중복한다.
    func testAC18_연속중지는_페이드와_stop을_각각_한번만_한다() async {
        let r = rig(); let p = PreviewPlayer("A", log: r.log)
        _ = await start(r, player: p)
        r.controller.stopPreview(); r.controller.stopPreview(); r.controller.stopPreview()
        await finishStop(r, player: p)
        XCTAssertEqual(r.log.events.filter { $0 == "A.fade=0.0:0.06" }.count, 1)
        XCTAssertEqual(p.stopCalls, 1)
        XCTAssertEqual(r.sleeper.durations, [.milliseconds(60)])
    }
    // 깨짐: 새 preview가 이전 player.stop보다 먼저 play하여 소리가 겹친다.
    func testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다() async {
        await assertNoOverlap(reopen: false)
    }
    // 깨짐: close/reopen의 beginSelection이 종료 task를 잃어버려 소리가 겹친다.
    func testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다() async {
        await assertNoOverlap(reopen: true)
    }
    private func assertNoOverlap(reopen: Bool) async {
        let r = rig(); let a = PreviewPlayer("A", log: r.log); let b = PreviewPlayer("B", log: r.log)
        _ = await start(r, player: a)
        r.controller.stopPreview()
        await fulfillment(of: [r.sleeper.arrival], timeout: 1)
        if reopen { r.controller.beginSelection(sound: .forest) } else { r.controller.chooseSound(.forest) }
        let prematurePlay = expectation(description: "B must not play while A stop gate is held")
        prematurePlay.isInverted = true
        b.playObservation = prematurePlay
        let task = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(1)], timeout: 1)
        r.factory.resolve(1, .success(b))
        await fulfillment(of: [prematurePlay], timeout: 0.1)
        XCTAssertEqual(a.stopCalls, 0); XCTAssertEqual(b.playCalls, 0)
        b.playObservation = nil
        r.sleeper.releaseAll()
        await fulfillment(of: [a.stopped], timeout: 1)
        await task.value
        XCTAssertEqual(r.controller.phase, .playing)
        let events = r.log.events
        XCTAssertLessThan(events.firstIndex(of: "A.stop") ?? Int.max, events.firstIndex(of: "B.play") ?? -1)
        r.controller.stopPreview(); await finishStop(r, player: b)
    }
    // 깨짐: none 요청이 factory를 호출하거나 저장값을 bus로 돌린다.
    func testAC19_none은_재생요청이_없고_초안에_저장된다() async {
        let r = rig(sound: .none)
        await r.controller.togglePreview()
        var draft = PreparationDraft(); draft.setSound(r.controller.selectedSound)
        XCTAssertEqual(r.factory.sounds, [])
        XCTAssertEqual(r.controller.phase, .stopped)
        XCTAssertEqual(draft.sound, JourneySound.none)
    }
    // 깨짐: factory throw를 성공으로 처리하거나 선택을 none으로 바꾼다.
    func testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다() async {
        let r = rig(sound: .rainBus)
        let task = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(0)], timeout: 1)
        r.factory.resolve(0, .failure(PreviewFailure.unavailable)); await task.value
        XCTAssertEqual(r.controller.phase, .stopped); XCTAssertNotNil(r.controller.errorMessage)
        XCTAssertEqual(r.controller.selectedSound, .rainBus)
        var draft = PreparationDraft(); draft.setSound(r.controller.selectedSound)
        XCTAssertEqual(draft.sound, .rainBus)
    }
    // 깨짐: prepare false 뒤 play를 호출한다.
    func testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다() async {
        await assertPlayerFailure(prepare: false, play: true)
    }
    // 깨짐: play false 뒤 playing/fade-in으로 전이한다.
    func testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다() async {
        await assertPlayerFailure(prepare: true, play: false)
    }
    private func assertPlayerFailure(prepare: Bool, play: Bool) async {
        let r = rig(sound: .subway); let p = PreviewPlayer("A", log: r.log, prepare: prepare, play: play)
        _ = await start(r, player: p)
        XCTAssertEqual(r.controller.phase, .stopped); XCTAssertNotNil(r.controller.errorMessage)
        XCTAssertEqual(r.controller.selectedSound, .subway)
        XCTAssertEqual(p.playCalls, prepare ? 1 : 0)
        XCTAssertFalse(r.log.events.contains("A.fade=1.0:0.12"))
        XCTAssertEqual(p.stopCalls, 1)
    }
    // 깨짐: loading 중 재입력이 취소가 아니라 두번째 요청/재생이 된다.
    func testAC21_loading중_재입력은_기존요청을_취소한다() async {
        await assertLateSuccess(action: "toggle")
    }
    // 깨짐: 선택 변경 후 늦은 factory 결과가 이전 소리를 재생한다.
    func testAC21_선택변경후_늦은성공은_재생하지_않는다() async {
        await assertLateSuccess(action: "selection")
    }
    // 깨짐: 저장·취소·이탈의 stop 경계가 늦은 factory 결과를 무효화하지 않는다.
    func testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다() async {
        for boundary in ["save", "cancel", "disappear"] { await assertLateSuccess(action: boundary) }
    }
    // 깨짐: inactive 이후 늦은 성공이 재생되거나 복귀가 자동 재생한다.
    func testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다() async {
        await assertLateSuccess(action: "inactive")
    }
    private func assertLateSuccess(action: String) async {
        let r = rig(); let p = PreviewPlayer("old", log: r.log)
        let task = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(0)], timeout: 1)
        switch action {
        case "toggle": await r.controller.togglePreview()
        case "selection": r.controller.chooseSound(.forest)
        case "inactive": r.controller.setActive(false); r.controller.setActive(true)
        default: r.controller.stopPreview()
        }
        r.factory.resolve(0, .success(p)); await task.value
        XCTAssertEqual(p.playCalls, 0, action); XCTAssertEqual(p.stopCalls, 1, action)
        XCTAssertEqual(r.controller.phase, .stopped, action)
        XCTAssertNil(r.controller.errorMessage, action)
        XCTAssertEqual(r.controller.selectedSound, action == "selection" ? .forest : .bus, action)
        XCTAssertEqual(r.factory.sounds.count, 1, action)
    }
    // 깨짐: old success/throw가 새 요청의 phase/error/player를 덮는다.
    func testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다() async {
        for succeeds in [true, false] { await assertStaleResult(succeeds: succeeds, reopen: false) }
    }
    // 깨짐: 동일 controller 재진입 후 이전 throw가 새 세션에 오류를 표시한다.
    func testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다() async {
        await assertStaleResult(succeeds: false, reopen: true)
    }
    private func assertStaleResult(succeeds: Bool, reopen: Bool) async {
        let r = rig(); let old = PreviewPlayer("old", log: r.log); let fresh = PreviewPlayer("new", log: r.log)
        let oldTask = Task { await r.controller.togglePreview() }
        await fulfillment(of: [r.factory.arrival(0)], timeout: 1)
        if reopen { r.controller.stopPreview(); r.controller.beginSelection(sound: .forest) }
        else { r.controller.chooseSound(.forest) }
        _ = await start(r, player: fresh, index: 1)
        r.factory.resolve(0, succeeds ? .success(old) : .failure(PreviewFailure.unavailable))
        await oldTask.value
        XCTAssertEqual(r.controller.phase, .playing); XCTAssertNil(r.controller.errorMessage)
        XCTAssertEqual(r.controller.selectedSound, .forest)
        XCTAssertEqual(fresh.playCalls, 1); XCTAssertEqual(fresh.stopCalls, 0); XCTAssertEqual(old.playCalls, 0)
        if succeeds { XCTAssertEqual(old.stopCalls, 1) }
        r.controller.stopPreview(); await finishStop(r, player: fresh)
    }
    // 깨짐: setActive(true)/beginSelection이 재생을 자동 재개한다.
    func testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다() async {
        for inactive in [false, true] {
            let r = rig(); let p = PreviewPlayer("A", log: r.log)
            _ = await start(r, player: p)
            if inactive { r.controller.setActive(false) } else { r.controller.stopPreview() }
            await finishStop(r, player: p)
            if inactive { r.controller.setActive(true) } else { r.controller.beginSelection(sound: .bus) }
            XCTAssertEqual(r.controller.phase, .stopped, "inactive=\(inactive)")
            XCTAssertEqual(r.factory.sounds, [.bus]); XCTAssertEqual(p.playCalls, 1)
        }
    }
}

@MainActor private final class PreviewEventLog { var events: [String] = [] }
private enum PreviewFailure: Error { case unavailable }
@MainActor private final class PreviewPlayer: SoundPreviewPlaying {
    let name: String; let log: PreviewEventLog; let prepareResult: Bool; let playResult: Bool
    let stopped = XCTestExpectation(description: "player stopped")
    private(set) var playCalls = 0; private(set) var stopCalls = 0
    var playObservation: XCTestExpectation?
    var volume: Float = 1 { didSet { log.events.append("\(name).volume=\(volume)") } }
    var numberOfLoops: Int = 0 { didSet { log.events.append("\(name).loops=\(numberOfLoops)") } }
    init(_ name: String, log: PreviewEventLog, prepare: Bool = true, play: Bool = true) {
        self.name = name; self.log = log; prepareResult = prepare; playResult = play
    }
    func prepareToPlay() -> Bool { log.events.append("\(name).prepare"); return prepareResult }
    func play() -> Bool {
        playCalls += 1; log.events.append("\(name).play"); playObservation?.fulfill()
        return playResult
    }
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) { log.events.append("\(name).fade=\(volume):\(fadeDuration)") }
    func stop() { stopCalls += 1; log.events.append("\(name).stop"); if stopCalls == 1 { stopped.fulfill() } }
}
@MainActor private final class PreviewFactoryGate {
    private(set) var sounds: [JourneySound] = []
    private var pending: [Int: CheckedContinuation<any SoundPreviewPlaying, Error>] = [:]
    private var arrivals: [Int: XCTestExpectation] = [:]
    func arrival(_ index: Int) -> XCTestExpectation {
        if let e = arrivals[index] { return e }
        let e = XCTestExpectation(description: "factory request \(index)"); arrivals[index] = e
        if sounds.count > index { e.fulfill() }
        return e
    }
    func make(_ sound: JourneySound) async throws -> any SoundPreviewPlaying {
        let index = sounds.count; let entered = arrival(index); sounds.append(sound)
        return try await withCheckedThrowingContinuation { c in
            pending[index] = c; entered.fulfill()
        }
    }
    func resolve(_ index: Int, _ result: Result<any SoundPreviewPlaying, Error>) {
        guard let c = pending.removeValue(forKey: index) else { XCTFail("factory continuation absent: \(index)"); return }
        c.resume(with: result)
    }
}
@MainActor private final class PreviewSleepGate {
    private(set) var durations: [Duration] = []
    var arrival = XCTestExpectation(description: "fade sleep entered")
    private var pending: [CheckedContinuation<Void, Never>] = []
    func sleep(_ duration: Duration) async {
        durations.append(duration)
        await withCheckedContinuation { c in pending.append(c); arrival.fulfill() }
    }
    func releaseAll() {
        let continuations = pending; pending.removeAll()
        arrival = XCTestExpectation(description: "next fade sleep entered")
        continuations.forEach { $0.resume() }
    }
}
```
