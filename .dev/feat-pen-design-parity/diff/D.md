# D 담당: 하차·요약·하차 후 홈 화면의 시안 대비 차이

대상: R28-alight-tag · R29-alight-done · R34-alight-resume · R17-summary · R30-summary-memo · R25-memo(앱에 없음) · R18-home-after(대응 화면 없음)

읽는 법
- 좌표·크기는 pt(402x874 기준)다. 시안은 `spec/*.txt` 값이고, 앱 캡처는 1206x2622 이미지에서 잰 값을 pt로 바꾼 것이다(오차 ±2pt).
- 소스 줄번호는 `next-step-w19/ios/FocusMate/` 기준이다.
- **[기능]** = 동작·상태·데이터 흐름까지 바꿔야 하는 항목. 표시가 없으면 화면 표현만 바꾸면 된다.
- **[데이터]** = 예시 데이터 값만 다른 것. 고칠 대상이 아니다.
- 상태 표시줄(시안은 9:41만, 앱은 와이파이·배터리)과 배경 3D 일러스트/MapKit 차이는 공통 차이(INDEX.md)라 따로 세지 않았다. 단, 지도 위에 무엇을 그리는지는 셌다.
- 시안의 "예시 …" 문구(예: "예시 현재 위치", "예시 여행 기록")는 시안이 예시 자리를 표시하려고 붙인 말로 본다. 해당 항목에 따로 적었다.

---

## R28-alight-tag (하차 태그, 대기 상태)

대상 소스: `CardTagScreen.swift`(승차·하차 공용), `AlightingTagView.swift`, `BoardingRules.swift`(BoardingGeometry), `PassFace.swift`

현재 앱은 단말기·카드·위 화살표만 그리고, 제목·정류장·안내 문구는 1pt 투명 글자로 낭독용만 둔다(`CardTagScreen.swift:48`). 시안은 화면에 문구를 모두 보여준다.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 화면 배경색 | `#101411` | `#101112` (`CardTagScreen.swift:64`) | `Color(red: 0x10/255, green: 0x14/255, blue: 0x11/255)`로 바꾼다. 승차 화면(R27)도 같은 색이면 공용으로 둔다 |
| 2 | 상단 줄 왼쪽 "여행의 마지막 정류장" | (24,74), 11pt Regular, `#9AA59C` | 없음 | `CardTagScreen.body` VStack 맨 위(48행 투명 제목 대신)에 `HStack { Text(kind.stageLeft); Spacer(); Text(kind.stageRight) }`를 넣는다. 왼쪽 11pt, 오른쪽 12pt, 둘 다 `#9AA59C`, 좌우 패딩 24/25, 상단은 safe area 아래 +12pt(y=74). `CardTagKind`에 `stageLeft`("여행의 마지막 정류장", 승차는 R27 시안 값)와 `stageRight`("하차 태그") 추가 |
| 3 | 상단 줄 오른쪽 "하차 태그" | (330,73) 우측 정렬, 12pt, `#9AA59C` | 없음 | 2번과 같은 HStack에 넣는다 |
| 4 | 큰 제목 "도착했어요." / "하차 태그를 해주세요." | 가운데 정렬, 27pt Bold, `#FFFFFF`, 줄 y=122·159(줄 간격 37pt, lh≈1.37) | 없음(낭독용 1pt 투명 글자만) | 2번 HStack 아래 48pt 띄우고 `Text("도착했어요.\n하차 태그를 해주세요.")`를 `FontCatalog.text(27, bold: true)`, `.multilineTextAlignment(.center)`, `.lineSpacing(10)`로 넣는다. `.accessibilityAddTraits(.isHeader)`와 식별자 `alighting.title`은 이 글자로 옮긴다. 투명 글자(48~49행)는 지운다. 문구는 `CardTagKind.headline`으로 둔다 |
| 5 | 부제 "서울숲 입구에 도착" | 가운데, (149,212), 13pt Regular, `#AAB5AC` | 없음 | 제목 아래 26pt에 `Text("\(도착 정류장 이름)에 도착")`, `FontCatalog.text(13)`, `#AAB5AC`. 정류장 이름은 `model.activeJourney?.destinationName`을 `AlightingTagView`에서 넘긴다(`CardTagScreen`에 `subtitle: String?` 인자 추가) |
| 6 | 단말기 위치·크기 | (83,246) 237x286. 화면 위에서 246pt | (65,136) 274x337. 위에서 136pt | `CardTagScreen.swift:125` `.frame(width: 274)` → `237`. 위 문구들이 생기면 세로 위치는 자연히 내려온다. 위쪽 `Spacer(minLength: 24)`(50행)는 부제와 단말기 사이 21pt로 고정(`.padding(.top, 21)`) |
| 7 | 단말기 테두리 | `#525454` 1pt | 흰색 20%(`:127`) | `.stroke(Color(hex 0x525454), lineWidth: 1)` |
| 8 | 단말기 모서리 | ≈28pt(이미지) | 28 | 같음 |
| 9 | 상단 표시줄(캡슐) | 156x4, 단말기 안 좌우 40pt, 위 13pt, `#737C76` | 좌우 24pt 패딩, 회색 60%(`:110~111`) | `.padding(.horizontal, 40)`, 대기 색 `#737C76`. 단말기 `.padding(.vertical, 15)`(124행) → 위 13pt |
| 10 | LCD 크기 | 201x125, 단말기 안 좌우 18pt, 캡슐 아래 18pt | 높이 112 (`:159`) | `.frame(height: 125)` |
| 11 | LCD 테두리 | `#5D625F` 1pt | 흰색 35%(`:161`) | `#5D625F`(대기), 인식 뒤 `#848F87`(R29 참조) |
| 12 | LCD 왼쪽 위 글자 | "FOCUS MATE" 대문자, 8pt Regular, `#C0C7C2` | "Focus Mate" 9pt(`:138`) | `Text("FOCUS MATE").font(FontCatalog.text(8))`, 색 `#C0C7C2` |
| 13 | LCD 오른쪽 위 | 버스 번호 "2014", 11pt Bold, `#F1F3F1` | 현재 시각 "11:08" 10pt Semibold(`:107~108, 140`) | 시각 대신 노선 번호를 보인다. `CardTagScreen`에 `busNumber: String` 인자를 추가하고 `AlightingTagView`에서 `model.activeJourney?.busNumber`, `BoardingTagView`에서 확정 준비의 버스 번호를 넘긴다. `TimelineView(.everyMinute)`(107행)는 없앤다. 낭독 라벨(129행)의 `time`도 버스 번호로 바꾼다. **[기능]**: 단말기 낭독 문구가 바뀌므로 UI 테스트에서 시각을 확인하는 곳이 있으면 함께 고친다 |
| 14 | LCD 구분선 | LCD 위에서 28pt, 좌우 11pt 안쪽, 흰색 14%(`#FFFFFF24`) 1pt | 시스템 `Divider()`(`:142`) | `Rectangle().fill(.white.opacity(0.14)).frame(height: 1)`, LCD `.padding(.horizontal, 11)` |
| 15 | LCD 상태 글자 "하차 준비" | 18pt **Bold(700)**, 구분선 아래 18pt | 18pt Semibold, 가운데(`:150`) | `FontCatalog.text(18, bold: true)`. 세로 정렬은 위쪽(구분선 +18pt)으로: `.frame(maxHeight: .infinity, alignment: .top).padding(.top, 18)` |
| 16 | LCD 안내 "아래 태그 영역에 카드를 대주세요" | 9pt Regular, `#B5B5BA`, LCD 아래쪽(y=379, LCD 바닥에서 18pt) | 없음 | 15번 아래 `Spacer()` 뒤에 `Text(kind.lcdHint)`(9pt, `#B5B5BA`). 승차는 R27 시안 문구를 쓴다 |
| 17 | 태그 영역 크기 | 149x76, 단말기 좌우 44pt 안쪽, LCD 아래 25pt | 238x160(`BoardingRules.swift:6`), LCD 아래 16pt | `tagAreaSize = CGSize(width: 149, height: 76)`, `VStack(spacing:)`은 25. **[기능]**: 접촉 판정은 겹친 면적 ÷ 태그 영역 면적 ≥ 0.30이다(`BoardingRules.swift:8, 24~30`). 영역이 1/3 크기로 줄면 같은 끌기 거리에서 접촉이 더 빨리 일어나고 `activationOffset`도 달라진다. 판정 단위 테스트 기대값을 다시 계산해야 한다 |
| 18 | 태그 영역 모양 | 채움 `#141617`, 테두리 `#707874`, 모서리 ≈18 | 채움 `#202324`, 테두리 흰색 32%, 모서리 20(`:113~114`) | 채움·테두리 색을 바꾸고 `cornerRadius: 18` |
| 19 | 태그 영역 아이콘 | 왼쪽 점(4x4) + 호 3개(17x32), 선 `#E1E6E2`. 영역 위에서 13pt, 크기 약 24x32 | `wave.3.right` 40pt, 흰색 70%(`:115`) | `Image(systemName: "wave.3.right").font(.system(size: 26, weight: .light))` 앞에 4pt 원을 둔다(또는 커스텀 Shape). 색 `#E1E6E2` |
| 20 | 태그 영역 글자 "카드를 여기에" | 10pt Regular, `#B7C1BA`, 아이콘 아래 9pt | 없음 | 아이콘 아래 `Text("카드를 여기에")` 추가. 인식 뒤에는 "태그 완료"(10pt, `#DCE5DF`)로 바꾼다 |
| 21 | 단말기 아래쪽 "FOCUS MATE" 각인 | 태그 영역 아래 5pt, 8pt Regular, `#A8B0AC` | 없음 | 태그 영역 바로 아래 `Text("FOCUS MATE")`, 단말기 아래쪽 여백 12pt |
| 22 | 단말기와 카드 사이 위 화살표 | 없음 | `chevron.up.2` title2 흰색 85%(`:54~56`) | 지운다. 단말기 바닥(532)과 카드 위(593) 사이 61pt는 `Spacer(minLength: 61)`로 둔다 |
| 23 | 카드 점선 테두리(깜빡임) | 없음. 카드 테두리는 `#51565A` 1pt 실선 | 흰색 점선 1.5pt, 6/5 간격, 0.18~0.55 깜빡임, 8pt 바깥 여백(`:174~177`) | 점선 overlay와 `blink` 애니메이션을 지운다. `.padding(8)`도 지워 카드 기준 위치(`cardRest`의 `insetBy(8)` 195~196행)도 같이 0으로 고친다. 카드 테두리는 PassFace 쪽 `#51565A`(아래 25번) |
| 24 | 카드 크기·비율 | (66,593) 270x158, 비율 1.71, 모서리 14 | 폭 268, 높이 168(비율 1.59, `PassFace.aspectRatio = 352/221.19`), 모서리 16·s≈12 | 태그 화면만 `PassFace(...).frame(width: 270, height: 158)`로 쓰려면 PassFace에 `aspectRatio` 덮어쓰기 인자를 추가한다(다른 화면 카드 비율은 담당 화면 확인 필요). `BoardingGeometry.cardWidth` 268 → 270. 모서리 14 |
| 25 | 카드 테두리 | `#51565A` 1pt | 흰색 8%(`PassFace.swift:56`) | `Color(hex 0x51565A)` 1pt. 공용 PassFace라 다른 화면 시안과 함께 확인 |
| 26 | 카드 안 서울 점지도 | 없음 | `PassDots` 점지도(`PassFace.swift:27~32`) | 시안 하차 태그 카드에는 점지도가 없다. 태그 화면에서 `PassFace(style:, dotsOpacity: 0)`로 넘긴다(인자는 이미 있음) |
| 27 | 카드 번호 "FM · 0842 3017" | 왼쪽 아래 (21,134), 7pt Regular, `#F1F2F3` | 없음 | `PassFace.artwork`에 `Text(PassIdentity.numberText)`(`PassIdentity.swift:13`에 이미 있음)를 `FontCatalog.text(7*s')`, offset (21,134 비율)로 추가. 270 폭 기준 s'=270/270 |
| 28 | 카드 글자 크기 | "Focus Mate" 10pt Bold (21,18) / "집중동행카드" 18pt Bold (65,64) / "나를 위한 시간, 한 장으로." 9pt (65,98) / 칩 30x22 (22,69) / 오른쪽 위 NFC 12x19 (236,16) | 폭 268 기준 s=0.761: 8.4pt (15,13) / 15.2pt (64,68) / 6.8pt (64,104) / 31x23 (20,73) / 13.7x16.7 (243,11) | PassFace 기준값을 시안 270x158에 맞춘다: Focus Mate 10·s, 제목 18·s, 부제 9·s(현재 9·s지만 기준폭 352라 작아짐 → 기준폭을 270으로 바꾸고 좌표를 위 값으로). 공용 컴포넌트라 R11·R27 시안과 같은 값인지 확인 후 적용 |
| 29 | 아래 안내 "카드를 위의 단말기로 올려주세요" | 가운데, y=772, 12pt Regular, `#BDC8BF`, 항상 보임 | 없음. 터치했을 때만 "카드를 위로 밀어 단말기에 대주세요" subheadline(15pt) 흰색(`:205`) | `notices`(202~216행)를 바꾼다: 기본 문구 "카드를 위의 단말기로 올려주세요"를 항상 12pt `#BDC8BF`로 보이고, 저장 실패만 오렌지로 덧붙인다. **[기능]**: `showsTapHint` 문구를 쓰는 테스트(`alighting.tapHint`)가 기대 문구·노출 조건을 바꿔야 한다 |
| 30 | "눌러서 태그하기" 밑줄 링크 | y=813, 11pt Regular, `#94A098`, 밑줄(75x1, 글자 아래 3pt), 홈 표시줄 위 35pt | 없음(카드 터치·낭독 동작으로만 가능) | **[기능]** `Button { controller.activate(reduceMotion:) } label: { Text("눌러서 태그하기").underline() }`를 맨 아래에 추가, 11pt `#94A098`, 최소 44pt 높이. 지금 카드 짧게 누르기는 튐+힌트만 보인다(`tapBounceCount`). 이 링크는 보조 기술 없이도 끌기 대신 바로 태그되게 하는 대체 경로다 |
| 31 | 뒤로가기 | 없음 | 없음(하차는 잠금) | 같음 |
| — | [데이터] LCD 오른쪽 값 | 2014 | 11:08 | 13번에서 다룸(표시 대상 자체가 다름) |
| — | [데이터] 부제 정류장 이름 | 서울숲 입구 | (없음) | — |

R28 차이 31개.

---

## R29-alight-done (하차 태그 인식·보류 상태)

R28의 1~12, 14, 21~31번 차이가 모두 같이 있다(같은 화면의 다음 상태). 아래는 인식 상태에서 추가로 다른 점이다.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 상단 문구·제목·부제 유지 | "여행의 마지막 정류장"/"하차 태그", "도착했어요. 하차 태그를 해주세요.", "서울숲 입구에 도착"이 그대로 있음 | 모두 없음 | R28 2~5번을 넣으면 해결. 인식 상태에서도 바꾸지 않는다 |
| 2 | 캡슐 인식 색 | `#B2C9B9` | `Color(0.7,0.85,0.75)` = `#B3D9BF`(`CardTagScreen.swift:110`) | `#B2C9B9`로 바꾼다 |
| 3 | LCD 테두리 인식 색 | `#848F87` | 흰색 35% 그대로 | `controller.isRecognized ? #848F87 : #5D625F` |
| 4 | LCD 내용 배치 | 왼쪽에 카드 축소 썸네일(100x64, 모서리 12, LCD 안 (10,45)), 오른쪽에 "하차 완료" 14pt Bold 흰색 (LCD 안 118,66), 그 아래 "집중동행카드" 9pt Bold `#CBD3CE` (131,92), 오른쪽 위 체크(11x8, 선 `#EEF2EF`, (175,46)) | 가운데 "집중동행카드" 18pt Semibold + 아래 초록 체크 title3(`:144~148`) | `lcd(time:)`의 `if controller.isRecognized` 분기를 `HStack(spacing: 17) { PassFace(style:, dotsOpacity: 0).frame(width: 100, height: 64); VStack(alignment: .leading, spacing: 12) { Text(kind.doneLCDText) 14pt Bold; Text(PassIdentity.displayName) 9pt Bold #CBD3CE } }`로, 체크는 `.overlay(alignment: .topTrailing) { Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(#EEF2EF) }` |
| 5 | LCD 인식 문구 | "하차 완료" | "집중동행카드"(PassIdentity.displayName) | `CardTagKind.doneLCDText`(하차 "하차 완료", 승차는 R12 시안 값)를 추가. 낭독 값(155행)도 "하차 완료"로 |
| 6 | 카드가 단말기 안에 들어감(축소) | 카드가 211x123(0.78배)로 줄어 단말기 안 (96,407)에 놓이고 태그 영역을 덮음. 단말기 바닥(532) 안에 있음 | 카드가 원래 크기(268폭)로 태그 영역 위쪽에 맞춰 올라가 단말기 바닥을 넘어 571pt까지 내려옴 | **[기능]** 보류(`held`) 상태에서 카드에 `.scaleEffect(0.78)`을 주고, 오프셋을 "카드 중심 = 태그 영역 중심(+3pt 아래)"이 되게 컨트롤러가 계산한다. `BoardingTagController`의 접촉 뒤 스냅 오프셋 계산과 `BoardingGeometry.clampedOffset`(카드 위쪽=태그 영역 위쪽에서 멈춤)을 바꿔야 한다. 동작 줄이기에서는 애니메이션 없이 최종 위치만 |
| 7 | 카드 인식 배지 | 카드 오른쪽 아래 27pt 원 `#D7EFDC`, 안에 체크(10x7, 선 `#183822`), 카드 안 (176,89) | 없음 | 카드 `overlay(alignment: .bottomTrailing)`에 `Circle().fill(#D7EFDC).frame(27).overlay(Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(#183822)).padding(7)`을 `controller.isRecognized`일 때만 |
| 8 | 태그 영역 인식 상태 | 채움 `#242829`, 테두리 `#A6B6AC`, 글자 "태그 완료" 10pt `#DCE5DF`(카드에 덮여 거의 안 보임) | 변화 없음 | R28 18·20번과 같이 `isRecognized`에 따라 색·문구를 바꾼다 |
| 9 | 아래 안내 문구 | "하차 완료 · 이번 여행을 기록했어요" 12pt `#BDC8BF`, 가운데 y=772 | 없음 | R28 29번 문구를 `isRecognized`면 이 문구로 바꾼다 |
| 10 | "눌러서 태그하기" 링크 | 인식 뒤에도 그대로 보임(11pt `#94A098` 밑줄) | 없음 | R28 30번. 인식 뒤에는 `.disabled(true)`로 두되 색은 유지(시안과 같게) |
| — | [데이터] LCD 시각 11:09 | 2014 | — | R28 13번 |

R29 차이: 고유 10개 + R28 공통 26개.

---

## R34-alight-resume (메인, 도착 여정 대기 카드)

대상 소스: `MainHomeView.swift`, `MainActiveJourneyView.swift`(ActiveJourneyCardView), `ActiveJourneyCardContent.swift`, `JourneyLifecycleText.swift`, `AppModel+Alighting.swift`

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 상단 도구 버튼 수·모양 | 2개(기록·마이페이지), 43x43 원, (289,61)/(343,61), 채움 `#0A0A0A` 75%, 테두리 `#444444` 1pt, 아이콘 흰색 선(문서 12x15, 사람 14x16) | 4개(기록 book.closed·마이 person.crop.circle·설정 gearshape·카드 creditcard) 44x44, 채움 panel 85%, 테두리 없음, 19pt(`MainHomeView.swift:57~86`) | R01 담당과 공통. 이 화면 기준: 설정·카드 꾸미기 버튼을 메인에서 빼고(마이페이지 안으로 이동) **[기능]**, 버튼은 `frame(43)`, `.background(Color(hex 0x0A0A0A).opacity(0.75), in: Circle()).overlay(Circle().stroke(#444444))`, 아이콘 `doc.text` / `person` 17pt light, 간격 11pt, 오른쪽 여백 16pt |
| 2 | "Focus Mate" 워드마크 | 없음 | 왼쪽 위 12pt Bold 자간 1.4(`:59~61`) | 지운다(R01 공통) |
| 3 | 인사 문구 위치·색 | (24,135) 15pt Regular `#E1E5E8` | (20,~142) 15pt `#BFC6C1`(secondaryText) | `.foregroundStyle(Color(hex 0xE1E5E8))`, 좌우 패딩 20 → 24(`:44`) |
| 4 | 제목 둘째 줄 문구 | "오늘은 조금 느긋하게." | "나만의 속도로 출발해요."(`:104`) | 제목 문구를 `"\(name)에서,\n오늘은 조금 느긋하게."`로 바꾼다(R01과 문구 정책 맞출 것). [데이터] 첫 줄 정류장 "서울숲" vs 앱 "성수역" |
| 5 | 제목 뒤 검은 띠 | 줄마다 `#000000` 53%(`#00000088`) 사각 띠(1줄 14,163 155x50 / 2줄 14,202 270x48), 글자 왼쪽 10pt 바깥으로 | 없음(상단 그라데이션만) | 제목을 줄 단위 `Text`로 나눠 각 줄에 `.padding(.horizontal, 10).padding(.vertical, 7).background(Color.black.opacity(0.53))`. 그라데이션(`:26~31`)은 시안의 전체 33% 어둡게(`#00000055`)로 바꾼다: `Color.black.opacity(0.33).ignoresSafeArea()` |
| 6 | 제목 글자 | 28pt Bold 흰색, 줄 y=168·207(줄 간격 39) | 28pt Bold `#F4F6F2`, 줄 간격 기본 | 색 `.white`, 5번 띠 높이로 간격이 맞춰진다 |
| 7 | "현재 정류장" 블록 | 없음 | 카드 위에 "현재 정류장 / 성수역 / 성수동 방면"(`:139~150`) | 도착 여정 카드가 있을 때 이 블록을 지운다. 낭독 식별자 `screen.main`·`main.currentStation`는 화면에 보이지 않는 요소로 옮겨 테스트 유지 |
| 8 | 지도 위 정류장 핀 | 없음 | 가운데 "성수역" 회색 핀(`showsStationAnnotation: model.activeJourneyCard != nil`, `:24`) | `showsStationAnnotation: false`. 지도 표현(MapKit vs 3D 일러스트)은 공통 차이 |
| 9 | 카드 패널 위치·크기 | (18,551) 366x246, 아래 여백: 카드 바닥 797 → 아래 버튼 802 | (20,618) 361x206, 바닥 824 | 패널 좌우 여백 20 → 18. 높이는 내용으로 정해진다(아래 항목 반영 시 ≈246) |
| 10 | 카드 패널 모서리·색 | `#0A0A0A`, 모서리 ≈20 | `#0A0A0A`, 모서리 24(`FMDesign.swift:42`) | `fmPanel`에 `cornerRadius` 인자 추가해 20 |
| 11 | 카드 제목 문구 | "마지막 태그가 남았어요." | "도착한 여정이 있어요"(`JourneyLifecycleText.swift:6`) | `arrivedTitle = "마지막 태그가 남았어요."` |
| 12 | 할 일 글자색 | 17pt Bold `#AAAAAA` | 17pt Bold `#F4F6F2`(`MainActiveJourneyView.swift:14`) | `.foregroundStyle(Color(hex 0xAAAAAA))`. [데이터] "책 한 챕터 읽기" vs "논문" |
| 13 | 버스 줄 오른쪽 상태 "하차 태그 대기" | 버스 줄과 같은 높이 오른쪽, 14pt Bold 흰색, 오른쪽 여백 22 | 없음 | 버스 줄을 `HStack { Text(busText); Spacer(); Text("하차 태그 대기") 14pt Bold }`로. 도착(kind == .arrived)일 때만. 문구는 `JourneyLifecycleText.awaitingAlightTag` |
| 14 | 버스 줄 글자 | "지선 2014" 13pt Regular `#C1CBC3` | 13pt `#BFC6C1` | 색만 `#C1CBC3`(거의 같음) |
| 15 | 경로 줄 글자 | "독서 · 서울숲 입구까지" 12pt `#A6B1A8` | 13pt `#BFC6C1`(`:17`) | `FontCatalog.text(12)`, `#A6B1A8` |
| 16 | 카드 내부 간격 | 위 26 → 제목, 제목→할 일 47, 할 일→버스 38, 버스→경로 24, 경로→버튼 40, 버튼 아래 20 (모두 줄 위끝 기준) | 모든 줄 간격 4, 버튼 앞 12(`:11~12`) | 정보 VStack을 `spacing` 대신 개별 `.padding(.top)`으로: 제목 아래 26, 할 일 아래 21, 버스 아래 11, 버튼 앞 28. 패널 위 패딩 26, 좌우 20, 아래 20 |
| 17 | 주 버튼 문구 | "이전 여정 이어가기 →" | "하차하기"(`JourneyLifecycleText.swift:14`) | 도착 카드도 "이전 여정 이어가기 →"(낭독 "이전 여정 이어가기")를 보인다. 누르면 지금처럼 하차 흐름(`open.alighting`, `beginAlighting`)으로 간다. **[기능]**: W09 결정("도착 여정의 유일한 동작은 하차")과 문구가 다르므로 테스트(`open.alighting` 라벨 확인)와 함께 바꾼다 |
| 18 | 주 버튼 모양 | 325x51, 채움 `#FFFFFF`, 테두리 `#444444` 1pt, 글자 15pt **Regular** 검정, 모서리 25.5(캡슐) | 최소 52 높이, `#F4F6F2`, 테두리 없음, 17pt Bold, 모서리 24(`FMDesign.swift:11~22`) | R01·R17 등 다른 시안 주 버튼도 같은 모양(흰색·#444 테두리·15pt Regular·캡슐)이라 `FMPrimaryButtonStyle`을 바꾼다: 폰트 `FontCatalog.text(15)`, 배경 `.white`, `Capsule()` + `.strokeBorder(#444444)`, `minHeight: 51` |
| 19 | 화살표 | 글자 뒤 4pt 띄어 "→" 같은 15pt 글자 | 문구 끝 "→" 17pt Bold | 18번 반영 시 맞춰진다 |
| 20 | "새 여정 시작" 보조 버튼 | 카드 아래 5pt, (18,802) 366x44, 채움 `#0A0A0A` 85% + 흰색 21% 겹침(≈`#3E3E3E` 회색), 모서리 22, 글자 13pt Regular 흰색 | 없음 — 도착 여정이 있으면 여행 준비 메뉴를 뺀다(`AppModel+Alighting.swift:67~69`, AC-21) | **[기능]** 도착 여정이 있어도 "새 여정 시작"을 보이고, 누르면 R32와 같은 확인 창(`newJourneyConfirmation`) 뒤 도착 여정을 버리고 준비로 간다. `mainMenuDestinations` 필터 제거, 확인 문구는 도착 여정용(완료 기록 없음)인지 결정 필요. 버튼 스타일은 `FMSecondaryButtonStyle`을 13pt, `minHeight: 44`, 배경 `Color.white.opacity(0.21)` over `#0A0A0A`로 |
| — | [데이터] 인사말 | "오늘도 수고했어요." | "좋은 아침이에요." | 실행 시각 차이(코드 문구는 동일) |
| — | [데이터] 할 일·정류장 | 책 한 챕터 읽기 / 서울숲 | 논문 / 성수역 | — |

R34 차이 20개.

---

## R17-summary (여행 요약, 메모 없음)

대상 소스: `AlightingSummaryView.swift`, `SceneMapBackdrop.swift`, `FMDesign.swift`

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 지도 위 경로 표시 | 지나온 경로(흰색 27% `#FFFFFF44` 선, 꺾인 모양) + 정류장 점 4x4(지난 곳 `#777777`, 앞쪽 `#FFFFFF`, 테두리 `#0A0A0A`) + 초록 버스 아이콘(44x57) | 도착 정류장 핀 "서울숲 입구"만(`AlightingSummaryView.swift:30`) | **[기능]** `SceneMapBackdrop(model:, stationID: 도착 정류장, routeID: 기록의 노선 ID, showsStationAnnotation: false)`로 노선을 그린다. `routeID` 인자는 이미 있으나(`SceneMapBackdrop.swift:10, 20~28`) `AlightingSummary`에 노선 ID·출발/도착 정류장 ID가 없으니 추가해야 한다. 선 색은 `.white.opacity(0.27)` 2pt, 정류장 점 `Annotation` 4pt, 버스 위치는 도착 정류장에 버스 심볼(초록 `#168445` 계열) |
| 2 | 지도 어둡게 | 전체(0~817) 검정 33% | 위쪽만 검정 30%(`:31~33`, `.overlay(alignment: .top)`이지만 전체 덮음) | `Color.black.opacity(0.33)`로. 거의 같음 |
| 3 | 패널 위치 | (12,308) 378x546, 화면 바닥에서 20pt | (12,230)~(12,827), 바닥에서 47pt(safe area 34 + 12) | 패널이 홈 표시줄 영역까지 내려오게 한다: 아래 `.padding(.bottom, 12)`(118행)를 safe area 무시 + 20으로(`.ignoresSafeArea(edges: .bottom)` 후 `.padding(.bottom, 20)`). 메모 칸을 접으면(4번) 높이 546이 된다 |
| 4 | 메모 입력 칸 기본 상태 | 접힘 — "메모 남기기  선택" 한 줄만 있고 입력 칸·글자 수 없음 | 입력 칸(3~6줄)과 "0 / 200"이 항상 펼쳐짐(`:72~87`) | **[기능]** `@State var memoExpanded = false`. "메모 남기기 선택" 줄을 버튼으로 만들어 누르면 펼치고 입력 칸에 초점(`@FocusState`). 펼친 모습은 R30 |
| 5 | 패널 모서리 | ≈26 | 22(`:111~112`) | `RoundedRectangle(cornerRadius: 26)` |
| 6 | 패널 배경 겹침 | `#0A0A0A` 위에 같은 크기 흰색 20%(`#FFFFFF33`) 사각이 하나 더 있음(이미지에서 패널 뒤 회색 직각 테두리로 보임) | 없음 | 내보내기 잔상(모서리가 각진 사각)으로 보인다. 반영하지 않기를 권장. 반영한다면 패널에 `strokeBorder(.white.opacity(0.2), lineWidth: 1)` 정도 |
| 7 | 안쪽 여백 | 왼쪽 27(글자 x=39), 위 31, 버튼 좌우 26 | 22(`:94`), 버튼 22(`:105`) | `.padding(.horizontal, 27).padding(.top, 31)`, 버튼 `.padding(.horizontal, 26)` |
| 8 | "하차 완료" 아이콘 | 체크만(11x8, 선 `#A6CCAF`), 글자와 10pt 간격 | `checkmark.circle`(원 안 체크)(`:36`) | `Label("하차 완료", systemImage: "checkmark")`, 아이콘 11pt semibold |
| 9 | "하차 완료" 글자 | 12pt Regular `#A6CCAF` | `.caption`(12) `#A6CCB0` | 폰트를 `FontCatalog.text(12)`로(시스템 폰트 → Noto Sans KR 계열 통일) |
| 10 | 큰 제목 "나를 위한 25 min" | 26pt Bold 흰색 | `.title`(28) Bold `#F4F6F2`(`:39`) | `FontCatalog.text(26, bold: true)`, `.white` |
| 11 | 부제 문구 | "예시 여행을 마쳤어요." 13pt `#9FA6A0` | "이번 여행을 기록했어요." `.subheadline`(15) `#BFC6C1`(`:42~43`) | 문구 `"여행을 마쳤어요."`("예시"는 예시 자리 표시로 판단. 그대로 쓸지 결정 필요), `FontCatalog.text(13)`, `#9FA6A0` |
| 12 | 세로 간격 | 하차완료→제목 35, 제목→부제 47, 부제→구분선 44, 구분선→태그 25, 태그→할일 28, 할일→라벨 37, 라벨→구분선 35, 구분선→항목 18, 항목라벨→값 22, 값→경로 40, 경로→구분선 39, 구분선→메모 26, 메모→버튼 51 | 모든 간격 16(`:35`) | VStack `spacing: 0`으로 바꾸고 각 요소에 위 값(줄 위끝 기준)을 `.padding(.top)`으로 준다. 대략: 제목 위 23, 부제 위 21, 구분선 위 31, 태그 위 25, 할 일 위 16, 라벨 위 16, 구분선 위 24, 항목 위 18, 경로 위 25, 구분선 위 28, 메모 위 26 |
| 13 | 태그 글자 | "독서" 12pt `#D7B378` | `.caption`(12), 기록의 태그 색 | 폰트만 `FontCatalog.text(12)`. 색은 기록 데이터(같은 값) |
| 14 | 할 일 글자 | 21pt Bold 흰색 | `.title3`(20) Semibold(`:49`) | `FontCatalog.text(21, bold: true)`. [데이터] "책 한 챕터 읽기" vs "논문" |
| 15 | "이번 여행에서 한 일" | 11pt `#929B95` | `.caption`(12) `#BFC6C1`(`:51`) | `FontCatalog.text(11)`, `#929B95` |
| 16 | 항목 라벨 "여행 시간"/"도착 정류장" | 11pt `#929B95` | `.caption`(12) `#BFC6C1`(`:143`) | `FontCatalog.text(11)`, `#929B95` |
| 17 | 항목 값 "25 min"/"서울숲 입구" | 15pt Bold 흰색 | `.body`(17) Semibold(`:144`) | `FontCatalog.text(15, bold: true)` |
| 18 | 두 항목 가로 위치 | 둘째 열이 x=178(첫 열 기준 +139) — 고정 2열 | `HStack(spacing: 24)`라 둘째 열 x≈113(`:56`) | `HStackLayout(alignment: .top, spacing: 0)` 안에서 첫 열 `.frame(width: 139, alignment: .leading)` |
| 19 | 경로 줄 | "2014번 · 성수역 → 서울숲 입구" 11pt `#8F9892` | "2014 · 성수역 → 서울숲 입구" `.caption`(12) `#BFC6C1`(`:62~63`) | 문구 `"\(record.bus)번 · \(record.from) → \(record.to)"`, `FontCatalog.text(11)`, `#8F9892` |
| 20 | 구분선 | 324 폭, 흰색 15% | `Divider().overlay(.white.opacity(0.15))` | 같음(폭은 7번 여백으로 맞춰짐) |
| 21 | "메모 남기기" / "선택" | 14pt Regular 흰색 / 11pt `#858E87`, 간격 10 | `.subheadline`(15) / `.caption`(12) `#BFC6C1`, 간격 8(`:68~70`) | `FontCatalog.text(14)` 흰색, `FontCatalog.text(11)` `#858E87`, spacing 10 |
| 22 | 주 버튼 모양 | 327x43, `#FFFFFF`, 테두리 `#444444`, 글자 15pt Regular 검정, 캡슐 | 최소 52 높이, `#F4F6F2`, 17pt Bold, 모서리 24 | R34 18번(공통 `FMPrimaryButtonStyle`). 이 화면 높이는 43이라 `minHeight`를 인자로 받거나 `.frame(height: 43)`. 버튼 아래 패널 여백 25 |
| 23 | 버튼 영역 배경 | 패널과 한 덩어리(구분 없음) | 별도 `safeAreaInset` 영역에 panel 배경(`:99~110`) | 같은 색이라 보이는 차이는 없음. 3번에서 하단 여백 조정 시 함께 |
| 24 | 화면 위쪽 상태바 아래 띠 | 없음 | 상단 safe area에 반투명 띠(캡처 0~62pt, 지도보다 밝은 회색) | `.toolbar(.hidden)`(126행) 뒤 내비게이션 바 배경이 남는 것으로 보임. `.toolbarBackground(.hidden, for: .navigationBar)` 추가 |
| — | [데이터] 할 일 | 책 한 챕터 읽기 | 논문 | 시드 값 |

R17 차이 24개.

---

## R30-summary-memo (요약, 메모 입력 중)

R17의 1~3, 5~22, 24번이 그대로 있다. 메모를 펼친 상태의 추가 차이는 아래와 같다.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 패널이 위로 늘어남 | 메모를 펼치면 패널 위끝이 308 → 124로 올라가고 지도가 위쪽 가운데 작은 조각(60x131)만 보임 | 패널 위끝 230 그대로(펼침/접힘 구분이 없어 처음부터 큼) | **[기능]** R17 4번 펼침 상태에서 패널 높이가 늘어나도록(현재 `bodyHeight + actionHeight` 계산, 113~114행) 그대로 두되 최대 높이를 `화면 높이 - 124`로. 키보드가 올라와도 패널이 가려지지 않게 확인 |
| 2 | 입력 칸 위 라벨 | "기억하고 싶은 생각" 12pt `#CCCCCC`, 칸 위 18pt(y=587) | 같은 문구가 칸 안 placeholder로만 있음 | 칸 위에 `Text("기억하고 싶은 생각")` 12pt `#CCCCCC`를 따로 두고, placeholder는 빈 문자열(또는 시안에 없는 짧은 안내). 낭독 라벨 "메모"는 유지 |
| 3 | 입력 칸 크기·모양 | (40,609) 323x91, 채움 `#151A16`, 테두리 `#5C655F` 1pt, 모서리 ≈12 | 폭 ≈333, 높이 ≈88, 채움 `#151A16`, 테두리 흰색 30%, 모서리 10(`:74~77`) | `RoundedRectangle(cornerRadius: 12)`, 테두리 `#5C655F`, `.frame(minHeight: 91)` |
| 4 | 입력 중 강조 테두리 | 칸 바깥 3pt 띄운 `#D7B378` 2pt 테두리(36,605 330x98) | 없음 | `@FocusState memoFocused`를 두고 초점일 때 `.overlay(RoundedRectangle(cornerRadius: 15).stroke(#D7B378, lineWidth: 2).padding(-3))`. 기록 메모 편집(`RecordMemoEditor.swift:35`)과 같은 금색 계열 |
| 5 | 입력 글자 | 13pt Regular 흰색, 칸 안 왼쪽 12·위 15, 줄 간격 20(y=624·644) | 시스템 body(17), 패딩 12(`:72~74`) | `.font(FontCatalog.text(13))`, `.lineSpacing(7)`, `.padding(.horizontal, 12).padding(.vertical, 15)` |
| 6 | 크기 조절 손잡이 | 칸 오른쪽 아래 7x7 대각선 손잡이(흰색 45%) | 없음 | 장식이다. `Image(systemName: "line.diagonal")` 7pt 흰색 45%를 `.overlay(alignment: .bottomTrailing)`로 두거나 생략(웹 textarea 흔적으로 보여 생략 권장) |
| 7 | 글자 수 | "31 / 200" 10pt `#929B95`, 칸 오른쪽 끝 맞춤, 칸 아래 5pt | `.caption2`(11) `#BFC6C1`, 칸 아래 8pt(`:84`) | `FontCatalog.text(10)`, `#929B95`, 위 간격 5 |
| 8 | "메모 저장" 보조 버튼 | 글자 수 아래 6pt, (40,721) 79x43, 채움 `#111111`, 테두리 `#444444`, 글자 12pt Regular 흰색, 캡슐 | 없음 | **[기능]** 요약을 끝내지 않고 메모만 저장하는 버튼을 추가: `model.updateRecordMemo(draft.text, forJourneyID: summary.recordID)` 호출 후 저장됨 표시(예: 버튼 문구 잠시 "저장했어요"). 스타일 `padding(.horizontal, 15)`, `frame(height: 43)`, `Capsule().fill(#111111)`, `strokeBorder(#444444)`. 빈 메모면 비활성 |
| 9 | 주 버튼 위치 | 패널 아래쪽 같은 자리(786) | 같음 | R17 22번 스타일만 |
| 10 | 주 버튼 문구 | "메모 저장하고 마치기" | 같음(`:101`) | 같음. 8번 저장 뒤 메모가 이미 저장됐으면 "여정 마치기"로 되돌릴지 결정 필요 |
| — | [데이터] 할 일 | 책 한 챕터 읽기 | 논문 | — |

R30 차이: 고유 9개(10번은 동일 확인) + R17 공통 23개.

---

## R25-memo (하차 후 홈의 메모 입력 카드) — 앱에 없음

앱은 하차 요약에서 "여정 마치기"를 누르면 메인으로 가고, 메인에는 방금 마친 여행 카드가 없다. 메모는 요약(R30)과 기록 화면의 `RecordMemoEditor` 시트에서만 쓴다. 시안은 하차 후 홈(R18)의 "예시 여행 기록" 카드에서 "메모 남기기"를 누르면 카드가 펼쳐져 홈에서 바로 메모를 쓰게 한다.

### 새로 만들 것

**[기능] 1. "방금 마친 여행" 상태**
- `AppModel`에 `recentFinishedRecordID: String?`(저장 안 되는 화면 상태로 충분)를 둔다. `finishAlightingSummary`(`AppModel+Alighting.swift:55~63`)에서 `path = []` 직전에 `summary.recordID`를 넣는다.
- 지우는 시점: 새 여정 준비로 들어갈 때, "나중에"를 눌러도 카드는 남기고 펼침만 닫을지(시안 R18은 접힌 카드), 앱 재실행 시 사라질지 결정 필요. 권장: 새 여정을 시작하면 지움, 재실행 시 사라짐.
- 메모를 요약에서 이미 썼으면 "메모 남기기" 대신 "메모 수정"으로 할지 결정 필요(시안 없음).

**2. 접힌 카드(R18과 같음)** — `MainHomeView.footer`의 시작 버튼 바로 위
- 패널 (18,718) 366x60, `#0A0A0A`, 모서리 ≈20, 시작 버튼 위 17pt.
- 왼쪽 "예시 여행 기록" 12pt Bold 흰색, 왼쪽 여백 14. 실제 문구는 "방금 마친 여행 기록"처럼 정할 것("예시"는 예시 자리 표시로 판단).
- 오른쪽 알약 두 개: "메모 남기기" 11pt `#E6F4EA`, 배경 `#28382E` 69x36 모서리 ≈10(선택된 모양) / "기록 보기" 11pt `#DDE6DF` 배경 없음, 오른쪽 여백 22.
- "기록 보기" **[기능]**: `openDestination(.records)` 후 해당 기록으로 스크롤/선택.

**3. 펼친 카드(R25)**
- 패널 (18,437) 366x341로 커진다. 좌우 안쪽 여백 14.
- 머리줄: 2번과 같음(y=460). 아래 구분선 y=497, 338폭, 흰색 14%(`#FFFFFF24`).
- 할 일 "책 한 챕터 읽기" 13pt Bold 흰색(y=516).
- 요약 줄 "성수역 → 서울숲 입구 · 25 min" 11pt `#BFC6C1`(y=538). 형식 `"\(from) → \(to) · \(minutesText)"`.
- 질문 "이번 여행은 어땠나요?" 12pt `#DDE6DF`(y=570). `RecordMemoEditor`의 제목 문구와 같다.
- 입력 칸 (32,594) 338x101, 채움 `#111814`(덤프에 같은 크기 흰색 19% `#FFFFFF30` 층이 더 있지만 이미지에서는 짙은 녹회색 `#151A16` 근처로만 보여 테두리 층으로 판단 → 1pt `#FFFFFF30` 테두리로 구현). 모서리 ≈14. 입력 글자 16pt Regular 흰색, 줄 간격 26(lh≈1.6), 칸 안 왼쪽 12·위 15. 커서 색 `#8EDBA4`(`.tint`).
- 초점 테두리: 바깥 3pt에 `#D7B378` 2pt(29,591 344x107).
- 크기 손잡이 7x7(생략 권장, R30 6번과 같음).
- 글자 수 "42 / 200" 10pt `#BFC6C1`, 오른쪽 맞춤, 칸 아래 7pt. `RecordMemoDraft.counterText` 재사용.
- 버튼 두 개(y=727, 164x39씩, 사이 9pt, 모서리 ≈12):
  - "메모 저장" 흰 배경 검정 12pt → `model.updateRecordMemo(draft.text, forJourneyID: recentFinishedRecordID)`. 성공하면 카드 접힘 + 저장 안내, 실패하면 `JourneyTimerDisplay.transitionFailureText`(오렌지).
  - "나중에" `#111111` 배경, 테두리 `#444444`, 흰 글자 12pt → 저장 없이 접기.
- 200자 제한·잘림 처리는 `RecordMemoDraft`(요약·기록과 같은 규칙)를 그대로 쓴다.
- 키보드가 올라오면 카드가 가려지지 않게 `ScrollView`가 초점 칸으로 스크롤되는지 확인(`MainHomeView`는 이미 ScrollView).

**4. 홈의 다른 요소** — R18과 같다(아래 R18 표의 1~6번). 펼친 상태에서는 가운데 정류장 표시가 카드에 가려져 보이지 않는다.

**5. 접근성·테스트 식별자 제안**
- `main.recentRecord`(카드), `main.recentRecord.memo`(메모 남기기), `main.recentRecord.records`(기록 보기), `main.recentRecord.field`, `main.recentRecord.save`, `main.recentRecord.later`, `main.recentRecord.counter`.
- `PenParityCaptureTests`에 R25 캡처 추가: seed `alightArrived` → 하차 → 요약에서 메모 없이 `summary.home` → `main.recentRecord.memo` → 두 줄 입력.

R25: 앱에 없는 새 화면 상태 1개(구성 요소 5묶음, 그 안에 [기능] 4건: 최근 기록 상태, 기록 보기 이동, 메모 저장, 나중에).

---

## R18-home-after (하차 후 홈) — 대응 화면 없어 메인으로 대체 캡처

캡처는 하차 뒤 일반 메인이다. 시안 요소 중 앱에 없거나 다른 것:

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 방금 마친 여행 카드 | (18,718) 366x60 "예시 여행 기록" + "메모 남기기"/"기록 보기" | 없음 | **[기능]** R25 1·2번 |
| 2 | 상단 도구 | 버튼 2개(기록·마이), 43pt, 테두리 `#444444` | 버튼 4개 + "Focus Mate" 워드마크 | R34 1·2번과 같음(R01 공통) |
| 3 | 제목 둘째 줄 | "오늘은 조금 느긋하게." | "나만의 속도로 출발해요." | R34 4번. [데이터] 첫 줄 "서울숲에서," vs 앱 "서울숲 입구에서,"(현재 정류장 이름 그대로. 시안은 짧은 이름) |
| 4 | 제목 검은 띠·인사 색 | 줄마다 검정 53% 띠, 인사 `#E1E5E8` | 띠 없음, 인사 `#BFC6C1` | R34 3·5·6번 |
| 5 | 가운데 정류장 표시 | 핀 아이콘 없음. "현재 위치 · 가상 정류장" 10pt `#B5B5BA`(가운데, y=437) + 정류장 이름 16pt Bold 흰색, 검은 상자(`#000000`, 92x29, 글자 둘레 6pt) 안. 방면 줄 없음 | `mappin.and.ellipse` 36pt + "앱 속 현재 정류장" 12pt + 이름 20pt Bold + "성수대교 북단 방면" 12pt, 그림자(`MainHomeView.swift:116~134`) | `station` 뷰를 바꾼다: 아이콘·방면 줄 삭제(방면은 낭독 값으로만 유지), 라벨 문구 "현재 위치 · 가상 정류장" `FontCatalog.text(10)` `#B5B5BA`, 이름 `FontCatalog.text(16, bold: true)` `.padding(.horizontal, 6).padding(.vertical, 6).background(.black)`, 그림자 제거, 라벨-이름 간격 3. 화면 세로 위치는 y≈437~479(화면 중앙 약간 위) |
| 6 | 시작 버튼 | (19,795) 365x51, 흰색 `#FFFFFF`, 테두리 `#444444`, "여행 시작하기" 15pt Regular 가운데, 화살표 없음, 캡슐 | (20,772) 362x52, `#F4F6F2`, 17pt Bold, 오른쪽 끝 `arrow.right`(`MainHomeView.swift:174~184`) | `startButton`에서 `Image(systemName: "arrow.right")`와 Spacer를 지워 글자만 가운데. 스타일은 R34 18번. 아래 여백: 버튼 바닥 846 → 화면 바닥에서 28pt(홈 표시줄 위 16pt), 지금 50pt → `.padding(.bottom)`을 safe area 무시 기준 28로 |
| 7 | 지도 어둡게 | 전체 검정 33% | 위→아래 그라데이션(0.92→0.55→0) | R34 5번 |
| — | [데이터] 인사말 | "오늘도 수고했어요." | "좋은 아침이에요." | 실행 시각 |

R18 차이 7개.

---

## 공용 컴포넌트 변경 시 영향

- `FMPrimaryButtonStyle`(FMDesign.swift:11~22): R34·R17·R30·R18의 주 버튼이 모두 흰색 `#FFFFFF`, `#444444` 1pt 테두리, 15pt Regular, 캡슐 모양이다. 다른 담당 화면에서도 같은지 확인하고 공용으로 한 번에 바꾸는 편이 낫다.
- `PassFace`(PassFace.swift): 번호 줄 추가, 테두리 `#51565A`, 글자 크기 기준 변경은 승차권·마이페이지·카드 꾸미기 화면에도 퍼진다.
- `CardTagScreen`: 승차(R27·R12)와 하차를 함께 그린다. R28·R29 수정은 `CardTagKind`별 문구로 나눠야 R27 시안과 충돌하지 않는다.
- `BoardingGeometry.tagAreaSize` 축소(R28 17번)는 접촉 판정 테스트에 영향이 있다.
