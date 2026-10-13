## 통합 감사 (review)

**감사 범위.** 직접 읽은 파일은 PRD 전체, 코드맵, 핵심 코드 12개, pbxproj의 빌드 구성 줄이다. 코드는 AppModel+JourneyStart, AppModel, RootView, UITestBootstrap, DestinationScreen, InitialStationSearchView, RouteData, AppSnapshot, TimeSelectionView, JourneyPlanner, JourneyPlanDraft, StationSearchState, LocalSnapshotStore, FocusMateApp이다. 설계서는 용량 제한으로 전체를 읽지 못했고 Grep으로 관련 줄만 확인했다. SnapshotCodec은 마이그레이션 부분만 Grep으로 봤다. 테스트 파일 11개는 읽지 않았다. 따라서 테스트가 무엇을 검증하는지는 미확인이다.

### 발견 사항

- [ASSUMPTION/MEDIUM] 저장이 "확인 후 쓰기"이고, 메모리 스냅샷으로 파일 전체를 교체한다.
  - 위치: `AppModel+JourneyStart.swift:25-28`, `LocalSnapshotStore.swift:32-42`
  - 근거: `confirmInitialStation`은 `snapshot`(메모리)에서 후보를 만든다. `store.save`는 `load()`로 읽을 수 있는지만 확인하고 내용이 같은지는 비교하지 않는다. 그 뒤 `.atomic` 쓰기로 파일 전체를 교체한다. 같은 `AppModel` 인스턴스 하나만 쓰면 안전하다. 하지만 BR-6(W01과 서로 덮어쓰지 않음)은 "모든 쓰기가 같은 AppModel을 거친다"는 가정 위에 있다. 이 가정은 W01 코드가 없어 확인하지 못했다.
  - 권고: W01 병합 시 저장 호출이 모두 `AppModel.save`를 거치는지 확인한다. 다른 저장소 인스턴스를 만들면 W01의 카드 데이터를 덮어쓸 수 있다.

- [GAP/MEDIUM] 저장 실패 안내가 실패 원인과 무관하게 "다시 눌러 주세요"라고 한다.
  - 위치: `InitialStationSearchView.swift:28-31`, `LocalSnapshotStore.swift:35-36`
  - 근거: `saveFailure`는 `writeFailed`, `writeBlocked(...)`, `invalidState`, `notReady` 중 어느 것이든 같은 문구를 띄운다. 실행 중 파일이 손상되어 `writeBlocked`가 나면 재시도해도 계속 실패한다. 사용자는 해결되지 않는 재시도를 반복한다.
  - 근거: 이 문구가 나올 때 VoiceOver 알림(announcement)도 없다. 시각 사용자만 실패를 알 수 있다.
  - 권고: 재시도로 해결되는 원인(`writeFailed`)과 아닌 원인을 문구에서 구분한다. 실패 문구가 나타날 때 접근성 알림을 보낸다.

- [ASSUMPTION/MEDIUM] 저장된 정류장 id가 `RouteStops`에 없으면 시간 선택이 막다른 길이 된다.
  - 위치: `RouteData.swift:33-36`, `AppModel+JourneyStart.swift:5-7`, `AppSnapshot.swift:52-61`
  - 근거: `validate()`는 id가 비어 있는지와 방향 값만 본다. 기존 W00 데이터와 v1 마이그레이션 데이터는 그대로 통과한다. 이 경우 `journeyOrigin`이 nil이고 진행 버튼은 "출발 정류장을 확인할 수 없어요"로 영구히 막힌다. FR-5 때문에 출발지를 다시 고를 방법도 없다.
  - 근거: 테스트 시드 `readySnapshot`의 이름이 "성수"·"서울숲"으로 카탈로그 이름("성수역"·"서울숲역")과 다르다. 시간 선택 화면은 저장된 이름을 그대로 보여 주므로 이름 불일치가 있어도 화면에 드러나지 않는다.
  - 권고: 기존 사용자 데이터에 카탈로그에 없는 id가 올 수 있는지 확인한다. 가능하다면 이 막다른 길의 처리 방침을 PRD에서 정한다.

- [GAP/MEDIUM] 큰 글자에서 후보 정보가 화면에서 줄어든다.
  - 위치: `TimeSelectionView.swift:60-71`, `:33`
  - 근거: 접근성 글자 크기에서는 후보 버튼이 버스 번호와 도착지만 보여 준다. 정류장 수와 거리는 VoiceOver 레이블에만 남는다. 진행 버튼은 `dynamicTypeSize(...accessibility2)`로 상한이 있어 사용자가 고른 최대 크기보다 작게 표시된다. PRD FR-11의 "도달해 누를 수 있다"는 충족할 수 있지만, 큰 글자를 쓰는 시각 사용자는 같은 정보를 받지 못한다.
  - 권고: 의도된 절충이면 PRD에 기록한다. 그렇지 않다면 정보 손실 없이 줄바꿈하는 방식을 검토한다.

- [GAP/MEDIUM] VoiceOver 낭독이 중복되고, 상태 변화 알림이 없다.
  - 위치: `TimeSelectionView.swift:19-21`, `:42-43`
  - 근거: `Text("25분")`에 `accessibilityValue("25")`를 붙였다. 그러면 "25분, 25"로 읽히고, 출발지 이름도 같은 방식으로 두 번 읽힌다. 이 값들은 UI 테스트 식별용으로 보인다.
  - 근거: 시간을 바꾸면 후보 목록이 바뀌고 선택이 해제된다. 이 변화를 VoiceOver에 알리는 코드가 없다. PRD FR-8은 즉시 해제를 요구하는데, 보조기술 사용자는 선택이 풀린 것을 알 수 없다.
  - 권고: 테스트용 value는 화면 읽기에서 숨기거나 값 형식을 바꾼다. 후보 수나 선택 해제를 알리는 접근성 알림을 추가한다.

- [GAP/MEDIUM] 동작 줄이기(Reduce Motion) 대응이 코드에 없고, 검증도 수동 확인에 맡겨져 있다.
  - 위치: `AppModel+JourneyStart.swift:29`, 설계서 `:427`
  - 근거: FR-11과 AC-24는 화면 전환 애니메이션 없음을 요구한다. 코드에는 `accessibilityReduceMotion` 참조나 `Transaction` 제어가 없다. 시스템 NavigationStack의 기본 동작에 의존한다. 설계서는 이를 "수동 확인 항목"으로 남겼고, 수동 확인을 했다는 기록은 확인하지 못했다.
  - 권고: 수동 확인 기록을 원장에 남기거나, 설계서의 `navigationTransaction(reduceMotion:)` 분리 권고를 반영한다.

- [ASSUMPTION/MEDIUM] `confirmInitialStation`이 카탈로그에 속한 옵션인지 검증하지 않는다.
  - 위치: `AppModel+JourneyStart.swift:24-28`, `RouteData.swift:50-57`
  - 근거: 현재 UI는 검색 결과(`StationCatalog.search`)에서만 옵션을 얻으므로, 저장되는 값은 카탈로그 상수뿐이다. 사용자가 입력한 문자열(검색어)은 저장 경로로 가지 않는다. 다만 모델 API는 임의의 `StationOption`을 받는다. `StationOption.init`은 `RouteStops.all[index]`의 범위를 검사하지 않아 잘못된 index에서 크래시한다. 지금은 내부 호출만 있어서 실제 위험은 아니다.
  - 권고: W01 등 다른 호출자가 생기기 전에 `StationCatalog.all`에 속하는지 확인하는 방어 코드를 추가한다.

### 교차 검증 결과

- [정합] 정류장 1회 저장(BR-5): `updatingStage(...)`가 cards, journey, records를 그대로 유지한다 (`AppSnapshot.swift:35-38`). 저장 호출은 `confirmInitialStation` 한 곳이고, `launchState == .ready(.initialStationEntry)`일 때만 동작한다.
- [정합] 재검색 차단(FR-5): 저장 후 `launchRoute`가 `.main`이 된다. 이후 `confirmInitialStation`은 guard에서 `false`를 반환하므로 연타해도 두 번 저장되지 않는다. `Destination`에 검색 진입점이 없다.
- [정합] 저장 실패 시 상태 일관성: 실패하면 `snapshot`과 `launchState`는 바뀌지 않고, `path`도 갱신되지 않는다. `saveFailure`만 기록된다 (`AppModel.swift:51-60`). 성공 시 `saveFailure`가 지워진다. 공용 문구는 `initialStationEntry`에서 숨겨 중복되지 않는다 (`RootView.swift:15`).
- [정합] 원본 보존·쓰기 차단(W00): 파일이 손상되었거나 지원하지 않는 버전이면 `loadIfNeeded`에서 `.failed`가 된다. `save`는 `.failed` 상태에서 `writeBlocked`로 거부한다. `LocalSnapshotStore.save`도 쓰기 전에 `load()`로 다시 검사한다. W02에서 이 규칙은 약해지지 않았다.
- [정합] 검증되지 않은 입력 저장: 검색어는 필터에만 쓰이고 저장되지 않는다. 저장되는 정류장은 카탈로그 상수이며, `validate()`가 id, 이름, 방향(±1)을 다시 검사한다.
- [정합] DEBUG 격리: `UITestBootstrap` 전체가 `#if DEBUG`로 감싸져 있다. `FocusMateApp`, `RootView`, `DestinationScreen`의 진단 코드도 모두 `#if DEBUG` 안에 있다. pbxproj에서 `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`는 Debug 구성에만 있고 Release 구성(`:55`, `:57`)에는 없다. 따라서 Release 빌드에는 `--fm-ui-test-id` 처리, 쓰기 실패 주입, 상태 진단(`test.snapshot`·`test.persistedBytes`)이 포함되지 않는다.
- [정합] `UITestBootstrap` guard 변경: 쓰기 실패 저장소는 모든 진입 상태에 주입되고, 시드 실패 저장 1회는 `.main`에서만 일으킨다. 그래서 `initialStationEntry`에서 실패를 재현할 수 있고, 그 경우 앞서 실패한 저장이 정류장을 바꾸지 않는다.
- [확인 한계] Debug 구성의 앱이 사내 배포 등에 쓰이면 `--fm-ui-test-id` 인자로 저장 위치 전환과 실패 주입이 가능하다. 배포 파이프라인이 Release만 쓰는지는 이 감사에서 확인하지 못했다.
- [정합] FR-12: `journeyPlan`은 `AppModel`의 메모리 속성뿐이고, 저장 경로(`updating...`)에 들어가지 않는다. 진행 여정은 만들지 않는다 (BR-4).
- [정합] `DestinationScreen` 진단(`test.journeySelection`)은 `.preparation` 화면에서 DEBUG 빌드에만 나타나고, Release에는 포함되지 않는다. 다만 DEBUG 빌드에서는 UI 테스트 모드가 아니어도 항상 존재한다. 디버그 한정이라 위험은 낮다.
- [정합] 후보 계산: `minutes % minutesPerStop == 0` 필터, 정수 연산 거리 표기, `RouteStops.wrap` 모듈러 계산이 PRD와 일치한다. 시간 변경 시 선택 해제는 `setMinutes`에 있다 (`JourneyPlanDraft.swift:37-42`). 범위는 15~360으로 clamp된다.
- [미확인] 접근성 레이블 형식(AC-23)은 `JourneyPlanner.swift:12`에서 PRD 형식과 일치함을 확인했다. VoiceOver 1분 증감과 Reduce Motion은 실기기 확인 기록이 없어 미확인이다.

### 탐색 추가 항목
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/FocusMateApp.swift` → 저장소 주입과 DEBUG 부트스트랩 분기 (코드맵에 없음)
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate.xcodeproj/project.pbxproj` → Debug/Release 컴파일 조건 확인 근거

### 확인이 필요한 사항

1. 기존 사용자 데이터(W00, v1 마이그레이션)에 `RouteStops`에 없는 정류장 id가 있을 수 있습니까?
   - 맥락: 있다면 해당 사용자는 시간 선택에서 영구히 막히고, 출발지 변경도 PRD상 불가능합니다.
   - 유형: 선택
   - 선택지:
     - (a) 없다고 확정 (권장) — 근거를 PRD 가정에 기록
     - (b) 있을 수 있다 — 막다른 길 처리 방침을 정의
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

2. 큰 글자에서 후보 버튼의 정류장 수·거리를 숨기는 것이 의도된 절충입니까?
   - 맥락: VoiceOver에서는 읽히지만 큰 글자를 쓰는 시각 사용자에게는 보이지 않습니다.
   - 유형: 선택
   - 선택지:
     - (a) 의도된 절충으로 PRD에 기록 (권장)
     - (b) 정보를 모두 보이도록 수정
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

### 감사 요약
- 총 7건 (CRITICAL: 0, HIGH: 0, MEDIUM: 7)
- 조치 필요 (배포를 막는 항목은 없음. 7건 모두 기록 후 개선 또는 PRD 보완 대상)

## 기계 판정 블록
```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 7
```