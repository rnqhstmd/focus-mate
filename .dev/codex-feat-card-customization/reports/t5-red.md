# T5 UI RED 승격 보고서

Status: **AUTHORED / STATIC PARSE PASS / ACTUAL RED PENDING**

T4의 부모 검증 247/247 PASS와 기존 18개 git blob hash 불변 확인 뒤, 준비된 12개 T5 초안을 `ios/FocusMateUITests/CardCustomizationFlowTests.swift`로 승격했다. draft의 선두 DRAFT 전용 주석 두 줄만 제거했으며 나머지 본문과 기대식은 바이트 단위로 동일하다. production source는 읽거나 수정하지 않았다.

## 정적 확인

- `xcrun swiftc -frontend -parse ios/FocusMateUITests/CardCustomizationFlowTests.swift`: exit 0.
- test method 12개를 확인했다.
- 저장 성공 helper 사용은 test05/test11/test12의 3곳이다. 편집기 부재, 메인 존재, `cardCustomization.savedNotice`의 정확한 문구, 최상위 saved 일치, draft/selected nil, didSave/canUndo false를 확인한 뒤 재진입한다.
- x/y control container 내부의 확정 child ID와 한국어 label을 사용한다. test04가 한 번의 조작으로 0.50→0.55/0.45가 되는 5% 계약을 검증한다.
- `cardCustomization.body`의 x=2% gutter에서 위·아래 방향을 선택하는 bounded scroll helper를 사용한다.
- `DRAFT ONLY`, `FM_T5_`, `NEEDS_CONTEXT`, 직접 `swipeUp()/swipeDown()`, 화면 내 `didSave == true` 대기 토큰은 실제 타깃에 없다.
- build, UI 실행, fixture staging, 실제 RED 판정은 수행하지 않았다.

## 12개 케이스와 AC 관찰

| # | 제품 관찰 | AC |
|---|---|---|
| 01 | 저장 정체성, 무변경 종료, snapshot/bytes 불변 | 01, 19, 31 |
| 02 | 색 변경 undo, 기본 복원과 복원 undo, 저장 전 파일 불변 | 03, 15, 17 |
| 03 | 종료 확인의 계속/버리기, 초안·undo/파일 보존 | 20, 21 |
| 04 | 실제 두 사진 순서·metadata, 선택 대상 X/Y 5%·폭·앞뒤·삭제·undo | 04, 11, 13, 14, 15, 31 |
| 05 | 카드 밖 사진 hit-test, 저장 auto-dismiss/정확 안내, 재진입 후 목록 복귀 | 11, 18, 31 |
| 06 | import gate 중 편집 잠금, close/continue와 명시적 release | 23 |
| 07 | discard가 이전 gate를 무효화하고 새 batch만 적용 | 22 |
| 08 | 선행 실패가 자리를 차지하지 않고 후행 성공만 추가 | 09 |
| 09 | 정상 7장 중 앞 6장, 한도 안내, batch 단일 undo | 06, 07, 15 |
| 10 | 경로 이탈/없는 파일 거부와 초안·undo·bytes 보존 | 10 |
| 11 | 실제 write fail-once 보존, retry auto-dismiss, 동일 UUID/다른 snapshot 섹션/사진 metadata 보존 | 24, 26, 30 |
| 12 | XXXL에서 기본·사진 도구가 고정 저장 footer 위로 도달하고 저장 뒤 재진입 | 31 |

test12는 XXXL 자동화만 담당한다. 실제 Reduce Motion ON은 부모가 owned iOS 27 simulator Settings에서 별도로 설정하고 read-only `test.reduceMotion == true`를 확인하는 보충 실행이다. 기본 OFF 실행을 Reduce Motion 증거로 사용하지 않는다. 실제 PhotosPicker, VoiceOver, 캡처 기반 visual 판정도 별도 보충 증거로 남는다.

## 부모 실행 예정 명령

fixture 생성·동일 앱 컨테이너 staging을 마친 뒤 다음 focused 명령을 정확히 한 번 실행해 실제 RED를 분류한다.

```bash
python3 scripts/check-ios.py test ios/FocusMateUITests/CardCustomizationFlowTests.swift
```

예상 상태는 신규 T5 UI 계약 미구현에 따른 assertion RED이다. fixture/staging 또는 test author compile 결함이면 제품 RED로 분류하지 않고 해당 원인을 먼저 분리한다.

## 파일 범위

읽기: T5 draft, 최신 design, T5 draft report, 기존 `UITestLaunchSupport.swift`, 승격 후 실제 target 정적 확인. 쓰기: `ios/FocusMateUITests/CardCustomizationFlowTests.swift`, 본 보고서. production source, 다른 test, T1~T4 산출물은 수정하지 않았다.

## 부모 직접 actual RED
12/12 actual XCTest failed, 각각 open.cardCustomization 부재 assertion(line322). Compile success, exit65, TEST FAILED. 다른 compiler/helper/context failure 없음. t5-parent-red.log. Fixture staging 완료, test19 gitblob hashes 잠금. T5 GREEN진입.
