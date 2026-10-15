# T6 RED
파일: ios/FocusMateTests/JourneyLiveActivitySyncTests.swift (기존 케이스 불변, 추가만; 헬퍼 tickSeconds 추가)
추가 케이스: AC3(★appear 반복), AC16, AC17(★), AC18(★appear 반복), AC19(회귀방지), AC20, AC21(회귀방지), AC22, AC23, AC24, AC25a, AC25b
실패 확인: 컴파일 에러 - RecordingLiveActivityGateway.failsStart 없음 (AC16, AC17에서 사용). 인터페이스 추가분(프로덕션 파일 FocusMate/LiveActivityGateway.swift)이 GREEN 선행 필요.
 => 번들 컴파일 실패로 개별 케이스의 런타임 실패/통과는 아직 미확정.
메모: 체크포인트 간격은 기존 테스트(AC5: 90->150)상 60초로 보여 AC19는 180틱/저장 3회 이상으로 작성. AC20은 saveWarning 뜰 때까지 1초 틱 반복.
명령: FOCUSMATE_SIMULATOR_ID=... python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivitySyncTests.swift

## 보정 R1
- 대상: testV15_AC22_모든_기록에서_running은_staleDate가_endDate이고_paused는_nil이다
- 변경: `XCTAssertGreaterThanOrEqual(checked, 10)` -> `XCTAssertEqual(checked, 9)` (손 계산 오류 정정)
- 근거: request 보유 기록 r1 1 + r4 3 + r8 1 + r12 1 + r13 1 + r20 2 = 9. 깨짐 주석에 "기록 수가 9가 아니면(누락·중복) 실패" 명시.
- 실행 확인은 오케스트레이터가 수행.
