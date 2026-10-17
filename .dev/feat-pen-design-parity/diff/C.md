# 시안 대비 앱 차이 C — 승차 태그·여행 지도 묶음

담당: R27-board-tag, R12-boarding-done, R42-board-custom, R13-focus-map, R14-next-stop(앱에 없음), R15-paused, R16-end-confirm, R22-sound-recover(앱에 없음)

읽는 법
- 좌표는 402x874pt 시안 기준이다. 앱 캡처(1206x2622px, @3x)는 px÷3으로 pt로 바꿔 비교했다.
- `[기능]`은 동작·상태·정책까지 바뀌는 항목이다. 표시가 없으면 화면만 바꾸면 된다.
- `[데이터]`는 예시 값만 다른 것이라 고칠 대상이 아니다.
- `(이미지 추정)`은 덤프에 수치가 없어서 시안 PNG를 보고 잰 값이다. 오차는 ±2pt 정도다.
- 경로는 `ios/FocusMate/` 기준이고, 줄번호는 worktree `next-step-w19`의 현재 파일 기준이다.
- 상태 표시줄(배터리·Wi-Fi), Apple 지도 로고·Legal 표기(MapKit 필수 표기라 지울 수 없음), 시안의 path 경계 상자 렌더 흔적(원형 버튼 뒤의 회색 사각형)은 차이에서 뺐다.

## 공통 (C 묶음 전체)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| C-1 | 글꼴 | 모든 글자가 Noto Sans KR | 태그·여행 화면은 시스템 글꼴, 카드(PassFace)는 서울알림체(`FontCatalog`) | 전역 결정이 필요하다. Noto Sans KR을 쓰기로 하면 `FontCatalog.register()`에 NotoSansKR-Regular/Bold를 추가하고, 아래 수정안의 `.system(size:)`를 `FontCatalog.text(size, bold:)`로 바꾼다. 아래 크기·굵기 값은 글꼴과 상관없이 적용한다. |
| C-2 | 원형 버튼 재질 | 46pt 원, `#080808` 80% 채움 위에 `#FFFFFF` 14.5%(`#FFFFFF25`) 덧칠 | 48pt 원, `.black.opacity(0.6)` | 공통 수정자 `fmGlassCircle(size: 46)`을 만들어 `Circle().fill(Color(hex:0x080808).opacity(0.8)).overlay(Circle().fill(.white.opacity(0.145)))`로 그린다. FMDesign.swift에 둔다. |

---

## R27-board-tag (승차 태그, 대기 상태) — 차이 20개

시안 `pen/R27-board-tag.png`, 덤프 `spec/R27-board-tag.txt` / 앱 `app/R27-board-tag.png`
담당 코드: `CardTagScreen.swift`(화면 전체), `BoardingRules.swift`(`BoardingGeometry`), `PassFace.swift`(카드 그림)

### 배치·배경
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 27-1 | 화면 배경색 | `#101411`(초록빛 검정) | `#101112` | CardTagScreen.swift:64를 `Color(red: 0x10/255, green: 0x14/255, blue: 0x11/255)`로 |
| 27-2 | 왼쪽 위 뒤로 버튼 | 덤프에 있으나 DISABLED라 화면에 없음 | 44pt 원형 뒤로 버튼이 보인다(16,62) | [기능] 시안대로라면 승차도 `navigationBarBackButtonHidden(true)`로 숨긴다(CardTagScreen.swift:72). 다만 AC-14(승차는 뒤로가기를 남김)와 충돌하므로 결정이 필요하다. 숨기면 엣지 스와이프만 남기거나 다른 이탈 경로를 정해야 한다. |
| 27-3 | 세로 배치 | 단말기 위 y=191, 올림 화살표 y=550, 카드 위 y=593 | 단말기 y≈172, 화살표 y≈577, 카드 y≈608(Spacer 비율 배치) | CardTagScreen.swift:47-61의 Spacer를 고정 간격으로 바꾼다. 위 여백은 191−안전영역(62)=129pt(`Spacer().frame(height:129)` 또는 `.padding(.top,129)`), 단말기, `Spacer(minLength:0).frame(height:73)`, 화살표(22pt), 21pt, 카드 순서. 나머지는 아래 Spacer가 받는다. |
| 27-4 | 하단 안내 띠 | (기본 상태) 없음 | 저장 직후 진입이면 "카드 외형을 저장했어요." 검은 띠가 남는다(R42 참고) | R42-1 참고 |

### 단말기(terminal, CardTagScreen.swift:106-133)
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 27-5 | 단말기 크기 | 237x286, x=83 | 폭 274, 높이 약 337(내부 크기로 정해짐) | `.frame(width: 274)`(:125)를 `.frame(width: 237, height: 286)`로. 내부 간격은 아래 27-7~27-12를 따른다. |
| 27-6 | 단말기 모서리·색 | 채움 `#1B1D1E`, 테두리 `#525454` 1pt, r≈24(이미지 추정) | 채움 `#1B1D1E`(일치), 테두리 `white 20%`, r=28 | :126-127에서 `cornerRadius: 28`을 24로, `.stroke(.white.opacity(0.2))`를 `.stroke(Color(hex:0x525454), lineWidth:1)`로 |
| 27-7 | 위쪽 표시줄 | 156x4, 위에서 13pt, 좌우 여백 40pt, 대기색 `#737C76` | 높이 4, 좌우 여백 24(폭 226), `.gray.opacity(0.6)` | :110-111을 `.frame(width:156, height:4)`, `.padding(.top,13)`으로. 대기색은 `Color(hex:0x737C76)`. VStack `spacing:16`과 `.padding(.vertical,15)`(:109, :124)는 빼고 각 요소에 명시 간격을 준다. |
| 27-8 | LCD 크기·간격 | 201x125, 표시줄 아래 18pt(단말기 위 기준 y=35), 좌우 18pt | 높이 112, 좌우 18 | :159 `.frame(height:112)` → `.frame(width:201, height:125)`. 표시줄과의 간격은 18pt. |
| 27-9 | LCD 모서리·테두리 | 채움 `#090B0C`, 테두리 `#5D625F`, r≈12(이미지 추정) | 채움 일치, 테두리 `white 35%`, r=14 | :160-161의 r을 12로, 테두리를 `Color(hex:0x5D625F)` 1pt로 |
| 27-10 | LCD 머리줄 | "Focus Mate" 9pt regular `#C0C7C2`. 시각 10pt **bold(700)** `#F1F3F1`. 안쪽 여백 11pt. 구분선은 위에서 28pt, 폭 178, `white 14%`(`#FFFFFF24`) | 9pt `#BFC7C2`, 시각 10 semibold monospaced. 구분선은 시스템 `Divider()`, padding 12 | :138-142 시각을 `.font(.system(size:10, weight:.bold)).foregroundStyle(Color(hex:0xF1F3F1))`로. `Divider()`를 `Rectangle().fill(.white.opacity(0.14)).frame(height:1)`로. `.padding(12)`(:158)를 `.padding(.horizontal,11).padding(.top,11)`로 |
| 27-11 | LCD 본문 문구 | **"작은 시작이\n오늘을 바꿔요."** 15pt bold, 줄높이 1.5(22.5pt), 가운데 정렬, 구분선 아래 14pt | "승차 준비" 18pt semibold, 세로 가운데 | `CardTagKind.readyLCDText`(:9)는 낭독용으로 두고, 화면용 `readyLCDDisplay`를 새로 만든다(승차 = "작은 시작이\n오늘을 바꿔요."). :150을 `Text(kind.readyLCDDisplay).font(.system(size:15, weight:.bold)).lineSpacing(7.5).multilineTextAlignment(.center)`로 하고, 세로는 위 정렬에 `.padding(.top,14)`. 하차 문구는 R28 담당과 맞춘다. |
| 27-12 | 태그 영역 크기 | **149x76**, 단말기 안 x=44, LCD 아래 25pt | **238x160** | [기능] BoardingRules.swift:6 `tagAreaSize`를 `CGSize(width:149, height:76)`으로. 접촉 판정(겹침 30%)·`activationOffset`·끌기 한계가 모두 이 값에 달려 있다. BoardingRulesTests.swift:107,127과 BoardingTagControllerTests.swift:123(기대값 `(0,-196)`)의 기대값을 다시 계산해야 한다. |
| 27-13 | 태그 영역 모양·색 | 채움 `#141617`, 테두리 `#707874` 1pt, r≈18(이미지 추정) | 채움 `#202324`, 테두리 `white 32%`, r=20 | :113-114를 `RoundedRectangle(cornerRadius:18).fill(Color(hex:0x141617))`와 `.stroke(Color(hex:0x707874))`로 |
| 27-14 | 태그 아이콘 | 점 하나 + 물결 3개(17x32 획, 점 4x4) `#E1E6E2`, 영역 위에서 13pt | `wave.3.right` 40pt, `white 70%`, 영역 세로 가운데 | :115를 `Image(systemName:"dot.radiowaves.right").font(.system(size:26, weight:.light)).foregroundStyle(Color(hex:0xE1E6E2))`로 하고, 위 정렬 `.padding(.top,13)` |
| 27-15 | 태그 영역 안 문구 | "카드를 여기에" 10pt regular `#B7C1BA`, 영역 위에서 54pt | 없음 | 태그 영역 overlay의 VStack(아이콘, 9pt 간격, 텍스트)에 `Text("카드를 여기에").font(.system(size:10)).foregroundStyle(Color(hex:0xB7C1BA))` 추가. 낭독은 지금처럼 숨긴다(`accessibilityHidden`). |
| 27-16 | 단말기 아래 각인 | 태그 영역 아래 5pt에 "FOCUS MATE" 8pt regular `#A8B0AC`, 아래 여백 12pt | 없음 | terminal VStack 마지막에 `Text("FOCUS MATE").font(.system(size:8)).foregroundStyle(Color(hex:0xA8B0AC))` 추가(위 5pt, 아래 12pt) |

### 카드·안내
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 27-17 | 카드 둘레 점선 | 없음 | 8pt 바깥에 r22 점선(1.5pt, 6/5, 깜박임) | CardTagScreen.swift:174-177의 `.padding(8)`과 점선 overlay를 지운다. `blink` 상태와 :82 애니메이션도 함께 지운다. `cardRest`의 `insetBy(dx:8,dy:8)`(:195-196)도 0으로 바꾼다. |
| 27-18 | 카드 크기·비율·모양 | 270x158(비율 1.709), r=14, 테두리 `#51565A` 1pt | 268x168.4(PassFace 비율 352/221.19=1.591), r=16·s≈12.2, 테두리 `white 8%` | `BoardingGeometry.cardWidth`(BoardingRules.swift:16)를 270으로. 비율은 PassFace 공통값(PassFace.swift:5)이라 다른 화면에도 영향이 있다. 다른 시안의 카드 비율이 1.71이면 공통으로 바꾸고, 아니면 태그 화면만 `.frame(width:270,height:158)`로 강제한다. 테두리는 PassFace.swift:56을 `Color(hex:0x51565A)` 1pt로, 모서리는 r=14@270(=`18.25*s`)로 |
| 27-19 | 카드 안 그림(기본 카드) | 서울 점지도 **없음**. "Focus Mate" 10pt bold `#F1F2F3` (21,18). "집중동행카드" 18pt bold (65,64). "나를 위한 시간, 한 장으로." 9pt (65,98). 칩 30x22 (22,69). 물결 12x19 (236,16) `#D5DED7`. 카드 번호 "FM · 0842 3017" 7pt (21,134) | 점지도(`PassDots`) 있음. 글자 8.4/15.2/6.9pt(352 기준 11/20/9에 s=0.761). 칩 31x23 (20,73). 물결 흰색 (243,11). 번호 없음 | PassFace.swift:27-39. ① 점지도 블록(:28-32)을 지우거나 `showsDots` 인자를 꺼서 숨긴다. 메인 등 다른 화면 시안을 먼저 확인한다. ② 352 기준값을 바꾼다(270→352 환산 ×1.304): Focus Mate `13*s` bold @(27.4,23.5), 제목 `23.5*s` bold @(84.8,83.5), 부제 `11.7*s` @(84.8,127.8), 칩 `39x28.7` @(28.7,90), 물결 `15.6x24.8` @(307.7,20.9) 색 `#D5DED7`. ③ [기능] 카드 번호 표시: 7pt(`9.1*s`) `#F1F2F3` @(27.4,174.7). `PassIdentity` 주석의 BR-4(번호 비노출)를 바꿔야 하므로 정책 결정이 필요하다. PassFace가 `numberText`를 받도록 인자를 추가한다. |
| 27-20 | 올림 화살표 | 22x22 아이콘 `#C5CFC7` | `chevron.up.2`, `.title2`, `white 85%` | CardTagScreen.swift:54를 `.font(.system(size:18, weight:.medium)).frame(width:22,height:22).foregroundStyle(Color(hex:0xC5CFC7))`로 |
| 27-21 | 탭 안내 문구 | (DISABLED, 탭했을 때 뜨는 문구) "카드를 위의 단말기로 올려주세요" 12pt regular `#BDC8BF`, 가운데, y=772 | "카드를 위로 밀어 단말기에 대주세요" `.subheadline`, 흰색, 화면 아래 | CardTagScreen.swift:205의 문구와 글자를 `Text("카드를 위의 단말기로 올려주세요").font(.system(size:12)).foregroundStyle(Color(hex:0xBDC8BF))`로. 위치는 위 기준 y=772이고 notices `.padding(.bottom,8)`(:215)을 `.padding(.bottom, 874-784-34)`≈56으로 맞춘다. UI 테스트에 이 문구 단정이 있으면 함께 고친다. |

[데이터] LCD 시각: 시안은 "20:00", 앱은 실제 현재 시각(11:08). 고정 문구가 아니라 시각 값이다(덤프 레이어 이름은 "2014"인데 내용은 20:00). 도착 예정 시각을 뜻하는 것이라면 [기능]이 된다. 디자이너에게 확인이 필요하다.

(번호 정리) 27-4는 R42 항목과 같으므로 개수에서 뺐다. 실제 차이는 27-1~27-3, 27-5~27-21로 **20개**다.

---

## R12-boarding-done (승차 태그 완료, held) — 차이 12개

시안 `pen/R12-boarding-done.png` / 앱 `app/R12-boarding-done.png`
R27의 단말기·배경·뒤로 버튼·카드 그림 항목(27-1,2,5~10,12~16,18,19)은 여기에도 똑같이 적용된다. 아래는 완료 상태에만 있는 차이다.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 12-1 | 위쪽 표시줄 인식색 | `#B2C9B9` | `Color(0.7,0.85,0.75)` = `#B3D9BF` | CardTagScreen.swift:110을 `Color(hex:0xB2C9B9)`로. :147 체크 색도 같은 값을 쓰면 일관된다. |
| 12-2 | LCD 테두리(인식) | `#848F87`로 밝아짐 | 대기와 같은 `white 35%` | :161을 `controller.isRecognized ? Color(hex:0x848F87) : Color(hex:0x5D625F)`로 |
| 12-3 | LCD 본문 구성 | 왼쪽에 **카드 축소판 100x64**(r12, LCD 안 (10,45)). 오른쪽 세로 묶음(x=216): "집중동행카드" 12pt bold 흰색 y=276, 체크 11x8 `#EEF2EF` y=272, "나의 Focus Mate" 8pt bold `#CBD3CE` y=310, 번호 "FM · 0842 3017" 7pt regular `#B7C1BA` y=327 | 가운데에 "집중동행카드" 18 semibold와 초록 체크(title3)를 세로로 | CardTagScreen.swift:144-148을 `HStack(alignment:.top, spacing:5){ PassFace(style:model.currentCardStyle).frame(width:100,height:64); VStack(alignment:.leading, spacing:0){ HStack(spacing:4){Text("집중동행카드").font(.system(size:12,weight:.bold)); Image(systemName:"checkmark").font(.system(size:9,weight:.bold)).foregroundStyle(Color(hex:0xEEF2EF))}.padding(.top,5); Text("나의 Focus Mate").font(.system(size:8,weight:.bold)).foregroundStyle(Color(hex:0xCBD3CE)).padding(.top,22); Text(numberText).font(.system(size:7)).foregroundStyle(Color(hex:0xB7C1BA)).padding(.top,9) } }`로. 시안은 체크가 제목 끝 글자와 겹치는데(x=276, 제목 216~296) 디자인 실수로 보여 제목 오른쪽 4pt에 둔다. 번호 줄은 [기능] BR-4 결정을 따른다(27-19). |
| 12-4 | "나의 Focus Mate" 문구 | 있음 | 없음 | 12-3에 포함. 고정 문구다. |
| 12-5 | 카드 축소·위치 | 인식되면 카드가 **211x123(×0.78)**로 줄고, 중심이 태그 영역 중심(201.5, 413.5)에 오며, 단말기 아래쪽(위 352~475)을 덮는다 | 카드가 268폭 그대로 y≈439~607에 놓여 단말기(아래 509) 밖으로 크게 삐져나온다 | [기능] CardTagScreen.swift:172-178의 카드에 `.scaleEffect(controller.isRecognized ? 211/270 : 1, anchor:.center)`를 추가하고, 인식 단계(`contacting`/`held`)의 `cardOffset`은 카드 중심이 tagFrame 중심에 오도록 한다. `BoardingTagController`의 접촉 처리(:128 부근)에서 `cardOffset = CGSize(width: tagArea.midX - cardRest.midX, height: tagArea.midY - cardRest.midY)`로 맞추고 스프링 0.3s로 옮긴다. 동작 줄이기에서는 바로 둔다. |
| 12-6 | 완료 배지 | 축소 카드 오른쪽 아래 (176,89)에 27x27 원 `#D7EFDC`, 안에 체크 10x7 획 `#183822`(약 2pt) | 없음 | 카드 overlay(.bottomTrailing)에 `Circle().fill(Color(hex:0xD7EFDC)).frame(width:27,height:27).overlay(Image(systemName:"checkmark").font(.system(size:11,weight:.bold)).foregroundStyle(Color(hex:0x183822))).padding(.trailing,8).padding(.bottom,7)`를 넣고 `controller.isRecognized`일 때만 보인다. 축소 전 좌표 기준 크기는 34.6pt다. |
| 12-7 | 올림 화살표 | 완료 상태에서는 없음 | 그대로 보인다(뒤에 깔림) | CardTagScreen.swift:54에 `.opacity(controller.isRecognized ? 0 : 1)` |
| 12-8 | 태그 영역 "태그 완료" 표시 | 태그 영역이 `#242829`/테두리 `#A6B6AC`로 바뀌고 아이콘 `#E5EEE7`, "태그 완료" 10pt `#DCE5DF`. 단 카드에 가려 화면에는 거의 안 보인다 | 바뀌지 않음 | 우선순위 낮음. 태그 영역 색을 `isRecognized`로 바꾸고 문구를 "카드를 여기에"→"태그 완료"로 바꾼다(:113-115). |
| 12-9 | 카드 점선 | 없음 | (완료에서는 opacity 0이라 안 보임) | 27-17에서 지우면 함께 해결된다. 별도로 세지 않는다. |
| 12-10 | 카드 그림 | 점지도 없음, 번호 있음(축소판·큰 카드 모두) | 점지도 있음, 번호 없음 | 27-19와 같다. |
| 12-11 | 완료 안내 문구 | (DISABLED) "승차 완료 · 출발합니다" 12pt `#BDC8BF` y=772 | 없음 | 표시하지 않는 문구다. 낭독용 공지를 이 문구로 맞출지만 확인한다. 개수에서 뺐다. |
| 12-12 | 뒤로 버튼 | 없음 | 있음 | 27-2와 같다. |
| 12-13 | 단말기 크기 | 237x286 | 274x337 | 27-5와 같다. 완료 상태에서 카드가 단말기 안에 들어가려면 필수다. |

[데이터] LCD 시각 20:00 / 11:05.
차이 개수: 12-1~12-8, 12-10, 12-12, 12-13에 R27에서 넘어온 화면 차이(배경·LCD 크기)를 더해 **12개**(중복 항목은 R27 수정으로 함께 해결된다).

---

## R42-board-custom (꾸민 카드로 승차) — 차이 7개(R27 공통 항목 제외)

시안 `pen/R42-board-custom.png` / 앱 `app/R42-board-custom.png`
단말기·배경·화살표·뒤로 버튼은 R27과 같다(27-1~27-16, 27-20 적용).

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 42-1 | 저장 알림 띠가 남음 | 없음 | 하단에 "카드 외형을 저장했어요." 검은 띠(17pt, 높이 약 60)가 승차 화면까지 계속 보인다 | [기능] RootView.swift:59-66 `savedCardNotice`는 끄는 곳이 없다. 표시 후 3초 뒤 `savedCardNotice = false`(`.task(id: savedCardNotice)` 안에서 `try? await Task.sleep(for:.seconds(3))`)를 넣고, `model.path`가 바뀔 때도 끈다(:39 `onChange(of: model.path)`에 추가). |
| 42-2 | 카드 둘레 점선 | 없음 | 있음 | 27-17 |
| 42-3 | 꾸민 카드의 "Focus Mate" 라벨 | 사진 위 (21,18)에 70x16 반투명 띠 `#080B0C` 80%(`CC`), 글자 "Focus Mate" 10pt bold `#D3D6D8`(띠 안 왼쪽 5pt) | 꾸민 카드(`!isStandard`)에서는 글자를 모두 숨긴다 | PassFace.swift:27의 `if style.isStandard` 밖으로 "Focus Mate"를 빼고, 꾸민 카드일 때는 `.padding(.horizontal,5).padding(.vertical,3).background(Color(hex:0x080B0C).opacity(0.8), in: RoundedRectangle(cornerRadius:4*s))`로 감싼다. 위치는 352 기준 (27.4,23.5), 글자 색 `#D3D6D8`. 띠 모서리는 r≈4(이미지 추정) |
| 42-4 | 꾸민 카드의 번호 라벨 | (21,130)에 65x12 띠 `#080B0C` 80%, "FM · 0842 3017" 7pt `#D3D6D8` | 없음 | [기능] 42-3과 같은 띠 처리. 번호 노출은 BR-4 결정을 따른다(27-19). |
| 42-5 | 꾸민 카드의 제목·부제 | 없음(사진이 덮음) | 없음 | 일치 |
| 42-6 | 칩·물결 위치 | 칩 (22,69) 30x22. 물결 (236,16) **흰색** 획 | 칩 (20,73), 물결 흰색 | 27-19의 기준값 수정에 포함. 꾸민 카드는 물결 색을 `.white`로 유지한다(기본 카드만 `#D5DED7`). |
| 42-7 | 카드 크기·모서리·테두리 | 270x158, r14, 테두리 `#51565A` | 268x168, r≈12 | 27-18 |
| 42-8 | 사진 배치 | 사진 2장이 서로 다른 위치·크기(210x140@(-2,-5), 132x87@(128,57)) | 픽스처 사진 2장이 같은 자리에서 겹침 | [데이터] 테스트 픽스처 배치가 달라서 생긴 차이다(INDEX.md). 그리기 로직(PassFace.swift:40-47)은 시안과 같은 방식이다. |
| 42-9 | 카드 배경 | `#D9CDB9`(sand) | sand 계열 일치 | 일치 |

[데이터] 사진 내용(도시 사진 / 단색 블록), LCD 시각.
차이 개수: 42-1, 42-2, 42-3, 42-4, 42-6, 42-7에 R27 단말기 묶음(1건으로 셈)을 더해 **7개**.

---

## R13-focus-map (여행 중 지도) — 차이 14개

시안 `pen/R13-focus-map.png` / 앱 `app/R13-focus-map.png`
담당 코드: `JourneyTimerView.swift`(버튼·하단 지표·그늘), `JourneyMapView.swift`(지도·경로·마커), `JourneyMapState.swift`(카메라 정책), `JourneyTimerDisplay.swift`

### 지도 표현
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 13-1 | 지도 종류 | 위성 사진풍 3D(건물 질감 있음, 지명 라벨 없음), 거의 위에서 내려다본 시점(기울기 약 25~30°, 이미지 추정) | MapKit 표준 다크 3D(평면 회청색 건물, 도로명·고속도로 방패 라벨 있음), 기울기 55° | JourneyMapView.swift:74-79 기본 테마 `.dark`를 `.imagery(elevation:.realistic)`로 바꾼다. 라벨이 없는 위성은 `.imagery`뿐이고, `.hybrid`는 라벨이 붙는다. 테마 시트의 "어두운 지도"는 선택지로 남긴다. JourneyMapState.swift:9 기본값을 `.satellite`로, :58 `pitchDegrees` 55→30으로. 거리(:59 1200m)는 시안 축척(화면 높이에 약 5정류장)에 맞춰 1000m 안팎으로 조정해 본다. |
| 13-2 | 전체 어둡게 | 지도 전체에 균일하게 `#000000` 33%(`#00000055`) | 하단만 검정 그라데이션(0→73%→88%, 높이 190+) | JourneyTimerView.swift:52-62 그라데이션을 지우고 `Color.black.opacity(0.333).ignoresSafeArea().allowsHitTesting(false)`를 지도 바로 위에 둔다. 지표 가독성이 부족하면 아래 120pt에만 0→20% 보조 그라데이션을 둔다. |
| 13-3 | 경로선(이번 여정) | 버스→도착 구간이 초록 `#168445`, 굵기 약 3pt(이미지 6px) | 파랑 `rgb(0.36,0.62,1)`, 5pt, 출발→도착 전체 | [기능] JourneyMapView.swift:26-27을 둘로 나눈다. 지나온 부분은 회색(13-4), 버스 위치부터 도착까지는 `MapPolyline(coordinates: [bus.point]+이후 정류장).stroke(Color(hex:0x168445), lineWidth:3)`. `JourneyMapController`에 `aheadPoints`(버스 위치 + nextStopIndex 이후 점)를 추가한다. |
| 13-4 | 노선 전체선 | 버스가 지나온 쪽과 도착 너머까지 노선 전체가 `white 27%`(`#FFFFFF44`) 약 2pt | 없음(여정 구간만 그림) | [기능] 노선 전체 좌표가 필요하다(`RouteCatalog.routes[...]`의 stops, SceneMapBackdrop.swift:20-28과 같은 방식). `CourseJourney`에 routeID로 전체 좌표를 붙이고 `MapPolyline(...).stroke(.white.opacity(0.27), lineWidth:2)`를 초록선 아래에 그린다. |
| 13-5 | 정류장 점 | 7x7 원, 테두리 `#0A0A0A` 1pt. 앞으로 갈 정류장은 흰색, 지나온 정류장은 `#777777`. 노선 전체 정류장에 찍힌다 | 10x10 흰 원, 테두리 `black 40%`. 이번 캡처에는 거의 안 보인다 | JourneyMapView.swift:28-33을 `Circle().fill(stop.index < map.nextStopIndex ? Color(hex:0x777777) : .white).frame(width:7,height:7).overlay(Circle().stroke(Color(hex:0x0A0A0A), lineWidth:1))`로. 노선 전체 정류장까지 그리는 것은 [기능](13-4와 같은 데이터) |
| 13-6 | 도착 마커 | 16x16 원 `#0A0A0A`, 테두리 초록 `#168445` 약 2.5pt, 가운데 흰 점(7pt 정류장 점이 겹침) | 주황 `flag.fill` 16pt | JourneyMapView.swift:35-38을 `Circle().fill(Color(hex:0x0A0A0A)).frame(width:16,height:16).overlay(Circle().stroke(Color(hex:0x168445),lineWidth:2.5)).overlay(Circle().fill(.white).frame(width:6,height:6))`로 |
| 13-7 | 버스 마커 | 위에서 본 초록 버스 그림(76x97 영역, 버스 몸체 약 34x58pt, 몸체 `#2E9E4F` 계열, 검은 테두리·창), 진행 방향으로 회전 | 파란 원(`rgb(0.2,0.45,0.95)`) 안의 `location.north.fill` 22pt | [기능 아님, 에셋 추가] Assets.xcassets에 `BusTopView`(PDF 벡터, 34x58pt)를 추가하고, JourneyMapView.swift:39-44를 `Image("BusTopView").resizable().frame(width:34,height:58).rotationEffect(...)`로 바꾼다. 회전 로직은 그대로 쓴다. 시안 그림은 덤프에 이미지(`fill=image`)로만 있으니 Pen에서 내보내야 한다. |

### 버튼
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 13-8 | 일시정지 버튼 | 46pt 원 (16,60), C-2 재질, 아이콘 두 막대 약 10x10pt 흰색 | 48pt 원 (16,70), `black 60%`, `pause.fill` 20 bold | JourneyTimerView.swift:126-131을 `.font(.system(size:14, weight:.bold)).frame(width:46,height:46)`과 C-2 재질로. 위치는 :111 `.padding(.top, 8)`을 `-2`로(iPhone 17 Pro 안전영역 62 기준, 0으로 두어도 2pt 차이) |
| 13-9 | 노선(다음 정류장) 버튼 | 왼쪽 두 번째 (16,116) 44pt 원, C-2 재질(`#080808` 79%+흰 14.5%), 노선 아이콘(점 2개를 잇는 꺾인 경로, 약 14x17pt) | **없음** | [기능] 일시정지 버튼 아래 10pt에 둔다. `point.topleft.down.to.point.bottomright.curvepath` 18pt. 누르면 R14 다음 정류장 패널을 켜고 끈다. 식별자 `journey.map.stops`, 라벨 "다음 정류장", 값 "펼침/접힘". topBar(:96-112)의 왼쪽을 `VStack(spacing:10){roundControl; stopsButton}`로 바꾼다. |
| 13-10 | 따라가기 버튼 | 43pt 원 (341,61), 채움 `white 12.5%`(`#FFFFFF20`), **흰 테두리 1pt**, 아이콘 조준경(원+가운데 점+십자 눈금) 18pt 흰색 | 48pt 원, `black 60%`, `location.fill`(종이비행기 화살표) 18 semibold | :102-104 아이콘을 `scope`로, :140-143 스타일을 이 버튼만 `Circle().fill(.white.opacity(0.125)).overlay(Circle().stroke(.white,lineWidth:1)).frame(width:43,height:43)`로. `toolButton`에 style 인자를 추가한다. |
| 13-11 | 지도 테마 버튼 | 46pt 원 (340,114), C-2 재질, `map` 외곽선 아이콘 17pt | 48pt, `black 60%`, `map` 18 semibold | :141 `.font(.system(size:17, weight:.regular))`, `.frame(46)`, C-2 재질 |
| 13-12 | 오른쪽 버튼 간격 | 위 버튼 아래 104 → 아래 버튼 114(간격 10) | `VStack(spacing:12)` | :101 spacing 12→10 |

### 하단 지표
| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 13-13 | 남은 시간 단위 분리 | "16" 30pt bold 흰색 + 3pt + "min" 15pt regular `white 64%`(`#FFFFFFA3`), 아래 기준선 정렬 | "15 min" 전체가 30pt bold 흰색 | JourneyTimerView.swift:170의 `Text(minutesText)`를 `Text("\(controller.remainingMinutes)") + Text(" min").font(.system(size:unitSize)).foregroundColor(.white.opacity(0.64))`로. 낭독 값은 그대로 둔다. 정류장·거리 단위(:182, :192)에도 `foregroundColor(.white.opacity(0.64))`와 regular 굵기를 명시한다. 지금은 단위 글자가 흰색으로 보인다. |
| 13-14 | 단위 색 | 개·km 모두 `white 64%` regular 15pt | "개"·"km"가 흰색(굵기는 상속된 bold일 수 있음) | 13-13에 포함 |
| 13-15 | 열 정렬 | 남은 정류장은 라벨·값 모두 가운데(ai=center), 남은 거리는 라벨·값 모두 오른쪽(ai=end) | 세 열 모두 VStack이 `.leading`이다. 프레임만 가운데·오른쪽이라 라벨이 값의 왼쪽 끝에 붙는다 | :199-204 `infoColumn`에 `alignment: HorizontalAlignment` 인자를 추가하고, 정류장은 `.center`, 거리는 `.trailing`으로 넘긴다(:161-162) |
| 13-16 | 지표 위치 | 라벨 위 y=772, 지표 묶음 높이 62, 좌우 16 | 라벨 y≈772, 좌우 16 | 일치(실행 상태). 일시정지에서는 어긋난다(R15-6). |

[데이터] 15 min/3개/1.6km ↔ 16/4/1.8. 지도 위치(실제 서울 좌표 / 시안 일러스트).
차이 개수: 13-1~13-13과 13-15로 **14개**다. 13-14는 13-13에 포함되고, 13-16은 일치한다.

---

## R14-next-stop (다음 정류장 패널) — 앱에 없음, 새로 만들 것

시안 `pen/R14-next-stop.png`, 덤프 `spec/R14-next-stop.txt`. R13 화면에서 13-9 노선 버튼을 누른 상태다.

### 무엇을 만들어야 하나
1. **[기능] 패널 열고 닫기**: `JourneyMapState`에 `isStopsPanelOpen: Bool`(기본 false)과 `toggleStopsPanel()`을 추가한다. 일시정지 중에는 다른 도구처럼 닫고 잠근다(`timerStatusChanged`에서 false로). 기존 테마 시트의 "정류장 표시" 토글(`showsStops`)은 지도 위 점을 켜고 끄는 다른 기능이므로 그대로 둔다.
2. **[기능] 정류장 정보 노출**: `JourneyMapController`에 다음 값을 추가한다.
   - `lastReachedStop`: `JourneyCourseProgress.reachedIndex`가 지금 private(:89)이라 공개 함수로 연다.
   - `nextStop`: 이미 있다.
   - `upcomingStops`: next 다음부터 도착 직전까지의 목록. `(index, name)` 형식으로, index는 출발=0 기준 순번이다. 시안의 "3 · 성동구민체육센터", "4 · 서울숲역"은 출발 성수역=0, 성수동=1, 뚝섬역=2로 센 번호다.
   - `destinationStop`: 이미 있다.
   - 중간 정류장이 많을 때는 최대 2개만 보여 주고 "외 N개"를 붙일지, 스크롤할지 정해야 한다(시안에는 2개만 있다).
3. **[기능] 패널이 열리면 지도 중심 이동**: 패널이 열리면 버스가 x=163에서 231로 68pt 오른쪽에 그려진다. `JourneyMapView`에 `.safeAreaPadding(.leading, isStopsPanelOpen ? 136 : 0)`을 주고, 카메라 목표를 다시 계산하는 애니메이션을 0.3s로 넣는다. 동작 줄이기에서는 바로 옮긴다.

### 화면 규격 (새 뷰 `JourneyStopsPanel.swift` 권장)
| 요소 | 값 |
|---|---|
| 뒤 그늘 | (0,147) 178x283, `black 13%`(`#00000022`). 패널 왼쪽을 살짝 어둡게 한다. 가장자리를 부드럽게 하려면 오른쪽으로 사라지는 그라데이션을 쓴다. |
| 패널 | (16,172) 128x216, 채움 `#090B0E` 85%(`D9`) 위에 `white 12.5%`(`#FFFFFF20`) 덧칠. r≈16(이미지 추정). 노선 버튼(아래 160) 아래 12pt |
| 세로 진행선 | x=33, y=195~364, 폭 1, `white 13%`(`#FFFFFF22`) |
| 최근 도달 | 점 5x5 `#737B84` (31,193). 라벨 "최근 도달" 9pt regular `#8C949E` (47,188). 이름(예: 성수동) 10pt regular `#A5ADB7` (47,203) |
| 다음 정류장 | 강조 원 20x20 `white 7%`(`#FFFFFF12`) (24,234) 안에 12x12 초록 `#168445` 원, 테두리 `#0A0D10` 1.5pt. 라벨 "다음 정류장" 9pt `#C2C9D0` (47,234). 이름(예: 뚝섬역) **15pt bold 흰색** (47,253) |
| 중간 정류장 | "n · 이름" 9pt regular `#929BA6`, 줄 간격 23pt (47,291), (47,314) |
| 도착 | 깃발 외곽선 아이콘(`flag`) 9x15 획 `#C9D0D7` (28,343). 라벨 "도착" 9pt `#929BA6` (47,343). 이름(예: 서울숲 입구) 11pt regular 흰색 (47,358) |
| 안쪽 여백 | 왼쪽 31(점 열), 글자 열 x=47(패널 기준 31), 위 16, 아래 18 |
| 접근성 | 패널 전체를 한 요소로 묶는다. 라벨 "다음 정류장", 값 "최근 도달 성수동, 다음 뚝섬역, 이후 성동구민체육센터, 서울숲역, 도착 서울숲 입구". 식별자 `journey.stopsPanel` |
| 나머지 | 버튼·하단 지표는 R13과 같다(13-8~13-15). |

[데이터] 정류장 이름은 모두 예시 값이다. 고정 문구는 "최근 도달", "다음 정류장", "도착", " · " 구분자다.
새로 만들 항목: 패널 뷰, 상태·토글, 컨트롤러 공개 값 4종, 지도 여백 이동, 노선 버튼(13-9). 모두 **8건**이다.

---

## R15-paused (일시정지) — 차이 13개

시안 `pen/R15-paused.png` / 앱 `app/R15-paused.png`
담당 코드: `JourneyTimerView.swift`, `JourneyAbandonBar.swift`, `JourneyView.swift:99-101`

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 15-1 | 지도 흐림 | 지도 전체가 강하게 흐려진다(가우시안 반경 약 12pt, 이미지 추정). 경로·버스는 초록 얼룩으로만 보이고 라벨은 읽을 수 없다 | 흐림 없음. 도로명·버스 마커가 그대로 보인다 | JourneyTimerView.swift:47 `JourneyMapView`에 `.blur(radius: controller.status == .paused ? 12 : 0)`를 주고, 동작 줄이기가 아니면 0.3s 애니메이션을 준다. 흐리면 MapKit 법적 표기도 흐려지므로, 필요하면 흐린 지도 위에 `Text("Legal")` 링크를 따로 둘지 검토한다. |
| 15-2 | 어둡기 | 균일하게 약 55~60% 검정(흐림과 합쳐 거의 검은 회색) | `PausedJourneyShade` 55%→68%→94% 그라데이션과, 법적 표기 주변만 30%로 밝힌 띠 | :321-345 그라데이션을 `Color.black.opacity(0.55)` 균일값으로 단순하게 바꾼다. 15-1에서 표기를 흐리게 처리하면 마스크 띠는 필요 없다. 13-2의 33% 그늘과 합쳐 계산한다(일시정지에서는 0.55로 교체). |
| 15-3 | 재개 버튼 | 46pt 원 (16,60), C-2 재질, 흰 삼각형 7x10pt | 48pt (16,70), `black 60%`, `play.fill` 20 bold | 13-8과 같다. 아이콘 `.font(.system(size:14, weight:.bold))` |
| 15-4 | 노선·따라가기·테마 버튼 | 일시정지 중에는 **없음** | 따라가기·테마 버튼이 40% 투명도로 남는다 | JourneyTimerView.swift:101-107의 오른쪽 도구 묶음과 노선 버튼(13-9)을 `if controller.status != .paused`로 감싼다 |
| 15-5 | 종료(X) 버튼 | 오른쪽 위 (340,60) 46pt 원, 채움 `#D13A42` 위에 `white 19%`(`#FFFFFF30`) 덧칠, 흰 X 11x11 획 약 2pt | 없음. 대신 하단에 "포기하기" 외곽선 캡슐 | [기능 위치 이동] JourneyAbandonBar의 버튼(:22-35)을 지운다. 일시정지일 때 topBar 오른쪽에 `Button{flow.request(isPaused:true)}`로 `Image(systemName:"xmark").font(.system(size:14,weight:.semibold))`를 `Circle().fill(Color(hex:0xD13A42)).overlay(Circle().fill(.white.opacity(0.19)))` 46pt로 둔다. 접근성 라벨은 "포기하기"(`JourneyLifecycleText.abandonButton`)와 식별자 `journey.abandon`을 유지한다. `JourneyAbandonController`·alert는 R16 수정과 함께 JourneyTimerView 쪽으로 옮기거나, JourneyAbandonBar를 overlay(.topTrailing)로 바꾼다. 실패 문구 표시(:37-42)는 하단에 남긴다. |
| 15-6 | 하단 지표 위치 | 라벨 y=772(실행 중과 같은 자리) | 포기 버튼 safeAreaInset 때문에 y≈712로 60pt 올라간다 | 15-5에서 하단 버튼을 없애면 해결된다. JourneyView.swift:99-101 safeAreaInset은 실패 문구가 있을 때만 높이를 갖게 한다. |
| 15-7 | "일시정지됨" 글자 | 18pt **regular** `#BBBBBB`, 가운데, 위 y=630 | `.title3`(20pt) medium, `white 73%`, y≈654 | JourneyTimerView.swift:68-71을 `.font(.system(size:18)).foregroundStyle(Color(hex:0xBBBBBB))`로 |
| 15-8 | "현재 정류장으로" 버튼 | (24,705) 354x44 캡슐, 채움 `#0A0A0A` 75%(`BF`), 테두리 `white 38%`(`#FFFFFF60`) 1pt, "현재 정류장으로" 13pt regular 흰색 가운데 | 없음 | [기능] 새 버튼. 동작은 일시정지 중 잠긴 따라가기를 대신해 카메라를 현재(최근 도달) 정류장/버스 위치로 되돌리는 것으로 보인다. `JourneyMapState.followTapped`의 일시정지 가드(:24)를 이 경로에만 풀어 주는 `recenterWhilePaused()`를 추가한다. 의미가 "현재 정류장에서 끝내기"인지는 디자이너 확인이 필요하다. 그 경우 X와 겹친다. 식별자 `journey.recenter` |
| 15-9 | 세로 간격 | 일시정지됨(630~648) → 19pt → 예시 문구(667~680) → 25pt → 버튼(705~749) → 23pt → 지표(772) | 일시정지됨과 지표 사이 `VStack(spacing:24)`, `.padding(.top,16)` | :66-74를 `VStack(spacing:0){ 일시정지됨; Spacer().frame(height:19)…; 버튼.padding(.horizontal,8)(24−16); Spacer().frame(height:23); bottomInfo }`로 명시한다. 예시 문구를 빼면 일시정지됨→버튼 간격은 57pt(630+18→705)다. |
| 15-10 | "예시 여정 · 실제로 저장하지 않아요." | 13pt regular `#D5DDD6`, (72,667) | 없음 | 시안의 데모(예시 여정) 모드 전용 문구로 보인다. 앱에는 예시 여정이 없으므로 **넣지 않는 것을 권장**한다. 넣는다면 [기능]으로 예시 모드 판정이 필요하다. 결정 필요 항목으로 남긴다. |
| 15-11 | 하단 그라데이션 | 없음(흐림+균일 어둡기) | 0→73%→88% 검정 그라데이션 | 13-2와 같다 |
| 15-12 | 남은 시간 단위·열 정렬 | 13-13~13-15와 같다 | "15 min" 전체 bold, 라벨 왼쪽 정렬 | 13-13, 13-15 |
| 15-13 | 지도 테마 상관없이 흐린 위성 질감 | 흐린 사진 질감 | 다크 벡터 지도 | 13-1 |

[데이터] 15/3/1.7 ↔ 16/4/1.8.
차이 개수 **13개**(15-1~15-13. 15-10은 결정 필요 항목).

---

## R16-end-confirm (종료 확인) — 차이 12개

시안 `pen/R16-end-confirm.png` / 앱 `app/R16-end-confirm.png`(시스템 alert)
담당 코드: `JourneyAbandonBar.swift:47-55`(`.alert`), `JourneyLifecycleText.swift:20-23`

시스템 `.alert`로는 시안 모양을 낼 수 없으므로 사용자 정의 모달로 바꿔야 한다. 동작(계속/그만두기, 포커스 복귀)은 그대로 둔다. 새 뷰 `JourneyAbandonDialog`를 JourneyTimerView 위 `.overlay`로 띄우고 `flow.isConfirming`으로 켠다.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 16-1 | 모달 종류 | 사용자 정의 카드 | iOS 26 시스템 alert(유리 재질, 둥근 큰 모서리) | 위 설명. `.accessibilityAddTraits(.isModal)`, 뒤 요소 `accessibilityHidden(true)`, 열릴 때 제목에 포커스. 기존 식별자 `journey.abandon.cancel`/`.confirm`을 유지한다. |
| 16-2 | 뒤 어둡게 | 화면 전체 `black 60%`(`#00000099`). 뒤 화면은 R15 그대로(흐린 지도·버튼) | alert 기본 dim(약 20~30%) | `Color.black.opacity(0.6).ignoresSafeArea()` |
| 16-3 | 카드 크기·위치 | 358x246, x=22(좌우 22), y=314(세로 가운데, 중심 y=437) | 폭 약 318, 가운데 | `.frame(width:358)`(또는 `.padding(.horizontal,22)`), 세로 가운데. 높이는 내용으로 정한다(246). |
| 16-4 | 카드 재질 | 채움 `#0C0C0C`, 테두리 `white 25%`(`#FFFFFF40`) 1pt, r≈24(이미지 추정) | 유리 재질 회색, r≈36 | `RoundedRectangle(cornerRadius:24).fill(Color(hex:0x0C0C0C)).overlay(RoundedRectangle(cornerRadius:24).stroke(.white.opacity(0.25)))` |
| 16-5 | 제목 | "여행을 그만둘까요?" **22pt bold** 흰색, 왼쪽 정렬, 카드 안 (25,26) | 17pt semibold 정도, 왼쪽 정렬 | `.font(.system(size:22, weight:.bold))`, `.padding(.top,26).padding(.horizontal,25)` |
| 16-6 | 본문 | 13pt regular `#AAAAAA`, **두 줄로 나눔**: "지금 도달한 정류장에서 다음 여행을 시작할 수 있어요." / "완료 기록은 남기지 않습니다." 줄 간격 22pt(382→404). 제목 아래 20pt | 15pt 정도 회색, 자동 줄바꿈("시작할 / 수 있어요.") | JourneyLifecycleText.swift:21의 문장 사이 공백을 `\n`으로 바꾼다(낭독은 같다). `.font(.system(size:13)).foregroundStyle(Color(hex:0xAAAAAA)).lineSpacing(9)`, `.padding(.top,20)` |
| 16-7 | 버튼 배치 | **세로**로 쌓고, 계속 여행이 위, 그만두기가 아래, 간격 13pt. 본문 아래 19pt, 카드 아래 여백 25pt | 가로 나란히(계속 여행 왼쪽, 그만두기 오른쪽) | `VStack(spacing:13)`, 버튼 폭 307(카드 안 좌우 25.5), 높이 43 |
| 16-8 | "계속 여행" 버튼 | 흰색(`#FFFFFF`) 채움 캡슐, 테두리 `#444444`, 글자 15pt **regular 검정** | 회색 유리 캡슐, 흰 글자 semibold | `Text(JourneyLifecycleText.continueTrip).font(.system(size:15)).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:43).background(.white,in:Capsule()).overlay(Capsule().stroke(Color(hex:0x444444)))` |
| 16-9 | "그만두기" 버튼 | `#111111` 채움 캡슐, 테두리 `#444444`, 글자 15pt regular **흰색** | 회색 유리, 글자 **빨강**(destructive) | `.background(Color(hex:0x111111),in:Capsule())`, 글자 흰색. 빨강을 쓰지 않는다. 낭독은 role 없이 라벨로만 구분한다. |
| 16-10 | 기본 버튼 강조 테두리 | "계속 여행" 바깥 3pt 위치에 금색 `#D7B378` 2pt 캡슐(318x54 @ (42,430)) | 없음 | 기본 선택(취소) 강조로 보인다. 열릴 때 기본 포커스를 계속 여행에 두고, 같은 캡슐을 `.padding(-5.5)` 바깥에 `stroke(Color(hex:0xD7B378), lineWidth:2)`로 그린다. 하드웨어 키보드 포커스에만 보이게 할지, 늘 보이게 할지 결정이 필요하다(시안은 늘 보인다). |
| 16-11 | 뒤 화면 | R15 상태(X 버튼, 현재 정류장으로, 흐린 지도) | R15 앱 상태(포기하기 캡슐, 흐리지 않은 지도) | R15 수정으로 해결된다 |
| 16-12 | 시안 내부 불일치(참고) | 이 프레임의 하단 지표는 라벨 10pt `#B5B5BA`, 숫자 28pt, 정류장 숫자 19pt `#DDDDDD`, km 13pt `#AAAAAA`로 R13/R15(12/30/15)와 다르다 | — | 같은 화면이므로 R13/R15 값(12/30/15)을 기준으로 한다. 디자이너에게 알려 줄 사항이다. 수정 대상이 아니다. |

차이 개수 **12개**(16-1~16-11, 16-12는 참고).

---

## R22-sound-recover (여행 중 소리 재생 실패) — 앱에 없음, 새로 만들 것

시안 `pen/R22-sound-recover.png`, 덤프 `spec/R22-sound-recover.txt`. 실행 중인 R13 화면 하단, 지표 위에 실패 안내와 버튼 2개가 붙는다.

### 전제: 여행 중 소리 재생 자체가 없다
조사해 보니 `JourneySound`는 준비 화면 미리 듣기(`SoundPreviewController`, `AVSoundPreviewPlayer`)에서만 재생된다. 여행 화면(JourneyView/JourneyTimerController/JourneyServices)에는 선택한 소리를 트는 코드가 없다. 그래서 R22를 만들려면 먼저 아래 1~3이 필요하다.

1. **[기능] 여행 소리 재생기**: `JourneySoundController`(@Observable)를 새로 만든다. `journey.sound`가 "소리 없음"이 아니면 실행 상태에서 반복 재생하고, 일시정지·도착·백그라운드에서는 멈춘다. `AVSoundPreviewPlayer.make(sound:)`를 재사용하고 `numberOfLoops = -1`로 둔다. AVAudioSession `.playback`/`.mixWithOthers` 정책을 정해야 한다. `JourneyServices`에 팩토리를 주입해 테스트에서 실패를 흉내 낼 수 있게 한다(`--fm-ui-journey-sound fail`).
2. **[기능] 실패 상태**: `play()`가 false이거나 만들다 오류가 나면 `showsFailure = true`. 타이머는 계속 흐른다(문구 그대로 "여행은 계속됩니다").
3. **[기능] 버튼 동작**: "다시 재생"은 재생을 다시 시도하고, 성공하면 안내를 숨긴다. "소리 없이 계속"은 이번 여행에서 소리를 끄고 안내를 숨긴다(저장 여부는 결정 필요. 기록의 sound 값은 바꾸지 않는 것을 권장). 낭독 공지 "소리를 재생하지 못했어요. 여행은 계속됩니다."를 띄우고, 포커스를 "다시 재생"에 둔다.

### 화면 규격 (JourneyTimerView.mapBody 하단 VStack, bottomInfo 바로 위)
| 요소 | 값 |
|---|---|
| 안내 문구 | "소리를 재생하지 못했어요. 여행은 계속됩니다." 12pt regular `#B5B5BA`, 왼쪽 정렬, (16,701) |
| 버튼 줄 | 문구 아래 14pt(y=727), `HStack(spacing:9)`, 왼쪽 x=17 |
| "다시 재생" | 73x43 캡슐, 채움 `#111111`, 테두리 `#444444` 1pt, 글자 12pt regular 흰색, 좌우 여백 13 |
| "소리 없이 계속" | 99x43 캡슐, 같은 스타일, 좌우 여백 13 |
| 지표와의 간격 | 버튼 아래(770) → 지표 라벨(R13 기준 772). 사실상 붙어 있으므로 bottomInfo의 위 여백(14)을 빼고 8pt 정도 띄운다. |
| 식별자 | `journey.sound.failure`, `journey.sound.retry`, `journey.sound.mute` |
| 나머지 | 지도·버튼은 R13과 같다(13-1~13-15). 경로 모양은 [데이터]. |

참고: R22 프레임의 하단 지표도 R16처럼 작은 버전(라벨 10pt, 숫자 28pt, 정류장 19pt)이다. 시안 내부 불일치이므로 R13 값을 따른다.
새로 만들 항목: 재생기, 실패 상태, 다시 재생, 소리 없이 계속, 안내 UI, 낭독·포커스, 테스트 훅. 모두 **7건**이다.

---

## 요약 표

| 화면 | 차이(또는 새로 만들 항목) 수 | [기능] 포함 |
|---|---|---|
| R27-board-tag | 20 | 뒤로 버튼 숨김, 태그 영역 크기(판정·테스트), 카드 번호(BR-4) |
| R12-boarding-done | 12 | 인식 시 카드 축소·중앙 정렬 |
| R42-board-custom | 7 | 저장 알림 띠 자동 닫기, 번호 띠 |
| R13-focus-map | 14 | 경로 2색 분리, 노선 전체선, 노선 버튼 |
| R14-next-stop | 새로 만들 것 8건 | 패널 전체 |
| R15-paused | 13 | X로 포기 이동, 현재 정류장으로(의미 확인) |
| R16-end-confirm | 12 | 시스템 alert → 사용자 정의 모달 |
| R22-sound-recover | 새로 만들 것 7건 | 여행 중 소리 재생부터 없음 |

## 결정이 필요한 항목
1. 승차 화면 뒤로 버튼을 숨길지(AC-14와 충돌)
2. 카드 번호 노출(BR-4 정책 변경)
3. 카드 점지도를 없앨지, 카드 비율(1.59 → 1.71)을 바꿀지(공통 PassFace 영향)
4. LCD "20:00"이 현재 시각인지 도착 예정 시각인지
5. "현재 정류장으로" 버튼의 의미
6. "예시 여정 · 실제로 저장하지 않아요." 문구를 넣을지(예시 모드가 앱에 없음)
7. 확인 모달의 금색 포커스 테두리를 늘 보일지
8. R16·R22 프레임의 작은 하단 지표(시안 내부 불일치)
