## 코드 맵: W02 첫 출발지·시간·버스·도착지 선택 (journey FR-7, FR-8)

### 핵심 파일
- ios/FocusMate/AppModel.swift:17 → `AppModel` 진입 상태(launchState)·스냅샷·`save(_:)` 전체 교체 저장·네비게이션 path(Destination)
- ios/FocusMate/AppSnapshot.swift:14 → `AppSnapshot`(cardIssued·initialStation·currentStation + cards/journey/records), `updatingStage`/`updating…`, `validate()`·`launchRoute()`; `StationSnapshot{id,name,direction(1|-1)}`
- ios/FocusMate/RootView.swift:52 → 진입 분기별 화면. `.initialStationEntry`는 제목만 있는 자리표시, `.main`은 현재 정류장·방향 + Destination 버튼(preparation 등)
- ios/FocusMate/JourneySection.swift:11 → `JourneySection{active: JourneySnapshot?}` 진행 여정 섹션(W00, 원소 미정의)
- ios/FocusMate/SnapshotCodec.swift:11 → 저장 파일 v2 인코딩/디코딩·v1 마이그레이션

### 참조 파일
- designs/final/animation-preview.html:670 → 웹 `stationCatalog`(성수역 정/역방향, 서울숲역) · `searchStations`(이름+별칭+방면 검색, 결과 없음 시 확인 불가) · `selectStation`/`confirmStation`
- designs/final/animation-preview.html:642 → `busOptions`(2014 지선 5분/정류장, 강남02 마을 6분, 343 간선 8분)
- designs/final/animation-preview.html:788 → `stopNames` 9개 순환 정류장
- designs/final/animation-preview.html:795 → `selectTime`(15~360 1분 단위, 시간 변경 시 선택 해제) · :856 `timeJourneyOptions`(분이 정류장당 분으로 나누어떨어지는 버스만, 도착지 = wrap(origin + heading*stops)) · :860 `chooseTimeJourney` · :861 `renderTimeJourneys`(후보 없음/미선택 시 다음 불가)
- ios/FocusMate/UITestBootstrap.swift:4 → UI 테스트 시드(none/cardOnly/ready/corrupt/unsupported)·저장 실패 시나리오
- ios/FocusMateTests/StorageTestSupport.swift:6 → 저장 테스트 공통 헬퍼(stage·assertStorageIssue·withTemporaryFile)
- ios/FocusMateUITests/Phase1FlowTests.swift → Phase 1 진입 분기 UI 테스트

### 설정
- .claude/config.json → projectTypes(node: npm test/build, ios-swiftui: python3 scripts/check-ios.py test/build)
- docs/FLOWS.md → `search`·`time` 화면 계약(성공·차단·저장)
- context/journey/status.md:23 → FR-7(AC-9)·FR-8(AC-10)
