# W10 T2 선언 지원 보고

Status: DONE_WITH_CONCERNS

## 수행 범위
현재 worktree에서 PRD, design.md 최종 계약 보강 부록, reports/t2-red.md, CardStyleTests/CardPhotoProcessorTests/CardStyleStorageTests 및 CardPhotoTestFixtures를 읽고 컴파일에 필요한 최소 선언만 작성했다. GREEN 실제 구현·REFACTOR·테스트 수정·commit/push·agent 디스패치는 수행하지 않았다.

## 변경 파일
- `ios/FocusMate/CardStyle.swift` (신규): CardColor/CardPhoto/CardStyle 값·보관 생성자·Codable/Equatable/Sendable, CardStyleValidationIssue 전체 case, 표준색 #121416/사진 0장, CardCustomizationPolicy 상수 선언.
- `ios/FocusMate/CardPhotoProcessor.swift` (신규): ProcessedCardPhoto 보관 생성자, 처리 오류 전체 case, CardPhotoProcessing 경계, ImageIOCardPhotoProcessor 생성자와 실패 stub.
- `ios/FocusMate/CardSection.swift`: CardSnapshot.style와 기본값 생성자 선언, updating(style:) no-op stub, 기존 decode에서 style = .standard 초기화. CodingKeys/encode는 기존 id/issuedAt만 유지한다.
- `ios/FocusMate/AppSnapshot.swift`: invalidCardStyle(CardStyleValidationIssue), invalidCardPhoto 오류 case만 추가. 기존 validate 동작 유지.
- `ios/FocusMate/LocalSnapshotStore.swift`: 최종 부록 순서대로 validateCardPhotos initializer 인자를 추가하고 private closure에 보관만 한다. load/save/backupAndClear에서 호출하지 않는다.
- `ios/FocusMate/SnapshotCodec.swift`: 변경 없음. currentVersion = 2와 기존 v1/v2 경로 유지. 현재 T2 테스트가 새 migration 타입을 직접 참조하지 않아 DTO/migrateV2 선언은 추가하지 않았다.

## 컴파일 실제 결과
- **미실행·미확인.** 사용자 지정 부모 직렬화 계약에 따라 xcodebuild/check-ios 및 다른 테스트·빌드·컴파일 명령을 실행하지 않았다. build 성공이나 assertion RED 확보를 주장하지 않는다.
- 허용 생산 파일 대상으로 `git diff --check -- ios/FocusMate/CardStyle.swift ios/FocusMate/CardPhotoProcessor.swift ios/FocusMate/CardSection.swift ios/FocusMate/AppSnapshot.swift ios/FocusMate/SnapshotCodec.swift ios/FocusMate/LocalSnapshotStore.swift` 실행: 종료 코드 0, 출력 없음. 이는 tracked diff 공백 검사이며 신규 untracked 파일의 컴파일 증거가 아니다.
- 새 파일 전문과 기존 파일 diff를 직접 읽어 선언/인자 순서/오류 case를 대조했다. 기존 production switch 검색에서 새 SnapshotValidationIssue case 때문에 추가 분기가 필요한 exhaustive switch는 발견하지 못했다. 실제 컴파일 확인은 부모 담당이다.

## 남은 stub 목록
1. `CardStyle.validate() throws`: 빈 body. 수치·수량·ID·byte·치수·배치 검증 없음.
2. `CardStyle.isStandard`: 항상 true. 실제 표준 외형 비교 없음.
3. `CardSnapshot.updating(style:)`: self 반환. 입력 외형을 적용하지 않음.
4. `ImageIOCardPhotoProcessor.process(_:)`: 항상 CardPhotoProcessingIssue.unreadable throw. 실제 이미지 처리 없음.
5. `ImageIOCardPhotoProcessor.validateStoredPhoto(_:)`: 항상 SnapshotValidationIssue.invalidCardPhoto throw.
6. `ImageIOCardPhotoProcessor.validateStoredStyle(_:)`: 항상 SnapshotValidationIssue.invalidCardPhoto throw. 사진 0장도 예외 없이 실패한다. Store에는 아직 연결하지 않았다.
7. `LocalSnapshotStore.validateCardPhotos`: closure 보관만, 실행 없음.
8. 저장 확장: CardSnapshot decode는 표준 외형, encode는 style 미저장. v3/독립 v2 DTO/이미지 검증 연결은 미구현.

새 생산 생성자·메서드·computed property 및 protocol method 선언에 `TODO W10 RED declaration marker`를 붙였다. 생성자는 검증/clamp 없이 값만 보관한다. Codable/Equatable/Sendable은 선언에서 Swift 합성을 사용한다.

## 정책 상수
inputByteLimit=8_388_608, maximumPhotos=6, photoByteLimit=1_048_576, totalPhotoByteLimit=6_291_456, aspectRatioRange=0.1...10, widthFractionRange=0.15...2.5, centerRange=-1...2, undoLimit=20. 설계가 값만 명시하므로 속성명은 해당 값의 용도를 나타내도록 선언했다. 정책 적용 로직은 없다.

## self-review / 우려사항
- 선언 지원 완료 범위와 GREEN 미구현 범위를 분리했다. 기존 저장 bytes/version, 기존 구조 검증 및 복구 I/O 순서를 바꾸지 않았다.
- 일부 성공/실패 시험은 no-op/고정 throw 때문에 우연히 통과할 수 있다. 이는 GREEN 증거가 아니며 부모는 실제 assertion RED와 compile/fixture 오류를 구분해야 한다.
- 컴파일 결과가 없으므로 DONE_WITH_CONCERNS다. 부모 컴파일에서 허용 파일 밖 수리가 필요하면 NEEDS_CONTEXT로 전달해야 한다.
- 사용자 안내대로 test author가 추가하는 exact8MiB/WebP fixture 2 case는 이 작업에서 작성·수정하지 않았다. 읽은 시점의 processor 테스트에는 아직 두 case가 없었다.
- 작업 시작 시 존재하던 TimeSelectionView·기존/신규 테스트·UI 테스트·.dev 산출물은 이 작업에서 수정하지 않았다. 보고서 외 작성 범위는 위 생산 파일 5개뿐이다.
