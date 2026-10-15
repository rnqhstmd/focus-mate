# T4 IMPLEMENT (세션)

## 구현 내용
- ios/FocusMate/MainActiveJourneyView.swift (신규): ActiveJourneyCardView(main.activeJourney 한 요소 + main.resumeJourney 형제 버튼), MainAbandonNoticeView(항상 배치, onChange 1회 낭독·포커스), newJourneyConfirmation alert(main.newJourney.keep/confirm)
- ios/FocusMate/RootView.swift: 임시 안내 → 카드·포기 안내·main.saveFailure(@State mainActionFailed, path 변경 시 해제), 시작 버튼 문구 mainStartTitle, 진행 여정 있으면 확인 창, apply(LifecycleActionResult), DEBUG test.writeAttempts·test.main.failNextSave
- ios/FocusMate/UITestBootstrap.swift: life* 이름 시드 10종(lifecycleSnapshot, 현재 정류장=출발지, 기록 1건, 도착지=식), UITestWriteCounter(writeData 첫 줄 기록), route journey 주석

## GREEN 증거
check-ios.py test LifecycleSeedTests JourneyLifecycleModelTests BoardingModelTests JourneyAbandonControllerTests JourneyReachTests ActiveJourneyCardContentTests + UI MainActiveJourneyCardUITests NewJourneyUITests ActiveJourneyMainUITests BoardingLargeTextUITests → 단위 95 pass/0 fail, UI 36 pass/0 fail (첫 실행)

## REFACTOR 내역
정리 없음

## self-review 결과
설계 E-10·E-11·F-12 일치. 시드 이름 고정(파라미터 파서 없음). 테스트 미수정(해시 동일).

## 우려사항
없음
