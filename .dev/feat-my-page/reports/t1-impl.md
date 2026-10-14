# T1 IMPLEMENT — RecordSection 누적 집계

## 구현 내용
- ios/FocusMate/RecordSection.swift: `struct RecordLifetimeSummary { count, minutes }`, `func lifetimeSummary() throws` — `try validate()` 후 같은 items에서 건수·minutes 합.

## GREEN 증거
- `FOCUSMATE_SIMULATOR_ID=7815DB9D… FOCUSMATE_DERIVED_DATA=.build/ios-red python3 scripts/check-ios.py test ios/FocusMateTests/RecordLifetimeSummaryTests.swift ios/FocusMateTests/RecordSectionTests.swift` → 26 pass / 0 fail
- RED 확인(뼈대): 5건 중 4건 단언 실패. 0건 케이스는 빈 값이 기대값이라 뼈대에서 우연 통과 → 회귀 가드로 유지.

## REFACTOR 내역
- 정리 없음 (dailySummary와 같은 형태).

## self-review 결과
- 완전성: AC-12·13·30(섹션) 충족. 품질: 기존 API 불변. 규율: 테스트 미수정(해시 동일). 테스트: 기존 RecordSectionTests 회귀 없음.

## 우려사항
- 없음
