# T3 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/AppModel+JourneyLifecycle.swift (신규): activeJourneyCard, mainStartTitle, resumeJourney, consumeResumeEntry, confirmNewJourney, abandonJourney(timerPaused:), AppModel: JourneyAbandoning
- ios/FocusMate/AppModel.swift: abandonNotice·resumeEntryJourneyID 저장 프로퍼티, saveHandlingFailure(실패 시 일반 saveFailure 미설정), open·beginCardCustomization에서 abandonNotice 초기화, goBack 주석
- ios/FocusMate/AppModel+Boarding.swift: startTripFromMain은 진행 여정이 있으면 거부

## GREEN 증거
check-ios.py test JourneyLifecycleModelTests BoardingModelTests JourneyAbandonControllerTests JourneyReachTests ActiveJourneyCardContentTests → 86 pass / 0 fail (첫 실행 통과)

## REFACTOR 내역
정리 없음

## self-review 결과
설계 C-4~6 일치. 단일 저장(endingActiveJourney), 상태 가드 기반 연타 방지, BR-6 timerPaused 가드. 테스트 미수정.

## 우려사항
없음

## 과잉 구현 정리
- 유지(설계 예약): activeJourneyCard·mainStartTitle 중 테스트가 직접 참조하지 않는 경로는 T4(RootView)가 사용.
