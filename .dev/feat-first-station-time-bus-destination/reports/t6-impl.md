# T6 IMPLEMENT (세션) — 시간 선택 화면 UI

## 구현 내용
- ios/FocusMate/TimeSelectionView.swift: 제목(screen.time), 출발지(time.origin, value=저장된 이름) + 방면 문구, 현재 분(time.minutesLabel, value "N"), 휠 Picker("여행 시간", 15~360 "N분", 접근성 수정자 없음, 바인딩 set = journeyPlan.setMinutes), 후보 버튼(time.candidate.{busID}, label = JourneyCandidate.accessibilityLabel, 선택 시 .isSelected, 탭 = journeyPlan.choose), 하단 진행 버튼(time.proceed, label = journeyProceedState.title, .ready 아니면 disabled, 탭 = proceedToPreparation). 애니메이션·자동 스크롤 없음.
- ios/FocusMate/RootView.swift: 메인 메뉴를 Destination.mainMenu로 순회하고 open(destination.mainMenuTarget) — "여행 준비"(open.preparation)가 시간 선택을 연다. `.time`이 메뉴에 나오지 않는다.

## spike 결과 (설계 판단 6 (b))
- testTimeWheelSpike 통과: pickerWheels 1개, 초기 "25분"/"25", 25→360·360→15 각각 20초 이내(테스트 전체 24.7초), 60→61 일치. → 휠 유지, 대안 (c) 미사용.

## GREEN 증거
- TimeSelectionUITests → Executed 9 tests, 0 failures.
- 회귀(Phase1FlowTests·FirstStationSearchUITests·StationSaveFailureUITests, 단위 63): 아래 "회귀" 절 참조.

## REFACTOR 내역
- origin 영역의 "출발 정류장을 확인할 수 없어요" 중복 문구를 제거(진행 버튼 문구가 같은 안내를 이미 함).

## self-review 결과
- 완전성: AC-10·11·12·17·18·19·20·23(UI) 통과.
- 품질: 화면은 모델 계산 속성만 읽고 상태 변경은 JourneyPlanDraft·AppModel 함수로만.
- 규율: 테스트 해시 동일.

## 우려사항
없음

## 회귀
- Phase1FlowTests 10 + FirstStationSearchUITests 7 + StationSaveFailureUITests 3 → Executed 20 tests, 0 failures.
- 단위 focused 63 → 0 failures.

## FIX R1 (리뷰 정리)
- 후보 버튼 화면 문구 "N min" → "N분"(Ruling: T6 리뷰 Important 분류). TimeSelectionUITests 재실행 결과는 t6-fix1-run.log.
