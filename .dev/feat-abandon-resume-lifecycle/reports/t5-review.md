## Part 1: AC 충족 매트릭스

| AC / 항목 | 충족도 | 근거 |
|---|---|---|
| AC-3 | ✅ | AppModel+JourneyLifecycle.swift:14-24 (저장 후 open(.journey)), JourneyView.swift:30-33 (autoStart 1회용 신호). JourneyResumeUITests AC3 4건 |
| AC-4 | ✅ | resumeJourney가 (90, paused=false) 저장. 테스트: 저장값 90/false, 60초 뒤 일시정지 시 150/true, resume·abandon 동시 노출. 완료 기록 수 불변은 이 파일에서 단언하지 않음(단위 테스트가 커버한다고 판단) |
| AC-5 | ✅ | resumeJourney의 path.isEmpty 가드 + UI 연타 테스트 2건 |
| AC-13 | ✅ | JourneyAbandonBar.swift:26 (isPaused일 때만 렌더). 진행·일시정지·재개 후·도착·출발 안내 5개 상태 테스트 |
| AC-14 | ✅ (포커스 단언 없음, 아래 참고) | 제목·본문·버튼 id/문구 테스트, 열기→취소 시 쓰기·바이트 불변 |
| AC-15 | ✅ | 닫힘, resume 노출, 포커스 의도 진단 |
| AC-16 | ✅ | 안내 문구, 카드 없음, 저장 정류장 ttukseom/방향 1, 기록 1건, 낭독 +1, 쓰기 +1 |
| AC-17 | ✅ | UI는 0/299/300초만, 1499초·강남02·343번은 단위 테스트(BR-1)가 근거 |
| AC-18 | ✅ | 역방향 300초 → 성수사거리/-1, 순환 900초 → 성수역 |
| AC-19 | ⚠️ 경미 | 0초 정류장만 단언, 안내 문구("성수역에서 …") 단언 생략. 기능은 AC-16과 같은 경로 |
| AC-20 | ✅ | 머무름, journey.timer.saveFailure 문구, resume 존재, 안내 없음, 바이트 불변·시도 +1, 재시도 성공 |
| AC-21 | ✅ | 연타 UI 테스트는 alert 1개와 쓰기 +1 확인. alert 버튼은 첫 탭에 닫혀 진짜 2연타 재현 불가(주석에 명시), 1차 보장은 hasFinished/.rejected 단위 테스트 |
| AC-22 | ✅ | 재실행 후 카드 없음, 뚝섬역, 안내 없음, 낭독 0회 |
| AC-23 | ✅ | 쓰기 0회, journey.briefing 노출, remaining·abandon 없음 |
| AC-26 | ✅ | 진행·일시정지·도착 3개 상태에서 뒤로가기 0개, 스와이프 후 유지 |
| AC-27 | ✅ (포커스 단언 없음) | 두 alert 모두 백그라운드 왕복 후 유지, 안전 버튼으로 닫아도 쓰기·바이트 불변 |
| AC-28 | ✅ | 두 alert 모두 재실행 후 카드, 24 min, 경과 90, paused, 정류장 불변 |
| AC-29, AC-30 | ✅ | 90 이상 100 미만과 paused 복원, 690초와 pause 버튼, 재실행 후 paused와 690 이하 |
| AC-31 | ✅ | 포기 경로의 메모리·저장 기록 1건 |
| AC-32 | ✅ | 라벨 "포기하기", 카드 1요소와 별도 버튼, 이어가기 낭독 정확히 1회와 화면 미노출 |
| AC-33 | ✅ | 최대 글씨에서 remaining·resume·abandon isHittable, 높이 44 이상, scrollView 0개, alert 버튼, 메인 버튼 |
| AC-34 | ✅ | 동작 줄이기에서 AC-3·AC-8·AC-16 반복 3건 |
| BR-5, BR-6, BR-8 | ✅ | JourneyAbandonController.request의 isPaused·hasFinished·isConfirming 가드, abandonJourney(timerPaused:) 가드. 연타는 상태로 막음 |
| FR-2 | ✅ | resumeAnnouncement 1회 낭독, 화면 문구 아님 |
| FR-10 | ✅ | NavigationPopBlocker와 뒤로가기 숨김 유지. 나가는 길은 포기뿐 |
| FR-12 | ✅ | 아래 포커스 참고 |

[Must] 전부 충족. [Should] FR-12는 포커스 자동 검증 한계로 부분 증명.

포커스 단언 한계(AC-14, AC-27, AC-32 / FR-12): 시스템 alert의 첫 VoiceOver 포커스는 XCUITest로 단언할 수 없다. 테스트 주석에서 W14로 이관한다고 밝혔다. 구현은 .cancel 역할 버튼을 쓰므로 시스템 기본 포커스에 맞는다. PRD가 "실기기 VoiceOver는 W14"로 제외한 범위와 일치하므로 ✅로 판단했다. 오케스트레이터는 product-owner에 PRD 보강(AC-14·27·32의 포커스 항목을 W14 수동 점검으로 명시)을 권고하면 좋다.

## 설계 범위 이탈
이탈 없음. 변경은 JourneyAbandonBar.swift(신규), JourneyView.swift, UI 테스트 4개와 헬퍼. design.md는 크기 제한으로 읽지 못했고 PRD, diff, 컨트롤러·모델 소스로 대조했다.

## Part 1 판정
모든 AC ✅ (경미한 ⚠️ 1건: AC-19 안내 문구 단언 생략) → SPEC PASS

## Part 2: 코드 품질 리뷰

특히 볼 것 항목 판정:
- alert 바인딩 set(false)와 확정 버튼 순서: 안전. confirm은 isConfirming에 의존하지 않고 hasFinished로 판정한다. cancel이 먼저 와도 .done 뒤 focusTarget이 nil이 되고, 나중에 와도 hasFinished가 막는다. 실패 시 포커스는 어느 순서든 abandon으로 수렴한다.
- 포기 후 pop 중 onDisappear leave(): 안전. 포기 시점은 항상 .paused이고 leave()의 .paused 분기는 ticker.stop()만 한다. 저장 경합 없음.
- 이어가기 1회용 신호: 안전. consumeResumeEntry가 ID 일치 시 1회 소비하고 ensureTimer의 timer == nil 가드와 겹쳐 낭독도 1회.
- 출발 안내 단계의 하단 safeAreaInset: 비어 있다. awaitingDeparture이거나 timer == nil이면 Bar가 만들어지지 않는다.
- 실패 문구 식별자 중복: !timer.showsTransitionFailure 가드로 해소.

### Critical (0건)
없음.

### Important (1건)
- JourneyAbandonUITests.swift, JourneyLifecycleSafetyUITests.swift, JourneyResumeUITests.swift — 동일 도우미가 파일마다 복사되어 있다. resumeFromMain(3파일 동일), launchPaused(2파일, extra 인자만 차이), announcementLines/lines(2파일 동일). 한 곳을 고치면 나머지가 어긋난다. → [동작불변]
  - 권고: UITestLaunchSupport.swift의 FocusMateUIHarness 확장(이미 launchLifecycle, alert(titled:)가 있음)으로 resumeFromMain, launchPausedByResume(seed:extra:), announcementCount(equalTo:)를 옮긴다.

### Minor (6건) — 전부 [동작불변], 비차단
- JourneyAbandonBar.swift:46-47 — 일시정지가 아닐 때도 빈 VStack에 .padding(.bottom, 8)가 남아 약 8pt가 예약된다. JourneyView.swift:62 주석 "일시정지가 아니면 높이 0"과 다르다. 일시정지 전환 시 타이머 영역이 밀리는지 [검증 필요: JourneyTimerUITests 또는 스냅샷]. 권고: 패딩을 isPaused/실패 문구 표시 시에만 주거나 주석을 고친다.
- JourneyAbandonBar.swift:33 — 포기 버튼에 .dynamicTypeSize(...accessibility3) 상한이 걸려 최대 접근성 글씨보다 작게 그려진다. 타이머 버튼과 일관된 의도로 보이나 QE-2 취지와 상충할 소지가 있다. 확신 낮음.
- JourneyAbandonBar.swift:17-18 — State(initialValue: JourneyAbandonController(...))는 부모 재평가마다 버려질 컨트롤러를 만든다. 동작 영향 없음.
- JourneyAbandonUITests.swift:285-293 — AC-15 포커스 테스트가 실제 @AccessibilityFocusState가 아니라 컨트롤러 의도(flow.focusTarget)를 진단으로 읽는다. 뷰 바인딩이 끊겨도 통과할 수 있다(주석에 한계 명시). 실포커스는 W14 수동 점검.
- JourneyAbandonUITests.swift AC-16, AC-19, AC-20 — path 값과 AC-19 안내 문구를 직접 단언하지 않고 화면 존재로 대체한다.
- W06 머지 충돌 위험(JourneyView.swift:62-65) — W06도 JourneyScreen의 ZStack과 .accessibilityElement 사이 modifier 체인(.safeAreaInset/overlay)을 건드릴 가능성이 높다. 머지 시 하단 safeAreaInset이 지도 도구와 포기 바로 겹치는지 확인하고, 하단 슬롯을 VStack으로 합치는 방식을 권고한다. 또한 AC-28·AC-29의 "시계 3600/600초 뒤 재실행"이 manualClockArguments 재실행에서 실제로 시계를 앞당기는지 [검증 필요: relaunch 구현]. 현재 단언은 시계가 정지해도 통과해 "종료 중 시간 미가산" 증명력이 약할 수 있다.

## Part 2 판정
Critical 0 + Important 1 → QUALITY FAIL (Important 1건은 테스트 헬퍼 DRY 정리로 implementer 정리 모드 대상)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 21
  ac_met: 20
  ac_partial: 1
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 0
  minor: 6
```

관련 파일:
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/JourneyAbandonBar.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/JourneyView.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/JourneyAbandonController.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/AppModel+JourneyLifecycle.swift
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/UITestLaunchSupport.swift