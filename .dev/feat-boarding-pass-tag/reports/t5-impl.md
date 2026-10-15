# T5 IMPLEMENT — 출발 안내 컨트롤러

## 구현 내용
- 신규 `ios/FocusMate/DepartureBriefingController.swift`: `DepartureConfirming`, `DepartureBriefingController`(세 문장·1700ms, begin(reduceMotion:) — 동작 줄이기면 즉시 전부+시작, 아니면 0→1→2 단계마다 token 확인 후 시작·포커스; reset — token 무효화·처음 상태; confirm — showsStart일 때만, 실패 시 showsSaveFailure·버튼 유지).

## GREEN 증거
focused 7파일 121 pass / 0 fail (DepartureBriefingControllerTests 10 포함).

## REFACTOR 내역
정리 없음.

## self-review 결과
진도·일시정지·남은 시간 상태가 없어 BR-5/AC-19 구조적 충족. confirm 중복 호출은 isConfirmed 가드.

## 우려사항
없음. (태스크 리뷰 skipped — 프로덕션 1파일)
