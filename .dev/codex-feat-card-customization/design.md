# 설계 초안: W10 카드 꾸미기

## 설계 규모
대형: 사진 처리·초안·공통 표시·v3 저장·큰 글자 회귀. 확정 PRD AC01~33과 context/card 용어·책임 경계를 유지한다.

## 변경 범위와 컨벤션
SwiftUI iOS17, Foundation 값 타입, MainActor Observable controller, Equatable 오류. 새 패키지 없음. PhotosUI/ImageIO/UniformTypeIdentifiers/CoreGraphics 사용. 저장은 AppModel.save → LocalSnapshotStore 기존 경로이며 최신 snapshot.updating으로 카드만 변경한다.
신규: CardStyle.swift, CardPhotoProcessor.swift, CardCustomizationController.swift, CardCustomizationView.swift, 각 unit/storage/UI시험과 사진 fixture.
수정: CardSection/AppSnapshot/SnapshotCodec/LocalSnapshotStore, AppModel/RootView/PassFace/UITestBootstrap, CardIssuanceView/TimeSelectionView, 문서. Xcode는 FileSystemSynchronizedRootGroup으로 신규 파일이 자동 등록된다. 불필요한 pbxproj 변경은 하지 않는다.

## 상세 설계
### 외형 값과 정책
```swift
struct CardColor: Codable, Equatable, Sendable {
 let red: Double; let green: Double; let blue: Double
 static let standard: CardColor
}
struct CardPhoto: Codable, Equatable, Identifiable, Sendable {
 let id: UUID; let data: Data; let pixelWidth: Int; let pixelHeight: Int
 var centerX: Double; var centerY: Double; var widthFraction: Double
}
struct CardStyle: Codable, Equatable, Sendable {
 var background: CardColor; var photos: [CardPhoto]
 static let standard: CardStyle
 var isStandard: Bool { get }
 func validate() throws
}
enum CardStyleValidationIssue: Error, Equatable {
 case invalidColor, tooManyPhotos(Int), duplicatePhotoID
 case invalidDimensions(UUID), invalidPlacement(UUID), photoTooLarge(UUID), totalPhotosTooLarge
}
```

CardCustomizationPolicy: 입력8_388_608바이트, 최대6장, 장당1_048_576바이트, 전체6_291_456바이트, 비율0.1...10, 너비0.15...2.5, 중심각축-1...2, undo20.
기본 RGB#121416/사진0장. 색 목록은 시안/현재 웹의 준비색 순서 #121416,#4B5661,#244154,#675364,#D9CDB9,#F1EEE7이다. 사용자 색상은 불투명sRGB0...1. 신규 사진 중심0.5/0.5·너비0.6. 배열 뒤쪽이 앞에 표시된다.
모든 수치는 유한값이어야 한다. 저장된 범위 밖 값은 거절하고 편집 요청만 clamp한다. 치수는 양수, 비율은 허용범위, 사진ID는 고유하다. 전체 바이트 검사를 장당 검사보다 먼저 수행한다. 실제 이미지 디코딩은 별도 경계에서 검증한다.

### 단일 v3 저장
CardSnapshot.init(id:String,issuedAt:Date,style:CardStyle = .standard), updating(style:CardStyle)->CardSnapshot.
AppSnapshot.validate는 style.validate를 호출하고 SnapshotValidationIssue.invalidCardStyle(CardStyleValidationIssue)·invalidCardPhoto를 추가한다.
SnapshotCodec.currentVersion=3. v3 style은 필수이며 누락을 기본값으로 숨기지 않는다. LegacySnapshotV2 전용 DTO에서 기존 id/issuedAt·stage/station/journey/records 계약을 고정하고 기본 외형으로 변환한다. static migrateV2(_ legacy:LegacySnapshotV2)->AppSnapshot. v1 변환 유지. 읽기만으로 재저장하지 않으며 저장·카드 보충 때 v3으로 쓴다. 지원 집합 밖 모든 버전은 기존 unsupportedVersion 경로다.
사진 Data를 같은 JSON에 base64로 저장한다. 사진6MiB는 JSON 약8MiB와 메타데이터이므로 사진 한도와 파일 크기를 구분한다. 기존 atomic write 한 번이 외형·사진의 공동 저장이며 W13 원본 백업에도 사진이 포함된다.

### ImageIO 처리·검증 경계
```swift
struct ProcessedCardPhoto: Equatable, Sendable {
 let data: Data; let pixelWidth: Int; let pixelHeight: Int
}
enum CardPhotoProcessingIssue: Error, Equatable {
 case inputTooLarge, unreadable, unsupportedAspectRatio, encodingFailed, cannotMeetStorageLimit
}
protocol CardPhotoProcessing: Sendable {
 func process(_ data: Data) async throws -> ProcessedCardPhoto
}
struct ImageIOCardPhotoProcessor: CardPhotoProcessing {
 func process(_ data: Data) async throws -> ProcessedCardPhoto
 static func validateStoredPhoto(_ photo: CardPhoto) throws
}
```

8MiB 초과는 디코딩 전에 거절한다. 확장자가 아닌 실제 ImageIO source·치수·orientation으로 판정한다. 원본 UIImage 전체 디코딩 대신 ThumbnailAlways·MaxPixelSize·WithTransform을 사용하며 최초 긴 변은 최대2048이다.
alpha가 있으면 PNG로 투명성을 보존하고 불투명 사진은 JPEG를 사용한다. JPEG quality0.85/0.7/0.55/0.4로 유한 시도하고 부족하면 긴 변0.75배를 최소64까지 반복한다. 매번 원본 source에서 thumbnail을 만든다. finalize·실제 Data.count·재디코딩·최종비율을 검사하고 한도를 맞추지 못하면 실패한다. 원래 orientation을 다시 삽입해 이중회전시키거나, 비율 경계를 맞추려고 늘이거나 잘라내지 않는다.
LocalSnapshotStore initializer에 기본 구현 validateCardPhotos:(CardStyle)throws->Void를 추가한다. load는 codec 이후 실제 디코딩과 선언치수를 확인하고 실패를 invalidCardPhoto로 분류한다. save는 구조·실제이미지 검증 후 기존 원자적 쓰기를 사용한다. backupAndClear의 정상파일 판정도 같은 이미지 검증을 사용해 손상사진의 명시적 복구가 가능하다. 기존 원본보존·재읽기·삭제확인 순서는 유지한다.

### 초안 controller
```swift
struct CardPhotoInput { let load: @MainActor () async throws -> Data? }
enum CardLayerDirection { case forward, backward }
enum CardCustomizationExitDecision: Equatable { case dismiss, confirmDiscard }
@MainActor protocol CardCustomizationSaving: AnyObject {
 func saveCardStyle(_ style: CardStyle, forCardID id: String) -> Bool
 var saveFailure: StorageIssue? { get }
}
enum CardCustomizationNotice: Equatable {
 case maximumPhotos
 case importFailed([CardPhotoProcessingIssue])
 case partialImport(failures:[CardPhotoProcessingIssue], omittedCount:Int)
 case saveFailed(StorageIssue)
}
@MainActor @Observable final class CardCustomizationController {
 init(card:CardSnapshot,saver:any CardCustomizationSaving,
      processor:any CardPhotoProcessing = ImageIOCardPhotoProcessor(),makeID:@escaping ()->UUID = UUID.init)
 private(set) var draft:CardStyle
 private(set) var selectedPhotoID:UUID?
 private(set) var isImporting:Bool
 private(set) var isSaving:Bool
 private(set) var didSave:Bool
 private(set) var notice:CardCustomizationNotice?
 var hasChanges:Bool { get }; var canUndo:Bool { get }; var canAddPhotos:Bool { get }
 func selectPhoto(_ id:UUID?)
 func setBackground(_ color:CardColor)
 func setPlacement(photoID:UUID,centerX:Double,centerY:Double,widthFraction:Double)
 func moveLayer(photoID:UUID,direction:CardLayerDirection)
 func deletePhoto(_ id:UUID)
 func undo(); func restoreDefault()
 func importPhotos(_ inputs:[CardPhotoInput]) async
 func requestExit()->CardCustomizationExitDecision
 func continueEditing(); func discard()
 @discardableResult func save()->Bool
}
```

controller는 카드ID와 진입 외형만 보관한다. 전체snapshot을 붙잡지 않는다. undo는 변경 직전 외형 최대20개이며 선택만 변경·같은 값·끝단순서·없는 사진은 no-op. undo로 없어진 선택ID는 nil이다.
import는 입력 순서대로 수행하고 실패는 자리를 소비하지 않는다. 성공 사진을 남은 자리까지 모아 한 번의 undo로 적용한다. 자리가 찬 뒤 나머지는 처리하지 않고 한도를 안내한다. 전부 실패하면 초안과 이력을 유지한다. 빈 picker 선택은 import를 시작하지 않으며 loader nil/throw는 unreadable이다.
generation을 시작 때 증가시키고 각 await 반환에서 활성 세션과 token을 확인한다. discard는 generation 증가·비활성·작업취소를 수행한다. 취소를 무시한 늦은 성공도 반영하지 않는다.
import 중 선택 외의 초안변경·undo·기본복원·save·재import는 controller에서도 막는다. 종료 확인은 허용한다. drag와 slider는 임시값으로 표시하고 동작 종료 때 한 번만 commit한다. 저장실패는 draft/history/selection 유지, 성공 때 baseline 갱신·history 제거·didSave. 동기 store 계약을 유지하며 저장 중 종료·중복저장을 막는다.

### AppModel·진입 통합
AppModel:CardCustomizationSaving, beginCardCustomization()->CardCustomizationController?, saveCardStyle(_ style:CardStyle,forCardID id:String)->Bool, currentCardStyle:CardStyle.
ready/발급/currentCard를 확인한다. 미발급은 초안 없이 기존 cardEntry를 유지한다. 저장은 최신 snapshot의 현재ID를 확인하고 카드외형만 바꾸어 snapshot.updating(cards:)→save를 호출한다. 최신 정류장·여정·기록을 보존한다.
메인에 카드 꾸미기 진입을 추가하고 W11 전체 profile은 구현하지 않는다. RootView fullScreenCover는 세션UUID identity, interactiveDismissDisabled(true), 명시적 닫기와 버리기 확인을 사용한다.

### 공통 카드·편집 UI
PassFace.init(style:CardStyle = .standard). 배경→기본일때만 점묘/기본텍스트→사진순서→고정IC/비접촉→테두리 순서이며 둥근 카드 경계로 자른다. 사진 너비=cardWidth*widthFraction, 높이=너비/비율, 중심=cardSize*center. 카드 번호는 표시하지 않는다. 현재 네이티브에 없는 기본 문구를 새로 창작하지 않는다.
편집 화면은 ScrollView, preview·색목록·불투명ColorPicker·orderedPhotosPicker.images·사진목록·선택제어·undo·기본복원·저장으로 구성한다. X/YStepper0.05와 너비Slider를 드래그 대안으로 제공한다. 이름·선택·현재값·가능여부를 접근성으로 노출한다. 큰 글자에서 제어를 수직배치하고 하단safeAreaInset 저장영역을 둔다. ReduceMotion이면 전환 애니메이션을 끈다.
PhotosPickerItem.loadTransferable(Data.self)를 CardPhotoInput loader로 전달하고 처리후 선택배열을 비워 같은 사진 재선택을 허용한다. 기존 announcer로 결과를 안내한다. DEBUG fixture 검사와 실제 PhotosPicker 선택·취소·재선택·보관함원본삭제 검증을 구분한다.

### 기존 큰 글자 회귀
AC32는 기존시험에서2회RED. 수리 전에 candidate/wheel frame·탭후minutes·proceed를 진단한다. wheel.frame(height:120)만 있으므로 hit영역침범은 가설이다. 필요할때만 clip/contentShape·후보가시공간을 수리하며1분step·20초spike기준을 유지한다.
AC33은 기존safeAreaInset을 중복추가하지 않는다. 끝스크롤로hint전체가button위에 도달하는지 확인하고 PASS이면 기능수리는 불필요하다. 가독성의 배경/여백은 표현설계로 분리한다. 필요하면 card.hint 식별자를 추가해 본문끝도달과 발급동작을 회귀검증한다.

## 의존성과 영향
저장항목추가시버전을올리는 context규칙을 따른다. 사진별파일저장계층을 추가하지 않고 기존단일store를 사용한다. v2 출력기대시험은새v3계약으로 테스트작성자가 갱신하고 v2 입력·변환회귀를 유지한다. W13복구·records저장·발급보충·미지원버전 차단을 검사한다.
사진이든test.snapshot전체base64를UI진단에복제하지 않고 ID/배치/hash의압축진단을 제공한다. 실제파일byte보존검증과구분한다. 공식API근거는 reports/api-notes.md다.

## 구현 순서 (critic 전 초안)
1 기존큰글자진단·수리: AC32/33, CardIssuanceView/TimeSelectionView.
2 외형model/PhotoProcessor: AC05/12/27의 수치·이미지.
3 Controller: AC03~17/19~23/26초안.
4 v3schema/store: AC24~29.
5 PassFace/편집UI: AC03/04/06/11~18/20~23/31.
6 AppModel/RootView/DEBUGfixture/E2E/문서: AC01/02/18/24~31 및 전체연결.
전RGR은순차실행한다. 3이CardSnapshot.style을요구해4보다먼저실행할수없으므로critic/test-architect에서2+4통합을평가하여최종태스크표를확정한다. 공유파일동시변경금지.

## 검증 경계
값/undo/importlock/generation→Unit, 실제PNGalpha/JPEG/HEIC/orientation/손상→ImageIOintegration, 실제tempfile/v1v2v3/atomic실패/W13백업→Storageintegration, fixture와실제PhotosPicker→UI. 실제VO포커스증거없이identifier시험으로완료를주장하지않는다. 큰글자/ReduceMotion/전체iOS/Node/DebugRelease가최종gate다.

## 확인 사항
추가 사용자 질문 없음. 사용자 전체진행 지시를 적용하고 비판 검토·testability를 거쳐 확정한다.


# 최종 계약 보강 (architect 2차)
이 부록은 초안의 모호한 계약과 구현 순서를 대체한다. 모든 타입·생성자·메서드는 internal이다.

## 값 생성자와 오류
CardColor.init(red:Double,green:Double,blue:Double), CardPhoto.init(id:UUID,data:Data,pixelWidth:Int,pixelHeight:Int,centerX:Double,centerY:Double,widthFraction:Double), CardStyle.init(background:CardColor,photos:[CardPhoto]), ProcessedCardPhoto.init(data:Data,pixelWidth:Int,pixelHeight:Int), CardPhotoInput.init(load:@escaping @MainActor () async throws->Data?), CardSnapshot.init(id:String,issuedAt:Date,style:CardStyle = .standard), updating(style:CardStyle)->CardSnapshot.
생성자는 보관만 하며 검증/clamp하지 않는다. 검증 순서: RGBfinite0...1→수량6→중복ID→전체byte→사진별emptyData→장당byte→양수치수/ratio→finite배치범위. 합계는overflow없이계산. CardStyleValidationIssue.emptyPhotoData(UUID)를 추가한다. RGB저장형식은Double로hex API없음. invalidCardPhoto는payload없음이며 style값오류는invalidCardStyle로구분.

## Store 전체 initializer
```swift
init(fileURL: URL,
 readData: @escaping (URL) throws -> Data = { try Data(contentsOf:$0) },
 createDirectory: @escaping (URL) throws -> Void = { try FileManager.default.createDirectory(at:$0,withIntermediateDirectories:true) },
 writeData: @escaping (Data,URL) throws -> Void = { try $0.write(to:$1,options:.atomic) },
 backupID: @escaping () -> UUID = UUID.init,
 writeBackup: @escaping (Data,URL) throws -> Void = { try $0.write(to:$1,options:.withoutOverwriting) },
 removeData: @escaping (URL) throws -> Void = { try FileManager.default.removeItem(at:$0) },
 validateCardPhotos: @escaping (CardStyle) throws -> Void = ImageIOCardPhotoProcessor.validateStoredStyle)
```
ImageIOCardPhotoProcessor.static validateStoredStyle(_ style:CardStyle)throws, validateStoredPhoto(_ photo:CardPhoto)throws. actual이미지검증실패는 SnapshotValidationIssue.invalidCardPhoto를throw. closure의어떤오류도Store에서StorageIssue.invalidState(.invalidCardPhoto)로포장한다.
load: read→codec/version/structure/modelvalidate→각styleactualvalidate→return.
save: candidate.validate→candidate각actualvalidate→기존load→encode→directory→atomicwrite. 후보invalidState와원본writeBlocked(issue)를구분한다. 후보검증실패는encode/create/write0회.
backup: originalread/expectedcompare→codec+actualvalidate→둘다정상일때만notRequired→기존backup bytecompare/re-read/delete/missing확인. 이미지손상도복구대상이지만원본보존은항상선행한다.
구조byte경계시험만명시적no-op validate closure를허용,actual사진보존성공으로주장하지않는다. 사진0이면추가decode없음.

## 실제 이미지 검증
input>8MiB=inputTooLarge. 빈Data/source실패/header·body손상/decode실패=unreadable. orientation적용원본ratio범위밖=unsupportedAspectRatio. destination/finalize실패=encodingFailed. 유한축소후1MiB불충족=cannotMeetStorageLimit.
source/index상태complete와thumbnail성공이필요하고bitmapcontext draw로실제decode를강제한다. 부분복구이미지는성공아님. 저장사진은actual/declared치수동일,긴변<=2048,actualratio0.1...10. 하나라도실패하면invalidCardPhoto. 최종인코딩바이트를다시읽어치수를정하며outputorientation은없거나1만. alphaPNG보존,한도·finalize확인. 별도cache계층없음.

## notice·편집·종료 계약
- 빈선택:모든상태/notice유지. 이미6장:maximumPhotos·loader0회.
- 성공만/생략없음:batch추가·notice nil.
- 성공0/실패있음:draft/history유지·importFailed(실패선택순).
- 성공있음/실패또는생략있음:batch추가·partialImport(failures,omittedCount).
- 자리찼으면남은loader호출없이omittedCount증가.
- loadernil/일반throw/활성세션CancellationError:unreadable. discard後세대변경success/error/cancel모두무시.
- saverfalse+saveFailure nil:saveFailed(.writeFailed). success:notice nil/didSave true/baseline=draft/historyclear. fail:draft/history/selection유지.
- finite범위밖배치clamp·달라진경우history. 비유한배치는전체no-op. invalidRGB no-op. unknown사진변경/삭제/순서/선택no-op. select(nil)은선택해제/history없음.
- discard:draft=진입baseline,historyclear,selectionnil,isImporting/isSaving/didSave false,notice nil,비활성. 이후변경/import no-op,save false. 비활성 requestExit는 상태 변경 없이 dismiss를 반환한다.
- generation은결과추가·오류notice·defer의isImporting해제모두보호. 확인dialog만으로import취소안함. 확인중완료후계속은완료초안유지,버리기는baseline복원. 정상저장후화면닫을때세션종료.
AppModelextension은private(set)setter관례를유지하려고AppModel.swift끝에둔다. begin은notready/미발급/카드없음nil. save는failed launch→writeBlocked(issue),그외notready/미발급/카드없음/ID불일치→notReady,false. 유효하면latestSnapshot카드style만save. currentCardStyle는currentstyle 또는standard.

## UI selector 계약
사용자label은한국어,식별자는화면에표시하지않는다.
- open.cardCustomization / screen.cardCustomization / cardCustomization.preview
- cardCustomization.color.standard / slate / blue / mauve / sand / ivory (각색전체접두사포함)
- cardCustomization.color.custom / cardCustomization.photoPicker / cardCustomization.photos / cardCustomization.photo.<UUID>
- cardCustomization.x / cardCustomization.y / cardCustomization.width
- cardCustomization.forward / backward / delete / undo / restoreDefault / save / notice / close (각전체접두사포함)
- cardCustomization.exitConfirmation / continueEditing / discard (각전체접두사포함)
시스템dialogcontainerID미노출이면실제문구와버튼ID검증,가짜dialog추가금지. PassFace그림은hitTestingoff,interactionlayer는카드영역안에서만hit. 시각clip과hit제한별도. 완전히밖의사진도목록재선택·Stepper로복귀가능해야한다.

## DEBUG 입력·진단
기존testUUID/seed유지. --fm-ui-card-photo-manifest <앱sandbox내JSON경로>, --fm-ui-card-import-hold manual, --fm-ui-card-save fail-once 추가.
manifest={"items":[{"path":"상대경로"}]}:같은fixture디렉터리내파일만허용. 잘못된경로/파일없음은loadfail. Release에는인자·fixture버튼·진단없음.
test.cardImportFixture / test.releaseCardImport 버튼. manual은continuation해제,임의sleep아님. 취소무시latecompletion은unitloader로검증하고productionDEBUG불필요분기추가금지.
test.cardStyleJSON compact키: cardID,background{red,green,blue},photos[{id,pixelWidth,pixelHeight,centerX,centerY,widthFraction,byteCount,sha256}],draft{background,photos},selectedPhotoID,isImporting,canUndo,didSave. 최상위는저장외형,draft는초안. 화면없으면draft/selectionnull,boolfalse. base64/undoCount없음.
재실행은같은UUID+seed생략. actualfixture는시험측독립ImageIO PNG/JPEG/HEIC/orientation생성,WebP는출처있는실제자료및지원여부기록. input8MiB성공은actualcomplete decode유효자료, 무조건후행padding/dummy크기맞춤금지. DEBUG입력과actualPhotosPicker선택/취소/재선택/보관함원본삭제는별도증거다.

## 최종 RGR 태스크 (초안 순서 대체)
| 태스크 | 의존 | 소유 파일 | AC |
|---|---|---|---|
| T1 큰글자baseline진단·유효결함수리 | 없음 | CardIssuanceView·TimeSelectionView·기존관련UI시험 | 32,33 |
| T2 모델·이미지·v3·store | 없음 | CardStyle·CardPhotoProcessor·CardSection·AppSnapshot·SnapshotCodec·LocalSnapshotStore·관련시험 | 05,12,24,25,27,28,29 |
| T3 Controller | T2 | CardCustomizationController·관련시험 | 03,04,06,07,08,09,10,11,13,14,15,16,17,19,20,21,22,23,26 |
| T4 AppModel통합 | T2,T3 | AppModel.swift끝extension·통합시험 | 01,02,24,26,29,30 |
| T5 화면·공통표현·DEBUG·최종연결 | T1,T4 | PassFace·CardCustomizationView·RootView·UITestBootstrap·새UI시험·문서 | 직접UI18,31 및전체연결 |
전RGR순차. T4후T5실제UI RED가능. RootView는T5만소유. PBX자동등록. T1 AC33이미PASS이면기능수리없이증거보존,문구/가독성수정끼워넣지않음. AC32진단후원인확정,20초spike기준유지.


## Testability 평가 (test-architect)
최종9/10 TESTABILITY PASS. 초기7/10의독립RED계약10항목을2차보강으로해소했다.
값·Controller·실제ImageIO·실제Store·UI구분 및AC01~33시험전략은reports/testability-draft.md참조. 실제인코더희귀실패는모의processor전달시험과실제통합증거를구분하며,표현·CUA/VO환경제약은점수감점대상이아니다.필수보강없음.

## 시안 구현 기준 — 사용자 방향 재확인 (2026-10-14)
사용자의 “시안 대로 화면 구성하는 것 맞지?” 지시를 반영한다. 화면 구성의 기준은 활성 Pencil 문서 `/Users/bonseung/Documents/ChatGPT/new/designs/focus-mate.pen`의 R39 `z3LCu`(처음), R40 `x3PCFl`(사진 배치)다. 두 노드의 구조를 MCP로 직접 읽고 캡처/PNG를 보존했다. 참조 PNG와 상세 값은 `reports/design-reference/`에 있다. `.pen` 내용은 일반 파일 도구로 읽지 않았다.

- 402×874 기준: 상단 뒤로/제목/되돌리기 → 좌우24pt 카드 미리보기(카드 inner352×221.1875, 둥근16pt) → 두줄 안내 → 배경색 → 직접 고르기 → 사진 제목/추가 버튼/가로 사진 목록 → 선택 사진의 크기 및 편집 제어 → 하단 고정 흰색 “이 카드로 저장하기” 버튼. generic Form/기본 파란 CTA를 새 화면의 전체 구성으로 쓰지 않는다.
- 기본 화면의 빈 사진 안내와 기본 검정 카드 복원 링크를 유지한다. 선택된 사진은 카드 내 선택 테두리/크기 손잡이, 목록 선택 표시, 크기 슬라이더를 제공한다. 위치 Stepper/앞뒤/삭제는 시안의 선택사진 도구 영역에 연결하며 큰 글자는 스크롤로 모든 도구/저장에 도달한다.
- 준비색 순서와 이름: 기본 검정#121416, 슬레이트#4B5661, 짙은 파랑#244154, 모브#675364, 샌드#D9CDB9, 아이보리#F1EEE7. ID는 standard/slate/blue/mauve/sand/ivory. 초안의 임의 bright palette를 대체하며 Controller의 임의 sRGB 색 API와 모델/저장 계약은 바뀌지 않는다.
- 화면 배경#0D0F10, 주요 글자#FFFFFF, 보조#B8BFC5/#B0BAC2, 사진 추가#181D20. header20/section15/help12/footer15pt의 위계를 기준으로 Dynamic Type에 대응한다. 최신 웹과 사용자 후속 결정의 서울알림체(기존 저장소의 Medium/Bold 라이선스 포함)를 적용한다. Pencil export의 이전 Noto 표기는 서체 후속 결정보다 앞선 상태다.
- 공통 PassFace의 기본 브랜드·카드명 배치/IC·비접촉 위치는 해당 카드 시안과 현재 웹을 대조한다. 기본 카드 서울 점묘, 카드번호 미표시, 꾸미면 브랜드·카드명·문구 숨김은 확정 PRD대로 적용한다. “나를 위한 시간, 한 장으로.”는 승인 시안에 있는 문구이므로 기본 카드에 사용할 수 있다. 이전 “현재 네이티브에 없는 기본 문구를 새로 창작하지 않는다”는 임의 문구를 금지하는 의미이며 승인 시안 문구 구현을 막지 않는다.
- W11 전체 마이페이지/W04 승하차 신규 화면은 이 작업에 포함하지 않는다. W10 진입과 공통 카드 표현에 필요한 부분만 연결한다.
- T5 완료 증거는 기본/사진배치/취소확인/오류/큰글자 시뮬레이터 캡처와 참조의 직접 대조다. 기능시험 PASS를 시각 일치 PASS로 대신하지 않는다. 카드 미리보기 비율/위계/색/버튼 위치를 먼저 확인하고 다른 네이티브 화면의 시안 일치까지 완료됐다고 확대하지 않는다.

## T2 메모리·PNG 무결성 보강
원본 index bitmap과 provider 전체 Data를 추가 할당하지 않는다. 입력 PNG는 chunk CRC 및 IDAT zlib stream을 고정 출력버퍼로 검증하고, scanline 길이/행 수/filter(0...4)를 IHDR/Adam7에서 독립 도출해 부분 복구를 거절한다. 7pass offset/stride=(0,0,8,8),(4,0,8,8),(0,4,4,8),(2,0,4,4),(0,2,2,4),(1,0,2,2),(0,1,1,2). width/height에 새 픽셀 상한을 추가하지 않으며 모든 PNG 표준 color type/bitdepth/interlace를 유지한다. CRC만 정상인 손상 IDAT나 정상 zlib의 짧은 raster도 성공 아님. 최종 IDAT의 zlib 종료 뒤 압축 잔여값은 명세에 따라 허용하되 과도한 inflate raster 출력은 거절한다. 원본 무결성 확인은 quality/축소 반복마다 재실행하지 않는다. 실제 ImageIO thumbnail과 bounded draw/출력 재읽기는 유지한다.
근거: test-architect SDK zlib header 조사 및 [W3C PNG 3](https://www.w3.org/TR/png-3/) 5,7,8,9,10,11. thumbnail-only의 플랫폼 자체 비용은 원본 추가 디코딩과 구분하며 모든 입력의 총 RSS 상한을 보장했다고 기록하지 않는다.

### WebP 추가 실제 손상 회귀
정상 VP8L header5바이트+0xff본문1바이트의 RIFF framing 정상 입력에서 ImageIO가 부분 복구를 성공으로 반환하는 actualRED를확보했다. [Google 공식 명세](https://developers.google.com/speed/webp/docs/webp_lossless_bitstream_specification)의 LSB-first: transformpresent1/type2=3 뒤8bit색상표크기필수로 총11bit인데본문8bit뿐이다. 내부 payload 경계 비트리더로 필수프리픽스절단을거절하고 다른chunk/padding을빌려읽지않는다. type0/1은3bitblocksize후보조이미지, type2는추가값없고다음transform, type3는8bitpalette후보조이미지. transform중복금지. 보조이미지/Huffman해석전검사종료→ImageIO전달이며완전한WebPstrictdecoder를새로구현하거나모든손상을검증했다고주장하지않는다. 일반VP8/extended형식허용은유지한다.

### T4 저장 여정 계약 확인
현재 `JourneySnapshot`은 case가 없는 enum이며 모든 non-null decoding을 거부한다. 저장 여정의 유일한 유효 리터럴은 `{"active":null}`이다. T4 최신 snapshot 보존은 편집 진입 뒤 기존 `AppModel.save`로 정류장을 바꾸고 `saveRecordMemo`로 기록을 바꾼 후 카드 저장·재로드로 검증한다. nonempty 저장 여정 값·setter·mock seam을 W10에서 추가하지 않는다. 메모리의 `journeyPlan`/계산값 `preparedJourney` 보존은 별도 실행 중 회귀이며 저장 여정 재실행 복원 증거가 아니다. 정확한 API·기대 리터럴·초안 제한 해소는 [T4 여정 계약](reports/t4-journey-contract.md)에 기록했다. non-null 여정 원본은 기존 corrupt/원본 보존 경계를 유지한다.

## T5 DEBUG fixture 경로·생명주기 기술 계약
`--fm-ui-card-photo-manifest`는 실제 Application Support를 기준으로 상대경로를 해석하며 absolute도 해당 subtree 안에서만 허용한다. parent가 앱 sandbox의 `Library/Application Support/FocusMate/UITestPhotoFixtures/`에 독립 실제 fixture/manifest를 staging한다. manifest item은 같은 디렉터리 하위만 허용하고 symlink/..로 벗어날 수 없다. 신규 seed나 base64 입력 인자를 만들지 않는다. UItest는 상대 경로 `FocusMate/UITestPhotoFixtures/valid2.json` 등을 쓰므로 simulator app-container UUID를 hardcode하지 않는다. DEBUG 입력은 actual ImageIO/controller/store 경로를 그대로 사용한다.
manual hold는 각 fixture batch의 첫 loader를 explicit release까지 보류하고 나머지 항목은 같은 release를 공유한다. 새 batch에서 다시 arm한다. View가 import Task를 소유하고 종료 시 cancel하며 Controller.discard가 먼저 세대무효화한다. DEBUG gate는 cancellation 시 자기 token의 continuation을 종료해 leak을 남기지 않는다. 취소무시 late-result는 기존 unit gate 경계로검증하고DEBUG에인위적분기추가하지않는다.
fail-once는 편집 Save action이 DEBUG shared failure box를 arm하고 기존 LocalSnapshotStore writeData closure가 1회 소비·throw한다. seed·보충·정류장·메모 저장에는 자동으로 arm하지 않는다. 바뀐 style 비교로 ‘저장 행위’를 추정하지 않는다. 다음 재시도는 정상 atomic write며 Release에는 flag/box/gate/diagnostic이 없다. UI의 test-onlysupport는 기존DEBUG Bootstrap 경계에만 두고 production AppModel 저장API/접근수준을 넓히지 않는다.

## T5 UI testability 보강
저장 성공은 편집 화면을 자동으로 닫고 “카드 외형을 저장했어요.”를 메인에서 비모달 안내·announcement로 제공한다. 닫힌 뒤 diagnostic draft/selectedPhotoID=null, didSave=false이며 저장 외형은 최상위에 남는다. 재편집은 진입 버튼으로 새 세션을 만든다. 저장 실패만 편집 화면/선택/이력을 유지한다. `cardCustomization.savedNotice`는 성공 안내 식별자다.
X/Y stepper는 한국어로 이름을 제어할 수 있는 감소/현재값/증가 버튼 쌍으로 제공해 보조기술·자동화에 동작을 명시한다. x: “가로 위치 줄이기”/“가로 위치 늘리기”, y: “세로 위치 줄이기”/“세로 위치 늘리기”; child ID `cardCustomization.x.decrease/increase`, y도동일. 1회5%·clamp는Controller계약이다. 최소44pt 버튼이며 UI플랫폼지원 Button repeat로 계속누르기도지원할수있다. nativeStepper의미확정localizedchildlabel을추정하지않는다. containerIDs x/y, widthSlider는원계약유지.
본문ScrollView의ID는 `cardCustomization.body`이며 테스트스크롤은 좌우24pt여백 안(2%지점)을 사용해 사진드래그와구분한다. 기본/선택사진캔버스 안의드래그는본문스크롤을대체해사진위치를조절한다.
XXXL 자동UI케이스와 실제시스템ReduceMotionON 보충실행을구분한다. 앱내가짜toggle/환경강제인자를추가하지않는다. DEBUG readonly `test.reduceMotion`은실제SwiftUIenvironment Boolean만읽어표시해parent가실제Simulator설정적용을확인한다. 설정ON검증은owned iOS27sim에서별도수행하고기존iOS26.5전체suite환경을임의변경하지않는다.

## XXXL 카드 그래픽 표시 정책 — 시각 검증 후 보강

PassFace는 카드명 전체를 가진 하나의 접근성 이미지다. 카드 내부의 브랜드·이름·목적 문구는 고정 비율 카드 artwork 좌표와 동일한 크기 체계로 렌더링해 Dynamic Type을 크게 해도 서로 겹치거나 카드 경계에서 잘리지 않아야 한다. 카드 그래픽의 조합을 유지하는 정책이며 편집 제목·본문·위치/크기/순서/삭제·저장 조작의 Dynamic Type 크기를 축소하지 않는다. 기본/XXXL 카드 그래픽의 동일 구성과 실제 XXXL 화면을 별도로 검증한다. 이는 최종 캡처에서 발견한 AC-W10-18 표시 결함에 대한 명확화다.

## 최신 main W11 통합 — 8ac11c3 합류

W11 설계서의 W10 합류 절차를 적용한다. RootView의 기존 편집 액션을 하나의 세션 시작 함수로 추출하고 DestinationScreen의 callback을 통해 ProfileView.onCustomize에 주입한다. ProfileView의 PassFace에는 model.currentCardStyle을 공급한다. Destination.cardStudio와 ProfileMenuItem.customize 자리표시는 제거하고 해당 단위/UI 계약을 실제 편집·닫기 복귀로 교체한다. 기존 통계/설정 동작은 유지한다. 저장 안내는 NavigationStack의 현재 화면에서 볼 수 있는 비모달 영역으로 제공한다. W10 카드와 버튼이 추가된 메인은 XXXL에서도 프로필 진입점에 실제 스크롤로 도달할 수 있어야 한다. root source integration은 별도 RED→GREEN으로 검증하며 전체 회귀에는 W11 Profile/Seed/집계 테스트를 포함한다.
