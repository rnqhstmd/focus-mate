# T6 태스크 리뷰 (sonnet, scoped)
SPEC PASS (12/12) · QUALITY PASS · C0 I0 · Minor 6 (유예)
1. start 실패 시에도 lastSent 대입(무해, 의미 혼동)
2. arrived end 후 lastSent 미초기화(종단 상태라 무해)
3. 시스템/사용자 종료 Activity를 알 방법 없음(FR-7·M-13 의도)
4. (이전 증분) leave에서 halt 알림 후 save 실패 시 표시와 저장 불일치 — 방어 경로
5. AC-19·21·25는 컨트롤러 구조로 통과(회귀 방지 명시됨)
6. AC-22 다중 rig·매직 넘버 9, makeRig 중복(T5 Ruling과 동일)
