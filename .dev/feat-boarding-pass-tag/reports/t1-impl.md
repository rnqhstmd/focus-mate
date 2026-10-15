# T1 IMPLEMENT — 진행 여정 저장 형식

## 구현 내용
- 신규 `ios/FocusMate/JourneySnapshot.swift`: `JourneySnapshot`(Phase/Tag/Progress, 선택 입력 필드만 저장), `boarding(details:cardID:id:boardedAt:)`(도착 정류장 id를 출발+방향×정류장 수로 1회 확정), `confirmingDeparture()`, 표시 조회(originName/destinationName/bus — 카탈로그 밖이면 nil), 구조 검증 `validate(currentCardID:)`, `ActiveJourneyValidationIssue`, 수동 Codable(boardedAt ISO8601 문자열, CardSnapshot 관례), `ActiveJourneyFactory`(ID·시계 주입, 초 단위 내림).
- `JourneySection.swift`: 빈 enum 제거(디코드 규칙은 그대로).
- `AppSnapshot.swift`: `SnapshotValidationIssue.invalidActiveJourney`, validate에서 active 있으면 currentStation 필수(.inconsistentStage) + 구조 검증 감싸기.
- `SnapshotCodec.swift`: `LegacyJourneySectionV2`(active null만 허용, 객체면 corrupt), migrateV2는 `.empty`.
- `PreparationDraft.swift`: PreparationTagIcon/PreparationTagColor/JourneySound에 Codable 채택.
- (기준선 수리, 별도) `UITestBootstrap.swift`: W10 사진 픽스처를 앱 컨테이너에 생성 — reports/baseline-w10-fix.md.

## GREEN 증거
`python3 scripts/check-ios.py test ios/FocusMateTests/JourneySnapshotTests.swift ios/FocusMateTests/JourneySnapshotStorageTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift ios/FocusMateTests/StorageV2Tests.swift` → 81 pass / 0 fail (T1 신규 33 + 기존 저장 48).

## REFACTOR 내역
정리 없음(초안 단계에서 검증 순서·주석 정리 완료).

## self-review 결과
- 완전성: RED 33 케이스 전부 통과. 검증 순서는 emptyField → cardMismatch → direction → minutes → task → tag → progress(빈 cardID가 cardMismatch보다 먼저 잡히도록).
- 품질: 기존 CardSnapshot 날짜 인코딩·CardSnapshotFactory 내림 관례와 동일.
- 규율: 테스트 파일 무수정(hash 동일). 과잉 멤버 없음(originName/destinationName/bus는 테스트 참조).
- 테스트: v2 객체 손상, v3 `{}`/"x" 손상 유지, null 재저장 바이트 동일 확인.

## 우려사항
없음. (설계 지시: SnapshotCodecTests·CardCustomizationAppModelTests의 "미정의 원소" 주석 갱신은 문서 정리 단계에서 처리)
