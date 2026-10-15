# T1 태스크 리뷰 (sonnet, task-scoped)
SPEC PASS (3/3) · QUALITY PASS · Critical 0 · Important 0 · Minor 5 (유예)
Minor (전부 [동작불변]):
1. xlsx.py:53 header를 grid[0]에서 가져옴 — r="1" 명시 탐색 권고
2. xlsx.py:55-56 중복 header 시 뒤 열이 덮어씀 — ValueError 권고
3. xlsx.py:120-121 r 속성·rels 부재 시 불명확한 예외
4. xlsx.py:31-32 Sheet 타입 힌트 list만
5. test_xlsx.py t="str"·리치 inlineStr·숫자 ARS is_text False 케이스 없음
