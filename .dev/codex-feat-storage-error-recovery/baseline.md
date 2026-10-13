# W13 착수 기준선

- npm test: exit 0. 31 tests, 31 pass, 0 fail. prototype-edge-qa 전체 PASS.
- iOS 27.0 / iPhone 18 Pro: exit 65. App·UI runner가 테스트 연결 전에 signal kill. assertion 결과 없음.
- iOS 26.5 / iPhone 17 Pro (EC533489-C7FF-4620-B46D-E3D8461427DB): exit 0, TEST SUCCEEDED. Unit 63 + UI 11 = 74 tests, 0 failures.
- 재실행에서 변경한 것은 FOCUSMATE_SIMULATOR_ID뿐이다. 앱 코드 수정 없음.
- 후속 TDD/verify 명령에 위 시뮬레이터 ID를 명시한다. 27.0 환경 문제의 세부 원인은 미확정.
- 로그: baseline-node.log, baseline-ios.log, baseline-ios-26.5.log (Git ignore 대상).
