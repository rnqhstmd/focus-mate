## Trust Ledger

### 통합 감사 (review 1회차)
- [ASSUMPTION/MEDIUM] 같은 v2 안에서 영역의 모르는 키가 읽을 때 버려지고 다음 저장에서 사라짐 (CardSection/JourneySection/RecordSection init(from:), SnapshotCodec)
  - 근거: 영역 디코딩이 골격 키만 읽음. W01 이후 빌드가 영역 필드를 추가한 파일을 이전 빌드가 저장하면 필드 소실.
  - 권고/처리: 사용자 결정 — 설계서 "후속 작업 인계"에 영역 확장 시 보존·쓰기 차단 정책 필수로 명시 (W00 범위 유지).
- [POLICY/MEDIUM] 숫자가 아닌 version을 corrupt로 분류 — PRD FR-5 문구("미지원")와 불일치
  - 처리: PRD FR-5 문구를 실제 분류(정수 범위 밖=미지원, 비정수=손상)로 정정. W13 인계 "corrupt 정리 전 사용자 확인" 유지.
- [GAP/MEDIUM] v1 모르는 키가 변환 시 버려지고 백업 없음 (BR-4 전제)
  - 처리: BR-4에 전제 명시 — 네이티브 앱 미출시, Phase 1 운영 코드에 저장 호출부 없음(DEBUG 시험 경로만).
- [ASSUMPTION/MEDIUM] 파일 크기 상한 없음, save의 확인→쓰기 사이 경쟁 조건
  - 처리: 유예 — docs/PHASE-1-FOUNDATION.md의 출시 전 확정 항목과 같은 범주(W13·Phase 6).

### 통합 리뷰 Part 2 요약 (review 1회차)
- Critical 0, Important 1 [동작불변] 테스트 헬퍼 중복(assertStorageIssue 3곳·withTemporaryFile 2곳·stage 4곳) → 정리 모드로 StorageTestSupport.swift에 통합, 단위 62/62 GREEN 재확인.
- Minor 10 → 유예 (reports/review-deferred.md)

### 위험 수용
- [MEDIUM 유예] 파일 크기 상한·경쟁 조건 — Phase 1 유예 범주 유지 (review/4c)

### 통합 감사 (review 2회차)
- 1회차 처리 적정성: 영역 모르는 키 인계 [적정], 크기·경쟁 조건 유예 [적정], v1 모르는 키 BR-4 전제 [적정], version 비정수 [부분 적정 → 설계서 FR-5 정정으로 해소]
- [POLICY/MEDIUM] 설계서 FR-5가 정정 PRD와 모순 → design.md:23 문구를 PRD와 동일하게 정정 (문서만, 동작 불변)

### 통합 리뷰 Part 2 요약 (review 2회차)
- 1회차 Important(헬퍼 중복) ADDRESSED. Critical 0, Important 0, Minor 3 유예. SPEC PASS 5/5.
