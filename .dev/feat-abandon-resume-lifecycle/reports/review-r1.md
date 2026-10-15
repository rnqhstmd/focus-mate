## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인 또는 PRD 인용) |
|----|-------|------|
| AC-1 | ✅ | ActiveJourneyCardContent.swift(제목·할 일·버스·남은 시간·경로), MainActiveJourneyView.swift(카드 1요소 + 버튼 "이전 여정 이어가기 →"), RootView `mainStartTitle`. MainActiveJourneyCardUITests AC1 6건(할 일·태그 경로 포함, 임시 문구 없음). 화살표 "→"는 XCUITest로 관측할 수 없어 코드로 확인 |
| AC-2 | ✅ | `JourneyTimerDisplay.remainingMinutes`(올림)를 재사용. ActiveJourneyCardContentTests testAC2(0/1/60/61/1499) |
| AC-3 | ✅ | AppModel+JourneyLifecycle `resumeJourney`, JourneyView `ensureTimer`(`consumeResumeEntry` → autoStart). JourneyResumeUITests AC3 4건(path, pause만 있음, 24→23 min, 쓰기 +1) |
| AC-4 | ✅ | (90, paused=false)를 1회 저장. UI에서 150/paused와 resume·abandon 노출 확인. 기록 수는 단위 testAC31로 확인 |
| AC-5 | ✅ | `path.isEmpty` 가드. 단위 테스트(.rejected, attempts 1)와 UI doubleTap 2건 |
| AC-6 | ✅ | `newJourneyConfirmation`의 제목·본문·`role: .cancel` 유지 버튼. 첫 VoiceOver 포커스는 W14로 넘김(PRD 제외 범위와 일치) |
| AC-7 | ✅ | NewJourneyUITests AC7 3건(카드 남음, 쓰기 0, 바이트·정류장 불변) |
| AC-8 | ✅ | `confirmNewJourney` → `endingActiveJourney` 1회 저장 → `.time`. 단위와 UI에서 ttukseom/1, 여정 nil, 기록 1, 쓰기 +1 확인 |
| AC-9 | ✅ | NewJourneyUITests AC9 2건 |
| AC-10 | ✅ | `saveHandlingFailure` 실패 → `.saveFailed` → `main.saveFailure`. 재시도 후 AC-8 결과(UI) |
| AC-11 | ✅ | 단위: 두 번째 호출 `.rejected`, path `[.time]`. UI doubleTap에서 쓰기 +1, screen.time 1개 |
| AC-12 | ✅ | `startTripFromMain`. 단위와 UI(대화상자 없음, 쓰기 0) |
| AC-13 | ✅ | JourneyAbandonBar `if isPaused`. 출발 안내 단계에서는 `!awaitingDeparture`라 bar를 만들지 않음. UI 3건 |
| AC-14 | ✅ | 제목·본문·두 버튼·열고 닫아도 불변(R6). 첫 포커스는 W14 |
| AC-15 | ✅ | `cancel()`이 `focusTarget = .abandonButton`. UI에서 resume 노출과 진단 focus="abandon" 확인 |
| AC-16 | ✅ | `abandonJourney`: path [], notice, 1회 저장. UI에서 문구·정류장·저장값·낭독 +1·쓰기 +1 확인 |
| AC-17 | ✅ | JourneyReachTests 경계 표(0/299/300/600/1499, 302·421 노선). UI는 299/300 |
| AC-18 | ✅ | 단위와 UI(성수사거리/-1, 순환 성수역) |
| AC-19 | ✅ | 단위: 정류장 성수역, notice "성수역". UI: 정류장. 문구 형식은 AC-16 UI가 같은 함수로 확인 |
| AC-20 | ✅ | `journey.timer.saveFailure`, 머무름, 바이트 불변, 시도 +1, 재시도 성공 |
| AC-21 | ✅ | 컨트롤러 `isConfirming`·`hasFinished` 가드(단위, R2 두 순서). UI에서 alert 1개, 쓰기 +1 |
| AC-22 | ✅ | 재실행 뒤 카드·안내·낭독 없음, 뚝섬역 |
| AC-23 | ✅ | 출발 대기는 저장 없이 `open(.journey)`. 단위와 UI(briefing, remaining·abandon 없음). 새 여정 확정 시 출발지(단위) |
| AC-24 | ✅ | `reachedStation`이 도착이면 저장된 도착지를 씀. 카드에 이어가기 없음, 확정 시 seoulForestGate/1(단위·UI) |
| AC-25 | ✅ | W05의 버림 규칙 그대로. UI에서 카드 없음, "여행 시작하기", 실패 문구 없음. 불변 단언이 약한 문제는 t4 R1 Minor로 유예됨 |
| AC-26 | ✅ | 진행·일시정지·도착 3상태에서 뒤로가기 버튼 0개, 스와이프 뒤 유지 |
| AC-27 | ✅ | 두 alert 모두 백그라운드를 다녀와도 유지되고 쓰기·바이트 불변. 포커스는 W14 |
| AC-28 | ✅ | 두 alert 모두 재실행 뒤 24 min, 90, paused, 성수역. 3600초는 설계 F-13대로 대체 관측 |
| AC-29 | ✅ | 90..<100, paused=true |
| AC-30 | ✅ | 690 + pause, 재실행 뒤 paused, 690 이하(관측력이 약한 점은 Minor) |
| AC-31 | ✅ | 모든 경로에서 records 1건(단위 resume/confirm/abandon, UI 포기·새 여정·취소, 실패는 바이트 불변) |
| AC-32 | ✅ | "포기하기" 라벨, 카드 1요소와 별도 버튼, 이어가기 낭독 정확히 1회·화면에 없음, 포기 안내 낭독 +1. alert 첫 포커스는 W14 |
| AC-33 | ✅ | XXXL에서 remaining·resume·abandon이 hittable·44pt 이상, scrollViews 0. alert 버튼과 메인 버튼도 확인 |
| AC-34 | ✅ | 동작 줄이기에서 AC-3·8·16 반복 3건 |
| AC-35 | ✅ | `main.saveFailure`, path [], (90, true) 불변, 시도 +1, 낭독 없음. 재시도는 단위 테스트로 확인 |

[Must] 35건 중 35건 충족(AC-33·34는 [Should] 성격이나 함께 충족). [Should] FR-12·QE-1~3 충족. 실기기 VoiceOver 포커스(AC-6·14·27·32)는 PRD 제외 범위("W14, 이번에는 Simulator UI 테스트까지")에 맞춰 이관됐다. 코드는 `role: .cancel`로 안전한 선택을 기본으로 둔다.

## 설계 범위 이탈
- 경미 1건: `ios/FocusMateUITests/MainActiveJourneyCardUITests.swift`는 설계의 신규 UI 테스트 목록(4개)에 없는 추가 파일이다. 테스트 전용이고 T5 범위(AC-1·24·25·35 화면)라 수용 가능하다.
- `JourneyTimerView.swift`를 수정하지 않아 조건부 1줄 변경은 쓰지 않았다. "수정하지 않는 파일" 5개는 지켰다.
- `LifecycleSeed`에서 설계의 busID·minutes 필드를 빼고 2014번·25분으로 고정했다. 시드 표가 모두 2014번·25분이라 동작은 같다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

특히 확인한 항목:
- 포기 확정과 alert 바인딩 해제의 순서는 안전하다. `hasFinished`로 판정하고 `isConfirming`에 의존하지 않는다.
- 포기 뒤 pop의 `leave()`는 paused 분기라 쓰기가 없다.
- 이어가기 1회용 신호와 `timer == nil` 가드가 겹쳐 낭독은 1회다.
- `saveHandlingFailure`는 실패해도 일반 `saveFailure`를 남기지 않는다. 단위 테스트 3곳이 `XCTAssertNil(model.saveFailure)`로 고정한다.
- `test.main.failNextSave`는 RootView.swift:88-121의 `#if DEBUG` 안에 있다.

### Critical (0건)
없음.

### Important (1건)
- docs/FLOWS.md(diff 116행, W04 승차 절 마지막 항목) — "진행 여정이 있으면 메인에 '진행 중인 여정이 있어요' 안내가 뜬다(재실행·이탈 복귀 모두). 메인에는 이어가기 카드가 뜨고…" 이 diff에서 고친 줄인데, 이번에 없앤 임시 안내가 아직 뜬다고 적혀 있다. 바로 뒤 문장, 그리고 같은 문서 W07 절의 "임시 안내 대신 카드가 뜬다"와 모순된다. FLOWS는 화면 계약 문서라 W09/W06 작업자가 잘못된 계약을 읽게 된다. → [동작불변]
  - 권고: 앞 문장을 지우고 "진행 여정이 있으면 메인에 이어가기 카드가 뜨고(재실행·이탈 복귀 모두), 시작 버튼은 '새 여정 시작'이 되어 확인 창을 거친다."로 합친다.

T5 Important(UI 테스트 도우미 중복)의 decisions.md 유예 Ruling: 동의한다. 테스트 파일 안의 유지보수 문제이고 동작 영향이 없다. 후속 정리 권고는 그대로 유효하다.

유예된 태스크 Minor(t1/t3/t4/t5) 중 머지 전에 Important로 올릴 항목은 없다. AC-25 불변 단언이 약한 문제(t4 R1)는 W05 기존 동작이고 기존 W05 테스트가 받친다고 보아 유예를 유지한다.

### Minor (7건) — 전부 [동작불변], 비차단
- docs/CURRENT-STATE.md(diff 79행) — `.dev/feat-abandon-resume-lifecycle/reports/final-verification.md`로 링크하지만 현재 이 파일이 없다(reports/ 폴더에 없음). [검증 필요] 최종 검증 단계에서 만드는지 확인한다. 만들지 않으면 깨진 링크다.
- context/journey/status.md(diff 35, 43, 55, 56행) — `W07 [#TBD]` 자리표시자 4곳. PR 번호가 정해지면 바꿔야 한다.
- ios/FocusMateUITests/JourneyLifecycleSafetyUITests.swift testAC32_이어가기_카드는_한_요소이고… — `XCTAssertNotEqual(resume.identifier, cards.firstMatch.identifier)`는 리터럴 id 두 개를 비교하는 항상 참 단언이라 별도 요소임을 증명하지 못한다. 실제 근거는 `cards.count == 1`과 `buttons["main.resumeJourney"]` 존재다. 권고: 이 줄을 지우거나 카드 label에 버튼 문구가 없음을 단언한다.
- ios/FocusMateUITests/NewJourneyUITests.swift testAC12 2건 — "진행 여정 없음" 전제를 손상 시드 `v3InvalidMinutes`(BR-9 버림 동작)로 만든다. AC-12가 BR-9 구현에 묶여 있어 BR-9가 회귀하면 AC-12가 엉뚱한 이유로 실패한다. 권고: 여정이 없는 `ready`/`cardOnly` 시드를 쓴다.
- ios/FocusMateUITests/JourneyResumeUITests.swift testAC30_백그라운드에서_600초가… — AC-30의 "백그라운드 진입 시 (90, paused=false) 저장"을 백그라운드 전에 읽은 값(이어가기 저장)으로 단언한다. 백그라운드 저장이 일어나지 않아도 통과한다. 권고: `goBackground` 직전·직후 `writeAttempts` 증가 +1을 단언한다.
- ios/FocusMateUITests/UITestLaunchSupport.swift `persistedState()` — `(root["state"] as? [String: Any]) ?? root`로 대체하는 관대한 파싱이라 저장 형식이 바뀌어도 조용히 다른 사전을 읽을 수 있다. 권고: 실제 v4 구조 하나만 받는다.
- ios/FocusMate/AppModel+JourneyLifecycle.swift `mainStartTitle`/`confirmNewJourney` (확신 낮음) — `activeJourney`는 있는데 `ActiveJourneyCardContent.init?`이나 `reachedStation`이 nil이면 카드 없이 버튼만 "새 여정 시작"이 된다. 확정은 `.rejected`라 안내도 없고 새 여정을 시작할 수 없는 막힌 상태가 된다. 현재는 `validate`가 카탈로그 id를 보장해 도달할 수 없는 경로로 보인다. 권고: 방어가 필요하면 `mainStartTitle`과 버튼 분기를 `activeJourneyCard != nil` 기준으로 맞춘다.

## Part 2 판정
Critical 0, Important 1 → QUALITY FAIL. Important 1건은 문서 1줄 정리라 implementer 정리 모드로 처리할 수 있다.

관련 파일:
- /Users/bonseung/Documents/ChatGPT/new-w07/docs/FLOWS.md
- /Users/bonseung/Documents/ChatGPT/new-w07/docs/CURRENT-STATE.md
- /Users/bonseung/Documents/ChatGPT/new-w07/context/journey/status.md
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/AppModel+JourneyLifecycle.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/JourneyLifecycleSafetyUITests.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/NewJourneyUITests.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/JourneyResumeUITests.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/UITestLaunchSupport.swift

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 35
  ac_met: 35
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 0
  minor: 7
```