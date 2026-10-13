# W08 변경 전 기준선
- npm ci: 성공, 취약점 0건.
- npm test: exit 0; Node 테스트 31건 실패 0, prototype edge QA 통과.
- python3 scripts/check-ios.py test: exit 65.
- FocusMateTests: 63건, 실패 0.
- FocusMateUITests-Runner: 연결 수립 전 signal term 종료. 전체 성공으로 판정하지 않음.
- appintentsmetadataprocessor 기존 경고 3건: AppIntents.framework 의존 없음으로 metadata extraction skipped.
- 로그: /tmp/w08-web-baseline.log, /tmp/w08-ios-baseline.log.
- 소스 변경 전 실행. UI runner 실패 원인 읽기 조사 중.

## W08 전용 Simulator 재실행
- UDID: 15645097-9CCF-4F45-A97B-8E43370F9488 (FocusMate W08).
- python3 scripts/check-ios.py test: TEST SUCCEEDED.
- 초기 오류: 같은 시뮬레이터에서 다른 xcodebuild 실행 및 기기 연결 제거가 겹침. 종료 주체 미확인.
- 로그: /tmp/w08-ios-isolated-baseline.log.
