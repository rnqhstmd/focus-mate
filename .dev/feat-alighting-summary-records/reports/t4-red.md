# T4 RED 보고

- 테스트 파일: ios/FocusMateTests/AlightingTagControllerTests.swift (케이스 8건)
  1. test끌지_않고_터치만_하면_하차_저장_없이_탭_힌트가_나온다 (AC-8)
  2. test활성화하면_끌기_없이_접촉_대기_뒤_하차_저장_1회 (AC-9)
  3. test인식_직후_접촉_대기_중_세_번_더_접촉해도_하차_저장은_1회 (AC-11)
  4. test하차_저장_실패는_failed와_실패_낭독이고_다시_활성화하면_성공_전환한다 (AC-12)
  5. test성공_뒤_유지_1400_페이드_450이_지나면_finished로_onFinished_1회 (AC-15)
  6. test카드_태그_문구는_승차는_기존과_같고_하차는_하차_문구다 (CardTagCopy)
  7. test하차_저장_전이면_모든_phase에서_종료하지_않는다 (표 8 phase)
  8. test하차_저장_뒤에는_접촉_유지_페이드만_기다리고_나머지는_종료한다 (표)
  9. test접촉_대기_중_중단_뒤_복귀하면_저장_성공_후_ready이고_화면_복구가_종료를_판단한다 (중단 MUST)
  (총 9건)
- 명령: cd /Users/bonseung/Documents/ChatGPT/new-w09 && FOCUSMATE_SIMULATOR_ID=7D81AFEE-FC29-4E6F-8E2C-195C022C52A6 python3 scripts/check-ios.py test ios/FocusMateTests/AlightingTagControllerTests.swift
- 로그: /private/tmp/claude-501/-Users-bonseung-projects-focus-mate/79aaedd3-8365-406d-90ad-aa6e6b956c1e/scratchpad/t4-red.log
- 실패(컴파일, NoSuchMethod RED):
  - cannot find type 'JourneyAlighting' in scope
  - extra argument 'alighter' in call / missing argument for parameter 'boarder'
  - cannot find 'CardTagCopy' in scope
  - cannot find 'AlightingTagRecovery' in scope
- 참조 파일: ios/FocusMateTests/BoardingTagControllerTests.swift, ios/FocusMateTests/BoardingTestDoubles.swift (프로덕션 코드 미열람). SuspendingSleep/RecordingAnnouncer/FakeIssuanceHaptics는 기존 테스트 헬퍼로 사용만 함.
