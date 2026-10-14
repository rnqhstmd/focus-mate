# T5 IMPLEMENT — 마이페이지 화면

## 구현 내용
- ios/FocusMate/ProfileView.swift(신규): ProfileCopy, ProfileStatsDisplay(화면 "3"/"1 h 5 min", 접근성 "완료한 여정, 3회"/"함께한 시간, 1시간 5분", unavailable이면 "-"와 항목 이름만·안내 "기록을 불러오지 못했어요"), ProfileView(전체 ScrollView·하단 고정 없음, 시안 순서, 다크 배경 #0F1012, 좌우 24, toolbarRole(.editor)+leading 제목, 통계 AnyLayout 2열↔접근성 크기 세로, 애니메이션 없음, 쓰기 없음), ProfileMenuRow(pencil / slider.horizontal.3 + chevron, minHeight 44, contentShape), ProfileStatView(children .ignore 한 요소 + 하위 값 식별자 .value).
- ios/FocusMate/DestinationScreen.swift: .profile이면 ProfileView(onCustomize: openFromProfile(.customize)), 그 외 기존 체인(placeholderOrTime). cardStudio는 기존 자리표시 분기.

## GREEN 증거
- RED(뼈대 ProfileStatsDisplay 빈 값): 24건 중 21건 실패, 3건(진입 제목·뒤로·저장 불변 — 기존 자리표시도 만족) 우연 통과 → 회귀 가드.
- focused: ProfileStatsDisplay·ProfileModel·ProfileSeed·ProfileTimeText·RecordLifetimeSummary(45) + ProfileUITests(21)·Phase1FlowTests(10) → 76 pass / 0 fail. 테스트 3파일 해시 불변.

## REFACTOR / 수정 내역
- 1차 실행에서 2건 실패: screen.profile이 2요소로 잡힘(툴바가 제목 래퍼에 식별자 복사) + 제목 폭 19pt로 잘림. → fixedSize, 바깥 HStack에 별도 식별자(profile.titleBar, .contain)로 제목 Text 1요소화. iOS 26+ 툴바 유리 버블은 sharedBackgroundVisibility(.hidden)로 숨겨 시안(버블 없는 제목)과 일치.
- 스크린샷 시안 대조: 제목·문구·카드·라벨·메뉴·통계 순서 일치. 카드 내부(이름 위치·칩·문구)는 W10 합류 시 해소(설계 결정).

## self-review 결과
- AC-1~4, 5(축소), 6, 8, 9, 15, 16, 18~20, 22~27, 29(표시), 32 충족. AC-21: ProfileView에 withAnimation/.animation/.transition/accessibilityReduceMotion 0건(grep).

## 우려사항
- 없음
