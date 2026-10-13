# T3 IMPLEMENT (세션) — 모델 저장·네비게이션

## 구현 내용
- ios/FocusMate/AppModel.swift: `Destination.time`(title "시간 선택"), 저장 프로퍼티 `var journeyPlan = JourneyPlanDraft()`.
- ios/FocusMate/AppModel+JourneyStart.swift(신규): journeyOrigin(currentStation id로 찾기), journeyCandidates, journeyProceedState(origin 없으면 .originUnavailable), preparedJourney(.ready 값 — 유일 출처), confirmInitialStation(initialStationEntry일 때만, snapshot.updatingStage(cardIssued 유지, initial=current=선택) → save, 성공 시 path=[.time]), proceedToPreparation(preparedJourney 있을 때만, path.last가 .preparation이면 추가 안 함), Destination.mainMenu / mainMenuTarget(.preparation → .time).

## GREEN 증거
- focused(T1~T3 5파일) → Executed 63 tests, 0 failures.

## REFACTOR 내역
- proceedToPreparation의 가드를 journeyProceedState 패턴 매칭 대신 preparedJourney 재사용으로 정리.

## self-review 결과
- 완전성: AC-6·7·8·9·21·22·25·26(모델)·출발 위치 실패·메뉴 매핑 통과.
- 품질: AppModel 본체 변경 3줄, 나머지는 새 파일(W01 충돌 최소화). save의 path 초기화 뒤 path=[.time] 순서에 의존(설계 판단 4).
- 규율: 테스트 해시 동일. 설계 인터페이스 외 공개 멤버 없음.
- 테스트: 해당 없음.

## 우려사항
- `Destination.allCases`에 `.time`이 생겨 RootView 메인 메뉴(현재 allCases 순회)에 "시간 선택" 버튼이 임시로 보인다 — 설계상 T6에서 `Destination.mainMenu`로 교체 예정. 그 전까지 Phase1FlowTests 버튼 수 UI 테스트는 실패할 수 있다(관찰, 이번 태스크 범위 밖).
