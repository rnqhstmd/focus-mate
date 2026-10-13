# 조사 반영 개선 시안

2026-10-12. [상세 조사](../../reports/pageflows-appshots-spotted-review-2026-10-12.md)를 반영한 [제작·검증 기록](../../reports/research-flow-improvements-2026-10-12.md).

현재 제품 흐름은 [HTML](../final/animation-preview.html)과 [게시 프로토타입](https://next-step-app-flow.sqisoft-3053.chatgpt.site)에서 체험한다. 18개 제품 장면과 42개 화면 상태를 다룬다. `*.png`와 `next-stop-revised.pdf`는 이번 렌더 스냅샷이다.

편집 가능한 시안은 [../focus-mate.pen](../focus-mate.pen)에 포함한다. 최신 42개 상태와 전체 흐름 보드, 과거 36개 시안과 기존 보드를 함께 보존했다. 이미지 경로를 위해 `../assets/`도 유지한다. 디자인 내용은 Pencil MCP로 읽고 수정했으며 JSON은 `.pen` 파일 자체가 아니다.

`pencil-layers.json`에는 개별 글자·벡터·이미지 레이어가 있다. UI 글자와 도형은 편집 가능하다. 지도·개인 사진은 비트맵이고, 카드 바탕·글자·IC 칩은 네이티브 레이어이며, 웹의 서울알림체 대신 Pen에서는 Noto Sans KR을 사용한다.

현재 레이어 정의는 텍스트 745개와 벡터 도형·경로 1561개다. 최초 개선판 이후 [홈 미리보기 잘림](../../reports/home-preview-clipping-fix-2026-10-12.md)을 고치며 R04를, [동네 인사말](../../reports/neighborhood-welcome-2026-10-12.md)을 넣으며 R01·R18을 갱신했다. [누적 기록 달력](../../reports/records-calendar-2026-10-12.md)을 적용하며 R19와 연결된 흐름 보드를 갱신했다. [실제 녹음 소리 교체](../../reports/recorded-audio-2026-10-12.md) 후 R10의 이름·안내와 PDF도 갱신했다. `flow-overview.png`는 첫 카드 발급·반복 여행·카드 꾸미기·여정 복원의 네 줄 흐름 보드의 내보내기이며, 보드의 화면은 개별 컴포넌트와 연결되어 있다. `verification.json`에는 최초 개선판의 브라우저 직접 실행 결과를 기록했다.

재생성 순서:

1. 로컬 서버에서 `designs/final/animation-preview.html`을 연다.
2. `npm run capture`로 42개 PNG·PDF를 생성한다. 현재 여행 진입·시간 화면은 `node scripts/minute-first-browser-qa.cjs`로, 메인 인사는 `node scripts/main-welcome-qa.cjs`로 검사·캡처한다. 기록·분석 변경은 해당 전용 QA를 사용한다.
3. `python scripts/build-revised-pencil.py`로 레이어 정의를 생성한다.
4. 정의를 Pencil MCP의 `Replace`로 반영한다.
5. `python scripts/build-flow-prototype.py`로 동일한 흐름을 게시용으로 묶는다.

완료 기록·메모는 이 브라우저에 저장되고 연간 색 잔디에서 날짜별로 확인한다. R19에 표시한 여러 날짜는 저장과 분리한 예시 기록이다. 지도와 운행 정보는 가상 예시다.

[여행 분석과 하차 후 메모](../../reports/analytics-and-alight-memo-2026-10-12.md)를 반영해 R18·R19를 갱신하고 R23 분석·R24 빈 분석·R25 하차 후 메모를 추가했다. `analytics-memo-qa.cjs`의 월/주 집계·메모·화면 검사와 `records-calendar-qa.cjs`의 기존 달력 검사를 실행했다.

[시간 우선 선택](../../reports/minute-first-journey-2026-10-12.md)을 반영해 R04 출발 안내·R06 시간을 갱신하고 R05를 후보 없음으로 바꿨다. R26은 후보 선택 전 화면이다. 분 단위 눈금 다음에 버스·도착 정류장을 고르며 시간 바로가기 카드는 제거했다. `minute-first-browser-qa.cjs`로 해당 변경의 동작·화면·캡처를 검사한다.

[GitHub 참고 연간 잔디](../../reports/github-activity-heatmap-2026-10-12.md)를 적용하며 R19 기록·R23 분석·R24 빈 분석과 연결된 흐름 보드를 갱신했습니다. 완료 기록만 집계하고 시연 화면은 예시 데이터입니다.

[시간 선택 정보 정리](../../reports/time-card-simplification-2026-10-12.md)를 반영하며 R05·R06·R26을 갱신했다. 후보 개수와 중복 경로 요약을 제거하고 버스·도착지 카드를 좌우로 스크롤해 선택한다.

[시작 한 번으로 출발](../../reports/direct-start-journey-2026-10-12.md)을 반영하며 R02 안내 문구와 R04를 출발 정류장의 초기 시간 선택으로 갱신했다. 별도 시간 선택 확인 버튼은 제품 흐름에 없다.

[전체 화면 승하차 태그와 요약](../../reports/fare-tag-and-journey-summary-2026-10-12.md): R11 승차권·R12 승차 성공·R17 요약을 갱신하고 R27 승차 태그·R28 하차 태그·R29 하차 성공·R30 요약 메모를 추가했습니다. 단말기는 편집 가능한 벡터와 텍스트입니다.

- [멈춘 여정 이어가기](../../reports/journey-resume-2026-10-12.md): 앱 복귀 시 남은 여정을 직접 재개하고 새 여정은 정리 여부를 확인합니다.

R15 일시정지에 메인 복귀를 추가하고 R31 이전 여정 이어가기·R32 새 여정 확인·R33 여정 재개·R34 하차 태그 이어가기를 추가했습니다. 전체 보드에는 재개 분기가 있으며 컴포넌트 인스턴스와 연결됩니다.

- [Focus Mate · 집중동행카드와 검은 단말기](../../reports/focus-mate-card-and-reader-2026-10-12.md): 첫 카드 발급, 검은 LCD의 카드 표시, 접촉 순간 진동과 상태 저장.

R35~R37은 카드 발급 전·출력·발급 완료입니다. R38~R42는 마이페이지·꾸미기 빈 상태·사진 배치·꾸민 카드·같은 카드 승차입니다. 카드 캔버스는 사진·글자·칩 레이어를 둥근 프레임 안에서 클리핑합니다. 최신 검증은 [카드 꾸미기](../../reports/card-customization-2026-10-12.md)와 [발급·단말기](../../reports/focus-mate-card-and-reader-2026-10-12.md)에서 확인합니다.

최종 UI·UX·플로우 전체 재검수 결과는 [최종 검수 보고서](../../reports/full-ui-flow-review-2026-10-12.md)를 사용한다. 42개 상태를 실제 반응형 화면에서 검사했으며, 최신 통합 결과는 [검증 JSON](../../reports/verification/full-review-2026-10-12.json)에 기록했다. 이 폴더의 `verification.json`은 최초 개선판 결과를 보존한 기록이다.


## 승차 단말기 후속 수정 — 2026-10-12
[승차 화면 수정 기록](../../reports/boarding-reader-refinement-2026-10-12.md)을 반영해 Pen의 R27·R12·R42를 갱신했다. [대기 화면](pen-updates/boarding-reader-2026-10-12/kxUUR.png), [인식 완료](pen-updates/boarding-reader-2026-10-12/JmXmQ.png), [꾸민 카드 승차](pen-updates/boarding-reader-2026-10-12/Vts6F.png)는 최신 Pen 렌더다. 수정한 세 화면의 네이티브 레이어를 pencil-layers.json과 document-snapshot.json에도 동기화했다. [최신 Pen 42개 화면 PDF](pen-updates/focus-mate-current-42.pdf)와 [최신 전체 흐름 보드](pen-updates/focus-mate-current-flow.png)를 새로 내보냈다. 기존 브라우저 캡처·PDF는 이전 검수 시점의 자료이며 최신 동작은 HTML을 기준으로 확인한다.

## 집중 화면 지도 도구·하단 정보 — 2026-10-13
[화면·상태 계약](../../docs/FLOWS.md#집중-화면-지도-도구와-하단-정보--2026-10-13)에 따라 Pen의 R13 집중 지도·R14 다음 정류장의 오른쪽 지도 버튼을 나침반/2D·지도 모드/전체 노선/따라가기 두 묶음으로 바꾸고, R13·R14·R15 하단 수치를 좌우 끝 정렬·38px 숫자·흰색 단위로 고쳤다. R15는 일시정지 안내를 24px 올려 Apple 지도 표기 자리를 비웠다. 지도 모드 시트는 42개 상태 밖의 보조 화면 `개선 R13-1 · 지도 모드`(노드 `w5RAL`)로 추가했고 R13 인스턴스 위에 시트를 얹었다. 위성 미리보기는 AI 생성 이미지 자리표시이며 실제 Apple 위성 사진이 아니다. pencil-layers.json·document-snapshot.json은 이번 변경을 반영하지 않았다.

출발 안내: 승차 인식 뒤 확인을 눌러야 출발하는 보조 화면 `개선 R12-1 · 출발 안내`(노드 `DO8HO`)를 추가했다. R13 인스턴스에서 하단 수치·지도 도구·일시정지·정류장 목록을 끄고 안내 패널을 얹었다. 렌더는 `pen-updates/focus-map-2026-10-13/DO8HO.png`다.

## 승하차 태그 화면·도착 안내 — 2026-10-13
R27 승차 태그·R12 승차 완료·R28 하차 태그·R29 하차 완료·R42 꾸민 카드 승차에서 제목·정류장·단계 표기·하단 안내·패드 라벨·상표 문구를 끄고, 단말기를 카드 폭에 맞춘 네이티브 레이어(본체 274×338, LCD 238×112, 태그 영역 238×160)로 다시 그렸다. 완료 화면은 카드가 태그 영역 아래쪽 가장자리에 걸친 모습이다. 하차 전 도착 안내 보조 화면 `개선 R13-2 · 도착 안내`(노드 `uPkg8`)를 추가했다. 렌더는 `pen-updates/tag-and-briefing-2026-10-13/`에 있다. 기존 PDF 기반 벡터는 삭제하지 않고 꺼 두었다.
