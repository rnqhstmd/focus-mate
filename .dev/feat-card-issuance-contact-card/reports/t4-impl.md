# T4 IMPLEMENT (세션) — AC-5/17/18/19 로직

## 구현 내용
- ios/FocusMate/IssuanceHapticPattern.swift: 순수 값 패턴. `.issuance` = 연속 0.9초(sharpness 0.3) + 세기 곡선 (0,0.15)→(0.45,0.45)→(0.9,1.0) + 끝 탭(0.9, 1.0, 0.9). `duration = max(연속 끝, 마지막 탭)`. `makeCHHapticPattern()` = hapticContinuous + hapticTransient + hapticIntensityControl 곡선.
- ios/FocusMate/IssuanceFeedback.swift: `IssuanceHaptics`, `AccessibilityAnnouncing` 프로토콜. `CoreHapticsIssuancePlayer`(지원 판단·재생 모두 CoreHaptics, 엔진 지연 생성·보관, stopped/reset 시 nil, 오류 무시). `SystemAccessibilityAnnouncer`(UIAccessibility announcement).
- ios/FocusMate/CardIssuanceController.swift: `CardIssuing` 포트, `CardIssuanceTiming`(standardHold 900ms, slotAnimation 0.86, hapticDuration 0.9), 상태 머신(ready/issuing/failed/issued). issue: 가드 → issuing+안내 → issueCard(동기) → 실패 시 failed+실패 안내 / 성공 시 지원이면 play(.issuance) → hold>0이면 sleep → issued+완료 안내+focus. proceed는 issued일 때만 finish. 안내 문구 3종 static 상수.
- ios/FocusMate/AppModel.swift: `extension AppModel: CardIssuing {}`.

## GREEN 증거
`python3 scripts/check-ios.py test ios/FocusMateTests/{IssuanceHapticPatternTests,CardIssuanceControllerTests,CardIssuanceModelTests,CardSupplementTests,CardStorageTests,PassIdentityTests,PassFaceAssetTests}.swift` → Executed 50 tests, with 0 failures. 첫 구현에서 통과. 신규 경고 없음(AppIntents 기존 경고만).

## REFACTOR 내역
정리 없음.

## self-review 결과
- 완전성: AC-5 연타 직렬화, AC-17 a/b/실패·순서, AC-18 a(기본 standard)/b·holdDuration, AC-19 안내·포커스·재시도, proceed 가드, 통합(저장 후 재생) 모두 통과.
- 품질: 연출 시간과 hold 분리(slotAnimation 상수) — 뷰는 T5에서 사용.
- 규율: 테스트 파일 해시 동일. 신규 멤버: 안내 문구 static 3종은 테스트 미참조이나 설계 §9 CardIssuanceCopy 안내 문구 상수(뷰·UI 테스트 공유) 위치 판단 → 아래 판정. slotAnimation은 설계 명시(설계 예약). CoreHapticsIssuancePlayer·SystemAccessibilityAnnouncer는 설계 명시 OS 어댑터(빌드·리뷰·수동 검증 대상).

## 우려사항
없음

## 과잉 구현 정리
- 유지(설계 예약): CardIssuanceTiming.slotAnimation, CoreHapticsIssuancePlayer, SystemAccessibilityAnnouncer
- 유지(설계 §9 안내 문구 상수 — 위치를 Controller로 둠): issuingAnnouncement/issuedAnnouncement/failedAnnouncement (테스트는 리터럴로 같은 값 검증)
