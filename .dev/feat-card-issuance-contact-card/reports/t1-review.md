# T1 태스크 리뷰 (reviewer, sonnet, task-scoped)

SPEC PASS (AC-13, AC-14 단위 충족) · QUALITY PASS · Critical 0 · Important 0 · Minor 5 (전부 [동작불변], 유예)

## Minor (유예 → phase-review Task A로 전달)
1. CardSection.swift:70 — `Date(_, strategy: .iso8601)` 기본 스타일: 소수초·`+09:00` 오프셋 입력 처리 불확실(소수초는 .corrupt 가능, 오프셋은 첫 재저장에서 Z로 정규화). 현재 AC 영향 없음(팩토리가 초 단위 내림). [검증 필요] — 정책 확인 권고.
2. CardStorageTests.swift:208 — 전각 숫자 케이스가 바이트 길이로만 거부되어 ASCII 숫자 판정을 직접 검증하지 못함. 11바이트 내 비ASCII 혼합 케이스 보강 권고.
3. CardStorageTests.swift:138-200 — a~f 입력이 분류/writeBlocked 테스트에 중복. 공유 배열로 정리 가능.
4. CardStorageTests.swift:203, 213 — 메서드명이 `testACn_` 컨벤션 아님.
5. AppSnapshot.swift:17-23 — currentCard·needsCardSupplement 프로덕션 호출자 아직 없음(후속 태스크 소비 전제).
