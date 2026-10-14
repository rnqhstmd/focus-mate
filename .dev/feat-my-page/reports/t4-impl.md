# T4 IMPLEMENT — 마이페이지 모델·cardStudio 목적지

## 구현 내용
- ios/FocusMate/AppModel.swift: `case cardStudio`(별도 행), title "카드 꾸미기".
- ios/FocusMate/AppModel+Profile.swift(신규): ProfileMenuItem(customize→.cardStudio, settings→.settings), ProfileStats(.loaded/.unavailable, from(_:) 순수 매핑 — lifetimeSummary 실패·nil이면 unavailable), AppModel.profileStats(위임), openFromProfile(path.last == .profile일 때만 open, 연타 차단). 머리 주석에 W10 합류 절차 요약.

## GREEN 증거
- RED(뼈대): 15건 중 8건 단언 실패. 7건(unavailable·false·쓰기 0·메뉴 4개·필드 부재)은 뼈대 값이 기대값과 같아 우연 통과 → 회귀 가드로 유지.
- focused: ProfileModel·ProfileSeed·ProfileTimeText·RecordLifetimeSummary + JourneyStartModel·AppFoundation(회귀) → 69 pass / 0 fail.

## REFACTOR 내역
- 정리 없음.

## self-review 결과
- AC-13·14·15·17·24~28·29·30·33(모델) 충족. 저장 쓰기 없음. CardSnapshot 무변경. 메인 메뉴 4개 유지.

## 우려사항
- 없음
