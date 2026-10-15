# T6 RED 보고
## 케이스
- JourneyTimerUITests (9): V1 2, V2 3, V3 1, V8 3
- JourneyTimerLifecycleUITests (9): V4 3, V5 3, V6 4(AC24, AC25, AC26 x2)
- JourneyTimerAccessibilityUITests (5): V7 5
- 지원: UITestLaunchSupport(relaunch(extraArguments:), 타이머 공용 헬퍼), DepartureBriefingUITests(journey.timer.remaining 대기, 뒤로가기 단계 제거, 이름에서 "뒤로 메인" 제거)
## 실패 확인
명령: check-ios.py test ios/FocusMateUITests/JourneyTimerUITests.swift (로그 /tmp/red-t6.log)
컴파일 성공, 9건 모두 실패(Executed 9 tests, 9 failures). 사유: 신규 시드/식별자 부재로 setup 대기 실패(Missing diagnostic/요소 부재 assertion). 예: journey.timer.remaining 부재, test.failNextSave 부재.
## 참조 파일
design.md, prd.md, UITestLaunchSupport, DepartureBriefingUITests, ActiveJourneyMainUITests, BoardingTagUITests, BoardingLargeTextUITests, StorageRecoveryFlowTests, CardStorageFlowTests, CardIssuanceFlowTests (grep: 전체 FocusMateUITests)
## 우려
- test.persistedBytes가 UTF-8 JSON 문자열이라고 가정(root.state...active 재귀 탐색).
- "쓰기 횟수"는 직접 측정 수단이 없어 persistedBytes 변화/값으로 대체.
- V6 무효 v3 시드는 route 없이 실행(active 없으면 route가 throw). 카드 유지는 snapshot cards.items로 확인.
- 연타는 UI상 2번째 탭이 버튼 소멸로 불가할 수 있어 존재할 때만 탭.

## 수정 R1
test.persistedBytes는 base64 문자열이다. UITestLaunchSupport.swift의 persistedJourney()를 Data(base64Encoded:) 디코드 후 JSON 파싱으로 수정했다. 다른 T6 케이스는 변경 없음. UI 테스트는 재실행하지 않았다(구현 전).

## 수정 R2
test.snapshot은 마지막 저장 성공값이므로 실시간 진도 단언은 test.timer의 elapsed로 교체: V2 AC10(99), V2 AC4/5(150), V2 AC6(95), V5 AC7(복귀 후 저장 700 + 실시간 700; 진입 시 (100,false)는 T5 AC-7 단위 테스트 담당), V7 AC30(150). 저장값 의미의 memoryElapsed(0/90/1500/120)는 유지. 결과(/tmp/t6fix.log): 두 파일 19 tests, 0 failures.
