# Phase 1 설계 — 2차 계약

2026-10-13 architect 2차. 이 문서가 design-draft.md의 이전 계약을 대체한다. 규모 대형. 승인 PRD P1-FR-1~3/P1-BR-1~3/P1-AC-1~4 유지. 신규 ios/앱·단위/UI 테스트 타깃, 상태·저장·모델·루트·DEBUG bootstrap만 구현. 외부 deps 없음. SwiftUI/Observation/Foundation/XCTest, iOS17, Swift5 언어모드.

## 파일 및 컨벤션

ios/FocusMate.xcodeproj 및 공유 FocusMate scheme; ios/FocusMate/{FocusMateApp,AppSnapshot,LocalSnapshotStore,AppModel,RootView,UITestBootstrap}.swift; ios/FocusMateTests/ 및 FocusMateUITests/. .gitignore/README.md/.claude/config.json은 실검증명령/산출물 연결. 검사 실행기 scripts/check-ios.py 및 Python3 명령 package.json, 구현 상태 연결 문서 docs/{CURRENT-STATE,DEVELOPMENT-PHASES,MVP,PHASE-1-FOUNDATION}.md와 context/README.md를 함께 보완한다. 웹/Pen 제품 동작 변경 없음.

Swift 타입·파일 UpperCamelCase, 멤버 lowerCamelCase. 모든 계약 internal, @testable import 가능. 값 타입 Codable/Equatable; 모델·저장 호출 MainActor 동기 직렬. 아래 의미가 부족하면 기존 코드로 추측하지 말고 계약 보강한다.

## AppSnapshot.swift

- StationSnapshot: Codable, Equatable. let id: String, name: String, direction: Int. init(id:name:direction:).
- AppSnapshot: Codable, Equatable. let cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?. init(cardIssued:initialStation:currentStation:).
- static AppSnapshot.empty = (false,nil,nil).
- LaunchRoute: Equatable { cardEntry, initialStationEntry, main }.
- SnapshotValidationIssue: Error, Equatable { inconsistentStage, emptyStationID, emptyStationName, invalidDirection(Int) }.
- validate() throws -> Void; launchRoute() throws -> LaunchRoute.

유효 조합: (false,nil,nil)→cardEntry; (true,nil,nil)→initialStationEntry; (true,station,station)→main. 마지막의 최초·현재는 달라도 됨. 검증순서 단계조합→최초→현재. 각정류장은 ID→이름→방향 검사. whitespace/newline trim 후 비어있으면 오류이며 저장 원문은 정규화하지 않음. direction은 1/-1, 숫자0은 invalidDirection(0), 문자열 등 decode 타입 오류는 corrupt. 생성자는 throw하지 않고 validate/launchRoute에서 검사. 카드 실제ID/발급/외형 및 태그/시간/여정 필드는 범위 밖.

## LocalSnapshotStore.swift

Application Support/FocusMate/app-state.json. envelope는 version: Int=1, state: AppSnapshot 필수. 같은 파일에 indirect enum StorageIssue: Error, Equatable:

unreadable, corrupt, unsupportedVersion(Int), invalidState(SnapshotValidationIssue), writeFailed, writeBlocked(StorageIssue), notReady.

- init(fileURL: URL, readData: (URL) throws -> Data, createDirectory: (URL) throws -> Void, writeData: (Data, URL) throws -> Void). closure기본값 제공.
- let fileURL: URL internal읽기.
- load() throws -> AppSnapshot?; save(_ snapshot: AppSnapshot) throws -> Void.
- 기본 read Data(contentsOf:), directory FileManager.createDirectory 중간폴더허용, write Data.write(.atomic).

load는 CocoaError.fileReadNoSuchFile만 nil. 기타 읽기오류 unreadable. 폴더/기본파일 생성 없음. version먼저 decode. 미지원 숫자면 payload를해석하지않고 unsupportedVersion. JSON문법/version형식/지원payload필수필드·타입 오류는 corrupt, 도메인검증은 invalidState(reason). 원본변경 없음.

save순서 후보검증→기존파일load→완전JSON인코딩→상위폴더생성→atomicwrite. 후보 invalidState는그대로. 기존원본오류는 writeBlocked(원래issue)로보존. 보호원본이면 directory/write호출0회. 폴더생성은 save책임. 인코딩/폴더/write실패 writeFailed. 결정적encoder실패가없는값모델에encodingFailedcase/encoderDI추가안함. 원본먼저삭제금지. 단일운영writer 모델 하나; background writer/extension 없음. atomic은부분파일방지, 전원장애/다중writer보장아님.

## AppModel.swift

@MainActor @Observable final class AppModel.

- LaunchState: Equatable { loading, ready(LaunchRoute), failed(StorageIssue) }.
- Destination: Hashable { preparation, records, settings, profile }.
- private(set) var launchState: LaunchState = .loading.
- private(set) var snapshot: AppSnapshot? = nil.
- var path: [Destination] = [] (SwiftUI바인딩위해internalsetter).
- private(set) var saveFailure: StorageIssue? = nil.
- init(store: LocalSnapshotStore).
- loadIfNeeded() -> Void; save(_ candidate: AppSnapshot) -> Bool; open(_ destination: Destination) -> Void; goBack() -> Void.

모든메서드는 반환시반영완료 동기계약. loadIfNeeded 최초1회만시도, 이후no-op. 파일없음은메모리empty만/자동쓰기없음. 성공snapshot+ready(route), 실패snapshotnil/path[]/failed(issue).

save는 ready만시도. loading→false/saveFailure.notReady, failed→false/writeBlocked(originalIssue), 파일접근없음. 실패는snapshot/root/path유지. 성공후candidate와route반영/saveFailurenil. route바뀔때만path비움, 같은route성공시path유지. open은ready(main)만append, goBack은ready(main) && nonempty일때removeLast. 다른단계/loading/failed는no-op. 탐색은저장호출없음.

## FocusMateApp.swift 및 RootView.swift

App이 @State로단일model소유, RootView @Bindable var model으로같은인스턴스관찰, NavigationStack(path:$model.path). body에서모델재생성금지. 별도 @State시작가드로1회 startup MainActor: 가드설정→DEBUG seed→loadIfNeeded→선택적저장실패시험. seed/load중복없음.

운영Application Support URL조회 create:false. 조회실패는 unreadable 로딩실패저장소 구성, temporary우회없음. 실제폴더생성save에서만.

| 상태/항목 | 표시 | accessibilityIdentifier |
|---|---|---|
| loading | 불러오는 중 | screen.loading |
| cardEntry | 집중동행카드 | screen.cardEntry |
| initialStationEntry | 최초 정류장 설정 | screen.initialStationEntry |
| main | 현재 정류장 | screen.main |
| currentStation/direction | 저장 이름 / 정방향 또는 역방향 | main.currentStation / main.direction |
| destinations | 여행 준비 / 기록 / 설정 / 마이페이지 | screen.preparation / screen.records / screen.settings / screen.profile |
| main buttons | 각화면이름접근성label | open.preparation / open.records / open.settings / open.profile |
| 읽기오류화면/문구 | 아래종류별 | screen.storageError / storage.error |
| 저장실패 | 아래문구 | storage.saveFailure |

NavigationStack 기본뒤로/스와이프유지. 자동뒤로identifier설정위해시험버튼추가금지. XCUI navigationbar뒤로기본요소조회. 앱이소유하는뒤로가기가있을때만 navigation.back 사용.

unreadable: “저장된 데이터를 읽지 못했어요.”; corrupt: “저장된 데이터 형식을 읽을 수 없어요.”; unsupportedVersion: “이 버전의 앱에서 열 수 없는 데이터예요.”; invalidState: “저장된 이용 상태를 확인할 수 없어요.” 공통 “기존 데이터는 변경하지 않았어요.”. saveFailure: “저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요.”. 성공toast없음. 첫이용/설정/destination은기본진입안내뿐, 실제후속완료버튼없음.

## UITestBootstrap.swift — DEBUG 계약

파일전체 #if DEBUG. --fm-ui-test-id <UUID>, optional --fm-ui-seed <none|cardOnly|ready|corrupt|unsupported>, optional --fm-ui-save fail. testID없으면시험비활성. 잘못된UUID/seed/인자조합은시험준비실패로명시중단, 운영파일우회없음.

시험경로 Application Support/FocusMate/UITests/<UUID>/app-state.json. none은새UUID파일없음/삭제없음. seed는파일없는신규시험경로에만허용. 재실행은동일UUID/no-seed, seed재기록없음. cardOnly=(true,nil,nil). ready=(true, seongsu/성수/1, seoulForest/서울숲/-1).

지원seed는정상store.save로준비해폴더생성. rawseed는bootstrap이시험폴더준비후atomicwrite. corrupt 정확UTF8 {broken (newline없음); unsupported 정확UTF8 {"version":999,"state":null} (newline없음). 준비실패는harness오류, 제품RED아님.

--fm-ui-save fail은유효main에서만허용. seed는정상writer; 모델store.write closure만오류throw. load후card/initial유지,current=ttukseom/뚝섬/1 candidate를기존model.save로1회제출. prod시험전용메서드추가없음.

시험활성일때비시각접근성진단요소: test.snapshot value=현재AppSnapshot JSON 또는 null; test.persistedBytes value=실제시험파일Base64 또는 absent/unreadable. 접근성트리조회가능, hidden으로제거금지. JSON은decode후값비교. 진단은읽기만. Release는인자/seed/실패주입/진단요소전부없음.

## 검증 순서 및 경계

1. critic/testability보완 (의존:없음).
2. gx-dev빈앱+Unit/UI하네스빌드·2smoke 검증 (의존:1; 동작AC선구현없음).
3. 파일을공유하는AC1~4를루트동작RGR묶음으로실행 (의존:2). 최초UI테스트는prod타입import없어컴파일가능. 빈앱에서행동assertionRED목격후상태/store/model/root/bootstrap 최소GREEN. API미존재compile에러를행동RED로보고하지않음.
4. 필요시순수값·임시파일·모델단위회귀보강; UI 실제화면왕복 및terminate/launch로같은ApplicationSupport복원 (의존:3).
5. reviewer SPEC→QUALITY 및 security, 전체native+웹검증, 인수, 문서·커밋·PR (의존:4).

temporaryDirectory/새store읽기=roundtrip근거, 실제재실행과분리. closure실패검사=실패대응근거, Foundationatomic자체보장시험아님. 후속도메인완료상태표시없음; 지도/타이머/기록등다음phase유지. 실제검증기록전수용완료아님.

## 공식 근거와 승인

native-references.md Apple문서보강참고. 사용자의 “모두 진행” 승인으로범위내통상설계결정·하네스·RGR 진행. 신규범위나정책질문없음. critic/testability 2차 확인은 아래 평가에서 완료했다.


## Testability 평가 (test-architect)

2차 9/10 PASS. 이전 생성자·오류·Observation·폴더·DEBUG 계약 부족 해소. 플랫폼 UI/생명주기는 실제 통합 필요. 모든 native XCTest 번들은 배치됐고 이 평가는 실행 성공 판정이 아니다.

### 컴포넌트별 테스트 전략

- AppSnapshot: 레이어 동작; XCTest Unit. 세 route 및 불일치/빈정류장/방향 검증 순서. Codable값통합. 외부모의없음, 값객체격리. AC1/3/4.
- LocalSnapshotStore/StorageIssue: 레이어 동작; XCTest Unit. read/directory/write closure경계, 파일없음/읽기/폴더/쓰기 실패, version우선검사, blocked원인, 보호원본쓰기0회 및load쓰기0회. 실제임시파일roundtrip/원본bytes통합. JSON정책실제실행. AC1/3/4.
- AppModel: 레이어 동작; XCTest Unit. 최초load/no-op/ready전저장차단/실패불변/성공route별path/네화면왕복 저장0회. 실제store연결통합. MainActor각model격리. AC1/2/3/4.
- FocusMateApp/RootView: 레이어 동작; XCTest UI. 세루트/현재정류장방향/네화면왕복/오류/완료동작없음. actualapp+UUID시험파일. 접근성이름·text·필요시contractidentifier. 모델internal읽기/좌표/style검사금지. AC1/2/4.
- UITestBootstrap: 레이어 동작; XCTest Unit/UI. UUID/인자/새경로seed/재실행무쓰기, 실제sameID terminate/launch복원, rawBase64보존, 실패writer안내. 운영과UUID로격리, Releaseexclude. AC1/2/3/4.
- 표현스타일·아이콘·배지: 표현 — 검증대상밖.

### 판정

TESTABILITY PASS 9/10. 최초UI RED는 production타입import없이컴파일하고 빈앱 행동assertion실패로목격. 빌드/runner/seed준비오류는RED아님. 단위roundtrip은실제process재실행을대체하지않음.

## 설계 비판 검토 — 2차

critic의 이전 MUST3건(단일소유/폴더/오류) 모두해소, 새근본위반없음. singlewriter전제도해소. 설계에 근본적인 문제는 발견되지 않았습니다. 이는문서검토이며빌드성공판정아님.

## 진행 승인

사용자 “모두 진행”이 승인범위 내 후속설계·하네스·TDD·리뷰·검증 진행을포함하므로통상단계재승인없이진행한다. 제품범위확장없음.
