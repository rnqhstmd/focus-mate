# 디자인 안내

> 현재 기준 (2026-10-12): [현재 상태](../docs/CURRENT-STATE.md) · [MVP 범위](../docs/MVP.md) · [화면·저장 계약](../docs/FLOWS.md). 과거 변경 기록은 당시 검증 증거로 보존합니다.


최신 인터랙션은 [final/animation-preview.html](final/animation-preview.html)입니다. 저장소 루트의 [실행 방법](../README.md)을 따라 로컬 서버로 열어주세요. 소스와 이미지 경로를 유지하기 위해 파일을 옮기지 않습니다.

## 현재 실행 자료

- [앱 흐름 프로토타입](prototype/README.md): 최신 조사 반영 흐름과 자동 재생. HTML·Pen과 같은 제품 규칙을 사용한다.

- [프로토타입](final/animation-preview.html): 현재 18개 제품 장면의 여행 흐름
- [개선 시안](revised/README.md): 42개 상태·편집 가능한 Pen 레이어·PDF
- [버스·서체 비교](final/bus-guide.html): 버스 유형 색상과 서체의 시각 참고
- [현재 상태](../docs/CURRENT-STATE.md): 최신 화면·동작 결정

## 디자인 스냅샷

[최종 V4 설명](final/README.md)과 아래 자료는 기존 디자인 시점의 스냅샷입니다. 이후 HTML 수정이 모든 PNG·PDF에 다시 반영된 것은 아닙니다.

- [전체 흐름](final/overview.png)
- [시작과 여행 계획](final/01-plan.png)
- [집중과 도착](final/02-focus.png)
- [기록과 설정](final/03-records-settings.png)
- [모달과 오류](final/04-modals-errors.png)
- [시스템 상태](final/05-system-states.png)
- [화면 목록](final/SCREENS.md)과 개별 `final/screens/01.png`~`36.png`
- [38페이지 PDF](final/next-stop-final.pdf)
- [브랜드](final/brand.png), [아이콘](final/app-icon-1024.png), [모션 보드](final/motion-storyboard.png)

편집 가능한 원본은 [focus-mate.pen](focus-mate.pen)입니다. 최신 42개 상태와 이전 36개 시안·흐름 보드를 함께 보존합니다. 저장소를 내려받아 이 파일을 Pencil에서 열고 `assets/` 폴더를 같은 위치에 유지하세요. 최신 노드 ID는 [revised/pencil-node-ids.json](revised/pencil-node-ids.json), 참조 이미지 목록은 [editable/asset-manifest.json](editable/asset-manifest.json)입니다.

최신 42개 PNG·PDF와 `revised/flow-overview.png`는 최종 검수 뒤 다시 생성했습니다. [전체 검수 결과](../reports/full-ui-flow-review-2026-10-12.md)를 함께 확인하세요.

## 자산 출처

- [서울 서체](final/assets/fonts/SOURCE.md): 사용 파일과 공식 출처·이용 조건
- [버스 그래픽](final/assets/bus/SOURCE.md): 유형별 시각 표현과 예시의 범위
- [여행 오디오](final/assets/audio/SOURCE.md): CC0 원본·편집 과정·청취 검증 한계
- [오디오 측정](final/assets/audio/audio-stats.json): 최신 정량 결과

지도는 생성 이미지이며 실제 MapKit 출력이 아닙니다. 현재 빗소리·숲·버스 소리는 CC0 현장 녹음이며 핑크 노이즈는 스튜디오 샘플입니다. 현장 녹음 장소는 가상 서울 노선과 다릅니다.

- [전체 화면 승하차 태그와 여행 요약](../reports/fare-tag-and-journey-summary-2026-10-12.md): 간단한 승차권 → 카드와 단말기 → 하차 태그 후 요약·선택 메모.

- [멈춘 여정 이어가기](../reports/journey-resume-2026-10-12.md): 앱 복귀 시 남은 여정을 직접 재개하고 새 여정은 정리 여부를 확인합니다.

- [Focus Mate · 집중동행카드와 검은 단말기](../reports/focus-mate-card-and-reader-2026-10-12.md): 첫 카드 발급, 검은 LCD의 카드 표시, 접촉 순간 진동과 상태 저장.

최신 후속 변경: [승차 단말기 정리](../reports/boarding-reader-refinement-2026-10-12.md). 브라우저 검증 이전/이후 범위는 현재 상태 문서를 확인합니다.

현재 편집 보드 내보내기: [42개 상태 PDF](revised/pen-updates/focus-mate-current-42.pdf) · [전체 흐름 PNG](revised/pen-updates/focus-mate-current-flow.png).

## Pen 파일 관리 — 2026-10-13

Pen 원본은 저장소의 [focus-mate.pen](focus-mate.pen) 하나로 관리한다. Pencil에서는 이 파일을 직접 열어 편집하고(파일 → 열기), 편집 후 저장하면 그대로 git 변경으로 잡힌다. 이미지 참조는 `.pen` 기준 상대 경로이므로 `assets/next-stop/`(기존 시안·승차권 질감)와 `images/`(생성 이미지)를 같은 위치에 둔다. `.gitattributes`가 `*.pen`을 바이너리로 다루므로 줄 단위 비교는 되지 않는다. 변경 내용은 `revised/README.md`와 `revised/pen-updates/` 렌더로 기록한다. Pencil 앱 내부 문서 폴더(`~/.pencil/documents/…`)의 사본은 원본이 아니다.
