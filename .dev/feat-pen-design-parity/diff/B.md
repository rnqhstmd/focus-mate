# 시안 대비 앱 차이 — B 묶음 (R07·R08·R09·R10·R21·R11)

- 기준: 시안 402x874pt(이미지 2x), 앱 캡처 1206x2622px(3x). 앱 좌표는 캡처를 pt로 환산한 근사값(±2pt).
- 파일 경로는 모두 `/Users/bonseung/projects/focus-mate/next-step-w19/ios/FocusMate/` 기준. 줄번호는 현재 워크트리 기준.
- `[기능]` = 동작/상태/데이터 흐름까지 바꿔야 하는 항목. 표시 없는 항목은 순수 표시(레이아웃·색·글꼴·문구) 수정.
- 공통 글꼴: 시안은 전부 **Noto Sans KR**, 앱 준비 화면은 `PreparationTypography`(서울알림체 SeoulAlrimTTF Bold/Medium, PreparationView.swift:469-484), 승차권은 시스템 글꼴. 글꼴 교체 여부는 전 화면 공통 결정이라 각 항목에서는 크기·굵기만 적고, 글꼴 패밀리 차이는 화면마다 1건으로만 센다.
- 공통 배경: 시안은 3D 일러스트 지도 + 녹색 노선(#168445) + 정류장 점 + 녹색 버스 그림. 앱은 MapKit 실지도(R07·R08) 또는 `BoardMap` 이미지(R11). INDEX.md에 명시된 공통 차이라 각 화면에서 "지도 표현" 1건으로 묶는다.

---

## R07-prepare (준비 · 처음)

### 레이아웃/패널
1. **시트 위치·높이** — 시안: 시트 x=12, y=411, 378x443pt, 아래 끝 y=854(화면 아래에서 20pt, 홈 인디케이터가 시트 안쪽에 겹침). 앱: y≈558, 높이≈269pt, 아래 끝 y≈827(하단 safe area 34 + padding 12 위). 
   - 수정: PreparationView.swift:127-130 `.frame(maxHeight: ... 270 : 350)` → 일반 크기에서는 `.frame(height: 443)` 고정(태그 선택 여부와 무관, 시안 R07·R08 모두 443). :138 `.padding(.bottom, 12)` → 시트를 `.ignoresSafeArea(edges: .bottom)` 처리하고 `.padding(.bottom, 20)`. 접근성 크기 분기는 유지.
2. **시트 모서리·색·테두리** — 시안 r=28, fill #0A0A0A, stroke #FFFFFF33(20%) 1pt. 앱 r=24, `Color(white:0.035)`(#090909), stroke 흰 12%.
   - 수정: :136-137 → `.background(Color(hex 0x0A0A0A), in: RoundedRectangle(cornerRadius: 28))`, `.overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.2), lineWidth: 1))`. (FMDesign.panel이 이미 #0A0A0A이므로 `FMDesign.panel` 사용)
3. **시트 안쪽 여백·간격** — 시안 padding 상24/좌우17/하0, 세로 gap 16(제목→칩 줄 y=72, 칩→여백 y=128), 하단 줄 y=363, 그 아래 16 + 홈 인디케이터 여백 12. 앱: 좌우 18, 위 18, 제목↔칩 22, 버튼 줄 위 12/아래 18.
   - 수정: :100 `.padding(.horizontal, 18).padding(.top, 18)` → `.padding(.horizontal, 17).padding(.top, 24)`; :37 `spacing: 22` → `16`; :125 → `.padding(.horizontal, 17).padding(.top, 16).padding(.bottom, 28)`(16 + 인디케이터 여백 12).
4. **제목 줄 닫기(X) 버튼 없음** — 시안: 제목 오른쪽 끝(x=322 in 344) 22x22 흰색 X 아이콘. 앱: 없음. `[기능]`
   - 수정: :38 Text를 `HStack { Text(...); Spacer(); Button { model.goBack() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .regular)).frame(width: 22, height: 22) } .accessibilityLabel("닫기").accessibilityIdentifier("preparation.close") }`. 제목 줄 높이 32.
5. **왼쪽 위 원형 뒤로 버튼(시스템 내비게이션)** — 앱에만 있음(iOS 26 글라스 back). 시안 없음. `[기능]`(4번 X가 대체)
   - 수정: PreparationView body 끝에 `.navigationBarBackButtonHidden(true)` 추가(AlightingSummaryView.swift:23과 같은 방식). 스와이프 뒤로가 필요하면 유지 여부 확인.
6. **상단 노선 캡슐 "지선 2014 · 성수동"** — 앱에만 있음(:26-32). 시안 없음.
   - 수정: :26-32 블록 삭제(또는 접근성 전용으로 숨김). 버스 정보는 시안상 승차권에서 보여줌.
7. **지도 표현** — 시안: 일러스트 + 녹색 노선(4px급, #168445)과 남은 구간 흰 44% 선, 정류장 점(6x6 흰색, 검정 테두리), 현재 정류장 14x14(검정 채움+녹색 테두리), 출발점에 녹색 버스 그림(64x81), 화면 전체에 #00000055 어둡게. 앱: MapKit 실지도, 흰 80% 3pt 폴리라인, `mappin.circle.fill` 36pt 핀 + 정류장명 "서울숲역", Apple Maps 로고/Legal. 
   - 수정: SceneMapBackdrop.swift:39-47 — 폴리라인 색 `Color(0x168445)` lineWidth 4, 정류장마다 `Annotation`(6pt 흰 원 + 1pt #0A0A0A 테두리), 출발 정류장에 버스 이미지(자산 추가 필요), 핀(:43-47) 제거 또는 현재 정류장 원형 마커(14pt)로 교체, 지도 위 `Color.black.opacity(0.33)` 오버레이. 실지도 vs 일러스트 자체는 공통 결정(INDEX 공통 차이).

### 태그 칩
8. **칩 배치: 1줄 가로 스크롤 vs 2줄 그리드** — 시안: 한 줄, 순서 독서·공부·업무·휴식·+ (+는 오른쪽 끝에서 잘려 스크롤 암시). 앱: `LazyHGrid` 2행(:41-43)이라 열 우선으로 독서/공부, 업무/휴식, + 배치 → 화면상 "독서 업무 +" / "공부 휴식".
   - 수정: :41-43 `LazyHGrid(rows: [GridItem(.fixed(tagHeight))], spacing: 8)`(1행), :76 `.frame(height: tagHeight * 2 + 10)` → `.frame(height: 40)`, 칩 간격 8(시안 x 0/84/168/252/336 → 폭76+8).
9. **칩 크기** — 시안 76x40, 좌 패딩 14, 아이콘 16x16, 아이콘-글자 간격 6, 글자 x=36. 앱: 높이 46(`tagHeight` :15), 좌우 14, 글자 17.
   - 수정: :15 `tagHeight = 46.0` → `40.0`; :49-51 `Label`을 `HStack(spacing: 6) { Image(systemName:).font(.system(size: 14)).frame(width:16,height:16); Text }`로, `.padding(.horizontal, 14)`.
10. **칩 글자 색·크기·굵기** — 시안: 이름 흰색 #FFFFFF, 14pt/600, 아이콘만 태그색. 앱: 글자·아이콘 모두 태그색(선택 시 흰색), 17pt Bold.
   - 수정: :50 `bold(17)` → `semibold 14`(Noto Sans KR SemiBold 14 또는 서울알림 Medium 14), :52 `.foregroundStyle(selected ? .white : tag.color.tint)` → 글자 `.white`, 아이콘만 `tag.color.tint`.
11. **칩 배경·테두리 투명도** — 시안 미선택 fill 태그색 0x22(13%), stroke 0x88(53%); 앱 fill 20%, stroke 45%.
   - 수정: :53 `opacity(selected ? 0.35 : 0.2)` → `selected ? 0.33 : 0.13`; :56 `opacity(selected ? 1 : 0.45)` → `selected ? 1 : 0.53`.
12. **태그 색상값** — 시안 독서 #E8B64C, 공부 #A78BFA, 업무 #60A5FA, 휴식 #4ADE80. 앱 `tint`(:427-434) sand #D6B378, purple #B599DE, blue #87ABF5, green #8CBAAB(채도 낮음).
   - 수정: :429-432 → sand `#E8B64C`, blue `#60A5FA`, purple `#A78BFA`, green `#4ADE80`. (pink는 시안 칩에 없음. R09 색 견본은 아래 R09-8 참고 — R09 시안 견본은 기존 저채도 값이라 두 시안이 서로 다름. 칩용 강조색과 견본색을 분리하거나 디자이너 확인 필요)
13. **칩 아이콘 모양** — 시안: 선형(lucide) 책·학사모·가방·연필, 16pt. 앱 SF `book`·`graduationcap`·`briefcase`·`pencil`(학사모·가방이 두껍고 큼). 휴식=연필은 양쪽 동일.
   - 수정: PreparationDraft.swift:16-20 심볼 유지, 크기 14pt `.fontWeight(.regular)`로 축소(9번과 함께). 완전히 맞추려면 lucide SVG 자산 추가.
14. **+ (새 태그) 버튼** — 시안 40x40 원, fill #1A1A1A, stroke #FFFFFF55(33%), 더하기 18pt. 앱 46x46, fill 흰 6%, stroke 16%, `.title2`(≈22pt).
   - 수정: :66-69 → `.font(.system(size: 18, weight: .regular))`, `.frame(width: 40, height: 40)`, `.background(Color(0x1A1A1A), in: Circle())`, `.overlay(Circle().stroke(.white.opacity(0.33)))`.

### 제목
15. **제목 글꼴** — 시안 22/700, 높이 32. 앱 22 Bold(서울알림). 크기·굵기 일치, 패밀리만 다름(공통 글꼴 결정).

### 하단 줄
16. **소리 칩 모양** — 시안 107x52 캡슐, fill #1A1A1A, stroke #FFFFFF33(20%), 스피커 18pt(x=14), 글자 14pt Regular 흰색(x=38). 앱: padding 14, 17pt Bold, fill 흰 6%, stroke 16%, 높이≈48.
   - 수정: :184-191 → `HStack(spacing: 6){ Image(systemName:).font(.system(size: 16)).frame(width:18,height:18); Text(...).font(14 regular) }.padding(.horizontal, 14).frame(height: 52)`, `.background(Color(0x1A1A1A), in: Capsule())`, `.overlay(Capsule().stroke(.white.opacity(0.2)))`.
17. **소리 없음 아이콘** — 시안: 스피커 + 작은 ×(volume-x). 앱 `speaker.slash`(사선). 
   - 수정: :186 및 PreparationDraft.swift:80 `speaker.slash` → 스피커+× 모양 자산(SF에 정확한 대응 없음; 커스텀 SVG `volume-x` 추가). 소리 있음 아이콘은 시안 R07에서 보이지 않으므로 `speaker.wave.2` 유지.
18. **소리 기본값** — 시안 "소리 없음", 앱 "버스". `[기능]`
   - 수정: PreparationDraft.swift:97 `private(set) var sound: JourneySound = .bus` → `.none`. 관련 UI/단위 테스트(기본 소리 "버스" 기대값) 함께 갱신. (INDEX도 이 차이를 지적함)
19. **승차권 보기(비활성)** — 시안 227x52, fill #252525, 테두리 없음, 글자 #888888 16/600. 앱 fill 흰 8%, stroke 흰 15%, 글자 흰 45% 17 Bold.
   - 수정: :202-206 → 폰트 16 semibold, `.frame(height: 52)`(padding 16 대신), 비활성 `foregroundStyle(Color(0x888888))`, `background(Color(0x252525))`, overlay 테두리 삭제. 활성은 fill #FFFFFF, 글자 #0A0A0A(현재 `.black` → `Color(0x0A0A0A)`).
20. **하단 줄 간격** — 시안 소리 칩과 버튼 간격 10(107+10=117). 앱 HStack spacing 10. 일치(차이 아님).

### 빈 공간
21. **태그 미선택 시 빈 영역** — 시안: 칩 아래 219pt 비어 있음(시트 고정 높이). 앱은 시트가 작아져(269pt) 빈 공간이 거의 없음. 1번 수정(높이 443 고정)으로 해결.

### 상태 표시줄
22. 시안 R07에는 상태 표시줄이 없음(다른 시안엔 9:41 표기). 앱은 시스템 상태 표시줄. 시안 내보내기 차이로 보고 무시 권장(차이 개수에는 포함하지 않음).

### 데이터 차이(차이 개수 제외)
- 앱 출발 정류장 "서울숲역"·노선 2014-r 60분 vs 시안 성수역→서울숲 입구 25분(캡처 경로상 값).

**R07 차이: 21건** (1~19, 21 + 글꼴 패밀리 1건; 20·22 제외)

---

## R08-prepare-filled (준비 · 입력 완료)

R07의 1~19 항목(시트·칩·소리·지도·X 버튼·뒤로 버튼·노선 캡슐·글꼴)은 R08에도 그대로 적용된다. 아래는 R08에서 추가로 보이는 차이.

1. **시트 높이 변화** — 시안: 태그 선택 후에도 시트 443 고정(y=411). 앱: 선택 시 maxHeight 350으로 커져 y≈478, 높이≈349.
   - 수정: R07-1과 동일(:127-130 고정 443). 
2. **할 일 입력칸 크기** — 시안 344x48, 위치 y=128(칩 줄 아래 16). 앱: padding 16 + 17pt 글자로 높이≈53, 칩 2줄 아래에 위치(시트 y≈667).
   - 수정: :85 `.padding(16)` → `.padding(.horizontal, 16).frame(height: 48)`.
3. **입력칸 모서리·배경** — 시안 r=14, fill #141414. 앱 r=16, fill 흰 5%.
   - 수정: :86, :88 `cornerRadius: 16` → `14`; 배경 `Color(0x141414)`.
4. **입력칸 테두리 강조 규칙** — 시안: 편집 중이 아니어도 선택한 태그색(#E8B64C) 1pt 테두리. 앱: `taskEditing`일 때만 태그색, 아니면 흰 15% (캡처는 키보드 내린 상태라 회색). `[기능]`(상태 조건 변경)
   - 수정: :88-89 `taskEditing ? tag.color.tint : .white.opacity(0.15)` → 항상 `tag.color.tint`(시안 기준). 편집 중 구분이 필요하면 lineWidth 1.5로만 구분.
5. **입력 글자** — 시안 16pt Regular 흰색, x=16. 앱 17pt Medium.
   - 수정: :85 `medium(17)` → 16 regular.
6. **선택된 칩 강조** — 시안 독서 칩 fill #E8B64C55(33%), stroke #E8B64C 100%, 글자 흰색. 앱 fill 35%, stroke 100%, 글자 흰색 — 색상값만 R07-12 차이(앱 sand #D6B378), 투명도는 R07-11 수정으로 맞음. 
7. **승차권 보기(활성)** — 시안 fill #FFFFFF, 글자 #0A0A0A 16/600, 테두리 없음. 앱 흰색 + 흰 15% 테두리, 17 Bold.
   - 수정: R07-19와 동일(:204-206).
8. **칩 줄과 입력칸 사이 간격** — 시안 16, 앱 22(:37). R07-3 수정으로 해결.
9. **입력칸 아래 여백** — 시안: 입력칸 아래 155pt 빈 공간 후 하단 줄. 앱: 입력칸 아래 ≈40pt 후 버튼. R07-1 고정 높이로 해결.
10. **지도 표현** — 시안 R08은 노선이 축소(카메라 멀리)된 일러스트. 앱은 R07과 같은 줌의 MapKit. R07-7과 동일.
11. **배경 전환** — 앱은 입력칸 편집 중(`taskEditing`) 지도 대신 단색 배경으로 바뀜(:142-143). 시안은 입력 완료 상태에서도 지도 유지. 캡처 시점(키보드 내림)에는 지도가 보여 이번 캡처 차이는 없음. 편집 중 표시는 시안 없음 → 참고만.

### 데이터 차이(제외)
- 소리 "버스" vs 시안 "소리 없음"은 R07-18(기본값) 결과라 R07에서 셈.

**R08 차이(추가분): 9건** (1~5, 7~10; 6·11 제외) — R07 공통 19건 별도.

---

## R09-new-tag (새 태그 시트)

1. **시트 형태** — 시안: 떠 있는 카드, x=12~390(좌우 12), y=451~854(아래 20pt 띄움), r≈28, 테두리 흰 ~20%. 앱: 시스템 sheet, 좌우 ≈8pt, 위 y≈440, 화면 아래 끝까지(기기 모서리), `.presentationCornerRadius(24)`.
   - 수정: PreparationView.swift:151-155 — 시스템 `.sheet` 대신 R07 시트와 같은 커스텀 오버레이(ZStack 하단 정렬, `.padding(.horizontal, 12).padding(.bottom, 20)`, 높이 403, r=28, stroke 흰 20%)로 교체하거나, 최소한 `.presentationCornerRadius(28)` + `.presentationBackground(.clear)` 후 내부 카드에 12pt 여백. `[기능]`(시트 표시 방식 교체 시 드래그 닫기·포커스 복귀 `onDismiss` 재구현 필요)
2. **배경** — 시안: 순검정 #000000, 다른 요소 없음. 앱: #0F1012 배경 위에 뒤로 버튼·노선 캡슐이 흐리게 남음.
   - 수정: :142-143 `FMDesign.background` → 태그 편집 중 `Color.black`; R07-5·6(뒤로 버튼 숨김·캡슐 삭제)으로 잔상 제거.
3. **제목 "태그 만들기"** — 시안 20/700, 위치 x=27(카드 안 15), y=476(카드 위에서 25). 앱 20 Bold, x≈28, 카드 위에서 ≈22. 
   - 수정: :241 `.padding(.horizontal, 20).padding(.top, 18)` → `.padding(.horizontal, 15).padding(.top, 25)`.
4. **닫기 ×** — 시안 23pt Regular 글리프 "×"(얇음). 앱 SF `xmark` 20pt + padding 4.
   - 수정: :239 `.font(.system(size: 20))` → `.font(.system(size: 18, weight: .light)).frame(width: 23, height: 23)`.
5. **미리보기 박스** — 시안: 높이≈57, r≈16, 테두리 흰 ~20%, 아이콘 ≈24pt + "새 태그" 19/700 #D7B378. 앱: minHeight 56, 테두리 흰 16%, 글자 17 Medium, 아이콘 ≈17pt.
   - 수정: :244-247 → `.font(bold 19)`, 아이콘 `.font(.system(size: 22))`, stroke `.white.opacity(0.2)`, `minHeight: 57`.
6. **라벨 "이름"·"아이콘"·"색"** — 시안 11pt Regular #AAAAAA. 앱 12pt Medium 흰색(기본 전경색).
   - 수정: :250, :263, :285 → `.font(11 regular).foregroundStyle(Color(0xAAAAAA))`.
7. **이름 입력칸** — 시안: 높이 46, 거의 캡슐형(r≈22), fill #111111, 태그색 테두리 2pt, placeholder "태그 이름" 15pt #757575, 글자 x=42(안쪽 ≈14). 앱: r=14, fill 흰 4%, 테두리 1pt, 17pt Medium, padding 12(높이≈44).
   - 수정: :252-254 → `.font(15 regular)`, `.padding(.horizontal, 14).frame(height: 46)`, `RoundedRectangle(cornerRadius: 23)`(또는 Capsule), `.background(Color(0x111111))`, `.stroke(draft.color.tint, lineWidth: 2)`, placeholder 색 `prompt: Text("태그 이름").foregroundStyle(Color(0x757575))`.
8. **색 견본 값** — 시안(이미지 판독) 모래 ≈#D7B378, 파랑 ≈#84AAF2, 보라 ≈#B39DE0, 초록 ≈#8FBFAE, 분홍 ≈#D896A8. 앱 분홍 #E6A8C4(0.90,0.66,0.77)가 더 밝고 분홍빛. 나머지는 근사 일치.
   - 수정: PreparationView.swift:433 pink → `#D896A8`(근사; Pen 원본 값 확인 권장). R07-12와 충돌 주의(칩은 고채도, 견본은 저채도).
9. **아이콘/색 셀** — 시안 셀 ≈64x43, r≈12, fill #141414, 테두리 흰 ~20%, 선택 셀 흰 1.5pt; 아이콘 ≈22pt 선형. 앱 minHeight 44, fill 흰 4%, 테두리 흰 15%, 선택 1pt; 학사모 SF가 두껍다.
   - 수정: :272-277, :294-299 → 배경 `Color(0x141414)`, 미선택 stroke `.white.opacity(0.2)`, 선택 `lineWidth: 1.5`, `minHeight: 43`.
10. **세로 간격** — 시안: 라벨→칸 ≈8, 칸→다음 라벨 ≈5(이름칸 끝 656 → "아이콘" 661), 셀 줄 끝→다음 라벨 ≈5. 앱: VStack spacing 8 + 섹션 간 8.
   - 수정: :243 `spacing: 8` → `5`, :249/:262/:284 내부 `spacing: 4` → `8`.
11. **"태그 저장" 버튼** — 시안 높이≈43, 글자 15pt Regular #000000, 좌우 ≈16(x 28~374). 앱 높이≈49, 17 Bold.
   - 수정: :318-320 → `.font(15 regular)`, `.padding(16)` 대신 `.frame(height: 43)`; :322 `.padding(.horizontal, 20)` → `16`, `.padding(.bottom, 16)` 유지.
12. **글꼴 패밀리** — Noto Sans KR vs 서울알림(공통 결정, 1건).

### 데이터 차이(제외)
- 없음(빈 이름 상태 동일).

**R09 차이: 12건**

---

## R10-sound (소리 선택 시트)

1. **시트 형태** — 시안: 떠 있는 카드 x=12, y=451, 378x403, r=28, fill #0A0A0A, stroke #FFFFFF33, 아래 20pt 띄움, 안쪽 pad 상22/좌우17/하28, gap 14. 앱: 시스템 sheet `.height(440)`, 좌우 ≈8, 화면 아래 끝까지, r=24, 내부 padding 20, spacing 16. `[기능]`(R09-1과 같이 표시 방식 교체)
   - 수정: PreparationView.swift:156-167, :408 `.padding(20)` → `.padding(.top, 22).padding(.horizontal, 17).padding(.bottom, 28)`, :342 `spacing: 16` → `14`, 카드 r=28·stroke 흰 20%·좌우/아래 여백 12/20.
2. **배경 지도 유지** — 시안: 소리 시트 뒤에 지도 일러스트가 그대로 보임. 앱: `showSoundSelection`이면 지도를 없애고 단색(:142-143). 뒤로 버튼·노선 캡슐 잔상도 보임.
   - 수정: :142 조건에서 `showSoundSelection` 제거(지도 유지). R07-5·6 적용.
3. **제목 "소리 선택"** — 시안 20/700. 앱 22 Bold.
   - 수정: :344 `bold(22)` → `bold(20)`.
4. **닫기 아이콘** — 시안 22x22 X. 앱 `.title2`(≈22) + padding 8(오른쪽이 8pt 안쪽으로 들어감).
   - 수정: :349 `.padding(8)` 제거, `.frame(width: 22, height: 22)`(탭 영역은 `contentShape`로 44 확보).
5. **셀 크기 고정·행 높이 불일치** — 시안 108x84 고정, 아이콘 위 18 / 글자 y=48. 앱: padding 16 기반이라 행마다 높이가 다름(숲속 ≈86, 소리 없음 ≈82, 1행 ≈84로 2행 셀이 서로 어긋남).
   - 수정: :364-367 → `.frame(maxWidth: .infinity).frame(height: 84)`(padding 제거), VStack `spacing: 8`.
6. **셀 행 간격** — 시안 가로 10, 세로 14(행1 y=65, 행2 y=163). 앱 둘 다 10.
   - 수정: :356 `spacing: 10`(세로) → `14`.
7. **셀 모서리·색** — 시안 r=16, 미선택 fill #141414 stroke #FFFFFF22(13%), 선택 fill #262626 stroke #FFFFFF(≈2pt). 앱 r=20, 미선택 흰 3.5% stroke 12%, 선택 흰 10% stroke 1pt.
   - 수정: :369-374 → `RoundedRectangle(cornerRadius: 16)`, fill `selected ? Color(0x262626) : Color(0x141414)`, stroke `selected ? .white : .white.opacity(0.13)`, `lineWidth: selected ? 2 : 1`.
8. **셀 글자** — 시안 13pt Regular 흰색(미선택도 흰색). 앱 15 Medium, 미선택 흰 80%.
   - 수정: :366 → 13 regular; :368 → `.foregroundStyle(.white)`.
9. **셀 아이콘 모양** — 시안 22pt 선형: 버스 정면(lucide bus), 구름+빗줄기, 지하철 정면(train-front), 나무 2그루(trees), 스피커+×. 앱 SF: `bus`(두꺼운 채움형), `cloud.rain`, `tram`, `tree`(한 그루), `speaker.slash`(사선).
   - 수정: PreparationDraft.swift:76-80 → `bus` 유지 시 `.fontWeight(.light)`; `tram` → `tram.fill`보다 `train.side.front.car` 근사; `tree` → `tree`(SF에 2그루 없음) 혹은 lucide 자산; `speaker.slash` → R07-17 커스텀 `volume-x`. 아이콘 크기 `.font(.system(size: 20, weight: .light))`, frame 22x22(:365).
10. **미리 듣기 버튼** — 시안 높이 44, stroke #FFFFFF33(20%), 글자 15/500. 앱 padding 16 + 17 Bold(높이≈52), stroke 흰 20%.
   - 수정: :391-394 → `.font(15 medium)`, `.frame(maxWidth: .infinity, minHeight: 44)`(padding 16 제거).
11. **소리 저장 버튼** — 시안 높이 52, 글자 15/600 #0A0A0A. 앱 17 Bold(높이≈52).
   - 수정: :402-405 → 15 semibold, `.frame(height: 52)`, 글자 `Color(0x0A0A0A)`.
12. **미리 듣기→저장 간격** — 시안 14(261+44=305 → 319). 앱 16(:385).
   - 수정: :385 `spacing: 16` → `14`.
13. **글꼴 패밀리** — 공통 1건.

### 데이터 차이(제외)
- 선택값 "버스"는 시안과 동일.

**R10 차이: 13건**

---

## R21-map-recover (준비 · 지도 불러오기 실패) — 앱에 없음, 새로 만들 것

### 시안 구성
- 배경: 지도 일러스트(실패 상태인데도 시안은 이미지가 보임 — 실제 구현에서는 실패 시 지도 영역이 비어 보일 것이므로 마지막 성공 화면 또는 `FMDesign.background` 위에 배너).
- **지도 오류 배너**(새 요소): 화면 위쪽 떠 있는 카드
  - 위치·크기: x=24~378(좌우 24), y≈125~238(높이≈113), r≈16, fill #0A0A0A(불투명에 가까움), 테두리 없음(이미지상).
  - 제목 "지도를 불러오지 못했어요" — 13pt Bold(700) 흰색, x=36, y=138.
  - 설명 "여행 준비와 시간은 유지돼요." — 12pt Regular #B5B5BA, y=160.
  - 버튼 "다시 불러오기" — 캡슐, x=36~366(폭 330), y≈182~226(높이 44), fill #0A0A0A(배경과 동일), stroke 흰 ≈25%, 글자 13pt Regular 흰색 가운데.
- 아래 시트: 시안 R21의 시트는 **R07과 다른 구판 레이아웃**이다(제목 "버스에서 할 일", 요약 줄 "2014 · 25 min · 성수역 → 서울숲 입구" 12pt #B5B5BA, "여행 태그"/"새 태그" 라벨 12pt, 사각형(r≈14) 칩 4개 13pt, "태그 관리" 12pt, 구분선, "여행 소리 · 선택 사항" 11pt + "소리 없음" 14pt + 오른쪽 chevron 행, 안내 "태그를 고르면 할 일을 입력할 수 있어요." 12pt #B5B5BA 가운데, 전폭 "승차권 보기" 15pt #888888). R07/R08(최신 개선안)과 충돌하므로 **시트는 R07 디자인을 유지하고 배너만 추가**하는 것을 권장. 디자이너 확인 필요 항목으로 표기.

### 새로 만들어야 할 것
1. `[기능]` **지도 로드 실패 감지** — SceneMapBackdrop.swift는 SwiftUI `Map`(:36)이라 타일 로드 실패 콜백이 없다. 
   - 방안 A: `MKMapView`를 `UIViewRepresentable`로 감싸 `mapViewDidFailLoadingMap(_:withError:)`에서 실패 상태를 올리고, `mapViewDidFinishLoadingMap`에서 해제. 
   - 방안 B: 네트워크 경로 모니터(`NWPathMonitor`) + 일정 시간 내 렌더 완료 없으면 실패로 간주(부정확).
   - 상태: `SceneMapBackdrop`에 `@Binding var loadFailed: Bool` 또는 `onLoadFailure: () -> Void` 추가. 다시 불러오기는 `.id(stop.id)`(:54)에 재시도 카운터를 섞어 `.id("\(stop.id)-\(retry)")`로 맵을 재생성.
2. **배너 뷰** — 새 `MapLoadFailureBanner`(PreparationView.swift 안 private struct 또는 새 파일): 위 수치대로. PreparationView body의 `GeometryReader > VStack` 위쪽(현재 노선 캡슐 자리, :26-32)에 `if mapLoadFailed { MapLoadFailureBanner(onRetry:) .padding(.horizontal, 24).padding(.top, 125 - safeAreaTop) }`.
3. `[기능]` **준비 상태 보존** — 문구대로 재시도해도 `model.preparation`(태그·할 일·소리)과 선택 시간·노선이 유지돼야 함. 현재 맵 재생성은 PreparationView 상태에 영향이 없으므로 `.id`만 바꾸면 충족. 접근성: 배너 `accessibilityIdentifier("preparation.mapError")`, 버튼 `preparation.mapRetry`, 배너 등장 시 VoiceOver 알림(`AccessibilityNotification.Announcement("지도를 불러오지 못했어요")`).
4. `[기능]` **UI 테스트 진입점** — INDEX상 `--fm-ui-route-data failed`는 정류장 데이터 실패라 다른 화면. 새 런치 인자 `--fm-ui-map failed`(UITestBootstrap.swift)로 SceneMapBackdrop가 실패 상태로 시작하도록 주입, PenParityCaptureTests에 `testR21_mapRecover` 추가.
5. 같은 배경 컴포넌트를 쓰는 다른 화면(메인 등)에도 배너를 띄울지 범위 결정(시안은 준비 화면만).

**R21: 신규 요소 5건**(감지·배너·상태 보존·테스트 진입점·범위 결정) + 시트 구판 레이아웃 충돌 1건(확인 필요)

---

## R11-boarding-pass (승차권)

시안은 **지도 위 하단 시트형 승차권**, 앱은 **노치 있는 티켓 카드 + 시트 밖 버튼**으로 구조 자체가 다르다. BoardingPassView.swift는 주석상 구 시안(TUNX2 이전판)을 따른 것으로 보인다.

### 구조/레이아웃
1. **컨테이너** — 시안: 하단 시트 x=12, y≈470~854(378x384), r=28, fill #0A0A0A, stroke 흰 ~20%, 아래 20pt 띄움(R07 시트와 같은 계열). 앱: `TicketShape`(r=24, 양옆 반원 노치 12pt @62%), fill #1C1C1E, x≈24~378, y≈433~727, 버튼은 카드 밖.
   - 수정: BoardingPassView.swift:54-78 `ticket()`를 시트 카드로 재작성 — `.background(FMDesign.panel, in: RoundedRectangle(cornerRadius: 28))`, `.overlay(... .stroke(.white.opacity(0.2)))`, `.padding(.horizontal, 12).padding(.bottom, 20)`, `.ignoresSafeArea(edges: .bottom)`. `TicketShape`(:113-121)·`TicketDots` 배경(:73) 제거.
2. **헤더 "‹ 승차권"** — 시안: 시트 안 왼쪽 위, "‹" 23pt Regular(x=45, y=497) + "승차권" 20/700(x=81, y=495). 앱: 없음(대신 왼쪽 위 원형 시스템 뒤로 버튼). `[기능]`
   - 수정: 시트 상단에 `HStack(spacing: 22) { Button { model.goBack() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .regular)) }; Text("승차권").font(20 bold) }`, 시트 위 패딩 ≈25, 좌 33. body에 `.navigationBarBackButtonHidden(true)`(:51 근처).
3. **상단 캡슐 "서울숲역 → 성수동"** — 앱에만 있음(:22-31). 시안 없음.
   - 수정: :22-31 삭제.
4. **노선 배지(녹색)** — 시안: 가운데 녹색 캡슐(≈120x40, x≈141~261, y≈539~578, r≈14~20, fill 녹색 ≈#168445/#1E8E4E 계열), 안에 버스 아이콘 ≈18pt 흰색 + "지선" 10pt Regular #B5B5BA(녹색 위 연회색) + "2014" 20/700 흰색. 앱: 없음 — 버스 번호는 낭독 라벨에만(:56-58, BoardingPassContent.swift:4·14 주석 "화면에 쓰지 않는다"). `[기능]`(표시 정책 변경)
   - 수정: BoardingPassContent에 `busKind`, `busNumber` 공개 필드 추가(현재 `busText`만), 시트에 `HStack(spacing: 6){ Image(systemName: "bus").font(.system(size:18)); Text(busKind).font(10).foregroundStyle(Color(0xB5B5BA)); Text(busNumber).font(20 bold) }.padding(.horizontal, 16).frame(height: 40).background(Color(0x168445), in: Capsule())`. 배지 색은 Pen 원본 확인(노선 색 #168445 추정). 기존 단위 테스트(번호 미표시 가정) 수정.
5. **출발/도착 행** — 시안: 두 열 각 가운데 정렬(출발 열 중심 x≈113, 도착 열 중심 x≈288), 라벨 10pt Regular #B5B5BA(y=593), 값 16/700 흰색(y=612), 라벨-값 간격 ≈9. 앱: 좌/우 끝 정렬, 라벨 `.footnote`(13) secondary, 값 서울알림 Bold `stationFontSize`(4자 이하 28, ≤6자 24 … 최대 24로 제한).
   - 수정: :59-60 → 값 폰트 고정 16 bold(`stationFontSize` 규칙 제거 또는 16 상한), :88-96 `cell`을 `.center` 정렬 VStack(spacing 9)로, 라벨 `.font(10).foregroundStyle(Color(0xB5B5BA))`. BoardingPassContent.swift:16-17, :33, :38-45 `stationFontSize` 정리.
6. **구분선 2개** — 시안: 출발/도착 아래(y≈655), 통계 아래(y≈723)에 1pt 흰 ~12% 가로선(좌우 17 안쪽, 폭 344). 앱: 없음.
   - 수정: 각 행 사이 `Rectangle().fill(.white.opacity(0.12)).frame(height: 1)`.
7. **통계 3칸 "여행 시간 / 정류장 / 이동 거리"** — 시안: 3열(라벨 10pt #B5B5BA, 값 13/700 흰색): "여행 시간 25 min", "정류장 5개", "이동 거리 2.8 km". 앱: 2열 행 "정류장/거리"(라벨 "거리"), 여행 시간 없음. `[기능]`(여행 시간 표시 = 4번과 같은 정책 변경)
   - 수정: :61-62 행을 3열 HStack으로: `("여행 시간", "\(journey.minutes) min")`, `("정류장", stopsText)`, `("이동 거리", distanceText)`. 라벨 문구 "거리" → **"이동 거리"**. BoardingPassContent에 `minutesText = "\(journey.minutes) min"` 추가.
8. **거리 표기 형식** — 시안 "2.8 km"(숫자와 km 사이 공백). 앱 "6.6km"(RouteCandidates.swift:28, 공백 없음).
   - 수정: 승차권 전용으로 `"\(tenths/10).\(tenths%10) km"` 포맷 또는 RouteCandidates.swift:28에 공백 추가(시간 선택 화면 TimeSelectionView.swift:138에도 영향 — 시안 R04/R06 확인 후 결정).
9. **탑승/날짜 행** — 앱에만 있음("탑승 지금", "날짜 2026/10/17", :63-64). 시안 없음.
   - 수정: :63-64 삭제, BoardingPassContent.swift:10-11, :26-30 `boardingText`·`dateText` 제거(테스트 갱신).
10. **태그·할 일 표기** — 시안: 한 줄 "독서 · 책 한 챕터 읽기" 15pt Regular 흰색, 왼쪽 정렬(x=29, y=747), 라벨 없음. 앱: 2열 "태그 / 할 일" 라벨 + 값(subheadline semibold), 할 일 오른쪽 정렬, 위 18pt 추가 여백.
   - 수정: :65-67 → `Text("\(content.tagName) · \(content.task)").font(15 regular).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)`. 접근성 식별자 `board.tag`/`board.task`는 숨은 요소로 유지하거나 테스트 갱신.
11. **"버스에 탑승하기 →" 버튼** — 시안: 시트 **안** 맨 아래, x=28~374(폭≈346), y≈795~838(높이≈43), 흰 캡슐, 글자 15pt Regular #000000. 앱: 시트 밖 `safeAreaInset`, 좌우 24(폭≈354), 높이≈68(minHeight 44 + 세로 12x2), `.headline`(17 semibold).
   - 수정: :99-109 → 버튼을 시트 VStack 마지막에 넣고 `.font(15 regular)`, `.frame(maxWidth: .infinity).frame(height: 43)`(vertical padding 제거), `.padding(.horizontal, 16)`(시트 안 기준), 시트 아래 패딩 16. :41 `safeAreaInset` 제거.
12. **세로 리듬** — 시안 시트 내부 y: 헤더 495 → 배지 539 → 출발 라벨 593 → 값 612 → 선 655 → 통계 라벨 668 → 값 687 → 선 723 → 태그 줄 747 → 버튼 795. 앱 VStack spacing 16, padding 22. 
   - 수정: 시트 VStack을 spacing 고정 대신 위 좌표에 맞춘 개별 padding(헤더→배지 18, 배지→출발 15, 값→선 27, 선→통계 13, 통계값→선 23, 선→태그 24, 태그→버튼 33).

### 지도/배경
13. **지도 표현** — 시안: 3D 일러스트 + 녹색 노선(출발 버스 그림 → 현재/도착 원형 마커) + 흰 44% 나머지 구간 + 정류장 점. 앱: `BoardMap` 이미지에 노선·버스·정류장 없음, 검정 35% 덮개(:18).
   - 수정: :12-19 — 시안과 같은 노선 표시가 필요하면 `BoardMap` 위에 노선 경로 오버레이(정적 이미지면 Path 오버레이) 또는 준비 화면과 같은 `SceneMapBackdrop(routeID:)` 재사용(R07-7 수정과 일원화). 덮개 투명도 35% → 시안 #00000055(33%)로 `0.33`.
14. **아래쪽 검은 띠** — 앱 캡처에서 y≈799pt 아래(버튼 아래)가 지도 없이 검정. `safeAreaInset`으로 ScrollView가 줄며 이미지 frame 계산(:13-14)이 하단을 덮지 못하는 것으로 보임. 시안은 지도가 화면 끝까지.
   - 수정: :12-17 이미지를 `ZStack` 바깥 `.background { Image("BoardMap")...ignoresSafeArea() }`로 옮겨 GeometryReader 크기와 분리. 11번(버튼 시트 안으로) 적용 시 `safeAreaInset`이 없어져 함께 해소.
15. **원형 뒤로 버튼** — 앱에만 있음(시스템). 2번에서 숨김.
16. **글꼴** — 시안 Noto Sans KR 전체. 앱 시스템 글꼴 + 정류장명만 서울알림 Bold(:60). 공통 결정 1건.

### 데이터 차이(제외)
- 출발/도착 "서울숲역 → 성수동" vs "성수역 → 서울숲 입구", 정류장 12개 vs 5개, 거리 6.6 vs 2.8, 노선 60분 vs 25분(캡처 경로상 선택값). 태그·할 일 "독서 · 책 한 챕터 읽기"는 일치.

**R11 차이: 16건** (그중 [기능] 3건: 2·4·7)

---

## 요약 표

| 화면 | 차이 수 | [기능] |
|---|---|---|
| R07-prepare | 21 | 3 (X 닫기·뒤로 버튼 숨김·소리 기본값) |
| R08-prepare-filled | 9 (+R07 공통) | 1 (입력칸 테두리 상시 태그색) |
| R09-new-tag | 12 | 1 (떠 있는 카드 시트로 교체) |
| R10-sound | 13 | 1 (떠 있는 카드 시트로 교체) |
| R21-map-recover | 신규 5 + 확인 1 | 4 (실패 감지·재시도·상태 보존·테스트 진입점) |
| R11-boarding-pass | 16 | 3 (헤더 뒤로·노선 배지/버스 번호 표시·여행 시간 표시) |

## 디자이너 확인 필요
- R21 시트가 R07/R08과 다른 구판 레이아웃("버스에서 할 일", "여행 태그", "태그 관리" 등). 배너만 반영할지.
- 칩 강조색(R07: #E8B64C 등 고채도)과 태그 만들기 색 견본(R09: 저채도)이 서로 다름.
- 승차권 노선 배지 정확한 녹색 hex(덤프에 없음, #168445 추정).
- 소리 없음 아이콘(스피커+×)은 SF Symbols에 정확한 대응 없음 → 자산 추가 여부.
