# AC별 최종 증거 원장

상태: **표현 구현·composite33 시각 수용·첫 전체 종료 및 영향7건/별도 빌드 통과**. 이 문서는 모든 AC의 완료 선언이 아니다. source 존재, 실제 캡처 관찰, focused 실행 결과와 미검증 범위를 분리한다. 본 원장 작성 중 빌드·테스트·시뮬레이터·캡처를 추가 실행하지 않았다.

## 공통 원본과 실행 출처

- 승인 기준: [prd.md](../prd.md), [design.md](../design.md). 현재 소스 검토는 [review-final.md](review-final.md)의 정적 PASS/actionable finding 없음이며 전체 실행 성공을 뜻하지 않는다.
- 실제 변경 전/후/reference 대응: [visual-comparison.md](visual-comparison.md). 변경 후33건은 단일 실행이 아니라 **after22의05–16/12건 + after17의나머지21건** composite다. [after-capture-observations.json](after-capture-observations.json)에 항목별 source attachment/bundle/hash가 있다. 과거 파일을 최신 재캡처로 바꿔 부르지 않는다.
- 실제 시각 판정: [main/time 92](visual-main-time-final.json), [card 90](visual-card-final.json), [journey 90](visual-journey-final.json), [records 91](visual-records-final.json), 모두 pass. 점수는 각 보고서가 명시한 상태·구조 범위이며 픽셀 동일성이나 전체 기능 통과 점수가 아니다.
- [after17 focused](after-capture-focused-17.log:4452): **17건/0실패, TEST SUCCEEDED**. 구성은 collector9 + ruler2 + 최대 글자 검색/시간2 + 메인/승차2 + 요약2다. collector는 실제 캡처 수집 실행이며 오류·취소·저장 경계 전체를 검증한 회귀 검사로 계산하지 않는다.
- 작은 화면 후속 결과는 서로 다른 실행이다. [small18](small-18.log)은5건 중3실패이며 메인·검색2건만 pass. [small20](small-20.log:657)은 프로필1건 pass/시간 관련2건 fail. [small21](small-21.log:1660)은 시간·승차2건/0실패. 이 결과를 같은 실행의5/5로 합산하지 않는다.
- [after22 collector](after-capture-focused-22.log:762)는2건/0실패이며05–16 실제 이미지를 갱신했다. 수집 성공 자체는 시각 승인과 다르다.

## AC1 — 발급·검색·메인 및 주요 조작 도달

**Source:** CardIssuanceView/InitialStationSearchView/MainHomeView/RootView가 승인된 카드·하단 패널·지도·CTA 위계를 표현한다. 검색은 같은 scroll 안에 제목·입력·결과를 두고 확인 action을 분리하며 submit으로 키보드를 닫는다. 메인 도구는 스크롤 밖에 있고 root의 기존 navigation/lifecycle closure를 사용한다.

**Actual capture:** 01–05/17/29/30과 card/main 시각 보고서. 04/29는 reference03 검색 레이아웃을 재사용하며, 실제 결과 전용 원본 렌더는 확보하지 않았다. 30은 reference05 메인 레이아웃 재사용이다. 실제 데이터가 기준 예시와 다른 것은 보존 범위다.

**Focused runtime:** after17의 최대 글자 검색, 메인 주요 메뉴 도달·프로필 진입 pass. small18의 메인 F3와 최대 글자 검색 pass. 발급/첫 정류장 collector 경로는 실제 화면 수집 근거다.

**Runtime update:** 전체 실행의 SimulatorLargeTextRecovery AC32는 실패했고 실제 후보 도달 입력 보조 수정 후 같은 AC32/AC33 두 건이 영향23 실행에서 통과했다. 제품 조건/선택값 assertion은 유지했다. **Limit:** 전체 실행의 다른 실패와 후속 실행 범위를 아래 AC6에서 분리한다. 캡처의 기본 글자 수용을 모든 접근성 크기 수용으로 확대하지 않는다.

## AC2 — 15…360, 1분 입력, 후보 무효화와 native AX

**Source:** TimeSelectionView/MinuteRuler는 일반 크기 Canvas 가로 드래그, 접근성 크기 native Slider와 실제44pt ±1분 버튼을 제공한다. 범위 clamp와 step1, 기존 setMinutes/chooseJourneyRoute/proceed 연결을 보존한다. 접근성 후보는 세로 흐름으로 바꾸어 높이 충돌을 해결했다.

**Actual capture:** 06/07은 after22. 실제 native Apple Maps/Legal이 검정 패널 위에서 읽히며, 중앙 시간·눈금·후보·진행 CTA는 실제 이미지에서 대조했다. 07은 reference06의 공통 틀 재사용이고 선택 상태 전용 원본 렌더는 아니다.

**Focused runtime:** after17 ruler2건은 실제 손가락 drag로15/360/60/61 정확한 표시·AX 값·후보 선택 해제·진행 잠금과 독립 왼쪽 드래그 방향을 확인했다. small21 시간/승차2건은 접근성 크기의 보이는 ± 버튼을 실제 탭하는 후속 입력 경로로 pass했다. helper는 버튼마다 정확한1분 증감·Slider 값을 assertion하며 모델 값을 직접 주입하지 않는다.

**Limit:** native AX 요소가 존재하고 값이 맞는다는 것과 실제 VoiceOver 조절 성공은 다르다. 일반 크기 synthetic Slider scrubber 조절은 좌표(0,0) 때문에 실패해 실제 drag로 교정했으며 이를 native AX 조절 성공으로 기록하지 않는다. 접근성 ± 버튼 pass도 VoiceOver Slider increment/decrement 검증을 대체하지 않는다. 별도 MinuteRulerValue 단위 seam은 통제된 계획 변경으로 구현하지 않았으므로 존재하지 않는 unit pass를 쓰지 않는다.

## AC3 — 준비·승하차·발급의 초안·저장·이탈·피드백 보존

**Source:** PreparationView/CardIssuanceView/CardTagScreen/BoardingPassView의 표현 변경이며 준비 draft, controller 저장/중복 방지·이탈 취소, .bus 기본값과 기존 발급 Reduce Motion 햅틱 예외는 바꾸지 않았다. 편집·키보드에서는 실제 지도를 숨겨 출처를 덮은 지도 일부를 노출하지 않는다.

**Actual capture:** 01/02/08–13/19. after22의08 준비 출처 가독성과09/10/11 지도 숨김, 검정 LCD/접촉 영역·카드·CTA 구성을 직접 확인했다. 기준의 데모 수치·노선·소리 없음 선택을 실제 초기 .bus로 치환하지 않는다.

**Focused runtime:** after17 U11은 최대 글자 승차 태그→출발 안내 시작까지 pass. small21 U11 후속 pass. collector의 발급·검색·준비·승하차 장면은 진입/캡처 근거이며, 모든 실패·취소 저장 횟수 검증을 뜻하지 않는다.

**Limit:** controller 불변에 대한 정적 근거와 실제 전체 회귀 검사를 구분한다. 태그/소리 편집 취소·미리듣기 정리·연타·발급 실패·복구의 실행 결과는 전체 로그에 귀속하며 전체 결과는UI319/2실패다. 실패 명단과 영향 후속은AC6를 따른다. 물리 햅틱의 강도·질감·연출 동기와 청취 체감은 미검증이다.

## AC4 — 집중·정지·도착·요약의 지도/HUD/실데이터/저장

**Source:** JourneyTimerView/JourneyView/ArrivalBriefingView는 기존 timer/controller 수명을 보존하고 shade/HUD만 바꾼다. MapKit 전체 blur/brightness를 제거하고 native 법적 표기 주변 음영을 조정했다. AlightingSummaryView는 본문 scroll·별도 safeAreaInset CTA와 기존 메모 draft·finish 저장 경계를 유지한다.

**Actual capture:** 14–20. after22의15/16에서 safe-area 밝은 띠와 음영 경계가 사라지고 실제 지도 출처가 읽히는 것을 journey 보고서가 직접 확인했다. 17의 진행 카드 중첩,20의 진단 사각형은 해소됐다. **14/18은 해당 상태 전용 원본 JPEG가 없으므로 검정 그라데이션·중앙 안내/CTA의 구조 검토**이며 정확한 모션·타이밍 일치 판정이 아니다.

**Focused runtime:** after17 요약 AC20 실패 후 입력 보존/재시도→메인과 AC5/10/15/17 하차 완료·메모·기록1건 경로2건 pass. 이전 fixedSize/키보드 가림 실패는 이 후속 성공과 구분해 보존한다. collector의 출발/지도/정지/도착 화면은 실제 이미지 근거다.

**Limit:** 전체 회귀는unit1426/0실패·UI319/2실패로 종료됐고 실패 명단은AC6와 같다. 이 수치를 미검사 실기기·모든 수동 조합 완료로 확대하지 않는다. 영상 없는 정적 캡처로 전환 타이밍·모션·햅틱 일치를 확정하지 않는다. native 출처 수용도 캡처된 상태에 한한다.

## AC5 — 기록·분석·프로필·꾸미기와 저장 초안

**Source:** RecordsView/RecordsAnalyticsView/ProfileView/CardCustomizationView/RecordMemoEditor는 현행 기록·분석 adapter/browser·필터와 저장 action을 사용한다. 전체 연도 개요와 접근성14pt 가로 격자, 프로필 점묘 대비는 표시 변경이다. 사진/메모/취소·저장 controller와 집계 계산은 변경 목록에 없다.

**Actual capture:** 21–26/32/33과 records 시각 보고서. **24/32/33은 정확한 scroll state 원본 JPEG가 없어 W09b 확장 보존·정보 위계 구조 검토**다. 23 이미지를 정확 상태 기준으로 대체해 pixel-match라 부르지 않는다. 22 unfocused 메모 캡처로 포커스 stroke를 검증했다고 하지 않는다.

**Focused runtime:** after17 collector는 기록/분석·프로필/꾸미기 실제 화면 수집 경로를 통과했다. small20 Profile AC20은 실제 양방향 저속 스크롤로 주요 요소가 nav/window 경계 안에 완전히 들어오는 assertion을 유지한 상태에서 pass했다. 이 프로필1건 성공을 small20 전체3건 성공으로 표기하지 않는다.

**Runtime update:** 전체 실행에서 분석 메모→편집 AC5가 실패했다. recordButton label에contentShape1행을 추가한 뒤 RecordsAnalytics5건이 모두 통과했으며 AC5는35.141초 PASS다. 직접 기록 메모 편집의200자/실패유지는 첫 전체에서54.034초 PASS였다. **Limit:** 날짜/태그/기간·사진 등 결과는 전체 로그와 실제 해당 검사로 한정한다. collector 수집과 시각 pass는 그 대체물이 아니다.

## AC6 — 통합·focused 이후 첫 전체 검증 및 실제 비교

**Source/process:** root 단일 큐의 첫 전체 실행은1회 종료했고 실패2건을 수정한 뒤 영향 있는 두 test파일7건만 재실행했다. 이 문서 작성자는 추가 실행을 시작하지 않았다.

**Actual capture:** after22의05–16/12건+after17의나머지21건 composite33, 유효 원본JPEG21개와 상태별 제한은 visual-comparison/관찰 메타데이터/네 최종 JSON을 따른다. 잘못 분류된reference04는 제외했다.

| 실행 | 실제 결과 | 출처 |
|---|---|---|
| 첫 전체 iOS (1회) | unit1426/0실패, UI319/2실패, TEST FAILED, exit65,5931.415초 | [로그](ios-full.log), [exit](ios-full-exit.json), [source manifest](ios-full-source-manifest.json) |
| 수정 후 영향23 | RecordsAnalytics5+SimulatorLargeTextRecovery2=7/7 PASS, TEST SUCCEEDED, exit0,245.476초 | [로그](ios-affected-23.log), [exit](ios-affected-23-exit.json), [manifest](ios-affected-23-source-manifest.json) |
| 별도 최종 Debug Simulator 빌드 | BUILD SUCCEEDED, exit0,4.065초 | [로그](ios-build-final.log), [exit](ios-build-final-exit.json) |

첫 전체의 실패는 RecordsAnalytics AC5 메모 편집 진입과 SimulatorLargeTextRecovery AC32 최대 글자 후보 도달이다. production recordButton label의contentShape1행과 해당 recovery test의실제 후보 도달 보조만 수정했다. 원래 저장/최신메모/선택값/진행 assertion을 완화하지 않았다. 두 manifest를 직접 비교해 전체 이후 변경 파일이 정확히 이2개임을 확인했다.

**판정:** 정해진 전체1회→실패 수정→영향 범위 재실행 절차는 완료됐다. 이는 수정 후 전체1745건이 같은 실행에서 통과했다는 의미가 아니다. source 표시/동작 수정의 실제 후속 증거와 실기기·OS 미검증 게이트를 구분한다.

## AC7 — native Widget/Island·데이터 출처·설정 보존

**Source:** Shared/Widget, 위젯 payload/URL 안전 진입·controller 변경 없음. root는 기존 위젯 진입/편집 중 차단을 유지한다. DataSourceView는 기존 실제 법적 내용·URL을 유지하고 Settings는 기존 placeholder이며 새 기능을 만들지 않는다.

**Actual capture:** 27/28/31은 현행 내용/placeholder와 가독성 검토다. 대응 원본 JPEG가 없으므로 정확 시안 일치 점수를 발명하지 않는다. native40–43 preview는 이번 앱33건 범위 밖이며 OS 실제 표시의 증거가 아니다.

**Focused runtime:** after17의 dataSource/settings/realBundled collector 경로는 실제 앱 화면 수집 근거다. 위젯/Live Activity의 OS 런타임·잠금 화면/Island 표시·갱신을 실행한 증거로 사용하지 않는다.

**Limit:** 실제 OS Widget/Island 표시·갱신, 실기기 VoiceOver와 햅틱은 미검증이다. 기존 계약의 정적 보존과 실제 OS 검증을 구분한다.

## 보고서 우선순위와 남은 판단

[security-review.md](security-review.md)는 **과거 소스 스냅샷**의 정적 보안 검토다. 특히 “helper가 실제 accessibility Slider 조절을 사용한다”는 설명과 당시 line 번호는 현재 helper를 설명하지 않는다. 최신 helper/입력·접근성 증거는 [review-final.md](review-final.md)와 본 원장이 우선하며, 일반 drag·접근성 ± 버튼·AX 노출/값을 실제 VoiceOver 조절 성공으로 바꾸어 보고하지 않는다. 과거 보안 finding 없음은 그대로 별도 검토 이력이다.

새로운 심각한 계약 누락은 확인하지 못했다. 첫 전체 종료·영향7건 후속·별도 빌드의 실제 결과는AC6에 확정 기록했다. 실기기/OS·원본 미수집 상태의 제한은 유지하며 자동 완료 처리하지 않는다.

후속23은재캡처가아니며33개이미지의17+22출처를유지한다. root가확인한실패attachment전용manifest는빈배열이라실패이미지확보를주장하지않는다. 정리완료수치와빌드확정은[verification.md](verification.md)를따른다.

Python문법빌드후속확인은 [python-build-final-exit.json](python-build-final-exit.json)의exit0/0.055초로확정했다. quiet출력자체를증거로간주하지않으며전체테스트재실행과구분한다.

## 마지막 양끝 후보 보완24 — AC1/AC2 소프트웨어 도달 공백 해소

기존 전체/SE21은2014첫후보진입을확인했지만양끝후보각각의실제탭증거는별도필요했다. root가새 `DesignSyncRulerUITests.testLargestTextCanSelectFirstAndLastCandidateAndProceed`를추가해SE3/accessibility5에서1/1 PASS했다. cardOnly성수120분3후보의첫2014/마지막421실제탭·배타선택·고정CTA·준비값120/421을검사했다. [보완24로그](ios-boundary-24.log)/[exit](ios-boundary-24-exit.json):exit0,231.091초(test198.577초).

보완후 [별도빌드24](ios-build-24.log)/[exit](ios-build-24-exit.json)도BUILD SUCCEEDED/exit0/4.557초다. 위AC6의첫전체unit1426/0·UI319/2실패와영향23의7/7 PASS는그대로보존한다. 추가24의1건을같은8건실행으로합치지않고새전체도실행하지않았다. Simulator범위완료이며실기기VoiceOver/햅틱/OSWidgetIsland/정확모션기준부재의한계는유지한다. source delta두파일이라는이전설명은전체→영향23구간이고,이번24는rulercoverage test추가다.
