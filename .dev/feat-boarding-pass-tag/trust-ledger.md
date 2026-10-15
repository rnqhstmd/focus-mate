## Trust Ledger

## 통합 감사 (review)

감사 범위: PRD, 설계서, 변경 파일(`ios/FocusMate` 신규·수정분)을 직접 Read했습니다. 빌드와 테스트는 실행하지 않았습니다. 이 감사에서 코드로 확인하지 못한 항목은 마지막 "미확인"에 따로 적었습니다.

- [RISK/HIGH] 진행 여정 한 건이 손상되면 저장 파일 전체가 읽기·쓰기 불가가 되고, 복구 경로가 카드·기록을 초기화한다
  - 근거:
    - `SnapshotCodec.swift:65`, `:68-69`: v3 `Envelope` 디코딩이 실패하면 어떤 오류든 `.corrupt`가 됩니다.
    - `JourneySnapshot.swift:85-99`: 필수 키 누락, 모르는 `Phase`/`PreparationTagIcon`/`PreparationTagColor`/`JourneySound` raw 값, `boardedAt` 형식 오류는 모두 throw됩니다.
    - `AppSnapshot.swift:82-87`: `active.validate` 실패(`cardMismatch`, 빈 필드, 범위 밖 값)는 `invalidState`가 되어 전체 파일을 거절합니다.
    - `LocalSnapshotStore.swift:108-109`: 이후 모든 `save`가 `writeBlocked`로 막힙니다.
    - `AppModel.swift:182-185`: 로드 실패 시 `launchState = .failed`가 됩니다.
    - `RootView.swift:127`: 복구 UI는 "카드, 여행, 기록 데이터가 초기화돼요"라고 안내하는 정리 버튼뿐입니다. 원본은 백업 파일로 남지만 앱 안에서 복원할 수 없습니다.
    - 결과: 임시 데이터(진행 여정, PRD 기준 최대 1건)의 손상이 영구 데이터(카드, 완료 기록)의 사실상 유실로 번집니다.
    - 손상이 생기는 경로:
      - 이전 v3 빌드(TestFlight 등)로 되돌릴 때. 설계서 A-3도 "이전 v3 앱은 active 객체를 손상으로 본다"고 인정합니다.
      - W05가 `Phase`나 아이콘 enum에 case를 추가한 뒤 구버전 앱이 읽을 때.
      - 향후 카드 교체와 겹쳐 `cardMismatch`가 날 때.
  - 권고:
    - `journey.active` 디코딩·검증 실패는 "active 없음"으로 격리(lossy decode)하고, 카드·기록은 그대로 로드하세요.
    - 격리가 어렵다면 최소한 이 경우만 "진행 여정만 정리" 복구 경로를 따로 두세요.
    - 이 격리 동작을 단위 테스트로 고정하세요(모르는 enum 값, 카드 불일치, 빈 필드).

- [GAP/MEDIUM] 저장 시점의 준비 값이 인식 시점이 아니라 300ms 뒤 현재 값으로 정해진다
  - 근거:
    - `BoardingTagController.swift:157-161`: 저장은 300ms를 기다린 뒤 `commit`에서 실행됩니다.
    - `AppModel+Boarding.swift:26-28`: `boardJourney`는 그 시점의 `confirmedPreparation`을 읽습니다.
    - `AppModel.swift:41-43`: `confirmedPreparation`은 초안이 바뀌었으면 nil을 돌려주는 계산 값입니다.
    - 인식 직후 이탈하고 초안이 바뀐 상태라면 `boardJourney`가 false입니다. 컨트롤러는 `failed` 상태로 가고(`:167-173`) 화면이 사라진 뒤에도 "승차 정보를 저장하지 못했어요"를 낭독합니다.
    - 사용자가 본 인식 결과와 달리 저장이 되지 않아, FR-10 "인식 후 이탈해도 저장 유지"와 BR-3에 어긋납니다.
    - 도달 가능성은 낮습니다. 300ms 안에 두 화면을 되돌아가 초안을 바꿔야 합니다. 다만 코드상 막혀 있지 않습니다.
  - 권고:
    - 인식 시점에 `details`를 캡처해 `boardJourney(details:)`로 넘기세요.
    - 같은 원인으로, 300ms 안에 메인에서 '여행 시작하기'(폐기)를 눌러도 이어서 저장이 실행됩니다(`commit`이 모델 상태를 보지 않음). 이것도 함께 해소됩니다.
    - 사전 조건 실패일 때는 저장소 실패 문구(`failedAnnouncement`)와 구분하세요.

- [ASSUMPTION/MEDIUM] `activeJourney.cardID == currentCard.id`를 저장 불변식으로 강제한다
  - 근거:
    - `JourneySnapshot.swift:63`, `AppSnapshot.swift:85`.
    - 카드 교체나 재발급이 추가되는 순간, 진행 여정이 남아 있으면 `save` 자체가 `invalidState`로 거절됩니다. 반대로 `AppSnapshot.issuingCard`(`:59-62`)처럼 카드만 바꾸는 헬퍼가 active를 그대로 둡니다.
    - 현재 코드에 그런 경로가 있는지는 확인하지 못했습니다. 지금은 카드 스타일 저장이 같은 id를 유지해서(`AppModel.swift:282-285`) 문제가 없습니다.
  - 권고: 카드가 바뀌는 기능을 만들 때 active 처리(폐기 또는 갱신)를 함께 정의하고 테스트하세요. 위 HIGH 격리로 영향도 줄어듭니다.

- [GAP/MEDIUM] `.journey` 목적지가 진행 여정 없이도 열린다
  - 근거:
    - `AppModel.swift:255-260`: `open(.journey)`는 가드가 없습니다. 설계서 B-5도 "호출부 없음"을 근거로 가드를 두지 않았습니다.
    - `JourneyView.swift:33`, `:38`: `activeJourney`가 nil이면 `awaitingDeparture`가 false가 되어 "여행" 자리표시가 보입니다.
    - 현재 호출부가 없어 도달 불가이지만, `.board`/`.boarding`과 달리 BR-1류 방어가 없습니다.
  - 권고: `open(.journey)`는 `activeJourney != nil`일 때만 허용하세요.

- [RISK/MEDIUM] 릴리스 빌드에서 테스트 코드 제외를 이번 감사에서 빌드로 확인하지 못했다. 소스 구조상으로는 분리되어 있다
  - 확인된 분리:
    - `UITestBootstrap.swift:1`, `:386`: 파일 전체가 `#if DEBUG`입니다. 런치 인자(`--fm-ui-*`) 파싱, 픽스처 생성, 시드 데이터, `ArmingBoarder`, `UITestHoldGate`가 모두 이 안에 있습니다.
    - `FocusMateApp.swift`와 `RootView.swift`의 `test*` 프로퍼티·진단·해제 버튼, `BoardingTagView.swift:92-94`와 `:212-241`, `JourneyView.swift:54-56`와 `:122-132`의 진단도 모두 `#if DEBUG`입니다.
    - `FocusMateApp.swift:47-51`: 릴리스 분기는 `LocalSnapshotStore(operationalURL)`과 `.live()` 서비스만 씁니다.
    - 경로 검증은 매니페스트에서 `support.path + "/"` 접두 검사와 심볼릭 링크 해석을 거칩니다(`:34-37`, 기존 로직). 새 저장 경로는 UUID 파싱을 거친 고정 하위 폴더입니다(`:68-69`).
    - `--fm-ui-route boarding`은 시드가 `ready`일 때만 허용됩니다(`:59`).
  - 잔여 위험:
    - `JourneyServices.swift:12-13`의 `forcedReduceMotion`, `boardingHoldSleep`, `makeBoarder`는 릴리스 타입에도 존재합니다. 기본값이 고정(false, nil, `{ $0 }`)이고 이를 바꾸는 코드는 DEBUG에만 있어, 외부에서 켤 방법은 찾지 못했습니다.
    - `#if DEBUG` 짝이 맞는지와 릴리스 컴파일 여부는 실제 빌드로 확인하지 않았습니다.
  - 권고: 릴리스 구성 빌드를 한 번 실행하고, 산출물에 `fm-ui` 문자열이 없는지 확인하세요.

- [GAP/MEDIUM] 검증이 값의 상한과 카탈로그 정합을 보지 않는다
  - 근거:
    - `JourneySnapshot.swift:65`: `minutes > 0`만 검사하고 상한이 없습니다.
    - `JourneySnapshot.swift:71`: `elapsedSeconds`도 상한이 없습니다.
    - 정류장·버스 id는 카탈로그 대조를 하지 않습니다(`:58`, 의도된 설계).
    - 표시용 조회는 nil일 때 대체 문구로 처리됩니다(`:54-56`).
    - 현재 W04 화면은 이 값들을 쓰지 않아 영향이 없습니다.
    - 다만 W05가 이 값으로 타이머와 위치를 계산할 때, 비정상 값이 검증을 통과해 들어올 수 있습니다.
  - 권고: W05 인계 문서에 "minutes/elapsed 상한과 카탈로그 미존재 id 처리" 확인을 명시하세요.

### 교차 검증 결과
- [정합] BR-1 / FR-1 승차권 진입 차단 — `AppModel.swift:258`이 `.board`/`.boarding`의 `open`을 `confirmedPreparation` 없이는 막고, `AppModel+Boarding.swift:11`과 `:19`도 같은 조건을 확인합니다.
- [정합] BR-2 / FR-8 인식당 저장 1회 — `BoardingTagController.swift:144`의 `recognitionID` 증가와 `:166`의 `recognitionID == id && phase == .contacting` 가드가 있습니다. 재시도 시 이전 Task의 `commit`은 무시됩니다. 인식 뒤 추가 접촉은 `dragChanged`의 `default`(`:85`), `dragEnded`의 `default`(`:101`), `activate`의 phase 가드(`:108`)로 무시됩니다.
- [정합] 전환 취소와 저장 분리(FR-10) — `transitionToken`과 `recognitionID`가 분리되어 있습니다(`:114-125`). `contacting` 중 이탈은 `transitionCancelled`만 켜고 저장은 예정대로 실행됩니다. 단, 위 MEDIUM(저장 시점 값)은 예외입니다.
- [정합] BR-3 / BR-9 / BR-8 — 폐기 경로는 `startTripFromMain`(`AppModel+Boarding.swift:49-55`)뿐이고 `records`를 건드리지 않습니다. 정리 저장이 실패하면 이동하지 않아 불일치가 생기지 않습니다. 새 인식은 `JourneySection(active:)`로 교체해 최대 1건입니다.
- [정합] FR-13 저장 실패 — `AppModel.persist`가 실패 시 `snapshot`을 바꾸지 않고(`:197-211`), 컨트롤러는 `failed`로 돌아가 `activate`/`dragChanged`에서 재태그할 수 있습니다(`:73`, `:108`).
- [정합] BR-5 — `validate`가 `awaitingDeparture`일 때 `elapsedSeconds == 0`을 강제합니다(`JourneySnapshot.swift:71`). 출발 안내 화면에는 진행·남은 시간 UI가 없습니다.
- [정합] BR-4 카드 번호 비노출 — `PassFace.swift:15`, `BoardingTagView.swift:181`, `:125`의 접근성 라벨은 `PassIdentity.displayName`만 씁니다. 번호는 `JourneySnapshot.cardID`로 저장되지만 화면과 접근성 라벨에는 쓰이지 않습니다. 이번 변경 파일(`Boarding*`, `Journey*`, `AppModel+Boarding`)에는 로그 출력이 없습니다. DEBUG의 `test.snapshot`에는 `cardID`가 포함되며 릴리스에는 없습니다.
- [정합] 접근성 라벨의 개인정보 — `board.route` 라벨(`BoardingPassContent.swift:33`)과 `boarding.title`은 사용자 본인의 여정·출발 정류장 정보입니다. 외부로 나가는 경로는 없습니다(네트워크 없음).
- [정합] 저장 형식 호환 — `launchRoute`를 바꾸지 않아 active 저장 시 `persist`의 경로 초기화(`:206`)가 일어나지 않습니다. v2는 `LegacyJourneySectionV2`로 null만 허용하고(`SnapshotCodec.swift:27-35`), v1/v2에서 `.empty`로 마이그레이션합니다(`:86`).
- [불일치] 설계서 C-9 "`onFinished`는 `isVisible && scenePhase == .active`일 때만" — `BoardingTagView.swift:21-25`의 `onFinished`에는 해당 조건이 없습니다. 대신 `cancelPendingTransition`이 `transitionToken`을 올려 늦은 전환을 막고, `finishBoardingTransition`이 `path.last == .boarding`을 다시 확인합니다. 결과는 같지만, 가시성·scenePhase 조건은 설계서 문구와 다르게 구현되어 있습니다.

### 확인이 필요한 사항
1. 진행 여정 손상 시 처리 방침
   - 맥락: 현재는 active 하나가 손상되면 앱 전체가 복구 화면으로 가고, 카드와 기록이 초기화 대상이 됩니다. HIGH 항목이 이 방침의 결과입니다.
   - 유형: 선택
   - 선택지:
     - (a) active만 폐기하고 나머지는 로드 (권고) — 손상된 진행 여정은 조용히 버리고 카드·기록은 유지합니다.
     - (b) 현행 유지 — 구조적으로 안전하다고 보고 전체를 막습니다. 이 경우 롤백 시나리오를 문서화해야 합니다.
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다.

### 감사 요약
미확인 항목:
- 릴리스 구성 빌드와 산출물 확인.
- 단위·UI 테스트 실행.
- `PassIdentity`가 신규 화면 어디에서도 번호를 렌더하지 않는다는 점의 시각 확인(코드 상으로만 확인).
- 카드 재발급·교체 경로의 존재 여부.

- 총 6건 (CRITICAL: 0, HIGH: 1, MEDIUM: 5)
- 조치 필요: HIGH 1건(진행 여정 손상의 전체 파일 확산)은 배포 전 해소를 권고합니다.

```yaml
security_verdict:
  critical: 0
  high: 1
  medium: 5
```
### 통합 리뷰 (reviewer Part 2 요약, R1)
- SPEC PASS 28/28 · QUALITY FAIL · Important 5 (동작결함 2: 실패 후 같은 제스처 재인식 반복, 메인 큰 글자 도달성(ScrollView 미적용) / 동작불변 3: T9 문서 미갱신, BoardingFlowUITests 조건부 해제, UI 테스트 내부 상태 단정) · Minor 41

### 위험 수용
- (없음)

### 통합 리뷰·재감사 (review 2회차)
- reviewer: SPEC PASS 28/28, QUALITY PASS (Critical 0, Important 0, Minor 7). 1회차 Important 5·보안 HIGH 1·MEDIUM (a)(b) ADDRESSED.
- security-auditor: CRITICAL 0, HIGH 0, MEDIUM 6 (N1 버린 여정 사본 없음, N2 늦은 commit 실패 문구, N3 awaitingRelease 해제 시점, N4 확정값 잔존 재승차, cardID 불변식, 상한·카탈로그) — 배포 차단 사유 없음, W05 착수 전 N1·N4 처리 권고.
- 릴리스 빌드 테스트 코드 제외: verify 단계에서 Release 빌드로 확인.

### 위험 수용 (complete)
- [verify 부분 실행] 최종 코드 전체 iOS 테스트를 761 통과·0 실패 시점에 사용자 지시로 중단, 웹 테스트·빌드와 Release 산출물 확인 생략 (complete/Step -1)
