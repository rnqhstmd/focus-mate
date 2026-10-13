# T2 RED report

Status: DONE_WITH_CONCERNS (컴파일 실패 RED — 뼈대 후 단언 RED 재확인 필요)

## 테스트 파일 (케이스 수)
- ios/FocusMateTests/StationSearchStateTests.swift (6)
- ios/FocusMateTests/JourneyPlanDraftTests.swift (16)

테스트 코드 전문은 위 두 파일 참조.

## 실패 확인 명령
FOCUSMATE_SIMULATOR_ID=65C4EB57-5CAD-4C4C-9FA5-1EF70EF47DEA python3 scripts/check-ios.py test ios/FocusMateTests/StationSearchStateTests.swift ios/FocusMateTests/JourneyPlanDraftTests.swift

## 실패 메시지
컴파일 에러: cannot find type/'JourneyPlanDraft' in scope, cannot find 'JourneySelection' in scope, type 'Equatable' has no member 'needsSelection'/'noCandidates' (ProceedState 부재).
StationSearchState 에러는 출력 head 30줄 필터에서 잘렸을 수 있으나 동일 사유.

## 누락 심볼
StationSearchState (query, results, selectedID, selectedOption, confirmationText, canConfirm, select), JourneySelection, ProceedState (title, isEnabled, 4 케이스), JourneyPlanDraft (init, minutes, selectedBusID, setMinutes, choose, candidates, selectedCandidate, proceedState).

## 참조한 파일
- ios/FocusMateTests/JourneyPlannerTests.swift
- ios/FocusMateTests/StationCatalogTests.swift

## 수정 R1
- 사유: 뼈대(results=[])에서 강제 언래핑(`!`)이 크래시 -> 러너 중단(Executed 0).
- 수정: StationSearchStateTests의 `!`를 `try XCTUnwrap(...)`으로 교체, 해당 테스트 함수(3건)와 helper `reverseOptionID`를 `throws`로 변경. 케이스·기대값 불변.
- 재실행(같은 명령): 크래시 없이 실행됨. JourneyPlanDraftTests 16건 실행, 33 단언 실패.
  StationSearchStateTests는 XCTUnwrap 실패(StationOption nil)로 해당 케이스 실패, 결과 없음 select 거부 케이스는 뼈대에서 우연 통과(허용).
