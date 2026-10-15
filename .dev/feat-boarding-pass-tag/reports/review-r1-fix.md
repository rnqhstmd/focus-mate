# 리뷰 R1 수정 (phase-review 4a RGR + 4b 정리)

## 동작 결함 (재현 RED → 수정)
- F1 [보안 HIGH, 사용자 결정 "여정만 버리기"]: `JourneySection` 디코드에서 active 객체 손상은 nil(`try?`), `SnapshotCodec.decode`가 구조 검증 실패 active(카드 불일치·빈 필드·진도 규칙·현재 정류장 없음)만 버리고 나머지는 그대로 로드. active 키 누락은 여전히 corrupt, v2 계약 불변, 쓰기 검증은 엄격 유지. RED: JourneySnapshotStorageTests 3건 기대 변경 + 3건 추가, AppSnapshotSectionsTests 2건 변경.
- F2 [동작결함]: 저장 실패 뒤 같은 손가락 동작에서는 재인식하지 않음(`awaitingRelease`, dragEnded에서 해제). RED: BoardingTagControllerTests 3건(동작 줄이기 on/off, 손 뗀 뒤 재태그). 수정 전 동작 줄이기 off 케이스는 무한 대기(재인식 반복)로 실패.
- F3 [동작결함]: 메인을 ScrollView로 감싸 가장 큰 글자에서 모든 메뉴 도달. RED: BoardingLargeTextUITests.testF3 — 수정을 임시로 되돌려 open.profile 미도달 실패 확인 후 복원.
- F4 [보안 MEDIUM]: 승차 저장은 승차권 보기로 확정한 값(`boardingDetails`)을 사용, 메인 폐기 시 확정값도 버림(`discardConfirmedPreparation`). RED: BoardingModelTests 2건.
- F5 [보안 MEDIUM]: `open(.journey)`는 진행 여정이 없으면 무시. RED: BoardingModelTests 2건(없음 무시/있음 열림).

## 동작 불변 정리
- R1: BoardingFlowUITests U3 조건부 해제 → 무조건 단정, AC-5 테스트에 정류장 이름 단정(red-writer).
- R2: UI 테스트 내부 상태 단정을 카드 frame·보이는 값 주 단정으로 교체, 진단은 보조 주석(red-writer).
- 문서(T9): docs/FLOWS.md(iOS W04 절, 출발 안내 충돌 안내), docs/CURRENT-STATE.md(W04 절).

## GREEN
- 단위 focused 8파일 144/144.
- UI focused 5파일: (실행 결과 아래 append)
