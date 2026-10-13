# T1 태스크 리뷰 (scoped, sonnet)

## Part 1: AC 충족 매트릭스 (태스크 범위)

| AC | 충족도 | 근거 |
|----|-------|------|
| FR-4 구조 보장 | ✅ | `AppSnapshot.swift` diff +17~25행에서 6인자 생성자가 `private`이고 기본값이 없다. 타입 밖 경로는 `.empty`, `updatingStage`, `updating(cards/journey/records:)`, 디코딩뿐이다. 호출부 3곳(`UITestBootstrap` +32/+50/+60)과 테스트 4곳은 모두 `updating…` 형태로 바뀌었다. 4개 `updating…` 함수는 나머지 필드를 원본에서 그대로 복사한다. |
| AC-1 일부 (영역 `.empty`) | ✅ | `AppSnapshot.empty`가 `cards: .empty, journey: .empty, records: .empty`를 쓴다. `CardSection.empty`는 `items: []`, `JourneySection.empty`는 `active: nil`, `RecordSection.empty`는 `items: []`다. `testEmptySnapshotHasEmptyCardJourneyAndRecordSections`가 검증한다. |
| AC-2 일부 (`state` 키 6개) | ✅ | `CodingKeys`에 영역 3개를 추가했고 `encode(to:)`가 영역 3개를 항상 쓴다. 정류장 nil은 `encodeNil`로 쓴다. `testSnapshotEncodesExactlyTheSixStateKeysEvenWhenStationsAreNil`이 키 집합을 단언한다. |
| 영역 디코딩 정책 | ✅ | 정책 항목별 확인 결과는 아래와 같다. |

- keyed container 필수: 세 영역 모두 `decoder.container(keyedBy:)`를 명시 호출한다. `[]`나 `null`이면 오류가 나고, 테스트 2건이 있다.
- 골격 키 필수: `items`는 `decode`로 읽고, `active`는 `contains` 확인 후 `decodeNil`로 읽는다.
- 원소가 있으면 오류: 세 원소 enum의 `init(from:)`가 항상 `dataCorrupted`를 던진다. `active: {}`와 `active: "x"`도 같은 경로로 실패한다.
- 영역 안 모르는 키 무시: 알려진 키만 읽는다.
- `active` null 허용·누락 오류: `contains` 가드와 `decodeNil` 순서가 설계와 일치한다.

[Must] 전달된 4건 중 4건 충족.

## 설계 범위 이탈
- 신규 `ios/FocusMateTests/AppSnapshotSectionsTests.swift`는 설계의 "AppFoundationTests.swift에 추가"와 다르다. 다만 test-architect가 클래스명과 파일명을 맞추면 허용한다고 명시했고(러너 규칙), 클래스명도 일치한다. 이탈로 보지 않는다.
- 그 외 이탈은 없다. `SnapshotCodec`과 `LocalSnapshotStore`는 T2/T3 범위라 건드리지 않았다.

## Part 1 판정
모두 ✅ → **SPEC PASS**

## Part 2: 코드 품질 리뷰

### Critical (0건)
- 없음. 두 가지는 위험으로 의심했지만 실제 결함이 아님을 확인했다.
  - `decodeNil(forKey:)`는 키가 없으면 던지는데, 앞의 `contains` 가드가 이를 막는다.
  - 값이 없는 enum의 `Equatable` 합성은 설계가 `==`를 직접 쓰라고 했으나 합성에 맡겼다. impl report의 24건 통과 주장을 믿는다면 컴파일에는 문제가 없다.

### Important (0건)
- 없음.

### 예상된 중간 회귀가 T1 결함인가
**T1 AC 위반이나 코드 결함은 아니다. 다만 태스크 분해와 순서 위험이므로 Minor로 보고한다.**

- 근거: 이 회귀는 T1이 지켜야 할 AC가 아니라 T2/T3(코덱·저장소 위임)에서 복구되는 설계 범위다. 기존 v1 읽기 테스트 14건 중 일부가 `corrupt`로 실패한다.
- 원인: `AppSnapshot`의 합성 디코딩이 이제 영역 키를 필수로 요구한다. 그런데 `LocalSnapshotStore`는 아직 이 합성 디코딩으로 v1 `state`를 읽는다.
- test-architect의 "RED 확인 전략"은 코덱 뼈대를 먼저 추출해 기존 테스트가 GREEN인 채로 진행하라고 권고했다. T1이 그 순서 없이 `AppSnapshot`만 먼저 바꾼 것이 원인이다.
- 부수 효과: T1~T2 사이에서 `save()`는 `version: 1` 봉투에 영역 키가 섞인 파일을 쓸 수 있다. T3 이전 커밋을 릴리스나 배포 기준으로 쓰면 안 된다.
- 조치: T1을 막을 필요는 없다. 오케스트레이터는 T2·T3 완료 전에 이 브랜치를 머지하지 않도록 하고, phase-review Step 0에서 `AppFoundationTests` 전체를 반드시 재확인해야 한다.
- 근거 한계: 실패 건수(17 assertion)는 impl report 주장이고 diff로 직접 검증하지 못했다. 원인 설명은 코드와 일치한다.

### Minor (6건) — 전부 [동작불변], 비차단
- `AppSnapshotSectionsTests.swift:314-324` `testUpdatingStageKeepsTheOriginalSections`: W00에서 영역이 항상 `.empty`라 `.empty == .empty`인 항상 참 단언이다. 주석이 이를 스스로 인정한다. 설계 인계 항목에 이미 있으므로 후속 작업(W01 이후)이 실제 원소로 보강해야 한다.
- `AppSnapshotSectionsTests.swift:336-368` S2: `updating(journey:)`와 `updating(records:)`의 "다른 영역 보존" 테스트가 없다. `updating(cards:)`만 있고 그 단언도 항상 참이다. 한 영역 갱신 함수가 다른 영역을 비워도 못 잡는다. 변이 검출이 약하다. 현재는 설계에서 허용한 한계다.
- `AppSnapshot.swift:27-42`: `updatingStage`와 `updating(...)` 3개의 본문이 6인자 호출로 거의 같다(DRY). 설계 시그니처를 따랐고 REFACTOR에서도 유지하기로 했다. 다만 영역이 늘 때마다 4곳을 함께 고쳐야 한다. 정리하려면 `copy(…)` 같은 private 헬퍼 하나로 모을 수 있다.
- 디코딩 테스트(`AppSnapshotSectionsTests.swift:439-444`)에서 "영역 안 모르는 키 무시"는 `CardSection`만 검증한다. `JourneySection`(`{"active":null,"extra":1}`)과 `RecordSection`은 없다.
- `stage(_:_:_:)` 헬퍼가 `AppFoundationTests`와 `AppSnapshotSectionsTests`에 중복 정의되어 있다(테스트 DRY). 설계도 이 구조를 승인했고, 파일 간 `private static`이라 분리가 불가피하다.
- 세 원소 enum의 `Equatable`이 합성이다(설계는 `switch lhs {}` 직접 작성). 설계 근거인 "툴체인과 무관하게 보장"과 어긋난다. 현재 Swift 5 모드에서는 컴파일되는 것으로 보이고, 필요하면 [검증 필요] CI 툴체인 변화 시 `AppSnapshotSectionsTests` 컴파일 확인.

## Part 2 판정
Critical 0 + Important 0 → **QUALITY PASS** (Minor 6건은 비차단)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 4
  ac_met: 4
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
  minor: 6
```

관련 파일
- /Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/AppSnapshot.swift
- /Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/CardSection.swift
- /Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/JourneySection.swift
- /Users/bonseung/Documents/ChatGPT/new/ios/FocusMate/RecordSection.swift
- /Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppSnapshotSectionsTests.swift
