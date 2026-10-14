# T1 구현 보고

Status: NEEDS_CONTEXT

## 구현 내용
프로덕션 변경 없음. 허용된 TimeSelectionView.swift의 수정도 원인 확정 전에는 수행하지 않았다. CardIssuanceView 및 테스트 수정·작성·삭제, 다른 워크트리 변경, agent 호출, 커밋·푸시 없음.

## 원인 근거
- reports/t1-red.md, design.md, prd.md, baseline.md와 기존 baseline-ios-test.log를 읽었다. baseline의 AC32는 후보 탭 후 proceed actual="버스와 도착지를 선택하세요"로 실패했다.
- TimeSelectionView.swift:29는 wheel에 height 120만 적용한다. 후보 선택 액션은 같은 파일:58의 choose 호출이며 Binding setter(:52)는 setMinutes를 호출한다.
- JourneyPlanDraft.swift:37~48에서 실제 분 변경은 selectedBusID를 nil로 만들고, 유효한 후보 choose는 selectedBusID를 저장한다. AppModel+JourneyStart.swift의 후보/진행 상태는 동일 journeyOrigin과 journeyPlan에서 계산된다.
- 원본 AC32를 소스·테스트 변경 없이 직접 재실행해 같은 line60 실패를 확인했다. 60분 assertion과 candidate.isHittable 검사 뒤 탭 이벤트는 존재하지만, 탭 후 minutes/selectedBusID와 두 요소 frame은 기록되지 않는다.
- xcresult 활동을 읽고 후보 Synthesized Event의 binary plist를 메모리에서 해석했다. 실제 합성 탭 좌표는 x=59.4000005275, y=459.9333339185, window=402×874이다. 해당 이벤트는 요소 frame을 제공하지 않아 어느 hit 영역이 탭을 받았는지 확정하지 못한다. 첨부물 JSON 조회는 binary plist이므로 실패했고 raw 조회 후 plistlib 해석으로 확인했다.
- 따라서 부분 노출 후보의 탭 누락, wheel 영역의 가림/가로채기, 탭 후 분 변경에 따른 선택 해제 중 어느 원인인지 구분할 actual 증거가 부족하다. 추측성 frame/contentShape/clipping 변경은 하지 않았다. 테스트 결함으로 단정하지 않는다.

## RED→GREEN 실제 출력 / GREEN 증거
GREEN 미달성. 지정된 focused 명령만 아래 순서로 실행했다.

### 1. 원본 실패 테스트 단독
실행 명령:
```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=D3BB49D7-3834-4BC9-B910-1CADD9E036E1' -derivedDataPath .build/ios -parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:FocusMateUITests/LargeTextUITests/testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow test CODE_SIGNING_ALLOWED=NO
```
로그: .dev/codex-feat-card-customization/t1-impl-focused.log
종료코드 65, 실제 0 pass / 1 fail.
```text
Executed 1 test, with 1 failure (0 unexpected) in 15.333 (15.338) seconds
** TEST FAILED **
```
결과 번들: .build/ios/Logs/Test/Test-FocusMate-2026.10.14_08-32-08-+0900.xcresult

### 2. 지정된 관련 focused 파일
실행 명령:
```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateUITests/LargeTextUITests.swift ios/FocusMateUITests/TimeSelectionUITests.swift ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift
```
로그: .dev/codex-feat-card-customization/t1-impl-focused-related.log
종료코드 65, 실제 11 pass / 1 fail. 원본 AC32의 line60 실패만 남았다. AC33 1/1 PASS, TimeSelectionUITests 9/9 PASS(20초 조건의 wheel spike 포함), LargeTextUITests 1/2 PASS.
```text
Executed 12 tests, with 1 failure (0 unexpected) in 213.112 (213.128) seconds
** TEST FAILED **
```
결과 번들: .build/ios/Logs/Test/Test-FocusMate-2026.10.14_08-32-39-+0900.xcresult
전체 스위트는 실행하지 않았다.

## REFACTOR 내역
수행하지 않음. GREEN 전 원인 확정에 필요한 진단이 부족하다.

## self-review 결과
- 소스 diff 없음, 요청 범위를 확대하지 않았다.
- 세 focused 시험 파일 모두 t1-test-hashes.json의 Git blob 해시와 일치한다. 최초 비교에서는 raw SHA-1과 Git blob SHA-1을 혼동했으나 Git blob 포맷으로 재검증해 모두 일치를 확인했다.
- 기존 line60 기대값·XXXL 인자·60분·2014·도착지·20초 wheel spike 기준·분 단위·동적 글자 정책을 유지했다.
- AC33 실제 PASS를 확인했고 CardIssuanceView는 수정하지 않았다.

## 변경 범위
직접 작성: 본 보고서와 지정된 검증 출력 로그 2개. 테스트 명령의 .build/ios 생성 산출물 외 다른 파일 수정 없음.

## 우려사항 및 부모 test-author 진단 요청
NEEDS_CONTEXT: 원본 AC32와 같은 launch/행동/기대값을 유지한 별도 진단 시험에서 다음 값을 attachment로 남겨 전달해 달라. implementer는 진단 시험을 작성하지 않았다.
1. 60분 조절 후, reach 전후, 후보 탭 직전/직후 candidate.frame, wheel.frame, ScrollView의 가시 frame, proceed.frame 및 app.frame.
2. 각 시점의 time.minutesLabel 값, wheel.value, 후보 isHittable/isSelected, proceed label/isEnabled. 탭 직전 후보가 부분 노출인지 구분할 화면 또는 접근성 트리.
3. 가능하면 탭 직후 실제 journeyPlan minutes/selectedBusID. 기존 진단에 이 값이 없다면 UI 관찰값부터 확보하고 추가 프로덕션 진단은 부모가 범위를 정한다.
이를 통해 후보 탭이 실행되지 않은 것인지, 실행 뒤 분 값 변경으로 해제된 것인지 구분한 뒤 한 변수 최소 수리 및 전달된 focused 검증을 수행할 수 있다. 현재 해결/0 failures를 주장하지 않는다.


## fix 라운드 1

Status: BLOCKED (최소 수리·원본 단독 GREEN 완료, 관련 focused 검증은 범위 밖 빌드 오류로 차단)

### 원인 actual evidence
전체 prd.md/design.md, 기존 구현 보고, t1-red.md/t1-red-diagnostic.md 및 실제 t1-diagnostic-test.log를 읽었다. 아래는 실제 진단 로그의 관찰이며 테스트 작성 보고의 미실행 상태와 구분한다.
- t1-diagnostic-test.log:4375~4382 (탭 직전): candidate2014 frame=(24,420.6667,354,392.6667), isHittable=true/isSelected=false. ScrollView frame=(24,140,354,446.3333), 따라서 후보는 아래가 잘린 부분 노출 상태다. wheel frame=(24,594.3333,354,120), value=60분. minutesLabel value=60. proceed disabled/label="버스와 도착지를 선택하세요".
- 같은 로그:4832~4839 (탭 직후): candidate.isSelected=false, wheel.value=60분, minutesLabel=60, proceed disabled/동일 라벨. :5245에서 기대 "이 여정 준비하기"와 actual "버스와 도착지를 선택하세요"로 assertion 실패. 분 값 변경으로 인한 선택 해제의 증거는 없다.
- 실제 xcresult(Test-FocusMate-2026.10.14_08-40-11-+0900.xcresult)의 candidate 탭 Synthesized Event binary plist를 xcresulttool get object --legacy --format raw로 추출하고 plistlib로 읽었다. down/up 좌표 모두 (59.4000005275,459.9333339185), window 402×874. 이 좌표는 후보 및 ScrollView 가시 프레임 안이고 wheel의 보고 프레임 위다.
- xcresulttool export attachments로 탭 직전/직후 PNG를 추출해 직접 확인했다. 후보는 큰 자동 둥근 테두리 모양이며, 텍스트 첫 줄 일부가 배경의 왼쪽 위 바깥으로 나간다. 위 탭 좌표도 후보 프레임에는 속하지만 둥근 배경 바깥이다. 탭 전후 화면은 선택 변화가 없다.
- 판단: XXXL에서 길어진 bordered 후보 버튼의 자동 테두리 모양과 직사각형 접근성 프레임/탭 위치가 어긋나 선택 동작이 누락된다. 위 관찰에 근거해 테두리 모양 한 변수만 변경했고 원래 실패 테스트가 PASS하여 이 수리의 효과를 직접 확인했다. 내부 UIKit hit-test 수신 뷰를 직접 계측한 것은 아니므로 wheel의 내부 hit 영역이나 실제 이벤트 수신 뷰까지 확정했다고 주장하지 않는다. 테스트 결함의 근거는 없다.

추출 파일(현재 W10 내):
- t1-diagnostic-attachments/96CE99ED-C4E7-48DD-875D-1FE804BBCAFE.png: 탭 직전 화면
- t1-diagnostic-attachments/28057ECF-5661-4EBA-86F9-03830017D0E0.png: 탭 직후 화면
- t1-diagnostic-attachments/activities.json 및 candidate-tap.plist: 실제 탭 좌표 근거

### 구현 내용 / 최소수정
- ios/FocusMate/TimeSelectionView.swift:78, 후보 버튼에 `.buttonBorderShape(.roundedRectangle)` 한 줄만 추가했다. 버튼의 자동 둥근 형태 대신 둥근 사각형을 사용하여 가시 후보의 탭 위치가 버튼 모양 안에 들어오도록 했다.
- 선택 액션, 분 Binding, 1분 단위, 20초 spike, 동적 글자 크기, 휠 높이·스타일, 진행 버튼, CardIssuanceView, 테스트는 변경하지 않았다. clip/contentShape/진단용 프로덕션 분기는 추가하지 않았다.
- API 확인: Apple 공식 buttonBorderShape 문서 URL과 설치 SDK SwiftUI swiftinterface의 iOS15+ `buttonBorderShape(_:)`/`roundedRectangle` 선언을 확인했다. 실제 iOS 빌드도 단독 명령에서 성공했다.
  https://developer.apple.com/documentation/swiftui/view/buttonbordershape(_:)

### GREEN 증거 / 실제 results
1. 원래 실패 단독 명령:
```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=D3BB49D7-3834-4BC9-B910-1CADD9E036E1' -derivedDataPath .build/ios -parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:FocusMateUITests/LargeTextUITests/testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow test CODE_SIGNING_ALLOWED=NO
```
로그: .dev/codex-feat-card-customization/t1-fix-single.log
종료코드 0, 1 pass / 0 fail. 실제 준비 진입과 minutes60/busID2014/destination성동구민체육센터 assertion 통과.
```text
Executed 1 test, with 0 failures (0 unexpected) in 18.615 (18.619) seconds
** TEST SUCCEEDED **
```
결과 번들: .build/ios/Logs/Test/Test-FocusMate-2026.10.14_08-43-27-+0900.xcresult

2. 지정된 관련 focused 명령:
```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateUITests/LargeTextUITests.swift ios/FocusMateUITests/TimeSelectionUITests.swift ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift
```
로그: .dev/codex-feat-card-customization/t1-fix-focused.log
종료코드 65. **테스트 실행 전 컴파일 실패**, 실행된 테스트 0건. 0 failures/PASS로 간주하지 않는다.
```text
ios/FocusMateTests/CardPhotoTestFixtures.swift:58:50: error: cannot find type 'CardPhoto' in scope
ios/FocusMateTests/CardPhotoTestFixtures.swift:63:49: error: cannot find type 'CardStyle' in scope
ios/FocusMateTests/CardStyleTests.swift:7:42: error: cannot find type 'CardStyleValidationIssue' in scope
ios/FocusMateTests/CardPhotoProcessorTests.swift:8:49: error: cannot find type 'CardPhotoProcessingIssue' in scope
Testing cancelled because the build failed.
** TEST FAILED **
(5 failures)
```
끝의5 failures는 실패한 build command 수이며 테스트 실패 수가 아니다. focused 필터는 실행할 시험을 제한하지만 scheme의 FocusMateTests 컴파일까지 생략하지 않는다. 작업 시작 git status에 없던 CardStyleTests.swift/CardPhotoProcessorTests.swift/CardPhotoTestFixtures.swift가 단독 명령 이후 상태 조회에서 untracked로 나타났다. 본 implementer가 작성하거나 수정한 파일이 아니다. 아직 없는 T2 타입 참조로 build가 차단됐으며 TimeSelectionView 단독 수리 범위에서 해결할 수 없다. 해당 시험들을 수정·삭제·제외하거나 누락 타입을 범위 밖에 구현하지 않았다.

### REFACTOR 내역
별도 정리 없음. GREEN 수리는 한 줄이고 추출·이름 변경으로 얻을 중복 제거가 없다. 관련 focused가 빌드 차단된 상태에서 추가 정리를 하지 않았다.

### self-review 결과
- 최종 소스 diff는 TimeSelectionView.swift 한 줄 추가뿐이며 git diff --check 통과.
- 세 focused 시험 파일의 Git blob SHA-1은 작업 전후 모두 t1-test-hashes.json과 일치한다: LargeText ef81d6e4c67e92d5581a32962fad2dd9ced8b323, TimeSelection 9d2e7f657069955ee87660009438ab737d75d109, SimulatorLargeTextRecovery bc7bae3b78d1511163b45949ce846e1289529ae2.
- 원본 테스트는 실제 앱의 선택·진행·준비 화면과 실제 여정 진단값을 검사한다. 기대값·XXXL 런치·접근성 식별자를 변경하지 않았다.
- 과잉 구현 없음. 테스트 수정/추가/삭제, commit/push, 다른 worktree 변경, agents 호출 없음.
- 단독 로그는 완전히 무경고가 아니다. 기존 CardIssuanceView.swift:14의 main actor-isolated static property 경고와 Xcode AppIntents/시뮬레이터 접근성 번들 중복·debugger 노이즈가 있다. 이 수리의 컴파일 오류는 없지만 깨끗한 출력이라고 주장하지 않는다. 범위 밖 경고는 수정하지 않았다.

### 우려사항 / 오케스트레이터 경계
- 관련 3개 파일의 이번 수리 후 통합 GREEN 증거가 아직 없다. AC33와 TimeWheelSpike의 이전 PASS는 보존되지만 이번 관련 명령에서는 실행되지 않았고 진단 AC32도 아직 수리 후 실행되지 않았다.
- 오케스트레이터가 T2의 RED 파일과 프로덕션 타입 간 빌드 상태를 정리한 후 위 동일 관련 focused 명령을 재실행해야 한다. 테스트 무결성·소유 범위상 이 implementer는 차단 파일을 수정하지 않는다.
- 수정은 실제 단독 GREEN 상태로 남겨 인계한다. 전체 회귀·실기기/VoiceOver 완료는 주장하지 않는다.

## 부모 직접 verify_implement
관련3개 UI파일 실제13/13PASS, 0fail, exit0(215.160초). 원본AC32, 신규32/33, 9time선택시험과20초wheel동작assert 모두통과. 임시T2시험분리·복원before/after SHA256동일(t1-displacement.json), T1 UI3개Gitblob해시불변. 새public API/과잉구현없음. 생산1file한줄이며fix-round없어태스크review skipped; 전체브랜치review예정.
