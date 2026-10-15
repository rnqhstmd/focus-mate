# T3 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/JourneyMapController.swift (신규): @MainActor @Observable 연결부. 저장자·타이머 의존 없음(BR-6). sync는 상태 변화 반영 후 위치·남은 값 재계산, follow일 때만 카메라 목표 재발행(revision+1). setReduceMotion, followTapped(유효하면 재정렬), 시트/테마/정류장/leave 위임. routePoints·visibleStops·destinationStop 계산 프로퍼티.
- ios/FocusMate/JourneyCourseProgress.swift: CourseJourney.init?(journey:) — 카탈로그 밖 정류장·버스, 나누어떨어지지 않는 분, 저장 도착지≠계산값이면 nil.

## GREEN 증거
focused 5파일 → Executed 63 tests, 0 failures. (nextStop 제거 후 JourneyMapControllerTests 18/18 재확인)

## REFACTOR 내역
정리 없음.

## self-review 결과
- sync는 status가 바뀐 경우에만 timerStatusChanged를 호출(같은 상태 반복 호출이 시트를 닫지 않도록 — running 반복은 원래도 무해).
- 테스트 파일 해시 일치.

## 우려사항
없음

## 과잉 구현 정리
- 제거: JourneyMapController.nextStop(설계 인터페이스에 없고 테스트 미참조). 뷰는 nextStopIndex로 이름을 찾는다.
