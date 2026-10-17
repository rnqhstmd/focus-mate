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
