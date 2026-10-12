# T1: 앱 루트·저장·화면 연결 (P1-AC1~4 묶음)

동일 RootView/모델/DEBUGseed/프로젝트를 공유하므로 한 RGR 태스크로 묶는다. production 구현을 읽지 않고 실제 UI 관찰로 검증한다.

## 수용 기준

### P1-AC-1 — 진입 분기 (P1-FR-1, P1-FR-3)

Given: 저장 데이터가 없는 상태, 카드 발급 정보만 있고 `initialStation`이 없는 상태, 카드와 `initialStation` 및 현재 정류장이 저장된 상태가 각각 준비되어 있다.

When: 각 상태에서 앱을 실행한다.

Then: 첫 경우는 첫 이용/카드 발급 진입점, 둘째는 최초 정류장 설정 진입점, 셋째는 저장된 현재 정류장 값을 표시하는 메인이 열린다.

### P1-AC-2 — 기본 화면 왕복 (P1-FR-2, P1-BR-3)

Given: 저장된 현재 정류장과 출발 상태로 메인에 진입해 있다.

When: 여행 준비, 기록, 설정, 마이페이지를 하나씩 열고 각 화면에서 뒤로간다.

Then: 선택한 이름의 기본 화면이 열리고 이전 화면 또는 메인으로 복귀하며, 왕복 전후의 현재 정류장과 출발 상태 값이 같다. 이번 기본 진입 화면에는 카드 발급·최초 정류장 선택·여행·기록 등 후속 기능을 완료하는 사용자용 버튼이나 완료 동작이 나타나지 않는다.

### P1-AC-3 — 지원 상태 복원 (P1-FR-3)

Given: 지원 버전의 카드 발급 여부, `initialStation`, 현재 정류장 값이 준비되어 있다.

When: 상태를 저장하고 앱을 종료한 뒤 다시 실행한다.

Then: 세 값이 저장 전과 같고 그 값에 해당하는 진입 화면이 열린다.

### P1-AC-4 — 손상·미지원·저장 실패 (P1-BR-1, P1-BR-2)

Given: 손상된 원본 데이터, 미지원 버전 원본 데이터, 저장 실패 조건이 각각 준비되어 있다.

When: 앱이 원본을 읽거나 새 상태를 저장한다.

Then: 손상·미지원 원본은 삭제되거나 바뀌지 않고 오류가 보고되며, 저장 실패에는 성공 안내가 나타나지 않는다.


## UI 공개 관찰 계약


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


## DEBUG 입력 계약


파일전체 #if DEBUG. --fm-ui-test-id <UUID>, optional --fm-ui-seed <none|cardOnly|ready|corrupt|unsupported>, optional --fm-ui-save fail. testID없으면시험비활성. 잘못된UUID/seed/인자조합은시험준비실패로명시중단, 운영파일우회없음.

시험경로 Application Support/FocusMate/UITests/<UUID>/app-state.json. none은새UUID파일없음/삭제없음. seed는파일없는신규시험경로에만허용. 재실행은동일UUID/no-seed, seed재기록없음. cardOnly=(true,nil,nil). ready=(true, seongsu/성수/1, seoulForest/서울숲/-1).

지원seed는정상store.save로준비해폴더생성. rawseed는bootstrap이시험폴더준비후atomicwrite. corrupt 정확UTF8 {broken (newline없음); unsupported 정확UTF8 {"version":999,"state":null} (newline없음). 준비실패는harness오류, 제품RED아님.

--fm-ui-save fail은유효main에서만허용. seed는정상writer; 모델store.write closure만오류throw. load후card/initial유지,current=ttukseom/뚝섬/1 candidate를기존model.save로1회제출. prod시험전용메서드추가없음.

시험활성일때비시각접근성진단요소: test.snapshot value=현재AppSnapshot JSON 또는 null; test.persistedBytes value=실제시험파일Base64 또는 absent/unreadable. 접근성트리조회가능, hidden으로제거금지. JSON은decode후값비교. 진단은읽기만. Release는인자/seed/실패주입/진단요소전부없음.


## Testability

9/10 PASS. XCTest UI runner 구성·smoke2개통과, 현재별도전체기준선검증중. 최초테스트는 XCTest/XCUIApplication만사용하며제품Swift타입import없음. 모의UI·스타일·좌표·전제결과계산금지. Lifecycle은실제terminate→동일UUID/no-seedlaunch. UI재실행과단위roundtrip분리.

## 테스트 스타일 및 명령

파일 ios/FocusMateUITests/Phase1FlowTests.swift, XCTestCase/@MainActor, 각test당UUID격리. FocusMate.xcodeproj는자동Swift파일발견. focused=FOCUSMATE_SIMULATOR_ID=529B88AF-5286-43EA-938A-4233F6B226CD FOCUSMATE_DERIVED_DATA=/tmp/focusmate-phase1-derived python3 scripts/check-ios.py test ios/FocusMateUITests/Phase1FlowTests.swift. 기존style: ios/FocusMateUITests/HarnessUITests.swift(테스트라열람가능).
