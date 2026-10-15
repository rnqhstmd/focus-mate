# T0 스파이크 결과 — 지도 접근성·안전 영역 (2026-10-15, iOS 27.0 iPhone 18 Pro 시뮬레이터)

구성: ZStack 바닥에 `Map(position: Binding(setter에서 positionedByUser 검사), interactionModes: [.pan,.zoom,.rotate])`, `.ignoresSafeArea` 없음, `.safeAreaPadding(.bottom, 110)`, `.accessibilityElement(children: .ignore)` + 식별자 `journey.map`, 하단 overlay(높이 110 + `.ultraThinMaterial, ignoresSafeAreaEdges: .bottom`), 시트는 detents [.medium,.large] + `.presentationBackgroundInteraction(.enabled)`. 스파이크 코드는 확인 후 전부 삭제했다.

| 확인 | 결과 | 결정 |
|---|---|---|
| `children: .ignore`가 MapKit 내부를 XCUITest 트리에서 가리는가 | **가리지 못함.** `journey.map`(Other, 라벨 "가상 코스 지도") 아래에 `Map`, `VKPointFeature`(실제 POI: 서울숲역·식당 등), `AnnotationContainer`(Annotation이 "Map pin" + 이미지 `bus.fill`로 노출, Annotation 내용의 `.accessibilityHidden(true)`도 무시됨), `Link 'Legal'`이 보인다 | AC-4 UI 단언은 내부가 보이므로 의미가 있다 → UI 단언(나침반·피치·스케일·사용자 위치 요소 없음) + 코드 리뷰 체크리스트 병행. AC-33 "개별 정류장 미노출"은 Annotation이 트리에 남으므로 판정 기준을 "우리 정류장 표시가 정류장 이름 라벨로 노출되지 않음(annotation title 빈 문자열, 이름 텍스트 없음)"으로 둔다. VoiceOver 실제 낭독은 M-2 |
| 실제 POI 노출 | `VKPointFeature`로 실제 정류장·가게가 지도 요소로 노출(서울숲역 등) | BR-1(실제 운행 오해 방지)·AC-33 혼동 방지를 위해 `pointsOfInterest: .excludingAll`을 dark·hybrid 모두에 적용 |
| 법적 표기 | **찾음.** `Link 'Legal'` frame y=709.3~720.0, 하단 정보 minY=730, x=70 (W 402의 왼쪽 절반) | AC-3 자동화 가능: `app.links["Legal"]`의 maxY ≤ remaining.minY, midX < W/2, 다른 요소와 비교차 |
| 지도가 안전 영역까지 그려지는가 | `Map` 요소 frame (0,0,402,874) 전체 화면 | `.ignoresSafeArea` 불필요 |
| `scrollViews.count` | 0 | W05 V7_AC29 단언 유지 가능 |
| 드래그 → `positionedByUser` | `press(0.1, thenDragTo:)` 1회로 setter의 positionedByUser=true 1회 | AC-14 실제 드래그 UI 테스트 채택 |
| Toggle 값 | `.accessibilityValue("켜짐")` 덮어쓰기는 보이나, 요소 탭 뒤에도 "켜짐" 유지(전환 안 됨 또는 갱신 안 됨) | 설계 대안 채택: `Button` + `.accessibilityAddTraits(.isToggle)` + 값 "켜짐/꺼짐" |
| 시트가 열린 채 배경 일시정지/재개 | `journey.timer.resume` isHittable=true | `.presentationBackgroundInteraction(.enabled)` 채택 |
