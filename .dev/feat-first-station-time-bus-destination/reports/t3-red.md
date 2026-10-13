# T3 RED report

- 테스트 파일: ios/FocusMateTests/JourneyStartModelTests.swift (케이스 14건, 전문은 해당 파일 참조)
- 실행: FOCUSMATE_SIMULATOR_ID=65C4EB57-5CAD-4C4C-9FA5-1EF70EF47DEA python3 scripts/check-ios.py test ios/FocusMateTests/JourneyStartModelTests.swift
- 결과: 컴파일 실패(예상). 누락 심볼:
  - AppModel.confirmInitialStation(_:)
  - AppModel.proceedToPreparation()
  - AppModel.journeyPlan
  - AppModel.preparedJourney / journeyOrigin / journeyCandidates / journeyProceedState
  - Destination.time (title "시간 선택"), Destination.mainMenu, Destination.mainMenuTarget
- 케이스: 확정 저장 바이트 decode, 확정 후 route/path, 저장 실패 유지, 재시도 성공, 메인 거부(쓰기 0), 진행 성공(AC-21), 연타 중복 없음, 60분 미선택 차단, 뒤로가기 유지(AC-22), 메인 재진입 유지, 기본값(AC-26), 출발 위치/후보, 미지 id, 메뉴
- 참조: AppFoundationTests.swift(250~310), StorageTestSupport.swift
- 가정: ProceedState/JourneyCandidate/JourneySelection Equatable, StationOption.snapshot.id/direction 존재, StopPosition(index:direction:) 라벨, JourneyCandidate.bus.id
