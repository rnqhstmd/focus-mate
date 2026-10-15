## Trust Ledger

### 통합 감사 (review)
- security_verdict: CRITICAL 0 / HIGH 0 / MEDIUM 6 — 배포 차단 사항 없음
- [GAP/MEDIUM] 손상·카탈로그 불일치 여정 무음 폐기, v3 원본 사본 없이 v4로 덮어씀 — 사용자 결정(지금처럼 버림)으로 수용. 카탈로그 id 변경 금지 규칙은 문서 유지 → W07/W14 이월
- [GAP/MEDIUM] 백그라운드 진입 후 시스템이 프로세스를 종료하면 그 뒤 흐른 시간이 진도에 반영되지 않음(종료=끊김 규칙) — "마지막 저장 지점부터 멈췄어요" 안내 여부는 W07 결정 → 이월
- [GAP/MEDIUM] 출발 뒤 메인 '여행 시작하기'가 진도 있는 여정을 확인 없이 정리 — 사용자 결정(W07 전 임시), 출시는 W05+W07 묶음(plan.md) → W07 이월
- [GAP/MEDIUM] saveJourneyProgress에 경과 단조성·도착 불변 가드 없음 — 현재 경로 도달 어려움, W07 재진입 도입 시 추가 → W07 이월
- [ASSUMPTION/MEDIUM] JourneyTimerController.deinit의 MainActor.assumeIsolated 메인 해제 가정 — 현 소유 구조상 안전 → 관찰
- [ASSUMPTION/MEDIUM] DEBUG 훅 릴리스 제외는 정적 확인만 — Release 빌드·심볼 확인은 W14 출시 게이트
- 이월 판정: 재승차 덮어쓰기·minutes/elapsed 상한·카탈로그 id → 해소. 손상 여정 사본·안내 → 미해소(사용자 결정)

### 위험 수용
- [기준선 전체 테스트 생략] 사용자가 전체 테스트 반복 실행을 원하지 않음. 기준선은 빌드(성공, 경고 5)만 측정하고 기준 GREEN은 W04 최종 검증(761 통과/0 실패, main c7c06b4)으로 갈음 (implement/Step 0.5)
- [전체 테스트 미실행] 사용자 지시("전체 돌리지말고 지금 구현한거 다 통과됐으면 다음 단계 진입"). 검증은 이번 작업이 만들거나 고친 테스트 파일 집합(focused)으로 갈음 (implement~complete)
- [T6 태스크 리뷰 생략] 사용자 속도 요청으로 phase-review 전체 리뷰에 통합 (implement/Step 2-V)
- [verify 게이트 focused 대체] gx-verify(전체 스위트 실행)를 호출하지 않고 focused 집합 결과 + 빌드로 verify 통과 처리. 근거 reports/final-verification.md (complete/Step -1)
