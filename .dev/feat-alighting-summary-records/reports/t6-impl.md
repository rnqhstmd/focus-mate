# T6 IMPLEMENT (세션)

## 구현 내용
- UITestBootstrap.swift: LifecycleSeed에 task·withRecord·destinationStopID, 시드 alightPaused1499 / alightArrived / alightMismatchArrived(뚝섬역).
- 신규 CardTagScreen.swift: BoardingTagScreen을 CardTagKind(.boarding/.alighting)로 일반화. 식별자 `<prefix>.*`, 하차는 뒤로 숨김+NavigationPopBlocker+카드 첫 초점, LCD "하차 준비", 진단 test.<prefix>에 focus, 하차 DEBUG test.activateAlightingCard·test.alighting.failNextSave, onSettle 훅(onAppear·phase 변경·포그라운드 복귀).
- BoardingTagView.swift: 래퍼만 남기고 CardTagScreen(kind: .boarding) 사용(식별자 불변).
- 신규 AlightingTagView.swift: init(alighter:) 컨트롤러, reconcile = AlightingTagRecovery.shouldFinish(phase, alightingSummary != nil) → finishAlightingTransition.
- 신규 ArrivalBriefingView.swift: alighting.briefing/route/sentence/confirm/saveFailure, test.arrivalBriefing.
- JourneyView.swift: ArrivalBriefingController 생성(progress: timer, confirmer: model), 도착 시 타이머 화면 접근성 숨김·터치 차단 후 오버레이, .task(id: arrived) begin, 백그라운드 reset / 복귀 시 재시작.
- JourneyTimerView.swift: journey.arrived 2곳 제거(EmptyView).
- 신규 AlightingSummaryView.swift: summary.* 식별자, 메모 200자(memoInput onChange로 잘린 값 되돌려 쓰기), 실패 안내, 뒤로 숨김, test.summary.failNextSave.
- DestinationScreen.swift: .alighting/.alightingSummary 연결.
- MainActiveJourneyView.swift / RootView.swift / JourneyLifecycleText.swift: 하차하기(open.alighting), model.mainMenuDestinations, beginAlighting.

## GREEN 증거
- LifecycleSeedTests 전체 통과(alight 6건 포함).
- AlightingFlowUITests 13/13: 1차 9 통과 + 실패 4건(테스트 결함 3건 red-writer R1 수정, 메모 200자 실제 결함 1건 수정) 재실행 4/4 통과.
- 수정된 기존 UI 7파일 + 승차 UI 회귀: (아래 회귀 결과 참조)

## REFACTOR 내역
정리 없음.

## self-review 결과
승차 식별자·문구는 kind로 동일 유지. 요약 nil이면 Color.clear 방어.

## 우려사항
없음

## fix 라운드
- R1: UI 4건 실패 → 테스트 결함 3건(tapHint 순서, AC-4·AC-1 실시간 경합) red-writer 수정, 실제 결함 1건(메모 TextField가 잘린 같은 값을 다시 받지 않아 201자 노출) memoInput onChange로 수정 → 4/4 통과.
- R2: 수정된 기존 UI 114건 중 2건 실패(도착 아래 타이머 "0개"/"남은 시간 0분"이 accessibilityHidden에도 노출) → JourneyTimerView.concealed로 도착 시 내용 비움(onAppear·진단 유지). 그 뒤 두 테스트가 부재 요소 값 읽기로 실패 → red-writer R2(부재 허용) → 2/2 통과. 나머지 112건(승차 회귀 BoardingFlow/LargeText/Tag 포함)은 R2 이전 실행에서 통과.
