# T4 IMPLEMENT 보고
## 구현 내용
- 신규 ios/FocusMate/AppModel+JourneyTimer.swift: `JourneyProgressSaving` 프로토콜, `hasDepartedJourney`, `saveJourneyProgress`(ready(main)·active·id·departed 가드, 쓰기 생략 없음, records 불변).
- ios/FocusMate/AppModel.swift: loadSnapshot이 active에 restingForLaunch를 메모리에만 적용, open(.board/.boarding)에 hasDepartedJourney 가드, goBack에 journey+departed 가드.
- ios/FocusMate/AppModel+Boarding.swift: showBoardingPass(confirmPreparation 이전)·openBoarding·boardJourney에 departed 가드, confirmDeparture 성공 시 discardConfirmedPreparation.
- ios/FocusMate/JourneyServices.swift: AppModel이 JourneyProgressSaving 채택.
## GREEN 증거
- RED 확인 2단계: (1) 새 API만 추가 → 13 assertion 실패(재승차·로드 정규화·확정값 정리) (2) 전체 적용 → focused 6파일 106 tests, 0 failures.
## REFACTOR 내역
정리 없음
## self-review 결과
테스트 미수정(해시 일치). 프로토콜은 설계상 JourneyTimerController.swift였으나 T4가 먼저 필요해 AppModel+JourneyTimer.swift에 둠(동작 동일).
## 우려사항
없음
