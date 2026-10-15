## Trust Ledger

### 위험 수용
- [기준선 전체 테스트 생략] 사용자 지시("전체 돌리지 말고 구현한 거 통과면 다음 단계")로 기준 GREEN은 main 6b7d4b7(W05 머지) 상태를 신뢰. 빌드·경고 5만 측정 (implement/Step 0.5)
- [태스크 분해 승인 게이트 생략] 설계 승인 시 PR 전까지 확인 없이 진행하기로 사용자 승인 (implement/Step 1.2)
- [alert 첫 VoiceOver 포커스] 시스템 alert라 시뮬레이터에서 관측 불가 — W14 실기기 점검으로 이관(사용자 결정) (design)
- [T6 RED 실행 생략] T6(JourneyLifecycleSafetyUITests)은 T4·T5가 구현한 동작의 생명주기·접근성 교차 검증이라, T5 이전 상태에서도 일부(새 여정 alert)는 통과가 예상됨. UI 15건 RED 단독 실행(약 6분)을 생략하고 typecheck 0 error + T5 GREEN 이후 focused 통과로 판정 — 사용자 속도 요청 반영 (implement/T6 verify_red)
- [T5 RED 일부 통과] 46건 중 41 실패, 5건 통과(AC-3·5 이어가기 경로, AC-13·23 출발 대기). 통과분은 T3·T4가 이미 구현한 이동·출발 안내 동작을 확인하는 케이스로, 잘못된 테스트가 아니라 앞 태스크가 범위를 먼저 덮은 것 — 재작성하지 않고 유지 (implement/T5 verify_red)

## 통합 감사 (review)

감사 범위: PRD 전체, diff 앞부분(문서와 앱 소스 전부, diff.txt 1~870행), 저장소의 실제 소스(AppModel, JourneyTimerController, AppModel+JourneyTimer, JourneyView, RootView, JourneyServices, JourneySnapshot, RouteData, AppSnapshot), W05 trust-ledger를 확인했다.
확인하지 못한 것:
- design.md는 열람 예산 제한으로 헤딩, 위험, DEBUG 관련 줄만 확인했다.
- diff.txt의 테스트 코드(870행 이후)는 읽지 않았다. 테스트가 실제로 통과하는지는 미확인이다.
- Release 빌드는 실행하지 않았다.

CRITICAL과 HIGH 사항은 없다. 코드가 PRD의 BR-4, BR-5, BR-6, BR-7, BR-8을 지키는 것은 확인했다.
- 현재 정류장 변경과 여정 삭제는 `endingActiveJourney` 한 스냅샷을 `store.save` 한 번으로 저장한다.
- 저장 실패 시 `saveHandlingFailure`가 false를 반환해 `.saveFailed`가 되고, 이동과 상태 변경 없이 안내만 한다.
- 연타는 `path.isEmpty`와 `path.last == .journey` 가드로 막힌다.
- 포기는 `isPaused` 가드로 `JourneyAbandonController`와 `abandonJourney(timerPaused:)` 두 곳에서 강제한다.
- 도달 정류장 계산(`JourneyReach`)은 BR-1 수식, 순환, 음수 방향(`wrap`)을 올바르게 처리한다.
- 어떤 W07 경로도 `records`를 건드리지 않는다.

### 발견 사항
- [GAP/MEDIUM] 도착 상태 타이머 화면에 나가는 길이 없다 (FR-10과 W09 미구현의 결합).
  - 근거: 도착 화면에서는 뒤로가기가 숨겨져 있고(`goBack` 가드, `NavigationPopBlocker`), 포기하기는 일시정지에서만 보인다(`JourneyAbandonBar`의 `isPaused`). 1500초를 끝까지 채운 사용자도 앱을 강제 종료해야만 메인으로 간다. 이 상태에서는 완료 기록도 없다.
  - 권고: PRD가 허용한 임시 상태이므로 결함은 아니다. 다만 W09 이전 사용자 배포를 막는 출시 게이트로 plan.md나 ledger에 명시한다.
- [GAP/MEDIUM] 체크포인트 저장 실패 후 포기하면 도달 정류장이 화면에 보인 진도보다 뒤처질 수 있다.
  - 근거: `JourneyTimerController.stopForSaveFailure`는 컨트롤러만 일시정지로 만들고 저장값은 paused=false와 마지막 저장 경과(최대 10초 전)에 남는다. 이때 포기하기가 노출되고, `abandonJourney`는 컨트롤러의 현재 진도가 아니라 `snapshot.journey.active`의 저장 경과로 `reachedStation`을 계산한다(`JourneyReach.swift`). 정류장 경계에서는 사용자가 본 것보다 한 칸 적은 정류장이 저장될 수 있다.
  - 권고: 이 상태에서는 포기 버튼을 숨기거나, "진도 저장 실패 상태에서는 마지막 저장 지점 기준"임을 BR-1에 명시한다.
- [GAP/MEDIUM] `saveJourneyProgress`에 경과 단조성과 도착 불변 가드가 없다 (W05 이월 항목, W07이 재진입을 도입했지만 가드는 미추가).
  - 근거: `AppModel+JourneyTimer.swift:14-19`는 id와 phase만 확인하고 이번 diff에서 변경되지 않았다. 컨트롤러가 항상 새로 생성되므로 현재 경로에서 도달은 어렵다.
  - 권고: `elapsed >= 저장 경과`와 `isArrived` 후 쓰기 거부를 추가하거나, 계속 이월 사유를 기록한다.
- [GAP/MEDIUM] 백그라운드에서 시스템이 프로세스를 종료한 경우의 안내가 여전히 없다 (W05 이월 항목).
  - 근거: W07 코드에 해당 문구나 분기가 없다. 이어가기 카드는 "잠시 멈춘 여정이 있어요. / N min 남음"만 보여 준다. 실제로는 백그라운드에서 시간이 흐르다 종료된 경우에도 마지막 저장 지점 값을 보인다.
  - 권고: 사용자 결정 사항으로 W14까지 이월을 유지하고, 필요하면 카드 문구를 결정한다.
- [ASSUMPTION/MEDIUM] DEBUG 코드가 릴리스 빌드에서 빠진다는 판단은 정적 확인뿐이다.
  - 근거 (정적으로 확인된 것):
    - `UITestBootstrap.swift`는 1행의 `#if DEBUG`부터 505행까지 전체를 감싼다.
    - W07이 추가한 `test.main.failNextSave`는 RootView의 `#if DEBUG`(88~121행) 안에 있다.
    - `test.writeAttempts`는 RootView의 `#if DEBUG`(262~317행) 안에 있다.
    - `test.abandon`은 `JourneyAbandonBar`의 `#if DEBUG` 안에 있다.
    - `JourneyServices`의 `testClock`과 `failNextSave`도 `#if DEBUG` 안에 있다.
    - `lifecycleSeeds`, `UITestWriteCounter`, 쓰기 계수는 `UITestBootstrap.swift`(DEBUG 전체 감싸기) 안에 있다.
    - 신규 프로덕션 파일 6개(`MainActiveJourneyView`, `ActiveJourneyCardContent`, `JourneyLifecycleText`, `JourneyAbandonController`, `JourneyReach`, `AppModel+JourneyLifecycle`)에는 `test.` 식별자나 UITest 참조가 없다.
  - 근거 (미확인): Release 구성 빌드나 심볼 확인 기록이 `.dev/feat-abandon-resume-lifecycle` 안에 없다("Release"와 "릴리스" 문자열 검색 결과 0건).
  - 권고: 출시 전에 `xcodebuild -configuration Release` 빌드와 `nm`/`strings`로 `test.`, `fm-ui`, `lifeP` 문자열이 없는지 확인한다. 이 게이트는 W14에 둔다.
- [GAP/MEDIUM] 새 여정 확정이 `.rejected`이면 아무 반응이 없다.
  - 근거: `confirmNewJourney`는 `reachedStation == nil`이면 `.rejected`를 반환하고, RootView의 `apply`는 `.rejected`에서 아무것도 하지 않는다. 사용자는 확정을 눌러도 아무 변화도 보지 못한다. 로드 시 카탈로그 검증을 거치므로 발생 가능성은 낮다.
  - 권고: `.rejected`와 `reachedStation == nil`을 오류 안내(또는 최소한 로그)로 연결한다.
- [GAP/MEDIUM] 포기하기 버튼과 저장 실패 문구의 글자 크기가 `.dynamicTypeSize(...accessibility3)`로 상한 고정되어 있다.
  - 근거: `JourneyAbandonBar.swift`의 포기 버튼과 `journey.timer.saveFailure` 텍스트. 최대 접근성 글씨(AX5)를 쓰는 저시력 사용자에게 오류 안내가 작게 보인다. 44pt 터치 영역은 충족한다.
  - 권고: 실패 문구는 상한을 풀거나, 상한을 둔 이유를 AC-33에 기록한다.
- [ASSUMPTION/MEDIUM] 확인 창을 열 때 VoiceOver가 안전한 선택에 처음 가는지, 낭독이 화면 전환 알림에 묻히지 않는지는 미검증이다.
  - 근거: 두 확인 창 모두 `.alert`이고 취소 버튼에 `role: .cancel`만 지정했다. 이어가기 낭독은 `ensureTimer`의 `onAppear` 시점이어서 push 전환과 겹친다. 포기 안내 낭독도 pop 전환과 겹친다. 이 위험은 ledger에 수용으로 기록되어 있다(design 위험 1, 2).
  - 권고: W14 실기기 점검 항목으로 유지한다.
- [POLICY/MEDIUM] 도착(완료) 여정에서 "새 여정 시작"을 확정하면 끝까지 마친 세션이 기록 없이 삭제된다.
  - 근거: FR-9와 사용자 결정 3에 따른 동작이고 확인 창은 거친다. 그런데 창의 본문이 도착 여정에도 "이전 여정은 그만두고 …"로 고정(`newJourneyMessage`)이라, 이미 마친 여정을 그만둔다고 표현한다.
  - 권고: 도착 여정에는 별도 본문을 두거나, W09 하차로 대체되기 전까지 위험 수용으로 기록한다.
- [GAP/MEDIUM] 손상된 진행 여정은 조용히 버려지고 원본 사본이 없다 (W05 이월, 미해소).
  - 근거: PRD BR-9와 AC-25가 같은 결정을 재확인하므로 사용자 결정으로 수용된 상태다. 카탈로그가 바뀌면 조용히 버려지는 구조도 그대로다.
  - 권고: 카탈로그 id 변경 금지 규칙은 유지한다.
- [GAP/MEDIUM] FLOWS.md의 같은 절에 모순되는 문장이 함께 있다.
  - 근거: `docs/FLOWS.md`(diff 115~116행)에 "메인에 '진행 중인 여정이 있어요' 안내가 뜬다"와 "메인에는 이어가기 카드가 뜨고"가 연달아 있다. 저장 형식 설명(117행)도 "버전 3"으로 남아 있다.
  - 권고: 구 임시 안내 문장을 삭제한다.

### 교차 검증 결과
- [정합] FR-3, FR-4, BR-4 — `AppModel+JourneyLifecycle.swift`의 `confirmNewJourney`가 `endingActiveJourney` 한 번의 저장으로 처리한다. `startTripFromMain`은 진행 여정이 있으면 거부한다(`AppModel+Boarding.swift`).
- [정합] FR-5, BR-6 — `JourneyAbandonBar`의 `if isPaused`, `abandonJourney(timerPaused:)`의 가드, 컨트롤러의 `request(isPaused:)`와 `confirm(isPaused:)`에서 확인된다.
- [정합] FR-7, BR-7 — `.saveFailed` 처리 후 이동하지 않고, 메인은 `main.saveFailure`, 타이머 화면은 `journey.timer.saveFailure`를 보인다.
- [정합] FR-10 — `goBack` 가드, `NavigationPopBlocker`, 뒤로가기 숨김이 그대로다. 나가기 버튼은 없다.
- [정합] FR-2 — `resumeJourney`가 paused=false를 1회 저장한 뒤 `open(.journey)`를 하고, `consumeResumeEntry`로 `autoStart`와 낭독이 1회만 일어난다.
- [정합] FR-8 — 출발 대기 여정은 저장 없이 `open`만 한다.
- [정합] FR-9 — 도착 여정은 `resumeJourney`에서 `.rejected`이고 `reachedStation`은 도착지다.
- [정합] BR-1, BR-2 — `JourneyReach.reachedStops`는 `min(몫, 총 정류장 수)`이고 `wrap`이 음수를 처리하며 방향은 여정 값을 그대로 쓴다.
- [정합] BR-10 — `abandonNotice`는 메모리 값이고 `open`과 `beginCardCustomization`이 지운다.
- [정합] FR-11 — 확인 창이 열려 있어도 확정 전에는 저장하지 않는다. 종료 후 `restingForLaunch`가 일시정지로 복원하고 종료 중 시간은 가산되지 않는다.
- [정합] 저장 형식 — v4 그대로이고 `records`는 W07 어느 경로에서도 건드리지 않는다.
- [불일치] 없음. 단 위 GAP 2번(체크포인트 실패 후 포기의 정류장)과 POLICY(도착 여정 문구)는 PRD가 침묵하거나 문구가 맞지 않는 부분이다.

### W05 이월 MEDIUM 6건 판정
1. 손상·카탈로그 불일치 여정 무음 폐기 — 잔존. PRD BR-9와 AC-25가 같은 결정을 재확인해 수용 상태다.
2. 백그라운드 후 프로세스 종료 안내 — 잔존. 코드와 문구가 없다.
3. 메인 시작이 확인 없이 정리 — 해소. 확인 창, `confirmNewJourney`, `startTripFromMain` 거부 가드로 처리됐다.
4. `saveJourneyProgress` 단조성과 도착 불변 가드 — 잔존. 재진입이 생겼지만 가드는 추가되지 않았다.
5. `JourneyTimerController.deinit`의 `MainActor.assumeIsolated` — 관찰 유지. 컨트롤러 소유 구조(`JourneyView`의 `@State`)가 그대로다.
6. DEBUG 훅 릴리스 제외 — 잔존. 정적 확인은 양호하지만 Release 빌드 증거는 없다.

### 탐색 추가 항목
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/JourneyServices.swift → DEBUG 전용 `testClock`과 `failNextSave` 선언 위치. Release 격리 확인 대상.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/FocusMateApp.swift → 테스트 부트스트랩의 `#if DEBUG` 분기(23~51행, 59~68행, 95~106행). Release에서 `testBootstrap`이 nil인지 확인 대상.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/CardCustomizationView.swift → `#if DEBUG`로 감싼 `testBootstrap` 프로퍼티(17~18행).

### 확인이 필요한 사항
1. 체크포인트 저장 실패 직후(타이머는 일시정지, 저장값은 paused=false인 상태)에도 포기하기를 노출해도 되는가?
   - 맥락: 이 상태에서 포기하면 도달 정류장이 저장된 경과(최대 10초 전) 기준이라 화면에 본 진도와 다를 수 있다.
   - 유형: 선택
   - 선택지:
     - (a) 숨김 (권장) — 저장이 복구되기 전에는 포기 불가
     - (b) 유지 — 마지막 저장 지점 기준임을 BR-1에 명시
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다
2. W09 이전에 사용자에게 배포되는 일이 있는가?
   - 맥락: 도착 상태 화면에 나가는 길이 없다. 앱을 강제 종료해야만 벗어난다.
   - 유형: 선택
   - 선택지:
     - (a) 없음, W07과 W09 묶음 출시 (권장) — 출시 게이트로 기록
     - (b) 있음 — 도착 화면에 임시 나가기 수단이 필요
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

### 감사 요약
- 총 11건 (CRITICAL: 0, HIGH: 0, MEDIUM: 11)
- 조치 필요 (배포 차단 사항은 없다. 출시 전 게이트: Release 빌드 확인과 W09 이전 배포 금지)

## 기계 판정 블록
```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 11
```
### 통합 리뷰 Part 2 요약 (review)
- [Quality/Important] docs/FLOWS.md 없어진 임시 안내 문장 — 정리 완료(문서)
- [Quality/Minor ×7] reports/review-deferred.md 로 유예

### 위험 수용 (review)
- [Mechanical Gate 전체 테스트 이월] 사용자 지시("마지막에 한 번만")로 phase-review 전체 테스트를 complete verify로 이월. W07 focused·관련 회귀는 통과 (review/Step 0)
- [출시 게이트] 도착 화면 나가기 없음 → W09 하차 전 사용자 배포 금지. Release 빌드 DEBUG 제외 실증은 W14 (review)

### 위험 수용 (complete/verify)
- [기존 실패 2건] ProfileUITests testAC20 최대 글자 크기 2건(메인에서 마이페이지 버튼이 스크롤 없이 닿지 않음)은 main 6b7d4b7에서도 같은 위치·메시지로 실패함을 별도 워크트리에서 재현 확인 — W07 회귀 아님. W05 때 전체 테스트를 건너뛰어 그때 생긴 것으로 추정, 후속 수정 필요(W14 전) (complete/Step -1)
- [verify 실행 방식] 전체 1회 실행 중 회귀 2종(DEBUG 버튼 겹침, 포기 안내 빈 자리) 발견 → 수정 후 사용자 지시("성공한 부분은 또 돌리지마")에 따라 실패·영향 테스트와 미실행 13개 UI 파일만 재실행. 통과한 스위트는 재실행하지 않음. 빌드 성공·경고 기준선 이하, 웹 테스트·빌드 통과 (complete/Step -1)
