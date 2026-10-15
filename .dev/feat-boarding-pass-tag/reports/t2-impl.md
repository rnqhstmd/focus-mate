# T2 IMPLEMENT — 순수 규칙

## 구현 내용
- 신규 `ios/FocusMate/BoardingRules.swift`: `BoardingGeometry`(clampedOffset 좌우 ±26·위 태그 위쪽·아래 20, overlapRatio = 교집합÷태그 면적, isContact ≥0.30, isTap 거리<8, activationOffset = 0.30×태그면적÷min(카드폭,태그폭)+8, x 중심 정렬), `BoardingTiming`(300/1400/450ms, 동작 줄이기 시 contact·fade 0), `BoardingClock.text`(그레고리력·주어진 타임존 HH:mm).
- 신규 `ios/FocusMate/BoardingPassContent.swift`: 승차권 값(출발·도착·"N개"·거리(PreparedJourneyDetails.distanceText 재사용)·"지금"·yyyy/MM/dd·태그·할 일), 정류장 글꼴 4/6/9자 경계, 낭독 라벨 "{출발}에서 {도착}까지, {kind} {number}번 버스, {분}분 여행".
- `IssuanceHapticPattern.swift`: `.boardingContact`(0.12s 약한 연속 + 탭 1회).

## GREEN 증거
focused(T1+T2 4파일) 72 pass / 0 fail.

## REFACTOR 내역
정리 없음.

## self-review 결과
- 경계값(29.9/30/30.1%, 7.9/8.0, 대각선) 통과, 카드 폭 238/268/300 활성 위치 임계 이상.
- 날짜·시각은 DateFormatter 대신 Calendar 컴포넌트로 로캘 비의존.
- 과잉 구현: tagAreaSize·cardWidth·terminalEntrance·cardEntrance·boardingContact는 테스트 미참조이나 설계서 인터페이스 명시 → 설계 예약(T6 화면에서 사용).

## 우려사항
없음.
