# T5 test05 좌표·도달성 독립 조사

판정: **원인 미확정. 다음 조치는 생산 코드 수정이 아니라 단일 버튼의 도달·상태 전후 probe다.** r4는 30회 XCTest 탭 이벤트 합성 성공을 보여주지만 `Button` action 호출이나 Y 값 변경을 입증하지 않는다. 최종 `centerY == 2` 실패를 유지해야 한다.

이번 조사는 읽기 전용이다. 현재 production/test/Git/기기 상태를 변경하거나 빌드·테스트를 실행하지 않았다. 이 보고서만 작성했다. 대상 로그의 기기는 `88EC0B32-40D7-4592-A34F-E09C051CECFA`이며 27 probe 기기와 구분한다.

## 확인한 입력과 버전

- `reports/t5-ui-fix-impl.md`: 4차 구현 시도와 실패 범위.
- `ios/FocusMate/CardCustomizationView.swift`: SHA-256 `752015bad30a5d57e67084dbb23eea6b4a264ebbaf4f64d510127b0537b13d18`.
- `ios/FocusMateUITests/CardCustomizationFlowTests.swift`: SHA-256 `f5f070ee817f9decb0d3198073fed60695914a150afdcad1e949c4661d2e2fb7`.
- `CardCustomizationController.swift:67–92`: mutation guard 및 placement clamp/apply 경로.
- `t5-ui-fix-focused-r4.log`, r1/r3의 test05 activity 비교.
- `t5-ui-fix-r4-moving.png`: 실제 픽셀을 열어 확인. PNG 자체 EXIF에는 촬영 시각이 없다. 파일 birthtime/mtime과 XCTest 시작 시각으로 아래 시점을 대응했다.
- r1 실패 AX: `t5-ui-fix-attachments/1B21E380-9048-470C-BBBF-4551B100D374.txt`. r4 AX라고 혼용하지 않는다.

## 확정 가능한 실행 순서

| r4 근거 | 관찰 |
|---|---|
| 로그 348행 | test05 시작 `2026-10-14 21:46:13.325` |
| 로그 14.85초 activity | 실제 width slider normalized 1.00 요청 |
| 로그 20.51~132.39초 | `Tap cardCustomization.y.increase Button` **30건** |
| 해당 case 전체 | `Press`/`Drag`/`Swipe`/`Scroll` activity **0건**. helper의 명시적 scroll 및 native auto-scroll 기록이 없다 |
| 로그 590~595행 | 10번째 Y+ 탭 t55.27, Synthesize event t55.36, idle t55.65 |
| moving PNG | birth `21:47:08.866162`, mtime `21:47:08.867012`: 시작 대비 약 **55.541초** |
| 로그 977~980행 부근 | t132.75부터 preview 존재/화면 포함 여부 조회. 이어 바로 JSON 조회와 sand 탭; 복귀 scroll activity 없음 |
| 로그 986~1005행 | sand와 save 이벤트 합성; 배경 변경·저장 종료 비교 통과 |
| 로그 1016행 | 독립 literal assertion 실패: 저장된 해당 photo의 `centerY`는 **0.5**, 기대 **2.0** |

파일 시각은 immutable capture timestamp가 아니므로 밀리초 단위 정확한 화면/터치 동기화라고 주장하지 않는다. 다만 이 파일이 현재 파일 시각대로 생성되었다면 **10번째 탭 중 화면**이며, preview 복귀 검사보다 약 77초 앞선다. 더구나 r4에는 실제 복귀 scroll 이벤트가 없다. 따라서 “의도적으로 위로 돌아간 뒤 촬영되어 상단이 보인다”는 설명은 현재 로그와 맞지 않는다.

화면에서는 편집기 상단 preview, 팔레트, 두 사진, `250%` slider와 고정 저장 footer가 보인다. Y 행은 보이지 않는다. 이것만으로 Y 버튼의 AX frame이나 이벤트 수신 뷰를 알 수는 없다.

## 가설별 판단

1. **왼쪽 2% gutter가 스크롤을 받지 못했다 — r4 직접 원인으로 입증되지 않으며 우선순위를 낮춘다.** `scrollBody`는 호출되면 `press(...thenDragTo:)`를 수행한다. r4에는 해당 활동이 없으므로 gutter hit-testing 이전에 도달 판단이 성공한 경로다. 향후 명시적 한 번의 swipe 전후에서 별도로 검증할 수 있다.
2. **`.accessibilityElement(children: .contain)`가 ScrollView role을 잃게 했다 — 현재 근거로 단정 불가.** 동일 modifier가 있던 r1 AX 36행에 `ScrollView`, ID `cardCustomization.body`, frame `{0,134,402,740}`이 명시되어 있다. 따라서 이 modifier가 항상 native role을 제거한다는 가설에는 반증이 있다. r4의 body/native scrollview frame과 role을 아직 수집하지 않았으므로 r4 viewport 이상까지 배제한 것은 아니다.
3. **`reach(container)`가 실제 버튼 도달 전에 성공했다 — 가장 먼저 검증할 경로.** `reach` 335~337행은 `above == nil`이면 `target.isHittable`만 본다. test05의 `step` 408~409행은 Y **container**를 target으로 넘긴다. 실제 버튼은 419행에 뒤늦게 query하고, 존재·label·enabled만 확인한 후 423행에서 tap한다. 버튼 frame의 화면/viewport/footer 포함 여부나 버튼 isHittable을 별도 측정하지 않는다. r4 무스크롤 반복은 이 조기 성공 경로와 일치하지만, 실제 잘못 계산된 요소/frame은 아직 미측정이다.
4. **preview가 탭을 받았다 / Y action이 호출되었지만 controller가 무시했다 / 값이 나중에 복원되었다 — 모두 미확정.** 현재 로그에는 action entry, computed hitpoint, 단일 tap 전후 JSON이 없다. 30회 뒤 최종 값만으로 어느 이벤트가 실제 발생했는지 역추정해서는 안 된다.
5. **저장이 Y 변경을 누락했다 — 현재 증거는 반대 방향이다.** `successfulSave` 435행의 `closed.saved == expected`가 통과했다. 여기서 expected는 save 직전 실제 draft다. 따라서 적어도 저장 직전부터 해당 값이 0.5였다는 근거가 있으며, 저장 이후 손실로만 설명하기 어렵다. 다만 이 case 자체는 파일 read-back/relaunch를 하지 않으므로 실제 persisted bytes의 별도 관측과 구분한다.

`positionControl`은 뷰 생성 당시 `photo.centerY`를 `value`에 담아 Y+ action에서 `value + 0.05`를 요청한다. `place`는 변경하지 않은 필드를 현재 draft에서 보존하고 controller는 유한 값/ID/활성 상태를 확인 후 clamp/apply한다. 이 정적 경로와 controller unit PASS만으로 실제 UI action 전달을 증명할 수 없다. 반대로 첫 탭 뒤 0.55가 관측되지 않은 현재 상태에서 stale closure를 주원인으로 확정할 근거도 없다.

## 설치 SDK의 실제 계약

읽은 primary 파일:
`/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIElement.h`

- 62~63행 `isHittable`: 이벤트 합성을 위한 hit point를 계산할 수 있는지를 뜻한다. 부모 container의 모든 자식이 화면에 보이거나 action이 실행된다는 보장이 아니다.
- 72~73행 `coordinateWithNormalizedOffset`: **요소 frame의 원점 + frame 크기 × offset**으로 screen point를 계산한다. 그러므로 body.frame이 실제 viewport인지 확인하지 않은 gutter 좌표는 검증되지 않은 좌표다.
- 136~139행 `tap`: 요소에 대해 계산한 hittable point로 tap 이벤트를 보낸다. `Synthesize event` 로그는 이 전달 시도이며 SwiftUI action 완료의 증거가 아니다.

현재 공개 API 근거에서 `tap()` 내부가 선택한 실제 hitpoint를 읽는 getter를 확인하지 않았다. 다음 probe는 그 좌표를 관측했다고 주장하지 않는다.

## 최소 probe 제안: 생산 코드/기존 oracle 유지

부모가 별도 독립 UI probe에 작성하고 한 번씩 순차 실행한다. 새 생산 setter·공개 instrumentation API·사설 AX 속성은 요구하지 않는다. 기존 실제 fixture와 `test.cardStyleJSON` 읽기를 쓴다.

1. **같은 사전 상태**: valid2 import 완료, 마지막 portrait 선택, slider maximum. 첫 Y+ 이전에 JSON 전체, 선택 ID, 두 photo의 placement/hash, `isImporting`, `canUndo`를 기록한다. 이 단계부터 각 capture에 `Date`와 stage를 함께 기록한다.
2. **좌표 관찰**: app frame, body의 `elementType/frame/isHittable`, `app.scrollViews.allElementsBoundByIndex`의 ID/frame, preview/slider/Y container/Y+ button/footer의 `frame/isHittable/isEnabled`, Y staticText label/value를 동시에 기록한다. 전체 debugDescription과 화면을 같은 stage에 첨부한다. `container`와 실제 `button`을 각각 측정한다.
3. **기존 경로 한 번**: 현재 `reach(container)`를 그대로 사용한 뒤 위 상태를 다시 기록한다. Y+ `button.tap()` 딱 1회 후 idle 직후와 짧은 bounded wait 뒤 JSON/AX/화면을 기록한다. 기대값은 **동일 ID Y=0.55, 다른 사진/width/X 불변**이다. 실패해도 30회 반복하거나 다음 색/저장 단계로 넘어가지 않는다. 원인 관찰을 위한 출력과 assertion을 구분한다.
4. **도달 비교**: 필요하면 새 동일 seed 세션에서 Y+의 실제 frame이 app 및 body viewport의 교집합 안이고 고정 footer 위에 완전히 놓일 때까지 명시적인 scroll를 한 번씩 시도한다. 첫 swipe 전후 preview/slider/Y/button frame 변화와 화면을 비교하여 실제 scroll 여부를 증명한다. 좌표가 screen 밖이면 합성하지 않는다. 2% gutter와 안전한 보이는 본문점은 별도 시도로 분리하며 한 시도 안에서 두 방식을 섞지 않는다.
5. **보이는 버튼의 한 번 tap**: 위 조건과 실제 screenshot에서 Y+가 보인 뒤 `button.tap()` 한 번, Y=0.55를 비교한다. 이 경로만 성공하면 controller 재설계보다 helper의 target/가시 영역 검증을 강화하는 방향이 타당하다. literal 최종 Y=2 및 비선택 사진 불변 검증은 그대로 남긴다.
6. **여전히 실패할 때만**: 관측된 visible 버튼 중심에 대한 explicit coordinate tap을 별도 새 세션에서 한 번 비교할 수 있다. 이때는 공개 coordinate API로 계산한 점을 출력할 수 있으나, 원래 `button.tap()`의 내부 hitpoint라고 부르지 않는다. 두 방식 모두 실패하면 그때 action entry/gesture 수신을 debugger breakpoint 등으로 관찰하는 별도 진단을 설계한다. 지금 곧바로 production modifier를 제거하거나 제스처 우선순위를 바꾸지 않는다.

## 판정 기준

- 현재 확정: native 이벤트 합성 30회, 상단 화면 유지 관찰, 명시적/자동 scroll activity 부재, save 직전/직후 Y=0.5, 최종 독립 assertion FAIL.
- 현재 모름: 실제 수신 뷰/action, r4 AX button/viewport frame, 한 번 tap 후 Y, scroll를 실제 수행했을 때의 변화.
- 다음 최소 증거: **동일 stage의 실제 button frame·화면 + 단일 tap 전후 JSON**. 이 증거 전에는 5번째 추측성 생산 수정이나 테스트 기대값 완화를 권하지 않는다.

## 다음 구현자에게: 임시 callback 로그를 먼저 권고

부모가 제안한 **DEBUG 전용 `private place` 입구/출구 OS.Logger 진단을 먼저** 수행하는 편이 현재 원인 분기에 더 직접적이다. 기존 test05와 19개 test hash를 그대로 유지하고, 상태·레이아웃·accessibility modifier를 바꾸지 않은 채 원래 실패 경로에서 callback 수신을 관찰할 수 있다. 이것은 수정안이 아니라 원인 관찰용 임시 로그이며 원인 확인 후 제거한다. 이 조사자가 추가하거나 실행한 것은 없다.

필수 로그는 `entry`의 photo ID와 optional x/y/width, 해당 ID의 before placement/존재 여부, guard 탈락 또는 setPlacement 이후 after placement다. 입구 기록은 ID guard보다 앞에 둬야 ID 불일치 조기 반환을 놓치지 않는다. 숫자·optional nil을 식별 가능한 형태로 남기고, 단조로운 순번이나 시스템 timestamp로 순서를 보존한다. 사진 byte/개인 정보는 출력할 필요 없다. logger filter는 실제 process/subsystem/category로 검증하고, 현재 test의 width 변경 로그가 수집되는지를 **양성 대조**로 삼는다. 수집이 유효하다는 확인 없이 로그 부재를 callback 부재로 해석하지 않는다.

현재 파일의 call site에서 `x=nil, y=non-nil, width=nil` 패턴은 Y 위치 버튼 경로이고, preview 이동은 x/y를 함께, 크기 조작은 width를 전달한다. 그러므로 입구의 optional 패턴으로 경로를 구분할 수 있다. 메서드명을 보았다는 이유만으로 모든 place 호출을 Y+로 계산하지 않는다.

| 결과 | 다음 분기 |
|---|---|
| width 로그는 있고 Y-only entry가 0개 | Y tap event 합성과 placement callback 수신 사이를 조사. “실제 탭이 다른 뷰로 갔다”까지는 미확정. 다음으로 독립 AX/frame/screenshot 단일 버튼 probe |
| Y-only entry는 있지만 ID 없음/after 불변 | source guard/ID/controller 상태 쪽으로 좁힘; 입력값과 ID 대조 |
| Y-only entry 및 0.5→0.55 후 다음 호출에서 되돌아감 | 되돌린 호출의 optional 패턴·시각을 추적; gesture/다른 binding 경로 구분 |
| Y-only entry가 반복되나 매번 같은 요청 0.55 | captured value/뷰 갱신 경로를 조사; first after 값과 이후 호출을 함께 해석 |
| 30회 점진 증가 후 draft가 다시 0.5 | 종료 전 다른 mutation/lifecycle 경로 조사. 저장 손실로 먼저 단정하지 않음 |

Logger 진단에서도 수정 대상이 source인지 harness인지 아직 정하지 않는다. action entry를 확인한 뒤 필요하면 위 독립 단일 버튼 probe로 가시성/좌표를 연결한다. 임시 로그 제거 후 원래 테스트를 재검증하고, 독립 centerY=2 oracle과 19개 test hash는 유지한다.
