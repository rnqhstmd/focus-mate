## Rulings

- 전체 리뷰의 동작 불변 검사 보강 — Important1건의 Unit fixture에 directory 카운터와 saveFailure nil 검사를 추가하고 기대값·제품 동작을 유지한다. (틀리면: 강화 검사 또는 전체 회귀 실패를 근거로 수정하고 verify를 새로 실행한다.)
- Minor2건·MEDIUM3건 유예, 문서2건 보정 — runner 0건 선택·UI JSON 표현 비교와 한도·복구·보호 정책은 유예하고, 검사 수와 파일 보존 증거 범위는 보정한다. (틀리면: 명시 AC와 RED로 후속 Phase에서 해결한다.)
- 브랜치와 커밋 타입 해석 — codex/ 접두사를 유지하며 feat 작업 의미를 커밋·PR에 적용한다. 모두 진행 승인 안의 현재 산출물만 올린다. (틀리면: 승인 범위 밖 파일은 분리한다.)

## Deferred

- [Minor] scripts/check-ios.py:37 — 비존재 focused 선택이 실제0 tests/exit0으로 끝날 수 있다. 현 전체 검증은26건 실행을 별도 확인한다.
- [Minor] ios/FocusMateUITests/Phase1FlowTests.swift:60 — 일부 snapshot 비교가 JSON 문자열 표현에 결합돼 있다.
- [MEDIUM] ios/FocusMate/LocalSnapshotStore.swift:15 — 파일·필드 크기 한도 정책과 원본 보호 AC가 필요하다.
- [MEDIUM] ios/FocusMate/AppModel.swift:27 — Phase1은 오류 감지까지만 지원한다. Phase5 복구 정의/Phase6 출시 검증이 필요하다.
- [MEDIUM] ios/FocusMate/FocusMateApp.swift:14 — 가상 정류장 데이터 분류·백업·파일 보호 정책을 출시 전 확정한다.
