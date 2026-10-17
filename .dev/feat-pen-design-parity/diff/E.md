# 시안 대 앱 차이 — E 묶음 (R31·R32·R33·R19·R23·R24·R20)

기준: 시안 = `pen/*.png`(402pt, 2x) + `spec/*.txt`, 앱 = `app/*.png`(402pt, 3x). 앱 이미지의 좌표는 pt로 환산했다(픽셀 ÷ 3, 미리보기 기준은 ÷ 2.289).
경로 앞부분 `FM/` = `/Users/bonseung/projects/focus-mate/next-step-w19/ios/FocusMate/`.
태그: **[기능]** = 동작·흐름·데이터 계산을 바꿔야 함. **[데이터]** = 예시 데이터 차이일 뿐이라 고칠 대상이 아님.

## 0. 모든 화면에 공통인 차이 (화면별 개수에는 넣지 않음)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| C1 | 글꼴 | Noto Sans KR (normal / 700) | 서울알림체 Medium/Bold(`FontCatalog.text`), 여행 화면 하단 지표는 SF(`.system`) | 시안 글꼴은 웹 프로토타입 기본값으로 보인다. 서울알림체를 유지할지 결정할 것. 유지한다면 R33 하단 지표의 `.system(size:)`(`FM/JourneyTimerView.swift:201-202`, `182`, `192`)만 `FontCatalog.text`로 맞춘다 |
| C2 | 반투명 패널 테두리 | 덤프에 `fill=#FFFFFF33/#FFFFFF40/#FFFFFF35/#FFFFFF26`이 같은 크기의 겹친 사각형으로 나온다. 이미지를 보면 패널 둘레의 1pt 밝은 테두리다 | `fmPanel`·`FMSecondaryButtonStyle`의 테두리가 없거나 다르다 | 공통 수식어를 추가한다: `func fmSheetPanel() -> some View { padding(…).background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.2), lineWidth: 1)) }` (`FM/FMDesign.swift:41-43` 옆) |
| C3 | 배경 | 3D 도시 일러스트 + 전체 `#00000055`(33%) 어둡게 | MapKit 실지도 | INDEX에 적힌 알려진 차이다. 어둡게 하는 막만 맞추면 된다(각 화면 항목 참고) |
| C4 | 공통 흰 버튼 | `#FFFFFF`, 1pt `#444444` 테두리, 캡슐형, 글자 15pt 보통 굵기 `#000000`, 높이 43~51 | `FMPrimaryButtonStyle`: `#F4F6F2`, 테두리 없음, 반경 24, 글자 17pt Bold, 최소 높이 52(+라벨 44 → 실제 약 68) | `FM/FMDesign.swift:15-20`: 글자 `FontCatalog.text(15)`, 배경 `Color.white`, `.overlay(Capsule().strokeBorder(Color(hex:0x444444), lineWidth:1))`, 모양 `Capsule()`, `minHeight: 44`. R31의 `Text(...).frame(minHeight: 44)`와 이 스타일의 `.padding(.vertical,12)`가 겹쳐서 높이 68이 되므로, 버튼 쪽 `.frame(minHeight:44)`를 빼고 스타일에서 `.padding(.vertical, 0)` + `.frame(minHeight: 44)`로 둔다 |
| C5 | 상태 표시줄 | 시안은 가짜 상태 표시줄("9:41", "▰") | 실제 시스템 상태 표시줄 | 차이 아님 |

---

## R31-resume-prev (메인 · 잠시 멈춘 여정)

관련 파일: `FM/MainHomeView.swift`, `FM/MainActiveJourneyView.swift`, `FM/JourneyLifecycleText.swift`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 상단 도구 구성 **[기능]** | 오른쪽 위 원형 버튼 2개(기록, 마이페이지)만 있다. 왼쪽 "Focus Mate" 워드마크 없음 | 워드마크 + 버튼 4개(기록·마이페이지·설정·카드) | `MainHomeView.swift:59-61` 워드마크를 지우고, `:65`(설정)와 `:66-73`(카드 꾸미기)도 지운다. 설정은 `ProfileView.swift:74`의 마이페이지 메뉴로, 카드 꾸미기는 마이페이지 `onCustomize`로 들어간다(설정 진입 경로가 하나 줄어든다) |
| 2 | 도구 버튼 모양 | 43×43, 채움 `#0A0A0A` 75%(`BF`), 1pt `#444444` 테두리, 버튼 간격 11pt, 오른쪽 여백 16pt, 위쪽 y=61 | 44×44, `panel` 85%, 테두리 없음, 간격 10, 좌우 여백 20, 위쪽 약 y=70 | `MainHomeView.swift:79-81`: `.background(FMDesign.panel.opacity(0.75), in: Circle()).overlay(Circle().strokeBorder(Color(hex:0x444444), lineWidth: 1))`(44pt는 그대로). `:58` HStack 간격 11, `:34` `.padding(.horizontal, 16).padding(.top, 0)`으로 위쪽을 9pt 올린다 |
| 3 | 도구 아이콘 | 기록 = 줄 있는 문서(테두리 선 12×15), 마이페이지 = 사람 윤곽선(머리 7pt + 어깨 14×9), 선 1.5pt 흰색 | `book.closed`, `person.crop.circle`(원 안에 사람) 19pt | `:63` → `doc.text`, `:64` → `person`, `.font(.system(size: 17, weight: .regular))` |
| 4 | 인사말 색 | 15pt `#E1E5E8` | 15pt `#BFC6C1`(secondaryText) | `:92` `.foregroundStyle(Color(hex:0xE1E5E8))` |
| 5 | 제목 문구 **[기능]** | 진행 중 여정이 있으면 "{정류장}에서,\n잠깐, 나에게 집중해요." | 항상 "{정류장}에서,\n나만의 속도로 출발해요." | `:102-105` `welcomeTitle`: `model.activeJourneyCard != nil`이면 `"\(name)에서,\n잠깐, 나에게 집중해요."` |
| 6 | 제목 글자 뒤 띠 | 줄마다 `#00000088`(53%) 사각형(높이 49, 글자 왼쪽 10pt·오른쪽 약 5pt까지), 반경 0. 글자는 2pt 아래 그림자 | 띠 없음, 그림자 없음 | `:94-97`: 두 줄을 따로 `Text`로 나누고 각각 `.padding(.horizontal, 10).padding(.vertical, 10).background(Color.black.opacity(0.53))`, `.shadow(color: .black.opacity(0.6), radius: 0, y: 2)`. VStack `spacing: 0`(줄 간격 39pt: 168 → 207) |
| 7 | 제목 줄 간격 | 28pt Bold, 줄 간 39pt | 28pt, 줄 간 약 31pt | 6번에서 두 줄을 분리하면 맞는다(줄 높이 49pt 중 10pt 겹침, `spacing: -10`) |
| 8 | 위쪽 그라디언트 | 없음. 화면 전체 `#00000055` 한 겹 | 위쪽 `background` 92%→55%→0 그라디언트 | `MainHomeView.swift:26-31` 그라디언트를 `Color.black.opacity(0.33)`으로 바꾼다 |
| 9 | 현재 정류장 블록 **[기능]** | 없음 | 카드 위에 "현재 정류장 / 성수역 / 성수동 방면" | `:139-150`을 지운다. 접근성 식별자 `screen.main`·`main.currentStation`·`main.bound`는 숨긴 요소로 남기거나 카드 접근성 라벨로 옮긴다(UI 테스트 영향) |
| 10 | 지도 정류장 핀 | 없음 | 가운데 회색 핀 + "성수역" | `:24` `showsStationAnnotation: model.activeJourneyCard != nil` → `false` |
| 11 | 카드 위치·크기 | x=18, 366×246, 위 y=551, 아래 y=797 | x=20, 약 361 폭, 위 약 y=535 | `:44` 가로 여백 20 → 18. 아래 15번과 함께 맞춘다 |
| 12 | 카드 안 배치 | 제목 21 Bold(y577) → 26 → 할 일(y624) → 21 → 버스줄(y662) → 11 → 노선(y686) → 28 → 버튼(y726). 위아래 안쪽 여백 26/20, 좌우 20 | VStack 간격 4 / 12, 안쪽 여백 20 | `MainActiveJourneyView.swift:11-12`: 바깥 `spacing: 28`. 정보 묶음은 각 요소 사이 `.padding(.top,…)`으로 26/21/11을 준다. `:41` `.fmPanel(padding: 20)` + `.padding(.top, 6)` |
| 13 | 할 일 색 | 17 Bold `#AAAAAA` | 17 Bold 흰색(primary) | `:14` `.foregroundStyle(Color(hex:0xAAAAAA))` |
| 14 | 남은 시간 위치·크기 | "15 min 남음" 14pt Bold 흰색, 버스줄("지선 2014")과 **같은 줄 오른쪽 정렬** | 20pt Bold, 혼자 한 줄 | `:15-16`: `HStack { Text(busText)…; Spacer(); Text(remaining).font(FontCatalog.text(14, bold: true)) }` |
| 15 | 버스줄 색 | 13pt `#C1CBC3` | 13pt `#BFC6C1` | `:15` `Color(hex:0xC1CBC3)`(차이가 아주 작음) |
| 16 | 노선 글자 | 12pt `#A6B1A8` | 13pt `#BFC6C1` | `:17` `FontCatalog.text(12)`, `Color(hex:0xA6B1A8)` |
| 17 | 이어가기 버튼 | 325×51(카드 안쪽 여백 21), 흰색 `#FFFFFF` + `#444444` 테두리, 캡슐형, 글자 15pt 보통 굵기 검정, "이전 여정 이어가기 →" | 높이 약 68, `#F4F6F2`, 반경 24, 17pt Bold | C4 공통 수정 + `:25-27` `.frame(height: 51)` |
| 18 | "새 여정 시작" 버튼 | 366×44, 채움 `#0A0A0A` 85%, 테두리 흰색 21%(`#FFFFFF35`), 글자 13pt 보통 굵기 흰색, 가운데 정렬, **화살표 없음** | 15pt, 테두리 primary 30%, 오른쪽에 `arrow.right` | `MainHomeView.swift:174-184`: 진행 중 여정이 있을 때는 `Image(systemName:"arrow.right")`를 빼고 `.font(FontCatalog.text(13))`. `FMSecondaryButtonStyle`(`FMDesign.swift:35`)의 테두리를 `Color.white.opacity(0.21)`, 모양을 `Capsule()`로 |
| 19 | 카드와 버튼 간격 | 5pt(797 → 802) | 12pt | `:137` footer VStack에서 카드 다음 간격만 5(`spacing: 12` 유지 + 버튼에 `.padding(.top, -7)`, 또는 카드와 버튼을 `VStack(spacing: 5)`로 묶는다) |
| 20 | 아래 여백 | 버튼 아래가 y=846(화면 아래에서 28pt) | 버튼 아래 약 y=823(51pt) | `:44` `.padding(.bottom, 16)` → 홈 인디케이터 영역으로 내려야 한다. ScrollView에 `.ignoresSafeArea(.container, edges: .bottom)` + `.padding(.bottom, 28)` |
| 21 | 인사말·제목 위치 | 인사말 y135, 제목 y168 | 인사말 약 y142, 제목 약 y165 | 2번에서 도구 줄을 9pt 올리면 인사말도 9pt 올라간다. `:99` `.padding(.top, 12)` → `.padding(.top, 19)`로 인사말을 y135에 맞춘다 |
| D | [데이터] | 할 일 "책 한 챕터 읽기", 정류장 뚝섬, 인사말 "오늘도 수고했어요."(저녁) | "생명주기 시드", 성수역, "좋은 아침이에요."(오전 캡처) | 수정 대상 아님 |

**차이 21개**(데이터 차이 제외)

---

## R32-new-confirm (새 여정 확인 창)

R31 화면 위에 확인 창을 띄운 상태다. 배경 차이는 R31과 같다. 관련 위치: `FM/MainActiveJourneyView.swift:60-72`(`newJourneyConfirmation`), `FM/RootView.swift:37`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 창 종류 **[기능]** | 직접 그린 카드형 창 | 시스템 `alert`(iOS 26 유리 스타일) | `newJourneyConfirmation`을 `ZStack` 오버레이로 다시 만든다. `RootView`의 `.newJourneyConfirmation(...)` 대신 `.overlay { if confirmsNewJourney { NewJourneyDialog(...) } }`. 접근성: `.accessibilityAddTraits(.isModal)`, 닫기 동작(`.accessibilityAction(.escape)`)을 "유지"에 연결. 식별자 `main.newJourney.keep`/`confirm`은 그대로 쓴다(UI 테스트는 alert 쿼리 → button 쿼리로 바꿔야 함) |
| 2 | 뒤 어둡게 하기 | 전체 `#00000099`(60%) | 시스템 alert 기본(약 20~30%) | `Color.black.opacity(0.6).ignoresSafeArea()` |
| 3 | 창 크기·위치 | x=22, 358×252, y=311(세로 가운데), 반경 약 24 | 약 318 폭, y≈337 | `.frame(width: 358)` 대신 `.padding(.horizontal, 22)`, 세로 가운데 |
| 4 | 창 배경·테두리 | `#0C0C0C`, 테두리 흰색 25%(`#FFFFFF40`) 1pt | 유리 블러 | `.background(Color(hex:0x0C0C0C), in: RoundedRectangle(cornerRadius: 24)).overlay(RoundedRectangle(cornerRadius:24).strokeBorder(.white.opacity(0.25)))` |
| 5 | 제목 | 23pt Bold 흰색, 왼쪽 정렬(x=47, 안쪽 여백 25), y=339(위 여백 28) | 시스템 17pt Semibold | `Text(JourneyLifecycleText.newJourneyTitle).font(FontCatalog.text(23, bold: true))`, `.padding(.top, 28)` |
| 6 | 본문 | 13pt `#AAAAAA`, 줄 높이 21pt, 제목 아래 24pt, 폭 안에서 자연스럽게 줄바꿈("…완료 기록은 / 남기지 않아요.") | 시스템 15pt 회색, 줄바꿈 "…준비해요. / 완료 기록은…" | `.font(FontCatalog.text(13)).foregroundStyle(Color(hex:0xAAAAAA)).lineSpacing(8)` |
| 7 | 버튼 순서 | 위 "이전 여정 유지하기", 아래 "새 여정 시작" | 위 "새 여정 시작", 아래 "유지하기" | 유지 → 새 여정 순서로 둔다 |
| 8 | "유지하기" 버튼 | 307×43, 흰색 + `#444444` 테두리, 캡슐형, 15pt 보통 굵기 검정 | 유리 회색 캡슐, 흰 글자 | C4 흰 버튼 스타일, `.frame(height: 43)` |
| 9 | "새 여정 시작" 버튼 | 307×43, `#111111` + `#444444` 테두리, 15pt 보통 굵기 흰색(빨강 아님), 위 버튼과 간격 13 | 빨간 글자(destructive) | `.background(Color(hex:0x111111), in: Capsule()).overlay(Capsule().strokeBorder(Color(hex:0x444444)))`, `.foregroundStyle(.white)`. 낭독용으로만 `role: .destructive` 의미를 라벨에 남긴다 |
| 10 | 초점 고리 | "유지하기" 둘레 금색 `#D7B378` 고리(318×54, 바깥으로 약 5.5pt 떨어짐, 2pt) — 기본 선택 표시 | 없음 | 창이 열릴 때 `@AccessibilityFocusState`를 유지 버튼에 둔다. 보이는 고리는 `.overlay(Capsule().inset(by: -5.5).stroke(Color(hex:0xD7B378), lineWidth: 2))`(포커스일 때만) |
| 11 | 버튼 영역 여백 | 버튼 x=48(창 안쪽 26), 마지막 버튼 아래 25pt | — | `.padding(.horizontal, 26).padding(.bottom, 25)` |
| — | R31에서 이어지는 차이 | 상단 도구·제목·카드·버튼 | R31과 같음 | R31 수정으로 같이 해결된다(따로 세지 않음) |

**차이 11개**

---

## R33-resumed (이어간 여정 · 지도 타이머)

관련 파일: `FM/JourneyTimerView.swift`, `FM/JourneyMapView.swift`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 일시정지 버튼 | 46×46, 채움 `#080808` 80%(`CC`) + 테두리 흰색 15%(`#FFFFFF25`), 위치 (16, 60), 아이콘은 가는 두 막대(약 10×13pt) | 48×48, 검정 60%, 테두리 없음, 위치 약 (16, 70), `pause.fill` 20pt Bold | `JourneyTimerView.swift:128-130`: `.font(.system(size: 14, weight: .semibold))`, `.frame(width: 46, height: 46)`, `.background(Color(hex:0x080808).opacity(0.8), in: Circle()).overlay(Circle().strokeBorder(.white.opacity(0.15)))`. 44pt 이상이라 누르는 영역은 그대로 충분하다 |
| 2 | 위쪽 위치 | 버튼 위 y=60 | y≈70 | `:111` `.padding(.top, 8)` → `.padding(.top, -2)`(또는 0 + 상단 safe area 보정) |
| 3 | 노선 버튼 **[기능]** | 일시정지 아래 44×44 버튼(노선/경로 아이콘 — 위아래 점 2개를 잇는 꺾은 선), y=116, 같은 반투명 스타일 | 없음 | `topBar`(`:96-112`)의 왼쪽을 `VStack(spacing: 10) { roundControl; routeButton }`으로 바꾼다. 동작(노선 한 바퀴 보기 / 경로 전체 보기)을 새로 정해야 한다. 아이콘 `point.topleft.down.to.point.bottomright.curvepath` 16pt |
| 4 | 따라가기 버튼 | 43×43, 채움 흰색 12.5%(`#FFFFFF20`), **1pt 흰 테두리**, 조준점 아이콘(원 + 가운데 점), 위치 (341, 61) | 48pt 검정 60%, `location.fill` 화살표 18pt Semibold | `:102` 아이콘 → `scope`. `toolButton`(`:141-143`)에 스타일 인자를 더해 따라가기만 `.background(.white.opacity(0.125), in: Circle()).overlay(Circle().strokeBorder(.white, lineWidth: 1))`, 크기 44 |
| 5 | 지도 테마 버튼 | 46×46, `#080808` 80% + 흰색 15% 테두리, (340, 114) | 48pt 검정 60% | `:141-143` 기본 스타일을 1번과 같게 바꾼다. `:101` `VStack(spacing: 12)` → `spacing: 7`(61+43=104 → 114) |
| 6 | 초점 고리 | 일시정지 둘레 금색 `#D7B378` 고리 56×56(5pt 떨어짐) — 이어간 직후 초점이 일시정지에 있음 | 첫 초점이 남은 시간 표시(`remainingFocused`, `:36`) | 시안대로라면 재개 직후 초점을 일시정지 버튼으로 옮긴다(접근성 동작 변경이므로 PRD FR-12와 대조 필요). 보이는 고리는 `.overlay(Circle().inset(by:-5).stroke(Color(hex:0xD7B378), lineWidth: 2))`(포커스일 때만) |
| 7 | 노선 선 색 **[기능]** | 지나온 구간 = 초록 `#168445` 굵은 선, 남은 구간 = 흰색 27%(`#FFFFFF44`) 가는 선 | 한 색 파랑 `#5C9EFF` 5pt | `JourneyMapView.swift:26-27`: 컨트롤러에서 지나온 점/남은 점을 나눠 `MapPolyline` 2개를 그린다. 지나온 구간 `.stroke(Color(hex:0x168445), lineWidth: 4)`, 남은 구간 `.stroke(.white.opacity(0.27), lineWidth: 2)` |
| 8 | 정류장 점 | 7pt, 지난 정류장 `#777777`, 남은 정류장 `#FFFFFF`, 둘 다 1pt `#0A0A0A` 테두리 | 10pt 흰색, 검정 40% 테두리 | `:30-31`: `.frame(width: 7, height: 7)`, 지난 여부로 색을 나누고 `.stroke(Color(hex:0x0A0A0A), lineWidth: 1)` |
| 9 | 도착 정류장 표시 | 16pt 원, 채움 `#0A0A0A`, 초록 `#168445` 테두리(2pt), 가운데 흰 점 7pt | 주황 `flag.fill` 16pt | `:36`: `ZStack { Circle().fill(Color(hex:0x0A0A0A)).overlay(Circle().stroke(Color(hex:0x168445), lineWidth: 2)); Circle().fill(.white).frame(width:7,height:7) }.frame(width:16,height:16)` |
| 10 | 버스 표시 | 위에서 본 초록 버스 그림 76×97(이미지) | 파란 원 안의 흰 `location.north.fill` 화살표 | 에셋 `BusTopDown`(초록 `#2E9E4F` 계열)을 추가해 `:40-42`를 `Image("BusTopDown").resizable().frame(width: 38, height: 48)`로 바꾼다(시안 76×97은 확대 그림이라 실제 크기는 지도 축척에 맞춰 정한다). 회전은 그대로 둔다 |
| 11 | 화면 어둡게 하기 | 지도 위 전체 `#00000055`, 아래 그라디언트 없음 | 아래 그라디언트(검정 0→73%→88%) | `JourneyTimerView.swift:52-62` 그라디언트를 지우고 `Color.black.opacity(0.33)` 한 겹. 지표 글자 대비가 떨어지면 아래 40%만 0→33% 정도로 약하게 둔다 |
| 12 | 하단 지표 라벨 | 10pt `#B5B5BA` | 12pt 흰색 64% | `:22` `labelSize = 10`, `:201` `.foregroundStyle(Color(hex:0xB5B5BA))` |
| 13 | 남은 시간 숫자/단위 | "15" 28pt Bold 흰색 + " min" 15pt 보통 굵기 `#AAAAAA` | "15 min" 전체 30pt Bold | `:170` `value`를 `Text("\(controller.remainingMinutes)").font(28 bold) + Text(" min").font(15).foregroundColor(Color(hex:0xAAAAAA))`. `JourneyTimerDisplay.text`는 낭독·다른 화면에서 쓰므로 그대로 둔다 |
| 14 | 남은 정류장 숫자/단위 | "3" **19pt** Bold `#DDDDDD` + "개" 11pt `#BBBBBB`(가운데 열만 작음) | "3" 30pt Bold + " 개" 15pt | `:181-182`: `Text(stops).font(19 bold).foregroundColor(Color(hex:0xDDDDDD)) + Text("개").font(11).foregroundColor(Color(hex:0xBBBBBB))`(앞 공백 제거) |
| 15 | 남은 거리 숫자/단위 | "1.6" 30pt Bold + "km" 13pt `#AAAAAA`(공백 없음) | "1.6" 30pt + " km" 15pt 흰색 | `:191-192`: `+ Text("km").font(13).foregroundColor(Color(hex:0xAAAAAA))` |
| 16 | 지표 위치·간격 | 라벨 y=781, 라벨과 숫자 간격 약 5pt, 숫자 아래 y≈832, 좌우 여백 20 | 라벨 y≈772, 간격 2, 숫자 아래 약 812, 좌우 여백 16 | `:200` `spacing: 5`, `:165` `.padding(.horizontal, 20).padding(.vertical, 14)` → 아래 여백을 8로 줄이고 하단 safe area 일부를 쓴다(`.padding(.bottom, -12)` 또는 `ignoresSafeArea(.container, edges: .bottom)` + `.padding(.bottom, 42)`) |
| 17 | 지표 정렬 | 가운데 열: 라벨 x=186, 숫자 x=200(열 안에서 가운데 정렬), 오른쪽 열: 라벨·숫자 모두 오른쪽 정렬(x 끝 382/384) | 가운데·오른쪽 열 안에서 내용이 **왼쪽** 정렬(`infoColumn`이 `.leading`) | `:199-200` `infoColumn`에 정렬 인자를 받아 가운데 열은 `.center`, 오른쪽 열은 `.trailing` |
| D | [데이터] | 15 min · 3개 · 1.6km | 같음 | — |

**차이 17개**

---

## R19-records (여행 기록 · 잔디)

관련 파일: `FM/RecordsView.swift`, `FM/RecordsCalendar.swift`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 화면 형태 **[기능]** | 전체 화면 지도 배경 위에 뜬 패널(x=12, y=116, 378×738, 아래 여백 20). 탐색 막대 없음 | push 화면: 시스템 원형 뒤로 버튼, 위에 지도 띠 120pt, 그 아래 패널이 스크롤 | `RecordsView.swift:29-56`: `ZStack { SceneMapBackdrop(...).ignoresSafeArea(); Color.black.opacity(0.33); 패널 }`. 패널은 `.padding(.top, 116 - safeTop).padding(.bottom, 20).padding(.horizontal, 12)`, 패널 안쪽만 ScrollView. `.toolbar(.hidden, for: .navigationBar)` |
| 2 | 닫기 버튼 **[기능]** | 오른쪽 위 "×" 23pt 흰색(x=341, y=145) | 없음(시스템 뒤로 버튼) | 제목 HStack 오른쪽에 `Button { model.path.removeLast() } label: { Image(systemName: "xmark").font(.system(size: 20, weight: .light)).frame(width: 44, height: 44) }.accessibilityLabel("닫기")` |
| 3 | 패널 테두리 | 흰색 20% 1pt(C2) | 없음 | `:54` `.fmPanel()` → C2의 `fmSheetPanel()` |
| 4 | 패널 위 여백 | 제목 y=144(패널 위에서 28) | 22 | `.padding(.top, 28)` |
| 5 | 탭 문구 | "잔디" / "분석" | "잔디" / "분석 보기" | `:40` `"분석 보기"` → `"분석"` |
| 6 | 탭 모양 | 바깥 332×42 `#181C19` 반경 10, 선택 칸 162×36 `#303B34`(초록 회색) 반경 8, 안쪽 여백 3. 글자 12pt 보통 굵기, 선택 흰색 / 비선택 `#BFC6C1` | 바깥 높이 50, primary 6%, 선택 칸 primary 12%(회색), 13pt(선택은 Bold) | `:36-46`: 글자 `FontCatalog.text(12)`(Bold 빼기), 선택 칸 `Color(hex:0x303B34)`, `frame(minHeight: 36)`, 바깥 `Color(hex:0x181C19)`. 누르는 영역은 `.contentShape` + 바깥 `padding(3)`으로 42pt(44에 가깝게 위아래 1pt 추가) |
| 7 | 탭 동작 **[기능]** | 기록과 분석이 같은 패널 안에서 탭으로 바뀐다(R23 시안도 같은 탭이 보이고 "분석"이 선택됨) | "분석 보기"를 누르면 새 화면 push | `RecordsView`에 `@State var tab: .heatmap/.analytics`를 두고 `RecordsAnalyticsView`의 본문을 패널 안에 넣는다(`:62-70`의 `navigationDestination`을 탭 전환으로). 위젯 진입(`consumeWidgetAnalyticsEntry`)은 `tab = .analytics`로 |
| 8 | 안내 문구 | 탭 아래 "예시 기록 · 날짜를 눌러 둘러보세요." 11pt `#BFC6C1`(y=247) | 없음 | 고정 문구 "날짜를 눌러 둘러보세요."를 추가(`FontCatalog.text(11)`, secondaryText). "예시 기록 · " 앞부분은 예시 데이터일 때만 붙인다 |
| 9 | 연도 머리줄 | 왼쪽 "2026년의 여행" 18pt Bold 흰색, 오른쪽 "‹ 올해 ›"(작은 갈매기 5×9, "올해" 11pt `#D2DDD6`) | "‹ [2026년] ›" — 가운데 흰 알약 메뉴 18pt Bold, 갈매기 기본 크기 | `yearBar`(`:111-136`)를 `HStack { Text("\(year)년의 여행").font(18 bold); Spacer(); 이전 버튼; Button("올해") { browser.selectYear(today.year) }.font(11).foregroundStyle(Color(hex:0xD2DDD6)); 다음 버튼 }`로. 갈매기 `.font(.system(size: 12, weight: .regular))`, 누르는 영역 44 유지 |
| 10 | "올해" 버튼 **[기능]** | 올해로 돌아가기 | 없음(메뉴로 연도 고르기만) | 9번에 포함. `browser.selectYear(browser.today.year, records:)` |
| 11 | 연도 칩 줄 **[기능]** | 요약 아래 "2026"(선택: 64×44 `#F3F6F3` 반경 8, 12pt `#0A0A0A`) "2025"(12pt `#C5CDC7`, 배경 없음) | 없음(`Menu`가 대신함) | `:118-129`의 `Menu`를 `HStack(spacing: 8)` + `ForEach(RecordsCalendar.yearOptions(...))` 칩 버튼으로 바꾼다. 각 칩 `.frame(width: 64, height: 44)` |
| 12 | 순서 | 탭 → 안내 → 연도 머리줄 → 요약 → 연도 칩 → 잔디 상자 → 범례 → 날짜 찾기 줄 → 구분선 → 날짜 목록 → 버튼 | 탭 → 연도 막대 → 요약 → 잔디(+범례) → 목록 | `:33-52` VStack을 시안 순서로. 간격(위→아래): 22·16·30·22·19·22·10·44·38·19 — `spacing: 0`으로 두고 요소마다 `.padding(.top, …)` |
| 13 | 요약 색 | 12pt `#C3CDC6` | 12pt `#BFC6C1` | `:49` 색만(아주 작음) |
| 14 | 잔디 상자 | 332×85, `#0B100D`, 흰색 15% 테두리, 반경 약 6. 월 라벨은 상자 안 위 15pt, 칸은 왼쪽 32pt부터 | 상자 없음 | `heatmap`(`:138-204`) 바깥에 `.padding(.top, 15).padding(.horizontal, 10).padding(.bottom, 12).background(Color(hex:0x0B100D), in: RoundedRectangle(cornerRadius: 6)).overlay(… .strokeBorder(.white.opacity(0.15)))`. 범례(`:175-185`)는 상자 밖으로 뺀다 |
| 15 | 칸 크기 | 4×4, 간격 1.5(5.5 간격), 7줄 높이 37 | 폭에서 계산(약 4.4) | 상자 안쪽 폭이 줄어 자동으로 약 4가 된다. `:145`의 `- 20`을 `- 32`로 |
| 16 | 선택 날짜 표시 | 7×7 흰 테두리(칸 바깥으로 1.5pt 커짐) | 칸과 같은 크기 1pt primary 테두리 | `:168-169`: `.overlay(RoundedRectangle(cornerRadius: 2).stroke(.white, lineWidth: 1).frame(width: side + 3, height: side + 3))` |
| 17 | 범례 | 상자 아래 10pt `#B8C4BC`: 왼쪽 "하루 여행 시간", 오른쪽 9×9 칸 5개(간격 3) 다음 "적음 → 많음" | 9pt secondaryText, "적음 ■■■■■ 많음", 칸 8×8 간격 4 | `:175-184`: `Text("하루 여행 시간"); Spacer(); HStack(spacing: 3) { 칸 5개 9×9 }; Text("적음 → 많음")`, `.font(FontCatalog.text(10)).foregroundStyle(Color(hex:0xB8C4BC))`. "많음" 단독 라벨은 없앤다 |
| 18 | "확대해서 보기" **[기능]** | 범례 아래 왼쪽 11pt `#DDDDDD` 버튼 | 없음 | 잔디를 크게 보는 화면/시트를 새로 만든다(접근성 큰 글씨에서 쓰는 14pt 칸 + 가로 스크롤 배치를 재사용할 수 있다, `:144-147`) |
| 19 | "날짜 찾기" **[기능]** | 오른쪽에 라벨 "날짜 찾기" 11pt `#BFC6C1` + 날짜 칸 135×44(`#101612` + 흰색 15% 테두리, 반경 6, "2026-10-12" 12pt `#EFF3EF`, 오른쪽 달력 아이콘 흰색 9×10) | 없음 | `DatePicker("", selection:…, in: …...today, displayedComponents: .date).datePickerStyle(.compact)`를 같은 모양 상자로 감싸고 `browser.select(RecordDay.from(date))`. 식별자 `records.findDate` |
| 20 | 구분선 | 날짜 찾기 줄과 목록 사이 332×1 흰색 14%(`#FFFFFF24`) | 없음 | `Rectangle().fill(.white.opacity(0.14)).frame(height: 1)` |
| 21 | 날짜 머리줄 문구 | "10월 12일 월요일" 16pt Bold(요일 포함) | "10월 17일"(요일 없음) | `:209` 요일을 붙인다: `RecordDay`에 `weekdayName`(일~토요일)을 추가하고 `"\(m)월 \(d)일 \(weekday)"` |
| 22 | 하루 요약 **[기능]** | 날짜 머리줄 오른쪽 "2회 · 1 h 15 min" 11pt `#C3CDC6` | 없음 | `HStack(alignment: .firstTextBaseline) { 날짜; Spacer(); Text("\(count)회 · \(ProfileTimeText.display(minutes:))") }` — 개수·합계는 `RecordsCalendar.records(on:in:)`에서 구한다 |
| 23 | 기록 줄 구성 | 할 일 16pt Bold → 12pt 아래 "출발 → 도착" 11pt `#BFC6C1` → 12pt 아래 "태그 · 25 min · 버스번호" 11pt **태그 색**(독서 = `#D7B378`) | 할 일 → "12:00 · 25 min · 독서" 12pt → "2014 · 성수역 → 서울숲 입구" 12pt, 모두 secondaryText, 간격 4 | `:226-229`: 2줄째 `Text("\(record.from) → \(record.to)").font(11)`, 3줄째 `Text("\(tag) · \(minutesText) · \(record.bus)").font(11).foregroundStyle(Color(hex: record.tagColor))`, `spacing: 12`(할 일 아래 12, 그다음 12). 완료 시각(`timeText`)은 빼거나 낭독 라벨에만 남긴다. `RecordListItemContent.routeText`(`RecordsCalendar.swift:237`)도 맞춘다 |
| 24 | 메모 버튼 **[기능]** | 기록 줄에 "메모 남기기" 없음 | 줄마다 "메모 남기기" 12pt 버튼 | 시안에는 다른 진입점이 없다(R25 홈 메모 카드는 앱에 없음). 지우려면 기록 줄 전체를 눌러 메모 편집을 열게 바꾼다(`:232-237`, 식별자 `records.memo.*` 유지). 지우지 않는다면 시안 쪽에 반영 요청 |
| 25 | 기록 줄 구분선 | 줄 사이 구분선 없음 | 줄마다 아래 1pt primary 14% | `:241` overlay를 지운다(시안 목록은 1개뿐이라 여러 개일 때의 구분선은 확인 필요) |
| 26 | 아래 고정 버튼 **[기능]** | 패널 아래 "다음 여행 시작하기" 335×43, 흰색 + `#444444` 테두리, 캡슐형, 15pt 검정, 패널 아래에서 15pt | 없음 | 패널 ScrollView 밖 아래에 `Button("다음 여행 시작하기") { model.path = [.preparation] }`(C4 스타일). 진행 중 여정이 있으면 메인과 같은 확인 창을 띄울지 정해야 한다 |
| 27 | 진단 버튼 | 없음 | 왼쪽 아래 검은 44pt 사각형 3개(`test.records.*`) | `:268-283` `debugButton`의 `.background(Color.black)` → `Color.clear` + `.contentShape(Rectangle())`(테스트 전용, 화면만 정리) |
| D | [데이터] | 257회 · 214일 · 367 h 20 min, 선택 10/12, 2025 칩, 꽉 찬 잔디 | 12회 · 1일 · 5 h, 선택 10/17 | 수정 대상 아님 |

**차이 27개**

---

## R23-analytics (여행 분석)

관련 파일: `FM/RecordsAnalyticsView.swift`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 화면 형태 **[기능]** | R19와 같은 뜬 패널(12, 116, 378×738) + "×" + 탭 "잔디/분석"("분석" 선택) | push 화면, 시스템 뒤로 버튼, 탭 없음, 지도 없음 | R19 7번(탭 통합)으로 해결된다. 이 화면만 따로 둔다면 R19 1~3번과 같은 패널·닫기·탭 처리를 한다 |
| 2 | 안내 문구 | "예시 기록으로 보는 여행 분석입니다." 11pt `#BFC6C1` | 없음 | 예시 데이터일 때만 쓰는 문구다. 실제 기록에서는 넣지 않는다(예시 모드가 생기면 그때 추가) |
| 3 | 기간 버튼 모양 | "주간"/"월간" 11pt, 선택 칩 32×38 `#303B34` 반경 8, 선택 글자 흰색 / 비선택 `#CBD6CE`, 칩 안쪽 여백 약 6 | 13pt(선택은 Bold), 44 높이, 안쪽 여백 15, primary 12% | `:103-107`: `FontCatalog.text(11)`(Bold 빼기), `.padding(.horizontal, 6).frame(minHeight: 38)`, 선택 배경 `Color(hex:0x303B34)`, 비선택 글자 `Color(hex:0xCBD6CE)`. 누르는 영역 44는 `.contentShape(Rectangle()).padding(.vertical, 3)` |
| 4 | 기간 이동 배치 | 기간 버튼과 **같은 줄** 오른쪽에 "‹ 이번 달 ›" 11pt `#CBD6CE`, 갈매기 5×9 같은 색 | 기간 버튼 아래 별도 줄, 화면 폭 가득, "이번 달" 15pt 흰색, 갈매기 흰색 | `toolbar`(`:75-99`)를 `HStack { 주간; 월간; Spacer(); 이전; 이번 달; 다음 }` 한 줄로. `.font(FontCatalog.text(11)).foregroundStyle(Color(hex:0xCBD6CE))`, 갈매기 `.font(.system(size: 12))` |
| 5 | 간격 | 탭 아래 16 → 안내 → 30 → 기간 줄(y277~315) → 12 → "2026년 10월"(y327) → 26 → 숫자(y371) | `spacing: 24` 일정 | `:39` `spacing: 0` + 요소별 위 여백 |
| 6 | 요약 숫자 형식 | 평균 "1 h 30 min" | "25분" | `:201` `"\(averageMinutes)분"` → `ProfileTimeText.display(minutes: report.totals.averageMinutes)` |
| 7 | 요약 라벨 크기·간격 | 라벨 10pt `#BFC6C1`, 숫자(17 Bold)와 라벨 사이 9pt | 라벨 11pt, 간격 3 | `:212` `spacing: 9`, 라벨 `FontCatalog.text(10)` |
| 8 | 요약 열 위치 | x = 35 / 140 / 231(열 폭 105 / 91 / 나머지) | 적응형 그리드(약 35 / 148 / 262) | `:198`(큰 글씨가 아닐 때): `HStack(alignment: .top, spacing: 0) { stat.frame(width: 105, alignment: .leading); stat.frame(width: 91, alignment: .leading); stat }` |
| 9 | 요약 아래 구분선 | 숫자 아래 24pt 뒤 1pt 흰색 14% | `.padding(.bottom, 20)` | `:207` 20 → 24 |
| 10 | 태그 제목 문구 **[기능]** | "태그별 여행 시간"(선택한 기간 기준. 예시: 11회 × 평균 1h30 ≈ 합계 16h35m) | "태그별 여행 시간 · 전체 기간"(전체 기간 집계) | `:122` 문구에서 " · 전체 기간"을 빼고, 도넛·범례를 선택 기간 집계로 바꾼다(`RecordsAnalyticsAdapter`/report의 tags 계산 범위). 접근성 라벨 `:205`의 "전체 기간"도 같이 |
| 11 | 도넛 크기·두께 | 선 중심 지름 128(바깥 약 147), 두께 약 19, 위치 x=51(왼쪽 16 들여씀) | 지름 140 + 여백 9, 두께 17 | `:217-226`: `lineWidth: 19`, `.frame(width: 128, height: 128).padding(10)`, 왼쪽 `.padding(.leading, 6)` |
| 12 | 도넛 바탕 고리 | `#27332B` | 흰색 10% | `:217` `Color(hex:0x27332B)` |
| 13 | 조각 사이 틈 | 조각 사이 약 2pt 어두운 틈(`#0A0A0A`) | 틈 없음 | `:220` `trim(from: start + 0.004, to: min(1, start + tag.share) - 0.004)` 또는 조각마다 끝에 `Circle().trim(...)`으로 2pt 패널색 선을 겹친다 |
| 14 | 도넛 가운데 | "16h 35m" **20pt** Bold(짧은 형식) + "합계" 11pt | "2 h 30 min" 15pt Bold + "합계" 11pt | `:223` `.font(FontCatalog.text(20, bold: true))`, 형식 `"\(h)h \(m)m"`(1시간 미만 `"\(m) min"`, 0이면 "0 min" — R24 참고). `ProfileTimeText`에 `compact(minutes:)` 추가 |
| 15 | 범례 위치·폭 | 도넛 오른쪽 x=211~367(폭 156), 위쪽 y=494부터, 줄 높이 53 | 도넛 오른쪽 18pt, 세로 가운데, 간격 8 | `:124` `HStack(alignment: .top, spacing: 32)`, 범례 `.frame(width: 156)`, `.padding(.top, -22)`(도넛보다 22pt 위에서 시작) |
| 16 | 범례 표시 모양 | 세로 막대 6×20(반경 3) | 원 6×6 | `:130` `Capsule().fill(color).frame(width: 6, height: 20)`, `.padding(.top, 0)` |
| 17 | 범례 글자 | 이름 12pt `#E8EEE9`, 값 10pt `#BFC6C1`, 이름과 값 간격 8 | 이름 13pt primary, 값 11pt, 간격 3 | `:131-134`: 이름 `FontCatalog.text(12)`·`Color(hex:0xE8EEE9)`, 값 `FontCatalog.text(10)`, `VStack(spacing: 8)` |
| 18 | 범례 값 형식 | "10 h · 60%", "4 h 30 min · 27%"(시간 형식 + 비율, 횟수 없음) | "75분 · 3회 · 50%" | `:133` `"\(ProfileTimeText.display(minutes: tag.minutes)) · \(percent)%"`. 횟수는 접근성 라벨에만 남긴다 |
| 19 | 범례 구분선 | 줄마다 아래 1pt 흰색 9%(`#FFFFFF18`), 156 폭 | 없음 | `:129-140` 각 줄에 `.padding(.bottom, 14).overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.09)).frame(height: 1) }`, `VStack(spacing: 14)` |
| 20 | "태그로 활동 보기" 칩 **[기능]** | 없음 | 회색 문구 + 태그 칩(공부·독서) | `:145-160`. 시안대로라면 지운다. 태그별 활동 필터 기능이 사라지므로, 범례 줄을 눌러 태그를 고르게 옮기는 것을 권장(`browser?.selectTag`) |
| 21 | 비교 문구 | "지난달 같은 기간보다 25 min 적게 여행했어요." 11pt `#C3CDC6` | "이전 같은 기간보다 N분 더/덜 집중했어요"(이 캡처에서는 "비교할 이전 기록이 아직 없어요") | `:277-280`: `"\(kind == .month ? "지난달" : "지난주") 같은 기간보다 \(ProfileTimeText.display(minutes: abs(delta))) \(delta > 0 ? "많이" : "적게") 여행했어요."`, 같을 때 "지난달 같은 기간과 같아요.". 색 `Color(hex:0xC3CDC6)` |
| 22 | 날짜별 차트 제목 | "날짜별 여행 시간" 15pt Bold | "전체 활동"(태그를 고르면 "{태그} 활동") | `:163` 기본 문구를 "날짜별 여행 시간"으로 |
| 23 | 아래 고정 버튼 **[기능]** | "다음 여행 시작하기"(R19 26번과 같음), 패널 아래 고정 | 없음 | R19 26번과 같은 처리 |
| 24 | 그 아래 섹션 | 시안 패널은 차트 제목에서 끝나고 버튼으로 가린다(스크롤 영역으로 보임) | 마친 시간대·자주 탄 노선·여행 길이·최장 연속·최근 여행·메모 회고 | 시안에 없는 섹션이다. 유지할지 확인 필요(시안 다른 프레임에 있는지 확인). 유지한다면 고정 버튼 아래로 가리지 않게 ScrollView 아래 여백을 버튼 높이(43+15)만큼 둔다 |
| D | [데이터] | 11회 · 9일, 태그 4개(휴식·공부·독서·업무) | 6회 · 1일, 태그 2개 | 수정 대상 아님 |

**차이 24개**

---

## R24-analytics-empty (분석 · 첫 기록 전)

R23과 같은 구조라 R23 1·3·4·5·7·8·9·11·12·23번이 그대로 해당한다(따로 세지 않음). 아래는 빈 상태에서만 생기는 차이다.

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 패널 높이 | 내용에 맞춘 패널: 위 y=200, 높이 654(아래 여백 20 고정) | 화면 위에서부터 이어지는 스크롤 | 패널을 아래 기준으로 두고 높이를 내용에 맞춘다(`.frame(maxHeight: .infinity, alignment: .bottom)` + 내용 크기). 탭 통합(R19 7번)이 되면 기록 탭과 높이가 달라지므로 애니메이션 여부를 정한다 |
| 2 | 평균 값 | "0 min" | "0분" | R23 6번 |
| 3 | 빈 상태 문구 위치·문구 | 도넛 **아래**(y=748) "첫 여행을 마치면 태그별 시간과 활동이 여기에 모여요." 13pt `#BFC6C1` | 요약 바로 아래, 태그 제목 **위** "첫 여행을 마치면 집중 기록을 분석해드려요" 15pt | `:118-121`: 문구를 바꾸고 `FontCatalog.text(13)`으로, 도넛 다음으로 옮긴다. 기록은 있는데 그 기간이 비었을 때 쓰는 "이 기간에는 마친 여행이 없어요"는 시안에 없으니 그대로 둔다 |
| 4 | 빈 도넛 **[기능]** | 태그가 없어도 바탕 고리(`#27332B`, 두께 19) + 가운데 "0 min" 20pt Bold + "합계" | 태그가 없으면 도넛·범례 전체를 숨김(`:123` `if !report.tags.isEmpty`) | `:123` 조건을 빼고 도넛은 항상 그린다. 범례만 태그가 있을 때 |
| 5 | 태그 제목 | "태그별 여행 시간" | "태그별 여행 시간 · 전체 기간" | R23 10번 |
| 6 | 비교 문구 **[기능]** | 없음 | "비교할 이전 기록이 아직 없어요" | `:161`을 `report.totals.count > 0`일 때만 보인다(또는 기록이 하나도 없으면 숨김) |
| 7 | 날짜별 차트 **[기능]** | 없음 | "전체 활동" + 빈 막대 01~09 | `:162-170`을 기록이 없을 때(`!value.hasAnyEligibleRecords`) 숨긴다 |
| 8 | 나머지 섹션 **[기능]** | 없음 | "마친 시간대 · 표시 시간대 기준", "기록이 더 필요해요", "새벽 0–5시 0분 · 0회" … | `:171-193`도 기록이 없을 때 숨긴다 |
| 9 | 아래 버튼 | "다음 여행 시작하기"(패널 아래에서 15pt) | 없음 | R19 26번(이 화면에서 첫 여행으로 가는 유일한 길이라 우선순위가 높다) |
| 10 | 안내 문구 | "예시 기록으로 보는 여행 분석입니다."(빈 상태인데 "예시 기록" — 시안의 모순) | 없음 | 넣지 않는 것을 권장. 디자이너에게 확인 |

**차이 10개**

---

## R20-settings (설정)

관련 파일: `FM/DestinationScreen.swift:34-58`(지금은 `.settings`가 자리표시 화면으로 떨어진다), `FM/MainHomeView.swift:65`, `FM/ProfileView.swift:74-75`

| # | 구분 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 화면 자체 **[기능]** | 설정 시트에 내용이 있다 | 빈 자리표시 화면(제목 "설정" + 가운데 탐색 제목 "설정"뿐) | 새 `SettingsView.swift`를 만들고 `DestinationScreen.swift`에 `else if destination == .settings { SettingsView(model:) }`를 추가한다 |
| 2 | 표시 방식 **[기능]** | 지도 위 아래쪽 시트(x=12, y=546, 378×303, 아래 여백 25), 위쪽은 지도가 보이고 전체 `#00000055`로 어둡게 | push 화면, 검은 배경, 뒤로 버튼 | `.sheet(isPresented:)` + `.presentationDetents([.height(303)])` + `.presentationBackground(.clear)`로 패널을 직접 그린다. 또는 R19와 같은 오버레이 패널. 메인/마이페이지 양쪽 진입점에서 `model.open(.settings)` 대신 시트 상태를 켠다 |
| 3 | 패널 모양 | `#0A0A0A`, 반경 약 24, 흰색 20% 테두리(C2), 안쪽 여백 23 | — | `fmSheetPanel()` |
| 4 | 제목·닫기 | "설정" 22pt Bold 흰색(x=35, y=579, 패널 위에서 33), 오른쪽 "×" 23pt(x=339) | 큰 제목 `.largeTitle.bold()`(시스템 34pt) + 탐색 막대 제목 | `HStack { Text("설정").font(FontCatalog.text(22, bold: true)); Spacer(); 닫기 버튼(xmark 20pt, 44×44) }`, `.padding(.top, 33)`. `DestinationScreen.swift:49` 탐색 제목은 쓰지 않는다 |
| 5 | 앱 소개 | "Focus Mate"(y=633) / "가상 지도와 30초 압축 시간의 프로토타입입니다."(y=660) 둘 다 15pt `#AAAAAA`, 줄 간격 27 | 없음 | `VStack(alignment: .leading, spacing: 12) { Text("Focus Mate"); Text(소개) }.font(FontCatalog.text(15)).foregroundStyle(Color(hex:0xAAAAAA))`. **문구 확인 필요**: 웹 프로토타입 문구라서 실제 앱(실지도, 실제 분 단위 시간)과 맞지 않는다. 앱에 맞는 문구를 정해 달라고 요청할 것 |
| 6 | 동작 줄이기 **[기능]** | 체크 상자(13×13, 파랑 `#0075FF`, 흰 체크) + " 동작 줄이기" 15pt `#CCCCCC`, y=709, 체크된 상태 | 없음. 앱은 시스템 `accessibilityReduceMotion`만 따른다(`RootView.swift:21`) | 앱 안 설정값 `reduceMotionOverride`(AppSnapshot/UserDefaults)를 추가하고, 지금 `@Environment(\.accessibilityReduceMotion)`을 읽는 곳(RootView → JourneyTimerView `reduceMotion`, BoardingTagController 등)에서 `system || override`로 쓴다. UI는 `Toggle(isOn:)` + `.toggleStyle(CheckboxStyle())`(직접 그린 13pt 사각형, 반경 2, `#0075FF`, 흰 `checkmark` 9pt Bold), 누르는 영역 44pt |
| 7 | 안내 | "이 데모는 iOS 권한이나 실제 운행 정보에 접근하지 않습니다." 10pt `#B5B5BA`, **가운데 정렬**, y=752 | 없음 | `Text(...).font(FontCatalog.text(10)).foregroundStyle(Color(hex:0xB5B5BA)).frame(maxWidth: .infinity)`. **문구 확인 필요**(앱은 공공 정류장 데이터를 쓰고 Live Activity 권한을 쓴다. "데모" 표현도 맞지 않음) |
| 8 | 링크 "서울 버스 유형 보기" **[기능]** | 11pt `#DDDDDD` 밑줄, y=780 | 없음 | `Link("서울 버스 유형 보기", destination: URL(서울시 버스 안내 페이지))`, `.font(FontCatalog.text(11)).underline().foregroundStyle(Color(hex:0xDDDDDD))`. 연결할 주소를 정해야 한다 |
| 9 | 서체 출처 **[기능]** | "서체: " 11pt `#AAAAAA` + "서울알림체 · 서울특별시" 11pt `#DDDDDD` 밑줄 링크, y=798 | 없음(마이페이지의 데이터 출처 화면 `DataSourceView`에 출처 문구가 따로 있음) | `HStack(spacing: 0) { Text("서체: "); Link("서울알림체 · 서울특별시", destination: 서울시 서체 페이지).underline() }`. 패널 아래 여백 약 40 |
| 10 | 마이페이지 진입 | 시안 메인에는 설정 버튼이 없다(R31 1번) | 메인 톱니 + 마이페이지 "설정" 줄 | R31 1번을 적용하면 마이페이지 줄(`ProfileView.swift:74`)만 남는다. 그 줄도 시트를 열도록 한다 |

**차이 10개**

---

## 요약

| 화면 | 차이 개수 | [기능] 항목 |
|---|---|---|
| R31-resume-prev | 21 | 3 (상단 도구 축소, 진행 중 제목 문구, 현재 정류장 블록 제거) |
| R32-new-confirm | 11 | 1 (시스템 alert → 직접 그린 확인 창) |
| R33-resumed | 17 | 2 (노선 버튼, 지나온/남은 구간 색 나누기) |
| R19-records | 27 | 10 |
| R23-analytics | 24 | 4 |
| R24-analytics-empty | 10 | 4 |
| R20-settings | 10 | 5 |
| 합계 | 120 | 29 |

공통 차이 C1~C5는 개수에서 뺐다.
