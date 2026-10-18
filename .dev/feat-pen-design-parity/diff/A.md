# 시안 대조 A — R01·R02·R03·R04·R05·R26·R06

- 기준: 시안 `pen/*.png`(402x874pt, @2x), 수치 `spec/*.txt`, 앱 캡처 `app/*.png`(@3x, 1206x2622)
- 앱 좌표는 캡처 px ÷ 3(=표시본 920px 기준 ÷ 2.288)으로 pt 환산. 시안 좌표는 spec 그대로(pt).
- 소스 경로: `/Users/bonseung/projects/focus-mate/next-step-w19/ios/FocusMate/`
- 태그: **[기능]** = 동작·네비게이션·데이터 흐름 변경이 필요한 항목. 태그 없는 항목은 표현(스타일·문구·배치)만 바꾸면 된다.
- 문구 차이는 고정 문구만 차이로 셌고, 정류장명·노선번호·분·정류장 수 같은 예시 값은 각 화면 끝 "데이터 차이"에 따로 적었다.

---

## 0. 공통(여러 화면에 걸친 차이) — 먼저 토큰으로 정리하면 화면별 수정이 짧아진다

| # | 항목 | 시안 | 앱(현재) | 수정안 |
|---|---|---|---|---|
| C1 | 글꼴 | 전 화면 **Noto Sans KR**, 본문·버튼 400(normal), 제목 700 | `FontCatalog.text` = 서울알림체(SeoulAlrimTTF-Medium/Bold). R03 검색 화면은 아예 **시스템 SF**(`.title2.bold()`, `.subheadline`, `.headline`, `.caption`) | 결정 필요. 시안을 따르려면 `FontCatalog.swift:7,15`에서 등록·이름을 `NotoSansKR-Regular` / `NotoSansKR-Bold`로 교체(OFL 폰트 번들 추가). 서울알림체를 유지하더라도 **R03의 시스템 폰트는 FontCatalog로 통일**해야 함(아래 R03 항목) |
| C2 | 배경 지도 표현 | 위성 사진 같은 **3D 항공 이미지**(나무·건물 텍스처, 도로명·POI 라벨 없음), 위에 **검정 33%(#00000055)** 균일 덮개 | MapKit `.standard(elevation: .realistic)` 다크 벡터 지도: 파란 회색 블록 건물, 도로명 라벨 다수, 녹지 초록 면 | `SceneMapBackdrop.swift:50` → `.mapStyle(.imagery(elevation: .realistic))`(라벨 없음). 카메라 `:36-37` `distance: 1_800, pitch: 50` → 시안처럼 넓게 `distance: 3_000~3_500, pitch: 55`. 덮개는 각 화면에서 `Color.black.opacity(0.33)`을 지도 바로 위에 1겹(아래 화면별 그라데이션 대체) |
| C3 | Apple 지도 로고·Legal | 없음 | 왼쪽 아래 " Maps  Legal" 노출(R01 y≈683pt, R04~R06 y≈290pt) | 제거 불가(MapKit 표기 의무). 위치만 패널 뒤로 숨지 않게 조정하는 현행 `safeAreaPadding` 유지. 시안과의 **허용 차이**로 기록 |
| C4 | 아래 시트(패널) 모양 | x=12, 너비 378(좌우 12pt), **화면 아래에서 20pt 위**(y끝 854, 홈 인디케이터 영역과 겹침), 반경 24, 채움 #0A0A0A, **1pt 테두리 #FFFFFF33(=#3B3B3B)**, 높이는 내용에 맞춤 | `fmPanel` 반경 24·#0A0A0A, **테두리 없음**. 시간 화면은 바닥에서 46pt(12 + 안전영역 34) 위, 최초 검색은 좌우 24pt·바닥 83pt 위 + 높이 고정 68% | `FMDesign.swift:41-43` `fmPanel`에 `.overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(Color.white.opacity(0.2), lineWidth: 1) }` 추가. 화면 쪽에서 `.padding(.horizontal, 12).padding(.bottom, 20).ignoresSafeArea(.container, edges: .bottom)` |
| C5 | 주 버튼(흰 알약) | **#FFFFFF 채움 + 1pt #444444 테두리, 완전 캡슐**(높이 43 → 반경 21.5; 메인은 높이 51). 라벨 **15pt / 400 / #000000**, 아이콘 없음 | `FMPrimaryButtonStyle`(`FMDesign.swift:11-23`): #F4F6F2, 반경 24, 높이 52, 17pt **Bold** | `:15` 폰트 → `FontCatalog.text(15, relativeTo: .body)`(굵기 normal), `:17-18` → `.padding(.vertical, 12).frame(maxWidth: .infinity, minHeight: 43)`, `:20` 배경 → `Color.white, in: Capsule()` + `.overlay(Capsule().strokeBorder(Color(hex: 0x444444), lineWidth: 1))`. 메인 CTA는 `minHeight: 51` 변형 |
| C6 | 비활성 주 버튼 | 채움 **#303A33**(테두리 동색), 라벨 **#C6D0C9 15pt/400**, 캡슐 | 같은 흰 버튼을 55% 불투명 → 회색 #8A8B89, 라벨 검정 70% 17pt Bold | `FMDesign.swift:19-20` 비활성 분기: 배경 `Color(hex: 0x303A33)`, 글자 `Color(hex: 0xC6D0C9)`, 테두리 없음(또는 #303A33) |
| C7 | 보조 글자색 | #B5B5BA(부제·설명), #AAAAAA(라벨·안내), #BFC6C1(면책 문구), #C2CCC5(카드 메타) | `FMDesign.secondaryText` #BFC6C1 하나 | `FMDesign`에 `textMuted = #B5B5BA`, `textHint = #AAAAAA`, `textMeta = #C2CCC5` 추가 |
| C8 | 버스 종류 색 | 간선 **#2563EB**, 지선 **#168445** (마을은 시안에 없음) | 색 구분 없음(`bus.fill` + 글자) | `FMDesign`에 `busColor(kind:)` 추가: "간선" #2563EB, "지선" #168445, 그 외(마을 등)는 서울 마을버스색 #53B332 제안(시안 미정 → 디자이너 확인) |
| C9 | 내비게이션 뒤로 버튼 | push 화면에도 시스템 뒤로 버튼 없음. 시간 화면은 **패널 안 왼쪽 위 `<`**(5x10 선, 흰색) | 시스템 Liquid Glass 원형 뒤로 버튼(44pt, 왼쪽 위 x≈16 y≈62) | [기능] 아래 R04 참조 |
| C10 | 상태바·홈 인디케이터 | 시안은 단순 그림(9:41 12pt, 배터리 "▰", 124x4 바) | iOS 실제 상태바·홈 인디케이터 | 시스템 요소 → 허용 차이(수정 없음) |

---

## R01-main · 지도 메인

시안 `spec/R01-main.txt` / 앱 `MainHomeView.swift`

### 차이 (18)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 배경 지도 | 3D 항공 이미지 + 전체 균일 덮개 #00000055 | 표준 다크 지도(도로명 "뚝섬로·왕십리로·강변북로" 등 라벨, 초록 녹지), 위쪽만 진한 그라데이션 | C2 적용. `MainHomeView.swift:26-31` LinearGradient(0.92→0.55→clear) 삭제 → `Color.black.opacity(0.33).ignoresSafeArea().allowsHitTesting(false)` |
| 2 | 지도 위 Apple 로고 | 없음 | " Maps Legal" x≈10 y≈683pt | C3(허용 차이) |
| 3 | 왼쪽 위 워드마크 | **없음** | "Focus Mate" 12pt Bold, 자간 1.4, #BFC6C1 (x≈20, y≈92) | `MainHomeView.swift:59-61` Text 삭제(Spacer만 남김) |
| 4 | 상단 도구 버튼 수 | **2개**: 기록, 마이페이지 | 4개: 기록·마이페이지·설정·카드 꾸미기 | [기능] `:65-73` 설정(`gearshape`)·카드(`creditcard`) 버튼 삭제. 둘 다 마이페이지(`ProfileView.swift:71,74` `profile.customize`·`profile.settings`)에서 이미 열 수 있음. `open.settings`·`open.cardCustomization`을 쓰는 UI 테스트 경로를 마이페이지 경유로 바꿔야 함 |
| 5 | 도구 버튼 위치 | 지름 **43**, x=289·343(간격 11, 오른쪽 여백 **16**), y=61~104(중심 82.5) | 지름 44, 간격 10, 오른쪽 여백 20, 중심 y≈92 | `:34` `.padding(.horizontal, 20).padding(.vertical, 8)` → `.padding(.leading, 20).padding(.trailing, 16).padding(.top, 2)`(중심 y 82~83 맞춤), `:58` spacing 10 → 11, `:68,80` frame 44 → 43 |
| 6 | 도구 버튼 모양 | 채움 **#0A0A0A 75%(BF)** + **1pt #444444 테두리** | 채움 #0A0A0A 85%, 테두리 없음 | `:69,81` `.background(FMDesign.panel.opacity(0.75), in: Circle()).overlay(Circle().strokeBorder(Color(hex: 0x444444), lineWidth: 1))` |
| 7 | 도구 아이콘 | 기록 = **문서(가로줄 있는 종이) 외곽선**(12x15), 마이페이지 = **사람 외곽선(원 테두리 없음)**(14x16), 흰 선 | `book.closed`, `person.crop.circle`(원 안 사람) 19pt | `:63` → `"doc.plaintext"`, `:64` → `"person"`; `.font(.system(size: 17, weight: .regular))` |
| 8 | 인사말 색·위치 | 15pt/400, **#E1E5E8**, x=24, y=135 | 15pt, #BFC6C1, x≈20, y≈135 | `:92` 색 → `Color(hex: 0xE1E5E8)`; 좌우 여백 `:44` 20 → 24 |
| 9 | 큰 제목 문구 | **"오늘은 어디에서\n출발해볼까요?"** (정류장이 있어도 이 문구) | 정류장 있으면 "서울숲에서,\n나만의 속도로 출발해요." | `:102-105` `welcomeTitle`을 항상 `"오늘은 어디에서\n출발해볼까요?"` 반환(현재 정류장명은 아래 정류장 표시로 충분). 문구 검증 테스트 있으면 갱신 |
| 10 | 큰 제목 줄 배경 | **줄마다 검정 53%(#00000088) 박스**: 1줄 x14 y163 204x47, 2줄 x14 y201 187x48(글자 좌우 10pt·위아래 약 5pt 여백, 반경 0), 글자 아래 2pt 그림자 | 박스 없음 | `:94-97` 제목을 줄 단위 `ForEach(lines)`로 나눠 각 `Text(line).padding(.horizontal, 10).padding(.vertical, 5).background(Color.black.opacity(0.53))`, 줄 사이 `spacing: -9`(박스가 1pt 겹침), 왼쪽 x 14가 되도록 `.padding(.leading, -10)` |
| 11 | 큰 제목 색·줄간격 | 28pt/700 **#FFFFFF**, 줄 기준선 간격 **39pt** | 28pt Bold #F4F6F2, 줄 간격 약 30.6pt | `:95` 뒤 `.foregroundStyle(.white)`; 10번처럼 줄을 분리하면 39pt 피치가 됨 |
| 12 | 인사말→제목 간격 | 인사말 y135 → 제목 박스 y163(제목 글자 y168) | 간격 8 | `:89` spacing 8 → 13 |
| 13 | 현재 정류장 표시 — 핀 아이콘 | **없음** | `mappin.and.ellipse` 36pt | `:118-120` Image 삭제 |
| 14 | 현재 정류장 위 라벨 문구 | **"현재 위치 · 가상 정류장"** 10pt/400 #B5B5BA | "앱 속 현재 정류장" 12pt #BFC6C1 | `:121` 문구·크기·색 교체 `FontCatalog.text(10)`, `Color(hex: 0xB5B5BA)` |
| 15 | 정류장 이름 | 16pt/700 #FFFFFF, **검정 #000000 박스** 110x28(글자 좌우 7pt, 위아래 약 6pt), 박스 위 라벨과 간격 3 | 20pt Bold, 박스 없음, 그림자(0.75, r5) | `:125` → `FontCatalog.text(16, bold: true)` + `.padding(.horizontal, 7).padding(.vertical, 6).background(Color.black)`; `:132` 그림자는 라벨에만 유지; `:117` spacing 6 → 3 |
| 16 | 방면 줄 | **없음** | "성동구민체육센터 방면" 12pt | `:127-129` 화면 표시는 삭제하되 접근성 값 보존이 필요하면 `.accessibilityHidden(false)` 투명 Text로 유지(테스트 `main.bound` 의존 확인) |
| 17 | 정류장 표시 세로 위치 | 라벨 y437 ~ 박스 끝 y478(화면 중앙 근처) | 아이콘 포함 y≈445~555(라벨 y≈503) | 13·16 삭제 후에도 Spacer 계산이 다름. `:39` `Spacer(minLength: 80)` 대신 정류장 블록을 `GeometryReader` 기준 **y=437 고정 오버레이**(`.position(x: w/2, y: 457)`)로 두는 편이 안전 |
| 18 | 주 버튼(여행 시작하기) | x19 y795 **365x51**, #FFFFFF + 1pt #444444, 캡슐, 15pt/400 검정, **화살표 없음**, 화면 아래 28pt 위(홈 인디케이터 바로 위) | x≈20 y≈773 361x51, #F4F6F2, 반경 24, 17pt Bold, 오른쪽 `arrow.right`, 화면 아래 50pt 위 | C5 + `:176-181` HStack·`arrow.right` 삭제하고 `Text(model.mainStartTitle)`만. 가로 `:44` 패딩은 버튼만 19pt가 되도록 `.padding(.horizontal, -1)`(또는 footer만 19). 바닥 `:44 .padding(.bottom, 16)` → 버튼 bottom이 846pt 되도록 `.padding(.bottom, -6)` 수준(안전영역 34 내부로 6pt 침범) |

### 데이터 차이(수정 대상 아님)
- 정류장 이름: 시안 "예시 현재 위치" / 앱 "서울숲"
- 인사말: 시안 "오늘도 수고했어요."(저녁 문구) / 앱 "좋은 아침이에요."(오전 캡처). 시간대 로직은 같음
- 지도 위치(시안 한강·다리 / 앱 서울숲 주변)

---

## R02-first · 첫 이용(소개 시트)

시안 `spec/R02-first.txt` / 앱은 해당 화면 없음 → 대체 캡처는 `InitialStationSearchView`(빈 검색)

### 차이 (12)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 화면 자체 | **"나를 위한 한 정거장" 소개 시트**가 첫 이용 시 지도 위에 뜸 | 없음. 바로 "출발 정류장" 검색 패널 | [기능] `RootView.swift:228-229` `.initialStationEntry` 분기 앞에 소개 단계 추가: 새 뷰 `FirstRunIntroView`(아래 2~10 사양). "출발 정류장 선택" → 검색 화면(R03)으로 전환 |
| 2 | 배경 | 3D 항공 지도 + #00000055 | 단색 #0F1012(지도 없음) | [기능] 현재 정류장이 없어 `SceneMapBackdrop`이 비어 있음(`SceneMapBackdrop.swift:55-57`). 기본 좌표(예: 서울숲 37.5444,127.0374)를 받는 `fallbackCoordinate` 인자를 추가해 첫 이용·검색 화면에도 지도 표시 + C2 덮개 |
| 3 | 상단 내비 제목 | **없음** | 가운데 "Focus Mate"(시스템 내비 제목 17pt) | `RootView.swift:139-147` `hidesRootNavigationBar`에 `.initialStationEntry`도 포함 |
| 4 | 왼쪽 위 브랜드 | "Focus Mate" **24pt/700 #FFFFFF**, x24 y91 | 없음(내비 제목만) | 새 뷰 상단: `Text("Focus Mate").font(FontCatalog.text(24, bold: true))` `.padding(.leading, 24).padding(.top, 91 - safeTop)` |
| 5 | 브랜드 부제 | "버스로 떠나는 나만의 여행" 12pt/400 #B5B5BA, y128(제목 아래 13pt) | 없음 | 같은 VStack `spacing: 13` |
| 6 | 시트 프레임 | x12 y552 378x297, 반경 24, #0A0A0A + 1pt #3B3B3B, 바닥에서 25pt 위 | (검색 패널) x24, 바닥 83pt 위, 테두리 없음 | C4 |
| 7 | 시트 제목 | "나를 위한 한 정거장" 22pt/700 #FFFFFF, x35(시트 안 23pt) y585(시트 위 33pt) | — | `.padding(.horizontal, 23).padding(.top, 33)` |
| 8 | 닫기 버튼 | 오른쪽 위 "×" 23pt/400 #FFFFFF, x339 y585 | — | [기능] `Image(systemName: "xmark").font(.system(size: 19, weight: .light))` 44x44 탭 영역. 닫으면 시트 숨기고 지도만(다시 여는 방법 필요 — 아래 CTA만 남기는 안 권장) |
| 9 | 설명 1줄 | "정해진 시간만큼 버스를 타고, 여행해요." 12.5pt/400 #B5B5BA, 제목 아래 27pt | — | `FontCatalog.text(12.5)` |
| 10 | 설명 2줄 | "처음에는 출발 정류장을 고르고," / "시간을 정해 나만의 여행을 시작해요." 15pt/400 **#AAAAAA**, 줄 피치 27pt, 설명1 아래 22pt | — | `Text(...).lineSpacing(12)` |
| 11 | 버튼 | "출발 정류장 선택" — x36 y752 **331x43**, #FFFFFF + 1pt #444444 캡슐, 15pt/400 검정 (시안 내부 여백 24pt) | (검색 패널의 "확인" 버튼) | C5 스타일, `.padding(.horizontal, 24)` |
| 12 | 면책 문구 | "앱 속 예시 위치입니다. 실제 버스 위치와 달라요." 10pt/400 #B5B5BA 가운데, 버튼 아래 16pt, 시트 바닥 28pt 위 | 없음 | `Text(...).font(FontCatalog.text(10)).foregroundStyle(Color(hex: 0xB5B5BA))` |

### 데이터 차이
- 없음(모두 고정 문구)

---

## R03-search · 출발 정류장 검색(결과 선택)

시안 `spec/R03-search.txt` / 앱 `InitialStationSearchView.swift`, `RootView.swift:149-161`

### 차이 (21)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 배경 | 3D 항공 지도 + #00000055 | 단색 #0F1012 | R02-2와 같음 [기능] |
| 2 | 내비 제목 | 없음 | "Focus Mate" | R02-3과 같음 |
| 3 | 패널 위치·크기 | x12 y350 **378x504**(내용 높이), 바닥 20pt 위 | x24 y350 354x441, 바닥 83pt 위, 높이 = 화면 68% − 44 고정 | `RootView.swift:159` 이 라우트일 때 `.padding(24)` 제외(`presentedRoute == .initialStationEntry ? 0 : 24`). `InitialStationSearchView.swift:54-56` → 내용 높이에 맞추고(`fixedSize(vertical)` + 최대 높이만 `geometry.size.height - 60`) `.padding(.horizontal, 12).padding(.bottom, 20)` + C4 |
| 4 | 패널 테두리 | 1pt #3B3B3B | 없음 | C4 |
| 5 | 패널 안쪽 여백 | 제목 x27(15pt), 내용 x30(18pt), 위 25pt, 아래 15pt | 22pt 사방 | `:56` `.fmPanel(padding: 22)` → `.padding(.top, 25).padding(.horizontal, 18).padding(.bottom, 15)` 후 배경만 적용 |
| 6 | 닫기 × | 오른쪽 위 "×" 23pt #FFFFFF(x347 y375) | 없음 | [기능] 제목 HStack 오른쪽에 `xmark` 버튼 → R02 소개 시트로 돌아가기(소개 시트 도입 시에만 의미) |
| 7 | 제목 | "출발 정류장" **20pt/700** #FFFFFF (Noto) | 시스템 `.title2.bold()`(22pt SF) | `:21` → `FontCatalog.text(20, bold: true, relativeTo: .title2).foregroundStyle(.white)` |
| 8 | 부제 | "출발 정류장을 골라주세요." **12.5pt/400 #B5B5BA**, 제목 아래 27pt | 시스템 `.subheadline`(15pt) #BFC6C1, 간격 12 | `:22` → `FontCatalog.text(12.5)`, `Color(hex: 0xB5B5BA)`; 제목–부제 간격 27(제목 블록 아래 `.padding(.bottom, 15)`) |
| 9 | "정류장 검색" 라벨 | **11pt/400 #AAAAAA**, 부제 아래 14pt | 시스템 `.caption`(12pt) #BFC6C1 | `:27` → `FontCatalog.text(11)`, `Color(hex: 0xAAAAAA)` |
| 10 | 검색칸 모양 | 343x47, 채움 **#111111**, 입력 중 **금색 1.5pt 테두리 #D7B378**, 반경 약 20(거의 캡슐) | 높이 49, 채움 흰 5%(#1A1A1A), 테두리 흰 16%, 반경 14 | `:29-31` → `.padding(.horizontal, 12).frame(height: 47).background(Color(hex: 0x111111), in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(searchFocused \|\| !search.query.isEmpty ? Color(hex: 0xD7B378) : Color(hex: 0x444444), lineWidth: 1.5))` |
| 11 | 검색칸 글자 | 15pt/400 #FFFFFF, 안쪽 여백 12 | 시스템 body 17pt, 여백 14 | `TextField(...).font(FontCatalog.text(15))` |
| 12 | 지우기 버튼 | 오른쪽에 **파란 "×" 아이콘 10x10**(x347) | 없음 | [기능] 검색어가 있을 때 `Button { search.query = "" } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: 0x3B6FD8)) }` 오른쪽 18pt 여백 |
| 13 | 결과 행 크기·간격 | 343x**67**, 행 간격 11, 검색칸→첫 행 11 | 약 354x72, 간격 12 | `:100` `.padding(14)` → `.padding(.horizontal, 13).padding(.vertical, 14)` + `.frame(minHeight: 67)`; `:20` VStack spacing 12 → 11 |
| 14 | 결과 행 모양 | 채움 #111111, **반경 약 20**, 선택 1pt **#FFFFFF**, 미선택 1pt **#444444** | 채움 #111111, 반경 14, 선택 흰 100%, 미선택 흰 14%(≈#242424) | `:103-104` 반경 14 → 20, 미선택 stroke `Color(hex: 0x444444)` |
| 15 | 결과 행 이름 | **15pt/700** #FFFFFF | 시스템 `.headline`(17pt semibold) | `:93` → `FontCatalog.text(15, bold: true)` |
| 16 | 결과 행 부제 | 한 줄 **"서울 성동구 · 성수동 방면 승차장"** 10pt/400 #B5B5BA, 이름 아래 15pt | ARS(있으면) + "성수동 방면" 시스템 body 17pt `.secondary` 회색, 두 줄 가능 | `:94-95` → 한 줄 `Text("\(district) · \(bound) 승차장")` `FontCatalog.text(10)` #B5B5BA. [기능] "서울 성동구" 자치구 값이 `StopSearchOption`에 없음 → 카탈로그에 구 정보 추가 필요(없으면 구 생략하고 "성수동 방면 승차장") |
| 17 | 결과 행 오른쪽 아이콘 | **모든 행**에 조준점 "⌖" 15pt 흰색(지도에서 위치 보기 의미) | 선택 행에만 `checkmark.circle.fill` | `:98` → 모든 행 `Image(systemName: "scope").font(.system(size: 13))`; 선택 표시는 흰 테두리로만. (조준점 탭 동작을 넣으려면 [기능]) |
| 18 | 면책 문구 | "실제 교통 정보가 아닌 앱 속 정류장 예시입니다." 10pt/400 #B5B5BA 가운데, 버튼 위 20pt | 없음 | 확인 버튼 바로 위에 추가 |
| 19 | 선택 확인 줄 | 별도 줄 없음(버튼 라벨로 흡수) | 결과 아래 "성수역 · 성수동 방면에서 출발" 본문 Text(스크롤 끝에 걸려 반쯤 잘림) | `:79-81` 화면 표시는 삭제(접근성 식별자 `search.confirmation`은 버튼 value로 이동) |
| 20 | 확인 버튼 라벨 | **"성수역 · 성수동 방면에서 출발"**(선택값 문장) | "확인" | `:46` `Button(selected.map(StationSearchState.confirmationText(for:)) ?? "출발 정류장을 골라주세요")`. 선택 전 라벨은 시안에 없음 → 제안값 |
| 21 | 확인 버튼 모양 | x28 y796 **347x43**, #FFFFFF + #444444 캡슐, 15pt/400 | 52pt, #F4F6F2, 반경 24, 17pt Bold | C5 |

### 데이터 차이
- 검색어: 시안 "성수"(3건: 성수역 2·서울숲역 1) / 앱 "성수역"(2건). 앱 픽스처에서 "성수"는 8건이라 맞춘 것
- 정류장 부제의 구·방면 값

---

## R04-search-time · 시간 고르기(후보 1개, 미선택)

시안 `spec/R04-search-time.txt` / 앱 `TimeSelectionView.swift`, `SceneMapBackdrop.swift`

### 차이 (25)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 배경 지도 | 3D 항공 + #00000055 | 다크 표준 지도 + 라벨 + 아래로 갈수록 #0F1012로 진해지는 그라데이션 | C2. `TimeSelectionView.swift:17-19` 그라데이션 → `Color.black.opacity(0.33)` |
| 2 | 시스템 뒤로 버튼 | **없음** | 왼쪽 위 Liquid Glass 원형 `<`(x≈16 y≈62 44pt) | [기능] `TimeSelectionView` body에 `.navigationBarBackButtonHidden(true)`, 패널 안 `<` 버튼(아래 4)으로 `model.path.removeLast()`. 가장자리 스와이프 뒤로가기는 `NavigationPopBlocker` 사용 여부 확인 |
| 3 | 왼쪽 위 출발 블록 | **없음** | "출발"(mappin.circle.fill 12pt) / "성수역" 18pt Bold / "성수동 방면" 13pt (x≈22, y≈125~185) — 지도 라벨과 겹쳐 지저분 | `:21-23` `origin` 표시 삭제(큰 글자 모드 `:28`만 유지하거나 지도 표식으로 대체). 테스트 식별자 `time.origin`·`time.bound`는 지도 표식 쪽으로 이동 |
| 4 | 출발 정류장 지도 표식 | 화면 가운데 위(x186 y131) **흰 물방울 핀 30x39**(가운데 구멍 11x11 #151A1D) + 아래 라벨 상자 2개: **"출발 정류장"** 11pt/400 #E5EAE7 on #000000 71x28, **"성수역"** 16pt/700 #FFFFFF on #000000 60x32 | MapKit 기본 원형 핀(`mappin.circle.fill` 36pt 흰색) + MapKit 제목 "성수역"(회색 작은 글자) | `SceneMapBackdrop.swift:43-47` Annotation 내용 교체: VStack(spacing: 3){ 물방울 `Image(systemName: "mappin.circle.fill")` 대신 커스텀 핀 Shape 30x39 흰색 + 구멍 원 11pt #151A1D; `Text("출발 정류장").font(FontCatalog.text(11)).foregroundStyle(Color(hex: 0xE5EAE7)).padding(.horizontal, 9).padding(.vertical, 8).background(.black)`; `Text(stop.name).font(FontCatalog.text(16, bold: true)).padding(.horizontal, 8).padding(.vertical, 8).background(.black)` }, `Map {...}.annotationTitles(.hidden)`(MapKit 기본 제목 숨김) |
| 5 | 패널 위치·크기 | x12 **y378** 378x476, 바닥 20pt 위 | x12 y300 378x526, 바닥 48pt 위(최대 73% 고정) | C4. `:49-50` `.frame(maxHeight: … 0.73)` → 내용 높이 우선(`.fixedSize(horizontal: false, vertical: true)`), `.padding(.bottom, 12)` → `20` + `.ignoresSafeArea(edges: .bottom)` |
| 6 | 패널 테두리 | 1pt #3B3B3B | 없음 | C4 |
| 7 | 패널 안 `<` | 제목 왼쪽 **`<` 5x10 흰 1.5pt 선**, x51(패널 안 39pt), 제목과 같은 줄 | 없음 | [기능] 2번과 같이. `Button { … } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .regular)) }.frame(width: 44, height: 44)` |
| 8 | 제목 | "시간부터 골라볼까요?" **18pt/700**, **왼쪽 정렬** x87(< 오른쪽 31pt), 패널 위 26pt | 24pt Bold **가운데 정렬** | `:29-31` → HStack{ back, Text(...).font(FontCatalog.text(18, bold: true)), Spacer }, `.multilineTextAlignment(.center).frame(maxWidth: .infinity)` 삭제 |
| 9 | 시간 숫자 | **"25 min" 한 덩어리 32pt/700**(숫자·min 같은 크기·굵기), 가운데, 제목 아래 27pt | 숫자 40pt semibold **rounded(SF)** + "min" 18pt 서울알림 | `:65-73` → `Text("\(minutes) min").font(FontCatalog.text(32, bold: true))` (60분 이상 표기는 시안에 없음 → R26-5 참조) |
| 10 | 눈금자 배경 | **검정 #000000 상자 338x81**, 반경 0, 숫자 아래 14pt | 배경 없음(패널색) | `MinuteRuler` `:174-197` Canvas에 `.background(Color.black)`, 높이 78 → 81 |
| 11 | 눈금 간격 | **1분 = 12pt** | 8pt | `:164` `pointsPerMinute` 8 → 12 |
| 12 | 눈금 길이·굵기·색 | 큰 눈금(5분) **20pt**, 작은 눈금 **10pt**, 둘 다 **1pt**, 큰 #FFFFFF **73%(BB)**, 작은 #FFFFFF **33%(55)**, 상자 위에서 23pt부터 위쪽 정렬 | 큰 32pt·2pt·primary 65%, 작은 18pt·1pt·30%, y12부터 | `:181-183` `tick.move(to: (x, 23)); addLine(to: (x, major ? 43 : 33))`, `lineWidth: 1`, 색 `Color.white.opacity(major ? 0.73 : 0.33)` |
| 13 | 눈금 숫자 | **"15 min" 12pt/400 #BFC6C1**, 상자 위 53pt(눈금 끝 10pt 아래); 현재값(가운데) 라벨은 **700** 또는 생략 | "15" `.caption2`(11pt SF) | `:185-186` → `Text("\(minute) min").font(FontCatalog.text(12, bold: minute == value))`, y 62 → 59. (R26·R06은 10분마다 라벨, R04는 5분마다 — 10분 간격 권장, 디자이너 확인) |
| 14 | 가운데 지시자 | 삼각형 10x7 상자 위 3pt, **바늘 2x23** 상자 위 21pt~44pt, 흰 100% | 삼각형 y0, 바늘 2x38 y10 | `:190-195` 삼각형 y 3~10, 바늘 `CGRect(x: c-1, y: 21, width: 2, height: 23)` |
| 15 | 눈금자 범위 끝 표현 | 상자 전체 폭에 눈금 | (R05에서 보임) 최소값 15 왼쪽은 빈칸 | 수정 불요(범위 15~360이 기능 규칙). 시안은 37분이라 해당 없음 |
| 16 | 안내 문구 | "눈금을 좌우로 밀어 1분씩 선택하세요" **11pt/400 #AAAAAA**, 상자 바로 아래 3pt | 12pt #BFC6C1, 간격 16 | `:35-37` → `FontCatalog.text(11)`, `Color(hex: 0xAAAAAA)`, 위 간격 3 (`:27` spacing 16을 개별 padding으로) |
| 17 | 후보 카드 크기·모양 | **178x140**, 채움 **#151B17**, **1pt 테두리 #FFFFFF2B(17%)**, 반경 약 20, 안내 문구 아래 16pt, 패널 왼쪽 안 24pt(x36) | 218x약104(`frame(width: 190)` + padding 14), 반경 16, 테두리 primary 18% | `:141` width 190 → 152(패딩 13 포함 178), `:143` 고정 높이 `.frame(height: 140, alignment: .topLeading)`, `:146-148` 반경 16 → 20, stroke `Color.white.opacity(0.17)` |
| 18 | 노선 배지 | **초록 #168445 알약 95x32**(반경 약 8), 안: 버스 외곽선 아이콘 18pt 흰 선 + **"지선" 9pt/400 #B5B5BA** + **"2014" 17pt/700 #FFFFFF** | 배지 없음. `Label("지선 2014", systemImage: "bus.fill")` 17pt Bold 한 덩어리 | `:132-134` → `HStack(spacing: 4){ Image(systemName: "bus").font(.system(size: 14)); Text(kind).font(FontCatalog.text(9)).foregroundStyle(Color(hex: 0xB5B5BA)); Text(number).font(FontCatalog.text(17, bold: true)) }.padding(.horizontal, 7).frame(height: 32).background(FMDesign.busColor(kind), in: RoundedRectangle(cornerRadius: 8))` (C8) |
| 19 | 카드 도착지 | **15pt/700** #FFFFFF, 배지 아래 13pt | 17pt Bold | `:137` 17 → 15 |
| 20 | 카드 메타 문구 | **"25 min · 5정류장"** 11pt/400 **#C2CCC5**, 도착지 아래 16pt | "25분 · 5정류장 · 2.8km" 12pt primary | `:138-139` → `Text("\(candidate.minutes) min · \(candidate.stops)정류장")` `FontCatalog.text(11)` `Color(hex: 0xC2CCC5)`; 거리(km) 표시는 시안에 없음 → 삭제(접근성 라벨에는 유지 가능) |
| 21 | 카드 안쪽 여백 | 왼쪽 13pt, 위 15pt | 14pt 사방 | `:144` → `.padding(.leading, 13).padding(.top, 15).padding(.trailing, 13)` |
| 22 | 면책 문구 | **"도착 후보는 가상 노선의 예시입니다."** 10pt/400 #BFC6C1 가운데, 버튼 위 29pt | 없음 | `:43` 버튼 위에 `Text(...).font(FontCatalog.text(10)).foregroundStyle(FMDesign.secondaryText)` 추가 |
| 23 | 진행 버튼(비활성) | x32 y796 **339x43**, #303A33 캡슐, "버스와 도착지를 선택하세요" 15pt/400 #C6D0C9 | 52pt, 회색 #8A8B89, 검정 70% 17pt Bold | C6 + C5 크기 |
| 24 | 버튼–패널 여백 | 버튼 좌우 패널 안 20pt, 아래 15pt | 22pt | `fmPanel()` 22 → 좌우 20·아래 15 |
| 25 | 상단 글자 그림자/가독 | 시안 라벨은 검정 상자 위 흰 글자(지도 영향 없음) | 지도 라벨과 앱 글자가 겹침("성수동 방면" 위에 도로명) | 3·4 수정으로 해소 + C2 `.imagery`로 지도 라벨 제거 |

### 데이터 차이
- 없음(2014 → 서울숲 입구, 25분, 5정류장 일치). 앱 메타의 "2.8km"는 문구 형식 차이로 20번에 포함

---

## R05-no-candidate · 도착 후보 없음

시안 `spec/R05-no-candidate.txt` / 앱 `TimeSelectionView.swift:99-103`, `JourneyPlanDraft.swift:35`

R04의 1~14·16·23·24번(지도·뒤로 버튼·출발 블록·핀 표식·패널·제목·시간 숫자·눈금자·안내 문구·버튼 모양)이 **그대로 모두 해당**한다. 아래는 이 화면에만 있는 차이.

### 차이 (R04 공통 15 + 고유 7 = 22)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 패널 높이 | 내용에 맞춰 줄어듦: **y425~854(429)** | R04와 같은 526 높이(아래 빈 공간 약 330pt) | R04-5(내용 높이 맞춤)로 해소 |
| 2 | 빈 상태 상자 | **#151B17 상자 336x83**, 반경 약 14, 패널 안 21pt, 안내 문구 아래 26pt | 상자 없음, 글자만 왼쪽 정렬 | `:101-103` → `.multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 83).background(Color(hex: 0x151B17), in: RoundedRectangle(cornerRadius: 14))` |
| 3 | 빈 상태 글자 | 13pt/400 **#C5D0C8**, **가운데 정렬**, 줄 피치 24pt | 15pt #BFC6C1, 왼쪽 정렬, 줄 간격 좁음 | `FontCatalog.text(13)`, `Color(hex: 0xC5D0C8)`, `.lineSpacing(11)` |
| 4 | 빈 상태 문구 | "이 시간에 도착하는 버스가 없어요." / "눈금을 움직여 다른 시간을 골라보세요." | 같음 | 일치 |
| 5 | 면책 문구 | "도착 후보는 가상 노선의 예시입니다." 버튼 위 | 없음 | R04-22와 같음(후보 없음 상태에도 표시) |
| 6 | 비활성 버튼 문구 | **"이 시간의 도착 후보가 없어요"** | "이 시간에 맞는 버스가 없어요" | `JourneyPlanDraft.swift:35` 문구 교체(이 문자열을 검사하는 단위/UI 테스트도 갱신) |
| 7 | 눈금 라벨 | "30 min / 40 min / 50 min"(10분 간격, 37분 기준 가운데 라벨 없음) | "15 20 25 30 35"(5분 간격, 숫자만) | R04-13 |

### 데이터 차이
- 선택 시간: 시안 37분 / 앱 17분(앱 픽스처에서 후보 없음이 검증된 값)

---

## R26-time-before · 시간 선택, 후보 2개 이상·선택 전

시안 `spec/R26-time-before.txt` / 앱 `TimeSelectionView.swift`

R04의 1~14, 16~24번이 그대로 해당한다. 고유 차이만 적는다.

### 차이 (R04 공통 23 + 고유 5 = 28)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 간선 배지 색 | 343 = **#2563EB** 파랑 배지(85x32) | 색 없음 | C8 `busColor("간선")` |
| 2 | 후보 카드 가로 배치 | 카드 간격 **10pt**, 둘째 카드가 **패널 오른쪽 밖(x399)까지** 그려져 잘림 = 스크롤이 패널 가장자리까지 확장 | 간격 10 일치, 하지만 패널 안쪽 여백(x≈368)에서 잘림 | `:111-117` 가로 ScrollView에 `.padding(.horizontal, -24).contentMargins(.horizontal, 24, for: .scrollContent)` 로 패널 끝까지 스크롤 영역 확장(패널 `clipShape`는 유지) |
| 3 | 카드 첫 위치 | 첫 카드 x33(패널 안 21pt) | x≈38 | 2번 contentMargins 21 |
| 4 | 가운데(현재값) 눈금 라벨 | "40 min" **700 굵게** | 같은 굵기 "120" | R04-13(`bold: minute == value`) |
| 5 | 60분 이상 시간 표기 | (시안은 40분만 있음) "N min" 한 덩어리 | "2 h 0 min"(숫자 40 rounded + h/min 18pt) | 결정 필요. 시안 서체 규칙(32pt/700 한 덩어리)에 맞춰 `"2h 0 min"` 또는 `"120 min"` 한 Text로. `:66-69` |

### 데이터 차이
- 시간: 시안 40분 / 앱 120분
- 후보: 시안 2개(간선 343 → 서울숲 입구 40 min·5정류장, 지선 2014 → 성수사거리 40 min·8정류장) / 앱 3개(지선 2014 → 성수대교 북단 120분·24정류장·13.2km, 마을 강남02 → 뚝섬한강공원 …, 간선 343 …)
- 앱의 "마을" 종류는 시안 색 미정(C8)

---

## R06-time-dest · 시간·도착지 선택됨

시안 `spec/R06-time-dest.txt` / 앱 `TimeSelectionView.swift`, `SceneMapBackdrop.swift`

R04의 1~3, 5~14, 16~19, 21, 24번이 그대로 해당한다. 고유 차이만 적는다.

### 차이 (R04 공통 19 + 고유 13 = 32)

| # | 영역 | 시안 | 앱 | 수정안 |
|---|---|---|---|---|
| 1 | 선택 시 지도 카메라 | 카메라가 **노선 전체가 보이도록 이동**(x100~284, y56~455 안에 노선 전체) | 출발 정류장 중심 고정(1800m) → 13.2km 노선이 화면에 거의 안 보임, 지도 변화 없음 | [기능] `SceneMapBackdrop.swift:36` `initialPosition` 고정 + `.id(stop.id)` → `@State var position: MapCameraPosition`; `routeID` 변경 시 `position = .rect(MKMapRect(boundingAll: route))`(패딩: 위 56, 아래 패널 높이+16) 애니메이션 |
| 2 | 노선 선 | **버스색 #168445 선 약 2pt**(R06 지선=초록), 선 외곽 #FFFFFF44 1pt | `FMDesign.primary` 80% 흰 선 3pt | `:39-40` `.stroke(FMDesign.busColor(kind), style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))` — 종류 전달을 위해 `routeKind` 인자 추가 |
| 3 | 정류장 점 | 경유 정류장 **흰 3x3 점 + #0A0A0A 1pt 테두리**, 출발 점 **#777777**, 도착 점 **6x6 #0A0A0A + #168445 테두리** | 없음 | [기능] `route` 좌표마다 `Annotation("", coordinate:) { Circle().fill(.white).frame(width: 5, height: 5).overlay(Circle().stroke(Color(hex: 0x0A0A0A), lineWidth: 1)) }`, 첫 점 #777777, 마지막 점 8pt #0A0A0A + 버스색 테두리 1.5pt |
| 4 | 출발 위치 버스 표식 | 출발 정류장 위치에 **초록 버스 그림 30x38** | 흰 원형 핀 + "성수역" 제목 | [기능] 노선 선택 상태(`routeID != nil`)에서는 `Annotation` 내용을 버스 아이콘(`Image(systemName: "bus.fill")` 20pt 흰색 on 버스색 RoundedRectangle 24x30 r6)으로 교체 |
| 5 | 출발 정류장 라벨 | 선택 후에는 **"출발 정류장/성수역" 라벨·핀 사라짐** | 계속 보임 | 4번 분기에서 라벨 제외 |
| 6 | 왼쪽 위 노선 칩 | **x16 y60 115x50**, 채움 #080808 79%(C9) + 1pt #FFFFFF25 테두리, 반경 약 14; 안에 초록 배지 103x38(버스 아이콘 20pt, "지선" 9pt #B5B5BA, "2014" 17pt/700) | 없음 | `TimeSelectionView.swift:20-23` 위치(지금 origin 자리)에 선택 노선이 있을 때 `RouteBadge(kind:number:, height: 38)` `.padding(6).background(Color(hex: 0x080808).opacity(0.79), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.145)))`, `.padding(.leading, 16).padding(.top, 60 - safeTop)` |
| 7 | 패널 높이 | **y304~854(550)** — "노선 한 바퀴 보기" 영역만큼 위로 커짐 | 고정 526 | R04-5(내용 높이) |
| 8 | 선택 카드 색 | 채움·테두리 **#F4F6F2**, 도착지 **#111A13** 15pt/700, 메타 **#405147** 11pt, 배지는 **원래 버스색 유지**(흰 글자) | 채움 primary, 글자 전부 검정, 배지 없음 | `:145-146` 선택 시 도착지 `Color(hex: 0x111A13)`, 메타 `Color(hex: 0x405147)`, 배지 색 유지(배지 글자색 고정 흰/#B5B5BA) |
| 9 | 선택 체크 아이콘 | **없음** | "지선 2014" 옆 `checkmark.circle.fill` | `:135` 삭제(선택 표시는 카드 반전으로 충분, 접근성 `.isSelected`는 유지) |
| 10 | 선택 카드 스크롤 | 선택한 둘째 카드가 보이도록 **가로 스크롤 이동**(첫 카드가 왼쪽으로 33pt 밀려 잘림) | 스크롤 이동 없음 | [기능] `:111` `ScrollView(.horizontal)`에 `.scrollPosition(id: $selectedID, anchor: .center)` 또는 `ScrollViewReader.scrollTo(routeID, anchor: .trailing)` (Reduce Motion이면 애니메이션 없이) |
| 11 | 노선 한 바퀴 보기 | 카드 아래 **"노선 한 바퀴 보기"** 11pt/400 #DDDDDD(x33, 카드 아래 31pt) + **"12초 미리보기 · 실제 여행 진도와 별개"** 11pt/400 #BFC6C1(아래 34pt) | 없음 | [기능] 노선 선택 시에만 보이는 버튼 추가 → 12초 동안 지도 위에서 버스 표식이 노선을 한 바퀴 이동하는 미리보기(실제 여정 진행과 무관). Reduce Motion일 때는 정지 이미지/생략 |
| 12 | 진행 버튼(활성) | "이 여정 준비하기" **#FFFFFF + #444444 캡슐 339x43, 15pt/400 검정** | #F4F6F2 반경 24, 52pt, 17pt Bold | C5 |
| 13 | 면책 문구 | "도착 후보는 가상 노선의 예시입니다." 버튼 위 | 없음 | R04-22 |

### 데이터 차이
- 시간: 시안 40분 / 앱 120분
- 선택 노선: 시안 지선 2014 → 성수사거리(40 min·8정류장), 비선택 간선 343 → 서울숲 입구 / 앱 지선 2014 → 성수대교 북단(120분·24정류장·13.2km), 비선택 마을 강남02 등
- 지도 위치·노선 모양(시안 사각형 경로 / 앱 실제 노선)

---

## 화면별 차이 개수 요약

| 화면 | 차이 수 | 그중 [기능] |
|---|---|---|
| 공통(C1~C10) | 10 | 0(C9는 R04에서 셈) |
| R01-main | 18 | 1 (도구 버튼 2개 제거) |
| R02-first | 12 | 3 (소개 시트 신설, 지도 배경 대체 좌표, × 닫기) |
| R03-search | 21 | 4 (지도 배경, × 닫기, 지우기 버튼, 자치구 데이터) |
| R04-search-time | 25 | 2 (시스템 뒤로 숨김 + 패널 `<`) |
| R05-no-candidate | 22 (R04 공통 15 + 고유 7) | 2 (R04에서 상속) |
| R26-time-before | 28 (R04 공통 23 + 고유 5) | 2 (R04에서 상속) |
| R06-time-dest | 32 (R04 공통 19 + 고유 13) | 7 (카메라 이동, 정류장 점, 버스 표식, 카드 스크롤, 노선 미리보기 + R04 2) |

## 수정 순서 제안
1. `FMDesign.swift`: 주/비활성 버튼(C5·C6), 패널 테두리(C4), 색 토큰(C7·C8) — 거의 모든 화면이 한 번에 맞춰진다
2. `SceneMapBackdrop.swift`: `.imagery` + 덮개 + 커스텀 출발 표식 + 노선 맞춤 카메라(C2, R04-4, R06-1~5)
3. `TimeSelectionView.swift`: 패널 레이아웃·눈금자·후보 카드·면책 문구(R04/R05/R26/R06 공통)
4. `MainHomeView.swift`: 제목 박스·정류장 라벨·도구 버튼(R01)
5. `InitialStationSearchView.swift` + 소개 시트 신설(R02·R03) — [기능] 범위라 별도 작업 권장
