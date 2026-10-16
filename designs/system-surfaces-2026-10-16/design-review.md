# Focus Mate 시스템 표면 시안과 코드 검토

2026-10-16. 현재 체크아웃 main 0346276 기준 읽기 전용 검토. 앱 소스 수정, 테스트 실행, 실제 Island 렌더링 검증은 이번 작업에서 하지 않았다.

## 시안

- `live-activity-board.png`: compact, minimal, expanded, 잠금 Live Activity, paused, completed.
- `widget-concepts-board.png`: 홈 small/medium, 잠금 accessory, StandBy 표현, dark medium.
- 생성 도구: built-in image_gen. 기준 이미지: 앱의 AppIcon-1024.png.
- 프롬프트 방향: 창문 심볼 유지, 차콜·오프화이트, 약한 새틴 하이라이트, 읽기 쉬운 한국어·고정폭 시간. Live Activity는 시간·노선·목적지·상태 우선, 카메라 영역 비우기. 홈 위젯은 일일 요약 또는 앱 진입. 가짜 GPS·버스 ETA·잔여 정류장·미구현 제어 버튼 금지.
- 생성 이미지의 모양·서체·기기 비율은 참고용이다. SwiftUI 구현 규격이나 실제 스크린샷이 아니다.

## 현재 구현과 시안의 차이

현재 FocusMateWidgetsBundle은 JourneyLiveActivityWidget만 제공한다. 홈 위젯/잠금 accessory Provider는 없다.

Live Activity 현재 attributes는 journeyID, busNumber, busKind, destinationName이고 상태는 status, endDate, pausedRemainingSeconds다. 시간은 집중 세션 남은 시간으로, 실제 버스 도착 예측이 아니다.

시안의 '집중 중'은 현재 '운행 중'을 바꾸는 문구 제안이다. 최종 문구는 앱 전체와 맞춘다. 이미지의 143 간선/서울숲/18:42는 예시이며 실노선 운행정보를 주장하지 않는다.

보드 02 minimal의 원형 링은 시각 탐색이다. 현재 attributes에는 시작 시각/총 시간이 없어 정확한 진행률을 계산할 수 없다. 1차 구현에서는 창문/정지/체크 심볼로 단순화한다. 진행률 링을 채택하려면 데이터 계약을 추가한다.

보드 06 완료 카드는 종료 정책 변경 제안이다. 현재 정상 완료는 즉시 제거하며, 만료(stale) fallback에서만 완료 문구를 보여준다. Activity 종료 후 Dynamic Island는 시스템에서 제거된다. 완료 내용을 잠금 화면에 잠깐 유지하는 제안과 Island 유지 약속을 혼동하지 않는다.

홈/잠금 accessory의 '48분 · 2회'는 새 위젯 제안의 예시 데이터다. 공유 저장소/App Group, 일일 집계 스냅샷, timeline과 변경 후 reload 배선이 추가로 필요하다. 기록이 없을 때에는 '첫 여정을 시작해요' 같은 빈 상태도 필요하다. 시간 표시가 필요하면 시스템 동적 날짜 표시를 활용할 수 있으며, 위젯 전체를 매초 reload하는 방식은 피한다.

StandBy는 Live Activity가 표시될 수 있는 시스템 표면이다. 현 Live Activity의 실제 자동 표현은 아직 확인하지 않았고, 보드는 전용 큰 글자 구성의 목표 시안이다. 별도 홈 위젯 구현과 구분한다.

## 우선 개선

### 1. Compact/minimal 상태 구분

`ios/FocusMateWidgets/JourneyLiveActivityWidget.swift:29–35`에서 두 상태 모두 같은 버스 심볼/시간으로 표시한다. compact 접근성 라벨도 노선만 설명한다. 일시정지에는 pause 심볼, minimal에는 상태 심볼을 사용하고 접근성 문구에 상태를 포함한다.

### 2. 표면별 시간/완료 표시

같은 시간 뷰를 compact 56pt 칸과 minimal에도 넣는다(`JourneyLiveActivityWidget.swift:33–35,76–78`). 현재 여행 시간 범위는 15…360분(`ios/FocusMate/JourneyPlanner.swift:5`)이며, `360:00` 또는 '도착했어요'가 작은 공간에 들어갈 수 있다. 실제 잘림은 미검증이다. compact에는 짧고 명확한 시간 형식, minimal에는 심볼, expanded/잠금에는 상세 시간을 사용한다. 0:05/9:59/99:59/120:00/360:00/paused/stale를 미리보기와 실제 Island에서 확인한다. 긴 목적지·노선 번호·큰 글자도 검증한다.

### 3. 잠금 카드 정보 계층과 브랜드

현재 `bus.fill`과 80% 검정 배경(`JourneyLiveActivityWidget.swift:10,15,30,52`)이다. 작은 표면은 단색 창문 심볼로 교체하고, 넓은 카드에서는 노선·상태를 위 행, 목적지·큰 남은 시간을 아래 행에 놓는다. '남은 집중 시간' 라벨로 ETA 오해를 줄인다. 심볼에는 앱 아이콘의 정사각형 배경을 넣지 않는다.

### 4. 완료 카드 정책

`JourneyLiveActivityPolicy.swift:42`는 arrived에서 nil을 반환하고, Sync:31–34는 end를 요청하며 Gateway:35–37은 `.immediate`로 종료한다. 완료 카드를 원하면 정상 완료의 final content와 잠금 화면 dismissal 정책을 별도 설계한다. 취소/교체/오류 정리는 즉시 종료와 분리한다.

### 5. 접근성 중복 읽기

잠금 카드의 왼쪽 그룹 라벨은 paused 남은 시간을 포함하고 오른쪽 고정 시간 Text도 별도 요소다(`JourneyLiveActivityWidget.swift:61–64`, `JourneyActivityDisplay.swift:25–31`). 중복 낭독 가능성이 있으며 실제 VoiceOver 확인이 필요하다. running 시스템 타이머는 별도로 유지하되, paused 정적 시간은 한 번만 읽히도록 구성한다.

## 유지할 기존 설계

- `JourneyTimerController.swift:118–131`: 백그라운드에서도 시간 유지, 복귀 시 경과 반영.
- `JourneyLiveActivityPolicy.swift:34–48`: running은 endDate 기반 시스템 카운트다운, paused는 만료 없는 고정 시간.
- `JourneyLiveActivitySync.swift:7–10,36–44`: 매초 ActivityKit update를 보내지 않는 중복 억제.
- 표시 정책/동기화/실패/재진입 테스트가 존재한다. 기록기 기반 UI 테스트는 실제 Island 레이아웃·VoiceOver 증거와 구분한다.

## 권장 적용 순서

1. 현재 Live Activity의 상태/작은 영역 표현 개선 + 창문 심볼/레이아웃 적용.
2. 정상 완료 카드 유지 여부 결정 및 final content 종료 정책 적용.
3. 홈 medium 진입 위젯 → 공유 집계 데이터를 쓰는 small/잠금 accessory.
4. 실제 장치의 Dynamic Island, 잠금, StandBy, 큰 글자·VoiceOver 검증.

## Apple 참고

- https://developer.apple.com/design/human-interface-guidelines/live-activities
- https://developer.apple.com/design/human-interface-guidelines/widgets
- https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date
- https://developer.apple.com/documentation/widgetkit/displaying-dynamic-dates

이번 결과는 시안과 정적 코드 분석이다. 구현 완료나 실제 시스템 렌더링 통과를 의미하지 않는다.
