# T3 구현 보고

## Status
DONE

## 구현 내용
- `ios/FocusMate/CardCustomizationController.swift`: 선언 marker와 결과 폐기 stub을 교체했다. MainActor Observable 컨벤션과 기존 internal 인터페이스를 유지한다.
- 카드 원래 ID·baseline·draft만 보관하며 전체 snapshot은 보관하지 않는다. saver 경계를 통해 원래 ID로 저장한다.
- RGB invalid no-op, 유한 배치 clamp, 한 단계 레이어 이동, 삭제, 기본 복원, 선택, 최대 20회 undo를 구현했다. 같은 값·없는 ID·레이어 끝단·선택만 변경은 이력을 소비하지 않는다. 제거된 선택 ID는 해제한다.
- 사진은 선택 순서대로 처리하고 실패는 슬롯을 소비하지 않는다. 6장 도달 후 남은 loader는 호출하지 않는다. 성공 batch는 하나의 이력으로 반영하고 마지막 추가 사진을 선택한다. 빈 입력·전부 실패·부분 성공·초과 생략의 notice 계약을 유지한다.
- 가져오기 중 변경·undo·복원·재입력·저장을 잠그며 선택과 종료 확인은 허용한다. 모든 loader/processor await의 성공·catch와 defer에서 활성 세대 확인을 수행한다.
- discard는 baseline 복원·세대 증가·비활성화·이력/선택/notice/플래그 초기화를 수행한다. 늦은 결과를 무시하며 비활성 세션의 변경/import/save를 차단한다.
- 동기 저장 전에 isSaving을 설정하여 중첩 저장과 변경을 차단한다. 성공은 baseline 갱신·history clear·didSave true·notice nil, 실패는 draft/history/selection을 유지하고 명시적 오류 또는 writeFailed를 안내한다.
- AppModel/UI/테스트/해시 파일은 수정하지 않았다. 에이전트·커밋·push를 실행하지 않았다.

## GREEN 증거
- 실행 명령:
```sh
FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateTests/CardCustomizationControllerTests.swift ios/FocusMateTests/CardStyleTests.swift ios/FocusMateTests/CardPhotoProcessorTests.swift ios/FocusMateTests/CardStyleStorageTests.swift ios/FocusMateTests/CardPhotoIntegrityTests.swift ios/FocusMateTests/CardPhotoMemoryTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/CardSupplementTests.swift ios/FocusMateTests/RecordStorageTests.swift ios/FocusMateTests/StorageRecoveryTests.swift ios/FocusMateTests/StorageV2Tests.swift ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift > .dev/codex-feat-card-customization/t3-impl-focused.log 2>&1
```
- 실행 횟수: 1회. 지정 simulator만 사용했고 전체 스위트는 실행하지 않았다.
- 결과: **231 actual test cases PASS / 0 fail / 0 unexpected**, 명령 종료 코드 0. `Test Case … passed`를 세어 중복 없는 231건임을 확인했다.
- 구성: unit 229개(컨트롤러 47개 포함), 기존 T1 큰 글자 UI 회귀 2개.
- 로그 요약: `Executed 229 tests, with 0 failures (0 unexpected)` 및 `Executed 2 tests, with 0 failures (0 unexpected)`, `** TEST SUCCEEDED **`. 마지막 비어 있지 않은 줄은 `Testing started`이며 이를 PASS 근거로 사용하지 않았다.
- 로그: `.dev/codex-feat-card-customization/t3-impl-focused.log`
- xcresult: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_10-35-21-+0900.xcresult`
- 잠긴 테스트 git blob SHA1: `t3-test-hashes.json`의 17개 모두 구현 전·후 및 검증 종료 후 일치. 테스트·double·fixture·hash 수정 없음.

## REFACTOR 내역
1. 초기 구현에서 기존 CardCustomizationPolicy를 재사용하고 공통 이력 적용/선택 정리/세대 확인을 private helper로 묶었다 → ✅ focused 231개 통과.
2. GREEN 후 self-review에서 별도의 동작 불변 정리가 필요하지 않아 추가 source 변경과 테스트 재실행을 하지 않았다.

## self-review 결과
발견 없음. 최종 소스를 RED 실패·design.md 최종 계약 보강·PRD와 대조했다. 공개/internal 인터페이스 추가, 테스트 전용 setter, full snapshot 보관, 이미지 재검증/cache, 추가 정책을 도입하지 않았다. continueEditing은 상태 보존 계약이므로 의도적 no-op이다. requestExit는 기존 dismiss/confirmDiscard 두 case만 사용한다.

## 우려사항
없음(T3 구현 범위 내).

## 검증 한계 및 인계
- 별도 `finaldesign.md`는 존재하지 않아 `design.md`의 최종 계약 보강 부록을 적용했다.
- 컨트롤러는 processor 결과 경계를 신뢰한다. 의도된 1바이트 fake processed data를 실제 이미지로 재검증하지 않았다. 실제 이미지/저장 검증 책임은 기존 processor/store 경계에 있다.
- 이 실행의 memory 시험은 aggregate warm 실행이다. T2에서 별도로 검증된 fresh memory budget을 여기서 재검증하거나 cold 증거로 주장하지 않는다.
- 런타임 로그에 simulator 접근성 중복 클래스, debugger lookup 및 기존 ImageIO opaque/alpha 진단이 있었다. Swift compile warning/error는 없고 테스트 실패는 0이다.
- 최신 snapshot 보존을 담당할 AppModel saver 통합, UI import task 취소, isSaving 동안 종료 버튼 비활성화, 실제 PhotosPicker/실기기/VoiceOver 검증은 후속 태스크 범위다. T3가 전체 W10 완료를 뜻하지 않는다.

## 부모 직접 GREEN 확인
동일누적focused actual231/231PASS(unit229+UI2),0failure,exit0. t3-parent-green.log. 테스트17gitblobhash모두동일. 생산Controller1파일변경/태스크fixround없음으로scopedreview조건미발동(skip); 전체branchreview후속에서확인한다.
