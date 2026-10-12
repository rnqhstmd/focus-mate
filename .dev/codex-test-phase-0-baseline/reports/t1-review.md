# T1 R3 재리뷰

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|---|---|---|
| AC-1 | ✅ | check-design-baseline.cjs:25-45 원본/복제본·필수 파일, design-baseline.test.cjs:131-217 정상/불일치/누락/손상 실제 CLI 검증 |
| AC-2 | ✅ | check-design-baseline.cjs:71-90 원본 productSceneIds와 정확 대조, internal/viewer/layer/state/Pen 연결. 원본 HTML:379-380. 제품 삭제 회귀 design-baseline.test.cjs:221-225 |
| AC-3 | ✅ | check-design-baseline.cjs:92-104,117-120 자동/수동 상태 분리. 실제 manifest:388-396 pending2, 문서:3,32-45 진행 중·선언과 증거 구분 |
| AC-4 | ✅ | 원본 HTML:378 requiredBaselineReviews, 검사기:94-103 필수 항목 및 선언 누락 오류. 테스트:359-380 |
| AC-5 | ✅ | 검사기:106-120 허용 인자/경로 검증 및 JSON 오류로 audit 차단. 테스트:382-419. 문서:30 |

[Must] 5건 중 5건 충족. 전달 증거는27 leaf/Node31 pass, SHA3dd73a4642a70d2a1b859b5308b71b579cd4bc55이며 리뷰어는 테스트를 재실행하지 않았다. 실제18/21/42/copies23, errors0/pending2로 제품 Phase0 미완료 유지.

## 설계 범위 이탈

core이며 정식 설계서 없음. 승인5AC와 코드 맵 기준. 원본/실행 HTML은 독립 기준선 metadata 추가이며 실행 UI/저장 로직 변경 없음. CLI/테스트/manifest/문서/설정 모두 승인 범위. 이탈 없음.

## Part 1 판정

SPEC PASS.

## 재리뷰 판정

| 항목 | 판정 | 근거 |
|---|---|---|
| 승인 제품 장면 삭제가 통과함 | ADDRESSED | 검사기:71-75 원본 productSceneIds와 상호 대조 |
| 제품 장면 삭제 테스트 부재 | ADDRESSED | 테스트:221-225,275-287 삭제 이름/오류/exit1 |

## Part 2: 코드 품질 리뷰

Critical0, Important0, Minor0. QUALITY PASS. 직접 수정·실행 없음.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 5
  ac_met: 5
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```
```yaml
quality_verdict:
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 0
```
