## Part 1: AC 충족 매트릭스 (태스크 범위)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-1 | ✅ | `JourneyTimerView.swift` mapBody가 식별자 7개를 모두 부여한다. `testAC1`에 존재 확인과 알림 0건 확인이 있다. |
| AC-2 | ✅ | topBar는 좌상단 pause, 우상단 follow·theme(세로)이다. bottomInfo는 좌·중·우 HStack이다. `testAC2`가 frame 식을 그대로 검증한다. DEBUG 시계 줄을 overlay로 옮겨 상단이 밀리지 않는다. |
| AC-4 | ✅ | `mapControls`에서 MapCompass·MapPitchToggle·MapScaleView를 숨기고 `.pitch`를 interactionModes에서 뺐다. `testAC4`가 전수 조회한다. |
| AC-14 | ✅ | `JourneyMapView.swift`의 Binding setter에서 `positionedByUser`일 때만 `userMovedCamera()`를 호출한다. 앱 대입은 `@State`에 직접 하므로 setter를 거치지 않는다. `testAC14_15`가 실제 드래그와 앱 갱신 후 follow 유지를 확인한다. |
| AC-15 | ✅ | `followTapped()` 후 retarget이 일어나고 revision이 올라가 `onChange`로 카메라가 이동한다. 테스트가 진단의 camera와 bus 좌표 일치를 확인한다. |
| AC-19 | ✅ | `JourneyMapThemeSheet.swift`에 세 컨트롤이 있다. 기본값 dark와 켜짐을 `testAC19`가 확인한다. |
| AC-20 | ✅ | `themeButton`이 `isSelected` 특성과 값("선택됨" / "선택 안 됨")을 갖는다. `testAC20`이 확인한다. |
| AC-21 | ✅ | `visibleStops`만 비고, 경로(10점)·버스·도착 표시는 유지한다. `testAC21`이 진단으로 확인한다. |
| AC-22 | ✅ | `MapSync` onChange → `sync` → `timerStatusChanged`가 시트를 닫고 `toolsEnabled`를 false로 만든다. `.disabled`로 반영되며 `testAC22`가 확인한다. |
| AC-24 | ✅ | 도착 시 status가 `.running`이 아니므로 시트가 닫히고, 도구는 `status != .paused`라 활성이다. `testAC24`가 확인한다. |
| AC-25 | ✅ | 일시정지 시 버튼이 `.disabled`이고, 상태의 `openThemeSheet`에도 `guard toolsEnabled`가 있다(이중 방어). `testAC25`가 확인한다. |
| AC-26 | ✅ | 컨트롤러에 저장자가 없다. `testAC26`이 버전 4와 키 부재를 확인한다. |
| AC-27 | ✅ | `JourneyView`의 `@State map`은 화면 수명 동안만 유지된다. `testAC27`은 재실행으로 검증한다. |
| AC-28 | ✅ | `testAC28`이 저장 바이트와 타이머 값의 불변을 확인한다. |
| AC-29 | ✅ | `UserAnnotation`·위치 API가 diff에 없다. `AppInfoLocationTests`가 키 4종을 검사하며, 테스트 번들에 TEST_HOST가 설정돼 있어 `Bundle.main`은 앱 번들이다. |
| AC-39(화면) | ✅ | `journey.timer.stops`와 `journey.timer.distance`가 값 "5개" / "2.6km", "0개" / "0.0km"를 노출한다. `testAC39`가 확인한다. |

FR-1~12·14·15와 BR-4·5·6·8도 diff에서 충족을 확인했다.
- 도착지 불일치 시 `map == nil`이 되어 W05 배치(legacyBody)로 폴백한다.
- W05 식별자와 접근성이 그대로다. 라벨은 `JourneyTimerDisplay.accessibilityLabel`("타이머"), 값은 "남은 시간 N분"이고, `remainingFocused` 포커스도 유지된다.
- 정류장·거리 컬럼은 `journey.timer.*`로 노출되고, `journey.arrived`·`saveFailure`·`saveWarning` 식별자도 유지된다.
- FR-12 중 "큰 글자 최대 크기" 항목은 이 태스크의 AC에 대응 테스트가 없다(AC-36은 범위 밖). 아래 Minor에 적었다.

[Must] 해당 AC 16건 중 16건 충족. [Should] 해당 없음.

## 설계 범위 이탈

이탈 없음. 변경 파일은 설계서 대상(JourneyMapView·ThemeSheet·TimerView·JourneyView·UITestBootstrap)과 테스트뿐이다.
- 시드 도착지를 계산값으로 바꾼 것은 `CourseJourney.init?`의 손상 판정에 맞춘 필요 변경이다.
- DEBUG 시계 줄을 `safeAreaInset`에서 overlay로 옮긴 것은 report에 사유가 있고 `#if DEBUG` 안에 있다.

## Part 1 판정
모두 ✅ → **SPEC PASS**

## Part 2: 코드 품질 리뷰

API 사용은 iOS 17 기준으로 정확하다.
- `Map(position:interactionModes:)`, `MapPolyline`, `Annotation`, `annotationTitles(.hidden)`을 맞게 썼다.
- `mapStyle(.standard/.hybrid(elevation:pointsOfInterest:))`, `mapControls`, `onMapCameraChange(frequency: .onEnd)`도 맞다.
- 시트 닫힘 경로 세 갈래가 모두 상태로 수렴한다. 시스템 스와이프는 Binding setter, 닫기 버튼은 `dismissThemeSheet`, 일시정지·도착·이탈은 상태 전이다.
- DEBUG 진단(`mapDiagnostics`)과 `testControls`는 전부 `#if DEBUG` 안에 있다.

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (8건) — 전부 [동작불변], 비차단
- `JourneyTimerView.swift:228` — `withAnimation(linear 1s) { map.sync }`가 지도 상태 전체를 감싼다.
  - 이 클로저 안의 `toolsEnabled` 변화로 `.opacity(enabled ? 1 : 0.4)`가 1초 선형으로 서서히 바뀐다.
  - 카메라 이동은 `JourneyMapView.swift:133`의 `onChange`가 별도 `withAnimation`으로 처리한다. 그래서 바깥 transaction은 카메라에는 효과가 없다.
  - 권고: 버스 이동에만 필요한지 확인하고, 아니면 제거하거나 `status` 변경 경로를 분리한다.
  - [검증 필요] 일시정지 직후 도구 버튼 투명도 전환이 1초 걸리는지 확인한다. AC-22 테스트는 `isEnabled`만 본다.
- `JourneyTimerView.swift:320` 등 — 하단 정보와 라벨이 `.font(.system(size:))` 고정 크기라 Dynamic Type으로 커지지 않는다.
  - `ViewThatFits`의 세로 쌓임 폴백이 사실상 도달하지 않는다.
  - PRD 엣지 시나리오("큰 글자… 줄바꿈 또는 세로 쌓임")와 M-4에 영향이 있다. 디자인 스펙의 12/15/30은 웹 기준이다.
  - 권고: `@ScaledMetric` 또는 `relativeTo:`를 쓰고, M-4와 AC-36 단계에서 확인한다.
- `JourneyMapThemeSheet.swift:22-23` — `Button("닫기")` 바깥에 `.frame(minWidth: 44, minHeight: 44)`를 붙여서, 탭 영역은 44pt가 아닐 수 있다.
  - 권고: 라벨 안쪽에 frame과 `contentShape`를 둔다.
- `JourneyMapThemeSheet.swift:64`와 `JourneyTimerView.swift:323` — `accessibilityElement(children: .ignore)`를 쓴 버튼에서 `isButton` 특성이 유지되는지 확신이 낮다.
  - 권고: `.accessibilityAddTraits(.isButton)`을 명시하거나 실기기 VoiceOver(M-2)로 확인한다.
- `JourneyTimerView.swift:333,343` — `Text + Text` 연결은 새 SDK에서 deprecated 경고가 날 수 있다. 보간 `Text("\(…)")`로 바꾸는 것을 권고한다.
  - 시각 문구 " 개"에 공백이 들어 "5 개"로 보인다. 의도인지 확인한다.
- `JourneyTimerView.swift:259,265` — `roundControl`의 pause/resume `switch`가 `legacyControl`과 중복된다. 버튼 모양이 달라 큰 문제는 아니다.
  - `notices`의 정렬을 `.center`에서 `.leading`으로 바꾼 것이 W05 폴백 배치에도 적용된다. 폴백에서 여러 줄이 되면 W05와 모양이 달라질 수 있다.
  - 권고: 폴백에서는 기존 `.center`를 유지한다.
- `JourneyMapView.swift:103,118` 등 — 색상과 크기 리터럴이 인라인이고, 접근성 값 계산이 뷰에서 `JourneyCourse.stops[map.nextStopIndex]`에 직접 접근한다. 컨트롤러에 `nextStopName`을 두는 편이 낫다.
- DEBUG 시계 overlay가 상단 가운데에 있다.
  - 큰 글자나 도착 캡슐("도착했어요") 폭에 따라 상단 컨트롤과 가로로 겹칠 수 있다. 테스트 전용이다.
  - [검증 필요] T6 회귀에서 기존 W05·출발 안내 UI 테스트가 이 이동으로 깨지는지 확인한다.
  - [검증 필요] `UITestBootstrap` 시드 도착지가 `seongdongSportsCenter`에서 바뀌었다. 이 값을 기대하는 기존 테스트가 있는지 확인한다.
- 테스트 품질: `testAC25`의 `Thread.sleep(0.5)`는 부정 검증이라 불가피하지만 취약할 수 있다. `testAC1`의 springboard 알림 검사는 즉시 한 번만 본다.

## Part 2 판정
Critical 0 + Important 0 → **QUALITY PASS** (Minor 8건은 비차단)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 16
  ac_met: 16
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
  minor: 8
```
