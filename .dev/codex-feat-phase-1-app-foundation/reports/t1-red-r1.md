# T1 재현 RED R1 보고서

## Status

BLOCKED

테스트 2건은 기존 8개 테스트 메서드 뒤에 추가했으며 프로덕션 코드는 읽거나 수정하지 않았다. 지정된 단일 xcodebuild 실행은 CoreSimulatorService 연결 실패로 테스트 번들을 빌드·실행하기 전에 종료되어, 의도한 assertion RED와 회귀 방어 PASS를 이번 실행에서 확인할 수 없었다.

## 깨짐 명명 및 변이 점검

- `testMalformedTestIDReportsSetupErrorAndStaysLoading`: malformed UUID 준비 오류가 bootstrap 유무에 종속되어 `test.setupError`로 공개되지 않으면 실패한다. malformed 입력 검증 누락과 잘못된 분기를 잡는다.
- `testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations`: 기본 destination에 내비게이션 뒤로가기 이외 고객용 버튼이 추가되면 실패한다. 금지된 부작용성 사용자 action 추가를 잡는다.

## 추가한 테스트 코드

파일: `ios/FocusMateUITests/Phase1FlowTests.swift`

```swift
func testMalformedTestIDReportsSetupErrorAndStaysLoading() {
    let app = XCUIApplication()
    app.launchArguments = ["--fm-ui-test-id", "not-a-uuid"]
    app.launch()

    XCTAssertTrue(element("test.setupError", in: app).waitForExistence(timeout: timeout))
    XCTAssertTrue(element("screen.loading", in: app).exists)
    XCTAssertFalse(element("screen.cardEntry", in: app).exists)
    XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
    XCTAssertFalse(element("screen.main", in: app).exists)
    XCTAssertFalse(element("screen.storageError", in: app).exists)
}

func testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations() {
    let app = launch(seed: "ready")
    XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))

    let destinations = [
        (button: "여행 준비", screen: "screen.preparation"),
        (button: "기록", screen: "screen.records"),
        (button: "설정", screen: "screen.settings"),
        (button: "마이페이지", screen: "screen.profile"),
    ]

    for destination in destinations {
        app.buttons[destination.button].tap()
        XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))

        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: timeout))
        XCTAssertEqual(navigationBar.buttons.count, 1)
        XCTAssertEqual(app.buttons.count, navigationBar.buttons.count)

        let backButton = navigationBar.buttons.firstMatch
        XCTAssertTrue(backButton.exists)
        backButton.tap()
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
    }
}
```

## 실패 확인

명령:

```sh
FOCUSMATE_SIMULATOR_ID=529B88AF-5286-43EA-938A-4233F6B226CD FOCUSMATE_DERIVED_DATA=/tmp/focusmate-phase1-derived python3 scripts/check-ios.py test ios/FocusMateUITests/Phase1FlowTests.swift > /tmp/focusmate-t1-red-r1.log 2>&1
```

- 실제 exit code: `70`
- 실제 xcodebuild 실행 횟수: `1`
- 분류: 테스트 assertion 실패나 테스트 컴파일 실패가 아닌 시뮬레이터 인프라 실패
- 직접 원인: `CoreSimulatorService connection became invalid`; 지정 destination `529B88AF-5286-43EA-938A-4233F6B226CD`를 찾지 못함
- 테스트 프로세스 시작 여부: 시작하지 않음

실패 메시지 마지막 10줄:

```text

	The requested device could not be found because no available devices matched the request.

	Destinations compatible with the "FocusMate" scheme:
		{ platform:macOS, arch:arm64, variant:Designed for [iPad,iPhone], id:00008112-0002249636A3C01E, name:My Mac }
		{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
		{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }

	Destinations incompatible with the "FocusMate" scheme:
		{ platform:macOS, arch:arm64e, id:00008112-0002249636A3C01E, name:My Mac, error:My Mac’s macOS platform doesn’t match FocusMate.app’s supported platforms. You can change FocusMate.app’s Base SDK or Supported Platforms to support My Mac. }
```

## 전체 10개 케이스 결과

이번 단일 실행에서 테스트 케이스가 시작되지 않았으므로 아래 결과는 모두 `미실행`이다. 기존 8개가 PASS 중이라는 정보는 태스크 입력의 사전 상태이며 이번 실행의 검증 결과로 재주장하지 않는다.

1. `testNoSavedDataOpensCardEntryWithoutCreatingAFile` — 미실행
2. `testCardOnlyOpensInitialStationEntryAndPublishesSnapshotSchema` — 미실행
3. `testReadyStateOpensMainWithSavedCurrentStationAndDirection` — 미실행
4. `testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction` — 미실행
5. `testReadyStateRestoresAfterTerminationWithoutReseeding` — 미실행
6. `testCorruptDataReportsErrorAndPreservesExactBytesAcrossRelaunch` — 미실행
7. `testUnsupportedDataReportsErrorAndPreservesExactBytesAcrossRelaunch` — 미실행
8. `testFailedSaveKeepsReadySnapshotAndBytesThenRestoresNormally` — 미실행
9. `testMalformedTestIDReportsSetupErrorAndStaysLoading` — 미실행; 예상 RED assertion 미확인
10. `testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations` — 미실행; 예상 PASS 미확인

## 참조한 파일

- `.dev/codex-feat-phase-1-app-foundation/rgr-task1.md`
- `ios/FocusMateUITests/Phase1FlowTests.swift`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-red/SKILL.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-dev/references/codex-runtime.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/testing-anti-patterns.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/frontend-testing.md`
- `/tmp/focusmate-t1-red-r1.log` (지정 테스트 실행 로그)

## 다음 단계

CoreSimulatorService와 지정 UDID가 사용 가능한 실행 환경에서 같은 명령을 다시 실행해 9번의 assertion RED 및 10번의 PASS를 확인해야 한다. 이번 역할에서는 프로덕션 수정이나 추가 xcodebuild 재실행을 수행하지 않았다.

## 상위 직접 재현

CLI sandbox의CoreSimulator오류는환경실패이며RED아님. 부모직접동일명령실행 /tmp/focusmate-t1-red-r1-parent.log:10cases 9pass/1assertfail(exit65). 기존8유지, 추가action-defense1pass, malformed-ID1fail. Release빌드exit0, 실행파일에시험switch/diagnostic문자열없음.
