# W16b T5 RED — UI 테스트 전환과 신규 RouteDataUITests

빌드·테스트 실행 없음(구문 검사 `swiftc -parse`만). 실행은 오케스트레이터.

## 변경 파일 (ios/FocusMateUITests)
- UITestLaunchSupport.swift: `XCUIApplication.typeStationQuery(_:)`, `waitForBound(_:)` 추가. `persistedCurrentStation()` 반환을 `(id, name)`으로 변경(direction 제거).
- FirstStationSearchUITests: 빈 검색어는 `search.prompt`만(결과 0건). 결과 id `search.result.seongsu`/`seongsu-r`. "건대" 방면 검색은 이름 검색("성수" 8건 -> "성수역" 2건)으로 교체. 낭독 라벨 "성수역, 성수사거리 방면" 단언 추가. AC-12 무번호정류장(`search.result.S11`, "무번호정류장, 델타 방면") 신규 1건. 저장 스냅샷 direction 단언을 "키 없음"으로 변경.
- StationSaveFailureUITests, LargeTextUITests, SimulatorLargeTextRecoveryTests, TimeSelectionUITests, PreparationFlowUITests: 결과가 검색어 입력 뒤에만 보이므로 `typeStationQuery("성수역")` 추가, id 새 형식. LargeText의 direction 단언 삭제.
- Phase1FlowTests, StorageRecoveryFlowTests: `main.direction == "역방향"` -> `main.bound == "성동구민체육센터 방면"`(ready 시드 seoulForest-r). 스냅샷 단언은 현재 정류장 id `seoulForest-r`, direction 없음.
- JourneyAbandonUITests, NewJourneyUITests: direction 단언을 정류장 이름/id 단언으로 변경(역방향은 `seongsuIntersection-r`).
- MainActiveJourneyCardUITests, NewJourneyUITests: 시드 `v3InvalidMinutes` -> `invalidMinutesJourney`.
- JourneyTimerLifecycleUITests: V6 v3 테스트 4건 정리(아래).
- AlightingFlowUITests: AC-79 하차 뒤 현재 정류장 = 저장 도착 정류장(`alightMismatchArrived`) 1건 추가. (AC-31 UI는 기존 AC-23 테스트가 이미 지도 없음을 검증.)
- 변경 없음: CardStorageFlowTests(원시 v2 손상 시드 바이트 비교라 그대로 유효), 그 밖 파일.
- DataSourceUITests.swift, 단위 테스트는 건드리지 않음.

## 삭제 테스트와 이유 (JourneyTimerLifecycleUITests)
- testV6_AC24_v3_출발_완료_여정은_일시정지로_읽히고_재개하면_v4로_저장된다: v1~v4 진행 여정은 내용을 해석하지 않고 비우므로 "일시정지로 읽힘/v4 저장" 전제가 사라짐.
- testV6_AC25_v3_출발_대기_여정은_출발_안내의_시작_버튼을_보여준다: 같은 이유(v3 여정이 유지되지 않음).
- testV6_AC26_v3_361분_여정...: v3 여정은 해석되지 않아 361분 판정이 무의미. 같은 의도를 현재 버전 시드 `invalidMinutesJourney`로 대체(testV6_AC26_v5_361분_여정은_여정만_버려지고_카드는_유지된다).
- testV6_AC26_v3_카탈로그_밖_정류장...: 저장 시 카탈로그 검증이 없어짐(BR-13이 포기 시점에 처리). RouteDataUITests AC-37~40이 대체.
- 대체 추가: testV6_AC46_v3_여정은_해석되지_않고_비워지며_카드는_유지되고_최초_정류장_화면이_열린다.
- FirstStation의 "AllThreeResults"(초기 3건 나열) 테스트는 AC-6에 따라 prompt 테스트로 의미 변경.

## 신규 RouteDataUITests (AC당 1개)
AC-37 lifeRouteGone700 포기 / AC-38 lifeOriginGone700 포기 / AC-39 같은 상태 새 여정 확정 / AC-40 stationGone 시작 시 안내 / AC-41 ready 방면·정방향역방향 문구 없음 / AC-42 pending main.bound 빈 값 / AC-43 pending 포기 버튼 비활성(test.abandon enabled=false) / AC-44 pending 새 여정 거절·저장 0회 / AC-46·47 legacyV4Stations 이전·안내·정류장 고르면 사라짐 / AC-48 재시작 시 안내 없음.

## 우려사항
- 큰 글씨 UI 테스트(LargeText, SimulatorLargeTextRecovery)는 검색어 입력 키보드가 확인 버튼 접근성에 영향을 줄 수 있음(기존 reach/isHittable 단언 유지). 실행에서 실패하면 키보드 내리기가 필요.
- AC-45(pending 해제 후 재시도)는 pending이 끝나지 않으므로 UI로 검증 불가, 단위 테스트 담당. failed 모드(search.loadFailed)와 AC-7 overflow도 UI 대상 아님.
- 기대 방면값 "성동구민체육센터 방면"과 검색 건수(8/2)는 uiTestFixture를 손으로 계산한 값이다. 어긋나면 픽스처 쪽 계산 확인.

## 전체 실행 후 수정 (21건 중 20건 수정, 실행은 오케스트레이터)
- ready 시드 현재 정류장은 `seoulForest-r`이라 지나는 노선이 2014-r뿐: 후보 식별자를 `time.candidate.2014-r`로 변경 (PreparationEditorUITests 헬퍼 전체 + busID 단언 "2014-r", BoardingFlowUITests 2곳, PreparationFlowUITests ready 시드 테스트 / 헬퍼에 routeID 인자 추가, 검색 경로는 기본 "2014").
- TimeSelectionUITests: 61분에도 60분 후보가 남으므로 testChangingMinutesClearsSelectionImmediately를 "후보는 남되 선택 해제, 버튼 '버스와 도착지를 선택하세요' 비활성"으로 변경. 0건 문구는 "이 시간에 맞는 버스가 없어요".
- JourneyMapUITests: AC26 저장 버전 5(테스트 이름 포함). AC21 경로 점·정류장 마커 수를 6으로(2014-r 5구간 + 출발, 닫는 선 없음). 마커 6은 visibleStops = 코스 정류장 전체라는 계약에 따른 추정이며 실행에서 확인 필요.
- ProfileUITests AC23: 버튼 4개(뒤로, 카드 꾸미기, 설정, 데이터 출처).
- 확인 필요(수정 안 함): CardCustomizationFlowTests test12_XXXL에서_도구와복원이_고정저장위로_도달한다 (:470) — 이번 변경과 무관해 보임.
- 오케스트레이터: CardCustomizationFlowTests.open()이 큰 글자에서 메인 "카드 꾸미기" 버튼을 화면 하단 120pt 위까지 스크롤한 뒤 누르도록 수정. 저장 뒤 다시 열 때 버튼이 화면 맨 아래에 걸려 탭이 빗나갔다(main 6542996에서는 통과 — 방면 줄이 "역방향"보다 길어 레이아웃이 내려감). 단독 재실행 통과
