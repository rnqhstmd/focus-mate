## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인 또는 PRD 인용) |
|----|-------|------|
| AC-1 | ✅ | JourneyTimerView.swift:41-67(지도·지표 3개·일시정지·도구 2개), JourneyMapView.swift:69 / JourneyMapUITests.swift:40 (alert 0 포함) |
| AC-2 | ✅ | JourneyTimerView.swift:69-85(왼쪽 위 일시정지, 오른쪽 세로 follow→theme), :129-143(좌·중·우) / JourneyMapUITests.swift:53 |
| AC-3 | ✅ (수동 대체) | 지도를 `accessibilityHidden`(JourneyMapView.swift:61)으로 숨겨 Legal을 찾을 수 없음. PRD AC-3 본문의 "찾지 못하면 M-1로 대체"와 trust-ledger [AC-3·AC-4 UI 단언 약화]에 해당. `.safeAreaPadding(.bottom, bottomInset)`(:54)로 구조상 표기를 하단 정보 위로 올림 |
| AC-4 | ✅ (체크리스트) | 체크리스트 직접 확인: JourneyMapView.swift:49-53(나침반·2D/3D·축척 3종 `.hidden`), :25(`interactionModes`에 `.pitch` 없음), UserAnnotation·MapUserLocationButton·CLLocationManager 없음. UI 단언(JourneyMapUITests.swift:75)은 ledger 기록대로 공허 통과 |
| AC-5 | ✅ | JourneyCourse.swift:23-43 / JourneyCourseTests test1~5 |
| AC-6 | ✅ | JourneyCourseProgress.swift:47-63 / ProgressTests test1~3 |
| AC-7 | ✅ | :55-56, :95-100 / ProgressTests test4·5 (출발 i 정방향과 출발 i+1 역방향 쌍) |
| AC-8 | ✅ | :49-54 clamp / ProgressTests test6 |
| AC-9 | ✅ | ProgressTests test7~9 (5·6·8분 버스) |
| AC-10 | ✅ | JourneyMapControllerTests test1 (실제 타이머·수동 시계 사용) |
| AC-11 | ✅ | JourneyCourseProgress.swift:49-53 / ControllerTests test2 |
| AC-12 | ✅ | JourneyMapController.swift:31-32, JourneyTimerView.swift:275 / ControllerTests test3 |
| AC-13 | ✅ | JourneyMapState.swift:8, :58 / ControllerTests test4. 2D 입력 경로 없음은 AC-4 체크리스트로 확인 |
| AC-14 | ✅ | JourneyMapView.swift:22-25 (setter의 `positionedByUser`) / JourneyMapUITests.swift:92 |
| AC-15 | ✅ | JourneyMapController.swift:49 / JourneyMapUITests.swift:103-109 |
| AC-16 | ✅ | JourneyMapState.swift:23-27 / StateTests test6 |
| AC-17 | ✅ | JourneyMapController.swift:40 / ControllerTests test7 |
| AC-18 | ✅ | JourneyMapState.swift:38-41 / StateTests test8 |
| AC-19 | ✅ | JourneyMapThemeSheet.swift:20-36 / JourneyMapUITests.swift:115 |
| AC-20 | ✅ | ThemeSheet:47-63 / UITests:127 |
| AC-21 | ✅ | ThemeSheet:23-36 / UITests:140 |
| AC-22 | ✅ | JourneyMapState.swift:15, :40, JourneyTimerView.swift:121 / UITests:160 |
| AC-23 | ✅ | JourneyMapState.swift:43, JourneyView.swift:27-30 (`map?.leave()` 연결 확인) / StateTests test10. UI 검증은 W07로 넘김(R-9) |
| AC-24 | ✅ | UITests:172 |
| AC-25 | ✅ | JourneyMapState.swift:29-32 / UITests:183 |
| AC-26 | ✅ | 컨트롤러에 저장 의존성 없음(JourneyMapController.swift:8-16) / UITests:206 |
| AC-27 | ✅ | JourneyView.swift:13 (`@State`에만 둠) / UITests:218, ControllerTests test8 |
| AC-28 | ✅ | UITests:230, ControllerTests test9 |
| AC-29 | ✅ | AppInfoLocationTests, UITests:46-47. 위치 API 사용 없음 |
| AC-30 | ✅ | JourneyMapState.swift:61-64, JourneyMapView.swift:57 / AccessibilityUITests:67, ControllerTests test10 |
| AC-31 | ✅ | AccessibilityUITests:76, ControllerTests test11 |
| AC-32 | ✅ | 동작 줄이기 값이 State에 없는 구조 / AccessibilityUITests:85, ControllerTests test12 |
| AC-33 | ✅ | JourneyMapView.swift:62-70 / AccessibilityUITests:106 |
| AC-34 | ✅ | JourneyTimerView.swift:113-127 / AccessibilityUITests:123 |
| AC-35 | ✅ | ThemeSheet:34, :60-61 / AccessibilityUITests:137 |
| AC-36 | ✅ | 코드: 도구·일시정지 48pt 고정(TimerView:104,117), 시트 컨트롤 `minHeight: 44`·`maxWidth: .infinity`, ScrollView 사용 / AccessibilityUITests:155. 시트 44pt 단언 누락은 Part 2 Minor로 올림 |
| AC-37 | ✅ (일부 수동) | 낭독 1회씩: AccessibilityUITests:188. 초기 포커스는 trust-ledger [AC-37 포커스 수동화]에 따라 M-2로 넘김. 코드는 :32, :153에서 포커스를 유지 |
| AC-38 | ✅ | W05 식별자와 "N min" 유지(TimerView:146-152, 238-250). W05 회귀 포함 UI 40/40(report 기준) + AccessibilityUITests:203 |
| AC-39 | ✅ | JourneyCourseProgress.swift:70-81 / ProgressTests test10~13, UITests:251 |
| AC-40 | ✅ (M-6 대체) | PRD AC-40과 ledger에 따라 대체. 구조 보장(컨트롤러에 저장·타이머 의존 없음)을 확인함 |

[Must] 39건 중 39건 충족 (AC-1~39), [Should] 1건 중 1건 충족 (AC-40, M-6 대체).

## 설계 범위 이탈
이탈이 없습니다. 설계 표 밖에 추가된 파일은 `ios/FocusMateTests/JourneyMapDisplayTests.swift` 하나인데, 설계서 Testability 절(JourneyMapDisplay 항목)이 이 분리를 권고했습니다. pbxproj, Info.plist, JourneyServices는 바뀌지 않았습니다. 설계 6번의 `.safeAreaPadding(.top, …)`은 빠졌지만, T0 스파이크 반영 절이 하단 패딩만 확정했으므로 이탈로 보지 않습니다.

## Part 1 판정
SPEC PASS. AC 40건이 모두 ✅입니다. AC-3·4·37·40은 PRD 본문 또는 trust-ledger가 인정한 수동·체크리스트 대체로 판정했습니다.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음. 태스크 리뷰에서 미뤄 둔 Minor(t1·t2·t3·t5·t6)를 다시 따져 봤지만, 머지 전에 꼭 고쳐야 할 항목은 없어 승격하지 않았습니다.
- t3의 "일시정지 중 매번 retarget": `MapSync`(status와 elapsed)가 바뀌지 않으면 sync가 호출되지 않습니다(JourneyTimerView.swift:56). 실제 낭비가 없습니다.
- t5의 "고정 폰트 크기": `@ScaledMetric`(JourneyTimerView.swift:19-21)으로 이미 해소됐습니다.

### Minor (12건) — 전부 [동작불변], 비차단
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift:172-181` — AC-36이 요구하는 시트 세 컨트롤의 "최소 44×44pt"를 단언하지 않고 hittable만 봅니다. 지금 코드(`minHeight: 44`)는 이 조건을 만족하지만 회귀를 잡지 못합니다.
  - 권고: 도구 버튼 루프처럼 width·height ≥ 44 단언을 추가합니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMateUITests/JourneyMapUITests.swift:75-87`, `JourneyMapAccessibilityUITests.swift:45-51` — 지도 전체가 `accessibilityHidden`이라 AC-4 금지 컨트롤 탐색과 AC-3 Legal 탐색이 항상 공허하게 통과합니다. ledger가 수용한 사항이지만, 테스트 이름이 실제 검증을 하는 것처럼 읽힙니다.
  - 권고: 두 테스트 주석에 "공허 통과, 실제 보증은 체크리스트·M-1"을 명시합니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyMapThemeSheet.swift:8, :44` — detent가 `.medium`으로 시작했다가 `onAppear`에서 `.large`로 바뀝니다. 큰 글자에서는 시트가 열리자마자 한 번 더 움직입니다. 설계는 "초기 detent를 large로" 두라고 했습니다.
  - 권고: `init`에서 환경값을 읽을 수 없다면, 시트를 띄우는 쪽에서 `dynamicTypeSize`를 넘겨 초기값으로 씁니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyTimerView.swift:56-58` — 백그라운드에서 돌아와 여러 정류장을 한 번에 건너뛸 때도 `linear(1s)`로 감쌉니다. 이때 버스가 코스를 무시하고 두 점 사이 직선(현)으로 1초간 미끄러집니다. 시각 문제일 뿐이고, BR-2의 "한 번에 이동"과는 어긋나지 않습니다. 확신은 낮습니다.
  - 권고: 경과 변화가 1정류장 구간보다 크면 애니메이션을 `nil`로 둡니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyMapView.swift:48` — `colorScheme .dark`를 위성(hybrid)에도 겁니다. 설계는 dark 테마에만 걸도록 했습니다. 앱이 전역 `.preferredColorScheme(.dark)`(RootView.swift:75)라 실제 영향은 없을 가능성이 큽니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyTimerView.swift:94, :214` — `"도착했어요"` 리터럴이 중복됩니다. :146의 "남은 시간"과 :158·:168의 " 개"·" km"도 `JourneyMapDisplay`/`JourneyTimerDisplay` 밖에 하드코딩돼 있습니다(t6에서 미룬 항목 포함).
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyView.swift:158-171` (DEBUG) — 수동 시계 버튼은 최대 6개 × 44pt = 264pt를 가운데에 둡니다. 375pt 폭 기기에서는 일시정지(x 16~64)와 도구 버튼(x 311~359) 영역에 걸칠 수 있습니다. DEBUG 전용이고 기준 기기에서는 겹치지 않습니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMateTests/JourneyMapDisplayTests.swift:28-48` — test4~7은 지도 값, 선택 상태, 스위치 값, 라벨 문구를 검증합니다. 해당 AC는 33·34·35인데 이름은 모두 `AC39`로 붙어 있어 추적이 어긋납니다.
- 테스트 이름 — 설계 컨벤션은 `testV<n>_AC<n>_<한국어>`인데, 새 테스트는 `test<N>_AC…`/`testAC…`를 씁니다. 저장소 안에서도 이미 두 방식이 섞여 있어(PreparationDraftTests, CardCustomizationFlowTests) 확신은 낮습니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMateUITests/JourneyMapUITests.swift:189` — "시트가 열리지 않음"을 고정 `Thread.sleep(0.5)` 뒤 한 번만 확인합니다. 부정 단언에 대기 시간이 고정돼 있어 느린 환경에서는 공허하게 통과할 수 있습니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyMapView.swift:12, :55` — 사용자가 지도를 회전하는 동안에는 `renderedHeading`이 `.onEnd`에서만 갱신됩니다. 그 사이 버스 아이콘 방향이 화면 기준으로 잠깐 틀립니다. 설계가 의도한 동작이며 기록용입니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyTimerView.swift:178` — 최대 글자 크기에서 `lineLimit(1)` + `minimumScaleFactor(0.6)` 조합 때문에 값이 잘릴 수 있습니다. t6에서 미룬 항목이고, M-4로 눈으로 확인할 대상입니다.

## Part 2 판정
QUALITY PASS. Critical 0건, Important 0건이고 Minor만 있습니다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 40
  ac_met: 40
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
  minor: 12
```
