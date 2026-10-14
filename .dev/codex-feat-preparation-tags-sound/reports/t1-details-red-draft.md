# T1 details RED draft

Status: DONE_WITH_CONCERNS — 1 independent draft case; not promoted or executed while GREEN10 runs.

Observed contract: W04 PreparedJourneyDetails exposes the origin name, bound label and distance from the supplied JourneySelection. The fixture and expected literals are supplied route/interface metadata: index 0, direction 1, 12 stops → 성수역 / 성수동 방면 / 6.6km. No production calculation generates expected values. Wrong origin/direction mapping, empty convenience getters or incorrect distance conversion must break this case.

Allowed references actually read: `.dev/codex-feat-preparation-tags-sound/design.md` pure value interface; parent task's fixed route metadata; red-writer role previously read in this isolated agent. Production was not read, searched or edited. Existing tests were not edited. No simulator command was executed. Failure is pending; this is not established behavior RED.

## PreparationDetailsTests.swift (1 case)

```swift
import XCTest
@testable import FocusMate

final class PreparationDetailsTests: XCTestCase {
    // Break: W04 payload derives the wrong origin/direction or drops the journey distance.
    func testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다() {
        let journey = JourneySelection(
            origin: StopPosition(index: 0, direction: 1), minutes: 60,
            busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let payload = PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)

        XCTAssertEqual(payload.originName, "성수역")
        XCTAssertEqual(payload.boundLabel, "성수동 방면")
        XCTAssertEqual(payload.distanceText, "6.6km")
    }
}
```

## Details contract assertion RED (2026-10-14)

Promoted ONLY draft-tests/PreparationDetailsTests.swift to ios/FocusMateTests/PreparationDetailsTests.swift after parent-confirmed GREEN10 (existing 41/0). Existing tests were not edited.

Command, executed from /Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new:
```sh
FOCUSMATE_SIMULATOR_ID=88ABB031-C48A-4DA0-B15C-14787702E647 python3 scripts/check-ios.py test ios/FocusMateTests/PreparationDraftTests.swift ios/FocusMateTests/PreparationModelTests.swift ios/FocusMateTests/PreparationDetailsTests.swift > .dev/codex-feat-preparation-tags-sound/t1-details-red.log 2>&1
```

Exit 65, assertion RED established for the new case. All 42 cases executed: existing Draft 20/0 failures + Model 21/0 failures; new Details 1 case/3 assertion failures (0 unexpected). All three convenience values returned empty strings rather than the independent expected literals. No production reads/searches/edits were performed.

```text
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:14: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("성수역")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:15: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("성수동 방면")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:16: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("6.6km")
```

Log: `.dev/codex-feat-preparation-tags-sound/t1-details-red.log`. Current case count: 42. Next: implement these three derived payload properties, then verify all 42 GREEN.
