## Trust Ledger

### 통합 감사 (review)
- [GAP/HIGH] AC-5·FR-5.2 카드 내부 문구·칩/비접촉 식별자 미충족 출고 → PRD 개정 기록으로 W10 합류 후 이연 공식화(사용자 결정: PassFace 미수정).
- [RISK/HIGH] FR-5.11 "W10이 cardStudio만 바꾸면 합류" 불성립(W10은 fullScreenCover 세션) → PRD 정정. 사용자 결정: W11 먼저 머지, W10이 나중에 합류 절차 수행(design.md "W10 합류 절차"). 합류 누락 시 마이페이지 카드가 기본 외형으로 남고 꾸미기 행이 자리표시로 감 → plan.md 완료 인계·PR 본문에 체크리스트로 남김.
- [RISK/MEDIUM] UITestBootstrap rawSeeds 끝 항목 추가 — W10도 같은 파일 수정 → 텍스트 충돌 가능(합류 시 해결). v2 시드의 W10 v3 변환 후 decode는 합류 때 ProfileSeedTests로 재확인.
- [ASSUMPTION/MEDIUM] 통계 값 UI 테스트가 children:.ignore 하위 노드 노출에 의존 → 스파이크로 확인(iOS 27 시뮬레이터, state.md execution-log). OS 변경 시 재확인.
- [GAP/MEDIUM] 집계 실패 UI 경로(AC-29~31) 미실행 — 실제 앱에서 도달 불가(decode·save 검증). 단위 연쇄로만 검증(사용자 결정).
- [GAP/MEDIUM] ProfileStats.from(nil) → unavailable("-") — 메인 ready에서만 진입하므로 현재 도달 불가. 문서화.
- [POLICY/MEDIUM] Dynamic Type 상한: 마이페이지 툴바 제목 accessibility1(바 높이 고정), 시간 화면 접근성 크기 머리말 축소(T0). 본문·통계·메뉴는 상한 없음, 전체 스크롤로 도달 보장.
- [GAP/MEDIUM] T0(TimeSelectionView W02 회귀 수정)이 W11 PR에 포함 — 사용자 결정(W11에서 함께 고침). LargeText 2/2, TimeSelection 9/9, Mechanical Gate 전체 통과.
- [GAP/MEDIUM] AC-21 동작 줄이기 — 시뮬레이터 자동화 불가, 애니메이션 API 0건 정적 확인. → 위험 수용(아래).
- [ASSUMPTION/LOW] 카드 최대 폭 제한 없음(iPhone 전용 전제), 분 합계 오버플로 미검사(건당 최대 360분이라 실용상 도달 불가).

### 통합 리뷰 요약 (reviewer)
- SPEC PASS 33/33. Quality: Critical 0, Important 2([동작불변] 통계 아래 간격, 테스트 이름 AC 번호) → 정리 후 재리뷰. Minor 15 유예(review-deferred.md).

### 위험 수용
- [실기기 미검증] VoiceOver 실제 읽기 순서·통계 한 요소 낭독(AC-18 묶음 여부, QE-1), 동작 줄이기(AC-21)는 시뮬레이터 자동 검증 불가 — Phase 6(W14) 실기기에서 일괄 확인. (review, 설계 결정 2026-10-14)
- [기존 실패 기준선] 기준선에서 LargeTextUITests 시간 화면 1건 실패(W02 기존 회귀) — 사용자 결정으로 T0에서 수정, 이후 통과. (implement/Step 0.5)
