# 동작 불변 검사·문서 보강

Important1건은 test author가 화면 왕복 fixture의 createDirectory 카운터와 saveFailure==nil 검사를 추가해 해결한다. 기존 assertion과 생산 코드는 변경하지 않았다. 초안과 target 파일은 동일하다. focused와 전체 gate는 부모가 직접 실행한다.

Minor 문서의 이전 UI8건은 최초 RED/GREEN 이력으로 보존하고 현재 전체 회귀는 제품UI10/Unit14 + smoke2 =26건으로 public 문서에 구별했다. 설계 변경 목록에 검사 실행기와 연결 문서를 추가했다.

보안 MEDIUM의 파일 불변 일반화는 Foundation atomic write 사용과 시험의 쓰기 전 주입 오류를 구별해 문서에 제한했다. 실제 교체 실패/전원 장애는 미확인이다. 복구 기능은 Phase1에 추가하지 않았으며 오류 감지 후 진행 불가와 후속 Phase5/6 책임을 문서에 명시했다.

비존재 focused 입력의 실험: MissingTests.swift를 helper에 전달하면 XCTest는 실제 0 tests/TEST SUCCEEDED, exit0이었다. 0건 실행은 검증 통과가 아니며, 현 최종 gate는 실제26건 실행을 따로 확인한다. 해당 runner 제한은 유예 목록에 보존한다.

focused AppFoundationTests14건/0fail/exit0을 직접 확인했다. 변이 구현을 삽입하는 추가 실험은 실행하지 않았으며, 회귀 감도는 새 directory/writer 카운터의 assertion으로 보강했다.

2차 전체 gate도 Unit15/UI11 전체26건0fail/exit0, 웹31 tests+VM26PASS 및 두 build exit0을 확인했다. 재검토에 현재 diff를 전달한다.
