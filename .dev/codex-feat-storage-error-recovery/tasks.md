# W13 RGR 태스크

사용자 “다음 작업 진행해”의 TDD 구현 진행 승인에 따라 설계 범위 안의 실행 단위를 확정한다.

| 태스크 | AC | 테스트 | 구현 파일 |
|---|---|---|---|
| T1 저장 복구 | AC-4~8 저장 경계 | StorageRecoveryTests.swift | LocalSnapshotStore.swift |
| T2 복구 상태 | AC-1~8 상태 전이 | AppRecoveryTests.swift | AppModel.swift |
| T3 복구 화면·시험 환경 | AC-1~7 사용자 흐름 | StorageRecoveryFlowTests.swift / RecoveryBootstrapTests.swift | RootView.swift / UITestBootstrap.swift |

T1 → T2 → T3 순차. 동일 컴포넌트의 AC를 묶고 태스크끼리 파일을 겹치지 않게 한다. 기존 XCTest helpers는 수정하지 않고 신규 테스트 파일별 helper를 사용한다. 테스트 코드부터 작성, 미존재 인터페이스의 컴파일 오류는 assertion RED와 구별하며 선언만 확보한 뒤 동작 실패를 직접 확인한다. focused 대상은 클래스명과 같은 파일명을 사용한다.
