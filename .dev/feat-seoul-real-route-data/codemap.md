## 코드 맵: W16 서울 전체 실데이터 번들(정류장·노선·버스·구간 시간)

### 핵심 파일
- ios/FocusMate/RouteData.swift → 예시 데이터: `StopPosition`(index·direction), `RouteStops`(9개 순환 정류장·wrap·boundLabel·position(of:)), `StationOption`/`StationCatalog`(검색 3건), `BusLine`(3종, minutesPerStop)
- ios/FocusMate/JourneyPlanner.swift → 후보 규칙: `minutes % minutesPerStop == 0`인 버스만, 도착지 = 순환 wrap, 거리 0.55km/정류장
- ios/FocusMate/JourneyCourse.swift → W06 정류장 id별 근사 좌표 표·서울 경계·닫힌 직선 코스
- ios/FocusMate/JourneyReach.swift → 도달 정류장(경과 ÷ 간격 몫, 방향 유지), `reachedStation`, `endingActiveJourney`
- ios/FocusMate/JourneySnapshot.swift:24 → 저장 필드 originStopID·direction·minutes·busID·destinationStopID, originName/destinationName/bus 조회가 RouteStops·BusLine 의존

### 참조 파일
- ios/FocusMate/JourneyCourseProgress.swift → `CourseJourney` 진도 → 버스 위치·다음/남은 정류장·남은 거리(55/정류장)
- ios/FocusMate/StationSearchState.swift → 검색어 → StationCatalog.search
- ios/FocusMate/InitialStationSearchView.swift → 최초 정류장 검색 화면
- ios/FocusMate/AppModel+JourneyStart.swift → currentStation → StopPosition, 정류장 확정 저장
- ios/FocusMate/PreparationDraft.swift:139 / TimeSelectionView.swift:46 / BoardingPassContent.swift:32 → 이름·방면·버스 표시
- ios/FocusMate/UITestBootstrap.swift:275 → UI 테스트 시드가 RouteStops·BusLine id에 의존
- ios/FocusMateTests/{StationCatalogTests,JourneyPlannerTests,JourneyCourseTests,JourneyReachTests?}.swift → 기존 규칙 테스트

### 설정
- ios/FocusMate.xcodeproj/project.pbxproj → objectVersion 77 동기화 폴더(리소스 번들 포함 방식 확인 필요)
- scripts/check-ios.py → build/test [files], FOCUSMATE_SIMULATOR_ID
- .dev/plan.md:51 → W16 범위 메모(원천 OA-1095 xlsx, 거리÷평균속도, 변환 스크립트, 다시 정할 항목)
- ios/FocusMate/AppSnapshot.swift → 저장 현재/최초 정류장 형식(id·이름·방향)과 단계 일관성
- ios/FocusMate/ProfileView.swift → 마이페이지(데이터 출처 항목 신규 위치)
- ios/FocusMate/Resources/Fonts/SOURCE.md → 기존 공공누리 출처 표기 선례
