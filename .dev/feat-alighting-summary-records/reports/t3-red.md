# T3 RED 보고
테스트 파일: ios/FocusMateTests/ArrivalBriefingControllerTests.swift (11건), ios/FocusMateTests/JourneyTimerArrivalProgressTests.swift (5건). 총 16건.
컨트롤러 파일: 내용 3(문구, 카탈로그 밖 버스 nil, 밖 도착지 nil), 순서 진행, reduceMotion, reset 후 재시작, 진행 중 reset 토큰, 확인 전 rejected, 확인 시 ensure->confirm .done, saveFailed 표시, 재시도 누적 2회+표시 해제.
타이머 파일: 도착 isArrived true, 진행 중 false, 미도착 ensure 저장 0회, 실패 후 ensure 재저장(1500,true) 성공 true, 이미 성공이면 추가 저장 없음.
명령: FOCUSMATE_SIMULATOR_ID=7D81AFEE-... python3 scripts/check-ios.py test <두 파일> > scratchpad/t3-red.log
실패: 컴파일 에러 (cannot find type 'ArrivalProgress', no member 'ensureArrivalSaved', ArrivalBriefingController/Content 미존재) = NoSuchMethod RED.
참조 파일: DepartureBriefingControllerTests, JourneyTimerControllerTests(앞 150줄), BoardingTestDoubles, JourneyLifecycleTestDoubles, JourneyTimerTestDoubles(grep), CardIssuanceTestDoubles(grep)
