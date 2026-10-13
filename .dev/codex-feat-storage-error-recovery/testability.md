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
