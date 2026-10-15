# review-r1 RED (unit) - 실행 안 함
명령: FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/JourneySnapshotStorageTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift ios/FocusMateTests/BoardingTagControllerTests.swift ios/FocusMateTests/BoardingModelTests.swift
- JourneySnapshotStorageTests: 변경 3(빈객체/문자열/모르는 아이콘 -> active nil 로드), 추가 3(카드불일치, 진도5, active 키 누락 corrupt=현재도 통과 가능한 보존 케이스), helper saveThenRewrite
- AppSnapshotSectionsTests: 변경 2(active {} / "x" -> nil)
- BoardingTagControllerTests: 추가 3 (reduceMotion false/true 실패 후 같은 동작 calls==1, dragEnded 후 재태그 calls==2: 마지막은 현재도 통과 가능한 보존)
- BoardingModelTests: 추가 4 (초안 변경 후 확정값 저장, startTripFromMain 후 false, open(.journey) 가드 없음/있음: 마지막은 보존)
예상 실패: 변경/추가 F1 케이스(throw corrupt/invalidState), F2 두 케이스(calls 2 이상), F4 두 케이스(false 또는 저장 안 됨 / 저장됨), F5 없음 케이스(path [.journey]).
참조: 4개 테스트 파일 + BoardingTestDoubles.swift (프로덕션 미열람)
