# T5 태스크 리뷰 (sonnet, scoped)
SPEC PASS (5/5) · QUALITY FAIL(Important 1 [동작불변]) · Minor 3
Important: 테스트 헬퍼 makeRigWithLeftovers가 makeRig와 ~20줄 중복 (테스트 파일).
Minor: AC-12 기대 endDate가 controller.remainingSeconds 파생 / AC-11 activeActivities 비었는지 미확인 / AC-15 end·start 순서 미고정
처리: Important는 테스트 파일 대상이라 구현 주체(세션)가 수정할 수 없다(테스트 수정 금지). T6 red-writer가 같은 파일에 케이스를 추가 중이므로 테스트 정리는 phase-review 정리 단계로 이월 — decisions.md Ruling 참조.
