# W18 집중 유도·분석 홈 위젯 PRD 초안

## 범위와 요구
승인 계획 journey FR15/NFR3·records FR8/NFR2. 집중 유도/분석 두 계열 각각 small/medium, 총4조합. W09b 공용계산을소비하고 위젯에서재계산하지않는다. 차콜/오프화이트, 풍선곡선/앱아이콘반복없음. 기존LiveActivity 유지. 구현착수는W09b완료후.

## 정책
- 앱원본/실행중타이머가권위. 공유는버전·생성시각·기준날짜 최소읽기모델. 카드ID/task/memo/완료기록원문/원본recordID목록 금지.
- 여정은초기설정/새준비/출발대기/진행/정지/도착,필요노선/목적지/저장시점진도만. 진도는실시간으로확정하지않고기준시점안내.
- 분석은W09b today/week 합계·횟수·정확히7일·태그상위+기타 최소투영. 전체report/노선insight/최근원문 공유금지. 월요일시작,완료당시date권위유지.
- 새후보는앱원본저장성공후만 publish/reload. 성공복원/자정foreground도검증된원본으로publish. 저장실패후보·읽기실패0게시금지. 공유실패는이전공유본/원본보존.
- malformed/unsupportedversion/unavailable는접근불가,stale은기준날짜와이전값+업데이트필요,validempty만0. 자정넘은자료를오늘현재값으로설명하지않음. 날짜경계timeline은상태표시갱신만,위젯집계없음. 매초reload없음/OS즉시반영보장없음.
- 링크는최신앱상태재검증. 설정필요→기존설정,없음→기존준비,대기→출발안내,진행/정지→기존이어가기,도착→기존하차. 진행중새여정은기존확인/취소보존. 이미열린여정중복진입저장시작없음.
- stale여정링크가다른여정자동재개/덮어쓰기금지. unknown/malformed→안전기본화면/데이터불변. 기간/태그없음은기본분석(미래기간차단). 직접시작/정지/재개/포기제어없음.
- 긴한글/큰글자/색외요약/ReduceMotion정보유지. 자동/미리보기/갤러리/서명/실기기/VO 증거구분. 미확보는사유기록.
- 제안group.app.focusmate.prototype,schemefocusmate는프로젝트식별자기반설정이며개발팀/프로비저닝성공을추정하지않는다.

## 수용 기준
### AC1 네조합·최소공유
Given:설정전/없음/대기/진행/정지/도착과완료기록.
When:두계열×두크기표시자료생성.
Then:4조합필요안내/수치만있고금지원문/전체report없음.
### AC2 게시·실패격리
Given:기존원본/공유본과저장성공·실패·복원성공·읽기실패.
When:게시갱신조건평가.
Then:확정원본만게시,실패후보미게시,공유쓰기실패도이전본/원본보존.
### AC3 분석일치·자정
Given:W09b주별[30,0,30,0,0,0,0],60분3회.
When:위젯/자정뒤갱신전/foreground뒤확인.
Then:동일합계/7일/태그합계,갱신전이전기준+업데이트필요,갱신뒤새기준.
### AC4 자료상태
Given:malformed/unsupported/unavailable/stale/validempty.
When:두계열표시.
Then:앞3접근불가(0아님),stale이전기준값,validempty실제0구분.
### AC5 안전진입
Given:상태변경여정링크/잘못된링크/없는태그/진행중새여정.
When:앱링크열기.
Then:최신상태/설정·이어가기·하차/새여정확인유지,중복저장/직접제어없음.
### AC6 권위·빈도
Given:앱런타임진도와마지막공유진도가다르거나비활성중읽기실패.
When:시간경과/위젯재표시.
Then:실시간진도로확정/0덮어쓰기/매초reload/위젯재계산없음.
### AC7 접근성·증거
Given:4조합긴한글/큰글자/빈/stale/unavailable.
When:미리보기/ReduceMotion/접근성기록확인.
Then:핵심정보·행동구분,실제등록/서명/진입/낭독결과또는미확보사유각각존재.

## 제외
large/lockaccessory/StandBy전용,직접타이머제어,GPS/ETA,원문공유,원본정책변경. 실제기기/출시성공주장없음.

## 근거
product-owner읽기전용사전조사. 승인계획/현재AppModel·Lifecycle·RootView·JourneySnapshot·위젯번들/W09b계약. 추가사업정책질문없음. 사용자지시전체검증은W18뒤1회,구현중focused만.
