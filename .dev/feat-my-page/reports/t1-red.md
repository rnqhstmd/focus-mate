# t1-red report

- 테스트 파일: ios/FocusMateTests/RecordLifetimeSummaryTests.swift (케이스 5건)
  1. testAC12_서로다른ID_세건은_건수3과_분합60을_반환한다
  2. testAC12_같은입력을_두번요청해도_결과가_같다
  3. testAC12_기록이_0건이면_건수0_분0이다
  4. testAC13_예시완료_저장시도는_누적집계를_바꾸지않는다
  5. testAC30_저장기록_5건중_minutes0이_있으면_일부합산_대신_invalidMinutes를_던진다
- 테스트 코드 전문: 위 파일 참조 (순수 값 타입, 모의 없음, 기댓값은 손으로 도출한 리터럴)
- 실패 확인 명령:
  `cd /Users/bonseung/Documents/ChatGPT/new-w11 && FOCUSMATE_SIMULATOR_ID=7815DB9D-633D-441D-B3B5-C7DABF274EB8 FOCUSMATE_DERIVED_DATA=.build/ios-red python3 scripts/check-ios.py test ios/FocusMateTests/RecordLifetimeSummaryTests.swift`
- 실패 메시지(요약):
  - Value of type 'RecordSection' has no member 'lifetimeSummary' (4곳)
  - Cannot find 'RecordLifetimeSummary' in scope
  - Testing cancelled because the build failed. (3 failures)
- 실패 사유: 컴파일 에러 — 누락 심볼(lifetimeSummary, RecordLifetimeSummary). Swift 특성상 정상 RED. 단언 RED는 오케스트레이터가 인터페이스 뼈대로 확인.
- 참조한 파일: ios/FocusMateTests/RecordSectionTests.swift (fixture/스타일 참조만)
