# T1 IMPLEMENT 보고

## 구현 내용
- ios/FocusMate/JourneySnapshot.swift: `paused` 필드(마지막), `Format{v3,v4}`, `maximumMinutes=360`, `totalSeconds`, `isArrived`, `updatingProgress`, `restingForLaunch`, private `with(...)` 복사 헬퍼. 검증: 분 1...360, 정류장·버스 카탈로그 대조(unknownStop/unknownBus), 진도 0...total, awaiting+paused → invalidPausedState. 디코드: userInfo `.journeyFormat == .v3`면 paused = (phase == .departed), v4는 paused 필수. 인코드에 paused. `CodingUserInfoKey.journeyFormat`. :4·:58 주석 교체.
- ios/FocusMate/SnapshotCodec.swift: currentVersion 4, `case 3`은 v3 userInfo 디코더로 같은 Envelope.
- ios/FocusMate/UITestBootstrap.swift: seededJourney `paused: false`.

## GREEN 증거
- `python3 scripts/check-ios.py test` + T1 관련 13개 파일(JourneySnapshotV4StorageTests, JourneySnapshotTests, JourneySnapshotStorageTests, SnapshotCodecTests, StorageV2Tests, CardSupplementTests, CardStorageTests, CardCustomizationAppModelTests, CardStyleStorageTests, RecordStorageTests, AppRecoveryTests, StorageRecoveryTests, BoardingModelTests) → Executed 212 tests, 0 failures.

## REFACTOR 내역
- `confirmingDeparture`·`updatingProgress`·`restingForLaunch`가 같은 13필드 복사를 쓰므로 private `with(phase:progress:paused:)`로 모음.

## self-review 결과
- 완전성: AC-20~26 대상 검증 규칙·v3 분기 반영. 품질: 검증 순서는 설계(분→카탈로그→…→진도→paused) 유지. 규율: 테스트 파일 미수정(해시 13개 일치). 테스트: focused 212/0.

## 우려사항
없음

## 과잉 구현 정리
- 유지(설계 예약): totalSeconds, isArrived, updatingProgress, restingForLaunch (설계 A1 명시, T4·T5에서 사용).
