# 실제 iOS Reduce Motion 설정 증거

Status: **OS SETTING ON — 직접 확인 완료**. 현재 W10 앱의 `test.reduceMotion` 환경 진단은 **미실행/PENDING**이며 별도 확인이 필요하다.

- 대상: `FocusMate W10 VoiceOver`, iOS 27.0, simulator `F226C28A-81D5-4708-B939-81B605AC748E`.
- 실제 앱: `com.apple.Preferences`, 한국어 `설정`.
- 독립 probe: `.dev/codex-feat-card-customization/voiceover-probe/ios/FocusMateUITests/ReduceMotionSettingsProbeTests.swift`.
- archived HEAD 5b7af0f 기반 기존 probe 프로젝트에 위 신규 설정 case만 추가했다. 현재 W10 production/UI test target은 수정하지 않았다.
- 실행은 매번 `-only-testing:FocusMateUITests/ReduceMotionSettingsProbeTests/testObserveAndEnableReduceMotion`, `-parallel-testing-enabled NO`로 제한했다.
- 전용 DerivedData: `.build/reduce-motion-probe/derived`. iOS 26.5 및 다른 기기의 설정·앱은 변경하지 않았다.

## 관찰 후 사용한 실제 접근성 경로

1. `observe01`: Settings 초기 트리에서 Button `com.apple.settings.accessibility`, label `손쉬운 사용`을 읽었다.
2. `observe02`: 위 버튼으로 진입한 트리에서 Button `MOTION_TITLE`, label `동작`을 읽었다.
3. `observe03`: 위 버튼으로 진입한 트리에서 Switch `REDUCE_MOTION`, label `동작 줄이기`, value `0`을 읽었다. 바깥 Switch 안에 실제 63×28pt Switch 자식이 있었다.
4. `enable04`: 바깥 Switch의 기본 tap으로는 value가 바뀌지 않아 10초 대기 assertion 1건 실패했다. 이 결과를 성공으로 대체하지 않고 로그/xcresult를 보존했다.
5. `enable05`: 이미 관찰한 자식 Switch를 `settings.switches["REDUCE_MOTION"].switches.firstMatch.tap()`으로 조작했다. 바깥 value `0 → 1`을 확인했다. Settings를 종료·재실행하고 같은 관찰 경로로 돌아와 value `1` 유지도 assertion과 screenshot으로 확인했다.

추측한 preferences key, defaults 쓰기, 가짜 앱 environment, URL deep link, CUA DeviceHub 우회는 사용하지 않았다. 사용한 selector는 앞선 실제 트리에서 각각 관찰했다.

## 실행 결과와 원본 증거

최종 `enable05`: **1 test / 0 failures**, 38.692초, xcodebuild exit 0 / `TEST SUCCEEDED`.

- [최종 실행 로그](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/enable05.log): 938행 BEFORE=0, 950행 AFTER=1, 1503행 AFTER_SETTINGS_RELAUNCH=1, 1602행 1/0.
- [최종 xcresult](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/enable05.xcresult)
- [재실행 후 실제 AX 트리](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/attachments05/83264FAA-2789-4EF6-B2C3-6E16744610B6.txt): 27행 REDUCE_MOTION, label 동작 줄이기, value 1.
- [재실행 후 실제 화면](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/attachments05/3E8ACDB5-E466-41BC-9C43-4646E0FE52C4.png): 녹색 ON 스위치를 직접 열어 확인했다.
- [최초 OFF 화면](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/attachments03/CAD099EB-6B10-494A-92CC-BABAC8198847.png)
- [바깥 Switch tap 실패 로그](/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/enable04.log)
- 최초 경로 관찰 `observe01/02/03`은 각각 1 test / 0 failures. 원본 xcresult 및 attachment manifest는 `.build/reduce-motion-probe/`에 보존했다. `.build/`는 기존 ignored 경로다.

실행 cwd: `.dev/codex-feat-card-customization/voiceover-probe`.

```sh
FOCUSMATE_DERIVED_DATA=/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/derived xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E' -derivedDataPath /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/derived -resultBundlePath /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/reduce-motion-probe/enable05.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never '-only-testing:FocusMateUITests/ReduceMotionSettingsProbeTests/testObserveAndEnableReduceMotion' test CODE_SIGNING_ALLOWED=NO
```

다시 실행할 때는 이미 존재하는 resultBundlePath를 새 이름으로 지정한다. 증거 export는 실제 `xcresulttool export attachments --help`를 확인하고 `xcrun xcresulttool export attachments --path <xcresult> --output-path <owned directory>`로 수행했다.

남은 경계: 이 결과는 실제 OS 설정 ON과 Settings 재실행 유지의 증거다. 현재 W10 SwiftUI environment 전달, 앱 동작 줄이기 처리, VoiceOver, 시안 일치의 PASS를 의미하지 않는다. 부모가 현재 앱에서 read-only `test.reduceMotion == true`를 확인할 수 있도록 ON 상태를 유지했다.
