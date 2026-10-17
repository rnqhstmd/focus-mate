# F — 카드 발급·마이페이지·카드 꾸미기 (R35~R41) 시안 대비 차이

기준: 시안 = `pen/*.png`·`spec/*.txt`(402x874pt), 앱 = `app/*.png`(3x, 402x874pt 환산).
경로 생략 시 `ios/FocusMate/` 기준. 줄번호는 next-step-w19 현재 소스.
`[기능]` = 동작·구조 변경이 필요한 항목. `[데이터]` = 예시 값 차이(수정 대상 아님).

---

## 0. 공통 (여러 화면에 동시에 걸리는 항목 — 한 번 고치면 여러 화면이 같이 맞춰짐)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| C1 | 카드 앞면 도트 지도(서울 점 모양) | R36·R37·R38·R39 카드 모두 **없음** | `PassFace`가 표준 카드에 `PassDots` 표시(발급 0.85, 마이페이지·꾸미기 0.25) | 호출하는 쪽에서 끈다: `CardIssuanceView.swift:88` `PassFace(dotsOpacity: 0)`, `ProfileView.swift:63` `dotsOpacity: 0`, `CardCustomizationView.swift:252` `dotsOpacity: 0`. (`CardTagScreen.swift:172`은 이 담당 범위 밖이라 그대로 둠) |
| C2 | 카드 번호 표시 `FM · 0842 3017` | 모든 카드 왼쪽 아래에 있음. 352 기준 (20,198), 7pt Regular, #F1F2F3 | **없음** | [기능] `PassFace`에 `var cardNumber: String?` 추가 → `Text(cardNumber).font(FontCatalog.text(7 * s)).offset(x: 20 * s, y: 198 * s)`. 표시 형식은 `CardSnapshot.id`(`FM-08423017`) → `"FM · 0842 3017"`(앞 4자리·뒤 4자리를 띄어씀). 호출하는 쪽(발급·마이페이지·꾸미기)에 현재 카드 id 전달. 숫자 값은 [데이터] |
| C3 | 카드 앞면 글자 크기(352 기준) | `Focus Mate` 10pt Bold (20,17) / `집중동행카드` **18pt** Bold (84,89) / 부제 9pt (84,137) | 11pt (20,17.2) / **20pt** (84.47,89.16) / 9pt | `PassFace.swift:33` `11 * s` → `10 * s`, `:35` `20 * s` → `18 * s`. 위치는 그대로 |
| C4 | 카드 앞면 글자색 | #F1F2F3 | `.white`(#FFFFFF) (`PassFace.swift:54`) | `.foregroundStyle(Color(red: 0xF1/255, green: 0xF2/255, blue: 0xF3/255))` |
| C5 | 비접촉 아이콘 | 12x19pt, (319,15), 선 #D5DED7 (사진 카드는 #FFFFFF) | `wave.3.right` 18x22pt (319,14.65), 흰색 | `PassFace.swift:50-52` 프레임 `width: 12 * s, height: 19 * s`, `offset(x: 320 * s, y: 15 * s)`, 표준 카드는 `.foregroundStyle(#D5DED7)`, 사진 카드는 흰색 유지 |
| C6 | 카드 테두리 | 1pt #51565A (마이페이지·발급) / #555C61 (꾸미기) | `Color.white.opacity(0.08)`(≈#232527, 거의 안 보임) (`PassFace.swift:56`) | `shape.stroke(Color(red: 0x51/255, green: 0x56/255, blue: 0x5A/255), lineWidth: 1)` — 꾸미기 화면은 #555C61이지만 차이가 미미하므로 #51565A 하나로 통일하는 걸 권장 |
| C7 | 사진 카드에서 `Focus Mate`·번호 표시 | 사진/색 카드에도 **유지**: 어두운 알약 배경 #080B0C 80%(`#080B0CCC`), `Focus Mate` 알약 70x16 (20,17), 글자 #D3D6D8 10pt Bold (25,19) / 번호 알약 65x12 (20,194), 글자 #D3D6D8 7pt (25,196). 모서리 약 3pt | `style.isStandard`일 때만 그려서 사진 카드에는 **글자 없음** (`PassFace.swift:27-39`) | `Focus Mate`·번호를 `if style.isStandard` 밖으로 꺼내 사진 **위**(ForEach 뒤, chip 앞)에 그린다. 표준이 아니면 `.padding(.horizontal, 5*s).padding(.vertical, 3*s).background(Color(red: 8/255, green: 11/255, blue: 12/255).opacity(0.8), in: RoundedRectangle(cornerRadius: 3*s))`, 글자색 #D3D6D8. `집중동행카드`·부제는 시안대로 사진 카드에서는 숨김 유지 |
| C8 | 주 버튼 스타일 (`FMPrimaryButtonStyle`) | 흰색 #FFFFFF, 1pt 테두리 #444444, 완전한 캡슐, 349x53, 글자 **16pt Regular** #000000 / 비활성: 배경 #252525, 테두리 #444444, 글자 #888888 | #F4F6F2 배경, 모서리 24, 높이 52, **17pt Bold**, 비활성은 같은 색 55% + 검정 70% 글자 | `FMDesign.swift:15-20`: font `FontCatalog.text(16, relativeTo: .headline)`, `minHeight: 53`, 배경 `isEnabled ? .white : Color(red: 0x25/255, green: 0x25/255, blue: 0x25/255)`, 모양 `Capsule()`, `.overlay(Capsule().stroke(Color(red: 0x44/255, green: 0x44/255, blue: 0x44/255), lineWidth: 1))`, 글자 `isEnabled ? .black : Color(red: 0x88/255, green: 0x88/255, blue: 0x88/255)`. ※다른 화면 담당과 공유하는 스타일이므로 다른 담당의 시안 확인 후 적용 |
| C9 | 화면 배경색 | 발급 #101112 (동일) / 마이페이지·꾸미기 **#0D0F10** | `FMDesign.background` #0F1012 | `ProfileView.swift:42`, `CardCustomizationView.swift:22`를 `Color(red: 0x0D/255, green: 0x0F/255, blue: 0x10/255)`로 |
| C10 | 글꼴 종류 (참고) | Noto Sans KR | SeoulAlrim(`FontCatalog`) + 일부 시스템 글꼴 | 의도된 브랜드 글꼴로 보고 이번 비교에서 차이로 세지 않음. 단 발급 화면에서 **시스템 글꼴**을 쓰는 곳(아래 R35-1·R35-4·R35-9)은 FontCatalog로 통일 |

---

## R35-issue (첫 카드 발급) — 차이 13건

파일: `CardIssuanceView.swift`, 감싸는 쪽 여백 `RootView.swift:154-160`(`.padding(24)`).

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | `Focus Mate` 글자 | 16pt **Bold**, 위쪽 y=66, x=28 | 시스템 `.subheadline` semibold(약 15pt), 위쪽 y≈99, x=24 | `:32` → `.font(FontCatalog.text(16, bold: true))` |
| 2 | 상단 위치 전체가 아래로 밀림 | Focus Mate 위쪽 66pt(상태바 영역 바로 아래 약 4pt) | 약 33pt 더 아래 (안전영역 + RootView 24 + `.padding(.top, 12)`) | `RootView.swift:159` `.padding(24)`를 `.padding(.horizontal, 24).padding(.top, model.presentedRoute == .cardEntry ? 4 : 24).padding(.bottom, model.presentedRoute == .cardEntry ? 0 : 24)`로 나누고, `CardIssuanceView.swift:33` `.padding(.top, 12)` → `0` |
| 3 | 가로 여백 | 글자 x=28, 버튼 x=27~376 | 글자·버튼 x=24~378 | 본문 VStack(`:30`)에 `.padding(.horizontal, 4)`, 하단 inset VStack(`:53`)에 `.padding(.horizontal, 3)` |
| 4 | Focus Mate→제목 간격 | 제목 위쪽 142 (Focus Mate 아래쪽 82에서 60) | `.padding(.bottom, 46)` | `:33` `.padding(.bottom, 60)` |
| 5 | 제목 줄간격 | 28pt, 줄 시작 간격 39pt (142→181) | `lineSpacing(5)`, 실제 약 36pt | `:36` `.lineSpacing(8)` |
| 6 | 제목→본문 간격 | 제목 아래쪽 209 → 본문 위쪽 240 (31pt) | `.padding(.top, 18)` (실측 약 8pt 좁음) | `:44` `.padding(.top, 26)` |
| 7 | 본문 글자 | 14pt Regular #C1CDC4, 줄 시작 간격 24pt | 시스템 `.subheadline`(15pt), lineSpacing 5 (약 22pt) | `:41` `.font(FontCatalog.text(14, relativeTo: .subheadline)).lineSpacing(7)`, 색 `:42` → `Color(red: 0xC1/255, green: 0xCD/255, blue: 0xC4/255)` |
| 8 | 카드 슬롯(꽂는 곳) 막대 | 213x6, (95,354), 채움 #040805, 테두리 #566359 | 214x7, 채움 검정, 테두리 #57635A, y≈379 | `:84` `.frame(width: 213, height: 6)`, `:82` `.fill(Color(red: 4/255, green: 8/255, blue: 5/255))` |
| 9 | 슬롯·카드 세로 위치 | 본문 아래쪽 278 → 슬롯 354 (76pt 고정), 슬롯→카드 391 (31pt) | `Spacer(minLength: 30)` 두 개로 가운데 정렬 → 슬롯 379, 카드 407~591 (약 16~25pt 아래) | `:45` `Spacer(minLength: 30)` → 고정 `Color.clear.frame(height: 76)`(또는 `.padding(.top, 76)`), `:47` Spacer는 그대로. `:80` `VStack(spacing: 24)` → `spacing: 0` 후 ZStack에 `.padding(.top, 31)` |
| 10 | 빈 카드 아이콘 | `plus.rectangle` 모양(둥근 사각 26x18 안 +), 선 #A6B7AA | `creditcard` 31pt light | `:97` `Image(systemName: "plus.rectangle").font(.system(size: 22, weight: .regular))` |
| 11 | 빈 카드 안내문 글꼴 | 13pt Regular #A6B7AA | 시스템 `.footnote` 13pt (색 동일) | `:98` `.font(FontCatalog.text(13, relativeTo: .footnote))`. 아이콘→글자 간격 시안 23pt(아이콘 아래쪽 477 → 글자 500) → `:96` `spacing: 23` |
| 12 | 하단 안내문 | 12pt Regular #AAB9AE, y=743 | 시스템 `.footnote`(13pt), y≈701 | `:61` `.font(FontCatalog.text(12, relativeTo: .footnote))`, 안내문→버튼 간격 27pt: `:53` `VStack(spacing: 27)` |
| 13 | 하단 버튼 위치·모양 | 349x53, y=782~835(버튼 아래쪽이 홈 인디케이터 영역 바로 위 약 5pt), 흰색+#444 테두리, 16pt Regular | 354x52, y≈728~780 (**약 54pt 높음**), #F4F6F2, 17pt Bold | 위치: `:64` `.padding(.bottom, 12)` → `5` + 항목 2의 RootView 하단 패딩 0. 모양: 공통 C8 |

---

## R36-issuing (카드 발급 중) — 차이 11건 (R35의 1~9·12 위치/글꼴 항목은 동일하게 적용, 여기선 R36에만 있는 것)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 슬롯 막대 불 켜짐 | 발급 중에는 채움 **#819B88**, 테두리 **#A6C8B0** (초록빛 켜짐) | 상태와 무관하게 검정 | `:82-83` `.fill(controller.phase == .issuing ? Color(red: 0x81/255, green: 0x9B/255, blue: 0x88/255) : Color(red: 4/255, green: 8/255, blue: 5/255))`, 테두리 `controller.phase == .issuing ? #A6C8B0 : #566359` |
| 2 | 카드 도트 지도 | 없음 | 0.85 불투명도로 표시, 제목과 겹쳐 `집중동행카드` 끝 글자 위에 점이 얹힘 | 공통 C1 |
| 3 | 카드 제목 크기 (발급 화면 전용) | 292폭 카드에서 `집중동행카드` **23pt** Bold (71,76) | 20×(292/352)=약 16.6pt | [기능] 시안이 발급 화면에서만 글자를 축소하지 않고 고정 크기로 둠(Focus Mate 10, 제목 23, 부제 10, 번호 8pt — 352 기준 18/9/7과 비례가 안 맞음). `PassFace`에 `var fixedTypography: Bool = false` 같은 옵션을 넣어 발급 화면에서는 `Focus Mate 10pt (21,18) / 제목 23pt (71,76) / 부제 10pt (71,114) / 번호 8pt (21,157)`의 절대값을 쓰게 하거나, 시안 쪽을 R38 비율로 고칠지 결정 필요 |
| 4 | 카드 부제 크기 | 10pt (71,114) | 9×0.83=약 7.5pt | 3번과 함께 |
| 5 | Focus Mate(카드 안) | 10pt Bold (21,18) | 11×0.83=약 9.1pt (16.6,14.3) | 3번과 함께 |
| 6 | 카드 번호 | `FM · 0842 3017` 8pt (21,157) | 없음 | 공통 C2 (값은 [데이터]) |
| 7 | 비접촉 아이콘 | 12x19 (258,15) #D5DED7 | 약 15x18 흰색 | 공통 C5 |
| 8 | 카드 테두리·글자색 | #51565A / #F1F2F3 | 흰 8% / 흰색 | 공통 C4·C6 |
| 9 | 비활성 버튼 | 배경 #252525, 테두리 #444444, 글자 #888888 **16pt Regular** | #F4F6F2 55%(밝은 회색), 검정 70% **17pt Bold** — 시안과 명암이 반대 | 공통 C8 비활성 분기 |
| 10 | 하단 안내문 | 12pt, x=77~318 (가운데) | 13pt | R35-12와 같은 수정 |
| 11 | 카드 세로 위치 | 391~575 | 407~591 (16pt 아래) | R35-9 |

문구: 제목·본문·안내문·버튼 문구 모두 시안과 동일.

---

## R37-issued (카드 발급 완료) — 차이 10건 (R36의 카드 앞면 2~8, 위치 항목 공통)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | `발급 완료` 아이콘 | 그냥 체크 표시(11x8, 선 #B4D4BB) | `checkmark.circle` (원 안 체크) | `:107` `Label` → `HStack(spacing: 10) { Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold)); Text("발급 완료").font(FontCatalog.text(13, relativeTo: .footnote)) }` 색은 그대로(#B5D4BA ≈ #B4D4BB) |
| 2 | 카드→`발급 완료` 간격 | 카드 아래쪽 575 → 595 (20pt) | VStack spacing 24 + 글줄 여유 (실측 약 27pt, y≈602) | `:106` 블록에 `.padding(.top, 20)` (항목 R35-9에서 VStack spacing 0으로 바꾼 뒤) |
| 3 | `발급 완료` 글꼴 | 13pt Regular (Noto) | 시스템 `.footnote` | 1번과 함께 FontCatalog 13 |
| 4 | 카드 도트 지도 | 없음 | 있음 | 공통 C1 |
| 5 | 카드 제목 23pt·부제 10pt·Focus Mate 10pt | — | 축소된 크기 | R36-3 |
| 6 | 카드 번호 | 있음 | 없음 | 공통 C2 |
| 7 | 슬롯 막대 | 완료 후 다시 어두운 색(#040805/#566359) | 검정/#57635A, 214x7, y≈360 | R35-8 |
| 8 | 버튼 | 흰색+#444 테두리 캡슐, `출발지 선택하기` 16pt Regular | #F4F6F2, 17pt Bold, 모서리 24 | 공통 C8 |
| 9 | 버튼 위치 | 782~835 | 728~780 | R35-13 |
| 10 | 상단 Focus Mate·제목 위치 | Focus Mate y=66, 제목 y=142 | 약 30pt 아래 | R35-1·2·4 |

문구: 모두 동일.

---

## R38-profile (마이페이지) — 차이 17건

파일: `ProfileView.swift`.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 뒤로 버튼 | 원 없이 **꺾쇠만** 7x14 #F4F4F4, x=35, y=79 | iOS 26 시스템 뒤로 버튼(유리 원 44pt, x 16~60) | [기능] `.navigationBarBackButtonHidden(true)` + `ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 17, weight: .medium)).foregroundStyle(Color(red: 0xF4/255, green: 0xF4/255, blue: 0xF4/255)).frame(width: 44, height: 44) } }.sharedBackgroundVisibility(.hidden)` (`:90-96` titleItem과 같은 방식). 시스템 버튼을 숨기면 가장자리 밀어서 뒤로가기가 꺼지므로 다시 켜는 처리 필요 → 동작 영향 있음 |
| 2 | 제목 `마이페이지` 위치 | x=74, 위쪽 75 (20pt Bold) | x≈76, 가운데 y≈83 | 1번 적용 후 꺾쇠 버튼 44pt + 간격으로 x=74 맞춤. 크기·굵기는 동일 |
| 3 | 화면 배경 | #0D0F10 | #0F1012 | 공통 C9 |
| 4 | 카드 위쪽 위치 | 233 | 약 229 | `:64` `.padding(.top, 32)` → `36` |
| 5 | 카드 도트 지도 | 없음 | 0.25로 흐리게 있음 | 공통 C1 (`:63` `dotsOpacity: 0`) |
| 6 | 카드 번호 | `FM · 0842 3017` 7pt (21,199) | 없음 | 공통 C2 (값 [데이터]) |
| 7 | 카드 안 글자 크기 | Focus Mate 10 / 제목 18 / 부제 9 | 11 / 20 / 9 | 공통 C3 |
| 8 | 카드 테두리·글자색·아이콘 | #51565A / #F1F2F3 / 12x19 #D5DED7 | 흰 8% / 흰색 / 18x22 흰색 | 공통 C4·C5·C6 |
| 9 | 카드 문구 `모든 몰입 여정에 함께` | **12pt** #AFB7BD, 이름 아래쪽 489 → 496 (7pt) | 13pt #BFC6C1, `.padding(.top, 4)` | `:67` `FontCatalog.text(12, ...)`, 색 `Color(red: 0xAF/255, green: 0xB7/255, blue: 0xBD/255)`, `:68` `.padding(.top, 7)` |
| 10 | 구분선 | 1pt **#2C3134**, 카드 문구 아래쪽에서 30pt | 시스템 `Divider()`(색 다름), `.padding(.top, 28)` | `:69`, `:73` `Divider()` → `Rectangle().fill(Color(red: 0x2C/255, green: 0x31/255, blue: 0x34/255)).frame(height: 1)`; `:69` 간격 `30` |
| 11 | `카드 꾸미기` 아이콘 | 테두리만 있는 연필(지우개 끝 있는 외곽선 연필, 14x14, 선 #F3F3F3) | SF `pencil`(가는 사선 한 줄처럼 보임) | `:70` 시안과 같은 외곽선 연필이 SF Symbols에 정확히 없으므로 14x14 `Path` 에셋(선 1.5pt)으로 추가하거나, 가장 가까운 SF 기호로 `pencil` + `.font(.system(size: 15, weight: .regular))`. 아이콘 중심 x=35 유지 |
| 12 | 메뉴 글자 시작 위치 | 아이콘 중심 35 → 글자 x=**57** | x≈64 (`HStack(spacing: 16)`) | `:139` `HStack(spacing: 9)` (아이콘 프레임 24 유지) |
| 13 | 메뉴 꺾쇠 | 6x12, **#9DA5AB**, 오른쪽 끝 x=371 | 기본 크기(약 9x16) #BFC6C1, 오른쪽 끝 ≈376 | `:143` `.font(.system(size: 13, weight: .medium)).foregroundStyle(Color(red: 0x9D/255, green: 0xA5/255, blue: 0xAB/255))` + HStack에 `.padding(.trailing, 6)` |
| 14 | 통계 라벨 | **12pt** #AEB5BB, 숫자 아래쪽 659 → 라벨 669 (10pt) | 13pt #BFC6C1, spacing 8 | `:165` `FontCatalog.text(12, ...)`, 색 `Color(red: 0xAE/255, green: 0xB5/255, blue: 0xBB/255)`, `:162` `spacing: 10` |
| 15 | 통계 오른쪽 칸 x | 213 | 209 (HStack spacing 16) | `:114` `HStackLayout(alignment: .top, spacing: 24)` (각 칸 165pt → 오른쪽 칸 x=213) |
| 16 | 부제 `한 장으로 함께하는 나만의 여정` 색 | #AEB5BB | #BFC6C1 | `:61` 색 #AEB5BB |
| 17 | `데이터 출처` 메뉴 | **없음** (설정 행이 마지막) | `info.circle` + `데이터 출처` 행 있음 (`:76-77`) | [기능] 시안대로면 이 행을 마이페이지에서 빼고 `설정` 안쪽으로 옮겨야 함. 출처 표시 의무(공공데이터) 여부 확인 후 결정 |

[데이터] 통계 `0`, `0 min` 동일 — 차이 없음.

---

## R39-studio (카드 꾸미기 · 처음) — 차이 16건

파일: `CardCustomizationView.swift`.

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 제목 `카드 꾸미기` x | 74 | ≈81 (`HStack(spacing: 14)`) | `:126` `HStack(spacing: 8)` |
| 2 | 뒤로 꺾쇠 크기 | 7x14 #F4F4F4 (원 52pt, 흰 테두리) | `chevron.left` 22pt(약 11x18) | `:130` `.font(.system(size: 16, weight: .regular))`. 원 52pt·흰 테두리는 동일 |
| 3 | 되돌리기 아이콘 위치·색 | 15x16, 중심 x≈361, 비활성 색 **#54595D** | 중심 x≈366, 밝은 회색(시스템 비활성) | `:137` `.padding(.trailing, 14)` → `18`; `:135` 이미지에 `.foregroundStyle(controller.canUndo && !locked ? Color(red: 0xF3/255, green: 0xF3/255, blue: 0xF3/255) : Color(red: 0x54/255, green: 0x59/255, blue: 0x5D/255))` |
| 4 | 배경 | #0D0F10 | #0F1012 | 공통 C9 |
| 5 | 미리보기 카드 도트 지도 | 없음 | 0.25 | 공통 C1 (`:252`) |
| 6 | 카드 번호·글자 크기·테두리·아이콘 | 번호 있음, 18pt 제목, 테두리 #555C61 | 번호 없음, 20pt, 흰 8% | 공통 C2~C6 |
| 7 | 안내 2줄 색 | #B8BFC5 12pt, 줄 시작 간격 20 | #BFC6C1 | `:44` 색 `Color(red: 0xB8/255, green: 0xBF/255, blue: 0xC5/255)` |
| 8 | 색 동그라미 줄 x | 첫 동그라미 x=25(중심 44.5), 39pt + 간격 9 | 48pt 프레임 안 중앙(첫 중심 48, 3.5pt 오른쪽) | `:143` `HStack(spacing: 9)`, `:147-151` 동그라미 프레임 39x39로 두고 선택 링은 `.overlay { Circle().stroke(Color(red: 0xF4/255, green: 0xF4/255, blue: 0xF4/255), lineWidth: 2).frame(width: 48, height: 48) }`(레이아웃에 영향 없음), HStack에 `.padding(.leading, 1)` |
| 9 | 동그라미 테두리 | 1pt **#737A80** | secondary 60% | `:148` `Color(red: 0x73/255, green: 0x7A/255, blue: 0x80/255)` |
| 10 | 선택 체크 | 10x7 가는 체크, 기본 검정 위 #F1F2F3 / 밝은 색 위 #121416 | 시스템 기본 크기(약 17pt) 체크, 흰/검정 | `:149` `.font(.system(size: 12, weight: .semibold))`, 색 `#F1F2F3` / `#121416` |
| 11 | `배경색`→동그라미 간격 | 동그라미 중심 489.5 | ≈485.5 (4pt 위) | `:141` `VStack(spacing: 12)` (8 → 12) |
| 12 | `직접 고르기` 견본 | **사각 견본** 38x32: 바탕 #111111 + 흰 15% 덧칠, 안에 28x18 사각(현재 배경색 채움, 1pt #777777 테두리), x=96 | 시스템 `ColorPicker`의 무지개 원(중심 x≈120) | `:157-163` ColorPicker를 `.labelsHidden()`으로 두고 그 아래 `ZStack`에 시안 견본(`RoundedRectangle(cornerRadius: 0).fill(#111111).overlay(Color.white.opacity(0.15))` 38x32 + 안쪽 28x18 `Rectangle().fill(현재색).overlay(Rectangle().stroke(#777777))`)을 그리고, ColorPicker를 같은 크기로 위에 겹쳐 `.opacity(0.02)`로 눌림만 받게 함. 라벨 `Text("직접 고르기")` 12pt #BDC5CB, 라벨→견본 x 간격: 라벨 끝 82 → 견본 96 (14pt) |
| 13 | `사진` 줄 위치 | `사진` 머리글 가운데 y≈610, `사진 추가` 버튼 590~633 | 머리글 ≈593, 버튼 ≈572~614 (약 17pt 위) | `:47` `photos.padding(.top, 10)` → `28` |
| 14 | `사진 추가` 버튼 | 93x43, 바탕 #181D20, 테두리 **#555E65**, 글자 12pt #F3F3F3 | 97x43, 테두리 secondary 50% | `:175` `.padding(.horizontal, 12)`, `:177` 테두리 `Color(red: 0x55/255, green: 0x5E/255, blue: 0x65/255)`, 글자색 `#F3F3F3` 명시 |
| 15 | 아래쪽 문구 간격 | 버튼 아래쪽 633 → `좋아하는 풍경…` 658 (25pt) → `사진은 이 기기에만…` 693 (줄 시작 간격 35) → `기본 검정 카드로 되돌리기` 749 | 각각 약 25·27·34pt 위 | `:168` `VStack(spacing: 25)`, `:59` `.padding(.top, 21)`, `:64` `.padding(.top, 28)` |
| 16 | 문구 색·밑줄 | `좋아하는 풍경…` #AEB5BB 12pt / `사진은…` #B0BAC2 11pt / `기본 검정 카드로 되돌리기` #B4BEC6 12pt, 밑줄은 글자 아래 3pt, 1pt, 133pt 폭 | 셋 다 #BFC6C1, 기본 밑줄 | 각각 `:181` #AEB5BB, `:59` #B0BAC2, `:63` #B4BEC6; `:61` `.underline()` → `.overlay(alignment: .bottom) { Rectangle().fill(#B4BEC6).frame(height: 1).offset(y: 3) }` |
| 17 | 저장 버튼 | 353x51, 흰색, **1pt #444444 테두리**, 15pt Regular | 흰 캡슐, 테두리 없음, 높이 약 48 | `:80` `.padding(.vertical, 17.5)` (또는 `.frame(height: 51)`), `:81` 뒤에 `.overlay(Capsule().stroke(Color(red: 0x44/255, green: 0x44/255, blue: 0x44/255), lineWidth: 1))`. 버튼 아래쪽 840 (앱 836, 4pt) → `:83` `.padding(.bottom, 3)` → `0` |

(번호 17까지지만 6번이 공통 묶음이라 화면 고유 차이는 16건으로 셈)

---

## R40-studio-photos (카드 꾸미기 · 사진 배치) — 차이 14건 (R39 1~4·7~9·11~14·17은 그대로 적용, 여기선 추가분)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 사진 카드 위 `Focus Mate` 알약 | 있음 (#080B0C 80% 알약, #D3D6D8 글자) | **없음** | 공통 C7 |
| 2 | 사진 카드 위 번호 알약 | 있음 (20,194) 65x12 | 없음 | 공통 C2+C7 |
| 3 | 카드 테두리 | 1pt #555C61 (모래색 위에서도 보임) | 없음(흰 8%) | 공통 C6 |
| 4 | 크기 조절 손잡이 | 선택 사진 오른쪽 아래, 카드 오른쪽 끝에 걸쳐 반쯤 잘린 흰 원(28x44 영역, 안에 대각 화살표) | 이번 캡처에선 사진이 카드보다 커서 손잡이가 카드 밖으로 잘려 안 보임 | [데이터] 위치 차이(사진 배치 값이 다름). 모양은 `:257-258` 흰 원 32pt + 12pt 아이콘으로 시안과 같음. 손잡이를 항상 카드 안에 보이게 하려면 [기능] `rect.maxX/maxY`를 카드 크기로 `min` 처리해 위치를 고정 |
| 5 | 사진 썸네일 크기 | **53x53**, 테두리 1pt #5C6267 | 58x58, 테두리 없음(선택만 흰색) | `:188-190` `.frame(width: 53, height: 53)`, 선택 안 된 것도 `.stroke(Color(red: 0x5C/255, green: 0x62/255, blue: 0x67/255), lineWidth: 1)` |
| 6 | 선택 썸네일 링 | 썸네일 바깥 3.5pt에 60x60 흰 링(2pt), 모서리 약 10 | 썸네일 경계에 바로 붙은 흰 2pt 선 | `:190` 선택 시 `.overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 2).frame(width: 60, height: 60))`; `:197` `.padding(3)` → `.padding(4)` (링이 잘리지 않게) |
| 7 | 썸네일 간격·x | 첫 x=29, 둘째 x=93 (간격 11) | 첫 x≈27, 간격 10 | `:184` `HStack(spacing: 11)` |
| 8 | 썸네일 줄 y | 650~703 | ≈636~694 (14pt 위) | R39-13·15 간격 수정으로 대부분 해결 |
| 9 | `사진 크기` 라벨 | **12pt** #CCCCCC | 15pt 기본색 (`:217` `.font(FontCatalog.text(15))`) | `:205` `Text("사진 크기").font(FontCatalog.text(12)).foregroundStyle(Color(red: 0xCC/255, green: 0xCC/255, blue: 0xCC/255))` |
| 10 | 퍼센트 값 | **12pt** #C8CFD4, 오른쪽 끝 x=380, 라벨보다 위(y=725) | 15pt, 라벨과 같은 줄 | `:205` `Text("\(…)%").font(FontCatalog.text(12)).foregroundStyle(Color(red: 0xC8/255, green: 0xCF/255, blue: 0xD4/255))`. 시안에선 % 값이 슬라이더 줄 오른쪽 위에 따로 놓임(라벨 749, % 725) — 시안이 슬라이더를 그리지 않은 것으로 보여 같은 줄 유지 권장 |
| 11 | 슬라이더·가로/세로 위치·앞으로/뒤로/삭제 | 시안엔 **안 보임** (`사진 크기` 바로 아래가 저장 버튼) | 슬라이더(가로 막대 + 흰 손잡이) 보임, 아래로 스크롤하면 위치·순서 조절 | [기능] 시안을 그대로 따르면 정밀 조절 UI가 사라짐(접근성용 대체 조작). 시안 누락으로 보고 **유지 권장**, 디자인 쪽 확인 필요 |
| 12 | `직접 고르기` 견본 | 안쪽 사각이 현재 색(#D9CDB9)으로 채워짐 | 무지개 원 안에 현재 색 | R39-12와 같은 수정 |
| 13 | 되돌리기 아이콘 | 시안은 회색 #54595D(비활성처럼 그려짐) | 변경이 있어 밝은 흰색(활성) | 동작상 앱이 맞음. 색만 R39-3(활성 #F3F3F3)로 |
| 14 | 선택 체크(모래색 위) | 10x7, #121416 | 큰 검정 체크 | R39-10 |

[데이터] 사진 내용(시안: 도시 항공 사진 / 앱: 단색 테스트 사진), 사진 위치·크기, `53%` vs `60%`.

---

## R41-profile-custom (꾸민 카드 · 마이페이지) — 차이 8건 (R38의 1~17은 그대로 적용, 여기선 추가분)

| # | 항목 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 사진 카드 위 `Focus Mate` 알약 | 있음 (21,18) 70x16 #080B0C 80%, 글자 #D3D6D8 10pt Bold (26,20) | 없음 | 공통 C7 |
| 2 | 사진 카드 위 번호 알약 | 있음 (21,195) 65x12, 7pt | 없음 | 공통 C2+C7 |
| 3 | 카드 테두리 | #51565A 1pt | 거의 안 보임 | 공통 C6 |
| 4 | IC칩 | 사진 위에 또렷이 (#C5B998, 테두리 #80775D) | 사진 위에 그려짐(동일) — 색 #C4BA99 / #877F63 | 칩 테두리 색만 `PassFace.swift:73,76,78` `Color(red: 0x80/255, green: 0x77/255, blue: 0x5D/255)`로 (공통, 모든 카드) |
| 5 | 저장 완료 알림 띠 | **없음** | 화면 맨 아래 검정 띠 `카드 외형을 저장했어요.`가 계속 남음 (`RootView.swift:59-67`) | [기능] `savedCardNotice`가 다시 `false`가 되는 곳이 없어 계속 표시됨. 2.5~3초 뒤 자동으로 숨기기(`Task { try? await Task.sleep(for: .seconds(3)); savedCardNotice = false }`)하거나 화면 이동 시 끄기. 시안 기준으로는 띠 없이 VoiceOver 알림(`:76-79`)만 남겨도 됨 |
| 6 | 알림 띠가 가린 `데이터 출처` 행 | 시안엔 행 자체 없음 | 띠에 가려 안 보임 | R38-17 |
| 7 | 비접촉 아이콘(사진 카드) | 12x19, #FFFFFF | 18x22 흰색 | 공통 C5 (크기만) |
| 8 | 카드 배경 사진 | 시안: 도시 항공 사진 2장, 모래색 바탕 #D9CDB9 | 단색 테스트 사진 2장, 모래색 바탕 | [데이터] (차이 아님, 바탕색은 일치) |

(8번은 데이터라 실제 차이는 7건)

---

## 요약 표

| 화면 | 차이 수(데이터 제외) | 주요 원인 파일 |
|---|---|---|
| R35-issue | 13 | CardIssuanceView, RootView, FMDesign |
| R36-issuing | 11 | CardIssuanceView, PassFace, FMDesign |
| R37-issued | 10 | CardIssuanceView, PassFace |
| R38-profile | 17 | ProfileView, PassFace |
| R39-studio | 16 | CardCustomizationView, PassFace |
| R40-studio-photos | 14 (데이터 1) | CardCustomizationView, PassFace |
| R41-profile-custom | 7 (데이터 1) | PassFace, RootView, ProfileView |

가장 큰 차이 3가지:
1. **카드 앞면(PassFace)** — 시안엔 도트 지도가 없고, 카드 번호 `FM · 0842 3017`가 있으며, 사진 카드에도 `Focus Mate`·번호를 어두운 알약 위에 남긴다. 앱은 도트를 그리고 번호가 없으며 사진 카드에선 글자를 전부 지운다. (7개 화면 전부)
2. **발급 화면 세로 배치·버튼** — 앱은 전체가 약 30pt 아래에서 시작하고, 하단 버튼은 약 54pt 높이 떠 있다. 주 버튼도 시안(흰색+#444 테두리, 16pt Regular, 비활성 #252525/#888)과 다르다(#F4F6F2, 17pt Bold, 비활성은 밝은 회색).
3. **마이페이지 구조** — 시스템 유리 원 뒤로 버튼(시안은 꺾쇠만), 시안에 없는 `데이터 출처` 행, 꾸미기 저장 후 사라지지 않는 `카드 외형을 저장했어요.` 띠. 셋 다 [기능] 변경이 필요하다.
