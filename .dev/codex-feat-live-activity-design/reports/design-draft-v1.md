# 설계 초안: W17 Live Activity 디자인·집중 시간 눈금

## 설계 규모
중형. 공유 ContentState 총 시간·순수 표시 계약과 네 시스템 표면을 변경한다. 사용자 승인 전 초안이다.

## 요구사항 및 수용 기준
승인 PRD(prd.md) 전체의 R1~R3, BR1~6, QE1~2, AC1~5가 계약이다. 타이머·저장 권위·백그라운드 시간 진행·정상 완료 immediate 종료를 유지한다. UI 표현은 자동 단위 검증과 별도 시각 대조로 구분한다.

## 변경 범위와 컨벤션
수정: ios/Shared/JourneyActivityAttributes.swift, JourneyActivityDisplay.swift; ios/FocusMate/JourneyLiveActivityPolicy.swift, JourneyLiveActivitySync.swift; ios/FocusMateWidgets/JourneyLiveActivityWidget.swift.
테스트: JourneyActivityDisplayTests, JourneyLiveActivityPolicyTests, JourneyLiveActivitySyncTests, 필요 시 CleanupTests. 신규 JourneyActivityPresentationTests.swift, DEBUG JourneyLiveActivityPreviews.swift.
Swift5/iOS17, Foundation 순수 enum 함수와 Equatable 값, @MainActor 동기화, XCTest/고정 Date/ManualJourneyClock/RecordingLiveActivityGateway 관례를 따른다. 기존 timer/gateway/view/앱 저장스키마/홈위젯은 변경하지 않는다. 동기화 폴더로 새 파일 자동 포함 예상.

## 상세 설계

### 공유 상태와 호환
ContentState에 totalSeconds:Int? 추가. init(status:endDate:pausedRemainingSeconds:totalSeconds:Int?=nil). immutable attributes에 넣지 않아 기존 활동 재사용 update로 보강한다. 기존3필드 JSON 누락/null은 nil로 읽는다. nil일 때 시간·상태 유지, 눈금/버스 생략. 새 앱 저장 migration/활동재생성 없음. 기존 7필드 JSON제한 테스트는 승인된8필드로 갱신하고 태그·할일·카드 미포함 유지.

### 정책·동기화
request(status:JourneyTimerController.Status,remainingSeconds:Int,now:Date,totalSeconds:Int?=nil)->JourneyActivityRequest?; pausedRequest(remainingSeconds:Int,totalSeconds:Int?=nil)->JourneyActivityRequest.
Sync는 journey.totalSeconds를 보관·전달. launchPlan paused 갱신도 total 전달. running endDate=now+remaining, staleDate=endDate; paused end/stale=nil·고정잔여; arrived는nil요청→기존종료. SentKey/observer빈도 유지, 같은 세션 total불변. resume는 새 endDate로 정지 경과 제외. 거절재시도없음·같은여정하나재사용·다른활동종료 보존.

### 순수 표시 인터페이스
JourneyActivitySurface:Equatable = expanded/lockScreen/compact/minimal.
JourneyActivityPresentation:Equatable 필드 sampledAt:Date,status:JourneyActivityStatus,remainingSeconds:Int?,fullTimeText:String,compactTimeText:String,progress:Double?,progressInterval:ClosedRange<Date>?,statusSymbol:String,showsRuler:Bool.
presentation(state:JourneyActivityAttributes.ContentState,isStale:Bool,now:Date,surface:JourneyActivitySurface)->JourneyActivityPresentation.
compactTime(seconds:Int)->String.
호출자가 now한번채취, 내부시계/sleep없이 테스트. paused우선, remaining=max(0,pausedRemaining??0). stale running/arrived는 arrived/잔여0/도착했어요/눈금생략. endDate없는 running도기존만료문구와일관되게arrived.
running잔여=max(0,Int(ceil(endDate-now))); 소수초/정수경계검증. full M:SS는기존 pausedTime. 실제running countdown은기존timeContent 유지.
total>0만progress=min(1,max(0,1-Double(remaining)/Double(total))). showsRuler는expanded이며running/paused·progress존재. running progressInterval=(endDate-total)...endDate, paused nil. resume때interval시작도이동.
statusSymbol running bus.side.fill/paused pause.fill/arrived checkmark; SDKglyph실존 별도확인.

### Compact 장시간 초안 규칙과 위험
<6000초 M:SS. >=6000초는잔여초를분으로올림, 시간분분해. 나머지분0이면 Hh, 아니면 HhMM(분2자리).
예:5999→99:59,6000→1h40,7200→2h,7201/7260→2h01,21600→6h,7199→2h.
임의HhMM은관찰시각snapshot이며 archived뷰에서 매분재평가/100분임계전환을보장못함. full은nativecountdown 유지. >=100분compact가재렌더전snapshot유지하는한계를검증기록에명시. 이한계는정확한남은시간UX에영향하므로비판검토대상이며확정안아님. 매초/매분ActivityKitupdate추가안함.

### UI 표면과 버스 갱신 한계
확장leading노선/trailing fullcountdown/bottom가로눈금·측면버스·목적지·단일상태, 중앙카메라overlay없음. 눈금은집중시간정규화이며정류장/거리숫자없음. 버스반폭inset으로잘림방지, 샘플progress위치.
running native ProgressView(timerInterval:countsDown:false) 기본.linear의자동진행채움 후보(공식지원과실제장치검증구분). 날짜progresscustomstyle미지원, fractionCompleted=nil이므로customstyle로버스위치추출금지. 버스는ActivityKit콘텐츠갱신/실제재렌더시표본이고연속이동안함. native진행채움과버스가달라질수있는한계를명시. Timer/TimelineView/장시간애니메이션추가금지.
paused는고정채움/위치/시간. stale는도착상태·문구로대체하고오래된버스생략. 잠금은노선/목적지/시간/상태,눈금없음. compact leading상태심볼/trailing짧은시간또는도착표현. minimal심볼만.
차콜·오프화이트·단일pause·반복앱아이콘/곡선없음. 동작줄이기와무관하게정보동일, 신규이동애니메이션없음.

### 접근성 계약
JourneyActivityAccessibility:Equatable 필드 summary:String,time:JourneyActivityTimeContent?,hidesVisualTime:Bool.
accessibility(attributes:JourneyActivityAttributes,presentation:JourneyActivityPresentation,surface:JourneyActivitySurface,timeContent:JourneyActivityTimeContent)->JourneyActivityAccessibility.
expanded/lock/compact running summary는전체노선/종류/목적지/상태한번,별도time요소잔여한번.
compact장시간HhMM은숨기고전체M분S초snapshot을접근성에제공(실시간갱신제약검토대상).
paused summary에전체이름/상태/고정시간,visible시간은accessibilityHidden. arrived summary에전체이름/도착,visible도착문구숨김·잔여낭독없음.
minimal 심볼단일요소summary에전체이름/상태/running또는paused표본시간. 눈금/장식버스/중복상태숨김. expanded지역간낭독순서는실제VoiceOver별도확인. 기존helper계약유지.

## 의존성 및 영향도
외부의존성없음. Foundation/SwiftUI/ActivityKit/WidgetKit. 기존활동JSON·재사용·launchcleanup총시간보강회귀. nativeAPI존재/시스템렌더링/실제낭독은순수함수테스트와다른증거.

## 구현 순서 / 격리 RED 인계
T1 AC1 total전달·고정Date진행/시간·확장연결·60초추가갱신없음 (선행없음).
T2 AC2 paused/resume·stalepaused·위치/심볼 (T1이후).
T3 AC3 legacyJSON·invalidtotal/clamp·cleanup/reuse/immediate (T2이후).
T4 AC4 surface포맷·compact/minimal·전체이름·preview (T3이후).
T5 AC5 접근성단일소유권·reduceMotion·증거기록 (T4이후).
각태스크 RED→GREEN→REFACTOR,같은프로덕션파일이라순차. RED는production열람없이위인터페이스사용.
고정now=Date(timeIntervalSince1970:1791882000), total1800,end=now+1122또는135. 예상값literal비율0.3766667/0.925,60초뒤1062·0.41;pause300초뒤유지. 오차0.000001. nil/0/-1total,1900/-5remaining,stale running/paused,missingend,legacyJSON누락/null 포함.
기존 Sync Rig에minutes:Int=60인자추가해30분fixture, 수동시계/gatewaycallcount사용. 생산포맷함수로expected만들지않음. glyph/font/레이아웃은스타일assert금지,캡처대조.
명령: python3 scripts/check-ios.py test {files}. 빌드/테스트한번에하나.

## 준수 규격 근거
- https://developer.apple.com/documentation/swiftui/progressview/init(timerinterval:countsdown:) — 날짜기반customstyle미지원
- https://developer.apple.com/documentation/swiftui/progressviewstyleconfiguration/fractioncompleted — 날짜기반nil
- https://developer.apple.com/documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:) — native자동시간과최대폭
- https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities — 갱신애니메이션/Always-On제약

## 탐색 추가 항목
Gateway.swift:37 immediate종료; JourneyTimerController.swift:199 observer; SyncTests.swift:9 manualRig; DisplayTests.swift:77 기존JSON필드제한; pbxproj:34 동기화폴더,:72 iOS17.

## 확인이 필요한 사항
기술초안. 긴시간compact snapshot과자동native표시의일치문제, 날짜진행/버스위치불일치가검토대상이다. nativeAPI/장치검증·glyph/카메라여백·실제VoiceOver증거미확보. 설계비판과testability평가후사용자승인필요.
