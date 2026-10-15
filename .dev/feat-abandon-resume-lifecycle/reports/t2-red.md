# T3(JourneyAbandonController) RED 보고

테스트 파일: ios/FocusMateTests/JourneyAbandonControllerTests.swift, ios/FocusMateTests/JourneyLifecycleTestDoubles.swift (코드 전문은 해당 파일 참조)

## 케이스 (12)
1. AC21 요청 두 번 = 하나
2. BR6 일시정지 아니면 열지 않음
3. AC15 취소 → 닫힘, 호출 0, 포커스 abandonButton
4. AC21 확정 → 닫힘, 호출 [true], 완료, 포커스 nil
5. AC21 확정 두 번 → 호출 1
6. R2 확정→취소: 호출 1, 포커스 nil
7. R2 취소→확정: 호출 1, 포커스 nil
8. BR6 .rejected: 표시 없음, 인자 false 전달
9. AC20 .saveFailed: showsFailure, 포커스 abandonButton
10. AC20 재시도 성공 (request가 실패 표시 지움, calls [true,true])
11. AC20 clearFailure
12. AC21 완료 뒤 request 무시

## 명령
cd /Users/bonseung/Documents/ChatGPT/new-w07 && FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyAbandonControllerTests.swift

## 실패 메시지
Cannot find type 'LifecycleActionResult' in scope (미정의 심볼 컴파일 실패) / ** TEST FAILED ** (5 failures)

## 참조 파일
design.md(grep + 405-425행), DepartureBriefingControllerTests.swift, JourneyTimerTestDoubles.swift. 프로덕션 코드는 읽지 않음.
