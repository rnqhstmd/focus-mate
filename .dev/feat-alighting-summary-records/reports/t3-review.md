# T3 태스크 리뷰 (reviewer, sonnet, scoped)
SPEC PASS (5/5) · QUALITY PASS · Critical 0 · Important 0 · Minor 4(유예)
1. ArrivalBriefingController begin/reset/token이 DepartureBriefingController와 약 40줄 중복(설계 위험 6 유예).
2. reset()이 showsSaveFailure를 초기화하지 않음 — 백그라운드 복귀 후 실패 표시 잔존 가능(확신 낮음).
3. confirm()이 ensureArrivalSaved 반환값을 버림 — 모델 confirmArrival이 저장본으로 판단(T5에서 검증).
4. 미도착 ensureArrivalSaved false 반환·reset 후 showsAll false 단언 미보강.
