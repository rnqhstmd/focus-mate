## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-3 | ✅ (M-1 수동 대체) | JourneyMapAccessibilityUITests:448-465. Legal 링크를 못 찾으면 M-1로 대체하는 PRD 규칙(prd.md:120)을 따른다. 지도 내부가 `accessibilityHidden`이라 이 경로가 사실상 상시 발동한다. trust-ledger.md:7에 기록돼 있다. |
| AC-30 | ✅ | UITests:471-476. `animated=false`와 `heading=0`을 단언한다. 구현은 JourneyTimerView `withAnimation(reduceMotion ? nil : ...)`(diff:170)와 `setReduceMotion`(diff:172)이다. |
| AC-31 | ✅ | UITests:479-483 |
| AC-32 | ✅ | UITests:488-504. 자유 탐색, 복귀, 테마, 정류장, 일시정지 후 잠김까지 확인한다. |
| AC-33 | ✅ | JourneyMapView:68-76 (대표 요소), UITests:509-521. RED에서 "뚝섬역" 누출로 실패한 뒤 GREEN이 됐다. 공허한 통과가 아니다. |
| AC-34 | ✅ | diff:188-192(`toolButton`의 라벨·값·disabled), UITests:526-535 |
| AC-35 | ✅ | UITests:540-553. 시트 구현은 T5 범위다. |
| AC-36 | ✅ | UITests:558-585. 44pt 이상, hittable, 지표끼리·일시정지와 비겹침, 시트 스크롤 후 hittable까지 본다. |
| AC-37 | ✅ (포커스는 M-2 수동 대체) | 낭독 1회 단언은 UITests:591-601에 있다. `onAppear`의 `remainingFocused = true`는 유지되고, `remainingColumn`에서 `$remainingFocused`에 한 번만 바인딩된다. trust-ledger.md:8에 기록돼 있다. |
| AC-38 | ✅ | UITests:606-621과 회귀 40/40(보고 기준) |
| FR-11 | ✅ | AC-30, 31, 32와 같다. |
| FR-12 | ✅ | AC-33~38과 같다. |

[Must] AC-3, 30~38과 FR-11, FR-12 전부 충족. 수동 대체 2건(AC-3, AC-37 포커스)은 ledger에 기록돼 있다.

## 설계 범위 이탈
이탈 없음. 수정 파일은 JourneyMapView, JourneyTimerView, 신규 UITests 하나이고, 모두 설계서 §6, §8과 "T0 스파이크 반영" 범위 안이다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

특히 확인하라고 한 항목의 결과는 다음과 같다.

- **히트 테스트**: overlay의 `Color.clear.allowsHitTesting(false)`가 지도 제스처를 막지 않는다. 접근성 요소로는 유지되며, AC-33이 `journey.map` 라벨을 읽어 이를 확인한다.
- **`accessibilityHidden` 범위**: Map에만 걸려 있다. overlay는 그 뒤에 붙으므로 숨겨지지 않는다. `topBar`와 `bottomInfo`에는 영향이 없다.
- **AnyLayout 상태 보존**: 세 자식의 뷰 타입이 두 레이아웃에서 같아서 정체성이 유지된다. `@AccessibilityFocusState` 바인딩은 `ViewThatFits`와 달리 한 번만 생긴다.
- **ScaledMetric**: `labelSize`, `unitSize`, `valueSize`가 `infoColumn`과 단위 `Text`에 적용돼 있다.
- **AC-3 공허 통과**: 구조상 존재하며 trust-ledger.md:7에 기록돼 있다. 아래 Minor에 개선안을 적었다.

### Critical (0건)
없음

### Important (0건)
없음

### Minor (5건) — 전부 [동작불변], 비차단
- UITests:451-454 — AC-3이 Legal을 못 찾으면 빈 `runActivity`만 남기고 통과한다. 지금은 사실상 항상 이 경로를 타서 공허 통과다. 결과가 로그나 리포트에 드러나지 않는다.
  - 권고: 활동 이름에 "Legal 미발견: M-1 수동 필요"를 명시한다. 이 테스트를 `XCTSkip`으로 바꾸는 방안도 있다. 단, 현재 PRD는 대체 통과를 허용하므로 필수는 아니다.
- JourneyMapView:67 — 지도 전체를 `accessibilityHidden`으로 숨겨서 VoiceOver 사용자는 Apple 지도 법적 표기 링크에 접근할 수 없다. 화면에는 보이고, 설계상 FR-12와 맞바꾼 결정이다. 확신도는 낮다.
  - 권고: M-1 수동 확인에서 법적 표기가 시각적으로 하단 정보 위 왼쪽에 있는지 확인한다. 배포 전에 접근성 예외로 허용되는지도 확인한다.
- JourneyTimerView:244-246 — `dynamicTypeSize.isAccessibilitySize`를 두 번 계산한다(`layout`과 `stacked`).
  - 권고: `stacked`를 먼저 정하고 `layout`을 거기서 파생시킨다.
- JourneyTimerView:259 — 라벨 "남은 시간"과 단위 " 개", " km"이 `JourneyMapDisplay` 상수와 달리 뷰에 하드코딩돼 있다. 같은 파일 안에서 문구 출처가 일관되지 않다.
  - 권고: 상수로 옮긴다.
- JourneyTimerView:292 — 최대 글자 크기에서 `valueSize`가 크게 커지는데 `lineLimit(1)`과 `minimumScaleFactor(0.6)` 조합이라 잘릴 가능성이 있다. AC-36은 겹침과 존재만 확인하고 텍스트 잘림은 확인하지 않는다. 확신도는 낮다.
  - 권고: M-4 수동 확인에 큰 글자 상태에서 값이 잘리는지 보는 항목을 추가한다. `[검증 필요]` AC-36 큰 글자 케이스의 스크린샷.

## Part 2 판정
QUALITY PASS (Minor만 있음)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 12
  ac_met: 12
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
  minor: 5
```

(ac_total 12는 AC-3, 30~38 10건에 FR-11, FR-12를 더한 값이다.)
