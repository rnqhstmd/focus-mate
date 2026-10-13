# T1 RED 보고

## 테스트 파일
ios/FocusMateTests/AppSnapshotSectionsTests.swift (클래스 AppSnapshotSectionsTests, 케이스 24건 — 전문은 해당 파일 참조, 각 케이스 위 주석에 "깨짐" 명명 기재)

## 케이스 (24)
1 empty 세 영역 빈 상태 / 2 updatingStage 3필드 교체 / 3 updatingStage 영역 유지 / 4 updatingStage 무검증(불일치 허용)
5-7 updating(cards|journey|records) 단계 3필드 보존 / 8 updating(cards:) 타 영역 유지
9 인코딩 키 정확히 6개 / 10 nil 정류장 null 유지 / 11-13 영역 .empty 인코딩 리터럴(sortedKeys)
14-23 디코딩 정책: items 누락, items 비배열, 영역이 [] , 영역이 null, 원소 {} , 원소 1, 모르는 키 무시, active 누락, active null→nil, active {}, active "x"
FR-7 생략 사유: W00에서 영역 값을 다르게 만들 수 없음(값 없는 enum).

## 기존 파일 변경 (ios/FocusMateTests/AppFoundationTests.swift)
- 라인 10-19 readySnapshot/cardOnlySnapshot: AppSnapshot(cardIssued:...) -> stage(...) 헬퍼 호출, private static func stage 추가
- 검증 위반 9건: AppSnapshot(cardIssued: X, initialStation: Y, currentStation: Z) -> Self.stage(X, Y, Z) (값·순서·단언 동일)
- invalid(구 145-149): Self.stage(true, StationSnapshot(id:" ",...), Self.currentStation)

## 실패 확인
명령: python3 scripts/check-ios.py test ios/FocusMateTests/AppSnapshotSectionsTests.swift
결과: 컴파일 실패(미존재 심볼), "Testing cancelled because the build failed."
누락 심볼: CardSection, JourneySection, RecordSection, AppSnapshot.cards/.journey/.records, AppSnapshot.updating(...), AppSnapshot.updatingStage(...)
부수 오류: "Generic parameter 'T' could not be inferred" — 누락 타입을 decode에 넘긴 파생 오류. 그 외 문법 오류 없음.
(AppFoundationTests도 updatingStage 미존재로 같은 빌드 실패)

## 참조 파일
ios/FocusMateTests/AppFoundationTests.swift (수정), ios/FocusMateTests/AppSnapshotSectionsTests.swift (신규). 프로덕션 코드 미참조.
