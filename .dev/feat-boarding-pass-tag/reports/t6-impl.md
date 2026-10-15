# T6 IMPLEMENT — 승차권·메인 화면

## 구현 내용
- 신규 `JourneyServices.swift`: 햅틱·낭독·sleep·holdSleep·forcedReduceMotion·makeBoarder 묶음, `.live()`, `AppModel: JourneyBoarding, DepartureConfirming`.
- 신규 `BoardingPassView.swift`: 지도 배경(BoardMap)+티켓(TicketDots 질감, 양옆 노치 even-odd 클립), 칸 4행(라벨 위·값 아래), 정류장 글꼴 BoardingPassContent 규칙, 낭독 전용 경로 요소 `board.route`(Color.clear 요소 — 화면 글자 아님), 하단 고정 '버스에 탑승하기 →'(safeAreaInset, 큰 글자 상한 accessibility3) → openBoarding.
- `DestinationScreen.swift`: services 주입, `.board` → BoardingPassView.
- `PreparationView.swift`: '승차권 보기' → showBoardingPass, 준비 확정 진단 제거(RootView 전역으로 이동).
- `RootView.swift`: services 프로퍼티(기본 .live()), 메인 진행 여정 안내 `main.activeJourney`, 메뉴 라벨 mainMenuTitle·준비는 startTripFromMain, 전역 진단 `test.preparedPreparation`.
- `FocusMateApp.swift`: 테스트 기록기를 쓰는 services 조립.
- `UITestBootstrap.swift`: 시드 `activeJourney`(ready + 출발 확인 전 진행 여정 1건).
- 자산: `TicketDots.imageset`(ticket-seoul-dots.png), `BoardMap.imageset`(board-image-0.png).

## GREEN 증거
UI focused: BoardingFlowUITests(U1·라벨) + ActiveJourneyMainUITests 3 + PreparationFlowUITests·PreparationEditorUITests·Phase1FlowTests 전체 통과(34건 중 실패 1건은 board.route 라벨이 StaticText로 잡힌 것 → Color.clear 요소로 수정 후 재실행 통과). U3(T7 RED)는 이 태스크 범위 밖.

## REFACTOR 내역
정리 없음.

## self-review 결과
- 버스 번호·분이 보이는 텍스트에 없음(board.route는 비텍스트 요소).
- 메인 안내 문구 "진행 중인 여정이 있어요" + 보조 문장.
- 툴바에 식별자 두지 않음(W11 교훈), screen.board는 본문 컨테이너.

## 우려사항
없음.
