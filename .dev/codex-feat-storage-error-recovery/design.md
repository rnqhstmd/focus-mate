# 설계: W13 저장 오류 복구

상태: 사용자 “다음 작업 진행해”로 승인됨.

## 설계 규모
중형 — 기존 저장소·시작 상태·오류 화면을 확장하며 저장 스키마와 도메인 구조를 유지한다.

## 배경 및 목적
확정 PRD는 `prd.md`다. 읽기 실패로 시작이 차단된 사용자에게 원본을 수정하지 않는 재시도와, 명시적 확인 후 동일 바이트를 앱 내부에 보존해야 가능한 정리를 제공한다. 외부 내보내기·공유는 제외한다.

## 요구사항 및 수용 기준
- FR-4a: 오류 원인·재시도·정리 → AC-1.
- FR-4b: 재읽기 성공/최신 실패 → AC-2·3.
- FR-4c: 안내·확인·취소 → AC-4·5.
- FR-4d: 동일 바이트 내부 백업 확인 후 활성 정리 → AC-5·6.
- FR-4e: 보존·정리 실패 시 성공 금지 → AC-3·6·7.
- BR-1·2: 재시도·확인 진입·취소는 원본 불변, 명시적 확인 필수.
- BR-3·5: v1·v2 읽기/v2 저장·기존 첫 시작 경험 → AC-2·5·8.
- BR-4·6: 백업 검증 전 삭제 금지·내부 보존만 → AC-5·6·7.
- GWT 전문은 prd.md AC-1~8을 따른다.

## 변경 범위
운영 수정: `ios/FocusMate/{LocalSnapshotStore,AppModel,RootView,UITestBootstrap}.swift`.
신규 테스트: `ios/FocusMateTests/StorageRecoveryTests.swift`.
테스트 수정: `ios/FocusMateTests/{AppFoundationTests,StorageV2Tests,StorageTestSupport}.swift`, `ios/FocusMateUITests/Phase1FlowTests.swift`.
`SnapshotCodec.swift`, `AppSnapshot`, 저장 영역 구조는 변경하지 않는다. pbxproj의 파일 시스템 동기화 그룹으로 테스트 등록 변경은 불필요하다.

## 적용 컨벤션
Swift 5·iOS17+, Foundation/SwiftUI/Observation/XCTest. AppModel의 MainActor/Observable/private(set), 저장소 closure DI, Error/Equatable enum, 임시 파일·@testable import를 유지한다. 도메인 용어·기존 복구 경계는 context/preferences/glossary.md와 architecture.md를 따른다. 새로운 서비스·프로토콜·외부 의존성 없음.

## 상세 설계
### LocalSnapshotStore.swift
StorageIssue 기존 계약은 유지하고 internal 값 enum을 같은 파일에 추가한다.
```swift
enum RecoverySource: Equatable { case bytes(Data), unreadable, missing }
enum StorageRecoveryIssue: Error, Equatable {
    case backupFailed, cleanupFailed, sourceChanged, sourceMissing, notRequired
}
```
- backupFailed: 원본 읽기·백업 쓰기·백업 재읽기·동일 바이트 확인 실패.
- cleanupFailed: 검증 백업 이후 원본 재확인·제거·제거 완료 확인 실패.
- sourceChanged: 확인 진입 때 원본과 실행 원본 또는 백업 이후 원본이 다름.
- sourceMissing: 실행 중 활성 원본 없음. 정리 성공으로 취급하지 않음.
- notRequired: 현재 파일이 정상 v1/v2. 삭제하지 않고 다시 시도로 갱신 안내.

기존 init 인자 뒤에 기본값 있는 closure DI를 추가한다.
```swift
backupID: @escaping () -> UUID = UUID.init
writeBackup: @escaping (Data, URL) throws -> Void
    = { try $0.write(to: $1, options: .withoutOverwriting) }
removeData: @escaping (URL) throws -> Void
    = { try FileManager.default.removeItem(at: $0) }
func recoverySource() -> RecoverySource
func backupAndClear(expectedSource: RecoverySource) throws -> URL
```
recoverySource는 활성 파일 읽기만 수행하며 바이트·없음·읽기 실패를 반환한다.
백업은 활성 파일의 앱 내부 디렉터리에 `app-state.recovery-<UUID>.backup`. backupID는 시도당 1회, 새 확인은 새 ID. 기존 백업 충돌 시 덮어쓰기·삭제 없이 backupFailed. withoutOverwriting은 atomic과 조합하지 않는다. 공식 API 근거: foundation-api-evidence.md 및 https://developer.apple.com/documentation/foundation/nsdata/writingoptions/withoutoverwriting.

#### 확인 후 실행 순서
1. 원본 재읽기: 없음→sourceMissing, 읽기 실패→backupFailed.
2. expected bytes면 원본과 비교: 변경→sourceChanged.
3. expected missing인데 파일 등장→sourceChanged.
4. expected unreadable이면 현재 확보한 바이트 사용. 이전 읽기 불가 바이트와 동일하다고 주장하지 않음.
5. SnapshotCodec.decode 성공하는 정상 v1/v2면 notRequired, 삭제 0회.
6. corrupt/unsupportedVersion/invalidState만 다음 단계.
7. 원본 바이트를 writeBackup으로 기록. 활성 파일 writeData는 호출하지 않음.
8. readData(backupURL)와 원본 Data 정확한 동등성 확인.
9. 활성 원본 재읽기·비교: 변경→sourceChanged, 없음→sourceMissing, 읽기 실패→cleanupFailed.
10. 모두 검증한 뒤 removeData(fileURL), throw→cleanupFailed.
11. 활성 파일 읽기가 fileReadNoSuchFile인지 확인. 파일이 남거나 다른 오류→cleanupFailed.
12. 성공 시에만 내부 백업 URL 반환.

#### 실패·반복·원자성
- 1~8 실패는 삭제 호출 0회. 불완전 백업이 남을 수 있지만 원본 유지.
- 실패 산출물·기존 백업 자동 정리는 범위 밖. 다시 정리하려면 새 확인·새 ID.
- 성공 후 직접 재호출은 원본 없음으로 실패하며 백업·성공 결과를 만들지 않음.
- MainActor에서 await 없는 동기 작업, 현재 앱 단일 작성자 경계.
- 최종 비교와 삭제는 파일 시스템 트랜잭션이 아님. 외부 프로세스 경쟁 쓰기 보호는 보장하지 않음.
- 중단이 삭제 전이면 원본과 백업/부분 백업, 삭제 후이면 검증 백업이 남음. 전원 손실 내구성 별도 보장 없음.

### AppModel.swift
loadIfNeeded 1회 시작 계약 유지, 공통 읽기를 private 처리로 추출.
```swift
private(set) var recoveryFailure: StorageRecoveryIssue?
private(set) var isRecovering: Bool
var isCleanupConfirmationPresented: Bool { get }
func retryLoad()
func requestCleanup()
func cancelCleanup()
@discardableResult func confirmCleanup() -> Bool
```
초기값 failure=nil, recovering=false, confirmation=false. private cleanupSource: RecoverySource? 존재 여부가 확인 표시를 결정한다.
- retryLoad: failed이며 확인·실행 중 아니어야 동작. 성공은 기존 launchRoute, 실패는 최신 StorageIssue·snapshot nil·path []. 쓰기·백업·삭제 0회. 원본 없음은 기존 nil load→empty/cardEntry 계약.
- 새로운 재시도 시작과 정리 확인 진입 시 recoveryFailure=nil로 해제하여 이전 실패 안내가 최신 읽기 결과와 섞이지 않게 한다.
- requestCleanup: failed이고 다른 복구·확인 없을 때 recoverySource 캡처. 쓰기·삭제 없음. unreadable/missing도 안내와 확인·취소 제공; 실행 시 재판정.
- cancelCleanup: 캡처만 해제. 시작 오류·원본·백업·경로 불변.
- confirmCleanup: failed·유효 캡처·!recovering 필요. 아니면 false/I/O0회. 캡처 소비 후 recovering=true, 중복/재진입 차단.
- 성공만 snapshot empty, ready(cardEntry), path [], saveFailure/recoveryFailure nil.
- 실패는 기존 failed/snapshot nil 유지하며 recoveryFailure 기록. 종료에 recovering=false 보장. 새 확인·재시도 가능.
- 정상/loading recovery API는 I/O없이 종료. 복구 중 save·다른 복구도 차단.

### RootView.swift
오류 콘텐츠를 ScrollView 세로 구성으로 만들어 큰 Dynamic Type에서 버튼 접근 보장.
- 기본: 기존 원인 + 다시 시도 + 저장 데이터 정리.
- 확인: 같은 오류 분기에서 교체 표시, 별도 라우터/modal 상태 없음.
- 안내: 카드·여행·기록 초기화, 같은 원본을 내부 보존 확인한 뒤 정리함을 설명.
- 확인 destructive 버튼 `원본 보존 후 정리`, 취소 버튼 `취소`.
- IDs: storage.retry, storage.cleanup, storage.cleanupConfirmation, storage.confirmCleanup, storage.cancelCleanup, storage.recoveryFailure. 기존 screen.storageError/storage.error 유지.
- backupFailed: 원본을 보존하지 못해 정리 미완료 안내.
- cleanupFailed: 원본 내부 보존은 됐으나 정리 완료 확인 실패 안내.
- sourceChanged/sourceMissing/notRequired: 변경/없음/정상화 각각 안내, 다시 시도로 갱신.
- 복구 실패 뒤에는 `기존 데이터는 변경하지 않았어요`를 일괄 표시하지 않음. 삭제 후 확인 실패·외부 변경의 잘못된 보장 방지.
- VoiceOver header trait, 확인·취소·실패 시 제목/안내 접근성 포커스.
- 시스템 글꼴·가변 높이·충분한 터치 영역·줄 수 제한 없음. 사용자 지정 애니메이션 추가 없음.

### UITestBootstrap.swift (DEBUG만)
기존 UUID별 테스트 파일·save fail·무재시드 재실행 유지.
- --fm-ui-recovery: readOnce/readAlways/backupFail/backupMismatch/cleanupFail.
- readOnce: 활성 첫 읽기만 실패, 실제 원본 불변. readAlways: 활성 읽기만 실패.
- 나머지 옵션은 해당 backup/remove closure만 주입.
- --fm-ui-seed invalidState: 읽히지만 단계 불일치 v1 fixture.
- backupBytes: 백업 파일명→base64의 JSON 문자열, 없음은 {}.
- RootView DEBUG 진단 test.backups로 실제 내부 백업 노출. Release 포함 금지.

## 의존성 및 영향도
외부 의존성 없음. StorageIssue/SnapshotCodec/v1변환/v2쓰기/기존 저장 차단 유지. 백업은 load의 입력이 아니며 정리 후 empty를 디스크에 저장하지 않아 활성 파일은 없다. 백업 복원 UI·자동 삭제·파일 시스템 전체 트랜잭션은 제외.

## 구현 순서 (초안)
동일 파일 변경 단계는 의존 순서를 따른다. 각 AC에서 RED→GREEN→필요 REFACTOR.
1. AC-1 오류4종 선택지/자동실행없음: 모델/UI/DEBUG seed (없음).
2. AC-2 재시도 성공·쓰기0회: 모델/UI readOnce (1).
3. AC-3 최신 실패·시작차단·쓰기삭제0회: 모델 (2).
4. AC-4 확인·취소·원본백업불변: 모델/UI (3).
5. AC-5 백업검증→삭제→첫시작·재실행: 저장소/모델/UI (4).
6. AC-6 읽기/쓰기/readback/불일치/충돌 실패·삭제0회: 저장소/모델/UI (5).
7. AC-7 삭제·삭제확인실패·백업유지·성공금지: 저장소/모델/UI (6).
8. AC-8 v1/v2/정수범위/문자열버전 회귀: StorageV2Tests/모델/UI (7).
- 정상 API 호출·원본변경/소실·재진입/반복·실패 후 확인은 AC-4~7 경계 테스트에 포함.
- StorageRecoveryTests 클래스=파일명. StorageTestSupport는 오류 비교 헬퍼만 필요시 추가.
- 컴파일 RED와 실제 동작 RED를 구분. 구현 단계의 태스크 분해는 같은 파일·컴포넌트 AC 묶음 규칙 적용 필요.
- focused 명령: FOCUSMATE_SIMULATOR_ID=EC533489-C7FF-4620-B46D-E3D8461427DB python3 scripts/check-ios.py test [파일들].
- 최종 전체 iOS·웹 회귀. 이 설계 단계에서 실행하지 않음. baseline.md에 iOS26.5 Unit63/UI11, 웹31+edge PASS. iOS27 러너 환경 문제 유예.

## 탐색 추가 항목
- ios/FocusMate/FocusMateApp.swift:48 → 시작·DEBUG prepare
- ios/FocusMateTests/AppFoundationTests.swift:308 → 실패 후 저장 차단
- ios/FocusMateUITests/Phase1FlowTests.swift:91 → 오류·원본·재실행
- ios/FocusMate.xcodeproj/project.pbxproj:24 → 동기화 그룹
- scripts/check-ios.py:35 → 테스트 파일명/클래스 선택
- .dev/feat-domain-storage-schema-v2/design.md → 손상 미래형식 인계

## 확인이 필요한 사항
추가 확인 사항 없음. 설계가 완료되었습니다.

## 격리 RED 입력: 기존 인터페이스 계약
생산 구현 본문은 전달하지 않고 다음 선언·값 계약과 기존 테스트 스타일만 전달한다.
- LocalSnapshotStore 기존 init: fileURL: URL, readData: @escaping (URL) throws -> Data, createDirectory: @escaping (URL) throws -> Void, writeData: @escaping (Data, URL) throws -> Void. fileURL 이외 모두 기본값 있음. 새 backupID/writeBackup/removeData 인자를 끝에 추가하며 기본값 있음.
- LocalSnapshotStore: let fileURL: URL, func load() throws -> AppSnapshot?, func save(_ snapshot: AppSnapshot) throws.
- StorageIssue: unreadable, corrupt, unsupportedVersion(Int), invalidState(SnapshotValidationIssue), writeFailed, writeBlocked(StorageIssue), notReady; Error/Equatable.
- LaunchState: loading, ready(LaunchRoute), failed(StorageIssue); Equatable.
- LaunchRoute: cardEntry, initialStationEntry, main; Equatable.
- AppModel는 @MainActor, init(store: LocalSnapshotStore), loadIfNeeded(), save(_ candidate: AppSnapshot) -> Bool, open(_ destination: Destination), goBack(). 관찰 가능 상태 launchState/snapshot/path/saveFailure와 본문의 신규 복구 상태.
- StationSnapshot는 Codable/Equatable, init(id: String, name: String, direction: Int). 방향 ±1.
- AppSnapshot는 Codable/Equatable, static let empty: AppSnapshot, updatingStage(cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?) -> AppSnapshot. 전체 생성자는 private이므로 호출 금지.
- SnapshotValidationIssue: inconsistentStage, emptyStationID, emptyStationName, invalidDirection(Int); Error/Equatable.
- SnapshotCodec: static func decode(_ data: Data) throws -> AppSnapshot; static func encode(_ snapshot: AppSnapshot) throws -> Data.
- XCTestCase 기존 헬퍼: static func stage(_ issued: Bool, _ initial: StationSnapshot?, _ current: StationSnapshot?) -> AppSnapshot; withTemporaryFile(_ operation: (URL) throws -> Void) throws; assertStorageIssue(_ expected: StorageIssue, _ message: String = "", file: StaticString = #filePath, line: UInt = #line, operation: () throws -> Void).
- helper는 production 소스가 아닌 StorageTestSupport.swift에서 읽기 허용. 기존 테스트 스타일·fixture도 읽기 허용. 신규 test 클래스명과 파일명을 맞춰 focused runner에 전달한다.

## Testability 평가

### 컴포넌트별 테스트 전략

#### LocalSnapshotStore
- 레이어: 동작.
- 러너: FocusMateTests XCTest, 신규 StorageRecoveryTests 파일·동명 클래스.
- 단위: 원본 관찰·확인 비교·정상 파일 보호·오류 종류·I/O 회수.
- 모의 대상: readData/writeBackup/removeData/backupID/writeData 외부 파일 경계. Codec·복구 알고리즘은 모의하지 않는다.
- 통합: 테스트별 실제 임시 디렉터리, 기본 Foundation I/O, 정확한 백업 바이트·원본 제거·새 저장소 load nil.
- 실패: 원본/백업 읽기·백업 쓰기·readback 불일치·충돌·remove throw/no-op·삭제 후 확인 실패.
- 캡처: 변경·소실·unreadable에서 읽기 가능·missing에서 새 파일·정상화 파일.
- AC 매핑: AC-4~7 중심, AC-1~3 무변경, AC-8 회귀.

#### AppModel
- 레이어: 동작.
- 러너: @MainActor XCTest 메서드.
- 단위: 실제 저장소에 I/O closure만 주입하고 관찰 상태·반환값 확인.
- 재시도 실제 성공·최신 오류·nil snapshot·빈 path·쓰기삭제 0회.
- 확인·취소·파일백업 불변, 확인없음/loading/ready/성공후 반복 API 거부.
- I/O closure 안 재진입에서 복구/save 차단 및 I/O 증가 없음.
- 실패 종료 confirm false·failed 유지·recovering false·recoveryFailure, 새 retry/request에서 안내 해제.
- 통합: 실제 정리 후 새 모델·저장소에서 empty/cardEntry.
- AC 매핑: AC-1~8.

#### RootView
- 레이어: 동작(오류·버튼·확인취소·실패·화면 이동) / 표현(색·폰트수치·여백·배치).
- 표현은 TDD 범위 밖이며 감점하지 않음.
- 러너: FocusMateUITests/Phase1FlowTests, 실제 XCUIApplication 하네스 있음.
- 셀렉터: 보이는 버튼 이름, 기존 accessibilityIdentifier 관례. SwiftUI 내부 상태·뷰 구조 assert 금지.
- UI 탭으로 오류4종·재시도·확인취소·성공·백업실패·정리실패 검증.
- 파일 결과: test.persistedBytes와 test.backups 실제 디스크 결과 병행 검증.
- 접근성: 큰글자 스크롤·버튼작동 가능. VoiceOver 실제 포커스 이동은 직접 확인 증거 별도 필요.
- AC 매핑: AC-1~8 화면 계약.

#### UITestBootstrap / DEBUG 진단
- 레이어: 동작.
- 러너: XCTest 인자/fixture/직렬화 + XCUI 실제 앱 경로.
- 모의: 파일 I/O closure만 대체, 운영 복구 알고리즘 사용.
- readOnce는 첫 활성 읽기만 실패 후 실제 읽기; backupMismatch는 다른 바이트를 실제 백업에 기록하여 기본 readback이 실패하도록 함.
- 격리: UUID별 파일, 재실행 seed/failure 옵션 제거, 진단은 실제 백업 바이트.
- AC 매핑: AC-1~7 UI 지원, AC-8 전체 행렬은 저장소 담당.

#### SnapshotCodec / 기존 저장 계약
- 레이어: 동작, 변경 없음.
- 러너: 기존 StorageV2Tests/AppFoundationTests.
- v1/v2·음수/0/3이상·문자열 버전을 실제 decode/load, Codec 모의 없음.
- AC 매핑: AC-8 및 notRequired 보호.

### 격리 RED 입력 조건
설계 부록의 기존 생성자·LaunchState/Route·StorageIssue·SnapshotValidationIssue·AppModel·AppSnapshot 선언과 테스트 헬퍼를 전달한다. AppModel 초기값 loading/snapshot nil/saveFailure nil/path []. loadIfNeeded로 시작. AppSnapshot 전체 init private, updatingStage 사용. withTemporaryFile은 미생성 중첩 URL을 전달하므로 테스트가 부모 디렉터리 생성. 테스트 스타일은 Foundation/XCTest/@testable import, 모델 메서드는 MainActor, 고정 JSON과 실제 바이트 비교.

### Testability Score: 8/10

### 판정
TESTABILITY PASS. closure 경계·실파일 통합·기존 XCUI로 모든 AC 동작 관찰 가능.
- 신규 API 미존재 컴파일 RED와 실제 동작 RED를 구분한다.
- check-ios.py는 파일stem=테스트클래스. StorageTestSupport.swift는 focused 대상으로 전달하지 않는다.
- 실행 명령: FOCUSMATE_SIMULATOR_ID=EC533489-C7FF-4620-B46D-E3D8461427DB python3 scripts/check-ios.py test [실제 테스트 파일].
- 기존 baseline 기록 Unit63/UI11·웹31+edge PASS를 읽었으며 평가 역할은 직접 실행하지 않음.
- iOS27 runner 연결전 kill 원인은 미확정.
- 동일 파일·컴포넌트 AC는 실제 RGR 태스크로 묶는다.
