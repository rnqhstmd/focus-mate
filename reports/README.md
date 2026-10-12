# 보고서 목록

> 현재 기준 (2026-10-12): [현재 상태](../docs/CURRENT-STATE.md) · [MVP 범위](../docs/MVP.md) · [화면·저장 계약](../docs/FLOWS.md). 과거 변경 기록은 당시 검증 증거로 보존합니다.


2026-10-11 이후의 작업 기록입니다. 날짜가 같아도 후속 요청으로 결정이 바뀌었습니다. 현재 기준은 [현재 상태](../docs/CURRENT-STATE.md)이며, 아래 보고서는 당시 조사·변경·검증을 보존합니다.

## 최신 전체 검수

- [UI·UX·플로우 전체 검수 및 수정](full-ui-flow-review-2026-10-12.md): 최종 42개 상태·12개 브라우저 검사·Pen 원본 보존·게시 버전
- [기계 판독 검증 결과](verification/full-review-2026-10-12.json)

## 시안 복원 이후 비교 조사

- [조사 기준을 반영한 시안 개선](research-flow-improvements-2026-10-12.md): 준비 허브 통합, 카드 피드백, 지도·소리 복구, Pen·프로토타입 반영과 검증.
- [Page Flows·Appshots·Spotted in Prod 비교와 개선 방향](pageflows-appshots-spotted-review-2026-10-12.md): 세 사이트의 공개 사례, 접근 범위, 16장면과 36개 시안의 차이, 준비·승차·여행·완료의 개선 우선순위. 구현 변경이 아닌 제안입니다.

## 최근 동작 기준

- [시간 선택 카드·정보 정리](time-card-simplification-2026-10-12.md)

- [GitHub 형태의 연간 기록 잔디](github-activity-heatmap-2026-10-12.md)

- [분 단위 시간을 먼저 고르는 흐름](minute-first-journey-2026-10-12.md)

- [여행 분석과 하차 후 메모](analytics-and-alight-memo-2026-10-12.md)

- [실제 녹음 기반 소리 샘플 교체](recorded-audio-2026-10-12.md)

- [여행 기록 달력과 누적 저장](records-calendar-2026-10-12.md)

- [시작 화면의 동네 인사말](neighborhood-welcome-2026-10-12.md)
- [이번 여정 미리보기 잘림 수정](home-preview-clipping-fix-2026-10-12.md)
- [한 바퀴 미리보기·첫 출발지·지도 메인](one-lap-preview-and-first-station-2026-10-11.md)
- [지도 안전영역·미리보기·도착 안내](map-safe-area-and-route-preview-2026-10-11.md)
- [레이아웃·승차권·합성 소리](layout-pass-and-audio-2026-10-11.md) — 오디오 최신 레벨은 [SOURCE.md](../designs/final/assets/audio/SOURCE.md)를 우선
- [준비 시트·태그 선택 정리](preparation-sheet-cleanup-2026-10-11.md)
- [버스에서 할 일 준비 허브](journey-preparation-flow-2026-10-11.md)

## 디자인 변경 기록

- [시안과 프로토타입 정렬](prototype-design-alignment-2026-10-11.md)
- [여행 화면 정리](travel-screen-refinement-2026-10-11.md)
- [진행 방향 추적 지도](heading-up-travel-ui-2026-10-11.md)
- [정류장 목록 정리](station-rail-refinement-2026-10-11.md)
- [서울 버스 시각 체계·서체](seoul-bus-visual-system-2026-10-11.md)
- [Componentry·60fps 참고 검토](componentry-60fps-design-review-2026-10-11.md)
- [경계 조건과 접근성 점검](prototype-edge-cases-2026-10-11.md)

## 제품·기술 조사

- [자체 서버 없는 생산성 앱 후보](serverless-productivity-app-ideas-2026-10-11.md)
- [일상 앱과 서울 집중 버스 검토](everyday-apps-seoul-focus-bus-2026-10-11.md)
- [초기 화면·기능 제안](seoul-focus-bus-screen-proposal-2026-10-11.md)
- [창밖 실제 풍경 가능성](bus-window-scenery-feasibility-2026-10-11.md)
- [FocusFlight 방식 MapKit 가능성](focusflight-mapkit-bus-feasibility-2026-10-11.md)

공식 문서상 가능성, 브라우저 상태 모형 검사, 실제 iOS 검증을 구분합니다. 과거 보고서의 검사 통과는 현재 환경에서 실행을 마쳤다는 의미가 아닙니다.

- [전체 화면 승하차 태그와 여행 요약](fare-tag-and-journey-summary-2026-10-12.md): 간단한 승차권 → 카드와 단말기 → 하차 태그 후 요약·선택 메모.

- [멈춘 여정 이어가기](journey-resume-2026-10-12.md): 앱 복귀 시 남은 여정을 직접 재개하고 새 여정은 정리 여부를 확인합니다.

- [Focus Mate · 집중동행카드와 검은 단말기](focus-mate-card-and-reader-2026-10-12.md): 첫 카드 발급, 검은 LCD의 카드 표시, 접촉 순간 진동과 상태 저장.

- [마이페이지와 사진으로 카드 꾸미기](card-customization-2026-10-12.md): 고정 IC 칩·배경색·다중 사진 캔버스·기기 저장·승하차 반영.

최신 후속 변경: [승차 단말기 정리](boarding-reader-refinement-2026-10-12.md). 브라우저 검증 이전/이후 범위는 현재 상태 문서를 확인합니다.
