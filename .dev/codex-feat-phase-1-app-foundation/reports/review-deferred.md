# 유예 항목

- [Minor] scripts/check-ios.py:37 — focused 입력의 실제 파일/클래스 존재와 0건 실행 차단이 없다. MissingTests.swift 실험에서 실제0 tests/exit0 확인. 후속 focused 작업 전에 검사 실행기 보강 대상으로 유지한다.
- [Minor] ios/FocusMateUITests/Phase1FlowTests.swift:60 — snapshot 비교 일부가 JSON 문자열 표현에 결합된다. 의미 값 비교로 보강할 수 있다. 원본 바이트 보존 비교는 유지해야 한다.
- [MEDIUM] ios/FocusMate/LocalSnapshotStore.swift:15 — 파일·필드 크기 상한의 정책과 한도 초과 원본 보호 AC를 후속 단계에서 확정해야 한다.
- [MEDIUM] ios/FocusMate/AppModel.swift:27 — 오류 감지·원본 보호만 제공하며 복구 전에는 진행 불가. Phase5에서 명시 복구를 정의하고 Phase6에서 출시 조건으로 검증한다.
- [MEDIUM] ios/FocusMate/FocusMateApp.swift:14 — 가상 정류장 데이터 분류·기기 백업·파일 보호 정책은 출시 전 확정한다. 실제 GPS 연동 또는 비민감 판정을 가정하지 않는다.

동작 변경을 동반하는 MEDIUM은 새 AC와 RED 없이 현재 범위에 추가하지 않았다. 유예는 위험이 없다는 판정이나 출시 보안 완료가 아니다.
