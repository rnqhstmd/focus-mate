## 통합 감사 (review)

감사 범위: PRD 전체, 지정한 Swift 변경 파일, 그리고 검증 경로 확인용으로 읽은 JourneySnapshot.swift, RouteData.swift, JourneyServices.swift, FocusMateApp.swift, RootView.swift, project.pbxproj. design.md는 58KB라 읽기 예산에 막혀 전체를 읽지 못했고, 보안 키워드 grep 결과만 확인했습니다. decisions.md와 codemap.md는 읽지 않았습니다. 따라서 설계서 대비 정합성은 부분 확인입니다. 빌드와 테스트는 실행하지 않았고, 모두 정적 분석입니다.

CRITICAL과 HIGH 발견은 없습니다. 요청하신 관점별 결과는 아래와 같습니다.

### 발견 사항

- [GAP/MEDIUM] 정류장 좌표 누락 시 Release 앱이 전체 크래시함
  - 위치: JourneyCourse.swift:35-38
  - 근거: `stops`는 `coordinates[stop.id]`가 없으면 `preconditionFailure`를 부릅니다. `preconditionFailure`는 Release에서도 동작합니다. BR-1은 정류장 카탈로그가 늘어도 좌표만 추가하면 된다고 정했습니다. 그런데 `RouteStops.all`에 정류장이 추가되고 좌표가 빠지면, `JourneyMapController`의 첫 접근(`JourneyView.ensureTimer`)에서 앱이 죽습니다. 같은 파일에서 `CourseJourney.init?`는 알 수 없는 정류장을 nil로 처리해 지도 없는 W05 배치로 대체합니다. 그 방어와 일관되지 않습니다. 이 오류는 AC-5 단위 테스트로 개발 중에만 잡힙니다.
  - 권고: 좌표가 없으면 `stops`를 nil/빈 값으로 두고 `CourseJourney.init?`가 nil을 반환하게 해 W05 폴백을 태우십시오. 서울 경계 상자 검사(`seoulBounds`)도 현재는 테스트에만 있으므로 같은 폴백에 넣으십시오.

- [RISK/MEDIUM] `CourseJourney`의 입력 방어가 호출 경로의 선행 검증에만 의존함
  - 위치: JourneyCourseProgress.swift:14-30, 10, 83
  - 근거: 저장 파일의 변조 값은 모두 `JourneySnapshot.validate`(JourneySnapshot.swift:78-97)가 먼저 막습니다. 그래서 현재 경로에서는 크래시가 없습니다. 이 검증은 `direction`이 ±1, `minutes`가 1...360, `busID`가 카탈로그 값, `elapsedSeconds`가 0...총초인지 확인합니다. 하지만 `init?(journey:)`는 `direction`을 ±1로 제한하지 않습니다. 공개 memberwise `init`은 `minutesPerStop == 0`을 막지 않습니다. 이 값이면 `totalMinutes / minutesPerStop`(10행)이 0 나눗셈으로 죽습니다. `direction * totalStops`와 `minutesPerStop * 60`은 큰 값에서 정수 오버플로로 죽습니다. 이 구조체는 신뢰 경계 바로 안쪽의 타입인데 자기 불변식을 스스로 지키지 않습니다. 검증이 우회되거나 느슨해지면(예: 향후 마이그레이션 경로 추가) 바로 크래시로 이어집니다.
  - 확인된 정상 동작: `RouteStops.wrap`은 음수 나머지를 보정합니다. `clamped`는 경과 초를 [0, total]로 자릅니다. `remainingDistanceTenthsKm`은 `total > 0` 가드가 있습니다. 구간 내 `fraction`의 분모는 `bus.minutesPerStop > 0`일 때만 0이 아닙니다.
  - 권고: `init?(journey:)`에 `journey.direction == 1 || journey.direction == -1`을 추가하십시오. `init`에 `minutesPerStop > 0`과 `totalMinutes > 0` 전제를 두거나 failable로 바꾸십시오. 이 테스트는 `direction = 0`, `minutesPerStop = 0` 입력을 포함해야 합니다.

- [POLICY/MEDIUM] "앱 내 가상 코스" 표기가 시각 사용자에게 보이지 않음 (BR-1, 실제 노선 오인)
  - 위치: JourneyMapView.swift:26-45, JourneyMapDisplay.swift
  - 근거: "가상 코스"라는 말은 VoiceOver 라벨(`mapLabel`)에만 있습니다. 눈으로 보는 화면에는 실존 지명의 지도 위에 파란 닫힌 선, 정류장 점, 버스 아이콘만 있습니다. 코스 선은 도로를 따르지 않는 직선입니다. 예를 들어 성수대교 북단→뚝섬한강공원(JourneyCourse.swift:30-31) 구간은 지도상 건물과 지형을 가로지릅니다. 실제 노선으로 오인할 수 있습니다. POI는 `.excludingAll`로 숨겼는데(JourneyMapView.swift:73-79), 이는 실제 대중교통 표시와의 혼동을 줄일 뿐 가상 코스임을 알리지는 않습니다. 새로 만든 문구 중 노선번호나 도착 예측 같은 표기는 없어서 BR-1의 금지 조항 자체는 지킵니다.
  - 권고: 지도 위나 테마 시트 안에 눈에 보이는 "가상 코스" 짧은 표기를 두거나, 이를 디자인 스펙 항목으로 확정하십시오. 현재 PRD는 이를 AC로 요구하지 않으므로 사용자 결정이 필요합니다(아래 확인 사항 1).

- [POLICY/MEDIUM] Apple 지도 법적 표기 가림 여부가 자동으로 검증되지 않음 (MapKit 약관)
  - 위치: JourneyTimerView.swift:43, 48-50, JourneyMapView.swift:54, 61
  - 근거: 표기가 하단 정보에 가려지지 않게 `bottomHeight`를 `safeAreaPadding(.bottom)`으로 반영합니다. 그러나 `@State bottomHeight`의 초기값이 0이라 첫 레이아웃 프레임에는 반영이 안 됩니다. 이 프레임에서는 표기가 하단 정보 밑에 깔릴 수 있습니다. 또 `.accessibilityHidden(true)`가 Map 내부를 접근성 트리에서 지웁니다(JourneyMapView.swift:61). 그래서 AC-3의 "접근성 트리에서 표기 frame 확인" 경로는 구조상 성립하지 않고, M-1 수동 확인에 전적으로 의존합니다. 큰 글자에서 세로로 쌓이면 하단 영역이 커져 측정값이 바뀔 때도 같은 일이 생깁니다(M-4).
  - 권고: M-1과 M-4를 W14 전 필수 수동 항목으로 고정하십시오. 가능하면 `bottomHeight == 0`일 때의 첫 프레임 동작을 확인하십시오.

- [ASSUMPTION/MEDIUM] "사용자 조작만 자유 탐색으로 바꾼다"는 전제가 MapKit 콜백 동작에 의존하고 단위 테스트로는 증명되지 않음 (BR-3, FR-4)
  - 위치: JourneyMapView.swift:21-25, 56-58
  - 근거: `position`에 앱이 직접 대입할 때는 `Binding.set`이 불리지 않는다고 가정합니다. 그런데 MapKit이 카메라 이동의 애니메이션 중이나 종료 시점에 binding을 되쓰는지, 그 값이 `positionedByUser == true`일 수 있는지는 코드로 확인되지 않았습니다. 틀리면 따라가기가 임의로 자유 탐색으로 풀립니다. 이는 보안 문제가 아니라 BR-3 정합성 문제입니다. 컨트롤러 단위 테스트는 `userMovedCamera()`를 직접 호출하므로 이 경로를 증명하지 못합니다. PRD도 M-3 실기기 확인으로 일부만 다룹니다. 이 점은 설계서 630행의 "첫 타일 로딩 중 드래그 무시" 위험과 별개입니다.
  - 권고: 실기기에서 일정 시간 가만히 둔 채 카메라 이동 후에도 `follow`가 유지되는지 확인하는 항목을 추가하십시오.

- [GAP/MEDIUM] 지도 타일 요청 시 나가는 정보에 대한 문서화 누락
  - 위치: JourneyMapView.swift (MapKit 사용), 프로젝트 전체에 `PrivacyInfo.xcprivacy` 없음
  - 근거: Apple 지도 타일은 Apple 서버에서 가져옵니다. 이때 기기 IP와 보고 있는 영역(성수 일대 고정 좌표 또는 사용자가 이동한 영역)이 Apple로 전달됩니다. 이 앱은 사용자 위치를 쓰지 않으므로 사용자 위치가 새는 것은 아닙니다. 다만 "외부로 나가는 정보"가 PRD(FR-14)나 AC에 명시되어 있지 않고, 프라이버시 선언 파일도 프로젝트에 없습니다. 앱스토어 심사 시 개인정보 라벨 작성 전에 근거가 필요합니다.
  - 권고: 배포 전 App Privacy 항목을 점검하고, "지도 타일 요청으로 Apple에 전달되는 정보는 IP와 지도 영역뿐"이라는 사실을 PRD나 설계서에 한 줄 기록하십시오.

- [RISK/MEDIUM] 따라가기 버튼 아이콘이 사용자 현재 위치 기능으로 오해될 수 있음
  - 위치: JourneyTimerView.swift:75
  - 근거: `location.fill`은 iOS에서 내 위치로 이동하는 표준 글리프입니다. FR-14는 사용자 위치를 쓰지 않는다고 했는데, 이 아이콘은 쓴다고 암시합니다. 위치 권한 UI가 한 번도 안 뜨는 점과 모순되어 사용자가 혼동할 수 있습니다. 버스 아이콘 `location.north.fill`도 같은 계열입니다. 디자인 스펙으로 분리된 항목이지만, 위치 정보 관점의 오해 위험이라 기록합니다.
  - 권고: 아이콘을 버스·깃발 계열로 바꾸거나 QE-3(W14)에서 사용자에게 확인하십시오.

### 교차 검증 결과

- [정합] FR-14 위치 키 없음 — pbxproj에 `NSLocation*` 키가 없습니다(Debug·Release, `GENERATE_INFOPLIST_FILE = YES` 사용). AppInfoLocationTests가 네 개 키 부재를 단언하는 것은 diff 목록으로만 확인했고 본문은 읽지 않았습니다. 소스에 `CLLocationManager`와 `CoreLocation` import도 없습니다(`JourneyCourse.swift:3`은 주석뿐). `Map`에 `UserAnnotation`이나 `showsUserLocation` 같은 사용자 위치 요소가 없습니다(JourneyMapView.swift:25-46).
- [정합] BR-6 저장 불변 — `JourneyMapController`는 saver나 timer를 갖지 않습니다(JourneyMapController.swift:1-60). `sync`는 값을 읽어 계산하고 상태만 바꿉니다. 지도 상태는 `JourneyMapState`의 메모리 값이고 `AppModel`을 참조하지 않습니다. `JourneyView`에서 컨트롤러는 `@State` 수명이며(JourneyView.swift:13) 다시 들어오면 새로 만들어져 FR-9 기본값으로 시작합니다.
- [정합] 저장 파일 변조 방어 — `JourneySnapshot.validate`가 direction ±1, minutes 1...360, busID·정류장 카탈로그, elapsed 0...총초를 막고(JourneySnapshot.swift:83-94), `CourseJourney.init?`가 저장 도착지와 계산 도착지의 불일치를 nil로 처리해 지도 없는 W05 배치로 폴백합니다(JourneyCourseProgress.swift:29). 다만 위 MEDIUM 항목의 init 방어 공백은 남습니다.
- [정합] DEBUG 코드의 Release 누출 없음 — `JourneyTimerView`의 `path`·`diagnostics`·`mapDiagnostics` 오버레이(JourneyTimerView.swift:10-12, 34-36, 64-66, 252-284), `JourneyView`의 `testControls`·`diagnostics` 오버레이(JourneyView.swift:65-67, 95-98, 155-193), `JourneyServices.testClock`/`failNextSave`(JourneyServices.swift:20-23)가 모두 `#if DEBUG`로 감싸져 있습니다. `JourneyView.swift:159`의 `services.testClock` 사용도 DEBUG 블록 안입니다. `UITestBootstrap.swift`는 파일 전체가 `#if DEBUG`이고, 앱 쪽 참조(FocusMateApp, RootView, CardCustomizationView)도 DEBUG 안에 있는 것을 확인했습니다. Release 호출부(`JourneyView.swift:68`)도 `path` 없이 맞게 분기합니다. Release 구성에는 `DEBUG` 컴파일 조건이 없습니다(pbxproj:55). 컴파일은 하지 않았으므로 Release 빌드 성공 여부는 미확인입니다.
- [정합] 진단 값의 노출 — `test.map`과 `test.timer`는 DEBUG에서만 생기고 좌표·상태만 담습니다. 개인정보나 시크릿은 없습니다.
- [정합] BR-1 좌표 범위 — 9개 좌표 모두 서울 경계 상자(위도 37.41~37.72, 경도 126.76~127.19) 안입니다(JourneyCourse.swift:24-32). 실제 위치와의 일치 정확도는 이 감사에서 검증하지 못했습니다. PRD 자가검증의 구 범위(위도 37.53~37.55, 경도 127.03~127.06 서술)는 본문의 서울 전체 범위와 서로 다른 잔재입니다(prd.md:216, 별도 MEDIUM 사항으로는 올리지 않음).
- [정합] BR-7 산술 — 거리를 정수 산술로 반올림하며 0 나눗셈 가드가 있습니다(JourneyCourseProgress.swift:75-81). 도착 시 `scaled = 0`이라 거리 0.0이고 남은 정류장도 0입니다.
- [정합] 외부 의존성 — 새 서드파티 의존성 없음(MapKit 시스템 프레임워크만). 배포 타깃 17.0이라 `MapCameraPosition`/`Annotation` API와 호환됩니다.
- [미확인] 설계서의 장애 대응·보안 설계 섹션 — design.md를 전체 읽지 못했습니다. 읽은 범위의 설계 결정은 POI 숨김(657행), 스타일(239행), DEBUG `--fm-ui-map blank` 대체 렌더(543행)입니다. 543행은 PRD AC-40의 "DEBUG 대체 렌더 없음, M-6으로 대체" 결정과 서로 어긋나 보이며, 코드에는 `--fm-ui-map` 인자가 없습니다(UITestBootstrap에 없음). 설계서 쪽 정리가 필요할 수 있습니다.
- [불일치] AC-3의 자동 검증 가능성 — 표기 요소를 접근성 트리에서 찾는다는 전제가 `accessibilityHidden(true)`와 충돌합니다. 위 POLICY 항목 참조.

### 확인이 필요한 사항

1. 지도 위에 눈에 보이는 "가상 코스" 표기를 둘지 여부
   - 맥락: BR-1은 실제 운행으로 오해될 새 표기를 만들지 말라고만 정했습니다. 현재는 "가상 코스"가 VoiceOver 라벨에만 있고 시각 사용자에게는 안 보입니다. 직선 코스가 실존 도로 지도를 가로지릅니다.
   - 유형: 선택
   - 선택지:
     - (a) 시트 또는 지도에 짧은 "가상 코스" 표기를 둔다 (권장) — 오인 위험을 직접 줄입니다.
     - (b) 현재대로 둔다 — W14의 QE-3 확인 결과를 보고 다시 정합니다.
     - (c) 직접 입력 — 위 선택지 외 다른 의견을 직접 입력합니다

2. 설계서 543행의 DEBUG `--fm-ui-map blank` 대체 렌더를 어떻게 처리할지
   - 맥락: PRD AC-40은 이를 두지 않기로 하고 M-6으로 대체했는데, 설계서에는 아직 남아 있습니다.
   - 유형: 자유입력

### 감사 요약
- 총 6건 (CRITICAL: 0, HIGH: 0, MEDIUM: 6)
- 조치 필요 수준: 배포 차단 사항은 없음. MEDIUM 중 `CourseJourney` 입력 방어(두 번째 항목)와 좌표 누락 폴백(첫 번째 항목)은 코드 한두 군데 수정으로 해소되므로 W06 안에서 처리를 권고합니다.

관련 파일: `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyCourseProgress.swift`, `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyCourse.swift`, `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyMapView.swift`, `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyTimerView.swift`, `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneySnapshot.swift`

### 탐색 추가 항목
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneySnapshot.swift` → 저장 여정 검증(`validate`). 신뢰 경계의 실제 방어선입니다.
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/JourneyServices.swift` → DEBUG 전용 필드(`testClock`, `failNextSave`) 정의
- `/Users/bonseung/projects/focus-mate/next-step-w06/ios/FocusMate/RouteData.swift` → `RouteStops.wrap`과 버스 카탈로그

## 기계 판정 블록
```yaml
security_verdict:
  critical: 0
  high: 0
  medium: 6
```
