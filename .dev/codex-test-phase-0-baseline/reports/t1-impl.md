# T1 IMPLEMENT — 시안 기준선 검사

## 구현 내용
- check-design-baseline.cjs: 원본/복제본·필수 파일·상태/노드 연결·수동 검토 상태 JSON 보고.
- design-baseline.json: 현재 18/21/42 분류와 23개 자료 복제 연결, 미검증 2개 항목.
- package.json: 새 테스트를 npm test에 포함, check:baseline 등록.
- PHASE-0-BASELINE.md / DEVELOPMENT-PHASES.md: 증거 범위와 남은 시각 검증 기록.

## GREEN 증거
- node --test scripts/design-baseline.test.cjs: 21 leaf 사례 통과 (부모 그룹 포함 24 pass / 0 fail).
- 실제 자료 검사: errors 0, counts 18/21/42, automationPassed true, phase0Complete false.
- R1의 기준선 파일 누락/손상은 JSON 오류 보고로 변경했다.

## REFACTOR 내역
- root를 실제 경로로 정규화해 macOS /tmp 별칭을 허용하고 프로젝트 밖 경로는 차단.
- audit 경계로 파일 오류 보고를 묶고 들여쓰기를 정리했다. 테스트 해시를 유지했다.

## self-review 결과
- 앱 동작·UI·저장 키 변경 없음. 입력 JS 실행 없음, Pen 내용 셸 해석 없음.
- product와 viewer는 다른 분류이며 제품 전체가 Pen 캡처에 포함됐다고 주장하지 않음.
- 공개 API는 실제 CLI 한 개이며 미사용 export를 추가하지 않음.

## 우려사항
- 최신 브라우저 승차와 tags 화면 시각 확인은 미완료이며 제품 Phase 0는 진행 중으로 유지.

## 리뷰 R2 수정

- 원본 HTML에 productSceneIds metadata를 명시하고 manifest의 제품 목록과 정확히 대조한다. 제품18과 시연42를 1:1로 강제하지 않는다.
- manifest에서 제품 장면 하나를 삭제하는 실패 테스트를 RED 역할이 추가했다. 부모가 RED 재현 후 수정했다.
- 21 leaf / Node 집계24 pass, 전체 npm test 및 npm build exit0. 실제 자료 검사 errors0, 완료 false 유지.
- 앱 UI/저장 동작 변경 없음. 최신 승차 브라우저·tags 캡처는 여전히 pending.
- core 보안 감사 HIGH2건의 처리 답변 대기. verify 최종 게이트·commit·PR은 실행하지 않았다.

## 감사 R3 수정

- 원본 requiredBaselineReviews literal과 manifest review 항목 대조. 필수 키 또는 literal 부재는 JSON 오류+exit1.
- CLI 인자 엄격 검증. 잘못된 옵션/값 누락/추가 인자/없는 root는 JSON 오류+exit1이며 다른 폴더를 검사하지 않음.
- 부모 직접 RED 재현 후 최소 수정, 27 leaf / Node 집계31 pass / 0 fail. 테스트 hash 3dd73a4642a70d2a1b859b5308b71b579cd4bc55 유지.
- build exit0, actual baseline errors0/pending2. self-review: 추가 export/실행 가능한 입력 코드/신규 의존성 없음.

## 최종 검증

2026-10-12T23:06:17+09:00 fresh npm test: Node31/31 + 기존VM 회귀 exit0. npm build exit0, 경고0(baseline0). code fingerprint 95939b2:2190ce4b9c39. AC1~5 충족, scoped reviewer 및 core보안 재검토 통과. 제품 화면 검증pending2는 완료로 선언하지 않음.
