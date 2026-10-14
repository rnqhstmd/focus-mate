# T3 IMPLEMENT — profileRecords 시드

## 구현 내용
- ios/FocusMate/UITestBootstrap.swift(DEBUG): rawSeeds["profileRecords"] — 카드 FM-12345678, 기록 journey-a/b/c(25·25·15분), 버전 2 형식. 기록 원본은 tagColor "#12ABef"의 `"#`가 raw 문자열 끝과 겹쳐 `##"…"##` 구분자 사용.

## GREEN 증거
- RED: 시드 제거 상태 5건 전부 실패(XCTUnwrap nil). GREEN: ProfileSeedTests+ProfileTimeTextTests+RecordLifetimeSummaryTests 26 pass / 0 fail.

## REFACTOR 내역
- 정리 없음.

## self-review 결과
- 기존 시드 불변, 딕셔너리 항목 1개 추가로 W10 충돌 범위 최소. 테스트 미수정.

## 우려사항
- 없음
