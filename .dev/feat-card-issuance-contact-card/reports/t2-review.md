# T2 태스크 리뷰 (reviewer, sonnet, task-scoped)

SPEC PASS (AC-15, BR-1, BR-4, 에셋) · QUALITY PASS · Critical 0 · Important 0 · Minor 4 (전부 [동작불변], 유예)

## Minor (유예)
1. PassIdentity.swift init(card:) — 접두·길이 미검사("FM-1234" → "FM · 1234 1234"). 번호 미노출 + T1 validate가 막아 영향 없음. 화면 노출 전 전제 주석/방어 권고.
2. PassFace.swift 테두리 lineWidth 1이 scale 비적용 (확신 낮음).
3. PassFace #Preview 없음 — [검증 필요] 시뮬레이터에서 폭 238/320 하단 이름 잘림·점묘 offset/clip 시각 확인 (T5 UI 단계 또는 수동).
4. PassFaceAssetTests의 dotsAssetName 자기 비교, PassIdentityTests displayName 상수 단언 — change detector 성격(가치 낮음).
