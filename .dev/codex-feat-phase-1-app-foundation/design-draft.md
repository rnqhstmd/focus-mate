# 설계 초안: Phase 1 iOS 앱 기반

작성: 2026-10-13, oh-my-gx:architect. 상태: 비판 검토·testability 평가 전. 네이티브 구현/실행 증거 없음.

## 설계 규모

대형 — 앱·단위/UI 테스트 타깃, 진입·탐색·파일 저장 경계를 새로 만든다. 범위는 승인 Phase 1만이다.

## 배경 및 목적

SwiftUI, 최소 iOS 17 기준으로 이용 단계에 맞게 시작하고 기본 화면을 왕복하며 종료 후 상태를 복원한다. 읽기·쓰기 실패와 손상·미지원 데이터를 초기 상태로 오인하지 않는다. 현재 감지 타입은 Node이며 아래는 향후 네이티브 구조다.

## 요구사항 및 수용 기준

[승인 PRD](prd.md)의 P1-FR-1~3, P1-BR-1~3과 P1-AC-1~4를 그대로 적용한다. 저장 없음→카드 진입, 발급만→최초 정류장 진입, 설정 완료→현재 정류장 메인. 네 기본 화면 왕복은 저장 상태를 바꾸지 않는다. 지원 상태 복원, 손상/미지원 원본 보존, 저장 실패의 정확한 안내가 필수다. 실제 후속 기능 완료 동작은 제공하지 않는다.

## 변경 범위

| 구분 | 경로 | 역할 |
|---|---|---|
| 신규 | ios/FocusMate.xcodeproj/project.pbxproj 및 공유 scheme | 앱·단위/UI 테스트 타깃 |
| 신규 | ios/FocusMate/FocusMateApp.swift | 구성·운영 저장 경로·루트 연결 |
| 신규 | ios/FocusMate/AppSnapshot.swift | 상태·버전·진입 분기·유효성 |
| 신규 | ios/FocusMate/LocalSnapshotStore.swift | JSON 읽기·검증·원자적 저장 |
| 신규 | ios/FocusMate/AppModel.swift | 로딩·상태·경로·오류 |
| 신규 | ios/FocusMate/RootView.swift | 루트 및 기본 destination |
| 신규 | ios/FocusMateTests/ | 상태·저장·모델 검사 |
| 신규 | ios/FocusMateUITests/ | 화면 왕복·종료/재실행 검사 |
| 신규 | ios/FocusMate/UITestBootstrap.swift | DEBUG 시험 경로·seed |
| 수정 | .gitignore, README.md | Xcode 산출물·실행 안내 |
| 수정 | .claude/config.json | 실제 하네스 확정 후 native 검증 명령 |

프로젝트에 필요한 최소 리소스만 추가한다. 범용 Repository/Service, 도메인별 패키지, 외부 라이브러리는 추가하지 않는다.

## 적용 컨벤션

- Focus Mate, 집중동행카드 용어 유지. 타입/파일 UpperCamelCase, 멤버 lowerCamelCase.
- Foundation 상태/저장은 뷰와 분리. 모델·뷰 변경은 @MainActor에서 직렬 처리.
- XCTest 번들 및 @testable import FocusMate. 외부 공개 패키지 API 불필요.
- try?로 오류를 초기 상태로 삼키지 않는다. 웹 npm 명령과 native 증거는 별도로 기록한다.

## 상세 설계

### 1. 프로젝트와 빈 하네스

현재 native 타깃·scheme·Simulator 실행 근거가 없다. iOS 17 SwiftUI 앱, Unit/UI Testing Bundle, 공유 FocusMate scheme을 만든다. gx-dev 부트스트랩은 빈 앱·테스트 연결만 수행하고 진입 분기·snapshot·저장·destination 등 수용 동작을 선구현하지 않는다. 사용자 약관 처리 후 SDK/Simulator 준비와 하네스 실행부터 확인한다.

### 2. AppSnapshot.swift

- SnapshotEnvelope: version: Int(현재 1), state: AppSnapshot.
- AppSnapshot: cardIssued: Bool, initialStation: StationSnapshot?, currentStation: StationSnapshot?.
- StationSnapshot: id: String, name: String, direction: TravelDirection.
- TravelDirection: forward = 1, reverse = -1. 기존 웹 방향 값 유지.
- LaunchRoute: cardEntry, initialStationEntry, main.
- 인터페이스: AppSnapshot.validate() throws -> Void; launchRoute() throws -> LaunchRoute.

유효 조합은 (false,nil,nil), (true,nil,nil), (true,station,station) 세 구조다. 마지막의 최초/현재 정류장은 달라도 된다. 정류장 ID·이름은 trim 후 비어 있으면 안 된다. 정의되지 않은 방향이나 나머지 상태 조합은 invalidState다. 카드 ID/외형/발급일은 이번 모델에 넣지 않는다. 출발 상태는 정류장 및 방향으로 나타내고 중복 departureStation 필드는 만들지 않는다.

### 3. LocalSnapshotStore.swift

Application Support/FocusMate/app-state.json에 버전 JSON을 Data.write(to:options:.atomic)으로 기록한다. 초기 UserDefaults 제안과 달리 쓰기 실패를 throw 가능한 경계로 표현한다.

- init(fileURL: URL, readData: (URL) throws -> Data, writeData: (Data, URL) throws -> Void)
- load() throws -> AppSnapshot?
- save(_ snapshot: AppSnapshot) throws -> Void

운영 initializer의 closure 기본값은 Foundation 읽기·원자적 쓰기다. 읽기/쓰기 실패 시험을 위해 두 작은 경계만 주입한다. 오류는 unreadable, corrupt, unsupportedVersion(Int), invalidState, encodingFailed, writeFailed, writeBlocked다.

파일 없음만 nil이며 접근 권한·읽기 실패는 미설정으로 처리하지 않는다. version을 먼저 확인하고 지원 버전 payload만 decode/validate한다. 잘못된 JSON·version 형식·필수 필드·도메인 상태·미지원 버전은 원본을 변경하지 않는다.

save는 후보를 검증하고 현재 파일을 다시 읽어 보호 여부를 확인한다. 손상·미지원·읽기 실패면 쓰기 차단. 유효 기존 파일 또는 파일 없음일 때만 완전 인코딩 후 atomic 교체. load 경로는 디렉터리나 기본 파일을 생성하지 않는다. 자동 삭제·복구·마이그레이션·웹 데이터 가져오기는 제공하지 않는다. atomic은 부분 파일 방지이며 전원 손실 내구성 보장은 아니다.

### 4. AppModel.swift

- init(store: LocalSnapshotStore)
- load() -> Void
- save(_ candidate: AppSnapshot) -> Bool
- open(_ destination: Destination) -> Void
- goBack() -> Void

관찰 값: launchState, snapshot, path: [Destination], saveFailure. launchState = loading / ready(LaunchRoute) / failed(StorageIssue). Destination은 여행 준비·기록·설정·마이페이지 Hashable enum.

파일 없음은 메모리의 빈 상태로만 첫 진입 표시. 시작만으로 저장하지 않는다. load 실패는 오류 화면, 저장 차단. save 성공 후에만 snapshot과 진입 상태 반영. 실패 시 이전 snapshot·루트·경로 유지, “저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요.” 안내. 별도 성공 안내는 필수 아님. open/goBack은 메인 화면 경로만 바꾸며 저장 호출 없음.

### 5. RootView.swift

NavigationStack(path:)과 값 기반 navigationDestination 사용. 경로는 영속 저장하지 않고 재실행은 이용 단계의 루트부터 시작한다.

- 첫 이용: 카드 진입 제목·안내만.
- 최초 정류장 설정: 단계 제목·안내만.
- 메인: 현재 정류장 이름·방향 및 네 이동 항목.
- 기본 destination: 선택한 화면 이름과 뒤로가기.
- load 실패: 종류별 오류 안내, 초기화/재발급/가짜 완료 버튼 없음.

지도·카드 발급·정류장 선택·여행 시작·기록 작성 기능은 이번에 구현하지 않는다.

### 6. 시험 입력 및 검증 경계

UITestBootstrap은 #if DEBUG와 UI 시험 활성화 인자+UUID가 함께 있을 때만 동작. 운영과 분리된 Application Support/FocusMate/UITests/<UUID>/app-state.json으로 한정.

seed = none/cardOnly/ready/corrupt/unsupported. ready는 최초 seongsu/성수/forward, 현재 seoulForest/서울숲/reverse로 최초·현재 혼동을 잡는다. cardOnly=(true,nil,nil). 지원 seed는 운영 저장 API로 기록한다. 손상/미지원 원시 바이트 준비는 시험 코드에만 둔다.

첫 실행만 seed를 지정하고 terminate/launch 재실행은 동일 UUID와 경로만 전달한다. 재실행 때 재기록 금지. 단위 검사: 상태 조합·왕복 불변·원본 바이트·save 실패 snapshot/path 불변. 임시 실제 파일 및 새 저장소 인스턴스는 round-trip 근거. 프로세스 복원은 앱 종료/재실행 UI 검사로 별도 확인한다.

## 의존성 및 영향도

외부 의존성 없음. SwiftUI·Foundation·XCTest 사용. Apple 공식 근거는 native-references.md에 정리했고 atomic/Application Support 근거도 document-specialist가 보강했다.

### 기존 구조와의 차이

4개 context 도메인은 개념 경계라 물리 패키지로 분리하지 않는다. issuedPass 전체 모델 대신 cardIssued만 준비. activeJourney/checkpoint·기록 생성/집계·설정 영속화는 후속. 웹 loadLocation/saveLocation의 오류 삼킴을 이식하지 않고 승인 PRD에 따라 오류 명시. 웹 파일/저장 키 변경 없음.

## 구현 순서

1. [Must] 설계·테스트 가능성·공식 근거 확정 (의존: 없음).
2. [Must] 사용자 약관 처리 후 SDK/Simulator 확인 및 별도 빈 하네스 구축 (의존: 1). smoke 통과는 AC 완료 아님.
3. [Must] 상태·저장 AC 테스트 작성 (의존: 2). API 미존재 컴파일 오류는 행동 RED 아님. 실행된 기대값 실패를 확인해야 구현 진입.
4. [Must] AppSnapshot·LocalSnapshotStore 최소 GREEN (의존: 3).
5. [Must] AppModel load/save/왕복 RED→GREEN (의존: 4).
6. [Must] RootView/DEBUG 시험 bootstrap 연결 및 화면/재실행 검사 (의존: 5).
7. [Must] 필요한 정리·리뷰·native 검증·웹 회귀와 문서 갱신 (의존: 6).

라이선스 exit 69·SDK 부재·러너 미실행·프로젝트 오류는 환경 문제이며 behavioral RED가 아니다. 모든 native 검증은 예정 상태다.

## 탐색 추가 항목

.claude/config.json:52, package.json:8, docs/FLOWS.md:7 및 :34, docs/CURRENT-STATE.md:7, docs/DEVELOPMENT-PHASES.md:17, context/card/glossary.md:7, context/journey/architecture.md:7, context/preferences/architecture.md:3, designs/final/animation-preview.html:400 및 :718을 참고했다. 코드맵에는 관련 상위 파일을 누적한다.

## 확인이 필요한 사항

추가 확인 사항 없음. 설계가 완료되었습니다.

이는 architect 초안 완료 판정이며 비판 검토·testability 평가 및 구현 검증 완료를 의미하지 않는다.
