## 설계 비판 검토 결과

### MUST-ADDRESS

- **[CHALLENGE] "JourneyTimerView는 수정하지 않는다"는 전제가, 일시정지 상태 큰 글씨 회귀 테스트에서 깨질 수 있다**
  - 근거: 하단 bar는 정확히 일시정지 상태에서만 나타난다(design.md:217). 그런데 기존 W05 테스트 `JourneyTimerAccessibilityUITests.swift:60-82`(testV7_AC29)가 바로 이 상태(`timerPaused90` + AccessibilityXXXL)에서 `remaining`·`resume`의 isHittable, 44pt, `scrollViews.count == 0`을 단언한다. 이 파일은 설계의 "기존 테스트 영향" 목록(design.md:309-318)과 위험 4(:408)에 없다. 위험 4는 새 AC-33만 다룬다. safeAreaInset 높이는 44pt + 여백 + 실패 문구이고, 여기에 DEBUG 상단 44pt 줄(JourneyView.swift:85, :158)이 더해지면 타이머 본문이 줄어든다. 맞추려면 `JourneyTimerView.swift:76`(dynamicTypeSize 상한)이나 레이아웃을 고쳐야 한다. 그러면 W06 충돌 회피 원칙(design.md:61-65, :322)과 정면으로 부딪힌다.
  - 질문: V7 AC29를 영향 목록에 넣고 T6 완료 조건으로 삼을 것인가? 들어가지 않을 때 JourneyTimerView를 고칠 수 있는지, 아니면 bar 쪽 상한(예: accessibility3 고정 높이)만으로 해결해야 하는지 지금 정해야 한다.
  - 권고: T6 전에 V7 AC29를 bar가 있는 상태로 한 번 돌려서 전제를 확인한다. 실패하면 W06 세션과 하단 영역 소유권을 먼저 합의한다.

- **[CHALLENGE] PRD AC-18(나)와 BR-1이 모순이다(설계 질문 1과 같은 내용)**
  - 근거: `RouteData.swift:11-21`에서 seongsuBridgeNorth는 index 6이다. 2014번으로 600초를 가면 2칸, 즉 index 8 "성수사거리"다. PRD AC-18(나)(prd.md:175)의 "성수역"은 3칸(900초)일 때만 나온다. 설계가 이를 올바르게 짚었고, 고치지 않으면 T1 단위 테스트와 UI 테스트가 BR-1 구현과 충돌한다.
  - 질문: (a)~(c) 중 사용자 결정이 필요하다. 이 결정 없이는 T1 테스트 표를 확정할 수 없다.

### CONSIDER

- **[CHALLENGE] 도착 정류장을 공식으로 다시 계산하는 것과 저장된 `destinationStopID`가 같다는 가정이 강제되지 않는다**
  - 근거: 설계는 "FR-8과 FR-9가 별도 분기 없이 같은 식으로 나온다"고 본다(design.md:113). 하지만 `JourneySnapshot.validate`(JourneySnapshot.swift:78-97)는 도착지가 공식과 맞는지 검사하지 않는다. 분이 간격의 배수인지, 분이 간격보다 작은지도 보지 않는다. 기존 시드도 이미 어긋난다. `timerJourney`(UITestBootstrap.swift:276-277)는 seoulForest(4), -1, 25분이라 공식으로는 index 8 seongsuIntersection인데 저장값은 seongdongSportsCenter다. 이 시드에 FR-9를 적용하면 카드는 "성동구민체육센터까지"(destinationName, JourneySnapshot.swift:74)로 보이고, 확정 뒤 현재 정류장은 "성수사거리"가 된다.
  - 참고: 실사용 데이터는 boarding(JourneySnapshot.swift:40-46)이 같은 식으로 만들기 때문에 일치한다. 다만 W06·W09에서 `timerArrived` 시드로 FR-9를 검증하면 모순이 드러난다. 도착 시 `destinationStopID`를 진실 원천으로 쓸지, 시드를 고칠지 하나는 명시하는 것이 좋다.

- **[CHALLENGE] FR-8의 "진도 0이면 현재 정류장은 사실상 변하지 않는다"가 시드에서는 성립하지 않는다**
  - 근거: `activeJourney` 시드(UITestBootstrap.swift:264-268, 317-319)는 현재 정류장이 서울숲(-1, 이름 "서울숲")이고 여정 출발지는 seongsu(+1)다. 설계에 따라 U11(BoardingLargeTextUITests.swift:56-104)에 확정 단계를 넣으면 현재 정류장이 "성수역" +1로 바뀌고, 그 뒤 시간 선택의 출발지(`journeyOrigin`, AppModel+JourneyStart.swift:5-7)와 후보도 달라진다. 지금 U11은 버튼이 닿는지만 보므로 통과할 가능성이 높다. 하지만 "현재 정류장 불변"을 단언하는 테스트를 이 시드로 쓰면 깨진다.
  - 참고: 설계는 lifecycle 시드에서만 현재 정류장 = 출발지로 맞춘다(design.md:288). 기존 시드로 W07 단언을 하지 않는다는 규칙을 명시해 두는 편이 안전하다.

- **[SIMPLIFY] `JourneyAbandonController`, 프로토콜, Fake, 전용 테스트 파일이 상태 3비트에 비해 무겁다**
  - 근거:
    - `hasFinished`로 막는 두 번째 확정은 모델 가드 `path.last == .journey`(design.md:185)가 이미 막는다. 첫 성공이 `path = []`를 동기로 실행하기 때문이다.
    - `request(isPaused:)`·`confirm(isPaused:)`의 일시정지 판단은 뷰가 넘겨주는 값을 그대로 비교할 뿐이다.
    - `abandonJourney()`는 가드 거부와 저장 실패를 모두 false로 돌려준다. 그래서 컨트롤러도 둘을 구분하지 못한다. `hasFinished`가 없으면 두 번째 탭이 실패 문구를 띄우는 것이 유일한 차이인데, 시스템 alert는 첫 탭에 닫히므로 사실상 두 번째 탭이 없다.
  - 참고: W05 관례(컨트롤러 + 단위 테스트)를 따르는 정당성은 있다. 다만 유지하려면 거부와 실패를 구분하는 반환값(enum)을 두어야 `showsFailure`가 의미를 가진다. 지금 구조로는 가드 거부도 "저장하지 못했어요"로 표시될 수 있다.

- **[SIMPLIFY] `--fm-ui-journey` 파라미터 시드(파서, 검증, invalidArguments 경로)**
  - 근거: 설계상 UI 테스트가 실제로 쓰는 조합은 90, 600, awaiting, 1500과 대표 경계 3건 정도다(design.md:383-392). AC-17·18의 나머지는 단위 테스트로 넘긴다. 기존 `timerSeeds` 딕셔너리 방식(UITestBootstrap.swift:271)으로 이름 붙은 시드 7~8개를 두면 파서, 검증, 오류 경로, 그에 대한 테스트가 필요 없다.
  - 참고: 파라미터화를 유지하면 그 파서 자체가 테스트 인프라 버그의 새 원천이 된다. 실패 시 `test.setupError` 진단으로 원인을 볼 수 있는지 확인해 둔다.

- **[SIMPLIFY/CHALLENGE] `mainLifecycleNotice.saveFailed`는 모델 상태일 필요가 약하고, BR-10 지우기에 빈틈이 있다**
  - 근거:
    - `.abandoned`는 여행 화면에서 메인으로 넘어가야 하므로 모델에 두는 것이 타당하다. 반면 `.saveFailed`는 RootView가 직접 호출하는 `resumeJourney()`·`confirmNewJourney()`의 Bool 반환으로 뷰 @State에 둘 수 있다.
    - 지우는 지점이 `open(_:)` 하나다(design.md:156). 카드 꾸미기(fullScreenCover, RootView.swift:51)는 `open`을 거치지 않으므로 다녀와도 포기 안내가 남는다.
    - 실패 안내가 `open`으로 지워진 뒤 메인에 돌아오면, 남아 있는 일반 `saveFailure`(RootView.swift:30) 때문에 "저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요."가 다시 보인다. 실제로 바뀐 것이 없는데 복원 불가처럼 안내하게 된다.
  - 참고: 성공 지표인 "저장 실패를 성공으로 안내하는 경로 0개"에는 걸리지 않는다. 하지만 BR-10과 문구 정확성이 흐려진다. 다른 화면에서 돌아올 때 일반 문구를 어떻게 처리할지 정해 두는 것이 좋다.

- **[CHALLENGE] 이어가기 신호가 1회용이면 화면이 다시 만들어질 때 W05 규칙으로 되돌아간다(W06 머지 리스크)**
  - 근거: `consumeResumeEntry`는 `ensureTimer`가 처음 타이머를 만들 때 한 번 소비된다(design.md:236). W06가 JourneyView/JourneyScreen의 뷰 구조를 바꿔(지도 컨테이너, 조건 분기 등) JourneyView의 @State가 재생성되면 어떻게 되는가. 이전 타이머는 `leave()`(JourneyTimerController.swift:124-130)로 paused=true를 저장하고, 새 타이머는 신호가 없어 일시정지로 열린다. 이어가기 직후 "바로 흐름"(FR-2)이 조용히 깨지지만 기능상 오류로는 보이지 않는다.
  - 참고: 단일 세션 안에서의 동작은 맞다. W06 머지 뒤 AC-3을 반드시 다시 돌리는 항목을 인계에 넣어 둔다.

- **[CHALLENGE] 포기 확정 직후 메인 포커스와 낭독이 pop 전환 중에 실행된다**
  - 근거: "그만두기"를 누르면 같은 트랜잭션에서 `path = []`와 `mainLifecycleNotice = .abandoned`가 설정된다. 루트 뷰는 push 중에도 살아 있으므로 `MainLifecycleNoticeView.onChange`(design.md:255)가 pop 애니메이션과 alert 닫힘 도중에 실행된다. 이때 `@AccessibilityFocusState` 지정과 announce가 시스템 화면 전환 알림에 묻히거나 무시될 수 있다. 위험 2(:404)는 이어가기 낭독만 다루고 포기 안내는 다루지 않는다.
  - 참고: `test.announcements` 1회 기록은 통과하지만 실제 청취는 보장되지 않는다. 위험 목록에 넣고 W14 점검 항목으로 넘긴다. 또 `MainLifecycleNoticeView`가 조건부 렌더링 안에 들어가면 onChange가 처음 나타날 때 실행되지 않는다. 항상 존재해야 한다는 점을 명시한다.

- **[CHALLENGE] BR-6(일시정지 중에만 포기)을 모델이 강제하지 않는다**
  - 근거: `abandonJourney()`의 가드는 departed, 미도착, path만 본다(design.md:185). 일시정지 여부는 뷰와 컨트롤러가 `timer.status`로 판단한다. 따라서 모델 단위 테스트로는 BR-6을 검증할 수 없고, 다른 호출 경로(W06 지도 도구, DEBUG 버튼 등)가 생기면 진행 중 포기가 가능해진다.
  - 참고: 설계가 든 이유(체크포인트 실패 시 snapshot.paused가 false로 남음)는 타당하다. 다만 그렇다면 판단을 넘기는 계약을 프로토콜 시그니처에 드러내는 편이 낫다. 예를 들어 지금 `abandonJourney()`에는 일시정지 여부를 받는 인자가 없다.

- **[CHALLENGE] 위험 5의 방향이 반대로 적혀 있다**
  - 근거: 체크포인트 저장 실패로 멈춘 경우(`stopForSaveFailure`, JourneyTimerController.swift:155-160), 화면 경과는 `halt()`로 고정된 현재값이고 저장 경과는 그보다 작거나 같다. 그래서 도달 정류장은 화면보다 한 칸 "뒤"일 수 있다. design.md:409는 "앞"이라고 적었다.
  - 참고: 대화상자 본문 "지금 도달한 정류장"과 사용자가 보는 경과가 어긋날 수 있다는 점은 BR-1 문언대로 수용하되, 표현은 바로잡는다.

- **[CHALLENGE] AC-31(완료 기록 수 불변)이 기록 0건 시드에서는 자명하게 참이다**
  - 근거: `readySnapshot`(UITestBootstrap.swift:317-319)은 `AppSnapshot.empty` 기반이라 기록이 0건이다. lifecycle 시드도 같은 기반이라면 "기록 수 불변"은 기록을 지우는 버그(예: `endingActiveJourney`가 records를 잃는 경우)를 잡지 못한다.
  - 참고: 단위 테스트(T1의 records 보존)가 보완한다. UI의 AC-31을 의미 있게 하려면 lifecycle 시드에 기록 1건 이상을 둔다.

- **[CHALLENGE] alert 닫힘과 확정 순서에 따른 포커스 복귀 판정 시점이 모호하다**
  - 근거: 바인딩의 set(false)에서 `flow.cancel()`이 먼저 불리면 그 시점에는 `hasFinished == false`다(design.md:221, :225). "닫힐 때"를 binding set에서 판정하면, 확정이 성공해도 `abandonFocused = true`가 먼저 실행된다. `.onChange(of: flow.isConfirming)` 기반이면 같은 트랜잭션 뒤에 평가되므로 안전하다.
  - 참고: 판정 위치를 onChange로 한정한다고 설계에 적어 두면 구현 편차를 막을 수 있다.

- **[CHALLENGE] 출발 대기 여정을 이어가면 나갈 길이 '시작'뿐이다**
  - 근거: JourneyScreen은 단계와 관계없이 뒤로가기를 숨기고 스와이프를 막는다(JourneyView.swift:63-65). FR-8은 출발 대기에 포기 버튼을 두지 않는다. 그래서 사용자가 출발 대기 여정을 이어갔다가 그만두려면 시작 → 일시정지 → 포기의 세 단계를 거쳐야 한다. PRD 결정 범위이므로 재정의하지는 않는다. 다만 설계에는 이 경로가 언급되어 있지 않다.
  - 참고: 문서(FLOWS)에 이 경로를 명시해 두어야 W09/W14 점검 때 결함으로 오인하지 않는다.

### 탐색 추가 항목
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMateUITests/JourneyTimerAccessibilityUITests.swift:60-82 → 일시정지 + XXXL에서 스크롤 없이 닿아야 하는 기존 W05 테스트. 하단 bar 추가의 직접 회귀 대상인데 영향 목록에 없다.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/JourneySnapshot.swift:74-97 → validate가 도착지와 공식의 일치, 분과 간격의 배수 관계를 검사하지 않는다.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/UITestBootstrap.swift:264-286, 317-319 → `timerJourney` 도착지가 공식과 어긋나고(seongdongSportsCenter, 공식상 seongsuIntersection), 시드의 현재 정류장이 여정 출발지와 다르며, 기록이 0건이다.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/UITestBootstrap.swift:387-390 → `UITestNextSaveFailure.arm`은 누적형(pending += 1)이다. 가드로 거부된 동작 뒤에는 실패 예약이 남아 다음 쓰기에 새어 나간다.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/DestinationScreen.swift:19-20 → `.journey`는 JourneyView를 직접 그린다. 포기 뒤 pop 중에도 화면이 유지되고 onDisappear가 자연스럽게 불린다.
- /Users/bonseung/Documents/ChatGPT/new-w07/ios/FocusMate/RootView.swift:30, 51 → 일반 저장 실패 문구 조건, 그리고 `open`을 거치지 않는 fullScreenCover(BR-10 지우기의 빈틈).

### 총평
- 강점:
  - 근본 원인(한 번의 탭으로 지우는 `startTripFromMain`, AppModel+Boarding.swift:53-56)을 가드로 직접 제거하고, 정리를 확인을 거친 `confirmNewJourney` 하나로 모았다. 연타 방지를 시간 디바운스가 아니라 상태 가드(path, active)로 처리해 W05 테스트 충돌을 피했다.
  - 포기 뒤 `leave()`가 paused에서는 쓰지 않는다는 점(JourneyTimerController.swift:131)과 `saveJourneyProgress`의 id·active 가드(AppModel+JourneyTimer.swift:15-16)를 실제 코드로 확인했다. 그래서 컨트롤러를 고치지 않고도 포기 뒤 저장 경합이 없다는 논증이 성립한다.
- 위 2건의 MUST-ADDRESS 항목을 해소한 후 설계를 확정하는 것을 권장합니다.