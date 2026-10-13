# T4 IMPLEMENT (세션) — 검색 화면 UI

## 구현 내용
- ios/FocusMate/InitialStationSearchView.swift(신규): 제목(screen.initialStationEntry 유지), ScrollView 안 검색창(search.query, label "정류장 검색"), 결과 버튼(search.result.{stopID:direction}, label "{이름}, {방면}", 선택 시 .isSelected), 결과 없음(search.empty "결과가 없어요"), 확인 문구(search.confirmation), 하단 고정 "확인"(search.confirm, 선택 없으면 disabled, hint) → model.confirmInitialStation. 애니메이션 없음.
- ios/FocusMate/TimeSelectionView.swift(신규, 뼈대): 제목 screen.time, 출발지 time.origin(value=저장된 이름). 나머지는 T6.
- ios/FocusMate/DestinationScreen.swift(신규): RootView의 navigationDestination 자리표시 본문을 그대로 옮기고 .time이면 TimeSelectionView.
- ios/FocusMate/RootView.swift: navigationDestination을 DestinationScreen 한 줄로, initialStationEntry 분기를 InitialStationSearchView로 교체(case 줄 유지).

## GREEN 증거
- `check-ios.py test ios/FocusMateUITests/FirstStationSearchUITests.swift` → Executed 7 tests, 0 failures.
- 단위 focused(T1~T3) → 63 tests, 0 failures.

## REFACTOR 내역
- 정리 없음.

## self-review 결과
- 완전성: AC-1·2·3·4·5·7(키보드 경로)·뒤로→메인 통과.
- 품질: 화면은 상태(StationSearchState)와 모델 함수만 호출. withAnimation·자동 스크롤 없음(설계 규칙).
- 규율: 테스트 해시 전부 RED 시점과 동일.
- 테스트: 해당 없음.

## 우려사항
없음
