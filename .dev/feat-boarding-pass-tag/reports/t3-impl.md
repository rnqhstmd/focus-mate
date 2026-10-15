# T3 IMPLEMENT — 모델·내비게이션·메인 동작

## 구현 내용
- `AppModel.swift`: `Destination`에 board/boarding/journey(제목 승차권/승차 태그/여행), `journeyFactory` 주입(기본값, 기존 호출부 무영향), `open()`에 board/boarding 가드(확정 준비 없으면 무시).
- `AppModel+JourneyStart.swift`: `Destination.mainMenuTitle`("여행 시작하기"), 주석 갱신.
- 신규 `AppModel+Boarding.swift`: activeJourney, showBoardingPass(확정 + 연타 가드), openBoarding(쓰기 0), boardJourney(현재 확정 준비로 교체 저장), finishBoardingTransition(path = [.journey]), confirmDeparture(멱등), startTripFromMain(있으면 폐기 저장 성공 시에만 시간 선택).

## GREEN 증거
focused 8파일 141 pass / 0 fail (BoardingModelTests + T1·T2 + AppFoundation·JourneyStartModel·PreparationModel 회귀).

## REFACTOR 내역
정리 없음.

## self-review 결과
- consumePreparationRequest 미사용(설계 2회차). `.journey` open 가드 없음(직접 경로 교체만).
- journeyFactory는 확장 파일에서 접근해야 해 internal `let`.
- records 경로 미접촉(BR-9).

## 우려사항
없음.
