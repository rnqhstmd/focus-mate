# 의사결정 기록

AskUserQuestion으로 오간 질문과 선택을 자동 기록한다. 고른 것뿐 아니라 버린 선택지도 남으므로 왜 그렇게 정했는지가 추적된다.

## 2026-10-13 19:18 · Ruling: T1 컴파일 RED 인정

**판정.** T1 RED를 "미존재 심볼로 인한 컴파일 실패"(누락 심볼 외 컴파일 오류 없음)로 인정하고 IMPLEMENT로 진행했다. GREEN 후 신규 24케이스가 실제 실행되어 통과했다.
**근거.** test-architect RED 확인 전략(설계서 Testability 평가 (c))이 구조 태스크의 컴파일 RED를 명시적으로 허용했다. Swift는 미존재 심볼을 런타임 실패로 표현할 수 없다.
**틀리면.** T1 테스트 파일을 유지한 채 신규 타입을 빈 뼈대로 되돌려 assertion RED를 재확인한다.

## 2026-10-13 19:18 · Ruling: T1 중간 회귀 수용

**판정.** T1 이후 기존 AppFoundationTests의 v1 파일 읽기 테스트가 corrupt로 실패하는 상태를 T3 완료까지 유지한다.
**근거.** v1→v2 변환은 설계상 T2(SnapshotCodec)·T3(저장소 위임) 범위이고, 태스크 간 파일 중복을 피하려고 저장소 수정을 T3에 두었다. focused 집합(T1 신규 테스트)은 통과.
**틀리면.** T3 완료 후에도 실패가 남으면 phase-review Step 0 전체 회귀에서 잡힌다.

## 2026-10-13 19:34 · Ruling: review 동작 불변 정리 1건

**판정.** 통합 리뷰 Important [동작불변] 테스트 헬퍼 중복을 StorageTestSupport.swift로 통합했다.
**근거.** phase-review 4b 기본값(수행). 단언·케이스 불변, 단위 62/62 GREEN.
**틀리면.** reports/review-cleanup.md 목록대로 각 파일에 private 헬퍼를 되살린다.

## 2026-10-13 19:34 · Ruling: security MEDIUM 4건 처리

**판정.** 문서 정정 3건(FR-5 문구, BR-4 전제, 설계 인계 — 인계는 사용자 선택) 수행, 파일 크기·경쟁 조건 1건 유예.
**근거.** 4c 기본값 — 동작 불변이 명백한 항목만 정리, 나머지 유예.
**틀리면.** trust-ledger.md 항목 기준으로 후속 작업에서 RED부터 처리.

## 2026-10-13 19:40 · Ruling: review Minor 13건 유예 · MEDIUM 1건 정리

**판정.** 2회차 Minor 3건과 1회차 Minor 10건을 유예(reports/review-deferred.md), 2회차 security MEDIUM(설계서 FR-5 문구)은 문서 정정으로 처리.
**근거.** 4c 기본값 — quality Minor 유예, 동작 불변이 명백한 MEDIUM 정리. 리뷰 반복 상한 2회 도달, 문서 전용 변경이라 확인 리뷰 생략.
**틀리면.** review-deferred.md 항목을 후속 작업에서 정리.
