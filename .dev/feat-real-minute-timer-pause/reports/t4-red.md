# T4 RED report

테스트 코드 전문: ios/FocusMateTests/JourneyTimerModelTests.swift (신규, 16케이스) 및 ios/FocusMateTests/BoardingModelTests.swift (끝부분 "출발 후 확정값 정리 (T4)" 섹션, 3케이스 추가). 파일을 참조.

## 추가 케이스 (19건)
JourneyTimerModelTests(16): 대기중_여정에는_저장_안함, id_다르면_거부, 진행여정_없으면_거부, 총시간_초과_거부, 음수_거부, 진도_저장_반영+records_불변, 같은_값_쓰기_생략_없음, 도착값_저장해도_기록_0, hasDepartedJourney, 로드시_메모리_paused, 로드_정규화_파일쓰기_0, 도착본_로드_isArrived·기록_0, AC-18 승차권_진입_거부, 승차_저장_거부, 승차태그_진입_거부, open(.board/.boarding)_무시, 여행화면_goBack_무시.
BoardingModelTests(3): 출발확인 후 confirmedPreparation nil, 출발 후 재승차 거부(AC-18), AC-19 회귀(현재 통과, 회귀 보호).

## 실패 확인
명령: FOCUSMATE_SIMULATOR_ID=497AF082-... FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/JourneyTimerModelTests.swift ios/FocusMateTests/BoardingModelTests.swift (로그 /tmp/red-t4.log, exit 65)
실패 메시지: 컴파일 에러(정상 RED) — `value of type 'AppModel' has no member 'saveJourneyProgress'` x18, `... 'hasDepartedJourney'` x6. 다른 에러 없음.

## 우려
- 컴파일 단계에서 막혀 assertion 수준 실패는 GREEN에서 확인 필요(재승차 차단·확정값 정리 케이스는 API가 생기면 assertion 실패해야 함).
- 확정값 정리·재승차 일부 테스트는 hasDepartedJourney 없이도 쓰이므로 BoardingModelTests의 T4 3건은 컴파일은 되나 같은 번들이라 함께 실패.
- ready(main) 아님 가드 케이스는 구성이 어려워 생략.
- 회귀 보호(현재 통과): testAC19_시작_전_대기상태에서는_다시_승차하면_새_id로_교체된다 1건.

## 참조한 파일
BoardingModelTests.swift, BoardingTestDoubles.swift, .dev/feat-real-minute-timer-pause/design.md, 테스트 프로젝트 파일 목록(ls)과 PreparationModelTests.swift 내 confirmedPreparation grep 결과. 프로덕션 코드 미참조.
