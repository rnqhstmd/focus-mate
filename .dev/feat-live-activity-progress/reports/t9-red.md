# t9 RED
- 테스트: ios/FocusMateTests/AppInfoLiveActivityTests.swift (5 케이스, testV15_AC29_*)
- 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateTests/AppInfoLiveActivityTests.swift
- 결과: Executed 5 tests, with 5 failures (assertion: NSSupportsLiveActivities nil, PlugIns/FocusMateWidgets.appex 없음)
- 참조: AppInfoLocationTests.swift 만

## 재현 RED R1
- 테스트: ios/FocusMateTests/JourneyActivityDisplayTests.swift (기존 유지, 7 케이스 추가, testV15_위젯_*)
  - 카드_제목은_번호_공백_종류다 / 축약_접근성_라벨은_번호번_버스다
  - stale_운행의_표시_상태는_도착이다 / 정상_운행의_표시_상태는_운행_중이다
  - stale_일시정지의_표시_상태는_일시정지다 / 정상_일시정지의_표시_상태는_일시정지다 / 도착_상태의_표시_상태는_도착이다
- 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-... python3 scripts/check-ios.py test ios/FocusMateTests/JourneyActivityDisplayTests.swift
- 실패: error: type 'JourneyActivityDisplay' has no member 'busTitle' / 'compactAccessibilityLabel' / 'displayStatus' (NoSuchMember, 정상 RED)
- 참조: 테스트 파일, t9-red.md 만
