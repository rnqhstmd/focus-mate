# Trust Ledger

### 핵심 모드 긴급 감사

초기 감사: CRITICAL 0, HIGH 2. 사용자 모두 진행 승인 — 자동 수정 중.

- GAP/HIGH: 필수 수동 검토 항목 집합이 고정되지 않아 productScreenCoverage를 지우고 browser만 passed로 바꾸면 완료 선언 가능. check-design-baseline.cjs:91-100 / design-baseline.json:388-396. 삭제 항목을 완료로 판단하지 않도록 정책·실패 테스트 보강 필요.
- RISK/HIGH: CLI에서 알 수 없는 인자/추가 인자를 기본 루트로 무시하고 --root 값 부재는 JSON 보고 전 예외 발생. check-design-baseline.cjs:4. 지정 루트에 대한 검사라는 오해를 막도록 엄격한 인자 파싱과 오류 보고 필요.

입력 HTML/JS 실행 경로 없음. .pen은 존재만 검사. 이 결과는 앱 제품 UI/실기기 검증이 아닌 로컬 검사 도구 감사다.

### 검증 경계

- 자동 자료 연결·복제 검사 및 VM 상태 회귀와 실제 브라우저/실기기 검증을 구분.
- 최신 승차 렌더/터치와 tags 중간 화면 캡처 미완료. 제품 Phase 0 완료로 선언하지 않음.
- 위험 수용 답변은 아직 없으며 통과/면제로 기록하지 않음.

### 승인된 수정안 (RED R3 진행 중)

사용자가 자동 수정을 선택하면 두 finding을 G-W-T로 추가하고 RED 격리 역할에 맡긴다. 원본 HTML의 requiredBaselineReviews metadata를 독립 기준으로 삼아 browser/productScreenCoverage 누락을 검사한다. fixture의 기존 passed 기대값은 필수 productScreenCoverage passed 선언을 추가해 보존하고 누락 사례를 추가한다. CLI는 무인자 또는 --root <경로>만 허용하며 잘못된 인자·경로 누락·추가 인자는 JSON 오류+exit1로 보고한다. 기존 제품/상태 매핑과20+1 leaf 회귀를 유지한다.

보안 수정 후 scoped reviewer와 core security-auditor 재검토, fresh gx-verify, AC 자가 검증, commit/PR 순으로 이어간다. 수동 확인 상태는 pending으로 유지하며 제품 Phase0와 GX 산출물 파이프라인 완료를 구분한다.

### 핵심 모드 긴급 감사 — R3 재검토

현재 CRITICAL0 / HIGH0. 이전 HIGH2건 모두 ADDRESSED.

- 필수 검토 키 삭제: 원본/복제본 HTML:378에 browser/productScreenCoverage 선언. 검사기:94-100 선언/키 누락 오류와 pending 추가, 오류 시:117-120 완료false. 테스트:359-380,404-419. 실제 manifest:388-396 모두pending, 문서:32,38-41 passed는 수동 선언으로 구분.
- CLI 인자 대체 검사: 검사기:106-116 무인자/--root폴더만 허용하며 다른 인자는 audit 전에 JSON 오류. :111-113 존재하는 폴더 검증. 테스트:383-419 네 경로 차단.
- 입력 HTML/JS 실행 없음, 문자열/JSON만 읽음, Pen은 존재 검사 (:25-29,44,46-52).
- 리뷰어는 테스트를 재실행하지 않았으며 부모27leaf/Node31pass 및 실제pending2를 정적 코드/계약과 대조했다. 추가 확인 사항 없음.

위험 수용 없이 두 finding을 RED→GREEN 수정했다. 초기 HIGH 기록은 해소 전 이력이다. 실제 제품 화면 검증의 대기2건은 보안 finding 해소와 별개다.
