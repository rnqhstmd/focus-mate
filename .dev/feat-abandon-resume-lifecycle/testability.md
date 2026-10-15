## Testability 평가: W07 포기·이어가기·생명주기

결론은 **8/10, TESTABILITY PASS**입니다. 재설계는 필요 없고, 아래 권고 R1~R7만 설계서에 반영하면 됩니다.

설계서는 `/Users/bonseung/Documents/ChatGPT/new-w07/.dev/feat-abandon-resume-lifecycle/design.md`입니다. 규칙(JourneyReach), 화면 값(ActiveJourneyCardContent), 모델 동작, 포기 흐름 컨트롤러는 모두 주입된 저장소와 Fake로 단위 테스트할 수 있습니다. 대부분의 UI AC는 수동 시계와 `test.*` 진단으로 결정적으로 자동화됩니다. 자동화할 수 없는 것은 대화상자가 열릴 때 VoiceOver가 처음 읽는 위치 하나뿐이고, 이것은 W14 실기기 점검과 trust-ledger로 넘깁니다.

### 러너
- `python3 scripts/check-ios.py test <files>`로 돌립니다(focused).
- 단위 테스트는 FocusMateTests(XCTest), UI 테스트는 FocusMateUITests(XCUITest, 시뮬레이터)입니다.
- 하네스는 이미 있습니다: `ios/FocusMateUITests/UITestLaunchSupport.swift`의 FocusMateUIHarness, 수동 시계, `test.failNextSave`, `test.snapshot`, `test.persistedBytes`, `test.announcements`.

### 컴포넌트별 테스트 전략

#### JourneyReach (도달 정류장 규칙, BR-1·2)
- **레이어**: 동작(순수 규칙). 러너는 XCTest.
- **단위**:
  - 표 기반으로 `reachedStops`의 경계를 봅니다: 0, 299, 300, 1499, 1500, 분 상한, 간격 5/6/8.
  - `station`은 정방향·역방향과 순환(끝에서 처음)을 봅니다.
  - `reachedStation`은 출발 대기면 출발지, 도착이면 도착지, 카탈로그 밖이면 nil입니다.
  - `endingActiveJourney`는 records·cards·initialStation을 보존하고 journey를 비우는지 봅니다.
- **통합**: 없음.
- **모의 대상**: 없음. 실제 `RouteStops`와 `BusLine` 카탈로그를 씁니다.
- **격리**: 다른 코드에 의존하지 않는 enum과 extension입니다.
- **AC 매핑**: AC-17(전체), AC-18(가), AC-18(나), AC-19, AC-24의 정류장, AC-8·16의 정류장. AC-18(나)는 질문 1의 답이 와야 기대값이 정해지고, 그 전에는 RED를 쓸 수 없습니다.

#### JourneyLifecycleText / ActiveJourneyCardContent
- **레이어**: 동작(순수 포맷터와 값 타입). 문구 상수 자체는 표현입니다.
- **러너**: XCTest.
- **단위**:
  - 남은 시간 올림: 0/1/60/61/1499초 → 25/25/24/24/1입니다.
  - 버스 문자열 "지선 2014", 경로 문자열 "{태그} · {도착지}까지"를 봅니다.
  - Kind가 resumable과 arrived로 갈리는지, 출발 대기는 전체 분인지 봅니다.
  - `showsResume`, `accessibilityLabel` 조합을 봅니다.
- **모의 대상**: 없음.
- **격리**: `init?(journey:)` 하나만 입력으로 받습니다.
- **AC 매핑**: AC-1(필드), AC-2, AC-23의 "25 min", AC-24의 kind, AC-32의 카드 라벨.

#### AppModel+JourneyLifecycle (resume, confirmNewJourney, abandon, consumeResumeEntry, mainStartTitle, startTripFromMain 가드, open의 notice 초기화)
- **레이어**: 동작(상태·가드·라우팅). 러너는 XCTest.
- **단위**:
  - 기존 `JourneyTimerModelTests.swift:10-28`의 패턴을 씁니다. 메모리 readData와 writeData(Probe)를 주입하고, `AppModel(store:journeyFactory:)` 뒤에 `loadIfNeeded`를 부릅니다.
  - path, snapshot, mainLifecycleNotice, 쓰기 수, 저장된 바이트의 디코드 값을 단언합니다.
  - 연타는 두 번 호출해서 봅니다. 가드가 상태(path, active) 기반이라 시간 의존이 없고 결정적입니다.
- **통합**: `saveJourneyProgress`(실제 코드 재사용)와 SnapshotCodec 왕복을 실제로 통과시킵니다.
- **모의 대상**: 파일 I/O만 대체합니다(writeData 클로저와 shouldFail 스위치).
- **격리**: 확장 파일과 저장 프로퍼티 2개뿐이고, 외부 의존은 store 하나입니다.
- **AC 매핑**: AC-4, AC-5, AC-7, AC-8, AC-10, AC-11, AC-12, AC-16, AC-19, AC-20(모델 불변), AC-23, AC-24, AC-31(모든 경로에서 records 불변), AC-35, BR-10(open이 notice를 지움).
- **권고 R1**: Probe를 `attempts`(실패한 시도 포함)와 `writes`(성공한 바이트)로 나눕니다. 지금 패턴은 성공한 쓰기만 셉니다. AC-10·35의 "실패 시 시도 1회, 재시도 1회"를 단언하려면 시도 수가 필요하고, UI의 `test.writeAttempts`(실패도 셈)와 의미도 맞춰야 합니다.

#### JourneyAbandonController (+ FakeJourneyAbandoner)
- **레이어**: 동작(상태 기계). 러너는 XCTest.
- **단위**:
  - 이미 설계에 있는 경우: request를 두 번 불러도 confirming은 하나, cancel 후 호출 0, confirm을 두 번 불러도 호출 1, `isPaused == false`면 무시, 실패하면 showsFailure이고 재시도하면 성공, 성공 뒤 request는 무시.
  - **권고 R2**: alert 바인딩의 set(false)와 버튼 액션의 호출 순서가 보장되지 않으므로 두 순서를 모두 단위 테스트로 고정합니다.
    - `confirm` → `cancel`: 호출 1, 성공 상태 유지.
    - `cancel` → `confirm`: 호출 1. 확정이 isConfirming에 의존하지 않음을 증명합니다.
  - **권고 R3**: 포커스 복귀 의도를 컨트롤러 상태로 올립니다. 예: `private(set) var focusTarget: FocusTarget?`(`.abandonButton`). cancel이나 실패 후 닫힐 때 설정됩니다. 뷰는 이 값을 `@AccessibilityFocusState`에 옮기기만 하고, DEBUG `test.abandon.focus`는 이 값을 보고합니다.
    - 근거: 출발 안내는 이미 `briefing.focusTarget`을 진단하고 있고(`JourneyView.swift:82, 175`), 이것은 UI 테스트에서 단언됩니다(`DepartureBriefingUITests.swift:53`).
    - 반면 `@AccessibilityFocusState` 값을 그대로 노출하는 `test.timer.focus`(`JourneyTimerView.swift:101`)를 단언하는 UI 테스트는 하나도 없습니다. VoiceOver가 꺼진 시뮬레이터에서 이 값이 유지된다는 근거가 저장소에 없습니다.
- **모의 대상**: `JourneyAbandoning`. Fake는 결과 배열을 순서대로 소비하고 calls를 기록합니다.
- **격리**: 프로토콜 주입이라 AppModel 없이 테스트합니다.
- **AC 매핑**: AC-15(포커스 의도), AC-20(showsFailure·재시도), AC-21, BR-6.

#### JourneyAbandonBar / JourneyView 연결 (autoStart||resumed, 낭독, safeAreaInset)
- **레이어**: 동작(조건부 노출, alert, 자동 시작, 낭독). 외곽선 스타일과 배치는 표현이라 범위 밖입니다.
- **러너**: XCUITest.
- **단위**: 일부만 가능합니다. 판단 로직은 컨트롤러와 모델에 있습니다(`consumeResumeEntry` 1회용은 모델 단위 테스트). `autoStart` 합성식과 `announce` 호출은 뷰 안에 있어서 UI 테스트로만 검증됩니다. W05와 같은 수준의 남는 감점입니다.
- **통합(XCUITest)**:
  - 노출 조건: `journey.abandon`의 존재·부재. 일시정지는 `journey.timer.pause`로, 도착은 수동 시계 advance로 만듭니다.
  - alert는 `app.alerts.matching(label == 제목)`으로 찾고, 버튼은 `.buttons.matching(identifier:)`에 label을 더해 찾습니다. 이 방식은 `CardCustomizationFlowTests.swift:521-554`와 `CardCustomizationView.swift:108-111`에서 이미 쓰고 있어 동작이 확인된 패턴입니다. 본문은 `alert.staticTexts`의 label로 단언합니다.
  - 실패 주입은 `test.failNextSave`를 arm한 뒤 abandon을 누르고 confirm합니다.
  - 낭독은 `test.announcements`에서 정확히 1회 나오는지 보고, 같은 label의 staticText가 화면에 없는지도 봅니다.
- **모의 대상**: ManualJourneyClock, UITestFeedbackRecorder(announcer), UITestNextSaveFailure. 모두 기존 것입니다.
- **AC 매핑**: AC-3, AC-4(후반), AC-13, AC-14(문구·불변), AC-15(닫힘·resume 노출·쓰기 0·focus 진단), AC-20, AC-21, AC-26, AC-32(포기하기 라벨, 이어가기 낭독), AC-33.

#### MainActiveJourneyView / RootView 연결 (카드, 안내, 새 여정 alert, 버튼 문구, DEBUG)
- **레이어**: 동작(조건부 카드, 안내, alert, 라우팅). 카드 스타일은 표현입니다.
- **러너**: XCUITest.
- **통합**:
  - 카드는 `main.activeJourney`(combine 한 요소, label 단언)와 형제 버튼 `main.resumeJourney`를 봅니다.
  - 새 여정 alert 버튼은 `main.newJourney.keep`과 `main.newJourney.confirm`입니다.
  - 안내는 `main.abandonNotice`와 `main.saveFailure`입니다.
  - 메인 실패 주입은 `test.main.failNextSave`입니다. 식별자를 분리한 것은 적절합니다. 진단 오버레이는 path가 비었을 때만 보이므로 여러 개가 일치하는 문제를 피합니다.
- **권고 R4**: 포기 안내 낭독은 `.onChange(of: notice)`에 의존합니다. NavigationStack 루트 뷰가 살아 있어야만 발화하므로 다음 두 가지를 UI 테스트에 명시합니다.
  - 포기 직후 `test.announcements`의 항목 수 증가분이 정확히 1이어야 합니다.
  - 재실행 뒤 같은 문구가 낭독 기록에 없어야 합니다(AC-22, BR-10).
- **AC 매핑**: AC-1, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-16의 안내, AC-22, AC-23, AC-24, AC-25, AC-32(카드 한 요소와 별도 버튼, 포기 안내 1회 낭독), AC-35.

#### UITestBootstrap (lifecycle 시드, `--fm-ui-journey`, UITestWriteCounter)
- **레이어**: 테스트 인프라라 점수 대상이 아닙니다.
- **확인 사항**:
  - `modelStore.writeData`(`UITestBootstrap.swift:189-191`)의 첫 줄에서 세면 실패 주입보다 먼저 세므로 실패한 시도도 셉니다.
  - 시드 `prepare()`는 별도 `LocalSnapshotStore`라 세지 않습니다.
  - `applySaveScenario`가 실행 시 하는 쓰기는 카운터에 들어가지만, 차이(diff)로 단언하므로 무해합니다.
  - 카운터는 프로세스마다 0부터 시작하므로, 재실행을 넘어서 비교하면 안 됩니다.
- **권고 R5**: 파라미터 시드의 잘못된 입력(방향 0, 분 361, 경과가 total보다 큼, 카탈로그 밖 ID)이 `test.setupError`를 내는지 UI 테스트 1건으로 확인합니다. 시드가 조용히 통과하면 모든 매핑 테스트가 거짓 양성이 됩니다.

### 특히 평가할 항목

1. **alert 버튼 접근**: 가능합니다. 이미 동작이 확인된 패턴(`.accessibilityIdentifier`를 붙인 alert 버튼, 제목 label로 alert 찾기)이 있습니다. 설계의 `alertButton(_:)` 도우미는 identifier와 label을 같이 매칭하도록 만듭니다.
   - 연타 한계: alert 버튼은 첫 탭에 사라지므로 XCUITest에서 진짜로 "두 번 탭"할 수는 없습니다.
   - AC-11과 AC-21의 '그만두기' 2회는 `doubleTap()`으로 최대한 재현하고 쓰기 diff 1과 path를 단언합니다. 실제 보장은 단위 테스트(모델 가드, `hasFinished`, R2)가 맡는다고 테스트 주석에 적습니다.
   - `journey.abandon`과 `main.resumeJourney`의 연타는 `doubleTap()`으로 실제 재현할 수 있습니다.
2. **test.writeAttempts**: 관측할 수 있습니다. RootView `testDiagnostics` 오버레이는 모든 화면에 있습니다.
   - **권고 R6**: alert가 떠 있는 동안 뒤쪽 진단 요소를 XCUITest가 읽을 수 있다는 근거가 저장소에 없습니다. 기존 테스트는 모두 alert를 닫은 뒤에 읽습니다(`CardCustomizationFlowTests.swift:65-77`).
   - AC-6, AC-14, AC-27의 "열린 동안 저장값 불변·쓰기 0"은 열기 전 값과 안전 버튼으로 닫은 직후 값의 차이로 단언하는 것을 기본 경로로 정합니다. 안전 버튼 자체의 쓰기 0은 AC-7·15와 단위 테스트가 따로 증명합니다.
   - 열린 상태에서 읽기가 되면 보강 단언으로만 둡니다.
3. **수동 시계와 재실행**: 결정적입니다.
   - 재실행하면 수동 시계가 0으로 돌아가므로, AC-28의 "3600초 뒤"는 "종료 중 시간이 더해지지 않음"과 같은 단언(24 min, 90, paused=true)으로 대체합니다. 설계 F-13 그대로이고 타당합니다.
   - **권고 R7**: AC-29의 "5초 진행"용 `test.clock.advance5` 버튼은 없습니다. 있는 것은 1, 10, 60, 600, armForeground600입니다(`JourneyView.swift:148-152`). `h.advance(1, times: 5)`로 쓴다고 매핑을 고칩니다.
   - AC-30은 armForeground600을 누르고 `goBackground()`를 한 뒤 relaunch(manual)하면 되고, 기존 W05 패턴입니다.
4. **VoiceOver 포커스·낭독**:
   - 낭독(AC-32의 이어가기 1회, 포기 안내 1회)은 `test.announcements`로 자동화됩니다.
   - 포커스 복귀(AC-15)는 R3을 적용하면 컨트롤러 상태로 단위 테스트와 UI 테스트 양쪽에서 결정적이 됩니다.
   - 대화상자가 열릴 때 처음 포커스가 가는 위치(AC-6, AC-14, AC-27 후반, AC-32 일부)는 시스템 alert라 XCUITest로 관측할 수 없습니다.
     - 대체 관측: 안전 버튼이 `role: .cancel`인지는 코드 리뷰로 확인하고, 버튼 문구와 존재는 UI 테스트로 봅니다.
     - 실제 첫 위치는 W14 실기기 점검으로 넘기고 trust-ledger에 기록합니다. 질문 2에서 (a)를 고르는 경우입니다. (b) 앱 전용 창을 고르면 포커스 의도를 R3과 같은 컨트롤러 상태로 둘 수 있어 자동화가 가능해집니다.
5. **대화상자 중 백그라운드(AC-27)**: 자동화할 수 있습니다.
   - `goBackground()`(home 후 activate, `UITestLaunchSupport.swift:155-159`)를 하고 alert가 남아 있는지 `waitForExistence`로 봅니다.
   - 저장값과 쓰기 0은 R6의 방식(안전 버튼으로 닫은 뒤 diff)으로 봅니다.
   - 포기 대화상자는 일시정지 상태라 `enterBackground`가 쓰지 않으므로 결정적입니다.
   - 포커스 부분은 4번과 같이 자동화할 수 없습니다.

### 자동 테스트로 확인할 수 없는 항목과 대체 관측
| AC | 불가 부분 | 대체 |
|---|---|---|
| AC-6, 14, 27, 32 | alert가 열릴 때 VoiceOver 첫 포커스 | `role: .cancel` 코드 리뷰, 버튼 문구·존재 UI 테스트, W14 실기기 점검(trust-ledger) |
| AC-32 | 실제 청취(전환 알림에 묻히는지) | `test.announcements` 1회, W14 |
| AC-28 | 실제 3600초 경과 | 재실행 시 시계 리셋 + (90, paused, 24 min) 동치 단언 |
| AC-11, 21 | alert 버튼 진짜 2회 탭 | `doubleTap` 최대 재현 + 단위 가드 테스트가 1차 보장 |
| AC-18(나) | 기대값 미확정 | 질문 1의 답 필요(테스트 차단 요인) |
| AC-33 | 44pt "가려지지 않음"의 시각 판단 | `isHittable`, frame 높이 44 이상 단언, 레이아웃 붕괴는 범위 밖 |

### Testability Score: 8/10 (동작 컴포넌트 대상)
- **가점**:
  - 순수 규칙과 값 타입을 분리했습니다.
  - 프로토콜(`JourneyAbandoning`)을 주입하고 Fake 패턴을 씁니다.
  - 모델은 store 주입만으로 테스트됩니다.
  - 연타 방지가 시간 기반이 아니라 상태 기반입니다.
  - 이어가기 신호가 1회용이라 검증할 수 있습니다.
  - UI 쪽은 쓰기 수, 저장값, 낭독 진단과 실패 주입 순서를 명시했습니다.
- **감점**:
  - (−1) 시스템 alert의 첫 포커스는 관측할 수 없습니다(구조적 한계, 대체 관측 있음).
  - (−1) 뷰 접착부(autoStart 합성식, 포기 안내 onChange 낭독, alert 바인딩 순서)는 XCUITest로만 검증됩니다. 포커스 진단이 FocusState 원값에 의존하는 문제는 R3으로 해소할 수 있습니다.

### 판정
TESTABILITY PASS입니다. 설계를 확정하고 red-green-refactor로 들어갈 수 있습니다. 진입 전에 아래를 반영해 주세요(구조 변경이 아니라 테스트 계약 보강입니다).
- **R1**: Probe를 `attempts`와 `writes`로 나눕니다.
- **R2**: 컨트롤러에서 confirm과 cancel의 두 순서를 단위 테스트로 고정합니다.
- **R3**: `JourneyAbandonController.focusTarget`을 두고, `test.abandon.focus`는 그 값을 보고합니다(DepartureBriefing 패턴).
- **R4**: 포기 안내 낭독은 증가분 정확히 1회, 재실행 뒤 0회를 단언합니다.
- **R5**: 파라미터 시드의 잘못된 입력이 `test.setupError`를 내는지 1건 확인합니다.
- **R6**: alert가 열린 동안의 불변은 안전 버튼으로 닫은 뒤 diff로 보는 것을 기본 경로로 둡니다.
- **R7**: AC-29는 `advance(1, times: 5)`로 매핑합니다.
- 차단 요인: AC-18(나)의 기대값(질문 1)이 정해져야 해당 RED를 쓸 수 있습니다.

### 탐색 추가 항목
- `ios/FocusMateUITests/CardCustomizationFlowTests.swift:521-554`: alert를 제목 label로 찾고, 버튼을 identifier와 label로 찾는 동작 확인된 패턴입니다. 진단은 닫은 뒤에 읽습니다.
- `ios/FocusMate/JourneyView.swift:82, 172-180`, `ios/FocusMateUITests/DepartureBriefingUITests.swift:53`: 포커스를 컨트롤러 상태로 진단하는 패턴입니다(R3 근거).
- `ios/FocusMate/JourneyTimerView.swift:101`: FocusState 원값 진단인데, 이를 단언하는 UI 테스트가 없습니다(R3 근거).
- `ios/FocusMate/JourneyView.swift:146-159`: 수동 시계 버튼은 1/10/60/600/armForeground600뿐이고, `test.failNextSave`는 여행 화면에만 있습니다(R7, 메인 전용 arm이 필요한 근거).
- `ios/FocusMate/UITestBootstrap.swift:173-200, 229-246`: writeData 주입 지점, announcer=recorder, failNextSave 서비스 연결입니다.
- `ios/FocusMate/RootView.swift:239-256`: `testDiagnostics` 오버레이(`test.announcements`, 그리고 `test.writeAttempts`를 추가할 위치)입니다.
- `ios/FocusMateUITests/UITestLaunchSupport.swift:33-37, 134-159`: relaunch는 인자를 초기화하므로 수동 시계를 다시 넘겨야 합니다. failNextSave 순서와 goBackground도 여기 있습니다.
- `ios/FocusMateTests/JourneyTimerModelTests.swift:10-28`: Probe는 성공한 쓰기만 기록합니다(R1 근거).