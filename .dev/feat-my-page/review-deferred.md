# 유예 Minor (머지 전 수정 불필요)

1. 뒤로 버튼 iOS 26 시스템 유리 버블(시안은 버블 없음) — 시스템 뒤로 동작(AC-16) 유지 위해 그대로.
2. profile.titleBar 이중 식별자 우회 — OS 버전 의존, OS 업데이트 시 ProfileUITests AC1·AC2 재확인.
3. 인라인 간격 수치(하단 간격은 수정됨).
4. ProfileMenuRow accessibilityLabel 중복(무해).
5. ProfileUITests `app.buttons.count == 3`·3초 고정 대기 취약.
6. AC-29 UI 수준 미검증(단위만, 판정 기록).
7. AC-14 단일 출처 테스트 동어반복.
8. AC-14 Mirror 금지어 부분 일치 — 허용 목록 방식이 견고.
9. AC-15 단위 writeCalls 절대값 0 단언.
10. XXXL 탐색 루프 swipeUp만 사용.
11. ProfileStats.from의 try?가 실패 원인 폐기(진단 없음).
12. SF `pencil`과 시안 연필 아이콘 모양 차이(시안은 외곽선).
13. 시간 화면 큰 글자 머리말 정보 유지를 직접 단언하는 테스트 없음.
14. design.md의 JourneyStartModelTests 수정 계획 대신 ProfileModelTests에 AC-28 배치(문서-구현 차이).
15. (태스크 리뷰 T4 재리뷰) AC-27 가드 케이스 — 조치 불필요.
16. (재리뷰 R1) 통계 위 여백 이중 적용(ProfileView 72·124) — 시안 대비 약 8pt 넓음, 한 곳으로 합칠 것.
