# Decisions

## Ruling: T0 W02 큰 글자 회귀 함께 수정 (implement/Step 0.5)
- 상황: 기준선에서 LargeTextUITests 시간 화면 케이스 1건 실패. W02 리뷰 정리(후보 두 줄 표시) 후 main에 들어간 기존 회귀.
- 사용자 결정: W11에서 함께 고침.
- 원인(녹화 프레임 확인): 가장 큰 글자에서 제목·출발지·현재 분 머리말이 스크롤 영역 대부분을 차지해 첫 후보 버튼이 아래가 잘린 채 보임 → isHittable true지만 중앙 탭이 잘린 쪽에 떨어져 선택 안 됨.
- 수정: 접근성 크기에서 머리말(제목 title3, 출발지 headline, 현재 분 headline, 출발지 묶음 accessibility1 상한)을 축소. 후보 두 줄 표시·하단 고정 진행 버튼(진입 직후 스크롤 없이 닿아야 함)은 유지.
- RED: 기존 실패 테스트 LargeTextUITests.testTimeScreenAtLargestTextSize… (테스트 미수정). GREEN: LargeTextUITests 2/2.

## Ruling: PassFace 미수정·W10 합류 절차 (design)
- 사용자 결정: 카드는 건드리지 않고 진행. 두 번째로 머지하는 브랜치가 합류 절차(design.md "W10 합류 절차")를 수행.
- AC-5 카드 내부 문구·칩/비접촉 식별자 검증은 W10 합류 후로 이연. 이번에는 profile.card 존재·라벨·FM- 미포함만.
- AC-14는 "CardSnapshot에 집계 관련 필드 없음"으로 재정의(W10 style 필드 추가 대비).
- AC-29·31 집계 실패는 실제 앱 도달 불가(decode·save 검증) → 단위 연쇄로만 검증(사용자 결정).
