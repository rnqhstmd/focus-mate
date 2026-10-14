# T2 RED draft — DONE_WITH_CONCERNS

2026-10-14. 独립 준비 초안, 정식 T2/RGR 미진입. 부모 baseline/T1 완료 뒤 승격·compile RED·행동 RED 지시 대기. 테스트 앱 폴더 및 프로덕션 파일에 쓰지 않았고 실행하지 않았다.

## AC mapping and limits

- AC14: beginSelection 확정값·stopped·factory0, chooseSound factory0. AppModel 주입 controller identity로 세션 소유 검증.
- AC15: 취소 경계 stop 후 같은 controller beginSelection으로 이전 확정값 복원. 실제 UI 취소 wiring은 T3.
- AC16: 임시 rainBus를 실제 PreparationDraft.setSound에 저장하고 다음 beginSelection 반영. 실제 UI 저장 wiring은 T3.
- AC17: 4샘플 각각 factory인자, volume0 → loops-1 → prepare → play → fade1/0.12 리터럴 순서 및 playing; factory 대기 loading.
- AC18: toggle 중지 fade0/0.06 → 60ms sleep → stop; 선택 변경 factory 증가0; 연속stop fade1/stop1; old stop 이전 B play0 및 log 순서 nooverlap.
- AC19: none controller factory0/초안 none 저장; adapter 직접 none은 throw. 유효 준비 확정 가드는 T1/T3 책임.
- AC20: factorythrow/preparefalse/playfalse 개별 케이스; stopped/error/선택유지 및 fadein0. 실제 준비 확정 가능 여부는 T1/T3 책임.
- AC21: loading 재입력, 선택 변경, 저장·취소·이탈 stop 경계, inactive/active, oldsuccess→freshplaying 및 oldthrow→freshplaying, close/reopen oldthrow. 반복 parameter는 메시지에 개별 경계/샘플 식별 포함.
- AC22: 재생중 stop/inactive 후 복귀 factory 증가0; 동일 controller beginSelection reopen시 종료task 보존/nooverlap.
- Resource: Bundle.main 실제 URL/bytes SHA256 4개 golden/AVAudioPlayer decode/adapter make+prepare+stop. 실제 play 없음. sourcepath fallback 없음. Bundle(for: AudioResourceTests.self) 누락 리소스4개 throw.

## Cases and name-the-break

22 controller + 3 resource = 25개 XCTest 메서드. 각 코드 주석의 깨짐 명명이 잡는 mutation은 잘못된 상수/인자·분기·부작용 누락·none 경계 누락·stale 결과 덮어쓰기다.

- testAC14_beginSelection은_확정소리로_열고_재생을_시작하지_않는다
- testAC14_소리_선택만으로는_factory를_호출하지_않는다
- testAC15_취소후_재진입은_이전_확정소리로_임시선택을_되돌린다
- testAC16_저장한_임시소리가_초안과_다음_선택에_반영된다
- testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다
- testAC17_factory_완료전에는_loading이다
- testAC18_다시누르면_60ms페이드_완료후_중지한다
- testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다
- testAC18_연속중지는_페이드와_stop을_각각_한번만_한다
- testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다
- testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다
- testAC19_none은_재생요청이_없고_초안에_저장된다
- testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다
- testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다
- testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다
- testAC21_loading중_재입력은_기존요청을_취소한다
- testAC21_선택변경후_늦은성공은_재생하지_않는다
- testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다
- testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다
- testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다
- testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다
- testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다
- testAC17_네_샘플은_실제앱번들의_goldenWAV이며_decode와_adapter준비가_성공한다
- testAC19_none을_adapterfactory에_직접_넘기면_throw한다
- testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다

## RED verification

실패 확인 명령: 실행 금지 지시로 미실행. 부모의 focused check-ios.py 러너 지시를 받아 파일 승격 뒤 compile RED 및 무동작 stub 행동 RED를 확인해야 한다. 실패 메시지 없음, PASS/RED 확인 주장 없음.

## Determinism and cleanup

실제 sleep/고정 Task.yield 루프 없음. factory checked throwing continuation은 index별 resolve에서 remove하여 단 한 번 resume. sleep checked continuation은 releaseAll에서 배열을 먼저 비워 단 한 번 resume. 정상/늦은 결과 task는 모두 await task.value로 join하며 종료 task의 효과는 stopped expectation으로 확인. expectation timeout 1초는 실패 상한이다. 제품이 주입 gate 외의 무한 대기를 도입할 경우 task join 자체에는 timeout이 없으므로 러너 timeout으로 감지해야 한다. 정상 구현에서 모든 생성 task/continuation이 정리되는 계약이며 승격후 실패 러너 결과로 점검 필요.

## Read references (all)

- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md
- .dev/codex-feat-preparation-tags-sound/design.md (2차보강/Testability 포함)
- .dev/codex-feat-preparation-tags-sound/prd.md
- ios/FocusMateTests/CardIssuanceControllerTests.swift
- ios/FocusMateTests/CardIssuanceTestDoubles.swift
- ios/FocusMateTests/PassFaceAssetTests.swift
- 이번 초안 두 테스트 파일 (자체 수정/케이스 수 확인)

프로덕션 소스 Read/Grep/Write 없음. memory lookup 없음.

## Full test sources

### .dev/codex-feat-preparation-tags-sound/draft-tests/SoundPreviewControllerTests.swift

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
        let entered = expectation(description: "new request entered")
        let task = Task { entered.fulfill(); await r.controller.togglePreview() }
        await fulfillment(of: [entered], timeout: 1)
        XCTAssertEqual(a.stopCalls, 0); XCTAssertEqual(b.playCalls, 0)
        r.sleeper.releaseAll()
        await fulfillment(of: [a.stopped, r.factory.arrival(1)], timeout: 1)
        r.factory.resolve(1, .success(b)); await task.value
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
    var volume: Float = 1 { didSet { log.events.append("\(name).volume=\(volume)") } }
    var numberOfLoops: Int = 0 { didSet { log.events.append("\(name).loops=\(numberOfLoops)") } }
    init(_ name: String, log: PreviewEventLog, prepare: Bool = true, play: Bool = true) {
        self.name = name; self.log = log; prepareResult = prepare; playResult = play
    }
    func prepareToPlay() -> Bool { log.events.append("\(name).prepare"); return prepareResult }
    func play() -> Bool { playCalls += 1; log.events.append("\(name).play"); return playResult }
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

### .dev/codex-feat-preparation-tags-sound/draft-tests/AudioResourceTests.swift

```swift
import AVFoundation
import CryptoKit
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class AudioResourceTests: XCTestCase {
    // 깨짐: 앱 번들 리소스 누락, WAV 대신 다른 bytes 포함, 손상된 WAV, adapter의 URL 매핑 오류.
    func testAC17_네_샘플은_실제앱번들의_goldenWAV이며_decode와_adapter준비가_성공한다() async throws {
        let samples: [(JourneySound, String)] = [
            (.bus, "eb580967c70cb86d709ecb0122d45c771343e37d834b45201be315ff9d5fb1be"),
            (.rainBus, "6efc8b0c2e2f16fbc491eac7cad5ad1da80ef138f20d1349150ef2bfbb45b8bb"),
            (.subway, "f938cfb97a5d0ae7a9cb91df9c4ff2d3e54ddd0dab4802ccb2452aaa31d235f1"),
            (.forest, "9391f1d2024588f505ccefc4f53907dde3aaabdc76115dcef53c3af5090a5cc8")
        ]
        for (sound, golden) in samples {
            let name = try XCTUnwrap(sound.resourceName, "\(sound) resource name")
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "wav"), "\(sound) bundled WAV")
            let actual = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(actual, golden, "\(sound) actual bundle bytes")
            let decoder = try AVAudioPlayer(contentsOf: url)
            XCTAssertTrue(decoder.prepareToPlay(), "\(sound) actual WAV decode")
            decoder.stop()
            let adapter = try await AVSoundPreviewPlayer.make(sound: sound)
            XCTAssertTrue(adapter.prepareToPlay(), "\(sound) actual adapter")
            adapter.stop()
        }
    }
    // 깨짐: none을 직접 factory에 넘겼는데 player를 반환한다.
    func testAC19_none을_adapterfactory에_직접_넘기면_throw한다() async {
        do {
            let unexpected = try await AVSoundPreviewPlayer.make(sound: .none)
            unexpected.stop()
            XCTFail("none factory must throw")
        } catch { }
    }
    // 깨짐: 리소스 없는 주입 bundle을 무시하고 main/sourcepath로 fallback한다.
    func testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다() async {
        let emptyBundle = Bundle(for: AudioResourceTests.self)
        for sound in [JourneySound.bus, .rainBus, .subway, .forest] {
            do {
                let unexpected = try await AVSoundPreviewPlayer.make(sound: sound, bundle: emptyBundle)
                unexpected.stop()
                XCTFail("\(sound): missing bundle resource must throw")
            } catch { }
        }
    }
}
```

## 정식 승격
T1 42/0fail 및 SPEC/QUALITY PASS 뒤 기존 격리 RED작성자가 만든 draft 두 파일을 그대로 승격. 재디스패치는 하네스 agent thread limit reached로 실패했으므로 오케스트레이터가 변경 없이 복사/직접실행. 새로 테스트를 작성하거나 수정하지 않았으며 원래 작성자의 production 격리 유지. compileRED 후 별도 assertionRED 확인 예정.

## 직접 assertion RED
오케스트레이터 직접 focused 67개 실행, exit65. 신규 25 cases 모두 실패, 기존 42 pass. 컴파일 오류가 아니라 XCTest assertion 및 미구현 factory 이벤트 기대 timeout. 로그 t2-red-behavior.log.
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:18: error: -[FocusMateTests.AudioResourceTests testAC17_네_샘플은_실제앱번들의_goldenWAV이며_decode와_adapter준비가_성공한다] : XCTUnwrap failed: expected non-nil value of type "String" - bus resource name
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:35: error: -[FocusMateTests.AudioResourceTests testAC19_none을_adapterfactory에_직접_넘기면_throw한다] : failed - none factory must throw
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:45: error: -[FocusMateTests.AudioResourceTests testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다] : failed - bus: missing bundle resource must throw
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:45: error: -[FocusMateTests.AudioResourceTests testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다] : failed - rainBus: missing bundle resource must throw
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:45: error: -[FocusMateTests.AudioResourceTests testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다] : failed - subway: missing bundle resource must throw
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/AudioResourceTests.swift:45: error: -[FocusMateTests.AudioResourceTests testAC20_리소스없는_테스트번들을_주입하면_네_샘플_각각_throw한다] : failed - forest: missing bundle resource must throw
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:40: error: -[FocusMateTests.SoundPreviewControllerTests testAC14_beginSelection은_확정소리로_열고_재생을_시작하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:41: error: -[FocusMateTests.SoundPreviewControllerTests testAC14_beginSelection은_확정소리로_열고_재생을_시작하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:49: error: -[FocusMateTests.SoundPreviewControllerTests testAC14_소리_선택만으로는_factory를_호출하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:58: error: -[FocusMateTests.SoundPreviewControllerTests testAC15_취소후_재진입은_이전_확정소리로_임시선택을_되돌린다] : XCTAssertEqual failed: ("subway") is not equal to ("bus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:69: error: -[FocusMateTests.SoundPreviewControllerTests testAC16_저장한_임시소리가_초안과_다음_선택에_반영된다] : XCTAssertEqual failed: ("subway") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:70: error: -[FocusMateTests.SoundPreviewControllerTests testAC16_저장한_임시소리가_초안과_다음_선택에_반영된다] : XCTAssertEqual failed: ("subway") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:90: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_factory_완료전에는_loading이다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_factory_완료전에는_loading이다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_factory_완료전에는_loading이다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_factory_완료전에는_loading이다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:79: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.bus]") - bus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:80: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("loading") is not equal to ("playing") - bus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:81: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("["A.volume=0.0", "A.loops=-1", "A.prepare", "A.play", "A.fade=1.0:0.12"]") - bus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:79: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.rainBus]") - rainBus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:80: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("loading") is not equal to ("playing") - rainBus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:81: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("["A.volume=0.0", "A.loops=-1", "A.prepare", "A.play", "A.fade=1.0:0.12"]") - rainBus
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:79: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.subway]") - subway
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:80: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("loading") is not equal to ("playing") - subway
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:81: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("["A.volume=0.0", "A.loops=-1", "A.prepare", "A.play", "A.fade=1.0:0.12"]") - subway
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:79: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.forest]") - forest
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:80: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("loading") is not equal to ("playing") - forest
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:81: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : XCTAssertEqual failed: ("[]") is not equal to ("["A.volume=0.0", "A.loops=-1", "A.prepare", "A.play", "A.fade=1.0:0.12"]") - forest
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC17_네_샘플은_무음준비후_반복재생과_120ms페이드를_요청한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:101: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:102: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:103: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : XCTAssertEqual failed: ("[]") is not equal to ("[0.06 seconds]")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:104: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional("A.fade=0.0:0.06")")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:106: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:107: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_다시누르면_60ms페이드_완료후_중지한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:126: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:127: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:128: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_연속중지는_페이드와_stop을_각각_한번만_한다] : XCTAssertEqual failed: ("[]") is not equal to ("[0.06 seconds]")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:142: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:149: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped", "factory request 1".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : failed - factory continuation absent: 1
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:151: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : XCTAssertEqual failed: ("loading") is not equal to ("playing")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:153: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : XCTAssertLessThan failed: ("9223372036854775807") is not less than ("-1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "next fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:114: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:115: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:117: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.bus]")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:118: error: -[FocusMateTests.SoundPreviewControllerTests testAC18_재생중_선택변경은_중지하고_새소리를_자동재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:162: error: -[FocusMateTests.SoundPreviewControllerTests testAC19_none은_재생요청이_없고_초안에_저장된다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:163: error: -[FocusMateTests.SoundPreviewControllerTests testAC19_none은_재생요청이_없고_초안에_저장된다] : XCTAssertEqual failed: ("subway") is not equal to ("none")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:169: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:171: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:171: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:172: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : XCTAssertEqual failed: ("subway") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:174: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_factorythrow는_선택을_유지하고_무음과_오류를_제공한다] : XCTAssertEqual failed: ("subway") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:187: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:187: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:189: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:191: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_playfalse는_무음상태와_오류_선택유지를_제공한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:187: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:187: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:191: error: -[FocusMateTests.SoundPreviewControllerTests testAC20_preparefalse는_play없이_오류와_선택유지를_제공한다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : XCTAssertEqual failed: ("0") is not equal to ("1") - toggle
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - toggle
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : XCTAssertEqual failed: ("subway") is not equal to ("bus") - toggle
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_loading중_재입력은_기존요청을_취소한다] : XCTAssertEqual failed: ("0") is not equal to ("1") - toggle
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:237: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 1".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : failed - factory continuation absent: 1
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:243: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("playing")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:244: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:245: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_닫고_재열어_재생한뒤_oldthrow는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - inactive
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - inactive
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("bus") - inactive
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_비활성화후_늦은성공과_복귀는_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - inactive
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:237: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 1".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : failed - factory continuation absent: 1
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:243: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("playing")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:244: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:245: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:246: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:237: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 1".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : failed - factory continuation absent: 1
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:243: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("playing")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:244: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:245: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_새재생후_old성공과_throw는_새상태를_덮지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - selection
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - selection
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("forest") - selection
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_선택변경후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - selection
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - save
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - save
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("bus") - save
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - save
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - cancel
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - cancel
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("bus") - cancel
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - cancel
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:212: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:220: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - disappear
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:221: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - disappear
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:223: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("subway") is not equal to ("bus") - disappear
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:224: error: -[FocusMateTests.SoundPreviewControllerTests testAC21_저장_취소_이탈의_stop후_늦은성공은_재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1") - disappear
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:142: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:149: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped", "factory request 1".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : failed - factory continuation absent: 1
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:151: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("playing")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:153: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : XCTAssertLessThan failed: ("9223372036854775807") is not less than ("-1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "next fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:257: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - inactive=false
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:258: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.bus]")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:258: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:23: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "factory request 0".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:296: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : failed - factory continuation absent: 0
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:29: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "fade sleep entered".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:31: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : Asynchronous wait failed: Exceeded timeout of 1 seconds, with unfulfilled expectations: "player stopped".
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:257: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("loading") is not equal to ("stopped") - inactive=true
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:258: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("[]") is not equal to ("[FocusMate.JourneySound.bus]")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/SoundPreviewControllerTests.swift:258: error: -[FocusMateTests.SoundPreviewControllerTests testAC22_재생중_이탈과_비활성화후_복귀는_자동재생하지_않는다] : XCTAssertEqual failed: ("0") is not equal to ("1")

## R1 겹침 테스트 보강
독립 격리red-writer의 reports/t2-red-strengthening.md. 기존25케이스 유지, helper를 A gate 보류 중 B factory반환/미재생 관찰로변경. 오케스트레이터가 stopTask await 1줄만 제거하는 통제변이를 실행하고 원본을 정확히 복원한다. runtime/t2-barrier-original.swift 원본 SHA256 6266dadcc2ce9c575ed2271f9a2a3260d6abb82a86d3acb86afa3d3de0d42f99. 실제기능 수정 아닌 회귀검출력 검증.

## R1 통제 변이 직접 결과
exit65,65 pass /2 failed, 종료await제거를 두겹침케이스가검출. 실패: ['-[FocusMateTests.SoundPreviewControllerTests testAC18_이전player가_완전히_중지된_뒤에만_새player를_재생한다]', '-[FocusMateTests.SoundPreviewControllerTests testAC22_같은controller로_닫고_재열어도_종료중인_소리와_겹치지_않는다]']. 실제제작코드원본SHA6266dadcc2ce9c575ed2271f9a2a3260d6abb82a86d3acb86afa3d3de0d42f99으로byte동일복원완료. 테스트새RED해시 fd1a0b5f6eb2a57510d650663d484f4f47b1f904. 로그t2-mutant-no-stop-barrier.log.
