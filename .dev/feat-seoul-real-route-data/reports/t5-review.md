# T5 태스크 리뷰 (sonnet, task-scoped)
SPEC PASS (3/3) · QUALITY PASS · Critical 0 · Important 0 · Minor 6 (유예)
1) AC-10 픽스처 입력 순서가 이미 정렬 순 — 역순 케이스로 변별력 보강 2) 색인 범위 밖·meters 불일치·format≠1 테스트 없음 3) 중복 정류장/노선 id 조용히 무시, 사전 구성 중복 4) visits/boundLabel 범위 밖 색인 크래시 — precondition 주석 5) 연속 같은 정류장이면 자기 자신 방면 가능(스크립트가 연속 합치기 하므로 실데이터 미발생) 6) 픽스처 모르는 id → -1
