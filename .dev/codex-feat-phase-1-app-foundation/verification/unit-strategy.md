# App foundation 추가 단위 회귀 전략

상태: T1 재검토 이후 target에 적용. 선행 UI RED→GREEN을 대체하지 않는 추가 경계 검증이다. 실행 결과는 ../reports/unit-verification.md와 mechanical-gate.md를 참조한다.

## 승인 seam과 경계

- `AppSnapshot.validate/launchRoute` — in-process 값 경계. 단계 및 정류장 불변식의 잘못된 분기를 잡고 Codable/UI 표현은 통과시킨다.
- `LocalSnapshotStore` closure — locally substitutable read/directory/write 경계. 호출 순서, 오류 매핑, 부작용 0회를 잡고 Foundation atomic-write 자체 보장은 통과시킨다.
- UUID 임시 파일의 `LocalSnapshotStore` — 실제 로컬 파일 경계. 최초 중첩 폴더 생성, fresh-store 복원, 보호 원본 byte 불변을 잡고 process 재실행과 운영 Application Support는 통과시킨다.
- `@MainActor AppModel` — 동기 모델 경계. 1회 load, route/path/snapshot/saveFailure 전이를 잡고 SwiftUI 렌더링과 앱 생명주기는 통과시킨다.

## 14개 case와 변이 감도

1. 세 launch route: `cardIssued` 또는 nil-stage 분기 뒤바뀜을 검출한다.
2. stage/blank ID/blank name/direction 0 loop: 검증 생략, trim 누락, 초기→현재 검사 순서 변경을 검출한다.
3. missing load: no-such-file을 오류로 바꾸거나 load가 directory/write를 호출하는 변이를 검출한다.
4. permission read: 모든 Cocoa read 오류를 missing으로 취급하는 변이를 검출한다.
5. `{broken`/version 999+null: payload 선해석 또는 unsupported를 corrupt로 합치는 변이를 검출한다.
6. 실제 보호 파일 save: 기존 오류 무시, directory/write 진행, 원본 byte 변경을 검출한다.
7. invalid candidate: 기존 파일 read보다 후보 검증을 늦추거나 실제 쓰기를 시도하는 변이를 검출한다.
8. 실제 최초 save/fresh load: 중간 폴더 미생성, envelope 누락, round-trip 필드 손실을 검출한다.
9. directory/write failure: 오류 누수, writeFailed 매핑 누락, directory 실패 뒤 write 진행을 검출한다.
10. model load 1회/non-main open: 중복 read와 card route 탐색 허용을 검출한다.
11. main 네 목적지/back: 목적지 누락, 비동기 반영, 탐색 중 저장 호출을 검출한다.
12. failed save: 실패 전에 snapshot/root/path를 갱신하거나 writeFailed를 잃는 변이를 검출한다.
13. success after failure: 성공 시 오류 미해제, route 미갱신, route 변경 시 path 미정리를 검출한다.
14. failed load 뒤 save: failed root에서 read/directory/write를 재호출하거나 원인 wrapping을 잃는 변이를 검출한다.

기대값은 설계 계약의 literal route/error/call count와 고정 fixture(`seongsu/성수/1`, `seoulForest/서울숲/-1`, `{broken`, `{"version":999,"state":null}`)에서만 온다. production 메서드로 기대값을 계산하거나 모의 구현 자체를 검사하지 않는다. 실제 파일은 `FileManager.default.temporaryDirectory/FocusMate-AppFoundationTests-<UUID>/...` 아래만 만들고 `defer`로 정리한다.

## 실행 인계

이 draft 작성 단계에서는 초안 작성 태스크 지침에 따라 build, XCTest, 임의 Swift CLI를 실행하지 않았다. 따라서 RED/GREEN 또는 컴파일 증거는 없다. parent가 T1 review 후 파일을 시험 target에 포함하고 XCTest 컴파일, 해당 suite, 전체 native/web gate 순으로 직접 검증해야 한다.
