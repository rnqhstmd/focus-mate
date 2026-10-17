# W09b 설계 (architect 초안)

규모 중형. PRD7AC를 따르며 원본저장/타이머/기존메모정책을 변경하지 않는다. Shared는 Foundation만 사용하며 앱 RecordSnapshot/RecordDay를 참조하지 않는다. 문서 기반 최소 선언(scaffold)은 미구현 오류만 던지고, assertion RED 관측 후 동작을 구현한다. 전체test/build는 사용자지시W18뒤.

## T1 공용 계산 (AC1~4)
신규 ios/Shared/RecordsAnalyticsTypes.swift, RecordsAnalytics.swift 및 ios/FocusMateTests/RecordsAnalyticsTests.swift.
별도표기없는 DTO는 Codable,Equatable,멤버별 internal initializer:
- AnalyticsPeriodKind:String: week,month
- AnalyticsPeriod: kind:AnalyticsPeriodKind,startDay:String,endDay:String
- AnalyticsRecordInput: id:String,day:String,completedAt:Date,minutes:Int,tag:String,tagColor:String,bus:String,from:String,to:String
- AnalyticsTotals: minutes:Int,count:Int,activeDays:Int,averageMinutes:Int
- AnalyticsTagID: Codable,Equatable,Hashable: named(String),remainder
- AnalyticsTagTotal: id:AnalyticsTagID,name:String,color:String,minutes:Int,count:Int,share:Double
- AnalyticsDayTotal: day:String,minutes:Int,count:Int,isFuture:Bool,tags:[AnalyticsTagTotal]
- AnalyticsComparison: previousStartDay:String?,previousEndDay:String?,currentMinutes:Int,previousMinutes:Int,deltaMinutes:Int,changePercent:Double?
- AnalyticsTimeBand:String: dawn,morning,afternoon,evening
- AnalyticsTimeBandTotal: band:AnalyticsTimeBand,minutes:Int,count:Int
- AnalyticsLengthBand:String: upTo30,from31To60,from61To120,from121To240,from241To360
- AnalyticsLengthTotal: band:AnalyticsLengthBand,minutes:Int,count:Int
- AnalyticsRouteTotal: bus:String,from:String,to:String,minutes:Int,count:Int
- AnalyticsInsights: timeBands:[AnalyticsTimeBandTotal],needsMoreTimeBandRecords:Bool,routes:[AnalyticsRouteTotal],lengths:[AnalyticsLengthTotal],longestStreak:Int
- RecordsAnalyticsReport: period:AnalyticsPeriod,today:String,totals:AnalyticsTotals,days:[AnalyticsDayTotal],tags:[AnalyticsTagTotal],topTags:[AnalyticsTagTotal],comparison:AnalyticsComparison
- RecordsAnalyticsComputation: Equatable: report:RecordsAnalyticsReport,effectiveTag:String?,filteredDays:[AnalyticsDayTotal],scopedRecordIDs:[String],insights:AnalyticsInsights
- AnalyticsIssue:Error,Equatable: invalidCalendar,invalidDay(String),invalidPeriod,invalidInput,arithmeticOverflow,notImplemented

RecordsAnalytics static API:
```
period(kind: AnalyticsPeriodKind, containing day: String, calendar: Calendar) throws -> AnalyticsPeriod
today(now: Date, calendar: Calendar, timeZone: TimeZone) throws -> String
shift(period: AnalyticsPeriod, by offset: Int, today: String, calendar: Calendar) throws -> AnalyticsPeriod?
compute(records: [AnalyticsRecordInput], period: AnalyticsPeriod, selectedTag: String?, now: Date, calendar: Calendar, timeZone: TimeZone) throws -> RecordsAnalyticsComputation
```
- Gregorian만 허용. 엄격YYYY-MM-DD, date-onlyUTC산술/DST분리, 주월요일~일요일. shift 월시작/주시작 기준, 미래시작/표현범위밖 nil.
- 전체입력중복ID(UTF16)/날짜/분/시각 방어검증, 손상항목 skip금지. 합산overflow오류. 적격은day<=today 및completedAt<=now, 저장day재분류없음.
- 기간전체 totals/tags/comparison/longestStreak. days는빈/미래포함 주7/월실제일수. 평균반올림.
- tags 분↓/횟수↓/이름↑. 대표색 최신완료(동률입력앞), share분/전체분. topTags상위3+남을때remainder(중립#BFC6C1), 실제기타이름과ID구분. 합보존.
- selectedTag없으면effectiveTag=nil. filteredDays/scopedRecordIDs/timeband/routes/lengths만 필터. ID최신순,동률입력순.
- 현재기간 오늘까지와이전같은경과일수(말일제한),과거기간이전전체. previous0이면percentnil,delta는유지.
- 시간대4버킷00/05/12/18경계,3회미만안내. 노선구조화(bus/from/to)키·횟수↓/분↓/3문자열↑ 상위3. 길이5버킷1~30/31~60/61~120/121~240/241~360 전부반환. 연속일기간전체서로다른day.
- report에는 recordID/task/memo가없으며W18은최소필드투영만직렬화. app전용scopedIDs/insights는report밖.

## T2 앱 연결 (AC5/6,기간·태그)
신규 RecordsAnalyticsAdapter.swift, RecordsAnalyticsBrowser.swift 및 각각 XCTest. T1과파일비중복.
- RecordsAnalyticsLoad:Equatable: available(RecordsAnalyticsContent),unavailable
- RecordsAnalyticsContent:Equatable: computation:RecordsAnalyticsComputation,recent:[RecordSnapshot],memoCount:Int,recentMemos:[RecordSnapshot],hasAnyEligibleRecords:Bool. Codable금지.
- RecordsAnalyticsAdapter.load(section:RecordSection?,period:AnalyticsPeriod,selectedTag:String?,now:Date,calendar:Calendar,timeZone:TimeZone)->RecordsAnalyticsLoad
- RecordsAnalyticsAdapter.validatedContent(section:RecordSection,period:AnalyticsPeriod,selectedTag:String?,now:Date,calendar:Calendar,timeZone:TimeZone)throws->RecordsAnalyticsContent
- nil section unavailable/emptyavailable0. whole section.validate먼저,타입변환실패/집계오류전체unavailable. ID utf16비교로원본매칭,최근5/메모수/최근메모3. hasAnyEligible는기간외포함적격존재. 저장호출없음.
- RecordsAnalyticsBrowser:Equatable, private(set) period:AnalyticsPeriod,selectedTag:String? 및 기준일anchorDay:String.
- init(selectedDay:String,calendar:Calendar)throws: 해당월+anchorDay보존
- mutating setKind(_:AnalyticsPeriodKind,calendar:Calendar)throws
- mutating move(by:Int,today:String,calendar:Calendar)throws->Bool
- mutating returnToToday(today:String,calendar:Calendar)throws
- mutating selectTag(_ name:String?,available:[AnalyticsTagTotal])
- mutating reconcileTags(available:[AnalyticsTagTotal])
- 종류전환은 period.startDay가아닌 anchorDay 기준(10-14 월→주는10-12~18). period이동은candidate시작으로anchor갱신,오늘복귀는today. 전환/이동/오늘은태그해제,거절은상태전체유지,같은태그재선택해제/없는태그해제.

## T3 화면 (AC7 및AC1~5UI)
신규 RecordsAnalyticsView.swift, 수정 RecordsView.swift, 신규 UI RecordsAnalyticsUITests.swift. 기존AppModel/Destination/저장형식변경없음.
- RecordsAnalyticsView(model:AppModel,selectedDay:String,onOpenRecord:(String)->Void).
- RecordsView내 navigationDestination(isPresented:) 분석보기로현재선택일 전달. 상단기간/오늘/전체합계·비교/전체태그/선택태그해제/일별누적/시간대/노선/길이/전체연속일/최근·메모 순.
- onOpenRecord 최신원본ID재검증→browser.select(record.date)/showMore로노출→분석닫힘→기존RecordMemoEditor시트. 부모editing소유,실패초안/경로보존. 없는ID는안내/이동안함. 재진입최신메모재집계.
- unavailable0카드금지,불러올수없음/기록복귀. foreground now/timeZone 재채취,매초timer없음.
- 다크/24pt/기존표시재사용. 날짜/태그/노선분·횟수텍스트+AX요약,색만정보없음. 큰글자수직재배치,긴이름줄바꿈. 기타는버튼아님. native뒤로가기 유지.

## 검증/RED인계
XCTest고정now/calendar/timeZone; 예상값독립literal. T1새API 선언몸체notImplemented throw에 대해테스트catch가XCTFail하는assertionRED확인후구현. 컴파일오류/프로세스trap은RED가아님. T2throwing validatedContent선언동일경로,loadwrapperGREEN연결. 기존완료저장 exclusion/memo멱등계약을복제하지않고회귀재사용.
필수예: 2026-10-16/10-14,7일[30,0,30,0,0,0,0]/60분3회2일평균20,윤년/연도/DST/미래시각,태그40/30/20/10 및동률·기타이름·최신색,시간대경계/길이경계/연속3일,중복/손상1건전체실패,메모/task report비포함. UI선택/복귀/필터/메모저장실패/큰글자focused. 스타일assert/전체snapshot없음. 실제VO/기기시각은별도미확보표시.

## 설계 평가와 보완
- design-critic: MUST-ADDRESS0, 근본 문제 없음. CONSIDER는 foreground 날짜 일치, 분석을 닫은 뒤 메모 sheet 표시, W18 최소 DTO 투영 유지.
- test-architect:9/10 PASS. 순수 값/고정 시각/실제 XCTest. 표현 레이어 스타일 assert 없음. 단일 손상도 전체 unavailable. 실제 VO는 별도 증거.
- 연도1 직전처럼 표현 범위 밖이면 previousStartDay/previousEndDay=nil, previousMinutes=0/changePercent=nil. 정상 현재 기간은 available 유지.
- T3는 최신 today로 부모 RecordsBrowser를 재구성하고 선택일을 유지(미래면today). 분석 onDisappear에서 pendingRecordID를 기존 editor로 전달하여 pop 중 sheet 동시 표시를 피한다.

## T3 검증용 시드
기존 recordsMemo 시드는 오전 실행에서 미래의 정오 완료시각을 사용한다. 이를 바꾸지 않고 analytics 전용 시드를 UITestBootstrap에 추가한다(T3 소유). 완료시각은 실제 오늘 시작 시각으로 고정하여 미래 제외 계약과 충돌하지 않게 한다. 기존 recordsMemo/recordsTwoYears 동작은 유지한다.
