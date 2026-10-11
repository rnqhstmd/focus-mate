# 다음 정류장 디자인 참고 검토

확인일: 2026-10-11. 사용자가 언급한 Componentry는 주소가 없어, 현재 컴포넌트 카탈로그가 운영되는 componentry.dev를 대상으로 확인했다. 공개 사이트와 컴포넌트 문서, 60fps의 shot 설명을 읽었다. 이번 조사에서 실제 영상 재생이나 컴포넌트 설치·실행은 수행하지 않았다.

추가 홈·집중 화면 개선에서는 [FocusFlight 공개 앱 모음](https://60fps.design/apps/focusflight)을 다시 확인했다. 지도 위 준비 시트로 여행을 시작하는 구성을 참고했다. 시간대 인사말, 정류장의 버스 선택, 집중 태그, 기본 노출 정류장 안내는 사용자 요청에 맞춘 자체 설계이며 FocusFlight의 실제 기능이나 문구를 그대로 재현한 것이 아니다.

## 역할과 적용 판단

| 자료 | 확인한 제공 형태 | 다음 정류장에 적용할 방향 |
|---|---|---|
| [Componentry](https://componentry.dev/docs) | React용 애니메이션 컴포넌트와 사용/설치 문서 | 카드 정보 위계, 선택 스냅·관성·페이드 등 일부 표현을 참고 |
| [60fps.design](https://60fps.design/) | 실제 앱 인터랙션 모음, 앱·패턴·제스처·요소 필터 | iOS 홈 진입, 하단 시트, 지도·시간 연동과 탭 피드백 설계 참고 |

Componentry 문서는 React·Framer Motion 등의 의존성을 명시한다. 따라서 SwiftUI에서는 모양과 동작을 재구현하는 것이 적합하다는 판단이다. 현재 데모도 단일 HTML이므로 라이브러리를 통째로 설치하는 변경은 하지 않았다.

## 적용할 후보

1. [Flight Status Card](https://componentry.dev/docs/components/flight-status-card): 출발·도착·진행률·남은 시간 정보가 있는 여행 카드. 버스 승차 준비/기록 상세의 정보 위계에 적합하다. 집중 지도에는 기존의 작은 HUD를 유지하는 것이 좋다.
2. [Wheel Carousel](https://componentry.dev/docs/components/wheel-carousel): 관성 드래그, 선택 항목 스냅, 가장자리 페이드 옵션을 제공한다. 현재 시간 선택의 수평 눈금을 유지하며 선택 감각을 다듬거나 소리 선택에 참고할 수 있다. 곡선 휠 자체로 바꾸자는 제안은 아니다.
3. [FocusFlight 시간 선택](https://60fps.design/shots/focusflight-duration-slider-swipe-interaction): 선택 시간·목적지·지도 경로를 연결하는 흐름에 참고.
4. [FocusFlight 탑승권](https://60fps.design/shots/focusflight-boarding-pass-check-in-scroll-interaction): 지도 맥락을 유지하며 준비 정보를 펼치는 흐름에 참고. 우리 앱의 카드 터치 승차는 유지한다.
5. [FocusFlight 시작 지도](https://60fps.design/shots/focusflight-get-started-map-zoom-in-animation): 지도와 흰 경로, 문구, 시작 버튼을 순서대로 공개하는 설명이 있다. 현재 정류장 홈에서 자연스럽게 여행 시작으로 안내하는 데 참고. 제목은 Zoom In이지만 본문은 zoom out이라고 설명하므로 정확한 카메라 방향은 영상 확인 후 결정해야 한다.
6. [Apple 앱 모음](https://60fps.design/shots/filter/apple): Apple 내장 앱의 하단 시트·아이콘·터치 피드백 참고. Apple의 공식 구현 문서와 동일하게 취급하지 않는다.

## 현재 적용 우선순위

메인 홈→시간 선택→카드 터치→집중→하차→메인 흐름을 먼저 안정화한다. 다음 단계에서는 홈 진입과 시트 높이 전환의 연속성, 카드 누름 피드백을 다듬는 것이 좋다. 이 판단은 앱의 집중 목적과 현재 지도 중심 시안에 따른 제안이다. 배경 WebGL·커서 hover·매초 플립 등은 이번 앱에 추가하지 않았다.

이번 요청으로 수정한 내용은 designs/final/README.md와 QA.md에 정리했다. 이후 사용자가 제안 적용을 승인해 여행 카드 정보 위계, 시간 선택 관성/스냅, 지도 위 하단 시트 전환을 기존 HTML/Pen에 맞춰 반영했다. React 패키지를 설치하지 않고 참고한 패턴을 현재 구조로 구현했다.
