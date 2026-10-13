# T1 RED 테스트 보고

## 상태
- 테스트 코드 작성 완료: `RecordSectionTests.swift` 21건, `RecordStorageTests.swift` 14건, 합계 35건.
- AC-1~15를 정상·경계·실패·실제 파일 복원으로 다룬다. AC-2 제외 동작과 AC-14 v1/v2 빈 기록 호환은 회귀 케이스로 명시했으며 신규 RED 근거와 구분한다.
- 생산 코드는 열람·검색·수정하지 않았다. 테스트 파일은 `xcrun swiftc -parse`와 focused XCTest 컴파일을 통과했다.

## 테스트 코드 전문
- `ios/FocusMateTests/RecordSectionTests.swift` (350줄, SHA-256 `e2a4fa755ada951a17321454ad0d14b47375351fd8d9aa4a1e7bb7a92f29d569`)
- `ios/FocusMateTests/RecordStorageTests.swift` (399줄, SHA-256 `aeee1100118fd6704df79c0325361925c62d9536260bc9f75b2279f3c0ca1b75`)
- 위 두 파일이 테스트 코드 전문의 단일 출처다. 독립 리터럴·수기 raw JSON을 사용했고 RecordSnapshot 합성 Equatable만으로 원문 동일성을 판정하지 않았다.

## 케이스 묶음
- 순수 동작 21건: 완료/제외/ID 멱등성, memo trim·200 UTF-16·scalar·수정·삭제·없는 ID, 1/360 경계, 자정·시간대·연도10000, 일합계, 최신순·동시각 tie, NFC/NFD ID, 중복·손상 검증.
- 저장 동작 14건: 실제 파일과 새 store/AppModel 복원, memo201·ID누락·duplicate·v3 원본 보존, 다른 영역, v1/v2 호환, 복원 정렬, 제외/no-op, NFC/NFD memo 원문, 오류 매핑, 완료·기존 메모 쓰기 실패 상태 보존.

## 실행
```sh
FOCUSMATE_SIMULATOR_ID=15645097-9CCF-4F45-A97B-8E43370F9488 python3 scripts/check-ios.py test ios/FocusMateTests/RecordSectionTests.swift ios/FocusMateTests/RecordStorageTests.swift
```
- 첫 부모 실행은 `RecordStorageTests.swift:100`의 `[Any]` Equatable 컴파일 오류로 종료되어 RED 성공으로 간주하지 않는다. 해당 assertion을 배열 `count == 0`으로 수정했다.
- 후속 실행은 컴파일 오류 없이 34 tests/48 failures로 종료했다. 동작 없는 선언의 `PendingRecordImplementation`과 잘못된 반환·오류·쓰기 결과로 실패했으므로 실제 RED다.

## 참조 파일
- `.dev/codex-feat-completed-record-memo/{prd,design,codemap}.md`
- `ios/FocusMateTests/{StorageTestSupport,StorageV2Tests,AppFoundationTests}.swift`
- `.claude/config.json`, `scripts/check-ios.py`
- GX `gx-red/SKILL.md`, `gx-dev/references/{codex-runtime.md,codex-roles/red-writer.md}`, `gx-tdd/references/testing-anti-patterns.md`

## 부모 직접 assertion RED 증거
- /tmp/w08-red.log: 34 tests 실행, 48 assertion/error failures, exit65.
- 동작없는 승인된 Swift 선언 이후 컴파일 통과, 완료/메모/저장 동작실패 직접 확인.
- 기존 호환/ID누락 구조거부 2건은 기존 동작을 유지하는 회귀 pass로 분리하며 신규 RED 근거에서 제외한다.

## QUALITY Important 보강
- 정렬 단위·raw v2 복원 fixture를 `01:00:00.001Z`와 `01:00:00Z` 조합으로 바꿔 문자열 내림차순 구현이 실패하고 실제 시각 파싱만 통과하도록 강화했다.
- 실제 임시 파일에 `memo="첫 메모"` raw v2를 seed하고 `writeData` 실패 시 `saveRecordMemo("수정") == false`, `.writeFailed`, 모든 snapshot 필드·UTF-16 메모·route/path·원본 바이트 보존을 검증하는 1건을 추가했다.
- 구현 GREEN 뒤 품질 보강이므로 신규 RED로 주장하지 않는다. `swiftc -parse`만 통과했으며 전체 simulator 회귀와 mutation 확인은 부모가 직렬 실행한다.
