# T4 IMPLEMENT (세션)

## 구현 내용
- 수정 ios/FocusMate/BoardingTagController.swift: JourneyAlighting 프로토콜, CardTagCopy(.boarding 기존 문구 / .alighting "집중동행카드 인식됨, 하차했습니다"·transitionFailureText), AlightingTagRecovery.shouldFinish, 내부 의존을 save 클로저 + copy로 일반화(private 지정 init), 기존 init(boarder:)와 신규 init(alighter:)는 convenience. 상태 기계·기하·타이밍 불변. 기존 static 문구는 CardTagCopy.boarding 값으로 호환.

## GREEN 증거
AlightingTagControllerTests 9/0, BoardingTagControllerTests 22/0(회귀, 무수정), T1~T3 신규 50/0 → 81 pass / 0 fail.

## REFACTOR 내역
정리 없음.

## self-review 결과
승차 공개 API(init(boarder:), static 문구) 유지. 테스트 무수정.

## 우려사항
없음
