# T6 RED report

## 신규 (13 UI 케이스 + 6 단위 케이스)
ios/FocusMateUITests/AlightingFlowUITests.swift (13): AC1_22(안내 문장 순서·확인·pause/abandon 없음), AC6_7_8_9_21(하차 태그: focus card·뒤로 없음·tapHint·탭만 무쓰기·LCD 카드 이름), AC5_10_15_17(요약→메인, 기록1, 메모, 정류장, LiveActivity 0), AC2(동작 줄이기 즉시 노출), AC3(저장 1500·쓰기1·기록0), AC21(도착 카드 하차하기만), AC4(안내 재실행 후 처음부터), AC14(태그에서 재실행), AC13(요약에서 재실행), AC12(하차 저장 실패), AC18(201자→200), AC20(요약 저장 실패), AC23(지도 생략).
ios/FocusMateTests/LifecycleSeedTests.swift (+6): alight 시드 존재·디코드, 할 일 논문·기록 0, 기본값, 경과 1499/1500/1500, 저장 도착지(seoulForestGate/ttukseom), CourseJourney(journey:) 정상 non-nil / 불일치 nil.
(isArrived는 프로덕션 API라 추측 대신 elapsedSeconds 1499/1500으로 단언.)

## 수정한 기존 테스트
- JourneyTimerUITests:138,150,192 / JourneyTimerLifecycleUITests:107 / JourneyAbandonUITests:99,395 / JourneyMapUITests:176: `journey.arrived` 노출 -> `alighting.briefing` 노출
- JourneyMapUITests AC24(172): 도구 isEnabled true -> 도구 없거나 비활성/비hittable(도착 안내가 가림), 이름 변경
- JourneyMapUITests AC39(257-259): stops "0개"/distance "0.0km" -> `alighting.briefing` 노출 + 그 값이 아님
- JourneyTimerAccessibilityUITests:26: remaining 값 "남은 시간 0분" -> alighting.briefing/alighting.route 존재, remaining 값이 "남은 시간 0분"이 아님
- MainActiveJourneyCardUITests: AC24 "새 여정 시작" 라벨 -> open.alighting("하차하기")만 있고 open.preparation·"새 여정 시작" 없음; 카드 테스트에 open.alighting 존재 단언 추가
- NewJourneyUITests:312,325: 확정 경로 2건 폐기 -> 도착 여정은 open.alighting만, open.preparation·alert 없음, 기록 1건으로 하나로 합침(중복)

## 명령
cd /Users/bonseung/Documents/ChatGPT/new-w09 && FOCUSMATE_SIMULATOR_ID=7D81AFEE-FC29-4E6F-8E2C-195C022C52A6 python3 scripts/check-ios.py test ios/FocusMateTests/LifecycleSeedTests.swift ios/FocusMateUITests/AlightingFlowUITests.swift
로그: /private/tmp/claude-501/-Users-bonseung-projects-focus-mate/79aaedd3-8365-406d-90ad-aa6e6b956c1e/scratchpad/t6-red.log (exit 65)

## 실패 메시지
- 단위 6건: "시드 없음: alightPaused1499/alightArrived/alightMismatchArrived" (XCTUnwrap). 기존 life* 단위는 통과.
- UI 13건 모두 실패(Executed 13 tests, 13 failures): AC12,13,14,18,20,23,4,5_10_15_17 = "open.alighting 없음"; AC1_22,2,3,6_7_8_9_21 = "main.resumeJourney 없음"(시드 미존재로 메인 카드 없음); AC21 = open.alighting waitForExistence false.

## 프로덕션에 요구되는 추측 식별자(설계서에 명시 없음, prefix 규칙 근거)
alighting.card(카드 탭), alighting.lcdStatus(LCD value "집중동행카드", boarding.lcdStatus와 동일 규칙), summary.* 라벨은 label로 단언, test.liveActivity JSON requests[].op "start"/"end" 차이로 활성 수 계산, 기록 메모는 persistedText 부분 문자열로 확인.

## 참조 파일
UITestLaunchSupport, JourneyResumeUITests, BoardingFlowUITests, BoardingTagUITests, JourneyLiveActivityUITests, MainActiveJourneyCardUITests, NewJourneyUITests, JourneyTimerUITests, JourneyTimerLifecycleUITests, JourneyAbandonUITests, JourneyMapUITests, JourneyTimerAccessibilityUITests, LifecycleSeedTests, JourneyMapControllerTests(CourseJourney 사용 예 grep), ArrivalBriefingControllerTests(grep), design.md(grep), testing-anti-patterns 경로는 요약 기준 사용.

## 수정 R1 (테스트 결함 3건, 실행 안 함)
- testAC6_7_8_9_21: alighting.tapHint 존재·문구 단언을 card.tap() 뒤로 이동(AC-8: 터치 뒤 노출).
- testAC4: 재실행 전 확인(showsConfirm true)을 기다려 확인한 뒤 재실행, 재실행 후 openAlighting 직후 showsConfirm false·alighting.confirm 부재, 이후 다시 confirm 노출로 "처음부터"를 시간 경합 없이 검증(index==0/첫 문장 라벨 단언 제거).
- testAC1_22: 문장 폴링 제거, advance 1회. 도착 직후 showsConfirm false·confirm 없음 → 결국 confirm 노출 시 sentence 라벨 "카드를 찍고 내려주세요"·index 2, pause/abandon/arrived 없음·기록 0 유지.

## 수정 R2 (실행 안 함)
도착 시 타이머 내용을 그리지 않아 값 읽기가 "No matches found"로 실패하므로, 요소가 없거나 값이 다르면 통과하도록 변경.
- JourneyMapUITests testAC39: journey.timer.stops != "0개", journey.timer.distance != "0.0km" -> `!e.exists || value != ...`
- JourneyTimerAccessibilityUITests testV7_AC27: journey.timer.remaining != "남은 시간 0분" -> `!e.exists || value != ...`

## 수정 R3 (실행 안 함)
도착 시 타이머·지도 내용은 그려지지 않는 것이 기대 동작이므로 OR 단언을 부재 단언으로 단일화(alighting.briefing 존재 단언 뒤).
- JourneyMapUITests testAC24: journey.map.follow/theme `!exists || !isEnabled || !isHittable` -> `XCTAssertFalse(exists)`
- JourneyMapUITests testAC39: journey.timer.stops/distance -> `XCTAssertFalse(exists)`
- JourneyTimerAccessibilityUITests testV7_AC27: journey.timer.remaining -> `XCTAssertFalse(exists)`

## 수정 R4 (실행 안 함)
journey.pause는 앱에 없는 식별자라 항상 통과했음. 실제 식별자로 교체.
- testAC1_22: journey.pause 부재 -> journey.timer.pause / journey.timer.resume / journey.abandon 각각 XCTAssertFalse(exists, id) (journey.arrived 부재 유지)
- testAC6_7_8_9_21: confirmBriefing(alighting.tag 존재 확인) 직후 같은 세 식별자 부재 단언 추가 (AC-22 하차 태그 화면)
