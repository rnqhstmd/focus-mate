# T4 태스크 리뷰 (sonnet, scoped)
SPEC PASS (8/8) · QUALITY PASS · C0 I0 · Minor 5 (유예)
1. ActivityKitLiveActivityGateway에 @MainActor 명시 권고(현재 추론)
2. update/end Task 완료 순서 비보장 (설계 R-3 감수 항목과 동일)
3. 사용자가 닫은 Activity에 update가 조용히 무시됨 — 의도 주석 권고 (M-13)
4. start nil 시 재시도 — T6 startFailed 범위
5. 기록기를 앱 DEBUG에 둔 이유(UI 테스트 공용) — T11에서 사용
