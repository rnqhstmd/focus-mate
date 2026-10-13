## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인 또는 테스트명) |
|----|-------|------|
| AC-1 | ✅ | RootView.swift:48-49, InitialStationSearchView.swift:36 / `FirstStationSearchUITests.testInitialSearchScreenShowsAllThreeResultsAndDisabledConfirm`, `StationSearchStateTests.test_초기_상태는_3건_결과이고_선택_확정이_없다` |
| AC-2 | ✅ | RouteData.swift:68-74 / `StationCatalogTests`의 서울숲·건대·성수 3건, UI `testQueryNarrowsResultsByStationNameAndByDirectionName` |
| AC-3 | ✅ | RouteData.swift:69-70 / `StationCatalogTests`의 trim·공백만·빈 문자열 3건, UI `testQueryWithSurroundingWhitespaceStillMatchesTrimmedText` |
| AC-4 | ✅ | InitialStationSearchView.swift:17-19, 36 / UI `testNoMatchShowsEmptyMessageAndConfirmCannotSaveAnything`: 비활성 확인을 탭해도 persistedBytes가 같음 |
| AC-5 | ✅ | StationSearchState.swift:10 / UI `testSelectingResultShowsConfirmationMarksSelectedAndEnablesConfirm` |
| AC-6 | ✅ | AppModel+JourneyStart.swift:24-31 / `JourneyStartModelTests.test카드만_발급된_상태에서_역방향_성수역을_확정하면…`: 쓰기 바이트를 디코드해 확인 |
| AC-7 | ✅ | AppModel+JourneyStart.swift:29 / UI `testKeyboardPathSearchSelectConfirmOpensTimeScreenWithSavedStation` (키보드가 올라온 상태) |
| AC-8 | ✅ | InitialStationSearchView.swift:28-31, RootView.swift:15, UITestBootstrap.swift:49 / `StationSaveFailureUITests` 2건, 단위 테스트의 실패 후 재시도 |
| AC-9 | ✅ | `PreparationFlowUITests.testRelaunchAfterSavingStationOpensMainAndNeverShowsSearchAgain`: 네 화면 모두에 `search.*`가 0건 / 단위 `test이미_첫_정거장이_있으면_확정을_거부…` |
| AC-10 | ✅ | JourneyPlanner.swift:16,21-23, TimeSelectionView.swift:27 (휠 범위가 15…360뿐) / `JourneyPlanDraftTests` 경계 clamp, UI `testWheelBoundariesReportFifteenAndThreeSixtyMinutes` |
| AC-11 | ✅ | JourneyPlanDraft.swift:33 / UI `testEntryShowsDefault25Minutes…`. 2.75km는 단위 테스트로 확인 (Ruling T6) |
| AC-12 | ✅ | `JourneyPlannerTests.test_120분은_버스_3건을_순서대로_반환한다`, UI `testSixtyToOneTwentyMinutesShowsAllThreeCandidates` |
| AC-13 | ✅ | `JourneyPlannerTests.test_24분은_2014를_제외하고…` |
| AC-14 | ✅ | `JourneyPlannerTests.test_최소_15분…`, `test_최대_360분…` |
| AC-15 | ✅ | `JourneyPlannerTests.test_성수역_역방향_60분…` |
| AC-16 | ✅ | `JourneyPlannerTests.test_서울숲역_정방향_60분…` |
| AC-17 | ✅ | JourneyPlanDraft.swift:64 / UI `testMinutesWithoutCandidatesShowDisabledProceedThatDoesNotNavigate` |
| AC-18 | ✅ | UI `testProceedWithoutSelectionAsksForSelectionAndStaysOnTimeScreen` |
| AC-19 | ✅ | UI `testSelectingCandidateMarksOnlyThatOneAndEnablesProceed` |
| AC-20 | ✅ | JourneyPlanDraft.swift:37-42 / UI `testChangingMinutesClearsSelectionImmediately` (대기 없이 단언), 단위 61→60 해제 유지 |
| AC-21 | ✅ | AppModel+JourneyStart.swift:35-39, DestinationScreen.swift:36-44 / UI `testProceedingWithSelectedBusOpensPreparationWithSelectionAndNoActiveJourney` |
| AC-22 | ✅ | AppModel.swift:24 (journeyPlan을 모델에 보관), RootView.swift:58 / UI `testReturningFromPreparationKeepsSelection…` (ready 시드, 출발지 "서울숲") |
| AC-23 | ✅ | JourneyPlanner.swift:12, TimeSelectionView.swift:26 (휠에 수정자 없음) / UI `testCandidateAndProceedExposeReadableAccessibilityLabels`, 휠 spike 60→61. VoiceOver 1칸 이동은 설계상 수동 확인 항목인데 기록이 없다 (Part 2 Important 3) |
| AC-24 | ✅ | `LargeTextUITests` 2건 (XXXL에서 확인·진행 isHittable, 저장값·전달값 확인). 두 화면 코드에 `withAnimation`·`scrollTo`·`.transition`이 0건이라 즉시 갱신된다 (TimeSelectionUITests:116 무대기 단언). 동작 줄이기를 켠 실행은 수동 확인 항목인데 기록이 없다 (Important 3) |
| AC-25 | ✅ | AppSnapshot.swift:35-37 (updatingStage가 세 영역을 복사) / 단위 AC-6 테스트, 진행 시 쓰기 0회, UI에서 `journey.active` null |
| AC-26 | ✅ | `PreparationFlowUITests.testSelectionIsNotPersistedAcrossRelaunchAndStoredBytesStayUnchanged`: 25분·선택 0건·bytes 동일 |

[Must] 26건 중 26건 충족. [Should] AC는 0건이다. BR-6은 AppModel.save 단일 경로를 써서 충족한다.

## 설계 범위 이탈
- **UI 테스트 파일 분리**: 설계는 `FirstStationTimeFlowTests.swift` 한 파일이었다. 실제로는 5개 파일로 나뉘었다. 태스크 분해 때 승인된 사항이라 이탈로 보지 않는다 (state.md:49). 다만 설계 후속 인계(design.md:482)가 존재하지 않는 파일명을 가리킨다 (Minor N5).
- **TimeSelectionView.swift:60-70 (T8)**: 접근성 글자 크기에서 후보에 "{번호} · {도착지}"만 보인다. 설계 판단 6("화면에는 유형·번호, 도착지, 분, 정류장 수, 거리를 보여 줍니다")과 FR-7에서 벗어난다. Important 1로 다룬다.
- **InitialStationSearchView.swift:32-37**: 확인 버튼에 `.safeAreaInset` 대신 VStack 하단 배치를 썼다. 효과는 같다 (t4 Minor 유지).
- **설계 산출물 누락**: T8의 "동작 줄이기·VoiceOver 한 칸 이동 수동 확인 기록"이 없다 (Important 3).

## Part 1 판정
26건 모두 ✅ → **SPEC PASS**

---

## Part 2: 코드 품질 리뷰

### T8 결정의 적절성 판단 (FR-11·QE)
- **제목·현재 분 상한(accessibility1)**: 적절하다. 제목은 상단 바 제목과, 현재 분은 휠 값과 같은 정보라서 정보 손실이 없다.
- **진행 버튼 상한(accessibility2)**: 수용 가능하다. QE-1의 차단 이유 문구는 그대로 큰 글자로 보인다. 다만 작은 기기에서의 확인이 남았다 (Minor N2).
- **후보 화면 문구 축약**: 부적절하다. 원인은 "버튼 프레임 중앙이 가시 영역 밖이라 XCUITest 탭이 닿지 않음"이었다 (t8-impl.md:10). 그런데 정보를 숨겨 테스트를 통과시켰다. 큰 글자 사용자는 VoiceOver를 쓰지 않는 저시력 사용자가 다수다. 이들은 유형·정류장 수·거리를 볼 수 없게 되어 FR-7 표시 요구가 깨진다. 구현자 스스로도 "디자인 확인 필요"로 남겼다. 아래 Important 1로 다룬다.

### Critical (0건)
없음.

### Important (3건)

1. **TimeSelectionView.swift:60-70 — 접근성 글자 크기에서 후보 정보 일부가 사라진다** → [동작불변]
   - 문제: 버스 유형, 분, 정류장 수, 거리가 화면에서 사라진다. FR-7("각 후보에는 버스 유형·표시 번호, 도착지, 분, 정류장 수, 거리(km)를 보여준다")과 설계 판단 6에서 벗어난다. 테스트의 탭 방식에 맞추려고 구현을 바꾼 형태다.
   - 권고: 정보는 모두 유지한다. 예를 들어 "{유형} {번호} · {도착지}" / "{정류장}정류장 · {거리}" 두 줄로 압축하거나, 고정 영역 높이를 줄인다. 도달성은 레이아웃으로 확보하고, LargeTextUITests가 그대로 통과하는지 확인한다. 그래도 축약이 필요하다면 사용자(디자인) 승인을 decisions.md에 Ruling으로 남긴다.

2. **InitialStationSearchView.swift:41-56, TimeSelectionView.swift:55-78 — 선택 상태가 눈에 보이지 않는다** (t4 Minor 승격) → [동작불변]
   - 문제: 두 화면 모두 선택된 버튼과 아닌 버튼이 똑같이 `.bordered`다. 선택 표시는 VoiceOver의 `.isSelected` 트레이트뿐이다. 시간 화면에서 눈으로 보는 사용자는 어느 버스를 골랐는지 알 수 없다. 단서는 진행 버튼 문구 변화뿐이다. FR-8(하나만 선택)과 QE-1(다음 행동을 문구·화면으로 안다)에 비해 머지 전 수정이 필요하다. 검색 화면은 큰 글자에서 확인 문구가 스크롤 밖으로 밀릴 수 있다. 여기에 t2 Minor(검색어를 되돌리면 선택이 조용히 되살아남)가 겹치면 사용자가 모르는 선택으로 확인할 위험도 있다.
   - 권고: 선택 항목에 `.borderedProminent`나 체크 아이콘처럼 상태 값과 무관한 시각 구분을 넣는다.

3. **수동 확인 기록 누락 (design.md:346, 351, 427, 472)** → [동작불변]
   - 문제: VoiceOver 1분 증감(AC-23)과 "동작 줄이기"를 켠 상태의 동작(AC-24)은 설계가 자동 검증 대신 실기기 수동 확인 기록으로 남기기로 한 항목이다. 피처 디렉터리에 trust-ledger나 그에 해당하는 기록이 없다. state.md에도 언급이 없다.
   - 권고: 머지 전에 수동 확인 결과(기기, iOS 버전, 결과)를 trust-ledger에 기록한다. 확인할 수 없다면 미검증 항목으로 명시한다.

### Minor (28건) — 전부 [동작불변], 비차단

**이번 리뷰 신규 (7건)**
- N1. JourneyStartModelTests.swift:128 — `choose(busID:from:)`가 `@discardableResult`가 아니어서 "result unused" 경고가 난다. helper가 선택 성공도 단언하지 않는다. `XCTAssertTrue(...)`로 감싼다.
- N2. TimeSelectionView.swift:12-35 — 휠(120pt)과 진행 버튼을 하단에 고정해서, 작은 기기(iPhone SE급)에서 XXXL일 때 스크롤 영역이 매우 좁아질 수 있다. `[검증 필요]` 가장 작은 지원 시뮬레이터에서 `LargeTextUITests`를 실행해 본다.
- N3. FirstStationSearch·StationSaveFailure·TimeSelection·PreparationFlow·LargeTextUITests — 같은 helper를 5개 파일이 각자 복제한다 (`element`, `value`, `diagnosticValue`, `snapshot`, `parseObject`, `launch`, 검색→시간 진입 helper). 기존 UI 테스트도 파일마다 자급하는 관례라 Minor로 둔다. `StorageTestSupport.swift`처럼 공용 UI 지원 파일로 빼는 방안을 검토한다.
- N4. LargeTextUITests.swift:13 — 테스트 이름은 "WithoutScrolling"인데 결과 항목은 `reach()`로 스와이프한다. 스크롤 없이 닿는다는 단언은 확인 버튼에만 해당하므로 이름을 고친다.
- N5. design.md:374, 449, 482 — W03 인계가 존재하지 않는 `FirstStationTimeFlowTests`를 가리킨다. 실제 위치는 `PreparationFlowUITests.testPreparationScreenExposesOnlyTheBackButtonAndNoCompletionAction`이다. 인계 문구를 고친다.
- N6. DestinationScreen.swift:24-44 — 프로덕션 뷰에 테스트 전용 진단(`test.journeySelection`)이 있다. `#if DEBUG`로 막혀 있고 기존 `test.snapshot` 관례와 설계 승인을 따른 것이라 Minor로 둔다.
- N7. TimeSelectionUITests.swift:54, 137-150 — 테스트 이름 "SixtyToOneTwenty"는 실제 동작(120으로만 설정)과 맞지 않는다. 경계 테스트도 15·360을 두 번 맞출 뿐 실제 감소·증가 시도는 없다. 휠 범위 구조와 단위 clamp가 보장하므로 결함은 아니다.

**태스크 리뷰 유예분 — Minor 유지 (21건)**
- t1 (4건): `distanceText`의 `%02d` 분기 미검증("6.05km"), `BusLine.id` 미검증, `String(format:)`의 Foundation 의존, `StationOption.init` 인덱스 무검사.
- t2 (4건): 검색어를 되돌리면 선택이 되살아남 (Important 2를 고치면 위험이 줄어든다), 360 상한 clamp 시 선택 유지 케이스 없음, `candidates` 반복 재계산, `originUnavailable`이 문구만 테스트됨 (T3에서 도달 경로 검증됨).
- t3 (2건): 보존 단언이 빈 시드라 영역이 지워져도 통과함 (AC가 빈 값을 명시하므로 Minor 유지), `proceedToPreparation`이 `.time` 경로 위치를 확인하지 않음.
- t4 (6건): `.safeAreaInset` 미사용, 제목에 `.isHeader` 없음, `@MainActor struct` 중복 표기, 뒤로 버튼을 `navigationBars.buttons.firstMatch`로 찾음, AC-2·3 일부의 UI 대응 테스트 없음 (단위로 커버), `[검증 필요]` delete 키 IME 안정성.
- t5 (3건): 실패 문구가 나타날 때 VoiceOver 알림 없음, 다른 정류장을 골라도 이전 실패 문구가 남음, 두 실패 테스트의 준비 코드 중복.
- t6 (2건): spike의 20초 임계값 (`[검증 필요]` 느린 CI), 뷰가 `journeyPlan.choose`를 직접 호출함 (설계 인터페이스와 일치).

**해소 확인 — 집계 제외 (3건)**
- t3 `allCases`에 `.time` 노출: 유일한 사용처인 AppFoundationTests.swift:220은 cardEntry 상태라 `open`이 아무것도 하지 않는다.
- t6 Phase1 "여행 준비" 행 삭제: 설계상 의도된 변경이다. 재실행 후 `여행 준비 → screen.time` 경로는 PreparationFlowUITests:106이 덮는다.
- t6 휠 높이: T8에서 하단 고정 레이아웃으로 처리되었다.

## Part 2 판정
Critical 0, Important 3 → **QUALITY FAIL**. Important 3건은 모두 [동작불변]이라 implementer 정리 경로로 가면 된다. 3번은 수동 기록이라 사용자 확인이 필요하다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 26
  ac_met: 26
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 3
  important_behavior: 0
  minor: 28
```