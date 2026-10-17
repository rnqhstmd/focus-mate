# 전체 앱 시안 동기화 — 승인 설계

상태: 2026-10-16 사용자가 “모두 진행”으로 전체 범위 구현을 승인했다. 표현 구현·시각 검토 및 첫 전체/영향 범위 후속 검증이 종료됐다. 첫 전체는2실패였고 수정 후 해당7건이 통과한 결과로 구분한다. architect audit, 이 문서의 대응표 및 reports/visual-comparison.md를 함께 사용한다.

## 의도
사용자는 현재 기능이 동작하지만 기존 Pen/HTML 시안과 앱의 화면 구성·그라데이션·진동이 다르다고 지적했다. 목표는 새로운 디자인을 만드는 것이 아니라 기존 기준의 정보 위계, 배치, 표면 표현, 상태 전환과 피드백을 SwiftUI 앱에서 일관되게 경험하게 하는 것이다. 자동 기능 테스트 통과만으로 시안 일치를 판정하지 않는다.

## 문서에 명시된 기준 우선순위
- 사용자 지정 기준: `designs/focus-mate.pen`, `designs/final/animation-preview.html`.
- Pen 두 파일 차이 감사에 따른 기준: **후속 HTML + 작업 checkout의 개선 프레임**을 사용하고 원본 전용 최종 아이콘은 보존한다. 원본 `/Users/bonseung/Documents/ChatGPT/new/designs/focus-mate.pen`을 작업본으로 통째 덮어쓰거나 반대 방향으로 대체하지 않는다. architect는 작업본 준비 r8 패널/티켓 r11/승하차 검정 LCD/집중 HUD 등이 후속 HTML과 일치한다고 확인했다. 본 작성자는 노드 렌더를 재검증하지 않았으며 판단 근거는 architect audit다.
- 기준 파일 SHA-256(직접 읽기 확인): 작업 Pen `b929d9b7a34605f62b18edce64abb91e264f5d0ba03b39223d70aa444139571a`, 원본 Pen `8d12be8feea752d499da59b088dc867ab3520ec26e650097afa4ae2117db3092`, HTML `87d9370ebfad5091acaff407031064fcf00e858c91dc11b6afff43683d8f0ff7`. 이 기준에서 후속 변경 시 차이를 기록한다.
- 문서 이력: `designs/final/SCREENS.md`는 36개 Pen/PNG의 인덱스이며 후속 HTML 결정이 전부 반영된 최신 화면 목록은 아니라고 명시한다.
- `designs/final/README.md:67–91`과 `SCREENS.md`는 후속 변경이 HTML 기준이며 Pen/PDF가 이전 시안일 수 있음을 명시한다. 따라서 명시된 후속 HTML 결정 → 대체되지 않은 Pen 시각 요소 순으로 적용한다. 이 우선순위는 root의 추측이 아니라 기존 문서 근거다. 문서로 해소되지 않은 충돌은 따로 기록한다.
- 04 반대편 확인·09 좌석 선택, 옛 독립 할 일 화면·태그 관리 등은 이미지 존재만으로 부활시키지 않는다. 실제 앱의 현재 승인 기능과 연결되는 유효 화면/상태만 대응시킨다.
- HTML은 누적 CSS를 포함하므로 최초 선언의 색/좌표를 최신 값으로 간주하지 않는다. 실제 적용된 최종 규칙과 상태를 대조한다. Pen 좌표를 기기 safe area·큰 글자에 무조건 고정하지 않는다.
- native Widget/Island는 해당 기능에서 승인된 네이티브 시안을 유지한다. 과거 웹/Pen의 시각·타이머 표현으로 되돌리지 않는다.

## 보존할 기능 계약
SwiftUI의 저장·마이그레이션·복구, 여정 선택 유효성, 태그/할 일/소리 초안, 승하차 중복 방지, 타이머 권위와 pause/resume, 완료 기록·메모, 분석 계산과 필터 범위, 위젯 최소 공유/안전 진입은 유지한다. 이 문서는 정책·데이터 모델 변경을 승인하지 않는다.

화면 재배치 뒤에도 뒤로가기, 편집 취소/저장 실패, 앱 비활성화, 재진입의 기존 결과가 같아야 한다. 접근성 이름·상태·포커스·핵심 컨트롤 도달을 장식보다 우선한다. 기능을 숨겨 시안을 맞추거나 실제 데이터 대신 예시 텍스트를 고정하는 것은 실패다.

## 화면 묶음과 목표

| 묶음 | 대조할 상태 | 동기화 대상 | 유지·확인할 동작 |
|---|---|---|---|
| 시작 | 첫 이용, 발급 전/중/후, 최초 정류장 검색·빈 결과·실패 | 제목/설명 위계, 카드/슬롯 표현, CTA 위치, 발급 움직임과 피드백 | 발급 저장 1회, 실패/복구, 검색 선택과 방면, 초점 이동 |
| 메인·준비 | 메인 정상/진행/도착 카드, 시간/버스, 준비 미선택/입력, 태그/소리 편집 | 지도와 정보 비율, 배경/그라데이션 범위, 간격·서체·태그 칩·버튼 위계 | 유효 선택만 진행, 편집 취소/왕복 초안, 미리듣기 정리, 기존 여정 확인 |
| 승하차·집중 | 승차권, 접촉 전/인식/완료, 출발 안내, 진행/노선 펼침/정지/포기, 도착/하차/요약 | 카드·단말기 비율, 접촉 연출, 지도 overlay·HUD·그라데이션·정지 모양 | 실제 타이머/저장 권위, 터치 대체 경로, 이탈 정리, 완료/포기 1회, 기록 보존 |
| 기록·프로필 | 기록 있음/없음, 선택 날짜·메모, 주/月 분석·필터, 프로필·꾸미기·출처 | 그래프·목록 위계, 긴 이름/빈 상태、편집 표면·버튼 | W09b 집계 불변, 날짜/태그 범위 명시, 메모 실패 초안, 사진/프로필 저장과 취소 |

갤러리 원본은 `.dev/codex-system-surfaces-w18/screen-gallery-2026-10-16/manifest.json`이다. capture 33개와 preview 4개를 읽고 각 PNG 파일 존재를 확인했다. 아래는 근거 대응이며 픽셀 대조 완료 판정이 아니다. Pen 근거는 작업본 JSON에서 ID와 개선 프레임 이름을 직접 확인한 결과다. 이름 대응은 렌더 일치 판정이 아니며 세부 요소는 구현 시 최신 HTML과 대조한다. 직접 대응이 없는 출처 화면은 현행을 유지하고 공통 토큰만 정렬한다.

| 갤러리 ID | HTML 장면/요소(소스 존재 확인) | Pen 근거 | 판정/동기화 경계 |
|---|---|---|---|
| 01-card-before | #issue | R35 dGyGQ | 수정: 발급 구성/카드/CTA |
| 02-card-issued | #issue, #issueStamp | R37 KKaGq | 수정: 완료 구성, 저장 동작 유지 |
| 03-first-station-search | #search | R03 fL7RF | 수정: 검색 배치 |
| 04-first-station-results | #searchResults | R03 fL7RF / R04 XM0Rr | 수정: 결과/키보드, 방면 선택 유지 |
| 05-main-empty | #main, #home | R01 CcKpX | 수정: 메인 구성, 잘림 확인 |
| 06-time | #time, #timeRuler | R06 c72dCj / R26 Zsv0p | 수정: 눈금/지도/하단 정보 |
| 07-bus-destination | #timeJourneyOptions, #timeSelectedSummary | R06 c72dCj | 수정: 선택 후보 위계, 실데이터 유지 |
| 08-preparation | #prepare, #prepareTags | R07 pcsoD | 수정: 허브, 초기 .bus 유지 |
| 09-tag-editor | #tagEdit | R09 WrVs7 | 수정: 편집 표면, 생성만 유지 |
| 10-sound | #sound | R10 a4F0n | 수정: 소리 시트, 미리듣기 정리 유지 |
| 11-preparation-task | #prepareInputGroup, #taskInput | R08 kjVd8 | 수정: 허브 내 입력/키보드 |
| 12-boarding-pass | #board | R11 TUNX2 | 수정: 승차권 구성, 하단 잘림 확인 |
| 13-boarding-tag | #boarding, #boardingReader | R27 kxUUR | 수정: 카드/단말기, 인식 계약 유지 |
| 14-departure | #departureBriefing | R12-1 DO8HO | 수정: 안내 위계/그라데이션 |
| 15-journey-map | #focus, #mapTools, #stationRail | R13 v7CByw / R13-1 w5RAL | 수정: 지도 HUD/접힌 노선 |
| 16-journey-paused | #pausedOverlay | R15 dqEMj | 수정: 정지 표현, 타이머 불변 |
| 17-main-active | #resumeCard | R31 y3tXR / R33 LRPCx | 수정: 이어가기 카드, 기존 확인 유지 |
| 18-arrival-briefing | #arrivalBriefing | R13-2 uPkg8 | 수정: 도착 안내, 저장 경계 유지 |
| 19-alighting-tag | #alighting | R28 yu5nz | 수정: 하차 접촉 표현 |
| 20-alighting-summary | #arrival | R17 We8JD / R30 CjBjx | 수정: 요약 위계, 완료/메모 유지 |
| 21-records | #records, #recordCalendar, #recordList | R19 DDMAd | 수정: 달력/목록, DEBUG 가림 제외 |
| 22-record-memo | #postMemoForm(동일 편집 화면인지 추가 추적) | R25 DOIzP(메모 표면 참고, 기능은 현행 유지) | 수정: 메모 편집, 실패 초안 유지 |
| 23-analytics-top | #analytics, #analyticsRangeTitle | R23 S1PZb(후속 W09b 확장 유지) | 수정: 기간/요약, W09b 계산 유지 |
| 24-analytics-scrolled | #analyticsRecent | R23 S1PZb + 현행 W09b(최근 기록은 HTML 기준) | 수정: 최근 기록 위계 |
| 25-profile | #profile | R38 EPnQQ | 수정: 프로필 구성 |
| 26-card-customization | #cardStudio | R39 z3LCu / R40 x3PCFl | 수정: 편집 표면, 사진/저장 유지 |
| 27-data-source | 직접 대응 없음 | 직접 대응 없음; 현행 유지·공통 토큰만 | 유지: 법적 출처, 주변 서체/여백만 정렬 |
| 28-settings-placeholder | #settings | R20 b0s2M(표현 참고, 새 기능 제외) | 유지: 현재 범위; 미구현 기능 추가 제외 |
| 29-real-station-results | #searchResults | R03 fL7RF / R04 XM0Rr | 수정: 04와 같은 틀, 실제 번들 이름 유지 |
| 30-real-main | #main, #home | R01 CcKpX | 수정: 05와 같은 틀, 실데이터 유지 |
| 31-real-data-source | 직접 대응 없음 | 직접 대응 없음; 현행 유지·공통 토큰만 | 유지: 실제 출처 내용, 임의 예시 치환 제외 |
| 32-analytics-middle | #analyticsDonut, #analyticsLegend | R23 S1PZb + 현행 W09b | 수정: 태그 구성, 합계/필터 유지 |
| 33-analytics-memos | #analyticsMemos, #analyticsMemoList | R23 S1PZb + 현행 W09b(본문은 HTML 기준) | 수정: 메모 회고, 개인정보/집계 범위 유지 |

40~43 preview는 승인된 native Live Activity/Widget 표현 **유지**이며 이번 앱 화면 재디자인에서 제외한다. 구성 요소 미리보기이고 실제 갤러리·Island·시스템 낭독 증거가 아니다. capture 05·12의 잘림과 21의 DEBUG 진단 가림은 manifest에 이미 기재돼 있다. 진단 가림을 제품 디자인으로 이식하지 않는다. 33개는 모든 오류/상호작용을 포괄하지 않으므로 수정한 화면의 실패·취소·큰 글자 상태를 추가 확인한다.

## 실제 확인한 충돌과 아직 결정하지 않은 것

1. **문서와 현재 앱의 소리 초기값:** SCREENS.md 마지막 문단은 소리 없음 시작을 말하지만 `PreparationDraft.swift:97`은 `.bus`다. 현재 HTML도 기본값 변수에 연결되어 있으므로 문서 문장만 보고 none으로 바꾸지 않는다. 이번 작업은 기능 불변이므로 `.bus`를 유지한다. 이는 시각 정렬과 별개의 과거 문서 충돌로 기록하고 none으로 바꾸지 않는다.
2. **햅틱과 Reduce Motion:** HTML `issueHaptic`(:1015)는 reduce가 켜지면 진동을 생략한다. 네이티브 `CardIssuanceController.swift:62–63`은 하드웨어 지원 시 발급 햅틱을 실행하고 reduceMotion은 대기 시간에 적용한다. 발급 패턴도 HTML의 짧은 `issueHaptic(18)` 호출과 네이티브 `IssuanceHapticPattern.issuance`의 약→강 연속 진동+끝 탭으로 다르다. `.dev/feat-boarding-pass-tag/design.md:426`은 기존 발급 햅틱 유지·승차 Reduce Motion 억제를 명시한다. 승인된 이번 구현에서는 기존 정책을 유지했다. 별도 변경 응답이 없는 상태를 승인 대기 게이트로 만들지 않고, HTML pulse를 구현 확정값으로 보지 않는다. 브라우저 vibration 수치를 CoreHaptics 강도로 그대로 치환하지 않는다.
3. **그라데이션의 대조 기준:** HTML에는 `.departure-briefing`(:466)의 다중 stop+blur와 집중/정지 overlay의 누적 규칙이 있다. 네이티브 `JourneyView.swift:162`에는 두 색 배경 그라데이션이 있다. 서로 다른 상태의 규칙을 같은 화면이라고 단정할 수 없으므로 대응 상태 캡처에서 범위·투명도·시작/끝·지도를 가리는 정도를 확인한다. 수치 차이만으로 결함 판정하지 않는다.
4. **Pen의 유효 범위:** 이번 초안 작성자는 Pen 노드의 직접 렌더를 검증하지 않았다. SCREENS.md의 후속 폐기/대체 이력은 확인했지만 Pen 대 HTML의 구체적 시각 충돌은 architect audit 후 추가한다.

## 햅틱의 완료 의미
화면 피드백 사건(발급 시작/완료, 승하차 접촉 등), 발생 조건·횟수·취소 조건과 네이티브 패턴을 대응시킨다. 기존 저장 성공/실패·중복 방지 경계는 유지한다. 시뮬레이터와 fake 호출 검사는 이벤트/구조만 증명하며 강도·질감·연출 동기 체감을 증명하지 않는다. 물리 기기 청취/진동 체감은 현재 미검증으로 별도 남기고 이를 화면 동기화 완료 근거에 섞지 않는다.

## 유의미한 완료 증거
- 같은 기기 크기·글자 설정·기준 상태/데이터에서 reference/변경 전/변경 후를 나란히 비교한다. 지도 타일·시간 등 환경 변동은 설명하고 레이아웃 불일치로 오인하지 않는다.
- 각 갤러리 항목에 reference 위치, 상태 진입 조건, 차이, 수용/수정/보류 판정을 남긴다. 색·간격의 코드 존재나 스크린샷 생성만으로 승인 처리하지 않는다.
- 화면별 주요 경로와 바뀐 상태 전환만 focused 검증한다. 입력/저장/취소/뒤로가기·큰 글자·접근성 노출 중 영향 있는 부분을 실제 조작한다. 스타일 상수를 그대로 복사한 테스트는 만들지 않는다.
- 사용자 지시대로 각 변경분에 필요한 검사 후 **최종 전체 검증 한 번**을 수행한다. 이 초안 작성에서는 빌드/테스트/시뮬레이터를 실행하지 않는다. 최종 실패 시 영향 범위와 수정 내용을 구분해 보고한다.
- 기능 회귀, 시각 대조, OS 접근성, 햅틱 실기기 체감, Widget/Island 실표시는 서로 다른 증거다. 미확보 항목은 이유와 재개 지점을 남긴다.

## 승인 범위와 검증 경계
33개 대응표의 추적 필요 항목과 주요 시각 차이는 architect audit로 보강한다. 소리 .bus와 기존 햅틱 정책은 유지하며, 선택 질문에 대한 사용자 응답이 있으면 햅틱 변경 범위를 별도로 반영한다. 전체 화면 범위는 승인되었으며, 별도 햅틱 정책 변경 승인은 추정하지 않는다. 실제 구현 추적은 implementation-plan.md, 최신 실행 상태는 state.md, 재개 지점은 RESUME.md를 따른다.


## HTML 햅틱 원문 계약과 네이티브 보존 경계

아래 pulse는 HTML 원문 관찰값이며 새로운 네이티브 패턴 승인이 아니다. 공통 `issueHaptic`(:1015)은 Reduce Motion, API 미지원 시 false이며 예외를 삼킨다. `navigator.vibrate` 반환 실패가 화면/저장 성공을 바꾸지 않는다.

| 사건 | HTML 원문 트리거/패턴 | 중복·취소·실패 조건 | 이번 설계의 처리 |
|---|---|---|---|
| 발급 시작 | issueTransitPass(:1016), `issueHaptic(18)` | issue 장면·발급 중 아님·기존 카드 없음 guard; 발급 중 버튼 비활성. persist 실패를 햅틱 호출 자체의 guard로 삼지는 않음 | 현재 네이티브 저장 성공 경계와 기존 pulse 유지. 별도 정책 변경은 미승인 |
| 발급 완료 | 같은 함수 timeout 뒤 `[15,40,25]`; reduce이면100ms, 일반900ms 후 | 완료 callback에서 scene이 issue가 아니면 반환. 재진입/중복은 시작 guard와 발급 상태로 제어. 실제 진동 API 실패는 성공 UI를 막지 않음 | 네이티브 발급 연속 패턴을 임의 제거하지 않음. 이탈/취소 정책과 성공 저장 조건 유지 |
| 승차 접촉 | completeFareTag(:1049), tagged 상태 진입 때 `[20,35,30]` | 장면·준비값·tapPending guard, 카드/대체 버튼 비활성. token 불일치·장면 이탈·document.hidden이면 인식 callback 취소 | 네이티브 중복 저장/전환 토큰 및 Reduce Motion 억제 유지 |
| 하차 접촉 | 같은 함수 alighting branch의 `[20,35,30]` | alightPending guard, 버튼 비활성·장면 검사. HTML 호출은 recordJourney 앞이므로 저장 성공을 보증하는 신호로 해석하지 않음 | 기존 하차 원본 보존/저장 실패 계약 유지, 웹 순서로 대체하지 않음 |

햅틱 차이의 사용자 응답 전 기본값은 `.dev/feat-boarding-pass-tag/design.md:426`의 기존 발급 유지·승차 reduce 억제다. 성공/취소/실패 UI와 재생 횟수는 focused 검사, 물리 진동 체감은 실기기 미검증으로 분리한다.

## 최신 실행 증거

현재33개 변경 후 이미지는 after22의05–16/12개와 after17의나머지21개를 출처별로 유지한 composite다. 최종 main/time92·card90·journey90·records91 시각 PASS는 구조/색/위계/CTA/지도 출처 대조이며 기준 없는 상태의 정확 일치나 모션·햅틱 보증이 아니다.

after17 focused17/17 PASS. SE는18 메인·검색,20 프로필,21 시간2가 각각 통과했으며 같은5/5 실행은 아니다. 첫 전체 iOS 실행은 unit1426건/0실패, UI319건/2실패로 종료(exit65,5931.415초)했다. 두 수정 후 영향 범위7건(RecordsAnalytics5+SimulatorLargeTextRecovery2)은0실패/exit0(245.476초)로 통과했다. 별도 최종 Debug Simulator 빌드는 BUILD SUCCEEDED/exit0(4.065초)다. 전체 실행 자체를 통과로 바꾸거나 서로 다른 실행을1745건 전체 통과로 합산하지 않는다. 실기기 햅틱·VoiceOver·OS Widget/Island 표시는 미검증이다.
