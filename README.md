# 다음 정류장

서울 버스를 타고 떠나는 버스 여행의 디자인과 브라우저 프로토타입입니다. 검정 화면, 버스 유형별 색상, 지도 위 가상 이동을 중심으로 구성했습니다. 실제 교통 안내나 완성된 iOS 앱은 아닙니다.

현재 HTML은 화면과 상호작용을 검토하는 시안입니다. 실제 iPhone 앱은 확정된 흐름과 자산을 바탕으로 SwiftUI에서 구현할 예정이며, 이 저장소에 Swift 앱은 아직 포함되어 있지 않습니다.

## 실행

Python 3만 있으면 현재 프로토타입을 열 수 있습니다.

```sh
git clone https://github.com/rnqhstmd/next-step.git
cd next-step
python3 -m http.server 8794 --bind 127.0.0.1 --directory designs/final
```

브라우저에서 [프로토타입](http://127.0.0.1:8794/animation-preview.html)을 엽니다. 종료는 터미널에서 `Ctrl+C`입니다. 포트가 사용 중이면 다른 포트 번호로 바꾸세요.

## 어디부터 볼까

- [현재 구현 상태와 흐름](docs/CURRENT-STATE.md): 최신 HTML 기준, 16개 장면과 검증 범위
- [문서 안내](docs/README.md): 현재 기준과 과거 결정의 구분
- [디자인 안내](designs/README.md): 프로토타입, PNG·PDF, 글꼴·버스·소리 자산
- [조사·수정 보고서](reports/README.md): 제품 조사와 구현 변경 기록

```text
docs/             현재 상태와 문서 안내
designs/final/    실행 가능한 HTML, 디자인 스냅샷과 자산
reports/          조사·디자인·회귀 검증 기록
scripts/          상태 회귀 검사와 합성 오디오 생성
```

프로토타입은 생성 지도 이미지와 예시 경로를 사용합니다. 실제 GPS·MapKit·실시간 버스 API를 연결하지 않습니다. 현재 정류장 저장은 같은 브라우저의 localStorage를 사용하며 다른 컴퓨터와 동기화되지 않습니다. 글꼴과 자산의 출처는 [디자인 안내](designs/README.md)를 확인하세요.
