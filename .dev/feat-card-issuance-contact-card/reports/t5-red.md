# t5-red 보고

- 케이스 18건 (CardIssuanceFlowTests 11, CardStorageFlowTests 7). 18건 모두 실패 (컴파일 통과, 요소 없음/진단 없음 계열). 즉시 통과 0건.
- 실패 확인 명령: cd /Users/bonseung/projects/focus-mate/next-step-w01 && python3 scripts/check-ios.py test ios/FocusMateUITests/CardIssuanceFlowTests.swift ios/FocusMateUITests/CardStorageFlowTests.swift
- 결과: Executed 18 tests, with 18 failures / TEST FAILED (exit 65)

## 케이스별 실패 유형
- AC1: card.title 요소 없음 (Failed to get matching snapshot)
- AC2/3/4/6/16: 발급 버튼 후 card.continueButton 대기 실패 (요소 없음)
- AC5/AC19: 발급 중 상태 진입 실패 (hold manual 미지원/라벨 불일치)
- AC7: card.issueError 없음
- AC20 x2: test.dynamicTypeSize 진단 없음
- AC10: screen.main 없음 (카드 없는 시드 미지원)
- AC14 a~f: screen.storageError 없음 (시드 이름 거부)

## 우려사항
- 앱의 AC-14 시드 JSON은 테스트 쪽 리터럴과 바이트가 정확히 같아야 한다: {"state":{"cardIssued":..,"cards":{"items":[..]},"currentStation":..,"initialStation":..,"journey":{"active":null},"records":{"items":[..]}},"version":2} (sortedKeys, 공백 없음).
- 동명 AC 실패는 현재 앱이 시드·진단을 모르는 데서 오므로, 구현 후 실제 실패로 바뀌는 부분은 GREEN에서 재확인.
- AC-19 완료 직후 포커스, VoiceOver는 수동 확인.
- face 하위 0개는 face.descendants(matching:.any).count==0으로 검사.

## 테스트 코드 전문
ios/FocusMateUITests/UITestLaunchSupport.swift, CardIssuanceFlowTests.swift, CardStorageFlowTests.swift 파일을 참조 (본문 동일).

## 참조한 파일
prd.md, design.md, ios/FocusMateUITests/Phase1FlowTests.swift, HarnessUITests.swift (읽기 전용)

## 재작성 R2 (테스트 결함 의심 반영)

- 변경: ios/FocusMateUITests/CardIssuanceFlowTests.swift `testAC19_...` 197행
  - 제거: `XCTAssertEqual(face.descendants(matching: .any).count, 0)`
  - 추가(주석): `// iOS 27 XCUITest는 accessibilityHidden 하위 요소도 자동화 트리에 노출해 descendants 수로 VoiceOver 노출을 판정할 수 없다 — 장식 비노출은 수동 VoiceOver 확인(trust-ledger)`
- 근거: 구현은 카드 그림을 `.accessibilityHidden(true)`로 숨기고 바깥 요소(라벨 "집중동행카드")만 노출하지만, iOS 27 XCUITest 트리에는 숨긴 하위 4개(StaticText 'Focus Mate', Image 'PassDots', Image 'wave.3.right', StaticText '집중동행카드')가 그대로 나온다. descendants 수는 VoiceOver 노출의 유효한 대리 지표가 아니다. 대체 단언은 `face.label == "집중동행카드"`가 이미 있어 중복 추가하지 않음.
- 실행: `python3 scripts/check-ios.py test ios/FocusMateUITests/CardIssuanceFlowTests.swift` -> 11 tests, 0 failures, TEST SUCCEEDED (207s)
- 미자동검증: AC-19 "장식 요소 비노출"은 수동 VoiceOver 확인(trust-ledger)으로 이관.
