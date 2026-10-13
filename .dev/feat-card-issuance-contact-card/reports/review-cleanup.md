# review 정리 (4b)

- R1: ios/FocusMate/IssuanceFeedback.swift makeEngine — engine.isAutoShutdownEnabled = true (재생 후 엔진 자동 종료). 동작 불변(재생 경로 동일).
- R2: testAC19 깨짐 명명 주석을 현재 단언 범위로 수정(+AC-19M 수동 안내), 안내 확인을 "
" 분리 후 두 문구 존재 및 시작 index < 완료 index 단언으로 교체. 실행: check-ios.py test CardIssuanceFlowTests 11건 0 failures, TEST SUCCEEDED.
