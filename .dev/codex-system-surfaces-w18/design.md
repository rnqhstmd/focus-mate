# W18 설계 초안

중형. W09b 이후 구현. PRD AC1~7, 원본/타이머 권위 유지. Foundation 값과 closure DI, 구체 저장소/publisher만 추가(프로토콜계층 증식 없음). Shared는 앱저장타입참조없음. DTO Codable/Equatable 및 멤버별 internal initializer. 테스트는 선언+notImplemented throw에 실행 assertion RED 관측후 GREEN. 전체검증W18뒤.

## T1 공용계약·저장·링크·표시
Shared 신규 WidgetSnapshot.swift, WidgetSnapshotStore.swift, WidgetLink.swift, WidgetPresentation.swift. 각각 XCTest 4파일. T2/T3와생산·테스트파일비중복.
- WidgetJourneyPhase:String: setup,ready,awaitingDeparture,running,paused,arrived
- WidgetJourney: phase:WidgetJourneyPhase,journeyID:String?,busNumber:String?,destination:String?,totalSeconds:Int?,elapsedSeconds:Int?
- WidgetDay: day:String,minutes:Int,count:Int
- WidgetTag: id:AnalyticsTagID,name:String,color:String,minutes:Int,count:Int
- WidgetAnalytics: today:WidgetDay,weekStart:String,weekEnd:String,weekMinutes:Int,weekCount:Int,days:[WidgetDay],tags:[WidgetTag]
- WidgetSnapshot: version:Int,generatedAt:Date,basisDay:String,timeZoneID:String,journey:WidgetJourney,analytics:WidgetAnalytics
- WidgetDecodedState:Equatable: valid(WidgetSnapshot),malformed,unsupportedVersion(Int)
- WidgetReadState:Equatable: unavailable,malformed,unsupportedVersion(Int),stale(WidgetSnapshot),validEmpty(WidgetSnapshot),valid(WidgetSnapshot)
- WidgetDataIssue:Error: invalidSnapshot,containerUnavailable,readFailed,writeFailed,notImplemented
- WidgetSnapshotCodec.encode(_ snapshot:WidgetSnapshot)throws->Data
- WidgetSnapshotCodec.decode(_ data:Data)->WidgetDecodedState
- WidgetFreshness.classify(_ decoded:WidgetDecodedState,now:Date,timeZone:TimeZone)->WidgetReadState
- version1;version만 먼저 읽고 미지원은unsupported, 나머지손상은malformed. 날짜연속7일(월시작)/분·횟수합/태그합/여정필드일관/시간범위 검증. 보정0금지. snapshot.generatedAt는투영시각이며진도저장/측정시각이라고설명하지않음. 진도는항상'저장된진행'정적값.
- freshness:기준일/시간대같음/generatedAt<=now/30분미만. 미래generatedAt malformed,날짜/TZ변경/30분stale. 정상주합계0이면validEmpty(여정상태독립). 오류3상태0아님.
- WidgetSnapshotStore.init(containerURL:@escaping()->URL?,readData:@escaping(URL)throws->Data={try Data(contentsOf:$0)},atomicWrite:@escaping(Data,URL)throws->Void={try $0.write(to:$1,options:.atomic)})
- store.read(now:Date,timeZone:TimeZone)->WidgetReadState; store.write(_ snapshot:WidgetSnapshot)throws
- AppGroup아래 widget-snapshot-v1.json만. Documents fallback없음. encode완료뒤atomicwrite. 목적파일먼저삭제금지/실패시이전bytes유지/실제temp파일테스트. 앱MainActor publisher단일writer,위젯읽기만.
- WidgetLinkTarget:Equatable: journey(expectedID:String?),newJourney(expectedID:String?),analytics(day:String?,tag:String?)
- WidgetLink:Equatable: issuedAt:Date,target:WidgetLinkTarget
- WidgetLinkParseResult:Equatable: valid(WidgetLink),expired,invalid
- WidgetLinkCodec.makeURL(_ link:WidgetLink)->URL?; parse(_ url:URL,now:Date)->WidgetLinkParseResult
- schemefocusmate/hostwidget/path journey,new,analytics. query v=1/issuedAt정수epoch. 발급은snapshot.generatedAt(렌더now로세탁금지). TTL24h,미래발급/duplicatequery/unknownfield/path/잘못된encoding/과도길이invalid. URLComponents,엄격day,태그remainder는전체.
- WidgetPresentation 구조/필드/entry명세는T3화면소비에필요한순수표시helper로정한다. 상태별안내/정적저장진도/기준날짜/업데이트필요. 오류는불러올수없음/0금지. 위젯내집계없음.

## T2 앱투영·게시·안전진입
신규 WidgetSnapshotPublisher.swift,WidgetNavigation.swift; 수정 AppModel/FocusMateApp/RootView/RecordsView/RecordsAnalyticsView. WidgetPublicationTests/WidgetNavigationTests/WidgetEntryUITests 소유.
- WidgetSnapshotProjection.make(snapshot:AppSnapshot,now:Date,calendar:Calendar,timeZone:TimeZone)throws->WidgetSnapshot
- 원본validate/launchRoute/recordsvalidate후여정상태. W09b현재주report하나의today/week7일/topTags만투영. report/원본record/task/memo/cardID/최근ids없음.
- @MainActor WidgetSnapshotPublisher.init(store:WidgetSnapshotStore,now:@escaping()->Date,calendar:Calendar,timeZone:@escaping()->TimeZone,reload:@escaping()->Void)
- publish(snapshot:AppSnapshot)->Bool. projection/write성공뒤만reload,실패false/원본결과에throw없음. 최소payload+기준/TZ동일이면불필요write/reload없음(단30분만료재게시). 직접ticker연결없음.
- AppModel기본publisher nil(noop)로기존테스트부작용차단,production FocusMateApp만live주입. 단일 publishWidgetSnapshotIfEligible 경계.
- persist store.save성공→snapshot/ready확정→publish. supplementCard directsave성공후도동일. load성공restored paused만게시,실패미게시. migration필요load후성공저장전eligibility보류(실패후foreground도미게시),후속persist성공복구. cleanup backupClear성공empty게시,실패이전본. retry동일. foreground ready/확정원본만날짜/TZ/신선도확인publish,원본추가저장없음.
- WidgetNavigationState:Equatable: isReady:Bool,needsSetup:Bool,activeJourneyID:String?,phase:WidgetJourneyPhase,isJourneyOpen:Bool,hasOtherOpenFlow:Bool
- WidgetNavigationDecision:Equatable: safeHome,deferUntilReady,alreadyOpen,showSetup,prepare,continueJourney,alight,confirmNewJourney,analytics(day:String,tag:String?)
- WidgetNavigationPolicy.decide(link:WidgetLinkParseResult,state:WidgetNavigationState,now:Date,calendar:Calendar,timeZone:TimeZone)->WidgetNavigationDecision
- 최신activeID UTF16일치필수(nil링크→새active도safeHome). 이미열린동일여정alreadyOpen(0저장/경로추가없음). 다른편집/승차흐름강제닫기금지/현재유지안내. setup기존launch. 없음 startTripFromMain,대기 resumeJourney기존무저장안내,진행/정지기존resumeJourney,도착beginAlighting. 새여정은RootView기존confirmation만띄우고확정전confirm메서드금지. malformed/expired안전기본/데이터변경없음. analytics날짜미래/없음/invalid오늘기본,태그최신report재검증.
- .onOpenURL pending1개,model.start/ready뒤소비. 복원실패/cleanup중보류,재시도성공최신재결정. 한 번 소비token으로중복실행방지. RootView는confirmation기존@State연결. RecordsView/AnalyticsView초기분석day/tag선택적진입값추가,기존복귀경로유지. 현재타이머재생성/옛진도덮어쓰기없음.

## T3 Provider·4조합·설정
신규 HomeWidgetProvider.swift,FocusPromptWidget.swift,AnalyticsHomeWidget.swift,HomeWidgetPreviews.swift; 수정WidgetBundle/project.pbxproj. 앱/확장각entitlements,앱Info.plist필요시추가. 이태스크만번들/프로젝트소유.
- HomeWidgetEntry:TimelineEntry: date:Date,state:WidgetReadState
- 한HomeWidgetProvider 두계열공용. now와다음자정/30분만료중빠른경계entry. 같은snapshot미래시각classify만하고재집계없음. .after(boundary). 이미stale은완만한재요청(최소15분)으로즉시루프금지. preview데이터는실제오류fallback금지.
- kind FocusMate.FocusPrompt,FocusMate.Analytics; supportedFamilies small/medium만.
- 집중유도상태안내/노선목적지/저장진행/앱열기. 분석small오늘/주요약,medium요약+7일+상위태그. smallwidgetURL/mediumLink영역지원. AppIntent직접제어없음.
- 차콜/오프화이트,긴이름줄바꿈/핵심수치우선,날짜/태그/분/횟수AX,stale기준일+업데이트필요,ReduceMotion정보동일.
- AppGroup group.app.focusmate.prototype 양타깃,URLschemefocusmate 앱등록. DEVELOPMENT_TEAM비어있음,서명/실기기capability 성공추정금지.

## 검증
Store실제임시파일/실패closure,Publisher기록reload/원본성공분리,날짜/TTL고정. persist/supplement/load/migration실패/cleanup/retry/foreground,save실패0게시,share실패원본성공,7일/태그합/자정stale/ID mismatch/이미열림0저장/confirmation취소0저장. 미리보기/갤러리/서명/실기기/VO결과또는미확보사유구분. 실제기기미확보를pure PASS로바꾸지않음.

## v2 확정 보완 (v1과 충돌하면 이 절 우선)
- 직접제어 금지 유지: 링크처리에서 resumeJourney 호출금지. running/paused는메인기존카드확인만(showActiveJourney,저장0/resumetoken0). 사용자가기존이어가기버튼을눌러서만재개. awaiting은showDeparture(openjourney무저장), arrived는beginAlighting무저장. 다른열린흐름alreadyOpen(no pop),새여정은Root기존확인만.
- WidgetNavigationDecision: safeHome,deferUntilReady,alreadyOpen,showSetup,prepare,showDeparture,showActiveJourney,alight,confirmNewJourney,analytics(day:String,tag:String?,kind:AnalyticsPeriodKind = .week).
- WidgetLinkTarget.analytics(day:String?,tag:String?,kind:AnalyticsPeriodKind = .week)으로기존2인자호출유지. codec query period=week/month(누락week). WidgetAnalyticsEntry(day:String,tag:String?,kind:AnalyticsPeriodKind = .week). 실제위젯주간맥락을앱월간으로바꾸지않도록보존.
- WidgetNavigationPolicy우선:!ready defer→열린흐름alreadyOpen→invalid/expired safeHome→needsSetup showSetup→journey/new ID UTF16검증(nil불일치포함)→phase별결정. analytics미래/누락today,tag는apply직전latest해당kind report검증.
- AppModel.init 마지막 widgetPublisher:WidgetSnapshotPublisher?=nil. refreshWidgetSnapshotIfEligible() 공개내부,productionsceneactive호출. 모든success경계같은함수. migrationeligibility false는후속성공persist/검증restore까지유지.
- AppModel.handleWidgetURL(_ url:URL)->WidgetNavigationDecision,consumePendingWidgetURL()->WidgetNavigationDecision?,setWidgetEntryBlocked(_ blocked:Bool). pending은rawURL1개. ready이전보류,실제consume시현재시각parseTTL재검증/최신state결정/적용전URL삭제. 중복consume nil. 실패/cleanup보류. blocked는모달/confirmation메모리입력(저장없음).
- apply:safeHome/showSetup/showActiveJourney/alreadyOpen/defer는저장/경로변경없음;prepare는기존startTripFromMain;departure는awaiting재확인후openjourney;alight는기존beginAlighting;newconfirm은반환만. Root가alert띄우고확인사용자행동만기존confirmNewJourney호출.
- AppModel private(set) widgetAnalyticsEntry:WidgetAnalyticsEntry?, consumeWidgetAnalyticsEntry()->WidgetAnalyticsEntry?. apply analytics는최신records전체검증/해당kind집계후없는tag해제,실패시기본records만. RecordsView entry한번소비후분석열기. AnalyticsView initialTag:String?=nil/initialKind:AnalyticsPeriodKind?=nil 추가(앱일반진입기존월유지),최신report와reconcile.
- WidgetDisplayContent:Equatable(title:String,subtitle:String,actionTitle:String,basisText:String,axSummary:String,snapshot:WidgetSnapshot?,isStale:Bool,progress:Double?). WidgetPresentation.content(state:WidgetReadState)->WidgetDisplayContent.
- 오류3상태 title='정보를 불러올 수 없어요'/action='앱 열기'/subtitle,basisText빈문자/snapshot,progressnil/isStalefalse. valid/validEmpty snapshot유지fresh. stale snapshot유지/isStaletrue/basisText='기준일 YYYY-MM-DD · 업데이트 필요'. fresh='기준일 YYYY-MM-DD · 저장된 정보'.
- title/action setup='설정을 마쳐주세요'/'설정 확인', ready='집중할 시간을 골라보세요'/'앱에서 준비',awaiting='출발을 기다리고 있어요'/'출발 안내',running='진행 중인 여정이 있어요'/'여정 확인',paused='잠시 쉬고 있어요'/'여정 확인',arrived='목적지에 도착했어요'/'하차 안내'. subtitle저장노선/목적지,없는필드생략. progress유효total/elapsed의clamp분수,시계추정없음. validEmpty도journey보존. axSummary상태/전체노선·목적지/저장기준/분석오늘·주분·횟수각1회.
- WidgetPresentation.nextRefreshDate(state:WidgetReadState,now:Date,timeZone:TimeZone)->Date. localGregorian다음자정, valid/empty는min(generatedAt+1800,nextmidnight),이미만료/stale/오류는min(now+900,nextmidnight),반드시now뒤/날짜실패now+900. Provider두entry는같은snapshotclassify만/진도보간·집계없음.

## 검토 결과
v2 design-critic MUST2 모두ADDRESSED/새MUST0. test-architect9/10 PASS. API미정/자동재개/consumeTTL/열린흐름/period보존 모두해소. WidgetDataIssue는 Error,Equatable로선언하여오류계약검증가능. 추가질문없음. 실제기기·갤러리·VO는후속별도증거.

### T2 clock 구체화
AppModel 링크 수신/consume 시각은 기존 recordClock.now(), 시간대는 recordClock.timeZone(), Gregorian calendar를 사용한다. 새 clock init 인자 없이 기존 테스트 DI를 유지한다.

### T3 검증 seam 확정
Shared WidgetTimelineValue(date:Date,state:WidgetReadState),WidgetTimelinePlan.entries(state,now,timeZone)로 provider의 실제 소비 계획을 순수 검증한다. 현재/다음2entry,동일snapshot미래classify만. WidgetEntryLinks.focus(state),analytics(state,day:nil,tag:nil)는 원본generatedAt 발급/주간맥락/named태그만/오류safehome을 생성하고 실제View가 소비한다. UI 스타일은 강제 단위테스트 없이 빌드·실제 렌더 대조로 확인한다.

### T3 큰 글자 렌더 보완
실제accessibility3host넘침증거에따라focuscompact배치(상태/진행/행동/기준우선,small긴노선visual생략·AX전체보존),analytics는고정위젯영역의제어된글자배치와medium횟수제목통합을사용한다. 모든분석태그/7일값/링크/AX값유지.
