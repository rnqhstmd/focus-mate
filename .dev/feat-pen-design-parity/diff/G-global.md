# G-global: 전 화면 공통 디자인 시스템 차이

근거: `spec/*.txt` 42개 grep 집계, `pen/R01·R06·R13`, `app/R01` 이미지 대조, 앱 소스 `next-step-w19/ios/FocusMate/`(FMDesign.swift, FontCatalog.swift, SceneMapBackdrop.swift, JourneyMapView.swift, JourneyMapState.swift, MainHomeView.swift, TimeSelectionView.swift, PreparationView.swift, JourneyView.swift, JourneyTimerView.swift).
좌표 단위는 pt(시안 프레임 402x874 = iPhone 17 Pro와 같은 크기).

---

## 1. 글꼴

### 1-1. 시안 집계 (text 노드 720개)

- 패밀리: **Noto Sans KR 720/720 (100%)**. 다른 패밀리 없음.
- 굵기: normal(400) 496 · 700 212 · 600 11 · 500 1 → 실사용 굵기는 **400 / 700**, 보조로 600(태그 칩 이름 14/600, "승차권 보기" 16/600).
- 줄 높이: 대부분 `lh1`(줄높이 = 글자 크기). 예외 `15/700/lh1.5` 2건, lh 표기 없는 레이아웃 프레임 텍스트(14/600, 22/700, 30/700 등)는 기본 줄높이.

| 크기/굵기 | 횟수 | 대표 용도 |
|---|---|---|
| 12/400 | 175(+9) | 보조 라벨, 눈금 "30 min", 남은 수치 라벨, 상태바 시각 |
| 11/400 | 70 | 안내 문구("눈금을 좌우로…"), 후보 요약("25 min · 5정류장") |
| 15/400 | 50(+9) | **CTA 글자**, 인사말, 단위("min") |
| 10/400 | 49 | 고지 문구("도착 후보는 가상 노선의 예시입니다."), "현재 위치 · 가상 정류장" |
| 13/400 | 38(+5) | 목록 보조 |
| 28/700 | 33 | 메인 제목("오늘은 어디에서 / 출발해볼까요?") |
| 8/400, 9/400 | 24, 21 | 배지 종류("지선" 9), 히트맵 축 |
| 15/700 | 20 | 후보 도착지명 |
| 17/700, 16/700 | 17, 17 | 노선 번호(배지 안), 정류장명 |
| 18/700 | 12 | 패널 제목("시간부터 골라볼까요?") |
| 20/700, 22/700, 23/700, 27/700 | 11, 5, 8, 10 | 화면 제목 |
| 30/700, 32/700 | 12, 4 | 큰 수치("16" min, "25 min") |
| 14/600 | 8 | 태그 칩 이름 |

3~7.8pt 조합(카드 위 장식 글자)은 카드 그래픽 내부 축소 표시라 타입 스케일에서 제외.

**권장 타입 스케일(토큰)**: `display 32/700`, `title 28/700`, `title2 22/700`, `heading 18/700`, `number 17/700`, `subhead 15/700`, `body 15/400`, `chip 14/600`, `callout 13/400`, `caption 12/400`, `footnote 11/400`, `micro 10/400`, `badge 9/400`.

### 1-2. 앱 현황

- 앱은 시스템 SF가 아니라 **서울알림체(SeoulAlrimTTF-Medium/Bold)** 를 번들해 쓴다.
  - `Resources/Fonts/SeoulAlrim-Medium.ttf` 2.59MB, `SeoulAlrim-Bold.ttf` 2.56MB (합 5.15MB), 출처 `Resources/Fonts/SOURCE.md`(서울시, 공공누리 1유형).
  - 등록: `FontCatalog.register()`(FocusMateApp.swift:19)에서 `CTFontManagerRegisterFontsForURL` 런타임 등록. Info.plist에 `UIAppFonts` 없음.
  - `PreparationView.swift:470-484`에 같은 등록·폰트 함수가 `PreparationTypography`로 **중복** 구현돼 있다. `BoardingPassView.swift:60`도 이름 직접 지정.
- 사용 분포: `FontCatalog.text(...)` 99곳, `.font(.system(...))` 60곳(대부분 SF Symbols 아이콘 크기지만 일부 글자도 포함), `.font(.caption/.headline/.subheadline/...)` 31곳(이 경우 SF로 렌더 → 서울알림과 섞임).
- 굵기가 Medium(≈500)/Bold 두 개뿐이라 시안의 400(본문)·600(칩)을 표현할 수 없다. 앱 캡처의 본문이 시안보다 두껍고 둥근 느낌인 주원인.
- 크기도 다르다. 예: CTA 시안 15/400 ↔ 앱 17 Bold(`FMPrimaryButtonStyle`), 메인 제목 28/700은 동일.

### 1-3. Noto Sans KR 번들 필요 여부 → **필요**

- iOS에는 Noto Sans KR가 시스템 폰트로 없다(한글 시스템 폰트는 Apple SD Gothic Neo). 시안과 같은 자형을 얻으려면 번들해야 한다. 대안으로 Apple SD Gothic Neo(Regular/SemiBold/Bold)를 쓰면 용량 0이지만 자폭·높이가 달라 시안과 줄바꿈 위치가 어긋난다.
- **라이선스: SIL Open Font License 1.1.** 앱 번들 포함·상업 사용 허용, 서브셋 등 수정 허용(Noto는 Reserved Font Name이 없어 서브셋 후 이름 변경 의무 없음). 폰트 단독 판매만 금지. 조건: 앱 내 "오픈소스 라이선스" 또는 번들에 `OFL.txt` 동봉 + 저작권 고지. 서울알림체(공공누리)보다 조건이 단순하다.
- **용량**
  - 원본: Google Fonts 가변 `NotoSansKR[wght].ttf` 약 10MB, 정적 굵기별 OTF/TTF 약 4.5~6MB씩. 3굵기 정적이면 15MB 이상 → 그대로는 과함.
  - **서브셋 가능**: `pyftsubset`(fonttools)로 `U+0020-007E`(ASCII) + `U+AC00-D7A3`(현대 한글 11,172자) + `U+3131-318E`(자모) + 사용 기호(·, →, ▰ 등). 한자 제거만으로 굵기당 약 1.5~2MB. KS X 1001 2,350자로 줄이면 굵기당 약 0.5~0.8MB이나, 사용자가 입력하는 할 일·태그·메모에 빠진 음절이 나오면 해당 글자만 시스템 폰트로 대체돼 섞여 보인다 → **11,172자 전체 유지 권장**.
  - 권장 구성: 400 / 600 / 700 정적 3개(또는 가변 1개 서브셋) ≈ 4.5~6MB. 서울알림체 2개(5.15MB)를 제거하면 앱 크기는 거의 그대로.
- 구현 메모
  - PostScript 이름은 `NotoSansKR-Regular`, `NotoSansKR-SemiBold`, `NotoSansKR-Bold`(정적 기준). `FontCatalog.text(_:bold:)`를 `weight: .regular/.semibold/.bold` 인자로 바꾸고 `relativeTo:` 유지(Dynamic Type 보존).
  - `PreparationTypography` 중복 삭제, `.font(.caption)` 등 SF 직접 사용 31곳을 토큰으로 교체.
  - 시안 `lh1`을 맞추려면 Noto의 기본 줄높이(≈1.45em)보다 좁다. SwiftUI는 줄높이를 줄일 수 없으므로 한 줄 텍스트는 frame 높이로, 두 줄 제목은 `.lineSpacing(음수 불가)` 대신 줄별 Text 분리 또는 그대로 두고 상하 여백으로 보정.
  - 서울알림체를 "버스 정류장 느낌"으로 의도해 넣은 이력(SOURCE.md)이 있으므로, 교체는 **제품 결정**으로 확인이 필요하다(LCD·승차권 등 일부 장식에만 서울알림을 남기는 절충 가능).

---

## 2. 색

### 2-1. 시안 집계 상위(fill)

`#FFFFFF` 468 · `#00000000` 226 · `#FFFFFF55` 182(눈금) · `#39D353` 86 · `#131815` 80 · `#26A641` 73 · `#1B211E` 72 · `#0E4429` 58 · `#BFC6C1` 54 · `#FFFFFFBB` 42 · `#090909` 42 · `#B5B5BA` 41 · `#14191B` 41 · `#000000` 41 · `#F1F2F3` 40 · `#0A0A0A` 37 · `#111111` 33 · `#AAAAAA` 27 · `#777777` 27 · `#121416` 26 · `#182024` 24 · `#00000055` 24 · `#168445` 21 · `#FFFFFFA3` 18 · `#0A0A0ABF` 14 · `#2563EB` 4(배지)
stroke: `#FFFFFF` 101 · `#0A0A0A` 98(정류장 점 테두리) · `#444444` 57(CTA·원형 버튼) · `#80775D` 39(IC칩) · `#FFFFFF44` 12(남은 노선) · `#168445` 11 · `#51565A` 11(카드 테두리)

### 2-2. 역할별 팔레트 vs 현재 토큰

| 역할 | 시안 값 | 앱 현재 | 조치 |
|---|---|---|---|
| 화면 바탕(지도 로딩 전) | `#090909` → `#14191B`/`#182024` 이미지 밑색 | `FMDesign.background` `#0F1012` | `#090909`로(지도 밑색 `#14191B` 별도 토큰 `mapBase`) |
| 지도 덮개 | `#00000055`(≈33%) 전면 균일 | 메인: 위→아래 그라데이션 background 92%→55%→0; 여행: `JourneyBriefingShade`/`PausedJourneyShade` 별도 | 공통 `mapScrim = black 0.33` 토큰, 균일 덮개 기본 + 필요한 화면만 추가 |
| 제목 뒤 글자 받침 | `#00000088`(53%) 직사각형(R01 제목 줄마다) | 없음 | 메인 제목에 줄별 배경(선택) |
| 하단 패널 | `#0A0A0A` + 테두리 `#FFFFFF33`(20%) | `FMDesign.panel` `#0A0A0A`, 테두리 없음 | 색 일치, **테두리 토큰 `panelStroke = white 0.2` 추가** |
| 주 텍스트 | `#FFFFFF` | `FMDesign.primary` `#F4F6F2`(미색) | `#FFFFFF`로 |
| 보조 텍스트 1 | `#BFC6C1` | `FMDesign.secondaryText` `#BFC6C1` | **일치** |
| 보조 텍스트 2(라벨) | `#B5B5BA`("현재 위치 · 가상 정류장", 배지 "지선") | 없음(secondaryText로 통일) | `tertiaryText` 추가 |
| 안내/힌트 | `#AAAAAA` | 없음 | `hintText` 추가 |
| 여행 수치 라벨 | `#FFFFFFA3`(64%) | — | `overlayLabel = white 0.64` |
| 인사말 | `#E1E5E8` | secondaryText | 근사(선택) |
| CTA 배경/글자/테두리 | `#FFFFFF` / `#000000` / `#444444` | `#F4F6F2` / black / 없음 | 배경 흰색, 테두리 추가 |
| CTA 비활성 | 배경 `#303A33`, 글자 `#C6D0C9` | primary 55% 투명 + black 70% | 시안 값으로 |
| 원형 버튼 배경/테두리 | `#0A0A0ABF`(75%) / `#444444` | `panel.opacity(0.85)` / 없음 | 75% + `#444444` 1pt |
| 여행 화면 원형 버튼 | `#080808CC` + 링 `#FFFFFF25`(15%) 44~46pt, 활성(따라가기) `#FFFFFF20` + 흰 테두리 | `.black.opacity(0.6)` | 토큰화 |
| **간선 파랑** | `#2563EB` | 없음(배지 색 구분 없음) | 추가 |
| **지선 초록** | `#168445` | 없음 | 추가(노선선·버스 아이콘도 이 색) |
| 노선선 진행/남은 구간 | `#168445` / `#FFFFFF44` | 단색 `rgb(0.36,0.62,1)`(파랑) 5pt, 메인은 primary 80% 3pt | 노선 종류 색 + 남은 구간 회색 |
| 정류장 점 | 흰 `#FFFFFF`, 지난 정류장 `#777777`, 테두리 `#0A0A0A` | 흰 + black 40% | 지난 정류장 회색 추가 |
| 후보 카드 | 미선택 `#151B17` + `#FFFFFF2B` / 선택 밝은 `#F1F3F1`계 | `rgb(21,27,23)`=`#151B17` + primary 18% / 선택 primary | 거의 일치, 테두리 17%로 |
| 목록 행 | `#111111`, 테두리 `#444444`, 선택 `#FFFFFF` | 화면마다 다름 | `rowBackground` 토큰 |
| 칩 배경 | `#1A1A1A` + `#FFFFFF33`/`#FFFFFF55` | `.white.opacity(0.06)` + 0.16 | 시안 값으로 |
| 비활성 알약 | `#252525`, 글자 `#888888` | — | 토큰 |
| 히트맵 4단계 | `#1B211E`/`#131815`(빈), `#0E4429`, `#26A641`, `#39D353` | 같은 값 하드코딩(RecordsView 등) | 일치, 토큰으로 이동만 |
| 강조 샌드 | `#D7B378` | `rgb(0.84,0.70,0.47)`≈`#D6B378` | 일치 |
| 카드 바탕/테두리 | `#121416` / `#51565A` | `rgb(18,20,22)`=`#121416` | 일치 |
| IC 칩 | `#C5B998` / `#80775D` | `rgb(0.77,0.73,0.60)`≈`#C4BA99` | 근사 일치 |
| 태그 4색 | 독서 `#E8B64C`, 공부 `#A78BFA`, 업무 `#60A5FA`, 휴식 `#4ADE80`; 칩 배경 22(13%)·테두리 88(53%), 선택 55(33%)·테두리 100% | sand `#D6B378`, blue `#87ABF5`, purple `#B599DE`, green `#8CBAAB`, pink; 배경 20/35%, 테두리 45/100% | **tint 값 교체**(채도 높은 시안 값). pink는 시안에 없음 |

**FMDesign.swift 변경 요약**: `primary #F4F6F2→#FFFFFF`, `background #0F1012→#090909`, 추가 `panelStroke, tertiaryText(#B5B5BA), hintText(#AAAAAA), overlayLabel, mapScrim(#000 33%), ctaStroke(#444444), ctaDisabled(#303A33/#C6D0C9), circleFill(#0A0A0A 75%), routeTrunk(#2563EB), routeBranch(#168445), routeRemaining(#FFF 27%), stopPassed(#777777), chipFill(#1A1A1A), rowFill(#111111)`. 앱 전역 `Color(red:` 하드코딩 50곳 중 같은 값은 토큰으로 이동.

---

## 3. 공통 컴포넌트

| 컴포넌트 | 시안 | 앱 현재 | 차이/조치 |
|---|---|---|---|
| **흰 알약 CTA** | 높이 43(목록·패널 안) / 51~53(메인·발급), 반경 완전 알약(r=999), 흰 배경, 1pt `#444444`, 글자 15/400 검정 가운데, 아이콘 없음. 좌우: 메인 19pt(폭 365), 패널 안 28~38pt | `FMPrimaryButtonStyle` minHeight 52, r=24, 17 Bold, 패딩 18/12, 일부 화면 오른쪽 `→` 아이콘(R01 캡처) | `Capsule()`, 15 Regular, 테두리 추가, 높이 2종(`.regular 51`, `.compact 43`), 화살표 제거 |
| 보조 버튼 | 시안은 흰 CTA 외 보조 알약이 거의 없음(텍스트 링크 "노선 한 바퀴 보기") | `FMSecondaryButtonStyle` r=24, panel 85% | 사용처 정리 |
| **원형 아이콘 버튼** | 43x43, `#0A0A0ABF`, 1pt `#444444`, 아이콘 흰 선 12~15pt. 위치: 상단 y=61(safe area 바로 아래), 오른쪽 끝 x=343(우측 여백 16), 간격 11. 메인은 **2개**(기록·마이페이지) | 44x44, panel 85%, 테두리 없음, SF Symbol 19pt, 메인 **4개**(기록·마이·설정·카드), 왼쪽 "Focus Mate" 워드마크 | 테두리·투명도 맞춤, 크기 44 유지(터치 영역), 메인 버튼 수·워드마크는 화면 담당과 협의 |
| 여행 화면 버튼 | 44~46 정사각에 가까운 어두운 원(#080808CC+링), 좌상 일시정지·노선, 우상 따라가기(흰 테두리 원)·지도 | `.black.opacity(0.6)` 원 | 토큰화 |
| **하단 패널(시트)** | x=12, 폭 378(좌우 12), 하단 끝 y=854(화면 바닥 20pt 띄움, 홈 인디케이터 위로 떠 있음), 네 모서리 r=28, `#0A0A0A` + 1pt `#FFFFFF33`, 내부 padding 상24·좌우17·하28, 세로 gap 14~16 | `fmPanel` padding 22, r=24, 테두리 없음, 대부분 화면 하단에 붙임; 준비 시트는 시스템 sheet(`presentationCornerRadius(24)`, detent 410/440) | **떠 있는 카드형 패널**로: `.padding(.horizontal,12).padding(.bottom,20)` + r=28 + stroke. 시스템 sheet는 바닥에 붙으므로 시안처럼 하려면 커스텀 오버레이 패널로 전환 필요 |
| 패널 제목 줄 | 뒤로 `<` 아이콘(x=51) + 제목 18/700, 또는 제목 22/700 + 오른쪽 닫기 22pt | 화면마다 다름 | 공통 `PanelHeader` |
| **노선 배지** | 둥근 사각(반경 약 8~10), 높이 32~33, 폭 85~95. 배경 간선 `#2563EB` / 지선 `#168445`. 내부: 버스 아이콘 18x18(왼쪽 7pt), 종류 "지선/간선" 9/400 `#B5B5BA`계, 번호 17/700 흰색 | `Label("지선 2014", systemImage:"bus.fill")` 17 Bold, 색 없음 | 새 `RouteBadge(kind:number:)` 컴포넌트. 종류 문자열 "간선"/"지선" 외(광역·마을·공항 등 실데이터 존재) 색 매핑 정의 필요 |
| 후보 카드 | 약 178x140(가로 2장), 미선택 `#151B17`+17% 테두리, 선택 밝은 배경+검정 글자, r≈16~20 | 폭 190, r=16, padding 14 | 거의 일치 |
| **태그 칩** | 76x40 알약, 아이콘 16 + 이름 14/600, 간격 8, 새 태그 `+` 40x40 원(`#1A1A1A`, `#FFFFFF55`) | Capsule, tint 20/35% | 색 값·크기 맞춤 |
| 소리 칩 / 비활성 알약 | 107x52 `#1A1A1A` + 20% 테두리, 스피커 18 + 14/400 / `#252525` 알약 + 16/600 `#888888` | `.white.opacity(0.06)` | 시안 값으로 |
| 목록 행 | 343x67 `#111111`, 1pt `#444444`(선택 `#FFFFFF`) | 화면별 | 공통 행 스타일 |
| 확인 대화상자 | 커스텀 카드(358x246, `#0C0C0C`+25% 흰 테두리, 안에 흰 CTA 307x43) | 시스템 alert(R16) | 커스텀 대화상자 컴포넌트 필요(화면 담당과 공유) |

---

## 4. 지도

### 4-1. 시안 표현

- 3D 항공 사진(건물 질감·숲·한강) 위에 전면 `#00000055`(검정 33%) 덮개. 도로명·POI·Apple 로고 없음(목업 이미지).
- 시점: 비스듬한 조감(메인 약 45~60° 기울기), 여행 화면은 더 내려다보는 각도.
- 노선선은 지선 초록 `#168445` 굵게(약 4pt), 남은/다른 구간 `#FFFFFF44` 얇게, 정류장 점 흰색+검정 테두리, 버스는 초록 차량 일러스트(위에서 본 모습).

### 4-2. 앱 현황

| 위치 | 설정 |
|---|---|
| `SceneMapBackdrop.swift:36-50` (메인·준비·시간 등 배경) | `MapCamera(distance: 1_800, pitch: 50)`, `.mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))`, `colorScheme(.dark)`, 조작 불가 |
| `JourneyMapView.swift:47,74-79` (여행) | 테마 `.dark` → `.standard(elevation: .realistic, POI 제외)`, `.satellite` → `.hybrid(elevation: .realistic, POI 제외)`. 기본값 `JourneyMapState.theme = .dark`. 카메라 pitch 55, distance 1200 (`JourneyMapState.swift:58-59`) |

즉 기본 화면이 모두 **어두운 벡터 지도**라 시안의 사진 질감과 다르다. 위성 모드는 여행 화면 테마 시트에서만 선택 가능하고, `.hybrid`라 도로명이 겹친다.

### 4-3. 시안에 가깝게 만드는 방법

1. 스타일: 두 곳 모두 **`.imagery(elevation: .realistic)`** 를 기본으로. `.imagery`는 라벨이 없어 시안(글자 없음)과 가장 가깝다. `.hybrid`는 도로명·지명이 남아 가상 노선(BR-1)과 헷갈리므로 기본으로는 비권장.
   ```swift
   .mapStyle(.imagery(elevation: .realistic))
   ```
   서울 주요 지역은 Apple 3D 항공(Flyover) 데이터가 있어 `elevation: .realistic` + pitch에서 건물이 입체로 나온다. 데이터 없는 지역은 평면 사진으로 떨어진다.
2. 카메라: 메인 배경 `pitch 55~60`, `distance 900~1_200`(현재 1_800은 너무 멀어 건물이 작음), `heading`은 정류장마다 고정값(예: 노선 진행 방향) 또는 0. 여행 화면은 현재 55/1200 유지.
3. 덮개: Map 위에 `Color.black.opacity(0.33).ignoresSafeArea().allowsHitTesting(false)` 공통 `MapScrim` 뷰. 기존 `MainHomeView`의 위쪽 그라데이션(92%→0)은 사진 위에서 너무 진하므로 제목 영역만 약하게(또는 제목 줄 배경 `#00000088`로 대체). 일시정지·브리핑 덮개는 그대로 위에 겹침.
4. 노선·정류장 표현: `MapPolyline` 색을 노선 종류 색(지선 `#168445`/간선 `#2563EB`), 지난 구간과 남은 구간 분리(남은 구간 `white 0.27`), 정류장 `Annotation` 지난 정류장 `#777777`.
5. 테마 시트(`journey.map.theme.dark/satellite`): 기본값을 `satellite`로 바꾸고 `satellite`의 스타일을 `.imagery`로 변경, `dark`는 "어두운 지도" 대안으로 유지하는 방식이 기존 기능을 보존하면서 시안을 맞춘다.

### 4-4. 영향

- **성능·데이터**: 항공 사진 + 3D는 타일이 커서 첫 로딩·메모리·발열이 늘어난다(특히 여행 화면은 오래 켜져 있음). 네트워크 없을 때 사진이 비면 밑색만 보이므로 밑색 `#14191B`/`#182024` 바탕 유지가 중요(시안도 같은 밑색 레이어가 있음). 시뮬레이터에서는 위성 3D가 느리거나 비어 보일 수 있어 캡처 테스트가 불안정해질 수 있다.
- **출처 표기**: MapKit은 스타일과 무관하게 Apple Maps 로고·"법적 고지(Legal)"를 표시하며 숨기는 것은 약관 위반. 시안에는 없지만 반드시 남는다. 위치는 `safeAreaPadding(.bottom, …)`로 패널 위로 올리는 현재 방식 유지. 33% 덮개가 표기 위에 겹치면 가독성이 떨어지므로 기존 `PausedJourneyShade`처럼 표기 띠 부분만 덮개를 옅게 하거나, 덮개를 Map의 safe area 안쪽까지만 깔지 확인 필요. 위성 사진은 제3자 제공 표기가 Legal 안에 포함됨.
- **기존 테스트**:
  - `FocusMateTests/JourneyMapStateTests.swift:15` `XCTAssertEqual(state.theme, .dark)` — 기본 테마를 바꾸면 수정 필요. `:142-146` 선택 전환 테스트는 영향 없음.
  - `FocusMateUITests/JourneyMapUITests.swift:118-122` — `journey.map.theme.dark`가 선택돼 있다고 가정 → 기본값 변경 시 수정.
  - `JourneyMapAccessibilityUITests`, `AlightingFlowUITests`, `JourneyMapControllerTests`, `JourneyMapDisplayTests`, `PassFaceAccessibilityTests`도 테마/지도 문자열을 참조 → 기본값 변경 시 함께 확인.
  - 스타일(`mapStyle`) 자체를 단언하는 테스트는 없음 → `.standard→.imagery` 교체만으로는 단위 테스트 영향 없음. `PenParityCaptureTests` 캡처 결과는 달라짐(의도된 변화).
- 접근성: 지도는 이미 `accessibilityHidden` + 대표 요소라 영향 없음. "동작 줄이기"에서 카메라 애니메이션 끄는 기존 로직 유지.

---

## 5. 상태바 · 홈 인디케이터 · safe area

- **상태바**: 시안은 단순화 그림(“9:41” 12pt x=18,y=18 / 오른쪽 “▰”). 실제 앱은 **시스템 상태바를 그대로 사용**해야 하며 시안 글자를 재현하지 않는다. 필요 조치는 밝은 글자(라이트 콘텐츠) 보장뿐 — 앱은 지도 위 `colorScheme(.dark)`/어두운 바탕이라 현재도 흰 글자로 나옴(R01 캡처 확인). 루트에 `.preferredColorScheme(.dark)` 일괄 적용 여부만 점검(현재 PreparationView 시트 등 일부만 지정).
- **홈 인디케이터**: 시안 124x4 흰 막대 y=862(그림). 시스템이 그리므로 구현 불필요. `persistentSystemOverlays` 숨김 금지.
- **safe area 수치(iPhone 17 Pro, 402x874)**: 상단 inset 약 62pt, 하단 34pt.
  - 상단: 시안 원형 버튼 y=61 → **safe area 상단에 바로 붙임(추가 여백 0)**. 앱은 `.padding(.vertical, 8)`로 8pt 더 내려가 있음(캡처에서 버튼이 더 아래). 인사말 y=135, 제목 y=163.
  - 좌우: 원형 버튼·제목 여백 **16~24pt**(버튼 16, 텍스트 24), 메인 CTA 19pt, 패널 12pt(패널 내부 17). 앱은 20pt 일괄.
  - 하단: 메인 CTA 바닥 y=846 → 화면 바닥에서 28pt(= safe area 34 안쪽으로 6pt 침범, 홈 인디케이터 바로 위). 패널 바닥 y=854 → 화면 바닥 20pt(**safe area 무시하고 떠 있음**). 여행 화면 수치 바닥 y=834 → 40pt.
  - 규칙 제안: 배경 지도·덮개는 `ignoresSafeArea()` 전체, 상단 버튼은 safe area 기준 0, 메인 CTA는 `safeAreaInset` 하단에서 `-6`이 아니라 **화면 바닥 기준 28pt**(홈 인디케이터 없는 기기 대비 `max(bottomInset - 6, 16)`), 하단 패널은 화면 바닥 기준 20pt(`.ignoresSafeArea(edges: .bottom)` + `padding(.bottom, 20)`), 패널 안 마지막 버튼은 홈 인디케이터와 겹치지 않도록 패널 하단 padding 28 이상 유지.
- 기기 차이: SE(홈 버튼, 하단 inset 0)·Dynamic Island 없는 기기는 상단 inset 20~47. 고정 y가 아니라 safe area 기준 상대값으로 구현할 것.

---

## 핵심 공통 변경 5개

1. **글꼴 교체**: 서울알림체(2굵기) → Noto Sans KR 400/600/700 번들(OFL 1.1, 한글 11,172자 서브셋으로 약 5MB, 서울알림 제거 시 앱 크기 거의 동일). `FontCatalog`를 굵기 인자로 바꾸고 중복 `PreparationTypography`·SF 직접 사용 31곳 정리. 서울알림 유지 여부는 제품 결정 확인.
2. **색 토큰 확장**: `primary #F4F6F2→#FFFFFF`, `background→#090909`, 패널 테두리 `white 20%`, 지도 덮개 `black 33%`, 간선 `#2563EB`/지선 `#168445`, 보조 텍스트 2단계(`#B5B5BA`, `#AAAAAA`), 태그 4색을 시안 값(`#E8B64C/#A78BFA/#60A5FA/#4ADE80`)으로.
3. **CTA·원형 버튼·패널 규격 통일**: CTA = Capsule·흰 배경·`#444444` 1pt·15 Regular·높이 51/43·화살표 없음, 원형 버튼 = 75% `#0A0A0A` + `#444444` 테두리, 하단 패널 = 좌우 12·바닥 20 떠 있는 카드·r=28·흰 20% 테두리(시스템 sheet → 커스텀 패널).
4. **노선 배지 컴포넌트 신설**: 종류별 색 둥근 사각(높이 32, 버스 아이콘 + 종류 9pt + 번호 17 Bold)과 노선선·버스 아이콘을 같은 종류 색으로.
5. **지도 = 3D 항공 사진 + 33% 덮개**: `SceneMapBackdrop`과 여행 지도 기본을 `.imagery(elevation: .realistic)`, 메인 카메라 pitch 55~60·distance ~1,000, 공통 `MapScrim`. Apple 로고·Legal은 유지(덮개 옅게), 기본 테마 변경 시 `JourneyMapStateTests:15`·`JourneyMapUITests:118-122` 수정 필요.
