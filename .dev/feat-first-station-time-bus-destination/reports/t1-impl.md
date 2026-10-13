# T1 IMPLEMENT (세션) — 도메인 규칙

## 구현 내용
- ios/FocusMate/RouteData.swift: `StopPosition`, `RouteStops`(9개 순환 정류장 id·이름, wrap, name(at:), boundLabel, position(of:) — id로만), `StationOption`(index·방향·별칭으로 생성, boundLabel·snapshot 계산), `StationCatalog`(3건, search: trim+lowercased, 이름·방면·별칭 부분 일치), `BusLine`(2014/302(강남02)/421(343)).
- ios/FocusMate/JourneyPlanner.swift: `JourneyCandidate`(distanceText·accessibilityLabel), `JourneyPlanner`(15...360, 초기 25, clamp, candidates — 나누어떨어지는 버스만, 도착지 = name(at: index + direction*stops), distanceText — 0.01km 정수 연산).

## GREEN 증거
- `FOCUSMATE_SIMULATOR_ID=65C4EB57-… python3 scripts/check-ios.py test ios/FocusMateTests/StationCatalogTests.swift ios/FocusMateTests/JourneyPlannerTests.swift` → Executed 27 tests, 0 failures.

## REFACTOR 내역
- 거리 상수 `hundredthsKmPerStop`로 이름 부여. 그 외 정리 없음.

## self-review 결과
- 완전성: AC-2·3·11(후보)·12~17(후보)·23(문자열) 단언 모두 통과.
- 품질: 순수 값·함수, SwiftUI·저장 의존 없음. 부동소수점 미사용.
- 규율: 테스트 파일 미수정(해시 동일). 인터페이스 외 공개 멤버 없음 — `StationOption.init(index:direction:aliases:)`는 카탈로그 정의용 생성자(설계서 인터페이스가 생성자를 명시하지 않음).
- 테스트: 웹 프로토타입 공식으로 손 계산한 리터럴과 일치.

## 우려사항
없음
