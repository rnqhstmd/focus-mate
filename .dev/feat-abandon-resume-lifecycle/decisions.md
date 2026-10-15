# 의사결정 기록

AskUserQuestion으로 오간 질문과 선택을 자동 기록한다. 고른 것뿐 아니라 버린 선택지도 남으므로 왜 그렇게 정했는지가 추적된다.

## 2026-10-15 16:31 · Ruling: T5 테스트 도우미 중복 정리 유예

**판정.** T5 리뷰 Important 1건([동작불변] — JourneyResume/JourneyAbandon/JourneyLifecycleSafety UI 테스트의 resumeFromMain·launchPaused·announcement 줄 세기 도우미 복제)을 이번 브랜치에서 수정하지 않고 Deferred로 둔다.
**근거.** 테스트 파일만의 유지보수 문제이며 동작 영향이 없다. 정리하려면 테스트 수정 권한이 있는 red-writer 재호출과 UI 60여 건 재실행(약 25분)이 필요해, 사용자의 속도 요청 대비 이득이 작다. 마지막 전체 테스트 실행으로 회귀는 따로 확인한다.
**틀리면.** reports/t5-review.md의 권고대로 세 도우미를 UITestLaunchSupport.swift의 FocusMateUIHarness 확장으로 옮기고 세 파일을 재실행하면 된다(후속 작업).

## 2026-10-15 16:31 · Ruling: T5 Minor 처리

**판정.** JourneyView.swift 하단 inset 주석을 실제 동작(일시정지가 아니면 버튼 없이 아래 여백 8pt)으로 고쳤다(주석만). 나머지 Minor 5건은 유예.
**근거.** 코드 동작 불변, 레이아웃 재검증 불필요.
**틀리면.** 주석 한 줄 되돌리기.

## 2026-10-15 16:36 · Ruling: review 동작 불변 정리 1건

**판정.** 통합 리뷰 Important 1건(docs/FLOWS.md W04 절의 없어진 임시 안내 문장)을 정리했다. 같은 김에 같은 절의 "버전 3" 저장 형식 문장을 현재(버전 4) 기준으로 고쳤다(보안 감사 MEDIUM 중 문서 모순 항목).
**근거.** 문서만의 동작 불변 정리라 테스트 재실행이 필요 없다.
**틀리면.** git diff docs/FLOWS.md 두 줄 되돌리기.

## 2026-10-15 16:36 · Ruling: review Minor 7건 유예 · MEDIUM 11건 중 1건 정리·10건 유예

**판정.** quality Minor 7건은 유예(reports/review-deferred.md). security MEDIUM 11건 중 문서 모순 1건만 정리하고, 나머지 10건(동작 변경 동반·이월·실기기 항목)은 유예.
**근거.** 남은 MEDIUM은 동작 변경(체크포인트 실패 후 포기 숨김, 도착 화면 나가기, saveJourneyProgress 단조성 가드, 도착 여정 확인 문구)이거나 W14 출시 게이트(Release 빌드 심볼 확인, alert 첫 포커스)·W05 이월 수용 항목이다. 동작 변경은 RED 없이 손대지 않는다.
**틀리면.** review-deferred.md 항목을 후속 작업으로 RGR 진행.
