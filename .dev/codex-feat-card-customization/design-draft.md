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
기본 RGB#121416/사진0장. 색 목록#121416,#F1F2F3,#497CE2,#4A8B73,#D9849B,#E2C46A. 사용자 색상은 불투명sRGB0...1. 신규 사진 중심0.5/0.5·너비0.6. 배열 뒤쪽이 앞에 표시된다.
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
