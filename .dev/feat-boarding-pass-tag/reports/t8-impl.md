# T8 IMPLEMENT — 여행·출발 안내 화면 + 가장 큰 글자

## 구현 내용
- 신규 `JourneyView.swift`: 바깥 JourneyView가 onAppear에서 DepartureBriefingController를 한 번만 만들고 JourneyScreen에 전달. 출발 확인 전: 어두운 그라데이션 + 버스 아이콘 + 같은 자리 문장 1개(`journey.briefingSentence`, 동작 줄이기면 세 문장 묶음) + '시작'(`journey.start`, AccessibilityFocusState ← focusTarget) + 저장 실패 문구, 뒤로가기·내비게이션 바 숨김, 안내 단계 표지 `journey.briefing`(별도 1pt 요소). 시작 후: 임시 화면 `journey.placeholder`('여행'), 기본 뒤로가기 → 메인. 바깥 컨테이너 `screen.journey`(ZStack — Group은 식별자를 자식에 덮어써 교체). scenePhase background → reset, active → begin 재시작. DEBUG test.briefing.
- `DestinationScreen.swift`: `.journey` → JourneyView.
- `DepartureBriefingController.swift`: sentences·interval을 nonisolated(기본 인자 참조 경고 제거).

## GREEN 증거
DepartureBriefingUITests 2/2, BoardingLargeTextUITests 1/1(XXXL: 여행 시작하기 → 버스에 탑승하기 → 시작까지 도달).

## REFACTOR 내역
없음.

## 우려사항
없음. 구현 중 식별자 노출 문제 2회(Group 수식어 분배, 중첩 컨테이너 흡수)를 수정.
