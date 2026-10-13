# T4 안내 이력 수정

유효 정리확인 후 hasAttemptedCleanup 유지, 실패해제/취소/재시도 뒤에도 RootView가 원본불변을 단정하지 않는 중립 안내를 표시한다. 초기오류 기존안내와 저장·백업순서는 유지.

부모 RED: 선언-only false bridge 후 Unit2중1실패4assert/UI1실패1assert, exit65. GREEN: Unit2+UI1=3 tests /0fail exit0, 2026-10-13 22:20:30KST. tests무변경. 리뷰 I-1/S-01을 재현하는 추가회귀. 태스크scope 생산2파일 리뷰 진행.
