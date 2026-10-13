# 설계 비판 검토

MUST-ADDRESS: 0건. 설계에 근본적인 문제는 발견되지 않았습니다.

## CONSIDER
재시도 후 과거 recoveryFailure 안내가 남는 수명이 불명확함. 최신 StorageIssue 안내와 이전 정리 실패를 구별할 필요가 있음.

## 처리
재시도 시작 시 recoveryFailure를 nil로 해제하여 최신 읽기 결과만 표시한다. requestCleanup의 새 확인 진입에서도 과거 복구 실패 안내를 해제한다. 확인 취소 자체는 파일·기존 시작 오류·백업을 변경하지 않는다. 새 실패만 새 recoveryFailure로 표시한다.

## 검토 근거
unreadable/missing 관찰 경계, 백업 검증·삭제 완료 확인, 정상화 파일 삭제 거부, 명시적 확인·중복 호출 가드가 PRD와 일치함. closure DI의 기존 구조를 사용하며 새 서비스·프로토콜 없음. 단일 작성자 범위 및 비트랜잭션 경계는 명시됨.
