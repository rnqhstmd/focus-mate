# T3 IMPLEMENT — LocalSnapshotStore 코덱 위임 (세션 직접)

## 구현 내용
- `ios/FocusMate/LocalSnapshotStore.swift`: `VersionHeader`·`Envelope` 선언 삭제. `load()`는 읽기·파일 없음 처리 후 `SnapshotCodec.decode(data)` 한 번 호출(오류 재포장 없음). `save()`는 validate → load 차단 순서 유지, 인코딩만 `SnapshotCodec.encode(snapshot)`(기존 `writeFailed` 블록 안). 공개 API 불변.

## GREEN 증거
- focused: `python3 scripts/check-ios.py test ios/FocusMateTests/StorageV2Tests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift`
- StorageV2Tests 8 + SnapshotCodecTests 16 + AppSnapshotSectionsTests 24 = **48 pass / 0 fail** (exit 0). 로그: reports/t3-impl-run.log

## REFACTOR 내역
- 정리 없음 (삭제로 이미 축소됨).

## self-review 결과
- 완전성: RED 8케이스 통과(AC-1·AC-2 v2 기록·AC-3 v2 records 누락·AC-4 포함).
- 품질: 코덱 오류를 그대로 전파(test-architect 주의점 — 포괄 catch로 unsupportedVersion이 corrupt로 바뀌지 않음).
- 규율: 테스트 파일 무수정(해시 기준선 일치).
- 테스트: T1 중간 회귀(기존 v1 읽기 테스트)는 이 변경으로 해소 대상 — 전체 회귀는 phase-review Step 0에서 확인.

## 우려사항
- 없음
