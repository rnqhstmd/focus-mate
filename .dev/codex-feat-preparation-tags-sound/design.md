# 설계: W03 준비 허브·태그·소리

## 설계 규모
대형. 승인prd25AC전체. 사용자전체진행승인으로routine설계선택자율진행. 웹시각선확인보류기록유지.

## 컨벤션·변경 범위
Foundation값타입 / MainActor Observable 컨트롤러 / Bindable SwiftUI. Xcode PBXFileSystemSynchronizedRootGroup으로Swift및WAV자동등록. 신규PreparationDraft.swift, SoundPreviewController.swift, AVSoundPreviewPlayer.swift, PreparationView.swift. 수정AppModel.swift, DestinationScreen.swift, PreparationFlowUITests.swift. 저장모델/스키마무변경. 기존WAV4개 Resources/Audio 아래바이트동일복사. 본문API는internal @testable접근용.

## 순수 값 타입 인터페이스
```swift
enum PreparationTagIcon: String, CaseIterable, Equatable {
 case reading, work, study, development, writing
 var title: String { get }; var systemImage: String { get }
}
enum PreparationTagColor: String, CaseIterable, Equatable {
 case sand, blue, purple, green, pink
 var title: String { get }
}
struct PreparationTag: Identifiable, Equatable {
 let id: String; let name: String
 let icon: PreparationTagIcon; let color: PreparationTagColor
 init(id: String, name: String, icon: PreparationTagIcon, color: PreparationTagColor)
 static var defaults: [PreparationTag] { get }
}
struct TagEditorDraft: Equatable {
 var name: String; var icon: PreparationTagIcon; var color: PreparationTagColor
 init(name: String = "", icon: PreparationTagIcon = .reading, color: PreparationTagColor = .sand)
}
enum TagNameIssue: Error, Equatable {
 case empty, tooLong, duplicate
 var message: String { get }
}
enum JourneySound: String, CaseIterable, Equatable {
 case bus, rainBus, subway, forest, none
 var title: String { get }; var systemImage: String { get }; var resourceName: String? { get }
}
struct PreparationDraft: Equatable {
 private(set) var tags: [PreparationTag]
 private(set) var selectedTagID: String?
 private(set) var task: String; private(set) var sound: JourneySound
 init()
 var selectedTag: PreparationTag? { get }
 var trimmedTask: String { get }; var isComplete: Bool { get }
 @discardableResult mutating func chooseTag(id: String) -> Bool
 mutating func setTask(_ value: String)
 mutating func setSound(_ value: JourneySound)
 @discardableResult mutating func saveTag(_ editor: TagEditorDraft) -> Result<PreparationTag, TagNameIssue>
}
struct PreparedJourneyDetails: Equatable {
 let journey: JourneySelection; let tag: PreparationTag
 let task: String; let sound: JourneySound
 init(journey: JourneySelection, tag: PreparationTag, task: String, sound: JourneySound)
 var originName: String { get }; var boundLabel: String { get }; var distanceText: String { get }
}
```
기본태그ID reading/study/work/rest, 이름독서/공부/업무/휴식. 초기선택nil·빈task·bus. 선택은목록존재ID만,다른초안유지. task는80UTF16예산누적하며Unicode scalar중간에서자르지않고trim은확정시만. 태그이름trim→빈값→20UTF16초과→NFKC소문자중복검사. 성공UUIDid태그추가및선택, 실패시초안불변. editor는시트State별도이므로취소는폐기.
PreparedJourneyDetails는W02 JourneySelection전체값. 이름RouteStops.name(at:),방면RouteStops.boundLabel(from:),거리JourneyPlanner.distanceText(stops:)재사용(실제시그니처는기존소스확인).

## AppModel 세션·W04 경계
```swift
var preparation: PreparationDraft
private(set) var confirmedPreparation: PreparedJourneyDetails?
private(set) var preparationRequest: PreparedJourneyDetails?
var canConfirmPreparation: Bool { get }
@discardableResult func confirmPreparation() -> Bool
func consumePreparationRequest() -> PreparedJourneyDetails?
```
AppModel본문에추가. canConfirm=ready(main)+preparedJourney존재+태그존재+trimtask비공백+80이하. confirm실패는confirmed/request nil/false, 성공값복사두곳보관. 동일payload중복은미소비요청유지. consume은request만비우고confirmed유지. W03실제승차권화면/새Destination/저장/진도없음. 승차권보기는confirm호출, W04가request소비할경계제공. 준비화면머무름을W04미구현한계로명시. 기존proceedToPreparation는초안reset없음. 시간이바뀌면W02선택무효라확정차단.

## 소리 제어 인터페이스
```swift
@MainActor protocol SoundPreviewPlaying: AnyObject {
 var volume: Float { get set }; var numberOfLoops: Int { get set }
 func prepareToPlay() -> Bool; func play() -> Bool
 func setVolume(_ volume: Float, fadeDuration: TimeInterval)
 func stop()
}
@MainActor @Observable final class SoundPreviewController {
 enum Phase: Equatable { case stopped, loading, playing }
 private(set) var selectedSound: JourneySound
 private(set) var phase: Phase
 private(set) var errorMessage: String?
 init(sound: JourneySound,
      makePlayer: @escaping @MainActor (JourneySound) async throws -> any SoundPreviewPlaying,
      sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) })
 func chooseSound(_ sound: JourneySound)
 func togglePreview() async
 func stopPreview()
 func setActive(_ active: Bool)
}
@MainActor final class AVSoundPreviewPlayer: SoundPreviewPlaying {
 init(url: URL) throws
 var volume: Float { get set }; var numberOfLoops: Int { get set }
 func prepareToPlay() -> Bool; func play() -> Bool
 func setVolume(_ volume: Float, fadeDuration: TimeInterval); func stop()
 static func make(sound: JourneySound, bundle: Bundle = .main) async throws -> any SoundPreviewPlaying
}
```
controller시트마다생성해확정소리로초기화. selectedSound는임시선택. 실제factory호출은사용자preview시만. active/stopped/non-none일때generation증가하고loading. factory반환후generation/active/sound/Task취소검사. 이전60ms종료task남으면await후재검사. volume0/loops-1/prepare Bool/play Bool 성공뒤fade1 0.12/playing. 오류선택값유지/stopped/안내. stop은generation즉시증가/stopped, 기존player fade0 0.06 후주입sleep60ms뒤stop. 이전player완전중지전새player재생금지. loading재입력은취소. none factory0. chooseSound변경시중지,activefalse중지,activetrue자동재개없음. stalefactory반환은play0,자원stop정리. 선택·저장·취소·스와이프·onDisappear·scenePhase != active 모두종료로수렴. Taskcancel만으로차단주장하지않음.
AVadapter는AVAudioPlayerforward. none/번들URL없음/init실패throw. 기존WAV 이름resourceName 확장자제외. 새library/backgroundaudioentitlement없음. 공식AppleAPI근거 native-references.md.

## 화면
PreparationView(model: AppModel). privateTagEditor/SoundSelectionView같은파일. DestinationScreen.preparation자리표시자교체, navigationTitle빈값·기본뒤로유지, DEBUG test.journeySelection유지.
태그LazyHGrid두행가로ScrollView/+마지막, 선택전taskTextField생성안함. 선택후binding.setTask. 소리왼쪽/confirm오른쪽. 전체세로ScrollView로최대글자도도달. 이름'무엇을할까요?' 실제문구띄어쓰기. 태그editor초기값매번빈값/독서/모래빛. 오류시시트유지·이름포커스, 취소save미호출/+포커스, 성공task포커스. 소리저장만draft.setSound;취소확정값불변. preview오류에도save활성. 닫히면소리칩포커스. reduceMotion시장식이동없음,fade유지.
접근성ID: screen.preparation, preparation.tag.<id>, preparation.addTag/task/sound/confirm, tagEditor.name/icon.<rawValue>/color.<rawValue>/error/save/cancel, sound.option.<rawValue>/preview/error/save/cancel. 이름·selectedtrait·enabled·currentvalue 제공. 숨긴컨트롤접근불가. W04request관찰은DEBUG test.preparedPreparation으로JSON진단허용제품테스트전용메서드없음.

## 테스트·실행 태스크
같은컴포넌트AC는묶되각AC시나리오개별케이스.
T1 순수draft+AppModel: AC1~13및23. PreparationDraftTests/PreparationModelTests. DIstorewriteSpy0,80/81·20/21·trimNFKC·시간왕복·payload·consume.
T2 previewcontroller+AVadapter: AC17~22와bundle샘플. SoundPreviewControllerTests+AudioResourceTests. fakeplayer는protocol경계만,continuationfactory/sleepgate. runtime실제시간sleep테스트금지. late결과5갈래/nooverlap/none0/factorythrow/preparefalse/playfalse/復帰0.
T3 SwiftUI: AC1~16,19~25. PreparationFlowUITests자리표시자검사교체, W03전용PreparationEditorUITests및큰글자/명칭/취소/왕복/confirm진단/시트정리. 스타일assert없음. 네이티브UI테스트와웹시각검증분리.
순서T1→T2→T3(각RED→GREEN→REFACTOR,태스크간병렬금지). 새타입compileRED뒤무동작선언허용하되behaviorassertRED실제실행후만GREEN.

## 의존성 및 제외
저장스키마/codec/store/cards/records/복구무변경. 기본W02반환계약유지. WAV기존4개동일복사·실제번들포함검증. W04승차권은후속이며W05travel오디오통합미구현. 웹브라우저확인보류상태유지.

## 확인이 필요한 사항
추가 확인 사항 없음. 설계가 완료되었습니다.


## 2차 설계 보강 (이 절이 이전 관련 계약을 대체)

### 확정값 현재 유효성
AppModel storedConfirmedPreparation/storedPreparationRequest private backing 두값. 공개 confirmedPreparation/preparationRequest는현재payload가각stored와동일할때만반환하는read-onlycomputedproperty. currentPreparationDetails는ready(main),현재preparedJourney,선택태그,trimtask비공백/80이하를검사해payload구성. invalid/differentgetter nil,읽기부작용없음. confirm유효현재payload를저장,invalid두backingnil/false. consume은현재payload/확정/요청모두일치때반환후request만nil; invalid/different면둘다nil. 요청만이미nil이고현재confirmed유효면confirmed유지. consume후재confirm은새request,미소비동일payload연타는하나유지. 시간/태그/task/sound변경후stale소비불가테스트추가. invalidconsume후입력복원해도삭제요청복원없음.

### 세션 단일 오디오 소유
시트별controller생성폐기. AppModel수명단일소유,이API추가는T2때진행(초안T1은controller없음).
```swift
let soundPreview: SoundPreviewController
init(store: LocalSnapshotStore, cardFactory: CardSnapshotFactory = .init(),
     soundPreview: SoundPreviewController? = nil)
```
nil이면init에서SoundPreviewController(sound:.bus,makePlayer:{try await AVSoundPreviewPlayer.make(sound:$0)})생성,실제player는생성안함. 기존생성자sourcecompatible.
controller에func beginSelection(sound: JourneySound)추가. 기존재생/loading무효화·stop,old60ms종료task보존,전달된확정소리/오류nil/stopped/active로초기화, factory/prepare/play0. 모든시트/prepare재진입같은model.soundPreview사용. close/reopen새preview는oldstop완료await후유효성검사하므로overlap없음.

### stale failure·중복stop
catch도generation/active/선택검증해oldthrow가currentphase/error/player덮지않음. stop은player를종료task로옮기면서activeplayer참조nil,fade0/60ms1회·stop1회. 반복stop은generation만무효화하고oldstopTask취소·교체안함. beginSelection도oldstopTask보존. 새preview는끝나지않은stopTaskawait.
필수tests: oldloading→선택변경→새요청성공→oldthrow;oldloading→close/reopen→oldthrow;stop여러번→fade/stop1회;시트close/reopenbeginSelection후nooverlap.

### 한줄/정책
한줄은TextField표현. interiornewline치환/거절새정책없음. UTF16상한·양끝trim만기존웹유지.

## Testability 평가

### Score:8/10 PASS
순수PreparationDraft/TagEditor:실제값테스트,mock없음 AC1~9/19.
AppModel:실제store와I/Oclosure경계spy,throw전호출증가,write0/snapshot및바이트불변,확정/요청소비·시간무효AC11~13/23.
Controller:protocolfakeplayer/factorycontinuation/sleepgate로late완료/nooverlap/fade120·60ms/loop-1/throw·preparefalse·playfalse/none0/복귀0 AC17~22.
AVadapter/WAV:실제Bundle.main4샘플URL·decode·factory성공,sourcepathfallback금지,복사바이트비교별도. fake만으로리소스포함주장안함.
SwiftUI:실제XCUITest role/name또는프로젝트ID컨벤션으로선택/입력/버튼enabled/시트취소·왕복/큰글자/숨긴컨트롤미노출 AC1~16/19~25.

### 동작/표현 분류
상태검증/폼가드/라우팅/컨트롤러/UI조건부렌더는동작.색/여백/폰트/테두리/장식모양은표현으로테스트밖.

### 러너
XCTest apphost와XCUITest이미존재,check-ios.py test파일단위focused실행.파일stem=class명일치.

### RED 격리
새타입compileRED뒤무동작선언만추가,behaviorassertRED실행후GREEN.기댓값손도출리터럴.테스트전용제품메서드금지.固定yield/sleep대신explicitexpectation+continuation해제,모든task정리.

### 검증 범위 한계
단위테스트stopAPI만호출해시트저장/취소/이탈5갈래UI연결을검증했다고주장하지않음. 실제UI연결검사필요. 자동접근성attribute와실제VoiceOver포커스수동검증구분. actualWAVdecode는청취품질아님.

### 판정
TESTABILITY PASS:8/10. critic두MUST보강뒤진입.


## UI 테스트 환경 계약 (T3)
DEBUG UITestBootstrap에선택적`--fm-ui-sound fail`인자검증을추가하고실제makePlayer가throw하는controller를AppModel에주입한다. 테스트ID없는일반앱/Release는기존실제adapter사용. 실패상태UI와저장계속검사용외래효과경계주입,production테스트전용메서드없음.
DEBUG PreparationView 또는DestinationScreen에`test.preparedPreparation` 진단: nil은문자열null,있으면 journey{minutes,busID,busNumber,destination,stops},tag{id,name,icon,color},task,sound JSON. 실제유저confirm후W04준비값관찰용.
DEBUG `test.soundPreview` 진단: selectedSound rawValue,phase(stopped/loading/playing),errorMessage(optional). 제품컨트롤에는sound.preview의accessibilityValue로현재재생phase노출. 닫힌시트컨트롤은미노출,세션controller진단은준비상태에서관찰가능. 현실실재생/닫기/복귀는UI진단과사용자결과로검증하고stale factory는T2주입gate단위검증.
최대글자테스트는기존`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`와`test.dynamicTypeSize`실반영확인. 실제VoiceOver포커스/실기기청취/실제시스템동작줄이기수동QA는한계명시. W03장식animation추가없음.

- T3 실제 스크롤 조작용 접근성ID: 태그 가로ScrollView `preparation.tags`, 태그편집세로ScrollView `tagEditor.fields`. 스타일/구조indexselector대신실제사용자스크롤동작위치지정.
