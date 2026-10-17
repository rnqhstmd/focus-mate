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
