# 전체 mechanical gate — 2026-10-13

부모가 설정된 명령을 직접 실행했고 각 exit0을 확인했다. node와 ios-swiftui를 모두 검사했다.

|대상|실행|결과|
|---|---|---|
|web build|npm run build|exit0|
|web test|npm test|Node31 tests/0 failures + VM edge26 PASS 항목, exit0|
|native build|python3 scripts/check-ios.py build|exit0|
|native test|python3 scripts/check-ios.py test|Unit15(제품14+smoke1)/UI11(제품10+smoke1), 합계26 tests/0 failures, exit0|

Simulator는 iPhone18Pro/iOS27, UUID529B88AF-5286-43EA-938A-4233F6B226CD다. FOCUSMATE_DERIVED_DATA=/tmp/focusmate-phase1-derived와 FOCUSMATE_SIMULATOR_ID 환경 변수로 동일 runner를 실행했다.

로그: /tmp/focusmate-review-{web|ios}-{build|test}.log. native test의 기존 AppIntents metadata 경고1건, build0건. 기존 baseline3 이하이며 신규 Swift 경고는 없다.

추가 Release generic Simulator build도 exit0이다. Release 바이너리 strings에서 --fm-ui-test-id/--fm-ui-seed/test.snapshot/test.persistedBytes 일치0건을 확인했다. 서명·실기기·42개 화면 native 이식·Phase0 미확인 화면2건의 해소 증거는 아니다.

## 2차 gate

검사·문서 보강 후 focused Unit14건0fail/exit0, 전체 Unit15+UI11=26건0fail/exit0을 새로 확인했다. /tmp/focusmate-review-cleanup-focused.log, /tmp/focusmate-review2-ios-{build,test}.log, /tmp/focusmate-review2-web-{build,test}.log 참조. 양쪽 build/test exit0이며 웹31 tests/26VM PASS는 동일하다. 제품 Swift 소스 및 UI test hash는 변경하지 않았다.
