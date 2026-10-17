# Pen 시안 일치 작업 진행 기록

## 0단계 — 전 화면 공통 디자인 시스템 (2026-10-17)

근거: `diff/G-global.md`, A~F.md의 '공통' 절.

### 한 것

**글꼴**
- 서울알림체 2개(`SeoulAlrim-Medium/Bold.ttf`)를 지우고 Noto Sans KR 정적 3굵기를 번들했다: `Resources/Fonts/NotoSansKR-{Regular,SemiBold,Bold}.ttf`(각 2.5MB, 합 7.5MB. 이전 5.15MB).
  - Google Fonts 가변 원본 `NotoSansKR[wght].ttf`에서 fonttools로 wght 400/600/700 인스턴스를 만들고 서브셋했다. 남긴 문자: ASCII, Latin-1, 일반 문장부호(— … ‹ ›), 화살표, 도형, CJK 기호, 한글 자모, 현대 한글 11,172자, 전각 문자. 힌팅은 제거했다.
  - OFL 1.1 전문은 `NotoSansKR-OFL.txt`로 넣었다(번들 안 파일명 충돌을 피하려고 이름을 바꿨다). 출처와 가공 내용은 `SOURCE.md`에 적었다.
  - 등록은 Info.plist `UIAppFonts`로 한다. `FontCatalog.register()`, FocusMateApp 호출, PreparationView의 중복 `PreparationTypography`를 지웠다. BoardingPassView에 이름으로 박혀 있던 글꼴도 바꿨다.
- `FontCatalog`
  - `text(_:weight:relativeTo:)`. 굵기 인자는 `FMFontWeight`(`.regular/.semibold/.bold`)다. 예전 `bold: true`는 `weight: .bold`로 바꿨고, 서울알림 Medium은 Regular(400)로 옮겼다.
  - `style(_ textStyle, weight:)`: `.headline` 같은 SF 텍스트 스타일 자리를 iOS 기본 크기 그대로 Noto로 바꾼다.
  - `fixed(_:weight:)`: Dynamic Type 영향을 받지 않는 글꼴이다. 기존 `.system(size:)`·`@ScaledMetric` 자리와 카드·LCD 글자에 쓴다.
  - 시안 타입 스케일 토큰: `display·title·title2·heading·number·subhead·body·chip·callout·caption·footnote·micro·badge`.
- 앱의 SF 글자 약 50곳을 Noto로 바꿨다(`.font(.headline/.subheadline/.caption…)`, `.system(.title2, weight:)`, `.system(size:)`). SF Symbols 아이콘 크기용 `.system`과 진단용 1pt 투명 글자는 그대로 뒀다.
- `RootView`에 기본 `.font(FontCatalog.style(.body))`를 걸어서 글꼴을 지정하지 않은 Text·TextField도 Noto로 나온다.

**색 토큰(`FMDesign`)**
- 바꾼 값: `primary #FFFFFF`, `background #090909`, `panel #0A0A0A`.
- 추가한 값: `mapBase #14191B`, `panelStroke`(흰 20%), `mapScrim`(검정 33%), `rowFill #111111`, `chipFill #1A1A1A`, `tertiaryText #B5B5BA`, `hintText #AAAAAA`, `overlayLabel`(흰 64%), `ctaStroke #444444`, `ctaDisabledFill #252525`, `ctaDisabledText #888888`, `circleFill`(#0A0A0A 75%), `routeTrunk #2563EB`, `routeBranch #168445`, `routeRemaining`(흰 27%), `stopPassed #777777`, `stopStroke #0A0A0A`, 태그 `tagReading #E8B64C`·`tagStudy #A78BFA`·`tagWork #60A5FA`·`tagRest #4ADE80`.
- `FMDesign.routeColor(kind:)`: 간선은 파랑, 지선은 초록이다. 실데이터에 있는 마을 `#53B332`·광역 `#DC2626`·순환 `#D49B00`·공항 `#0284C7`·심야 `#3B4B8F`는 서울 버스색을 따른 제안값이라 디자이너 확인이 필요하다.
- `Color(hex:)` 도우미를 추가했다.
- 준비 화면 태그 칩 tint를 시안 4색 토큰으로 바꿨다. 분홍은 시안에 없어 기존 값을 유지했다.

**공통 컴포넌트**
- `FMPrimaryButtonStyle(size: .regular | .compact)`: 캡슐, 흰 바탕, `#444444` 1pt 테두리, 15pt Regular 검정 글자. 높이는 regular 51, compact 44다(시안은 43이지만 44pt 터치 기준을 지켰다). 비활성은 `#252525`/`#888888`.
  - 패널 안 CTA(시간 선택, 첫 정류장 검색, 진행 여정 카드, 분석)는 `.compact`로 바꿨다.
  - 승차권 "버스에 탑승하기 →"를 이 스타일로 옮겼다. "→"는 시안 글자라서 남겼다.
  - 메인 "여행 시작하기"의 화살표 아이콘을 지웠다.
- `FMSecondaryButtonStyle`: 모양을 캡슐로 바꾸고 테두리를 `#444444`로 맞췄다.
- `FMCircleButtonStyle(diameter: 43)`: 75% 검정 바탕, `#444444` 테두리, 15pt 흰 아이콘, 터치 영역 44 이상. 메인 상단 도구 4개에 적용했다. 버튼 수와 워드마크는 화면 단계에서 정한다.
- `fmPanel`: 흰 20% 테두리를 추가했다.
- `fmBottomPanel(floating:)`: 시안 하단 패널이다. 안쪽 여백은 위 24·좌우 17·아래 28, 반경 28, 흰 20% 테두리, 좌우 12pt, 바닥 20pt 띄움. 아직 어느 화면에도 적용하지 않았다(다음 단계 몫).
- `RouteBadge(kind:number:)`: 종류 색 둥근 사각형(높이 32, `@ScaledMetric`). 버스 아이콘 18, 종류 9pt, 번호 17 Bold. 낭독은 "지선 2014" 하나로 묶었다. 아직 화면에는 적용하지 않았다.
- `fmMapScrim()`·`FMMapScrim`: 검정 33% 균일 덮개다. 지도 안전 영역 바로 위 왼쪽 아래(Apple 지도 로고·법적 고지 자리) 150x40 영역만 흐리게 비워서 표기가 덮개에 가리지 않는다.

**지도**
- `SceneMapBackdrop`: `.imagery(elevation: .realistic)`, 카메라 distance 3,000·pitch 55(`cameraDistance/cameraPitch`), 공통 덮개, 밑색 `mapBase`. 노선선은 노선 종류 색으로 4pt.
- 여행 지도(`JourneyMapView`)
  - 기본 테마를 `.satellite`로 바꾸고 위성 스타일을 `.hybrid`에서 `.imagery(elevation: .realistic)`로 바꿨다. `dark` 테마는 대안으로 남겼다.
  - 공통 덮개를 깔았다.
  - 노선선은 지나온 구간을 노선 종류 색 5pt로, 남은 구간을 흰 27% 3pt로 그린다.
  - 지난 정류장 점은 `#777777`, 점 테두리는 `#0A0A0A`다. 버스 원 배경도 노선 종류 색으로 칠했다.
- `CourseJourney.routeKind`를 추가했다. `JourneyMapController`에 `travelledPoints`·`remainingPoints`·`isPassed(_:)`를 추가했다.
- 메인 위쪽 그라데이션(92%→0)을 35%→0으로 약하게 바꿨다. 공통 덮개가 생겨 과하게 어두워지지 않게 하려는 것이다.

**테스트 수정·추가**
- 기본 테마 변경을 반영했다: `JourneyMapStateTests`(test1 이름 `…_위성_…`, test14), `JourneyMapControllerTests`(test8·9·AC32 계열), `JourneyMapUITests`(AC19 이름 `…_위성과_…`, AC20·26~28), `JourneyMapAccessibilityUITests`(AC32·AC35). '바꾸기' 동작은 이제 dark를 누른다.
- `PassFaceAccessibilityTests`에서 `FontCatalog.register()` 호출을 지웠다.
- 새 테스트
  - `FontCatalogTests`: 3굵기 등록·한글/기호 글리프, 서울알림 제거와 OFL 동봉, UIAppFonts, 색 토큰.
  - `JourneyMapControllerTests.test20`: 지나온·남은 구간 분할, 지난 정류장, 노선 종류.

### 건너뛴 것(이유)
- 화면별 크기·배치: CTA 좌우 여백, 메인 버튼 수·워드마크, 패널을 떠 있는 카드로 바꾸는 일, 시스템 sheet를 커스텀 패널로 바꾸는 일, 준비·승차권 화면의 다른 직접 그린 버튼(“승차권 보기”, 출발 브리핑 "시작" 등)은 각 화면 단계의 몫이다.
- `RouteBadge`·`fmBottomPanel`의 화면 적용(TimeSelection 후보 카드·Preparation 머리줄 `Label(... "bus.fill")`)도 다음 단계로 넘겼다.
- 버스 아이콘을 차량 일러스트로 바꾸는 일과 여행 화면 원형 버튼 재질(`#080808CC`+링, C-2)은 C 단계에서 한다.
- 위젯·라이브 액티비티(FocusMateWidgets) 글꼴: 확장 번들에 글꼴을 따로 넣어야 하고 Pen 시안 범위 밖이라 SF를 유지했다.
- 내비게이션 바 제목(UIKit)과 시스템 alert 글꼴은 시스템 요소라 바꾸지 않았다.
- 기록 색(`PreparationTagColor.recordHex`)은 저장 데이터라 바꾸지 않았다. 바꾼 것은 화면 tint뿐이다.
- 노선선 남은 구간은 시안 값(흰 27%) 그대로라 항공 사진 위에서 다소 흐리다. 화면 단계에서 대비를 다시 볼 것.
- 시뮬레이터에서는 Flyover 3D 데이터가 일부 지역(성수역 근처)만 입체로 나오고 나머지는 평면 사진으로 떨어진다. 시안의 청회색 일러스트 톤과는 다르다(실사진이라 허용 차이).

### 테스트 결과
- 빌드: build-for-testing 성공(오류 0).
- 단위(focused): FontCatalogTests, JourneyMapStateTests, JourneyMapControllerTests, JourneyMapDisplayTests, PassFaceAccessibilityTests, CourseJourneyTests, AlightingSnapshotTests → **72개 실행, 실패 0**.
- UI(focused): JourneyMapUITests, JourneyMapAccessibilityUITests, BoardingFlowUITests, BoardingLargeTextUITests, LargeTextUITests, MainActiveJourneyCardUITests, Phase1FlowTests, TimeSelectionUITests → **64개 실행, 실패 0**.
- PenParityCaptureTests 전체: **38개 실행, 실패 0**(579초). 캡처는 `scratchpad/app/`에 갱신했다. 시안과 비교한 화면: R01·R06·R07·R11·R13. 공통 요소는 의도대로 들어갔다: Noto 글꼴, 흰 알약 CTA(테두리·15 Regular·화살표 없음), 원형 버튼 테두리, 항공 사진과 33% 덮개, Apple 로고·Legal 노출, 지선 초록 노선선, 패널 흰 20% 테두리, 태그 4색. 화면별 크기·배치 차이는 다음 단계에서 맞춘다.

### 남은 것(다음 단계가 알아야 할 것)
- 새 API: `FontCatalog.text/style/fixed`와 타입 토큰, `FMFontWeight`, `FMPrimaryButtonStyle(size:)`, `FMCircleButtonStyle`, `fmBottomPanel(floating:)`, `fmMapScrim()`/`FMMapScrim`, `RouteBadge(kind:number:)`, `FMDesign.routeColor(kind:)`, `Color(hex:)`.
- 공통 덮개가 `SceneMapBackdrop`과 여행 지도 안에 들어갔다. 화면마다 따로 깔던 어둡게 하는 막(준비·요약·브리핑·일시정지 그라데이션)은 이제 덮개와 겹친다. 각 화면 단계에서 시안 밝기에 맞게 줄이거나 지울 것.

## A단계 — R01·R02·R03·R04·R05·R26·R06 (2026-10-17)

근거: `diff/A.md`, `diff/G-global.md`. 캡처 비교 3회 반복(시안 PNG와 나란히 붙여 크기를 맞춘 비교 이미지, 패널 부분 확대 대조).

### 한 것

**공통(FMDesign)**
- 비활성 흰 알약 CTA를 시안 값으로 바꿨다: 채움·테두리 `#303A33`, 글자 `#C6D0C9`(`ctaDisabledFill/Text`). 0단계의 `#252525/#888888`은 "승차권 보기" 전용 값이라 공통 CTA에는 맞지 않았다.
- `RouteBadge`: `height` 인자(기본 32, 노선 칩은 38)를 추가했다. 아이콘은 외곽선 `bus`, 종류 글자는 `#B5B5BA`, 반경은 8이다.

**R01 메인(진행 여정이 없을 때)** `MainHomeView`
- 워드마크 "Focus Mate"를 지웠다. 상단 도구는 2개(기록 `doc.plaintext`, 마이페이지 `person`)이고 간격 11, 오른쪽 여백 16, 안전 영역 바로 아래에 둔다. **설정·카드 꾸미기 버튼은 메인에서 빠졌다**(마이페이지 `profile.settings`·`profile.customize`로 연다). `MainHomeView.customizeCard` 인자도 지웠다.
- 위쪽 그라데이션을 지웠다(공통 33% 덮개만 남김).
- 인사말은 `#E1E5E8`, 좌우 여백은 24다. 제목은 항상 "오늘은 어디에서 / 출발해볼까요?"이고, 줄마다 검정 53% 받침을 깔고 흰 28 Bold로 쓴다(낭독은 한 덩어리).
- 정류장 표시: 핀 아이콘을 지웠다. 라벨은 "현재 위치" 10pt `#B5B5BA`이고, 정류장 이름은 16 Bold 흰 글자에 검정 받침 상자를 둔다. 세로 위치는 시안 y≈437에 맞췄다. 방면 줄은 화면에서 지우고, `main.bound`는 보이지 않는 접근성 요소로 남겼다.
- "여행 시작하기"는 좌우 19pt, 화면 바닥에서 28pt 위에 둔다.
- 진행 여정 상태(R31~R34)는 여백 20·바닥 16과 기존 현재 정류장 묶음을 그대로 유지했다. 상단 도구 2개는 공통으로 적용된다.

**R02/R03 출발 정류장 검색** `InitialStationSearchView`, `RootView`
- 이 라우트에서는 내비 막대("Focus Mate")를 숨기고 RootView의 24pt 여백을 뺐다.
- 배경으로 지도를 깔았다. 정류장이 아직 없으므로 `SceneMapBackdrop(fallbackCoordinate:)`의 기본값(서울숲 근처)을 쓰고, 공통 덮개를 덮는다. 패널 높이만큼 지도 safe area를 줘서 Apple 로고가 패널 위로 오게 했다.
- 패널: 좌우 12, 바닥 20pt 위에 떠 있다. 반경 28, 흰 20% 테두리이고 높이는 내용에 맞춘다(큰 글자·키보드에서는 최대 높이까지 스크롤).
- 글자: 제목 20 Bold, 부제 12.5 `#B5B5BA`, 라벨 11 `#AAAAAA`. 안내·빈 결과·많음·로딩 문구는 12.5 `#AAAAAA`다.
- 검색칸: 높이 47, `#111111`, 반경 20이다. 입력 중이거나 검색어가 있으면 금색 `#D7B378` 1.5pt 테두리를 두르고, 아니면 `#444444`다. 검색어가 있으면 오른쪽에 파란 × 지우기 버튼(`search.clear`)이 나온다.
- 결과 행: 최소 높이 67, 반경 20, 선택 시 흰 테두리, 미선택 시 `#444444`. 이름은 15 Bold다. 부제는 한 줄 "ARS · ○○ 방면 승차장"(10pt `#B5B5BA`)이고, 모든 행 오른쪽에 조준점 아이콘을 둔다. 체크 아이콘은 지웠다.
- 선택 확인 문장 줄을 지우고 **확인 버튼 라벨을 그 문장으로 바꿨다**("성수역 · 성수동 방면에서 출발"). 선택 전 라벨은 "출발 정류장을 골라주세요"(제안값)다. `search.confirmation`은 보이지 않는 접근성 요소로 남겼다.

**R04/R05/R26/R06 시간 선택** `TimeSelectionView`, `SceneMapBackdrop`, `JourneyPlanDraft`
- 시스템 뒤로 버튼과 내비 막대를 숨겼다. 패널 안 왼쪽 위에 `<` 버튼(`time.back`, 44pt, `model.goBack()`)을 두고, 그 오른쪽에 제목 "시간부터 골라볼까요?"를 18 Bold 왼쪽 정렬로 둔다.
- 왼쪽 위 출발 블록을 지웠다. 대신 지도에 시안 표식을 그린다: 흰 물방울 핀(30x39, `#151A1D` 구멍)과 검정 상자 두 개("출발 정류장" 11pt `#E5EAE7`, 정류장 이름 16 Bold). `time.origin`은 보이지 않는 접근성 요소로 남겼다(값 = 정류장 이름, 라벨 = "출발 정류장, 방면"). 큰 글자 모드의 패널 안 출발 블록은 유지했다.
- 표식과 노선선이 덮개 위에 선명하게 보이도록, 시간 화면에서는 덮개를 지도 안 다각형(`MapPolygon`, 검정 33%)으로 깐다. Apple 로고·Legal은 지도 UI라 가려지지 않는다.
- 패널: 좌우 12, 바닥 20pt 위, 반경 28, 흰 20% 테두리, 높이는 내용에 맞춘다(최대 화면 78%, 큰 글자 85%).
- 시간 숫자는 "N min" 한 덩어리 32 Bold다. 60분 이상도 "120 min"으로 쓴다(시안 서체 규칙. 이전 "2 h 0 min" 표기는 버렸다).
- 눈금자: 검정 직사각형 상자 81pt, 1분 = 12pt. 5분 눈금은 20pt 흰 73%, 1분 눈금은 10pt 흰 33%, 굵기 1이다. 라벨은 10분마다(+범위 시작 15) "N min" 12pt `#BFC6C1`이고, 가운데 값이면 Bold다. 지시자는 삼각형 10x7과 바늘 2x23이다.
- 안내 문구는 11 `#AAAAAA`로 상자 바로 아래에 둔다.
- 후보 카드: 178x140, `#151B17`, 흰 17% 테두리, 반경 20. 안에 `RouteBadge`, 도착지 15 Bold, "N min · N정류장" 11 `#C2CCC5`를 둔다. km 표기와 체크 아이콘은 화면에서 지웠다(낭독 라벨은 그대로). 선택하면 `#F4F6F2` 바탕에 글자 `#111A13`/`#405147`이고, 배지 색은 유지한다. 가로 스크롤은 패널 끝까지 이어지고(첫 카드는 안쪽 21pt), 선택하면 그 카드로 스크롤한다(Reduce Motion이면 애니메이션 없이).
- 후보 없음: `#151B17` 상자(최소 83, 반경 14), 13pt `#C5D0C8` 가운데 정렬. 버튼 문구는 **"이 시간의 도착 후보가 없어요"**로 바꿨다(`ProceedState.noCandidates`).
- R06 지도 표현(기존 데이터만 씀): 노선을 고르면 카메라가 고른 구간(`RouteCandidate.leg.stopIndices`) 전체가 들어오게 이동한다(위 70pt·패널 높이 여백, 0.6초). 그리는 것은 노선 종류 색 2pt 선(흰 20% 외곽), 경유 정류장 흰 5pt 점(`#0A0A0A` 테두리), 도착 정류장 8pt `#0A0A0A` 점(노선색 테두리), 출발 위치의 노선색 버스 표식이고, 출발 핀은 숨긴다. 왼쪽 위에는 노선 칩(`#080808` 79% 판, 흰 14.5% 테두리, 반경 14, 안에 높이 38 배지)이 나온다.
- 준비·메인 등 다른 화면의 `SceneMapBackdrop` 동작은 바뀌지 않는다. 새 인자(`labelsOrigin`, `leg`, `fallbackCoordinate`)는 모두 기본값이 꺼짐이다.

**테스트 수정**
- 문구: `JourneyPlanDraftTests`, `JourneyPlanDraftCatalogTests`, `TimeSelectionUITests`의 후보 없음 문구.
- 시간 화면 뒤로가기를 내비 막대 대신 `time.back`으로 바꿨다: `FirstStationSearchUITests.testBackFromTimeScreenReturnsToMain`, `Phase1FlowTests`(목적지 왕복), `PreparationFlowUITests`(2곳), `BoardingFlowUITests`(마지막 되돌아가기 루프).
- 메인 설정·카드 버튼을 지운 것에 맞춰 바꿨다:
  - `Phase1FlowTests`: 왕복 목록에서 설정을 빼고, 설정 자리표시 검사는 마이페이지 → `profile.settings` 경유로 바꿨다.
  - `PreparationFlowUITests`: 재실행 목록에서 설정을 뺐다.
  - `BoardingLargeTextUITests.testF3`: 메인 버튼 목록을 3개로 줄였다.
  - `CardCustomizationFlowTests`: `open()`이 마이페이지 → `profile.customize`로 열고, 닫기·저장 뒤에는 `screen.profile`로 돌아오는지 본다(재실행 뒤는 `screen.main`).
  - `PenParityCaptureTests`: R20은 마이페이지 → 설정, R39~R42는 마이페이지 → 카드 꾸미기로 연다. R41은 저장 직후 마이페이지를 찍고, R42는 뒤로 가서 메인부터 시작한다.

### 건너뛴 것(이유)
- R02 "나를 위한 한 정거장" 소개 시트, 왼쪽 위 "Focus Mate / 버스로 떠나는 나만의 여행" 브랜드 블록, 검색 패널의 × 닫기: 앱에 없는 화면이라 만들지 않았다(BRIEF 범위 규칙). R02 캡처는 계속 빈 검색 화면이다.
- R06 "노선 한 바퀴 보기 · 12초 미리보기": 새 동작이라 만들지 않았다. 그래서 R06 패널이 시안보다 약 60pt 낮다.
- 시안의 예시·가상 문구: "현재 위치 · 가상 정류장"은 "현재 위치"로 줄였고, "실제 교통 정보가 아닌 앱 속 정류장 예시입니다."와 "도착 후보는 가상 노선의 예시입니다."는 넣지 않았다. 그만큼 R03~R06 패널이 시안보다 약 30pt 낮다.
- 결과 행 부제의 "서울 성동구"(자치구): 카탈로그에 자치구 데이터가 없다. ARS가 있으면 ARS를 그 자리에 둔다.
- 조준점 아이콘 탭 동작(지도에서 위치 보기): 새 동작이라 장식으로만 뒀다.
- 시간 화면 가장자리 스와이프 뒤로가기: 시스템 뒤로 버튼을 숨기면서 같이 꺼졌다. 패널 `<` 버튼으로 대신한다.

### 테스트 결과
- 빌드: build-for-testing 성공(오류 0), 마지막 수정 뒤에도 1회 다시 확인했다.
- PenParityCaptureTests A 화면 7개(R01·R02·R03·R04·R05·R26·R06): 3회 실행, 매번 **7개 실행, 실패 0**. 캡처는 `scratchpad/app/`에 갱신했다.
- focused 묶음 실행(사용자 지시로 도중에 중단): **101개 실행, 실패 1**.
  - 통과 100: FirstStationSearchUITests 8, DesignSyncRulerUITests 3, LargeTextUITests 2, BoardingFlowUITests 3, BoardingLargeTextUITests 2, CardCustomizationFlowTests 12/13, HarnessUITests 1, MainActiveJourneyCardUITests 14, ActiveJourneyMainUITests 3, FontCatalogTests 3, JourneyPlanDraftTests 17, JourneyPlanDraftCatalogTests 16, RouteCandidatesTests 16.
  - 실패 1: `CardCustomizationFlowTests.test11`. 재실행 뒤 `screen.main`이 아니라 `screen.profile`을 기다리도록 잘못 바꾼 테스트 코드 탓이다. 기대값을 `screen.main`으로 고쳤고, 다시 돌리지는 않았다.
- **마지막 회귀에서 확인할 것**(이번에 돌리지 못했거나 고친 뒤 다시 돌리지 않은 것):
  - `CardCustomizationFlowTests.test11`(수정 후)
  - `TimeSelectionUITests`, `Phase1FlowTests`, `PreparationFlowUITests`, `RouteDataUITests`, `StationSaveFailureUITests`, `SimulatorLargeTextRecoveryTests`, `StorageRecoveryFlowTests`, `NewJourneyUITests`, `ProfileUITests`
  - `PenParityCaptureTests`의 testR20_settings, testR38_profile, testR39_studio, testR40_studioPhotos, testR41_profileCustom, testR42_boardCustom

### 남은 차이
- 공통: 지도는 실제 항공 사진이다. 시안처럼 기울어진 3D 일러스트 톤이 아니고, 이 지역은 거의 평면으로 보인다. Apple 로고·Legal은 표기 의무라 남는다. 상태 표시줄과 홈 인디케이터는 시스템 요소다.
- R01: 시안과 거의 같다. 제목 받침 상자가 1~4pt 정도 어긋난다.
- R02: 소개 시트가 없어 화면 자체가 다르다(위 건너뛴 것).
- R03: × 닫기, 면책 문구, 자치구가 없다. 그 밖의 크기·색·간격은 1~2pt 안이다.
- R04·R05·R26: 면책 문구 몫(약 30pt)만큼 패널 윗변이 낮다. 패널 안 요소 크기·간격은 1~2pt 안이다. 출발 핀 위치는 지도 중심에 따라 정해져 시안(y≈131)보다 조금 아래에 온다.
- R06: "노선 한 바퀴 보기"가 없다. 카메라가 위에서 내려다보는 시점(.rect)이라 시안의 비스듬한 시점과 다르다. 버스 표식은 시안의 버스 그림 대신 노선색 둥근 사각형이다.
- 노선 종류 색(마을 `#53B332` 등)은 0단계에서 정한 제안값 그대로다.

## B단계 — R07·R08·R09·R10·R11 (2026-10-17)

근거: `diff/B.md`, `diff/G-global.md`. R21(지도 실패 배너)은 새 기능이라 제외. 캡처 비교 2회(시안 좌표와 캡처 pt 환산 대조).

### 한 것

**R07/R08 준비** `PreparationView`
- 시스템 뒤로 버튼·내비 막대를 숨기고, 제목 줄 오른쪽에 × 닫기(`preparation.close`, 22pt 글리프·44pt 터치, `model.goBack()` → 시간 화면)를 뒀다. 상단 노선 캡슐("지선 2014 · 성수동")을 지웠다.
- 시트: 지도 위에 떠 있는 고정 높이 443 패널(좌우 12, 화면 바닥에서 20, 반경 28, `#0A0A0A`, 흰 20% 테두리). 태그 선택 여부와 무관하게 높이가 같다. 안쪽 여백 위 24·좌우 17·아래 28, 간격 16. 큰 글자에서는 전체 높이 + 스크롤(기존 수준 유지).
- 태그 칩: 한 줄 가로 스크롤(`LazyHGrid` 2행 → `HStack`). 칩 높이 40, 아이콘 16(태그색)·간격 6·이름 14 SemiBold 흰색, 채움 13%/선택 33%, 테두리 53%/선택 100%. + 버튼 40 원, `#1A1A1A`, 흰 33% 테두리, 18pt.
- 할 일 입력칸: 높이 48, `#141414`, 반경 14, 16 Regular. 테두리는 항상 태그색(편집 중 1.5pt).
- 소리 칩: 높이 52 캡슐 `#1A1A1A`, 흰 20% 테두리, 아이콘 18 + 14 Regular. 소리 없음 아이콘은 시안의 스피커+×(lucide volume-x)를 `VolumeXShape`로 직접 그렸다.
- 승차권 보기: 높이 52, 16 SemiBold, 테두리 없음. 비활성 `#252525`/`#888888`, 활성 흰 바탕/`#0A0A0A`.
- **소리 기본값을 "버스" → "소리 없음"으로 바꿨다**(`PreparationDraft.sound = .none`).
- 지도: 소리 시트를 열어도 지도를 유지한다(R10). 태그 시트는 순검정 배경(R09). 고른 구간 `leg`를 `SceneMapBackdrop`에 넘긴다(`AppModel.legStopIndices(for:)` 추가).

**R09 태그 만들기 / R10 소리 선택**
- 시스템 `.sheet` 두 개를 준비 화면 위에 뜨는 커스텀 시트(`FloatingSheet`: 좌우 12, 바닥 20, 반경 28, 높이 403, 모달 낭독 + VoiceOver escape 닫기)로 바꿨다. 열려 있는 동안 준비 시트는 투명·터치 불가·낭독 숨김이다(상태 유지용으로 계층에는 남김). 닫으면 기존처럼 + 버튼/소리 칩으로 접근성 포커스를 돌린다. 시스템 시트의 아래로 끌어 닫기는 없어졌다(×로 닫음).
- R09: 순검정 카드, 흰 19% 테두리. 제목 20 Bold, × 23 얇게. 미리보기 57 높이·반경 16·아이콘+"새 태그" 19 Bold 견본색. 라벨 11 `#AAAAAA`. 이름칸 높이 47·`#111111`·반경 20·견본색 2pt 테두리·자리글 15 `#757575`. 아이콘/색 칸 43 높이·반경 12, 선택 흰 9%+흰 테두리, 미선택 `#111111`+`#444444`. 색 견본은 시안 저채도 값(`swatch`: `#D7B378 #82AAF2 #B49CE1 #91B9AB #D596A6`)으로 분리했다(칩 강조색 `tint`는 그대로). "태그 저장"은 `FMPrimaryButtonStyle(.compact)`.
- R10: 여백 위 22·좌우 17·아래 28, 간격 14. 제목 20 Bold. 셀 84 고정 높이·반경 16, 미선택 `#141414`+흰 13%, 선택 `#262626`+흰 2pt, 글자 13 Regular 흰색, 아이콘 22 light. 미리 듣기 44 높이·15 Regular·흰 20% 테두리, 소리 저장 52 높이·15 SemiBold `#0A0A0A`.

**R11 승차권** `BoardingPassView`, `BoardingPassContent`
- 노치 티켓 카드·`BoardMap` 이미지·상단 캡슐·시트 밖 버튼을 지우고, 지도(`SceneMapBackdrop`, 출발 정류장·노선·구간) 위 떠 있는 시트로 바꿨다(좌우 12, 바닥 20, 반경 28, 흰 20% 테두리). 시스템 뒤로 버튼을 숨기고 시트 안 "‹ 승차권" 머리줄(`board.back`)을 뒀다.
- **규칙 변경(시안 우선)**: 노선 배지(노선 종류 색, 버스 아이콘 + 종류 10pt `#B5B5BA` + 번호 20 Bold, `board.bus` 낭독 "지선 2014")와 여행 시간("60 min", `board.minutes`)을 화면에 표시한다.
- 출발/도착 두 열 가운데 정렬(라벨 10 `#B5B5BA`, 값 16 Bold). 구분선 2개(흰 9%/12%). 통계 3열 "여행 시간 / 정류장 / 이동 거리"(값 13 Bold). 거리 표기는 승차권에서만 "6.6 km"(공백). 라벨 "거리" → "이동 거리".
- "탑승 지금"·"날짜" 행과 `boardingText`·`dateText`·`stationFontSize`(글자 수별 크기 규칙)를 지웠다. `BoardingPassContent.init(details:)`로 단순화(now·timeZone 인자 제거), `busKind/busNumber/minutesText/taskLine` 추가.
- 태그·할 일은 한 줄 "독서 · 책 한 챕터 읽기" 15 Regular 왼쪽 정렬. `board.tag`/`board.task`는 값만 담은 숨은 요소로 유지.
- "버스에 탑승하기 →"를 시트 안 맨 아래로 옮겼다(좌우 16, compact 흰 알약).
- `BoardMap`·`TicketDots` 이미지 자산은 이제 쓰지 않는다(삭제는 하지 않음).

**테스트 기대값 수정(실행 안 함)**
- `BoardingPassContentTests`: init 변경, 날짜·승차·글꼴 크기 테스트 6개 삭제, 거리 "6.6 km", `taskLine`, 새 테스트 `testAC3_화면에_노선_배지와_여행_시간을_표시한다`. 옛 `testAC3_화면_필드에는_버스_번호와_여행_시간이_없다` 삭제.
- `PreparationDraftTests`(초기값 테스트) `.none`, `PreparationModelTests.test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다` 2곳 `.none`.
- `PreparationEditorUITests`: AC1 이름 `testAC1_InitialHubHasNoTagOrTaskAndNoSound`·"소리 없음", AC4(`board.back`, sound "none"), AC10(`preparation.close`, "소리 없음"), AC14(기본 선택 none, 취소 후 "소리 없음"), AC17(미리 듣기 전에 버스 선택), AC23("소리 없음").
- `BoardingFlowUITests`: 승차/날짜 검사 삭제, 번호 노출 금지 검사 → `board.bus` "지선 2014"·`board.minutes` "60 min" 확인, 승차권→준비 `board.back`, 준비→시간 `preparation.close`.
- `PreparationFlowUITests`: 준비→시간 뒤로 2곳을 `preparation.close`로.

### 건너뛴 것(이유)
- R21 지도 실패 배너: 새 기능(BRIEF 범위).
- 태그·소리 아이콘의 lucide 선형 모양(학사모·가방·연필·버스 정면·지하철 정면·나무 2그루): 자산 추가가 필요해 SF Symbols 가는 굵기로 근사했다. 소리 없음(스피커+×)만 직접 그렸다.
- 시트 끌어 닫기 제스처: 커스텀 시트로 바꾸며 뺐다(× 버튼·VoiceOver escape로 닫음).

### 테스트 결과
- build-for-testing 성공(앱·단위·UI 타깃 컴파일, 오류 0), 마지막 수정 뒤 1회 더 확인.
- PenParityCaptureTests R07·R08·R09·R10·R11: 2회 실행, 매번 **5개 실행, 실패 0**(각 약 2분 20초). 그 밖에 지도 원인 확인용 R07 단독 2회. 캡처는 `scratchpad/app/` 갱신.
- 그 밖의 단위/UI 테스트는 실행하지 않았다(사용자 지시).

### 마지막 회귀에서 확인(미실행)
- 단위: `BoardingPassContentTests`(전체), `PreparationDraftTests`(초기값 테스트), `PreparationModelTests.test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다`
- UI: `PreparationEditorUITests`(전체 — 시트 방식 교체로 AC5·AC9·AC24·AC20·AC19 포함), `BoardingFlowUITests.testConfirmOpensBoardingPassWithValuesBoardsToTagScreenAndBackWritesNothing`, `BoardingFlowUITests.testU3_인식_후_뒤로가면_전환이_취소되고_수정해_재인식하면_교체되며_메인에_안내가_뜬다`, `PreparationFlowUITests.testRapidDoubleTapOnProceedPushesPreparationOnlyOnce`, `PreparationFlowUITests.testReturningFromPreparationKeepsSelectionAndItSurvivesLeavingToMainInSameRun`, `BoardingLargeTextUITests`, `LargeTextUITests`, `SimulatorLargeTextRecoveryTests`, `DesignSyncRulerUITests`(준비 진입)
- `PenParityCaptureTests`: testR27_boardTag, testR42_boardCustom 등 준비·승차권을 지나는 캡처

### 남은 차이
- 공통: 실제 항공 사진(시안은 3D 일러스트), Apple 로고·Legal 노출.
- **R07·R08·R10·R11 지도**: 구간 색인(`leg`, 13개)은 넘어가는 것을 진단 글자로 확인했고 카메라도 구간 전체로 잡힌다. 그런데 캡처에는 정류장 점·버스 표식·밝은 노선선(R06 표현)이 나오지 않고 노선선만 보인다. 같은 `SceneMapBackdrop`이 시간 화면(R06, 선택 후 leg가 바뀌는 경우)에서는 점·표식을 그리므로, 처음부터 leg가 있는 채로 나타날 때 Map 주석이 안 그려지는 것으로 보인다. 원인 미확정 — 다음 지도 단계(C)에서 볼 것. 시안의 남은 구간 흰 44% 선·현재 정류장 14pt 원도 없다.
- R07/R08: 시트·칩·하단 줄 위치는 1~2pt 안. 칩 아이콘 모양(SF vs lucide).
- R09: 요소 위치 1~3pt 안. 아이콘 모양 차이.
- R10: 위치 1pt 안. 셀 아이콘 모양 차이(나무 1그루, 지하철 모양).
- R11: 시트 높이 시안 384 대비 약 1~3pt 안으로 맞춤(2회차 수치 조정). 배지 버스 아이콘은 SF `bus`라 시안 선형 아이콘보다 두껍다. 배지 녹색은 `FMDesign.routeColor(kind:)`(#168445) 사용.

## C단계 — R27·R12·R42·R28·R29·R13·R15·R16 (2026-10-17)

근거: `diff/C.md`(R27·R12·R42·R13·R15·R16), `diff/D.md`(R28·R29), `diff/F.md` 공통 C1~C7, `G-global.md`. R14(다음 정류장 패널)·R22(여행 중 소리)는 새 기능이라 제외. 속도 우선 지시로 캡처 비교 2회.

### 한 것

**PassFace(공용 카드 앞면)**
- 서울 점지도를 지웠다(`dotsOpacity` 인자 삭제, `PassDots` 에셋·`dotsAssetName`은 남김).
- **카드 번호 표시(BR-4 시안 우선 변경)**: `numberText` 인자, 왼쪽 아래 7pt "FM · 0842 3017". `AppModel.currentCardNumberText` 추가, `PassIdentity` 주석 갱신. 태그 화면·LCD 썸네일·마이페이지에 넘긴다(꾸미기 미리보기·발급 화면은 넘기지 않음 — F단계 몫).
- 배치 `Layout`: `.wide`(352x221, 마이페이지·발급·꾸미기 기본값)와 `.ticket`(270x158, 태그 화면). 글자 #F1F2F3, Focus Mate 10 Bold, 제목 18, 비접촉 아이콘 12x19(기본 카드 #D5DED7, 꾸민 카드 흰색), 테두리 #51565A 1pt.
- 꾸민 카드: "Focus Mate"·번호를 사진 위 어두운 알약(#080B0C 80%, 글자 #D3D6D8)으로 보인다.

**CardTagScreen(승차·하차 공용)**
- 배경 #101411, 단말기 237x286(r24, #525454), 표시줄 156x4(대기 #737C76/인식 #B2C9B9), LCD 201x125(r12, #5D625F/인식 #848F87), 태그 영역 149x76(#141617·#707874, 인식 #242829·#A6B6AC, 아이콘 `dot.radiowaves.right`+"카드를 여기에"/"태그 완료"), 아래 각인 "FOCUS MATE". 카드 270x158, 점선·깜박임 삭제.
- 세로 배치 고정: 승차 단말기 y=191·화살표 550·카드 593, 하차 단말기 246·카드 593, 아래 안내 772.
- LCD 문구: 승차 "작은 시작이 / 오늘을 바꿔요."(15 Bold)+현재 시각, 하차 "하차 준비"(18 Bold)+"아래 태그 영역에 카드를 대주세요"+오른쪽 위 노선 번호(`lcdTrailing`, AlightingTagView가 처음 나타날 때 잡아 둠).
- 인식 연출(R12·R29): 카드가 0.78배로 줄어 태그 영역 가운데로 이동(뷰에서 계산, 컨트롤러 `cardOffset`은 그대로), 오른쪽 아래 초록 체크 배지, LCD는 왼쪽 카드 썸네일 + 승차 "집중동행카드 ✓ / 나의 Focus Mate / 번호", 하차 "하차 완료 / 집중동행카드 / ✓". 올림 화살표는 인식 시 숨김.
- 하차 화면 문구 노출(R28): "여행의 마지막 정류장"/"하차 태그", "도착했어요. / 하차 태그를 해주세요."(27 Bold), "○○에 도착", 늘 보이는 "카드를 위의 단말기로 올려주세요"(인식 뒤 "하차 완료 · 이번 여행을 기록했어요"), "눌러서 태그하기" 밑줄 버튼(`alighting.tapToTag`, 기존 `activate`와 같은 동작). 시각 문구는 낭독에서 숨기고 기존 낭독 제목은 유지.
- 승차 안내는 카드를 눌렀을 때만 "카드를 위의 단말기로 올려주세요"(12pt #BDC8BF).
- **승차 화면 뒤로 버튼 숨김(AC-14 시안 우선 변경)**: 승차·하차 모두 내비 막대 숨김. 테스트 전용 `test.boarding.back`(DEBUG, `model.goBack()`)을 뒀다.
- `BoardingGeometry.tagAreaSize` 238x160 → 149x76, `cardWidth` 268 → 270.
- R42: 카드 저장 안내 띠(`savedCardNotice`)를 경로가 바뀌면 지운다(승차 화면에 남던 문제).

**여행 지도(R13)** `JourneyMapView`, `JourneyTimerView`, `BusTopMarker`(새 파일)
- 버스 표식: 위에서 본 초록 버스를 도형으로 그렸다(`BusTopMarker`, 30x57, 지선 몸체 #2E9E4F, 앞유리·뒷유리·옆창·미러). 진행 방향 회전 유지. R06·R07·R11 출발 표식도 같은 그림(24폭).
- 노선선: **시안대로 앞으로 갈 구간(버스→도착)을 노선색 3.5pt, 지나온 구간을 흰 45% 2.5pt**로 바꿨다(0단계는 반대였고 남은 흰 27% 선이 너무 흐렸다). 정류장 점 7pt(지난 #777777, 앞 흰색, #0A0A0A 1pt), 도착은 16pt 검은 원+노선색 2.5pt 테두리+흰 점.
- 덮개 33%를 지도 위 덮개 뷰 대신 지도 안 다각형으로 깔아 선·표식이 덮개 위에 선명하다.
- 카메라 기울기 55→40°, 거리 1200→1000m.
- 버튼: 일시정지 46 유리 원(`fmGlassCircle`: #080808 80%+흰 14.5%, 아이콘 14 Bold), 그 아래 노선 버튼 44(`journey.map.route`, 동작은 기존 지도 보기 시트 열기), 따라가기 43 흰 12.5%+흰 1pt 테두리 `scope`, 지도 테마 46 유리 원. 간격 10, 위 여백은 안전 영역 바로 아래.
- 하단 지표: 숫자 30 Bold 흰색 + 단위 15 Regular 흰 64%, 정류장 열 가운데·거리 열 오른쪽 정렬. 하단 진한 그라데이션 → 아주 약한 0→30%(150pt).

**일시정지(R15)·종료 확인(R16)** `JourneyTimerView`, `JourneyAbandonBar`, `JourneyView`
- 지도 흐림 12 + 검정 55% 균일(`PausedJourneyShade` 삭제). 일시정지 중 노선·따라가기·테마 버튼을 숨긴다.
- "일시정지됨" 18 Regular #BBBBBB, "현재 정류장으로" 캡슐(44, #0A0A0A 75%, 흰 38% 테두리, `journey.recenter`) → `JourneyMapController.recenter()`(일시정지 중에도 카메라를 버스로 되돌림, `JourneyMapState.recenter()`).
- 포기: 아래 "포기하기" 캡슐 → 오른쪽 위 빨간 X(46, #D13A42+흰 19%). 식별자 `journey.abandon`·라벨 "포기하기" 유지. `JourneyAbandonBar`는 safeAreaInset 대신 타이머 위 overlay라 일시정지 중 하단 지표 위치가 실행 중과 같다.
- 종료 확인: 시스템 alert → 직접 그린 창(`journey.abandon.dialog`, 검정 60% 배경, 358폭 #0C0C0C r24 흰 25% 테두리, 제목 22 Bold, 본문 13 #AAAAAA 두 줄, 세로 버튼 "계속 여행"(흰 캡슐+금색 바깥 테두리)·"그만두기"(#111111 흰 글자)). 버튼 식별자·동작·포커스 복귀 그대로, 모달 낭독·escape 닫기·열릴 때 제목에 포커스. 낭독 본문은 기존 `abandonMessage` 한 문장(`abandonMessageLines` 추가).

**B단계 버그(R07·R08·R11 지도에 정류장 점·버스가 안 보임) — 원인·수정**
- 원인: MapKit이 지도를 처음 만들 때 함께 받은 Annotation·MapPolygon을 그리지 않는다(MapPolyline은 그림). R06은 노선을 고른 뒤 나중에 더해져서 그려졌다. 캡처 확대로 R07이 이미 `detailed` 분기(2pt 선+흰 외곽)였음을 확인했다.
- 수정: `SceneMapBackdrop`·`JourneyMapView`에서 표식·덮개 다각형을 지도가 나타나고 0.6초 뒤(`showsMarks`)에 더한다. 2회차 캡처에서 R07·R11에 정류장 점·버스·덮개가 나온다. R07 시안처럼 노선 전체를 흰 44% 1.5pt 선으로 고른 구간 아래에 깐다.

**진단 버튼**: 여행 화면 수동 시계 버튼·메인 저장 실패·기록 화면 진단 버튼 배경을 검정 → 검정 2%로 바꿨다(터치 영역은 `contentShape` 그대로).

**테스트 기대값 수정(실행 안 함, build-for-testing 컴파일만 확인)**
- `BoardingRulesTests`: 태그 영역 149x76·카드 270x158 기준으로 다시 계산(29.9%=22.72, 30.1%=22.88, BR-7 교집합 149x38=0.5, 활성 위치 카드 위쪽 45.2, 폭 270/149/120/300). 정확히 30% 경계 검사만 이진 소수 오차를 피하려고 100x50 영역으로 본다.
- `BoardingTagControllerTests`: rig 기하 (−60.5,260,270,158)/(0,0,149,76). 드래그 −240 접촉·−150 미접촉 유지, activate 기대값 (0, −214.8)(정밀도 비교).
- `UITestLaunchSupport`: `alert(titled: "여행을 그만둘까요?")`와 `alertButton("journey.abandon.*")`이 직접 그린 창을 찾는다.
- `JourneyAbandonUITests.testAC21`: alerts.count → 창 개수.
- `BoardingFlowUITests`: 승차 화면 → 승차권 이동을 `test.boarding.back`으로(3곳), 내비 버튼 0개 확인 추가.
- `AlightingFlowUITests.testAC6_7_8_9_21`: 안내 문구 "카드를 위의 단말기로 올려주세요".
- `JourneyMapUITests.testAC22`·`testAC25`, `JourneyMapAccessibilityUITests.testAC34`: 일시정지 중 도구는 "없거나 잠김".
- `PenParityCaptureTests.testR16_endConfirm`: `journey.abandon.dialog`를 기다린다.

### 건너뛴 것(이유)
- R14 다음 정류장 패널, R22 여행 중 소리: 새 기능(BRIEF).
- R13 노선 전체선(도착 너머까지 흰 선): 여행 지도에 노선 전체 좌표를 붙이는 데이터 작업이 필요해 뺐다(준비·승차권 지도에는 넣음).
- 노선 버튼의 다음 정류장 패널 동작: 지시대로 기존 지도 보기 시트를 연다.
- R15 "예시 여정 · 실제로 저장하지 않아요.": 예시 문구(BRIEF).
- 승차 화면 이탈 경로: 뒤로 버튼을 숨기면서 사용자 이탈 경로가 없어졌다(시안대로). 테스트만 진단 버튼을 쓴다.
- 꾸미기 미리보기·발급 화면 카드 번호: F단계 화면이라 `numberText`를 넘기지 않았다.

### 테스트 결과
- build-for-testing 2회 성공(앱·단위·UI 타깃, 오류 0).
- PenParityCaptureTests R27·R12·R42·R28·R29·R13·R15·R16·R07·R11: 2회, 매번 **10개 실행, 실패 0**(각 약 226초). 캡처는 `scratchpad/app/` 갱신.
- 그 밖의 단위/UI 테스트는 실행하지 않았다(사용자 지시).

### 마지막 회귀에서 확인(미실행)
- 단위: `BoardingRulesTests`(전체), `BoardingTagControllerTests`(전체), `PassFaceAccessibilityTests`, `PassFaceAssetTests`, `PassIdentityTests`, `JourneyMapStateTests`, `JourneyMapControllerTests`
- UI: `BoardingTagUITests`(전체 — 태그 영역·카드 크기 변경으로 끌기 좌표 영향), `BoardingFlowUITests`(전체), `BoardingLargeTextUITests`, `AlightingFlowUITests`(전체), `AlightingTag` 관련 UI, `JourneyAbandonUITests`(전체), `JourneyLifecycleSafetyUITests`, `RouteDataUITests`, `JourneyResumeUITests`, `JourneyMapUITests`(전체), `JourneyMapAccessibilityUITests`(전체), `JourneyTimerUITests`, `DepartureBriefingUITests`, `ProfileUITests`, `CardCustomizationFlowTests`(저장 안내 띠), `LargeTextUITests`, `SimulatorLargeTextRecoveryTests`
- `PenParityCaptureTests`: testR33_resumed, testR38_profile, testR39~R41, testR34_alightResume, testR06_timeDest·testR08·testR10(지도 표식 지연 적용)

### 남은 차이
- 공통: 실제 항공 사진(시안은 3D 일러스트), Apple 로고·Legal.
- R27·R42: 1~2pt 안. 태그 아이콘은 SF `dot.radiowaves.right`. LCD 시각은 현재 시각(시안 20:00).
- R12·R29: LCD 썸네일이 100x58(시안 100x64, 카드 비율 유지). 하차 머리 문구가 시안보다 약 2~3pt 아래.
- R28: 1~3pt 안.
- R13: 시안 대비 지도 시점·축척 차이(항공 사진). 노선 전체선 없음. 이번 캡처 화면 안에는 정류장 점이 들어오지 않았다(정류장 간격이 넓음, 표식 자체는 R07·R11에서 그려짐 확인).
- R15: 흐린 지도가 시안보다 조금 밝다. 하단 지표·버튼 위치는 1~3pt 안.
- R16: 창 세로 위치·높이 2~4pt 차이, 뒤 흐림 화면 동일.
- R07·R11: 점·버스·덮개는 나오지만 시안의 현재 정류장 14pt 원은 없다. 지도 범위가 시안보다 넓다(구간 전체 맞춤).

## D단계 — R34·R17·R30·R18 (+R27 스와이프 뒤로가기) (2026-10-17)

근거: `diff/D.md`(R34·R17·R30·R18), `G-global.md`. R25(홈 메모 카드)와 R18의 "방금 마친 여행 기록" 카드는 새 기능이라 제외. 속도 우선 지시로 캡처 비교 2회.

### 한 것

**R34 도착 여정 메인** `MainHomeView`, `MainActiveJourneyView`, `ActiveJourneyCardContent`, `JourneyLifecycleText`
- 카드 제목 "마지막 태그가 남았어요."(`arrivedTitle`), 버스 줄 오른쪽 "하차 태그 대기" 14 Bold 흰색(`awaitingAlightTag`, `ActiveJourneyCardContent.statusText`. 멈춘 여정은 같은 자리에 남은 시간 — R31 시안과 같은 구조). 낭독 라벨에 상태가 들어간다.
- 하차 버튼 문구 "이전 여정 이어가기 →"(낭독 "이전 여정 이어가기", `alightButton`/`alightButtonLabel`). 식별자 `open.alighting`과 동작(기존 하차 흐름)은 그대로.
- 카드(진행·도착 공용 컴포넌트): 반경 20, 테두리 없음, 안쪽 위 21·좌우 20·아래 20. 제목 21 Bold 흰색 → 할 일 17 Bold `#AAAAAA` → 버스 13 `#C1CBC3` → 노선 12 `#A6B1A8` → 51pt 흰 캡슐 버튼. 간격은 Noto 줄 높이를 뺀 17.5/14/5/25.
- **"새 여정 시작" 노출(AC-21 시안 우선 변경)**: `mainMenuDestinations` 필터 제거, `confirmNewJourney`의 도착 여정 거부 조건 제거(도달 정류장 = 저장된 도착 정류장, 기록 없음). 누르면 기존 새 여정 확인 창. 버튼 스타일 `FMNewJourneyButtonStyle`(44, #0A0A0A 85%, 흰 21% 테두리, 13pt) — 진행 여정 공용, 카드와 간격 5.
- 도착 여정일 때만: 좌우 여백 18, 버튼 바닥 화면 28pt 위, 현재 정류장 묶음 숨김(`screen.main`·`main.currentStation`·`main.bound`는 보이지 않는 요소로 유지), 지도 핀 없음, 제목 "{정류장}에서, / 오늘은 조금 느긋하게.".

**R18 하차 후 메인**
- 제목: 마친 기록이 있는 기본 메인이면 "{정류장}에서, / 오늘은 조금 느긋하게."(처음 메인 R01은 기본 문구). "방금 마친" 상태를 새로 두지 않고 기존 기록 유무로 정했다.
- 기본·도착 메인의 맨 아래 버튼 바닥을 화면 바닥 28pt 위로(전에는 안전 영역 때문에 34pt). R01에도 적용된다.

**R17·R30 요약** `AlightingSummaryView`, `AppModel+Alighting`, `SceneMapBackdrop`
- 문구 "여행을 마쳤어요."(예시 제거). 글꼴: 하차 완료 12(체크 11 semibold, 간격 10, `#A6CCAF`), 제목 26 Bold 흰색, 부제 13 `#9FA6A0`, 태그 12, 할 일 21 Bold, 라벨 11 `#929B95`, 값 15 Bold, 경로 "2014번 · …" 11 `#8F9892`, 메모 머리 14/선택 11 `#858E87`. 두 항목은 첫 열 139pt 고정. 구분선 흰 15% 1pt. 간격은 시안 줄 위끝 기준에서 환산.
- 패널: 화면 바닥 20pt 위(홈 표시줄 영역까지), 반경 26, 흰 20% 테두리, 안쪽 위 28·좌우 27, 버튼 좌우 26·아래 24, 43pt 버튼(compact). 최대 높이는 위끝 y=124까지. 내비 막대 배경 숨김.
- 메모(펼친 모양만, R30): 칸 위 라벨 "기억하고 싶은 생각" 12 `#CCCCCC`(placeholder는 비움, 낭독 라벨 "메모" 유지), 칸 #151A16·반경 12·`#5C655F` 1pt·최소 91, 글자 13·줄 간격 20, 입력 중 바깥 3pt 금색 `#D7B378` 2pt, 글자 수 10 `#929B95`. 칸 빈 곳을 눌러도 입력 시작.
- 지도: `AlightingSummary`에 `routeID`·`legStops`(하차 때 `RouteLegFinder`로 구간 계산, 카탈로그 없으면 nil)를 더하고, `SceneMapBackdrop(finished: true)`로 구간 선(흰 45% 2.5pt — 시안 27%는 항공 사진에서 안 보여 C단계 지나온 구간 값 사용), 지난 정류장 점 5pt `#777777`, 도착 10pt 고리, 도착 정류장의 초록 버스(`BusTopMarker` 20폭)를 그린다. 위쪽 30% 검정 막은 지웠다(덮개 중복).

**R27 승차 화면 가장자리 스와이프 뒤로가기 복원** `NavigationPopBlocker.swift`, `CardTagScreen`
- `NavigationEdgeSwipeEnabler`: 보이는 동안 `interactivePopGestureRecognizer`의 위임을 바꿔 막대 숨김 상태에서도 시작하게 하고, 떠날 때 원래 위임·활성 상태로 되돌린다. 승차 태그에만 붙이고, 태그 단계가 `ready`/`failed`일 때만 시작한다(인식·전환 중 금지). 뒤로 버튼은 계속 숨김, `test.boarding.back` 그대로. 하차는 기존 `NavigationPopBlocker` 유지.

**테스트 기대값 수정(실행 안 함, 컴파일만 확인)**
- `AlightingModelTests`: 요약 비교는 기록 값만(노선·구간 제외), `testAC21_도착_여정의_새여정_확정은_도착_정류장에서_여정을_지우고_기록은_남기지_않는다`(.done, 쓰기 1, 기록 0, 현재 정류장 서울숲 입구), `testAC21_도착_여정이어도_메뉴에_준비가_남는다`.
- `RouteDataLifecycleModelTests.testConfirmNewJourneyAfterArrivalEndsJourneyRegardlessOfAvailability`(.done, 시도 1).
- `ActiveJourneyCardContentTests.testAC24_…`: 제목 "마지막 태그가 남았어요.".
- `AlightingFlowUITests.testAC21_도착_여정_카드에는_하차_버튼과_새_여정_시작이_있다`, `MainActiveJourneyCardUITests`(제목 문구, `testAC24_도착_여정은_하차_버튼과_새_여정_시작이_있다`), `NewJourneyUITests.testAC24_도착_여정에도_새_여정_시작이_있고_확인_창을_거친다`(확인 창 → 유지하기 → 쓰기 0).

### 건너뛴 것(이유)
- R18 "방금 마친 여행 기록" 카드·R25 홈 메모 카드: 새 기능.
- R17 메모 접기/펼치기, R30 "메모 저장" 별도 버튼: 새 동작. 그래서 R17도 메모 칸이 펼쳐져 패널이 시안보다 약 140pt 높고(위끝 ≈170 vs 308), R30은 "메모 저장" 몫만큼 칸·글자 수가 시안보다 아래, 버튼과의 간격은 24.
- R30 크기 조절 손잡이: 웹 textarea 흔적(D.md 권장대로 생략).
- 시안 "현재 위치 · 가상 정류장": A단계처럼 "현재 위치"만.

### 테스트 결과
- build-for-testing 성공(앱·단위·UI 타깃, 오류 0). 2회차는 `xcodebuild test`로 빌드 포함.
- PenParityCaptureTests R34·R17·R30·R18: 2회, 매번 **4개 실행, 실패 0**(각 약 65초). 캡처 `scratchpad/app/` 갱신.
- 그 밖의 단위/UI 테스트는 실행하지 않았다(사용자 지시).

### 마지막 회귀에서 확인(미실행)
- 단위: `AlightingModelTests`(전체), `ActiveJourneyCardContentTests`, `RouteDataLifecycleModelTests`, `JourneyLifecycleModelTests`, `BoardingModelTests`(confirmNewJourney 경로)
- UI: `AlightingFlowUITests`(전체 — 요약 메모·글자 수 포함), `MainActiveJourneyCardUITests`(전체), `NewJourneyUITests`(전체), `ActiveJourneyMainUITests`, `JourneyLifecycleSafetyUITests`, `WidgetEntryUITests`, `JourneyResumeUITests`, `BoardingFlowUITests`·`BoardingTagUITests`(가장자리 스와이프 위임 교체), `BoardingLargeTextUITests`, `LargeTextUITests`, `SimulatorLargeTextRecoveryTests`, `Phase1FlowTests`, `StorageRecoveryFlowTests`, `CardStorageFlowTests`, `RouteDataUITests`
- `PenParityCaptureTests`: testR01_main(바닥 여백 변경), testR31_resumePrev·testR32_newConfirm·testR33_resumed(공용 카드·새 여정 버튼 변경), testR19_records

### 남은 차이
- 공통: 실제 항공 사진, Apple 로고·Legal.
- R34: 1~2pt 안. 할 일·정류장은 데이터 차이.
- R18: 기록 카드 없음(제외). 제목 첫 줄은 현재 정류장 전체 이름("서울숲 입구에서,").
- R17: 메모 칸이 펼쳐진 채라 패널이 높고 지도 보이는 영역이 좁다. 지도 축척이 시안보다 넓어 구간이 작게 보이고, 선은 흰 45%(시안 27%).
- R30: "메모 저장" 버튼·금색 초점 테두리(캡처는 키보드를 내려 초점이 없음) 외 1~3pt 안. 패널 위끝 ≈170(시안 124, 버튼 몫).
- E단계 참고: 진행 여정 카드·"새 여정 시작" 버튼 스타일은 공용이라 R31~R33에도 이미 적용됐다. 멈춘 여정의 제목 문구·현재 정류장 묶음·좌우 여백·지도 핀·바닥 여백은 손대지 않았다(`MainHomeView.isArrived` 분기).

## E단계 — R31·R32·R33·R19·R23·R24·R20 (2026-10-17)

근거: `diff/E.md`, `G-global.md`. 속도 우선 지시로 캡처 비교 2회. 기록·분석의 "지도 위 한 패널 + 잔디/분석 탭 전환 + × 닫기" 재구성과 설정 화면 신규 구현은 제외(BRIEF 범위).

### 한 것

**R31 멈춘 여정 메인** `MainHomeView`
- 진행 여정(멈춘·도착) 공통 배치로 묶었다(`isActive`): 좌우 18, 버튼 바닥 화면 28pt 위, 현재 정류장 묶음 제거(`screen.main`·`main.currentStation`·`main.bound`는 보이지 않는 요소로 유지), 지도 정류장 핀 없음, "새 여정 시작"은 카드 아래 5pt.
- 멈춘 여정 제목 "{정류장}에서, / 잠깐, 나에게 집중해요."(줄별 검정 53% 띠는 A단계 공용). 카드·버튼 모양은 D단계 공용 그대로.

**R32 새 여정 확인 창** `MainActiveJourneyView`(`NewJourneyDialog`), `RootView`
- 시스템 alert → 직접 그린 창(`main.newJourney.dialog`): 검정 60% 배경, 화면 전체 세로 가운데, 좌우 22, #0C0C0C 반경 24 흰 25% 테두리, 제목 23 Bold, 본문 13 #AAAAAA(문구 그대로 한 문장, 자연 줄바꿈), 버튼 순서 "이전 여정 유지하기"(흰 캡슐+금색 바깥 테두리) 위 → "새 여정 시작"(#111111 흰 글자, 빨강 아님) 아래, 간격 13.
- 동작 동일: 유지 = 닫기만, 새 여정 = 닫고 `confirmNewJourney()`. 식별자 `main.newJourney.keep/confirm` 유지. 모달 낭독, escape = 유지, 열릴 때 유지 버튼에 초점. 창은 NavigationStack 바깥에 overlay로 띄운다(위젯 진입 등 어느 경로에서도 전체를 덮음).

**R33 이어간 여정**: C단계(R13) 결과로 일시정지·노선·따라가기·테마 버튼, 노선선 색 분리, 정류장 점, 도착 표시, 버스 그림, 하단 그라데이션, 지표 정렬이 이미 맞다. 코드 변경 없음.

**R19 기록** `RecordsView`, `RecordsPanelChrome.swift`(새 파일), `RecordsCalendar`(`RecordDay.weekdayName`)
- push·시스템 뒤로 버튼은 그대로 두고, 120pt 지도 띠 → 화면 전체 지도 + 떠 있는 패널(`RecordsPanelScreen`: 위끝 y≈116, 좌우 12, 바닥 20, 반경 28, 흰 20% 테두리, 안쪽 23, 내비 막대 배경 숨김).
- 탭 모양(`RecordsTabBar`): #181C19 반경 10·안쪽 3, 선택 #303B34 반경 8, 12pt, "분석 보기" → "분석"(누르면 기존처럼 분석 push).
- 안내 "날짜를 눌러 둘러보세요." 11pt(예시 접두어 제외), 연도 머리줄 "2026년의 여행" 18 Bold + 오른쪽 "‹ 올해 ›"(`records.year.current` = 올해로), 요약 #C3CDC6, 연도 칩 줄(64x44, 선택 #F3F6F3/#0A0A0A, `records.year.<연도>`) — 연도 메뉴(`records.year.picker`)를 대체.
- 잔디 상자 #0B100D 반경 6 흰 15% 테두리, 월 라벨을 실제 1일이 있는 주 위치에, 요일 열 32pt, 칸 약 4pt·간격 1.5, 선택 날짜는 칸보다 3pt 큰 흰 테두리. 범례는 상자 밖 10pt #B8C4BC "하루 여행 시간 … ■■■■■ 적음 → 많음".
- 구분선(흰 14%), 날짜 머리줄 "10월 17일 토요일" + 오른쪽 "N회 · 합계"(11pt #C3CDC6), 기록 줄 "할 일 16 Bold / 출발 → 도착 11pt / 태그 · 25 min · 버스 11pt 태그 색", 줄 구분선 제거. 낭독 라벨은 시각·경로를 포함해 유지.
- "다음 여행 시작하기"(compact 흰 알약, `records.startNext`): 진행 여정이 없을 때만 보이고 누르면 경로를 비운 뒤 `startTripFromMain()`(메인 "여행 시작하기"와 같은 흐름). 진행 여정이 있으면 메인 확인 창을 거쳐야 하므로 숨긴다.

**R23/R24 분석** `RecordsAnalyticsView`
- 같은 떠 있는 패널. 기록이 하나도 없으면 패널 높이를 내용에 맞춰 아래에 붙인다(R24, `ViewThatFits`).
- 탭 줄 표시(분석 선택). "잔디"는 `analytics.tab.records` = 기록으로 돌아가기(dismiss, 기존 뒤로와 같음).
- 기간 줄 한 줄: "주간/월간" 11pt(선택 #303B34 반경 8 높이 38, 누름 영역 44) + 오른쪽 "‹ 이번 달 ›" 11pt #CBD6CE.
- 요약 세 열 105/91/나머지, 라벨 10pt, 평균은 "1 h 30 min" 형식. 도넛: 두께 19, 바탕 #27332B, 조각 사이 틈, 가운데 "16h 35m"/"0 min" 20 Bold(`ProfileTimeText.compact` 추가). **빈 상태에서도 빈 고리 + "0 min 합계"**.
- 범례: 6x20 막대, 이름 12 #E8EEE9, 값 10pt "1 h 15 min · 50%"(횟수는 낭독에만), 줄마다 흰 9% 선, 폭 156.
- 비교 문구 "지난달/지난주 같은 기간보다 N min 많이/적게 여행했어요." #C3CDC6. 차트 제목 "날짜별 여행 시간"(태그 선택 시 "{태그} 여행 시간").
- 빈 상태 문구 "첫 여행을 마치면 태그별 시간과 활동이 여기에 모여요."를 도넛 아래 13pt로. 기록이 하나도 없으면 비교·날짜별·인사이트 섹션을 숨긴다.
- 고정 "다음 여행 시작하기"(R19와 같음).

**R20 설정(자리표시)** `DestinationScreen`(`SettingsPlaceholderView`)
- 자리표시를 시안 패널 모양으로: 지도 배경, 아래 시트(좌우 12, 바닥 25, 반경 28, 흰 20% 테두리), "설정" 22 Bold(`screen.settings`), "Focus Mate" 15 #AAAAAA, **"데이터 출처" 진입(`settings.dataSource` → `.dataSource`)**. 내비 제목 제거, 뒤로 버튼 유지.
- **F단계 참고**: 마이페이지의 '데이터 출처' 줄(`profile.dataSource`)은 아직 그대로다. F단계에서 지우고 관련 테스트(DataSourceUITests 진입 경로 등)를 설정 경유로 바꿀 것.

**테스트 기대값 수정(실행 안 함, build-for-testing 컴파일만 확인)**
- `UITestLaunchSupport`: `alert(titled: "새 여정을 시작할까요?")` → `main.newJourney.dialog`, `alertButton("main.newJourney.*")` → 직접 그린 창의 버튼.
- `PenParityCaptureTests.testR32_newConfirm`: `main.newJourney.dialog`를 기다린다.
- `Phase1FlowTests.testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations`: 설정은 자리표시 버튼 수 검사 대신 `settings.dataSource` 존재 확인.

### 건너뛴 것(이유)
- R19/R23/R24 한 패널 + 탭 전환 + × 닫기: 화면 재구성(BRIEF). 탭은 모양만, × 대신 시스템 뒤로 버튼.
- R19 "확대해서 보기", "날짜 찾기"(날짜 선택기): 새 기능. 그만큼 범례~구분선 간격이 시안보다 짧다.
- R19 기록 줄의 "메모 남기기/수정" 버튼: 시안에는 없지만 메모 편집의 유일한 진입이라 11pt로 작게 남겼다.
- R23 태그별 집계를 선택 기간으로 바꾸기: 동작 변경이라 보류. 그래서 제목에 " · 전체 기간"을 남겼다(시안은 "태그별 여행 시간").
- R23 "태그로 활동 보기" 칩: 시안에 없지만 지우면 태그 거르기 기능이 사라져(테스트 `analytics.tag.*`) 안내 문구만 빼고 작은 칩으로 남겼다.
- R23/R24 "예시 기록으로 보는 여행 분석입니다.", R19 "예시 기록 · ": 예시 문구(BRIEF). 그래서 R24 패널이 시안보다 약 30pt 낮다.
- R20 앱 소개 "가상 지도와 30초 압축 시간의 프로토타입입니다.", "이 데모는 …", 동작 줄이기 체크, "서울 버스 유형 보기"·서체 출처 링크: 프로토타입 문구이거나 새 기능. 그래서 패널이 시안(303)보다 낮다(약 190).
- R31·R32 금색 초점 고리(R33 일시정지 둘레 포함)는 R32 확인 창의 기본 버튼에만 그렸다. R33 재개 직후 초점 이동은 접근성 동작 변경(PRD FR-12)이라 보류.
- R33 하단 지표: R33 시안(15 = 28 Bold + min 15 #AAAAAA, 정류장 19/11, km 13 #AAAAAA, 라벨 10 #B5B5BA)과 R13 시안(30 Bold + 단위 15 흰 64%, 라벨 12)이 같은 화면인데 서로 다르다. C단계의 R13 값을 유지했다 — 디자이너 확인 필요.

### 테스트 결과
- build-for-testing 2회 성공(앱·단위·UI 타깃, 오류 0).
- PenParityCaptureTests R31·R32·R33·R19·R23·R24·R20: 2회, 매번 **7개 실행, 실패 0**(각 약 68초). 캡처 `scratchpad/app/` 갱신.
- 그 밖의 단위/UI 테스트는 실행하지 않았다(사용자 지시).

### 마지막 회귀에서 확인(미실행)
- UI: `NewJourneyUITests`(전체 — 확인 창 교체), `JourneyLifecycleSafetyUITests`(새 여정 창 AC27·AC28·AC32·AC33 — 백그라운드 왕복·재실행·최대 글씨), `WidgetEntryUITests`(새 여정 창, 분석 진입), `ActiveJourneyMainUITests`, `MainActiveJourneyCardUITests`, `BoardingLargeTextUITests`, `RouteDataUITests`(새 여정 확정), `RecordsUITests`(전체 — 연도 메뉴 → 칩, 기록 줄·빈 문구 배치), `RecordsAnalyticsUITests`(전체 — 기간 줄, 빈 상태 섹션 숨김, 큰 글자 AC6·AC7), `RecordsAnalyticsVisualCaptureTests`, `Phase1FlowTests`(설정 데이터 출처 확인), `ProfileUITests`(설정 AC26·AC27·XXXL 왕복), `DataSourceUITests`, `LargeTextUITests`, `SimulatorLargeTextRecoveryTests`, `StorageRecoveryFlowTests`
- 단위: `RecordsCalendarTests`, `ProfileTimeTextTests`, `RecordsAnalyticsAdapterTests`, `RecordsAnalyticsBrowserTests`, `RecordsAnalyticsRowTests`, `RecordsAnalyticsTests`
- `PenParityCaptureTests`: testR34_alightResume·testR18_homeAfter·testR01_main(진행 여정 공통 배치·바닥 여백 분기 변경)

### 남은 차이
- 공통: 실제 항공 사진(시안은 3D 일러스트), Apple 로고·Legal, 상태 표시줄.
- R31: 1~3pt 안. 할 일·정류장·인사말은 데이터 차이.
- R32: 창 위치·크기 1~2pt 안. 본문 줄바꿈 위치 동일.
- R33: 하단 지표 서체 값(위 R13/R33 충돌), 재개 직후 금색 초점 고리 없음. 지도 시점·축척(항공 사진).
- R19: × 대신 시스템 뒤로 버튼, 날짜 찾기·확대해서 보기 없음, 메모 버튼 있음. 그 밖의 요소 위치 1~4pt 안.
- R23: × 대신 뒤로 버튼, 예시 안내 줄 없음(그만큼 위로 붙음), 제목 " · 전체 기간", 태그 칩 줄 추가. 도넛·범례·요약은 시안과 같은 모양.
- R24: 예시 안내 줄 몫만큼 패널이 낮다(위끝 ≈232 vs 200).
- R20: 프로토타입 문구·동작 줄이기·링크가 없어 패널이 낮다. 뒤로 버튼 있음(시안은 ×).
