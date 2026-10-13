# T2 IMPLEMENT — SnapshotCodec (세션 직접)

## 구현 내용
- 신규 `ios/FocusMate/SnapshotCodec.swift`
  - `LegacySnapshotV1`(버전 1 계약 고정), `enum SnapshotCodec { currentVersion = 2; decode; encode; migrateV1 }`.
  - decode: `VersionHeader` 실패 → `.corrupt` → `switch version` (1: `EnvelopeV1` → `migrateV1`, 2: `Envelope`, 그 외 `.unsupportedVersion(n)`) → 본문 실패 `.corrupt`(StorageIssue는 그대로 전파) → `validate()` 실패 `.invalidState(issue)`.
  - encode: `.sortedKeys`로 `Envelope(version: 2, state:)`.
  - migrateV1: `AppSnapshot.empty.updatingStage(...)`.

## GREEN 증거
- focused: `python3 scripts/check-ios.py test ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift`
- SnapshotCodecTests 16 pass, AppSnapshotSectionsTests 24 pass — **40 pass / 0 fail** (exit 0). 로그: reports/t2-impl-run.log
- G1/G2 golden 정확 일치 통과 — 설계의 바이트 결정성 가정이 실제 툴체인에서 확인됨.

## REFACTOR 내역
- 정리 없음 (함수 4개, 중복 없음).

## self-review 결과
- 완전성: RED 16케이스 전부 통과, 설계 시그니처와 일치.
- 품질: StorageIssue 재포장 방지(`catch let issue as StorageIssue { throw issue }`)로 미지원 버전이 corrupt로 바뀌지 않음.
- 규율: 테스트 파일 무수정(해시 기준선 일치). 저장소 위임은 T3 범위라 손대지 않음.
- 테스트: 연쇄 오류로 의심됐던 "Equatable has no member main"·"failed to produce diagnostic"은 심볼 생성 후 사라짐.

## 우려사항
- 없음 (T1의 중간 회귀는 T3에서 해소 예정 — 저장소가 아직 코덱을 쓰지 않음).
