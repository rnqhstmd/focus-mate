# 이전 미확인 항목 시뮬레이터 점검

날짜: 2026-10-14 (Asia/Seoul). W10 구현 전 최신 main에서 시작한 브랜치. 프로덕션·시험 코드는 변경하지 않았다.

## 환경과 증거
- iOS 26.5 / FocusMate W13 / D3BB49D7-3834-4BC9-B910-1CADD9E036E1.
- Debug 빌드 직접 실행 exit0, 앱 설치·실행 성공.
- Xcode 27 화면 앱은 Device Hub. Apple 공식 문서: https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub
- CUA Simulator 이름·기존 경로는 없는 앱. Device Hub 본체 실행 후에도 CUA 앱 연결은 -10005 timeoutReached 반복. 접근성 인스펙터는 열렸지만 실제 VoiceOver 탐색/포커스를 관찰하지 못했다.
- 화면은 simctl 실제 화면 캡처를 view_image로 직접 확인. 자동 시험은 실제 Simulator의 기존 XCUI 검사를 실행했다. 자동 검사와 실제 VoiceOver 수동 확인을 구분한다.

## 직접 관찰
- issuance-start.png: 발급 전 제목·설명·발급 버튼 표시.
- live-01.png: 가장 큰 글자에서 제목 물음표가 한 줄 분리되고 본문 일부가 고정 발급 버튼 뒤에 보임. 가독성 개선 후보. 본문 끝까지 스크롤 도달 가능 여부는 미확인.
- live-06.png: 가장 큰 글자 시간 선택에서 후보 아래가 스크롤 경계에서 잘리고 고정 Picker가 이어짐. 25분 화면이며 실패했던60분 화면의 정확한 탭 좌표 증거가 아님.
- live-07.png: 가장 큰 글자 저장 정리 확인 설명은 세로로 길어짐. 스크롤/확인/취소 기능은 기존 UI 시험이 검증하고 있음.
- live-08.png·live-11.png: 저장 오류 원인·재시도·정리 버튼 표시.
- live-03~05·live-09~10은 앱 실행 사이 빈 화면/홈 전환으로, 정상 제품 화면 완료 증거로 쓰지 않는다.

## 발견된 실패
- LargeTextUITests.testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow:60.
- 새UUID + cardOnly + 접근성XXXL → 성수역 정방향 → 60분 → 2014 후보 탭.
- 기대 진행 문구: 이 여정 준비하기. 실제: 버스와 도착지를 선택하세요.
- 60분 값과 후보 존재/hittable 검사는 통과했다. 후보 탭 전 reach는 스크롤하지 않았다.
- 원인 후보는 부분 노출 후보의 실제 탭 경로 또는 Picker 값 변화/선택 해제. frame·탭 좌표·탭 후 휠 값 증거가 없어 확정하지 않는다.
- W01 trust-ledger에도 같은 XXXL 시험 실패가 기록되어 있다. W10 구현으로 생겼다고 표시하지 않는다.

## 남은 직접 확인
- W01 실제 VoiceOver 단일 카드 요소·장식 비노출·발급 완료 직후 포커스.
- W02 실제 VoiceOver 휠 한 칸=1분·Reduce Motion 비교.
- W13 실제 확인/취소/실패 후 VoiceOver 포커스.
- 최대 글자 본문 끝까지 스크롤 도달, 시간 후보의 정확한 탭 경로.
- 햅틱 체감·실기기 오디오/잠금 생명주기는 실기기 필요.
- Phase0 태그 선택/최신 승차는 웹 직접 확인 대상이고, 현재 iOS 미구현 화면을 이 검사로 완료 처리하지 않는다.

## 자동 검사 결과
첫 실행: UI31개 중29 PASS/2 FAIL, xcodebuild exit65.
- CardIssuanceFlowTests 11/11 PASS.
- LargeTextUITests 1/2 PASS, 최대글자60분→2014 선택→준비 실패.
- StorageRecoveryFlowTests 9/9 PASS.
- TimeSelectionUITests 8/9 PASS. testTimeWheelSpike는360분 이동24.8606초로20초 기준 초과. 실제 분값 오류와 구분한다.
- 로그: /tmp/focusmate-w10-simulator-tests.log.
- 결과 번들: .build/ios/Logs/Test/Test-FocusMate-2026.10.14_07-42-54-+0900.xcresult. collect-test-diagnostics never 조건의 번들에는 실패 화면 첨부가 없었다(export manifest에0건).
- 두 실패만 재실행: 2개 중1 PASS/1 FAIL, exit65.
- XXXL60분→2014→준비 실패는 동일하게2회 재현.
- testTimeWheelSpike는재실행PASS. 첫24.86초 초과는기록하고 자동화/환경 영향과 실제휠 성능 문제를 구분할 추가 근거가 필요하다.
- 재실행 로그: simulator/recheck.log.
- 확인 가능한 동작의 검사는 마쳤으나 전체통과로 표시하지 않는다. 실제VoiceOver·Reduce Motion 직접 비교는 CUA 연결 문제로 계속 미확인이다.

## W10 상태
사진 입력/보존 정책 질문은 별도 pending 유지. 이 점검으로 PRD 승인·설계·구현 게이트를 통과했다고 처리하지 않는다.

## W02 큰 글자 수리 직접 재검증
2026-10-14: 후보 Button의 borderShape를 roundedRectangle로1줄정정. 원래AC32 실패테스트와신규진단시험모두준비진입성공;관련13UI/0fail exit0. 직접읽은후보탭전후UI에서 selected false→true, proceed disabled→enabled,60분유지. xcresult screenshot 두장선택추출·직접이미지열람: t1-after-selection.png(후보부분노출/선택체크/활성준비버튼), t1-preparation.png(준비화면). 후보모든문구가스크롤없이보이는것이나실제VoiceOver는확인안됨. 진단테스트는해당기능동작근거이며시각전체완료와구분.

## iOS27 실제 VoiceOver 1차
독립 HEAD5b7af0f 복사프로젝트, 신규전용Simulator F226C28A...에서API enable/moveForward/currentSpeech/Output.utterance 실행실제성공. 4UI/2PASS2FAIL. W01카드단일이미지·독립장식없음/발급완료출발지버튼focus와W13백업실패안내focus PASS. W02는wheel찾기에서static분label을선택했고, W13취소는actual오류제목focus관찰했으나test목표가원인본문만허용한오류. 두fail은locator보강후재실행필요하며제품버그/PASS로단정않음. 음성출력텍스트는label모방없이service.actualutterance를기록. voiceover-native-test.log. W01타이틀/정류장label+value가같은정보를반복낭독하는관찰도후속UI리뷰항목으로보존.

## 실제 iOS27 VoiceOver 추가 검증
이전 미확인 VoiceOver를 Xcode27의 실제 service로 보강했다. 별도 immutable HEAD app probe이며 W10 최종 화면 검증과 구분한다. W01 완료 포커스/카드 단일요소 및 W13 백업실패 안내가 초기 실행에서 PASS. W02는 실제 wheel speech를 관찰한 뒤 대상식별을 수정해 focused1/1 PASS: before `25분 선택기 항목 조절 가능 총 346개 중 11번째...`, 실제 swipeUp 뒤 `26분 총 346개 중 12번째`. 실제 value25→26/service enabled/current speech26 assertion 모두 통과했다. 로그 voiceover-wheel-actual.log. 자동 cleanup 취소포커스는 service No speech available 환경오류 이후 별도 focused 재확인 중이며 아직PASS 아님. 이 결과는 실기기 haptic/audio/lock 검증을 대체하지 않는다.

W13 취소 포커스 focused 재확인 1/1 PASS(44.380초, exit0). 실제 정리 확인 표시 뒤 `저장 데이터 정리 머리말`, 실제 취소 doubleTap 뒤 자동 낭독 `저장된 상태 확인 머리말`; 원본 파일 bytes unchanged 검사도 통과. 로그 voiceover-cancel-focused.log. 앞선 No speech available 오류는 실행 기록에 남기며 이번 성공으로 덮어 지우지 않는다.
