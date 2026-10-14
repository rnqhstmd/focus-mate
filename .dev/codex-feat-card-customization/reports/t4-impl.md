# T4 구현 보고

## 구현 내용
- `ios/FocusMate/AppModel.swift` 끝의 `CardCustomizationSaving` extension에서 DECLARATIONS-ONLY marker와 stub만 교체했다. 기존 본문·private(set)·인터페이스는 그대로다.
- `beginCardCustomization`: ready·발급 상태·현재 카드가 모두 있을 때만 저장 외형을 가진 Controller(card: card, saver: self)를 생성한다. 진입은 읽기·쓰기·보충·재발급을 수행하지 않는다.
- `currentCardStyle`: 최신 snapshot의 저장 외형 또는 `.standard`를 반환한다. Controller 초안과 연결하지 않는다.
- `saveCardStyle`: 실패 launch는 `.writeBlocked(issue)`, loading·미발급·카드 부재·현재 ID 불일치는 `.notReady`로 거부한다. 최신 snapshot의 일치 카드만 `CardSnapshot.updating(style:)`로 바꾸고 기존 `save(candidate)`를 호출한다.
- ID·issuedAt·다른 카드·이용 단계·정류장·journey·최신 records/memo를 유지한다. 직접 persistence·추가 읽기·새 seam·정책·API 확대는 없다. 일반 저장 경로와 메모리 journeyPlan/preparedJourney를 변경하지 않았다.

## GREEN 증거
- 실행 명령:
```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateTests/CardCustomizationAppModelTests.swift ios/FocusMateTests/CardCustomizationControllerTests.swift ios/FocusMateTests/CardStyleTests.swift ios/FocusMateTests/CardPhotoProcessorTests.swift ios/FocusMateTests/CardStyleStorageTests.swift ios/FocusMateTests/CardPhotoIntegrityTests.swift ios/FocusMateTests/CardPhotoMemoryTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/CardSupplementTests.swift ios/FocusMateTests/RecordStorageTests.swift ios/FocusMateTests/StorageRecoveryTests.swift ios/FocusMateTests/StorageV2Tests.swift ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift > .dev/codex-feat-card-customization/t4-impl-focused.log 2>&1
```
- 실제 종료 코드: **0**.
- XCTest 실제 고유 test case: **247 pass, 0 fail = 245 unit + 2 UI**. 로그의 passed case 이름 중복 제거로 집계했다. T4 AppModel **16/16 pass**.
- 성공 마커: `** TEST SUCCEEDED **` (로그 마지막 비어 있지 않은 줄은 `Testing started`).
- 로그: `.dev/codex-feat-card-customization/t4-impl-focused.log`.
- xcresult: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_10-54-01-+0900.xcresult`.
- 실행 후 잠금 테스트 **18/18 git blob SHA1 동일** (`t4-test-hashes.json`). AppModel extension 앞 기존 본문 SHA256 `f3961d466c65ae06ebb90cb2ff255391f2160b90f43f5dfba96033ae142f0031` 동일.

## REFACTOR 내역
1. 구현이 최소이므로 추가 정리를 수행하지 않았다. 기존 updating/save 경로를 재사용했고 위 focused 실행으로 GREEN을 확인했다.

## self-review 결과
- 발견 없음. 최신 snapshot 기반 교체와 저장 성공 후에만 기존 persist가 메모리 snapshot을 갱신하는 경계를 확인했다.
- 실제 PNG 손상·invalid color·진입 후 원본 손상·writeData 1회 실패/재시도·v2 진입 무쓰기/v3 명시 저장 회귀가 위 focused 집합에서 통과했다. Controller baseline 처리 코드는 변경하지 않았다.
- 테스트와 다른 생산 파일을 수정하지 않았다. 기존 작업 트리 변경은 보존했다. agent·commit·push·전체 스위트·다른 기기 실행은 하지 않았다.

## 우려사항
- 실행 경고 있음: `CardIssuanceView.swift:14:52`의 main actor-isolated `failedAnnouncement` 기본 인자 참조 경고가 두 architecture에서 발생했다(Swift 6 언어 모드에서는 error라는 진단). 이 태스크 범위 밖 파일이며 수정하지 않았다.
- AppIntents.framework 미의존 metadata 추출 생략 경고 3회, debugger version lookup/no debugger version 진단, 시뮬레이터 WebCore/WebKit의 `UIAccessibilityLoaderWebShared` 중복 클래스 진단이 있다. 실행 실패나 XCTest 실패는 없었다. 경고 없는 실행으로 주장하지 않는다.
- 저장 journey는 현재 타입상 `active == nil`만 표현 가능하다. 비어 있지 않은 저장 여정 보존 증거는 없다. 메모리 preparedJourney 60분/2014/성동구민체육센터/12정류장 보존은 같은 실행 범위에서 검증했다.
- 지정 iOS 26.5 시뮬레이터 focused 검증만 수행했다. T5 Root UI 연결·시안 대조·실기기·VoiceOver 검증과 부모 review gate 판정은 이 보고 범위가 아니다.

## 부모 직접 GREEN
누적focused actual247/247PASS(unit245+UI2),0failure/exit0, t4-parent-green.log. test18hash다음gate에서검증. 생산AppModel1파일/noFix라scopedreview조건미발동(skip), 전체branchreview후속확인. T5 UI RED진입.
