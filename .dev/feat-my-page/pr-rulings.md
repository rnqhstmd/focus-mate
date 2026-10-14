## Rulings
- T0 W02 큰 글자 회귀 함께 수정 — 가장 큰 글자에서 시간 화면 머리말(제목·출발지·현재 분)을 줄여 첫 후보 버튼이 잘리지 않게 함. 후보 두 줄·하단 고정 진행 버튼 유지 (틀리면: 별도 핫픽스로 분리하고 TimeSelectionView 변경을 되돌림)
- PassFace 미수정·W10 합류 절차 — 마이페이지는 현재 공통 카드를 그대로 쓰고 카드 내부 시안 일치(AC-5)는 W10 합류 후 검증. AC-14는 "집계 필드 없음"으로 재정의, AC-29·31은 단위 연쇄로만 검증 (틀리면: 이번 PR에서 PassFace를 시안 배치로 수정 — W10과 충돌 감수)

## Deferred
- [Minor] ProfileView.swift — 뒤로 버튼 iOS 26 시스템 유리 버블(시안은 버블 없음)
- [Minor] ProfileView.swift — profile.titleBar 이중 식별자 우회, OS 버전 의존
- [Minor] ProfileView.swift:72·124 — 통계 위 여백 이중 적용(시안 대비 약 8pt 넓음)
- [Minor] ProfileView.swift — 인라인 간격 수치, ProfileMenuRow accessibilityLabel 중복, SF pencil 아이콘 모양 차이
- [Minor] ProfileUITests — app.buttons.count == 3·3초 고정 대기 취약, XXXL 탐색 swipeUp만 사용, AC-29 UI 미검증
- [Minor] ProfileModelTests — AC-14 동어반복·Mirror 부분 일치, AC-15 writeCalls 절대값 단언
- [Minor] AppModel+Profile.swift — try?가 집계 실패 원인 폐기
- [Minor] TimeSelectionView — 큰 글자 머리말 정보 유지 직접 단언 없음
- [Minor] design.md — AC-28 테스트 위치 문서-구현 차이
- [MEDIUM] UITestBootstrap.swift — W10과 rawSeeds 텍스트 충돌 가능(합류 시 해결)
- [MEDIUM] Dynamic Type 상한 — 마이페이지 툴바 제목 accessibility1, 시간 화면 접근성 크기 머리말 축소
