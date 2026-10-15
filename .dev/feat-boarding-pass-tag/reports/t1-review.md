# T1 태스크 리뷰 (reviewer, task-scoped, sonnet)
SPEC PASS (AC-11·19·20·24·BR-8 충족, 설계 범위 이탈 없음) · QUALITY PASS · Critical 0 / Important 0 / Minor 5 (전부 [동작불변], 유예)

## Minor (유예 → phase-review)
1. JourneySnapshot.swift:120 — 태그 이름 20 상한을 trim 전 값으로 셈(task와 비대칭). 설계·PreparationDraft 규칙과 대조 권장.
2. JourneySnapshotTests.swift — 도착 정류장 기대값을 `12 % count`로 계산(미러에 가까움). 역방향(direction -1) 도착 계산 테스트 없음.
3. JourneySnapshotTests.swift — AC-20 기대값을 withDestination 우회로 구성, 가독성 낮음.
4. JourneySnapshotStorageTests.swift — v2 active 키 누락, active 있는데 currentStation nil(inconsistentStage) 경로 미고정.
5. BoardingTestDoubles.swift — 픽스처 기본 destinationStopID "seongsu-dest"가 카탈로그 id 아님(오해 소지).
