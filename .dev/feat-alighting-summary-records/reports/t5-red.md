# t5-red 보고

## 신규 케이스 (총 27건)
- AlightingModelTests.swift 25건: AC10 beginAlighting 성공/미도착 rejected, BR-1 confirmArrival, confirmArrival 미도착 saveFailed/중복 rejected/timerArrived false rejected, AC10 하차 저장, AC11 재호출, AC12 실패 불변/재시도, AC13 재로드, 위험1 진도저장 false, 전환, AC16, AC19, AC17, AC20, AC21(open 시작계열/하차계열, confirmNewJourney, 메뉴, goBack 하차태그/요약), AC32 통계
- ActiveJourneyCardContentTests.swift 2건: showsAlight (도착 true+resume false / 진행 false)
- JourneyLiveActivityPolicyTests AC-5: 추가 안 함 -- 기존 커버 (testV15_AC10_여정이_없으면_전부_종료한다)

## 이전한 기존 케이스
- JourneyLifecycleModelTests testAC24_도착_여정의_새여정_확정... -> testAC21_도착_여정의_새여정_확정은_rejected이고_쓰기가_없고_여정이_그대로다
- RecordStorageTests: saveRecordMemo 5곳 -> updateRecordMemo (.done x3, .rejected(미지원버전), .saveFailed + XCTAssertNil(saveFailure))
- CardCustomizationAppModelTests:156 -> .done
- 그 외 saveRecordMemo 사용처 없음 (grep 확인)

## 명령
cd /Users/bonseung/Documents/ChatGPT/new-w09 && FOCUSMATE_SIMULATOR_ID=7D81AFEE-... python3 scripts/check-ios.py test <6개 파일> > scratchpad/t5-red.log

## 실패 메시지 (컴파일 RED)
- ActiveJourneyCardContent has no member 'showsAlight'
- extra argument 'recordClock' in call
- AppModel has no member 'beginAlighting' / 'confirmArrival' / 'alightJourney' / 'finishAlightingTransition' (이후 .done 등 연쇄 오류)
- Destination has no member 'alighting' / 'alightingSummary'

## 참조 파일
JourneyLifecycleModelTests, JourneyLifecycleTestDoubles, RecordStorageTests, StorageTestSupport, ActiveJourneyCardContentTests, JourneyLiveActivityPolicyTests, ProfileModelTests(220-261), ProfileStatsDisplayTests(1-30), BoardingTestDoubles(1-50), CardCustomizationAppModelTests(140-165), JourneyTimerModelTests(1-60), grep 결과. 프로덕션 코드는 grep으로 RecordSnapshot 선언 첫 줄만 우연히 노출됨(열람 안 함).
