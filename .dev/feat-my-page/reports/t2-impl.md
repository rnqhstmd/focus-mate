# T2 IMPLEMENT — ProfileTimeText

## 구현 내용
- ios/FocusMate/ProfileTimeText.swift(신규): display(minutes:) "N min"/"H h"/"H h R min", spoken(minutes:) "N분"/"H시간"/"H시간 R분". 공통 format.

## GREEN 증거
- focused: ProfileTimeTextTests + RecordLifetimeSummaryTests → 21 pass / 0 fail
- RED(뼈대 "" 반환): 16건 전부 실패.

## REFACTOR 내역
- 고정값이던 separator 파라미터 제거 → focused 재실행 통과.

## self-review 결과
- AC-10·11·22(단위) 충족, 테스트 미수정, 로캘 미사용.

## 우려사항
- 없음 (red-writer 지적: 메서드명 testAC{n}_ 형식이 JourneyPlannerTests test_ 형식과 혼재 — 프로젝트 내 RecordSectionTests가 testAC 형식이라 수용)
