# 설계 초안: W08 완료 기록·선택 메모 저장 모델

## 설계 규모
중형 — v2 저장 구조·앱 상태 확장. 새 화면·계층·외부 의존성 없음.

## 목적과 요구사항
승인 PRD FR-5/NFR-1, AC-1~15. 완료 당시 날짜·선택 메모 보존, 멱등성·손상 원본 보호·다른 영역 보존. W09 UI와 진행 상태 머신 제외.

## 변경 범위
수정: ios/FocusMate/RecordSection.swift, AppSnapshot.swift, SnapshotCodec.swift, AppModel.swift.
신규 테스트: ios/FocusMateTests/RecordSectionTests.swift, RecordStorageTests.swift.
LocalSnapshotStore/JourneySection/CardSection 재사용. StorageTestSupport 실제 임시 파일 헬퍼 재사용. Xcode 동기화 그룹 자동 등록.

## 컨벤션
Swift 값 타입 Codable/Equatable, let 필드, 명시적 오류 enum. AppSnapshot.updating(records:)로 records만 변경. @MainActor AppModel의 동기 저장·Bool·saveFailure 패턴. 저장 성공 뒤에만 메모리 상태 교체. XCTest 기존 testAC…/실제 파일/정확 오류·바이트 비교.

## 상세 설계
### RecordSection.swift: 공개 타입과 인터페이스
RecordSnapshot: Codable, Equatable 구조체. 저장 필드는 모두 필수, 기본 decode 값 없음.
minutes Int, 나머지 String. completedAt은 UTC ISO8601 문자열을 그대로 저장.
```swift
struct RecordSnapshot: Codable, Equatable
init(id: String, completedAt: String, date: String,
     bus: String, tag: String, tagColor: String, task: String,
     minutes: Int, sound: String, from: String, to: String, memo: String)
struct RecordCompletionInput: Equatable
init(id: String, completedAt: String,
     bus: String, tag: String, tagColor: String, task: String,
     minutes: Int, sound: String, from: String, to: String)
enum RecordCompletionOutcome: Equatable // alighted, active, abandoned
struct RecordDaySummary: Equatable // let count: Int; let minutes: Int
init(count: Int, minutes: Int)
enum RecordValidationIssue: Error, Equatable
// invalidID, invalidText(String), invalidTagColor,
// invalidCompletedAt, invalidDate, invalidMinutes(Int), memoTooLong,
// duplicateJourneyID(String), recordNotFound(String)
struct RecordSection: Codable, Equatable
init(items: [RecordSnapshot])
static let empty: RecordSection
func validate() throws
func recordingCompletion(_ input: RecordCompletionInput,
    outcome: RecordCompletionOutcome, isExample: Bool = false,
    timeZone: TimeZone) throws -> RecordSection
func updatingMemo(_ memo: String, forJourneyID id: String) throws -> RecordSection
func dailySummary(on date: String) throws -> RecordDaySummary
func sortedNewestFirst() -> RecordSection
```
RecordSnapshot/Input 생성자는 값을 그대로 담으며 검증은 validate와 변경 메서드에서 수행한다.
recordingCompletion은 기존 섹션 검증 후 실제 alighted만 추가한다. active/abandoned/예시는 원본 반환.
실제 완료 순서: ID 검증 → 기존 ID 확인 → 신규 내용 검증. 기존 ID이면 기존 내용·시각·메모 불변.
신규 memo="", 배열 뒤 추가 후 최신순. 예시 모델/저장소는 추가하지 않는다.

### 검증·메모·날짜
- ID: trim했을 때 비어있지 않고 원문 UTF16≤100. 원문 보존, ID 중복 판정은 원문 UTF16 코드 단위 동일성(utf16.elementsEqual)을 사용한다. Swift String의 정규화 동등성을 ID 판정에 사용하지 않는다.
- bus/tag/task/sound/from/to: 공백만 거부, UTF16≤500, 원문 보존.
- tagColor: # 뒤 ASCII 16진수6자리. 잘못된 저장 색상을 보정하지 않고 거부.
- minutes: Int 1...360. 타입 위반은 구조오류, 범위 위반은 내용오류.
- completedAt: UTC yyyy-MM-dd'T'HH:mm:ss'Z' 또는 yyyy-MM-dd'T'HH:mm:ss.SSS'Z'. 실제 날짜·시각만. 윤초·남는문자·자동 날짜 이월 거부.
- date: ASCII YYYY-MM-DD, Gregorian 연도0001...9999 실제 날짜. 파싱 뒤 연월일 동일성 확인, 이월 불가.
- 새 date: 주입 TimeZone과 completedAt으로 한 번 생성. Gregorian 명시, 사용자 달력 설정 무관. 생성된 로컬 날짜도 연도0001...9999 및 실제 날짜 검증을 통과해야 한다. 범위를 넘으면 invalidDate.
- 복원 date는 현재 시간대로 재계산하지 않고 completedAt과 현재 시간대로 대조하지 않는다. 집계는 저장 date 일치.
- 메모 입력: whitespacesAndNewlines trim 후 UTF16≤200인 가장 긴 Unicode scalar prefix. surrogate 경계의 scalar 전체 제외. 가199+😀→가199, 😀101→😀100. Character.count 사용 금지, 결합문자/ZWJ는 여러 UTF16단위. 비정상 surrogate 생성 금지.
- 저장 memo: UTF16≤200, 읽을 때 trim/절단 없음. 201은 전체 읽기 실패.
- 메모 변경: 같은 ID memo만 교체. 없는 ID recordNotFound(id), 잘못된 ID invalidID. 새 기록 생성 금지.
- dailySummary: 섹션 및 날짜 검증. 해당 날짜 없음은 count0/minutes0.
- 파일 중복ID: 내용 같아도 duplicateJourneyID(id)로 전체 거부. 부분 복원/자동 제거 없음.

### 정렬·오류
완료 시각을 파싱하여 내림차순. 문자열 정렬 금지. 같은 시각은 입력 배열 순서, 새 동시각은 기존 뒤. 원래 index를 tie 기준으로 안정성 보장.
sortedNewestFirst는 유효섹션 사용 계약. 신규완료/복원에 적용하며 읽기 파일 재작성 없음.
구조 오류(필드 누락/null/타입/원소 형태) → StorageIssue.corrupt.
내용 오류(ID/문자열/색상/시각/날짜/분/메모/중복) → invalidState(.invalidRecords(issue)).
SnapshotValidationIssue에 case invalidRecords(RecordValidationIssue) 추가.
unsupportedVersion/writeBlocked/notReady/writeFailed 기존 의미 유지.

### AppSnapshot·SnapshotCodec
AppSnapshot.validate 기존 단계/정류장 검증 다음 records.validate, 도메인오류 invalidRecords로 래핑.
Codec 기존 헤더→버전→구조→내용 판정순서 보존. 성공 후 state.updating(records: state.records.sortedNewestFirst()) 반환.
v1 마이그레이션 빈records, v2 빈records 및 기존 state6키 유지.
LocalSnapshotStore 후보검증→기존파일 읽기→원자적쓰기 재사용.

### AppModel 저장 진입점
```swift
@discardableResult
func recordCompletion(_ input: RecordCompletionInput,
    outcome: RecordCompletionOutcome, isExample: Bool = false,
    timeZone: TimeZone) -> Bool
@discardableResult
func saveRecordMemo(_ memo: String, forJourneyID id: String) -> Bool
```
호출자가 시각/시간대 전달. 전역 현재시각/현재시간대 의존 없음.
ready 확인: load 실패는 writeBlocked(원인), loading은 notReady.
진행/포기/예시 false·쓰기없음·saveFailure=nil. 정상저장/같은ID재요청 true.
같은 ID/같은 memo는 쓰기없이 성공, 이전 saveFailure 지움. 같은 memo 판정도 UTF16 원문 동일성을 사용한다. no-op 성공은 현재 메모리에 로드된 결과의 멱등성만 보증하며 외부 변경된 현재 파일의 정상성은 보증하지 않는다.
도메인오류 saveFailure=.invalidState(.invalidRecords(issue)).
변경후보 records만 교체하고 기존 save 호출. 실패시 snapshot/route/path/기록/메모 불변.

## 의존성과 영향
새 패키지 없음. Foundation Calendar/TimeZone/문자열/날짜 파서.
W00 CardSnapshot/JourneySnapshot은 원소 생성 불가. AC13은 현재 허용 빈cards/active:null 및 실제 정류장 값 보존을 확인한다. 비어있지 않은 카드/여정 수용은 범위 밖.
다른영역 값보존, 알수없는키 원문바이트 보존 약속 없음.
구현 전 공식 Foundation UTF16/scalar 및 날짜파서 엄격성 확인; 날짜이월은 명시적 비교검증.

## 구현 순서(각 AC별 RED→IMPLEMENT→VERIFY)
1. 순수 기록·검증·날짜·메모: AC1,4,5,6 및 잘못된값 (의존없음)
2. 완료제외·멱등성·집계·안정정렬: AC2,3,7,8,9,15 및 저장중복ID (의존1)
3. Snapshot/Codec 통합: AC11,14 및 오류우선순위 (의존2)
4. AppModel 실제저장: AC10,12,13 및 쓰기실패 보존 (의존3)
5. Unicode/동시각/실제파일·기존회귀 (의존4)

## 코드 맵 추가
AppSnapshot.swift:47 records교체/:52검증; LocalSnapshotStore.swift:32보호; AppFoundationTests.swift:259상태보존; StorageTestSupport.swift:35파일헬퍼; animation-preview.html:695완료/:709복원/:901메모; project.pbxproj:22자동파일그룹.

## 확인이 필요한 사항
추가 확인 사항 없음. 설계가 완료되었습니다. Testability/비판 검토 및 사용자 승인 대기.

## 비판 검토 반영
MUST-ADDRESS 0건. CONSIDER: Unicode 원문 동일성 명시, no-op 디스크 정상성 한계 명시, 생성 날짜 연도 경계 검증 반영.

## 공식 문서 근거
- Swift String 동등성은 canonical equivalence, 원문보존 검증은 utf16/utf8 비교: https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html
- Apple String encoding views: https://developer.apple.com/documentation/swift/string
- DateFormatter strict형식·locale en_US_POSIX: https://developer.apple.com/documentation/foundation/dateformatter
- isLenient heuristic 설정: https://developer.apple.com/documentation/foundation/dateformatter/islenient
- 해석: isLenient=false와 형식·실제 날짜 roundtrip 검증을 함께 사용하여 허용 계약을 보장한다.

## Testability 평가 (test-architect)
### 평가 방식
Agent 슬롯 제한으로 기존 architect 채팅을 test-architect 역할로 전환해 재사용했다. 독립 critic 검토는 별도 수행했다. 본 평가자는 파일/테스트 패턴/러너 읽기만 수행, 실행 기준선은 부모 증거다.
### 컴포넌트별 테스트 전략
#### 기록모델·검증
- 레이어: 동작. 러너: XCTest RecordSectionTests, scripts/check-ios.py test {files}.
- 단위: 정상/비정상 값, 정확한 도메인오류, ID100/101·텍스트500/501·메모200/201·윤년/달력 경계.
- 통합: 원시 JSON의 누락/null/타입과 내용위반을 Codec에서 정확히 분류. 모의없음, 고정값. AC1,6,11.
#### 완료·메모·집계·정렬
- 레이어: 동작. 러너: XCTest RecordSectionTests.
- 고정시각/주입TimeZone, 기대값은 PRD 고정 예제로 독립 산출. 모의없음. AC1~9,15.
- 예시/진행/포기 제외, 멱등성, 여행별 메모, 없는ID 오류, UTF16/scalar/결합문자/ZWJ, 안정동시각 정렬.
- 정규화동등·원문이 다른 ID/메모는 utf16 비교로 판정하고 원문복원 역시 utf16/JSON로 검증.
#### AppSnapshot·Codec
- 레이어: 동작. 러너: XCTest RecordStorageTests 및 기존 저장회귀.
- 원시 JSON fixture 사용, 유효 상태 다른영역/버전/정렬/모든 필드, 전체읽기 실패. AC9,11~15.
- AC13 현행 유효 빈카드/active:null과 실제 정류장 값만 증거 가능.
#### AppModel·실제파일
- 레이어: 동작. 러너: @MainActor XCTest RecordStorageTests.
- UUID 임시파일 정상저장/새 저장소·새 AppModel복원. 모의는 read/create/write 실패와 호출횟수 경계만.
- 원본Data 보존 및 snapshot/route/path 유지, no-op write0. AC10~14 및 저장연결보강1~5,9,15.
- 시간대는 명시주입, 전역시간대 바꾸면 defer복구·직렬테스트. 신규UI/E2E없음; 기존UI회귀 유지.
### RED 격리 계약
설계 공개타입/생성자/필드/함수/오류만 전달. production파일 열람 금지. 기존 StorageTestSupport/StorageV2Tests/AppFoundationTests 테스트패턴 전달. sortedNewestFirst는 유효섹션만.
### 러너 격리
FOCUSMATE_SIMULATOR_ID=15645097-9CCF-4F45-A97B-8E43370F9488 python3 scripts/check-ios.py test ios/FocusMateTests/RecordSectionTests.swift ios/FocusMateTests/RecordStorageTests.swift
파일stem=테스트클래스명. 전용Simulator 명령직렬.
### Testability Score: 9/10
TESTABILITY PASS. 순수함수/시간대주입/실제파일 seam으로 검증가능. 파일복원·전역시간대 변경 통합격리 필요. 사용자 설계 승인 대기.
