# T3 IMPLEMENT (세션) — AC-3/4/6/7(모델), AC-8, AC-9, AC-11, AC-12

## 구현 내용
- ios/FocusMate/AppModel.swift
  - `init(store:cardFactory: = .init())`, `cardFactory` 보관.
  - `persist(_:) -> StorageIssue?` (private): 기존 save 본문(경로 계산 → store.save → snapshot·launchState 교체 → 경로 바뀌면 path=[])을 옮김. saveFailure는 건드리지 않음. `save`는 `saveFailure = persist(candidate)`로 기존 동작 유지.
  - `issueCard()`: `.ready(.cardEntry)` + snapshot + `!cardIssued` 가드 → `persist(snapshot.issuingCard(factory.make()))`. 성공 시 `isHoldingIssuedCard = true`. 실패 시 아무것도 바꾸지 않음(saveFailure 미설정).
  - `presentedRoute`: `.ready`가 아니면 nil, 보류 중이면 `.cardEntry`, 아니면 launchState 경로. `finishCardIssuance()`가 보류 해제.
  - `start()` = `loadIfNeeded()` + `supplementCardIfNeeded()`. 보충은 `hasAttemptedSupplement`(먼저 세움)·`.ready`·`needsCardSupplement` 가드, `store.save` 직접 호출, 성공 시 snapshot 교체, 실패 시 `supplementFailure`만 기록.

## GREEN 증거
`python3 scripts/check-ios.py test ios/FocusMateTests/{CardIssuanceModelTests,CardSupplementTests,AppFoundationTests,StorageV2Tests,CardStorageTests,SnapshotCodecTests,AppSnapshotSectionsTests,PassIdentityTests,PassFaceAssetTests}.swift` → Executed 95 tests, with 0 failures. 첫 구현에서 통과. 기존 AppFoundationTests(save 경로)·StorageV2Tests(읽기는 쓰지 않음) 회귀 없음.

## REFACTOR 내역
save/persist 분리 자체가 설계 지정 구조. 추가 정리 없음.

## self-review 결과
- 완전성: 15건 전부 통과. 불변식(finish 후 재발급 거부·쓰기 0) 확인.
- 품질: presentedRoute 단일 판단 규칙을 주석으로 명시. 보충 실패는 화면 비노출(Q2).
- 규율: 테스트 파일 해시 동일. 새 public 멤버(start, supplementCardIfNeeded, issueCard, finishCardIssuance, presentedRoute, supplementFailure, init cardFactory) 모두 테스트 참조 또는 설계 명시.
- 테스트: 기존 save 호출부 동작 동일.

## 우려사항
없음
