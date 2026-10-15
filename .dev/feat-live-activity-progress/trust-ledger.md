## Trust Ledger

### 위험 수용
- [기준선 전체 테스트 생략] 사용자 지시(작업 중 focused만, 전체 테스트는 마지막 1회). 기준선은 build 경고 5건만 측정 (implement/Step 0.5)
- [태스크 분해 승인 생략] 설계 승인 시 12단계 구현 순서 승인 + 사용자 지시(승인 후 게이트마다 묻지 않음) (implement/Step 1.2)
- [리뷰 기계 게이트 전체 테스트 생략] 사용자 지시(전체 테스트는 마지막 1회). Mechanical Gate는 build + W15 관련 focused(단위 121 + UI 1, 0 failures)로 수행, 전체 회귀는 complete의 verify에서 1회 (review/Step 0)

## 통합 감사 (review)
security-auditor: CRITICAL 0 · HIGH 0 · MEDIUM 6
- [GAP/MEDIUM] update/end 비구조 Task 순서 비보장 — 연타 시 카드 상태 역전 가능 → 감수(PRD 개정 1 M-15, W14 점검)
- [GAP/MEDIUM] 앱 시작 정리와 화면 진입 정리가 비동기 end 때문에 같은 중복 카드를 다르게 고를 수 있음 → 유예(동작 변경 동반, 후속)
- [GAP/MEDIUM] 저장 읽기 실패 실행에서 복구 후 정리 재실행 없음 → 감수(PRD M-16)
- [ASSUMPTION/MEDIUM] 잠금 화면 노출 데이터(버스·도착지) — 가상 노선 이름이라 개인정보 아님 → PRD 가정으로 확정
- [ASSUMPTION/MEDIUM] 확장 서명·임베드 실행 증거 — build ✓, AppInfoLiveActivityTests 5/5(PlugIns 내장 확인), HarnessUITests 설치 1/1로 확인. 실기기 서명은 W14
- [ASSUMPTION/MEDIUM] 단위 테스트 기본 게이트웨이 — FocusMateTests에 JourneyServices/.live() 사용처 0건 확인. UI 테스트는 항상 기록기

reviewer: SPEC PASS (33/33) · Critical 0 · Important 2([동작불변], 테스트 헬퍼 중복·RED 단계 주석) → 정리 · Minor 10

## 재리뷰 R2
I1·I2·M2·M3·M5 ADDRESSED · SPEC PASS · QUALITY PASS · Minor 1(MARK 구조, 비차단)

### 위험 수용 (complete)
- [verify 전체 테스트 생략] 사용자 지시("전체테스트 돌리지 말고 저거만 테스트 돌리고 PR 생성 후 머지"). 진행 중이던 전체 테스트를 중단했고(중단 시점까지 실행된 UI 테스트는 0 failures), main(W07 #19) 병합 후 build + W15 관련 focused 테스트로만 검증 (complete/Step -1)
