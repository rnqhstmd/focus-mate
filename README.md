# Focus Mate · 집중동행카드

서울 버스를 타고 떠나는 버스 여행의 디자인과 브라우저 프로토타입입니다. 검정 화면, 버스 유형별 색상, 지도 위 가상 이동을 중심으로 구성했습니다. 실제 교통 안내나 완성된 iOS 앱은 아닙니다.

현재 HTML은 화면과 상호작용을 검토하는 시안입니다. 실제 iPhone 앱은 확정된 흐름과 자산을 바탕으로 SwiftUI에서 구현할 예정이며, 이 저장소에 Swift 앱은 아직 포함되어 있지 않습니다.

## 실행

Python 3만 있으면 현재 프로토타입을 열 수 있습니다. 테스트와 재생성에는 Node.js 22 이상을 사용합니다.

```sh
git clone https://github.com/rnqhstmd/next-step.git
cd next-step
python3 -m http.server 8794 --bind 127.0.0.1 --directory designs/final
```

브라우저에서 [프로토타입](http://127.0.0.1:8794/animation-preview.html)을 엽니다. 종료는 터미널에서 `Ctrl+C`입니다. 포트가 사용 중이면 다른 포트 번호로 바꾸세요.

## 검증과 재생성

```sh
npm ci
npm test
```

다른 터미널에서 `npm run preview`로 서버를 켜고 `npm run test:browser`를 실행합니다. Windows에서는 설치된 Chrome을 사용하며, 없으면 `npx playwright install chromium`으로 검사 브라우저를 설치합니다. 다른 브라우저 실행 경로는 `FOCUS_MATE_BROWSER_PATH`로 지정할 수 있습니다.

`npm run build`는 독립 실행 자료를 `designs/prototype/`에 생성합니다. `npm run capture`는 42개 상태의 PNG·PDF를 갱신합니다. Pen 레이어 재생성에는 `python -m pip install -r requirements-design.txt` 후 `python scripts/build-revised-pencil.py`를 사용합니다. 이미 생성된 Pen 원본은 별도 설치 없이 아래 파일을 열면 됩니다.

## 어디부터 볼까

- [최종 UI·UX·플로우 검수](reports/full-ui-flow-review-2026-10-12.md): 전체 재검사, 수정 사항과 검증 한계
- [편집 가능한 Pen 원본](designs/focus-mate.pen): 최신 42개 상태와 이전 36개 시안. `designs/assets/`를 같은 위치에 유지합니다.
- [게시 프로토타입](https://next-step-app-flow.sqisoft-3053.chatgpt.site/): 최신 검수 반영 버전

- [현재 구현 상태와 흐름](docs/CURRENT-STATE.md): 최신 HTML 기준, 18개 제품 장면과 42개 화면 상태·검증 범위
- [문서 안내](docs/README.md): 현재 기준과 과거 결정의 구분
- [디자인 안내](designs/README.md): 프로토타입, PNG·PDF, 글꼴·버스·소리 자산
- [조사·수정 보고서](reports/README.md): 제품 조사와 구현 변경 기록

```text
docs/             현재 상태와 문서 안내
designs/final/    실행 가능한 HTML, 디자인 스냅샷과 자산
reports/          조사·디자인·회귀 검증 기록
scripts/          상태·브라우저 검사, 화면·Pen 레이어·오디오 재생성
```

프로토타입은 생성 지도 이미지와 예시 경로를 사용합니다. 실제 GPS·MapKit·실시간 버스 API를 연결하지 않습니다. 현재 정류장 저장은 같은 브라우저의 localStorage를 사용하며 다른 컴퓨터와 동기화되지 않습니다. 글꼴과 자산의 출처는 [디자인 안내](designs/README.md)를 확인하세요.

- [전체 화면 승하차 태그와 여행 요약](reports/fare-tag-and-journey-summary-2026-10-12.md): 간단한 승차권 → 카드와 단말기 → 하차 태그 후 요약·선택 메모.

- [멈춘 여정 이어가기](reports/journey-resume-2026-10-12.md): 앱 복귀 시 남은 여정을 직접 재개하고 새 여정은 정리 여부를 확인합니다.

- [Focus Mate · 집중동행카드와 검은 단말기](reports/focus-mate-card-and-reader-2026-10-12.md): 첫 카드 발급, 검은 LCD의 카드 표시, 접촉 순간 진동과 상태 저장.
