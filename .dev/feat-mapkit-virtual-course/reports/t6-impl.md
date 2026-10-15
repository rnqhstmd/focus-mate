# T6 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/JourneyMapView.swift: Map에 `.accessibilityHidden(true)` + 같은 자리 overlay 대표 요소(라벨 "가상 코스 지도", 값 다음/도착 정류장, 식별자 journey.map, hit testing 없음). T0에서 `children: .ignore`가 MapKit 내부(실제 지명 "뚝섬역" 등)를 가리지 못함을 확인 → FR-12 "지도는 하나의 요소" 충족 수단 변경.
- ios/FocusMate/JourneyTimerView.swift: 하단 지표 ViewThatFits → dynamicTypeSize 기반 AnyLayout(HStack/VStack) 단일 인스턴스(ViewThatFits가 두 배치를 만들어 AccessibilityFocusState가 이중 바인딩됨). 하단 글자(12/15/30)를 @ScaledMetric으로 큰 글자에 맞춰 키움(T5 리뷰 Minor 반영).

## GREEN 증거
- JourneyMapAccessibilityUITests 10/10 (AC-37 테스트 결함 재작성 후).
- 회귀: JourneyMapUITests + JourneyTimerUITests + JourneyTimerLifecycleUITests + JourneyTimerAccessibilityUITests + DepartureBriefingUITests → Executed 40 tests, 0 failures.

## REFACTOR 내역
정리 없음.

## self-review 결과
- 지도 내부를 숨기면 Legal 링크도 접근성 트리에서 빠질 수 있음 → AC-3은 테스트 규칙대로 2초 탐색 후 M-1로 대체될 수 있음(테스트는 통과). AC-4 UI 단언도 내부가 숨겨져 공허해짐 → 코드 리뷰 체크리스트로 보증(trust-ledger).
- VoiceOver 초기 포커스는 시뮬레이터 관찰 불가 → M-2.

## 우려사항
없음
