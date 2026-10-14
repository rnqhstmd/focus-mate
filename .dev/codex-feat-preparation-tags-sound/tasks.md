# W03 TDD 태스크

사용자 전체 과정 계속 승인으로 routine 태스크 진행. 같은컴포넌트AC묶되각AC시나리오테스트개별.

1. T1 PreparationDraft + AppModel: AC1~13/23. 순수태그/입력/초안·시간왕복·확정값/저장0.
2. T2 SoundPreviewController + AVadapter: AC17~22,실제WAV번들누락·리소스동일. 취소/late/nooverlap·repeat/fade·failure/none.
3. T3 SwiftUI 준비/태그/소리: AC1~16/19~25. 기존PreparationFlow자리표시자검사교체,왕복/취소/큰글자/접근성컨트롤·미리듣기시트수명.

순차각RED隔離→assertRED직접확인→세션GREEN/REFACTOR→focused직접확인/해시→태스크review→전체review→verify→acceptance→commit/PR.

4. 구현 후 시안 대조: 승인 시안 경로 확인 → 실제 네이티브 실행 화면과 상태별 구성 비교 → 선택/입력/저장/취소/뒤로가기·초안 보존 직접 조작 확인. 자동 테스트와 구분한 증거/수정/재확인 기록. 사용자 추가 지시로 필수 최종 확인 항목.
