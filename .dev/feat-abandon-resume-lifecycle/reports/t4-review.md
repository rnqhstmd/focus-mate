## Part 1: AC 충족 매트릭스 (태스크 범위: 메인 화면 AC)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-1 | ⚠️ | 구현은 충족한다. 카드 제목·할 일·버스·남은 시간·"태그 · 도착지까지"가 `ActiveJourneyCardView`(MainActiveJourneyView.swift:11-37)와 `ActiveJourneyCardContent`에 있다. 버튼은 "이전 여정 이어가기 →"이고 라벨은 화살표 없는 "이전 여정 이어가기"다. 시작 버튼은 `mainStartTitle`로 "새 여정 시작"이 된다. 임시 안내 문구는 RootView에서 삭제됐다. 테스트가 AC의 Then을 다 덮지 못한다. `testAC1_일시정지_여정은_이어가기_카드로_보인다`는 제목·"24 min 남음"·"지선 2014"·"서울숲 입구까지"만 단언한다. 저장된 할 일과 태그 이름은 단언하지 않는다. 버튼의 보이는 문구("→" 포함)도 단언하지 않는다. 라벨만 단언한다. |
| AC-6 | ✅ | alert 제목·본문·두 버튼 문구와 id는 `newJourneyConfirmation`(MainActiveJourneyView.swift:64-73)과 NewJourneyUITests가 맞춘다. 안전 버튼이 `.cancel` 위치다. 포커스 단언은 설계가 W14로 넘긴 범위다. 열기 전과 닫은 직후의 값 비교는 AC-7 테스트가 한다. |
| AC-7 | ✅ | 닫힘·메인 유지·카드 유지 단언이 있다. 쓰기 시도 수 불변과 persistedBytes 동일 단언이 있다(NewJourneyUITests:723-736). 현재 정류장 표시 불변 단언도 있다. |
| AC-8 | ✅ | `confirmNewJourney`가 `endingActiveJourney`로 1회 저장한다. 테스트가 `ttukseom`·방향 1, 여정 삭제, 기록 1건 유지, `screen.time`, 카드 없음, 쓰기 정확히 +1을 단언한다. |
| AC-9 | ✅ | 재실행 후 카드 없음, "뚝섬역", 방향 1, 버튼 문구가 "새 여정 시작"이 아님을 단언한다. |
| AC-10 | ✅ | `apply(.saveFailed)`가 `main.saveFailure`를 띄운다. 테스트가 실패 문구, 메인·카드 유지, 바이트 불변, 시도 +1을 단언한다. 재시도 시 AC-8 결과와 시도 +2도 단언한다. |
| AC-11 | ✅ | 모델 가드(`path.isEmpty`)가 1차 보장이다. UI 테스트는 doubleTap, 쓰기 +1, 화면 1개를 단언한다. alert 버튼은 첫 탭에 닫히므로 진짜 두 번 탭은 불가능하다는 한계가 주석에 있다. |
| AC-12 | ✅ | 여정이 없으면 `startTripFromMain()`을 바로 호출한다. 테스트가 alert 없음과 쓰기 0회를 단언한다. |
| AC-24(카드·확정) | ✅ | 도착 카드는 "도착한 여정이 있어요"이고 이어가기 버튼이 없다. 버튼 문구는 "새 여정 시작"이다. 확정하면 `seoulForestGate`·방향 1이 되고 여정은 삭제되며 기록은 1건 그대로다. |
| AC-25 | ⚠️ | 카드 없음, 문구가 "여행 시작하기"임, "불러오지 못했어요" 없음은 단언한다. 카드 수만 `cardCount > 0`으로 보고, AC의 "완료 기록·현재 정류장은 그대로"는 단언하지 않는다. |
| AC-35(메인 안내) | ✅ | 메인 유지, `main.saveFailure` 문구, `screen.journey` 없음, 저장값 90·paused=true, 시도 정확히 +1, 이어가기 낭독 없음을 단언한다. "저장을 성공으로 바꾸고 다시 누르면 AC-3·4 결과"는 T5 범위로 본다. |
| AC-32(카드 한 요소·별도 버튼·포기 안내 1회 낭독) | ✅ | 카드는 `.combine` 한 요소이고 버튼은 형제 요소다. `MainAbandonNoticeView`는 항상 배치되어 `onChange`에서 1회 `announce`한다. 낭독 횟수 증가분(+1) 단언은 이 태스크 테스트에 없다. 포기 흐름은 T5 소관이다. |
| BR-7 | ✅ | `apply`가 `.saveFailed`면 true로 두고, `.rejected`는 안내를 바꾸지 않는다. |
| BR-8 | ✅ | 모델 가드로 막는다. 한계는 AC-11에 적었다. |
| BR-10 | ✅ | `abandonNotice`는 메모리 전용이다. 안내 뷰는 상태 변경만 받는다. |

[Must] AC-1·25가 ⚠️이고 나머지는 충족이다. 구현 결함은 아니고 테스트 단언 누락이다.

## 설계 범위 이탈
이탈 없음. 변경 파일은 MainActiveJourneyView(신규), RootView, UITestBootstrap, 각 테스트다. 설계서의 변경 범위 표와 일치한다. F-12(life* 시드 10종, `UITestWriteCounter`를 writeData 첫 줄에서 기록, `test.writeAttempts`, `test.main.failNextSave`와 `path.isEmpty` 노출 조건)도 설계와 맞다. 시드 값은 설계 표와 일치하고, 설계서가 실제 시드 이름 9개(`lifeAwaiting` 포함 10개)를 적은 대로다. 도착지는 식과 일치시켰고 현재 정류장은 출발지, 기록은 1건이다.

## Part 1 판정
SPEC FAIL. AC-1·AC-25의 Then 일부가 테스트로 검증되지 않는다. 구현 변경은 필요 없고 단언 보강이면 된다.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (2건)
- ios/FocusMateUITests/MainActiveJourneyCardUITests.swift:514-523 (AC-1 테스트) — 카드의 할 일과 태그 이름("독서") 단언이 없다. 버튼의 보이는 문구("이전 여정 이어가기 →")도 단언하지 않는다. 이대로면 `ActiveJourneyCardContent`가 이 필드들을 빼도 테스트가 통과한다. → [동작결함] (재구현 대상 — AC-1)
  - 권고: 시드 task "생명주기 시드"와 "독서 · 서울숲 입구까지"를 카드 label에서 단언한다. 버튼 `staticTexts` 또는 title의 "→"를 확인한다.
- ios/FocusMateUITests/MainActiveJourneyCardUITests.swift:568-576 (AC-25 테스트) — 손상 시드에서 완료 기록 수와 현재 정류장 불변을 단언하지 않고 `cardCount > 0`만 본다. → [동작결함] (재구현 대상 — AC-25)
  - 권고: `persistedRecordCount`, `persistedCurrentStation`을 시작 전 값과 비교한다.

### Minor (4건) — 전부 [동작불변], 비차단
- ios/FocusMate/MainActiveJourneyView.swift:54-58 — `onChange`에서 `focused = true`와 `announcer.announce`를 둘 다 호출한다. 포커스 이동이 텍스트를 읽고 announce도 읽으면 VoiceOver에서 이중 낭독될 수 있다. 같은 변경 순간에 Text가 막 생기므로 포커스 바인딩이 아직 붙지 않았을 수도 있다. 확신이 낮다. [검증 필요] 포기 안내 낭독이 정확히 1회인지는 `test.announcements` 증가분 단언(T5의 AC-16/32 테스트)에서 확인한다.
- ios/FocusMate/UITestBootstrap.swift:439-445 — `UITestWriteCounter.record()`가 `writeData` 클로저에서 불린다. 이 클로저가 메인 스레드가 아닌 곳에서 호출되면 `@Observable` 변경이 메인이 아닌 스레드에서 일어난다. 기존 `nextFailure.consume()` 패턴과 같은 수준이고 현재 UI 36 pass다.
- ios/FocusMate/RootView.swift:139-143 — 시작 버튼 클로저에서 `activeJourney != nil` 분기를 뷰가 직접 판단한다. `mainStartTitle`과 같은 조건이 모델과 뷰 두 곳에 있어 어긋날 여지가 있다. 모델에 `startAction`처럼 한 곳으로 모으는 것이 좋지만 동작은 맞다.
- ios/FocusMateUITests/NewJourneyUITests.swift:690-696 — AC-6 본문 테스트가 alert 제목을 단언하지 않고 `alert(titled:)` 존재만 쓴다. 이 경로가 사실상 제목을 확인하므로 결함은 아니다. 가독성상 제목 단언을 명시하면 좋다.

## Part 2 판정
QUALITY FAIL (Important 2건, 모두 테스트 단언 누락이며 AC-1·25 재구현과 함께 처리).

```yaml
spec_verdict:
  verdict: FAIL
  ac_total: 11
  ac_met: 9
  ac_partial: 2
  ac_unmet: 0
  unmet_ids: [AC-1, AC-25]
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 2
  important_behavior: 2
  minor: 4
```

(ac_total 11은 AC-1, 6, 7, 8, 9, 10, 11, 12, 24, 25, 35이다. AC-32는 부분 범위, BR은 보조 항목이라 계수에서 뺐다. AC-32는 ✅다.)

## 재리뷰 R1

## 재리뷰 판정

| 항목 | 판정 | 근거 |
|------|------|------|
| (1) AC-1 카드 할 일·태그 경로·버튼 보이는 문구 단언 누락 | ADDRESSED | 할 일과 태그 경로는 `MainActiveJourneyCardUITests.swift:144-151`(r1 diff 기준)의 `testAC1_카드는_저장된_할_일과_태그_경로를_보인다`가 "생명주기 시드"와 "독서 · 서울숲 입구까지"를 카드 label에서 단언한다. 버튼의 보이는 "→"는 `accessibilityLabel` 덮어쓰기 때문에 XCUITest로 볼 수 없다. 그래서 `:155-163`이 낭독 라벨 "이전 여정 이어가기", "→" 없음, `isHittable`, 높이 ≥44를 단언한다. 소스 `MainActiveJourneyView.swift:25`에 `resumeButton`("이전 여정 이어가기 →")이 `.frame(minHeight: 44)`와 함께 있고, `JourneyLifecycleText.swift:9`가 문구를 확인해 준다. |
| (2) AC-25 기록 수·현재 정류장 불변 단언 누락 | ADDRESSED | `:206-223`의 `testAC25_손상_여정_버림은_기록_수와_현재_정류장을_바꾸지_않는다`가 `persistedRecordCount`와 `persistedCurrentStation().id` 불변, 카드 없음, `main.currentStation` 표시값 불변을 단언한다. 약점은 아래 Minor에 적었다. |

## Part 1: AC 충족 매트릭스 (태스크 범위: AC-1, AC-25, AC-33 중 메인 이어가기 버튼 44pt)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-1 | ✅ | 카드 제목·버스·"24 min 남음"·도착지 단언은 `:109-118`, 할 일·태그 경로는 `:144-151`에 있다. 이어가기가 카드와 별도 버튼인 것과 라벨은 `:121-127`, "새 여정 시작" 문구는 `:130-133`, 임시 안내 없음은 `:136-141`이 확인한다. 보이는 "→"는 코드 `MainActiveJourneyView.swift:25`로 확인했다. XCUITest 관측 불가 한계는 테스트 주석에 적혀 있고 W14 시각 점검으로 넘겼다. |
| AC-25 | ✅ | 카드 없음과 문구 "여행 시작하기"는 `:185-193`, "불러오지 못했어요" 없음은 `:196-203`, 기록 수·현재 정류장 id 불변은 `:206-223`이 단언한다. |
| AC-33 (메인 이어가기 버튼 44pt) | ✅ | `:162`가 `resume.frame.height >= 44`를 단언한다. 소스는 label 내부 `frame(minHeight: 44)`(`MainActiveJourneyView.swift:25`)다. 재현 RED가 높이 34pt로 실패해 실제 결함을 잡았고 수정 후 14/14 pass라고 보고됐다. 이 판정은 코드를 읽은 것이고 테스트는 재실행하지 않았다. |

[Must] 3건 중 3건 충족 (AC-33은 메인 이어가기 버튼 44pt 부분만), [Should] 해당 없음.

## 설계 범위 이탈
이탈 없음. 수정 diff는 `MainActiveJourneyView.swift`의 버튼 frame 한 줄과 테스트 파일뿐이다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (4건) — 전부 [동작불변], 비차단
- `MainActiveJourneyCardUITests.swift:206-223` — AC-25 불변 테스트는 기준값(`recordsAtStart`, `persisted`)을 앱을 켠 뒤에 읽는다. 손상 여정은 켜는 순간 버려지므로, 그 시점에 기록이나 정류장이 바뀌어도 이 테스트는 잡지 못한다. 또 `shown`을 `persisted.id`와 비교하지 않고 "비어 있지 않음"만 본다. 주석의 "표시가 저장값과 어긋난다"를 검증하지 못한다. 확신이 낮고 시드 기준값(기록 1건 등)과 비교하면 더 강해진다.
- `MainActiveJourneyCardUITests.swift:155-163` — 보이는 화살표 "→"는 자동 검증이 없고 코드 리뷰·W14 시각 점검에 의존한다. 한계는 주석에 명시돼 있다.
- 이전 라운드에서 넘어온 Minor가 남아 있다. 모두 비차단이다.
  - `MainAbandonNoticeView`의 `focused = true`와 `announce`가 이중 낭독될 수 있다. [검증 필요] T5의 낭독 증가분 단언으로 확인한다.
  - `RootView`의 `activeJourney != nil` 분기가 `mainStartTitle`과 중복된다.
  - `UITestWriteCounter.record()`가 어느 스레드에서 호출되는지 확인이 필요하다.
- `MainActiveJourneyView.swift:24-29` — `Button` 뒤 수정자 줄의 들여쓰기가 일관되지 않다. 가독성 문제다.

## Part 2 판정
QUALITY PASS (Critical 0, Important 0, Minor만 있음)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 3
  ac_met: 3
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 4
```