# T2 IMPLEMENT (세션) — AC-15, BR-1, 에셋

## 구현 내용
- ios/FocusMate/CardSnapshotFactory.swift: 난수(기본 0..<1억)·시계 주입. `FM-` + `%08u`(값 % 100_000_000), issuedAt은 초 단위 내림.
- ios/FocusMate/PassIdentity.swift: `displayName = "집중동행카드"`, `numberText = "FM · dddd dddd"`, `current(in:)`은 currentCard 없으면 nil.
- ios/FocusMate/PassFace.swift: 기본 외형 카드 뷰(비율 85.6/53.98, 기준 폭 238 배율). 배경 #121416, 테두리 #51565a, 점묘(폭 78%, 오른쪽 + 12% 바깥, 0.85), "Focus Mate", wave.3.right, IC 칩(#c5b998, 7.5%/43%/12%), 이름. 번호 없음. 접근성: children .ignore, 라벨 displayName, .isImage.
- ios/FocusMate/Assets.xcassets (Contents.json, PassDots.imageset: ticket-dots.svg 복사, preserves-vector-representation).

## GREEN 증거
`python3 scripts/check-ios.py test ios/FocusMateTests/CardStorageTests.swift ios/FocusMateTests/SnapshotCodecTests.swift ios/FocusMateTests/AppSnapshotSectionsTests.swift ios/FocusMateTests/PassIdentityTests.swift ios/FocusMateTests/PassFaceAssetTests.swift` → Executed 58 tests, with 0 failures. 빌드 경고: 기존 AppIntents 2건 외 신규 없음.

## REFACTOR 내역
정리 없음.

## self-review 결과
- 완전성: AC-15 (a)(b)·앞자리 0, BR-1 3건, 에셋 로드 통과.
- 품질: PassFace 이름은 PassIdentity.displayName 단일 출처 사용. 외형은 표현 레이어(테스트 비대상).
- 규율: 테스트 파일 해시 동일. 과잉 멤버: PassFace.aspectRatio·referenceWidth는 테스트 미참조이나 설계서 인터페이스 명시 → 설계 예약(유지).
- 테스트: T1 테스트 회귀 없음.

## 우려사항
없음 (red-writer 우려 "PassFace 이름 출처 단위 검증 불가"는 T5 AC-19 UI의 card.face 라벨로 검증 예정 — 관찰)

## 과잉 구현 정리
- 유지(설계 예약): PassFace.aspectRatio, PassFace.referenceWidth
