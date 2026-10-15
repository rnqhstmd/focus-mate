# T1 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/JourneyCourse.swift (신규): CoursePoint, CourseStop, JourneyCourse(seoulBounds, 정류장 id별 좌표, stops, point(at:), closedPath). 좌표는 실제 위치 근사. 성동구민체육센터·성수사거리는 근사(미검증 — M-5 육안 확인 시 보정).
- ios/FocusMate/JourneyCourseProgress.swift (신규): CourseJourney, CourseBusPosition, JourneyCourseProgress(position/nextStopIndex/remainingStops/remainingDistanceTenthsKm). 정수 산술, 도착 고정, 국지 평면 heading.
- ios/FocusMate/JourneyMapDisplay.swift (신규): 문구·접근성 값. followValue는 JourneyCameraMode(T2) 의존이라 T2에서 추가.

## GREEN 증거
`check-ios.py test JourneyCourseTests JourneyCourseProgressTests JourneyMapDisplayTests` → Executed 25 tests, 0 failures.

## REFACTOR 내역
정리 없음(처음부터 private 헬퍼 travelled/clamped/secondsPerStop로 중복 없이 작성).

## self-review 결과
- 완전성: AC-5~9, 39(계산) 케이스 전부 통과. `CourseJourney.init?(journey:)`는 T3 범위로 미구현.
- 품질: 도착 시 heading은 마지막 구간(도착 직전→도착) 기준.
- 규율: 테스트 파일 미수정(해시 일치).
- 테스트: 기존 테스트 영향 없음(신규 타입만 추가).

## 우려사항
없음

## 과잉 구현 정리
- `JourneyCourse.seoulBounds`: focused 테스트 미참조이나 설계서 인터페이스 명시 → 설계 예약으로 유지.
