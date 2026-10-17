# 최종 전체 회귀 중 발견 사항 (실행 중)

전체 실행 시작: 2026-10-16 12:14 KST. W17→W09b→W18 구현 뒤 처음 실행한 전체 통합 검증이다. 모든 테스트 완료 전 PASS로 표시하지 않는다.

확정 실패 공통원인: iOS 시스템 alert의 같은 접근성 버튼이 부모/자식 Button으로 중복 노출. Widget URL로 초기 표시된 alert는 반대로 ID가 생략됐으며 이 경계의 focused5는 통과했다. 기존 클릭 흐름의 ID 유지/중복 경계를 놓쳤다. 실제앱 여정 삭제/저장 실패 동작이 잘못됐다고 아직 판정하지 않는다.

확정 사례: ActiveJourneyMainUITests 2건, BoardingLargeTextUITests1건. sparse tree에 부모Button(id,label)→동일 자식Button이 보인다. reports/t2-alert-duplicate-analysis.md의 유일한 말단Button 선택 수리안이 있다. 사용자 지시에 따라 전체 회귀 완료 후 일괄 수리한다. 현재 소스는 수정하지 않는다.

Node 테스트·빌드 exit0. iOS unit1426/0fail. iOS UI317건 진행 중,최종목록은로그 기준 다시 생성한다. Python검증은iOS뒤에직렬실행한다. 한 세션에서 동시에여러빌드/테스트를돌리지않는다.

## 후속 분류
UI29실패시점:27건은동일ID/label중첩Button으로tap실패,2건은JourneyLifecycleSafetyUITests 최대글자확인창의keep/cancel.isHittable이false다(205/227행). 후자도같은공용query를쓰지만말단선택수리뒤실제hittable인지반드시재검증한다. 별도제품결함으로확정하거나동일원인완전해결이라고선언하지않는다. 공식XCTest배열AXbinding/descendants근거는xctest-query-docs.md.
