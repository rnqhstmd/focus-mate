# T5 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/JourneyMapView.swift (신규): Map(커스텀 Binding setter에서 positionedByUser → userMovedCamera), interactionModes [.pan,.zoom,.rotate](pitch 제외), MapPolyline 닫힌 코스, 정류장·도착·버스 Annotation(제목 숨김), dark=.standard / satellite=.hybrid 둘 다 POI 제외, 나침반·피치·스케일 숨김, safeAreaPadding(.bottom, 하단 정보 높이), cameraTarget 변화 시 linear 1s(동작 줄이기면 즉시) 적용, onMapCameraChange(.onEnd)로 버스 아이콘 상대 회전, 지도 전체 접근성 요소(라벨·값·식별자 journey.map).
- ios/FocusMate/JourneyMapThemeSheet.swift (신규): 어두운 지도/위성 버튼(isSelected·값), 정류장 표시 토글형 버튼(.isToggle, 값 켜짐/꺼짐), 닫기, detents [.medium,.large](큰 글자면 large), presentationBackgroundInteraction(.enabled).
- ios/FocusMate/JourneyTimerView.swift: map 있으면 지도 배치(상단: 일시정지/재개 원형·도구 2개 세로·안내 배너, 하단: ViewThatFits 남은 시간·정류장·거리), 없으면 W05 배치(legacyBody). MapSync onChange에서 withAnimation(linear 1s | nil) map.sync. DEBUG test.map 진단.
- ios/FocusMate/JourneyView.swift: 타이머 생성 직후 CourseJourney.init?로 지도 컨트롤러 생성(reduceMotion 생성자 전달), onDisappear에서 map.leave(). DEBUG 시계 버튼 줄을 상단 safeAreaInset → 상단 가운데 overlay로 이동(AC-2 상단 20% 배치를 밀어내지 않고, 하단이면 시트에 가려짐).
- ios/FocusMate/UITestBootstrap.swift: timerJourney 도착지를 계산값(성수사거리)으로 정정(v3 시드 파생 포함).

## GREEN 증거
`check-ios.py test JourneyMapUITests AppInfoLocationTests` → JourneyMapUITests 14/14 pass(3회차), AppInfoLocationTests 1/1.
1회차: AC-2 실패(DEBUG 시계 줄 44pt가 상단을 밀어 theme.midY 198 > 0.2H 175). 2회차(시계 줄 하단): AC-24 실패(하단 시계 버튼이 medium 시트에 가려짐). 3회차(상단 가운데 overlay): 전부 통과.

## REFACTOR 내역
정리 없음.

## self-review 결과
- 지도 → 저장 경로 없음(컨트롤러에 저장자 없음).
- 테스트 파일 해시 일치(JourneyMapUITests, AppInfoLocationTests, UITestLaunchSupport, 이전 태스크 테스트).
- W05 회귀(기존 3개 타이머 UI 클래스)는 T6에서 실행.

## 우려사항
- DEBUG 시계 줄 위치 변경이 기존 W05·출발 안내 UI 테스트에 영향 줄 수 있음 → T6 회귀 실행에서 확인.
