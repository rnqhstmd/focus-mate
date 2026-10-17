# 전체 앱 시안 동기화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking. 아래 파일 소유권과 root의 단일 검증 큐를 따른다.

**Goal:** 현재 기능 계약을 보존하면서 승인된 최신 HTML과 작업 Pen의 화면 구성·정보 위계·표면·그라데이션을 SwiftUI에 동기화한다.

**Architecture:** 기존 AppModel과 controller를 그대로 사용하고 표현 계층만 변경한다. root가 최소 공유 스타일과 메인 구성을 소유하고, 나머지 네 영역은 겹치지 않는 View 파일을 소유한다. 시간 눈금자는 기존 JourneyPlanner의 1분 정책과 유효 범위를 그대로 사용한다. 독립 MinuteRulerValue/unit seam은 아래 통제된 계획 변경에 따라 추가하지 않았고 실제 입력 focused UI로 검증한다.

**Tech Stack:** SwiftUI, MapKit, XCTest/XCUITest, 기존 FocusMate Xcode project·scheme, Python `scripts/check-ios.py`.

**Spec:** `.dev/codex-design-sync/design.md` 및 `.dev/codex-system-surfaces-w18/reports/design-sync-audit.md`. 사용자 “모두 진행”으로 이 설계의 전체 화면 범위가 승인되었다. 초안 안의 scope 대기 문구는 승인 전 이력이며 추가 확인 게이트가 아니다.

## Global Constraints

- 후속 HTML 명시 결정 → 대체되지 않은 작업 Pen 개선 프레임 순으로 대조한다. 기준 hash·프레임 ID는 설계 문서를 따른다. 원본 Pen 전용 최종 아이콘을 보존하고 Pen 파일 전체를 서로 덮어쓰지 않는다.
- 기능 로직·저장·마이그레이션·복구·후보 계산·선택 유효성·타이머 권위·pause/resume·승하차 중복 방지·메모 저장·W09b 집계·Widget/Island 계약은 변경하지 않는다. 새 기능과 폐기 기능을 복원하지 않는다.
- 준비 소리 초기 `.bus`, 기존 발급 햅틱 및 발급의 Reduce Motion 예외, 승차 Reduce Motion 억제를 그대로 유지한다. HTML pulse 수치를 CoreHaptics에 복사하지 않는다.
- 현재 accessibilityIdentifier와 의미·포커스·뒤로가기·실패 초안 보존을 유지한다. 시간 입력만 wheel 전제를 가로 ruler의 접근성 adjustable/slider 계약으로 명시적으로 이전한다.
- 스타일 상수를 그대로 복사한 테스트를 추가하지 않는다. 변경한 상호작용은 의미 있는 RED→GREEN 및 기존 회귀 검사로 확인한다.
- 작업 중에는 변경 영역의 focused 검사만 실행한다. 모든 구현 통합 후 전체 검증을 한 번 실행하며 실패 수정 후 영향 범위만 재실행한다. 전체 반복 실행을 기본 루프로 만들지 않는다.
- root만 단일 시뮬레이터·빌드 큐를 실행한다. `FOCUSMATE_SIMULATOR_ID=F5C2655F-70B3-4B70-AFCA-77813611A4AC`, `FOCUSMATE_DERIVED_DATA=<worktree>/.build/w17-ios`. 다른 세션 기기·자원을 건드리지 않는다. 시작 시 `df -h /System/Volumes/Data` 확인, 10GB 미만이면 정리를 먼저 제안한다.
- 물리 햅틱 체감·실기기 VoiceOver·실제 Widget/Island 표시는 별도 미검증으로 보고한다. 시뮬레이터 화면 또는 단위 테스트로 대체 입증하지 않는다.

## Review Focus

- 작은 화면·접근성 큰 글자·키보드 표시에서도 주요 CTA와 후보 전체가 도달 가능하고 서로 겹치지 않아야 한다. Task 2/3/5의 실제 조작과 캡처로 확인한다.
- 눈금자 양끝·중간 1분 이동·급격한 드래그에서 분이 범위 밖으로 벗어나지 않고 후보 선택 해제가 기존 정책대로 일어나야 한다. Task 3의 실제 입력 UI 검사로 확인한다. 별도 순수값/unit seam은 통제된 계획 변경을 따른다.
- 후보/태그/소리 편집을 취소하거나 왕복했을 때 원래 초안과 선택 상태가 기존 계약대로 유지되어야 한다. Task 3/5에서 테스트한다.
- 정지·재진입·저장 실패 중 지도 음영과 장식이 필수 조작·경고·법적 지도 표기를 가리지 않아야 한다. Task 4/7에서 확인한다.
- 기록↔분석↔메모 및 프로필↔꾸미기 왕복 뒤 필터·선택 날짜·저장 실패 초안이 유지되고 이전 집계 결과가 같아야 한다. Task 6에서 검사한다.

## 파일 소유 경계와 통합 계약

| Owner | 수정/생성 파일 | 제외·연결 계약 |
|---|---|---|
| root / 공통·메인 | `ios/FocusMate/RootView.swift`, 새 `MainHomeView.swift`, 필요 시 `FMDesign.swift`, 새 `SceneMapBackdrop.swift`, `MainActiveJourneyView.swift` | 저장·widget navigation·root customization 상태 수명은 RootView에 유지. 새 MainHomeView는 표시값과 기존 action closure만 전달받는다. root만 공유 스타일 API 및 project 파일을 수정한다. RootView의 main 공통 padding 제거도 이 owner가 맡는다. |
| time | `TimeSelectionView.swift`, 새 `MinuteRuler.swift`, 필요 시 새 `MinuteRulerValue.swift`, 해당 unit/UI tests | JourneyPlan/JourneyPlanner/AppModel 불변. `Binding<Int>`를 기존 setMinutes로 연결, 선택/진행은 기존 model 메서드 사용. destination/time의 바깥 padding은 이 owner가 time 경계에서만 조절한다. |
| journey | `JourneyTimerView.swift`, `JourneyView.swift`, `ArrivalBriefingView.swift`, `AlightingSummaryView.swift`, 관련 UI tests | controller 생성/관찰 수명·타이머·도착/하차 저장 계약 불변. 지도 도구·노선 접힘·법적 표기를 유지한다. |
| preparation / card | `CardIssuanceView.swift`, `InitialStationSearchView.swift`, `BoardingPassView.swift`, `CardTagScreen.swift`, `BoardingTagView.swift`, `AlightingTagView.swift`, `PreparationView.swift`, 관련 UI tests | TagEditorView/SoundSelectionView는 현재 PreparationView 내부 private struct이므로 이 owner만 수정한다. controller·draft·햅틱 패턴 불변. PassFace 변경 필요 시 root에게 요청하여 단일 소유권 결정 후 수정한다. |
| records / profile | `RecordsView.swift`, `RecordMemoEditor.swift`, `RecordsAnalyticsView.swift`, `ProfileView.swift`, `CardCustomizationView.swift`, 관련 UI tests | shared analytics 계산/adapter/browser·customization controller·AppModel 불변. 출처/설정은 현행 기능과 내용 유지·공통 표현만 정렬한다. |

공유 스타일은 root가 실제 중복을 확인한 최소 API만 제공한다. 후보는 `FMDesign`의 static Color, `FMPrimaryButtonStyle`, `FMSecondaryButtonStyle`, 필요 시 `.fmPanel()` modifier이다. 채택 여부와 정확한 signature는 root가 먼저 확정·공지하며 다른 owner는 공유 파일을 수정하거나 새 범용 테마 계층을 추가하지 않는다. 화면별 그라데이션은 장면 의미가 다르므로 각 owner가 소유한다. 기존 PreparationTypography는 필요 없이 대체하지 않는다.

### Task 1: 기준·최소 공유 표현 확정 (root)

- [x] 설계 승인 상태를 기록하고 HTML의 최종 적용 CSS 및 Pen 개선 프레임을 각 담당자에게 지정한다. 감사의 오래된 “소리 없음” 문구보다 승인 설계의 `.bus` 보존을 따른다.
- [x] 기존 PassFace/PreparationTypography와 재사용 가능한 색·패널을 확인하고 필요한 최소 FMDesign API를 확정한다. 새 파일 추가 시 project 자동 포함 여부를 확인하고 필요한 project 등록은 root만 수행한다.
- [x] `SceneMapBackdrop`는 실제 정류장 point/routeCatalog에서 위치를 받아 그리는 표시 전용 지도 공통 뷰로 구현한다. 메인·시간·요약 owner는 이 인터페이스를 재사용하며 고정 예시 좌표나 캡처 이미지로 대체하지 않는다.
- [x] `.dev/codex-design-sync/reports/visual-comparison.md`에 갤러리 01–33의 reference 위치·기기/글자·상태·변경 전/후·판정 열을 만든다. 40–43은 native 유지 범위로 분리한다.
- [x] 스타일 값 복사 테스트 없이 소스 검토로 공통 API 범위를 확인하고 owner에게 전달한다.

### Task 2: 메인 화면 재구성 (root)

- [x] RootView의 현재 정류장/방면·진행 카드·꾸미기·메뉴를 새 MainHomeView의 지도 중심 상단 안내/하단 CTA/보조 탐색으로 구성한다. `mainActionFailed`, 새 여정 확인, recovery/widget 진입 수명은 RootView에 둔다.
- [x] 실제 정류장 데이터와 기존 지도 컴포넌트 재사용 가능성을 확인한다. 장식 지도 이미지로 실제 지도나 상태를 대체하지 않는다.
- [x] 정상/진행/도착 메인의 소프트웨어 경로를 focused + 마지막 전체에서 검사했다. 전체 로그의 ActiveJourneyMain3, MainActiveJourneyCard14, NewJourney19, JourneyResume16, JourneyLifecycleSafety14건은 각각0실패다. 작은 화면 메인·검색은SE18, 최대글자 메인/승차는after17·전체 BoardingLargeText2건 PASS 근거를 따른다.
- [x] 갤러리 05/17/30과 최신 HTML #main/#home/#resumeCard를 같은 상태로 대조하고 차이/수정을 기록한다.

### Task 3: 가로 시간 눈금자와 후보 패널 (time)

- [x] wheel 의존 테스트/도우미를 `rg -n 'pickerWheels|adjust\(toPickerWheelValue|setMinutes' ios/FocusMateUITests`로 전수 찾고 변경 파일 소유권을 root와 조율한다. 다른 owner 파일의 helper를 동시에 수정하지 않는다.
- [ ] MinuteRulerValue에 범위 clamp·위치↔분·1분 반올림을 순수 함수로 두고 범위 끝/중간/비정상 폭에 대한 기대값 테스트를 먼저 작성한다. JourneyPlanner.minuteRange를 사용하며 5분 snap을 추가하지 않는다.
- [x] 고정 중앙 포인터와 가로 ticks/선택 분을 Canvas+Drag로 구현한다. `MinuteRuler(value: Binding<Int>, range: ClosedRange<Int>)` 수준의 최소 입력을 사용하고 접근성 slider 식별자는 `time.ruler`, 증가/감소는 1분, 현재 값은 분으로 노출한다.
- [x] 기존 TimeSelectionUITests 및 함께 쓰는 helper의 wheel 전제를 실제 drag/접근성±버튼과 native Slider 노출·값 검사로 이전했다. 상하한15/360·60/61의1분 이동·후보 해제/진행 잠금은focused ruler2건으로 확인했다. 취소/뒤로가기/재선택 등 TimeSelection9건과 PreparationFlow7건은 마지막 전체에서 각각0실패다. 실제 VoiceOver 조절 성공으로 확대하지 않는다.
- [x] `TimeSelectionUITests` 및 영향 선택/준비 경로를 focused + 마지막 전체의 root 단일 큐로 실행했다. 전체 TimeSelection9·PreparationFlow7·BoardingFlow·PreparationEditor12건은0실패이며 SE21 시간/승차2건 PASS다. 첫/마지막 후보를 각각 실제 탭하는 추가 도달 증거는 아래 별도 항목으로 남긴다.
- [x] 작은 SE/최대 글자의 첫·마지막 후보 실제 탭: `DesignSyncRulerUITests.testLargestTextCanSelectFirstAndLastCandidateAndProceed`를 SE3/accessibility5에서 실행해1/1 PASS(exit0,231.091초; test198.577초). cardOnly 성수120분의3후보에서 첫2014/마지막421 실제 탭, 배타선택·고정CTA·준비값120/421을 검사했다. `reports/ios-boundary-24.log`와exit메타데이터가근거다. 기존전체319건/영향23의7건과다른추가실행이다.
- [x] 갤러리 06/07, HTML #time/#timeRuler/#timeJourneyOptions와 비교한다. 분·노선·거리·시간 데이터는 예시로 고정하지 않는다.

### Task 4: 집중·도착·요약 장면 표현 (journey)

- [x] 현재 material HUD를 최신 HTML 투명 HUD/검정 shade로 대응하고 지도 위 정보·pause/resume·노선 rail·도구를 재배치한다. 높이190 등 기준 수치는 같은 viewport 대조의 출발점이며 글자를 자르는 고정 제약으로 쓰지 않는다.
- [x] JourneyView 출발 안내·ArrivalBriefingView 도착 안내·AlightingSummaryView 지도/어두운 시트/완료 표시/메모/CTA의 장면별 위계를 대응한다.
- [x] 기존 controller 테스트와 타이머/도착 경계를 focused + 마지막 전체에서 검사했다. 전체 JourneyTimer9·JourneyTimerLifecycle8·JourneyTimerAccessibility5·JourneyMapAccessibility10·JourneyAbandon30·AlightingFlow14건은 각각0실패다. 요약 실패 초안/재시도focused2건 및 controller unit 전체0실패와 구분해 기록한다.
- [x] 갤러리14–20의 실제 정적 이미지와 기준을 상태별 대조했다. DEBUG 가림/지도safe-area띠를 분리해 수정하고 최종journey90 PASS로 기록했다.
- [ ] 14/18 전환의 정확 시안 일치: 해당 상태 전용 원본JPEG/동일전환기준이 없어 static 구조 검토를 넘어 모션·타이밍의exact-reference 통과로 처리하지 않는다.

### Task 5: 발급·검색·준비·승하차 표면 정렬 (preparation/card)

- [x] 발급 cardStage/저장/포커스는 유지하고 제목·여백·카드/슬롯·하단 CTA를 정렬한다. 최초 검색/빈 결과/실패의 입력·결과 위계를 정렬한다.
- [x] 준비 허브의 현재 태그 두 줄·할 일 입력·소리 시트 동작을 살려 공통 패널/CTA와 정렬한다. TagEditorView/SoundSelectionView는 같은 owner가 수정한다.
- [x] 승차권과 최신 검정 LCD 단말기의 비율·접촉 표시를 정렬한다. 녹색 구형 단말기/독립 태그 관리/좌석/반대편 확인을 복원하지 않는다.
- [x] 발급/검색/준비 편집/접촉 소프트웨어 경로를 focused + 마지막 전체에서 검사했다. 전체 CardIssuanceFlow11·FirstStationSearch8·PreparationEditor12·PreparationFlow7·BoardingTag8건은 각각0실패다. `.bus` 및 기존 Reduce Motion/햅틱 정책 보존은최종정적리뷰, 실제진동체감은별도미검증이다.
- [x] 갤러리 01–04/08–13/19/29를 최신 HTML과 대조하고 저장 성공과 애니메이션·햅틱 증거를 분리한다.

### Task 6: 기록·분석·프로필·꾸미기 정렬 (records/profile)

- [x] 기록의 달력/목록/빈 상태, 분석 주월/필터/그래프/최근 기록/메모의 위계를 현행 W09b 데이터와 연결하여 정렬한다.
- [x] 프로필·꾸미기 패널/도구/저장 취소를 정렬한다. 사진 crop/저장 controller는 유지한다. 출처 화면은 실제 법적 내용을 보존하고 주변 서체/여백만 정렬한다.
- [x] 기록·분석·프로필·꾸미기 경로를 focused + 마지막 전체와 실패 영향후속으로 검사했다. 전체 Records3·Profile22·CardCustomizationFlow13건은0실패다. RecordsAnalytics5건 중AC5가실패해 contentShape1행을고친뒤 영향23의동일class5건이모두PASS했다. 작은화면Profile은SE20 PASS다. 첫전체실패와후속성공을같은실행으로합산하지않는다.
- [x] 갤러리 21–28/31–33과 대조하고 전체 집계와 선택 태그/기간 범위를 명시한다. 소스 계산과 정적 캡처 일치를 혼동하지 않는다.

### Task 7: 통합·최종 한 번 검증·완료 근거 (root)

- [x] 모든 owner의 수정 파일·focused 결과를 통합하고 범위 밖 AppModel/controller/Shared/Widget diff가 없는지 검토한다. 미해결 통합 오류는 focused 검사로 해결한 뒤 전체 실행한다.
- [x] 변경 상호작용과 기존 핵심 흐름을 하나의 단일 sim/build 큐에서 검증한다. 명령: `FOCUSMATE_SIMULATOR_ID=F5C2655F-70B3-4B70-AFCA-77813611A4AC FOCUSMATE_DERIVED_DATA=<worktree>/.build/w17-ios python3 scripts/check-ios.py test` (파일 인자 없음 = scheme 전체). 실제 러너는 check-ios.py이며 test-ios.sh는 없다.
- [x] 전체 실행의 테스트 수·실패 수·exit·로그를 기록한다. 실패 시 원인/수정/영향을 명시하고 해당 test 파일만 `python3 scripts/check-ios.py test ios/FocusMateTests/<File>.swift` 또는 UITests 경로로 재실행한다. 테스트 파일 stem과 XCTestCase 이름을 일치시킨다.
- [x] 첫 전체 실행은 root 단일 큐에서 unit1426/UI319건으로 종료했고5931.415초/exit65였다. 이후 두 파일 수정과 영향7건만 재실행했다. 실행·기록 완료 체크이며 첫 전체 성공을 뜻하지 않는다.
- [x] 01–33의 reference/변경 전/변경 후를 같은 viewport·글자·상태로 대조하여 수용/수정/보류 및 근거를 기록한다. 작은 화면 CTA·실패·취소·큰 글자는 추가 캡처/조작한다. 캡처 생성만으로 합격 처리하지 않는다.
- [x] 최종 보고에 기능 회귀·시각 대조·접근성·실기기 햅틱·Widget/Island 실표시를 분리하고 미확보 항목 및 재개 지점을 남긴다. 커밋/PR/머지는 별도 root의 승인 범위를 따른다.

## 현재 검토 근거와 미실행 경계

이 계획은 설계·감사·현재 RootView/TimeSelectionView/JourneyView/JourneyTimerView/PreparationView 및 주요 View 구조, 기존 TimeSelectionUITests의 wheel 전제, scripts/check-ios.py와 FocusMate scheme를 읽어 작성했다. 이 계획 작성에서는 production 코드 수정·빌드·테스트·시뮬레이터 실행을 하지 않았다. 작성자에게 전달된 `reports/design-sync-audit.md`/`scripts/test-ios.sh` 경로는 실제 경로로 정정했다.

## 2026-10-16 진행 기록 — 완료 게이트 유지

표현 구현 및 실제 시각 근거가 있는 항목만 체크했다. 상태는 [state.md](state.md),33개 비교·판정은 [visual-comparison.md](reports/visual-comparison.md)를 따른다. after17 focused17/17 PASS, SE18 메인·검색 PASS/시간·프로필 FAIL → SE20 프로필 PASS/시간 FAIL → SE21 시간2 PASS다. 이를 한 실행의5/5 통과로 합산하지 않는다.

after22 collector2/2 PASS가05–16의12개만 갱신했고 다른21개는 after17 바이트를 유지한다. composite33의 실제 시각 재판정은 main/time92·card90·journey90·records91 PASS다.14/18 등 기준 없는 상태는 구조/보존 경계 판정이지 exact-reference 통과가 아니다. 첫 전체 iOS 실행은 unit1426건/0실패, UI319건/2실패로 종료(exit65,5931.415초)했다. 두 수정 후 영향 범위7건(RecordsAnalytics5+SimulatorLargeTextRecovery2)은0실패/exit0(245.476초)로 통과했다. 별도 최종 Debug Simulator 빌드는 BUILD SUCCEEDED/exit0(4.065초)다. 전체 실행 자체를 통과로 바꾸거나 서로 다른 실행을1745건 전체 통과로 합산하지 않는다.

**통제된 계획 변경 — Task 3:** 별도 `MinuteRulerValue.swift` 추출/단위 seam은 추가하지 않았다. private Canvas ruler의 작은 좌표 산술/clamp는 실제 drag15/360/60/61·후보 해제, native Slider 노출/값 및 접근성 크기의 실제44pt +/-1분 버튼으로 확인했다. 순수함수/unit 체크박스는 미체크로 유지한다. synthetic AX Slider API의 불안정성을 실제 버튼 입력으로 보완했으며 이는 실기기 VoiceOver 증가/감소 검증과 다르다.

기준 JPEG는22장 수집 이력 중 잘못 명명된04 시간 화면을 제외한 유효21장이다.04/29는03 검색 레이아웃,07은06 시간,30은05 메인을 재사용하고 상태 전용 렌더로 주장하지 않는다. 실기기 햅틱/VoiceOver/OS Widget·Island 실표시는 별도 미검증이다. 아직 실행하지 않은 기능 조합 전체를 focused 결과로 완료 처리하지 않는다.

## 마지막 미체크 감사 — 소프트웨어 근거와 남은 경계

focused만 따로 실행하지 않았다는 형식 때문에 열어두었던 항목은 `reports/ios-full.log`의 해당 class 종료/건수와 `ios-affected-23.log`를 직접 읽어 위와 같이 `focused + 마지막 전체 + 실패 영향후속`으로 정합했다. 각class PASS는 첫전체unit1426/0·UI319/2실패라는실행전체결과를대체하지않는다. wheel전수검색/이전파일목록근거는 `reports/time-impl.md`이며 이후 실제drag/접근성±버튼 경로는최종review와실행로그가우선한다.

별도 MinuteRulerValue/unit seam은 통제된 계획 변경으로 미체크다.14/18의정확한모션기준부재는별도미체크로유지한다. 새 첫/마지막후보검사는추가24의1/1 PASS로근거공백을해소했다. 이후별도빌드24도BUILD SUCCEEDED/exit0(4.557초)다. 첫전체/영향23/추가24를합산한같은실행의8건통과로표기하지않는다.

- [ ] 물리기기 VoiceOver 증가/감소·낭독체감, 햅틱 질감/강도/동기, OS Widget/Island 실제표시·갱신: 이번 소프트웨어/시각 검사 범위밖으로 미검증이다.
