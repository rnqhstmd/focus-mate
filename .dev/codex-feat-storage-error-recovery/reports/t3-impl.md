# T3 구현 검증

RootView 복구 원인·재시도·명시적 확인/취소·원본보존후정리·실패 설명을 연결했다. ScrollView, 시스템 글자, 버튼 최소높이44, AccessibilityFocusState 적용. DEBUG Bootstrap은 실제 파일을 유지하면서 readOnce/readAlways/backupFail/backupMismatch/cleanupFail 경계만 대체한다.

부모 직접 검증: t3-green-final.log, 2026-10-13 21:55:09 KST, Unit41+UI9=50 tests /0 failures, exit0. 신규 RecoveryBootstrap7 + StorageRecoveryFlow9. unknown옵션 테스트 helper의 잘못된 nested XCTUnwrap은 RED작성자가 고쳤다. 최대글자는 UIKit공식rawValue 사용 및 DEBUG environment accessibility5 확인; 진단누락 UI RED1건을 직접 확인하고 구현했다(t3-font-red.log).

T1/T2 테스트 무변경. T3 수정된 테스트 기준해시는 t3-unit-test.sha/t3-ui-test.sha. 실제 VoiceOver 포커스/실기기/프로세스종료 내구성은 확인하지 않음. 동작변경 없는 추가리팩터 필요 없음. T3 생산2파일이므로 태스크리뷰 수행.
