# T5 IMPLEMENT (세션) — 저장 실패 UI

## 구현 내용
- ios/FocusMate/UITestBootstrap.swift: `applySaveScenario` guard를 "쓰기 실패 + 메인일 때만 시드 실패 저장 1회, 그 외 진입 상태는 그냥 반환"으로 변경. 쓰기 실패 저장소(modelStore)는 모든 진입 상태에 그대로 주입.
- ios/FocusMate/InitialStationSearchView.swift: `model.saveFailure != nil`이면 확인 버튼 위에 `search.saveFailure` "출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요."
- ios/FocusMate/RootView.swift: 공용 `storage.saveFailure`를 최초 정류장 설정 화면에서는 숨김(조건 1줄).

## GREEN 증거
- `check-ios.py test StationSaveFailureUITests FirstStationSearchUITests` → Executed 10 tests, 0 failures.

## REFACTOR 내역
- 정리 없음.

## self-review 결과
- 완전성: AC-8(검색 화면 유지·전용 문구·공용 문구 없음·정류장 null·바이트 불변·재시도 가능)과 ready+fail 회귀 가드 통과.
- 품질: 메모리 상태가 바뀌지 않은 실패에서 공용 문구("변경 내용 복원 보장 불가")가 나오지 않게 분리.
- 규율: 테스트 해시 동일.

## 우려사항
없음
