# W17 T1 구현

## 구현 내용
ContentState에 optional totalSeconds와 기본 nil 초기화 추가. Sync는 여정 총시간을 보관해 실행/정지/재개 요청에 전달. launch cleanup도 총시간을 보강한다.

## GREEN 증거
Codable focused4건 통과(t1-green-codable.log). 60건 focused 60pass / 0fail (t1-green-run.log). 부모 직접 실행·테스트 SHA256 재검증 통과.

## REFACTOR 내역
추가 정리 없음. 기존 SentKey와 종료/거절/재사용 로직 유지.

## self-review 결과
총시간과 잔여를 구분했고 Codable 누락/null 호환 보존. 생산3파일에 한정. 고정 expected와 기존 종료 회귀 유지. 테스트 SHA256 무결성 통과.

## 우려사항
전체 회귀는 사용자 지시로 W18 이후 이연. DisplayTests 7필드 제한은 T2에서 승인8필드로 변경 예정. AppIntents 메타데이터 추출 생략 SDK 경고 관찰.
