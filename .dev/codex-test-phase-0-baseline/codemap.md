# Phase 0 코드 맵

## 핵심
- designs/final/animation-preview.html: 최신 제품 UI·상태·저장 계약
- designs/final/flow-viewer.js: 제품과 분리된 42개 화면 시연
- scripts/prototype-edge-qa.cjs: 21개 내부 장면과 여정/접촉/복원 VM 회귀

## 참조
- designs/prototype/index.html: 빌드가 복제하는 실행 HTML
- designs/focus-mate.pen: 편집 가능한 원본, 셸 해석 금지
- designs/revised/pencil-layers.json: 42개 상태 생성용 레이어
- designs/editable/document-snapshot.json: 저장한 Pen 전체 문서 스냅샷
- docs/FLOWS.md: 제품 18개 논리 장면과 저장/취소 계약
- docs/CURRENT-STATE.md: 확인한 증거와 미검증 범위
- docs/DEVELOPMENT-PHASES.md: Phase 0~6 범위, 미래 개발 계획 제외
- reports/boarding-reader-refinement-2026-10-12.md: 최신 승차 VM·Pen 근거, 브라우저 미검증
- scripts/build-flow-prototype.py: 현재 HTML·뷰어·자산 패키징

## 설정
- package.json: npm build/test
- .claude/config.json: GX core 선택과 별개인 standard 모델 프로필
- .gitignore: 빌드 아티팩트, 로컬 .dev/.active 제외
