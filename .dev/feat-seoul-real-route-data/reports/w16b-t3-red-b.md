# W16b T3 RED part B - 기존 단위 테스트 이전 보고

빌드·테스트 실행 없음(컴파일 확인은 오케스트레이터). UI 테스트와 프로덕션 코드는 손대지 않았다. 새 파일 없음(기존 파일 수정·삭제만).

## 수정한 파일
- 공용: BoardingTestDoubles.swift (JourneySelection 새 init, F.journey(originName/busNumber/busKind/destinationName 추가, direction 제거), 새 헬퍼 readyRouteData() / uiCatalog() / chooseRoute(_:in:), originName "성수역", distanceMeters 6_600)
- 저장·코덱: SnapshotCodecTests, StorageV2Tests, JourneySnapshotStorageTests, JourneySnapshotV4StorageTests(파일명 유지, 내용은 v5), CardStorageTests, CardStyleStorageTests, CardSupplementTests, CardIssuanceModelTests, CardCustomizationAppModelTests, ProfileModelTests, RecordStorageTests, AppFoundationTests, AppRecoveryTests, StorageRecoveryTests
- 여정·계획: JourneySnapshotTests, JourneyPlanDraftTests, JourneyPlannerTests, PreparationDetailsTests, PreparationModelTests, BoardingModelTests, BoardingPassContentTests, JourneyTimerModelTests, JourneyStartModelTests, StationSearchStateTests
- 코스·도달·하차·생명주기: JourneyCourseProgressTests, JourneyMapControllerTests, JourneyReachTests, LifecycleSeedTests, AlightingSnapshotTests, AlightingModelTests, JourneyLifecycleModelTests
- 비실패 계약 전환: ActiveJourneyCardContentTests, ArrivalBriefingControllerTests, JourneyLiveActivityPolicyTests, JourneyLiveActivitySyncTests
- 기계적 변경(StationSnapshot direction 인자 제거): 위 파일 외 AppSnapshotSectionsTests 등

## 삭제한 파일·테스트와 이유
- StationCatalogTests.swift 전체 삭제: StationCatalog 삭제됨. 검색 동작은 StationSearchTests가 카탈로그 기준으로 이미 다룬다.
- JourneyCourseTests.swift 전체 삭제: JourneyCourse enum(stops/closedPath/point(at:)/seoulBounds) 삭제. 코스 구성은 CourseJourneyTests(A)가 다룬다.
- JourneyPlannerTests: candidates 5건 이상·distanceText·접근성 라벨·BusLine 정의 테스트 삭제(후보 계산은 RouteCandidatesTests, uiTestFixture 후보는 RouteCatalogTests가 다룸). clamp·minuteRange·initialMinutes만 유지.
- JourneyReachTests: reachedStops(칸 수 몫/상한)·JourneyReach.station(wrap/방향) 테스트 삭제(JourneyReach 삭제). 같은 의도를 uiTestFixture 위 reachedStation(in:) 경계표·역방향·순환·출발대기·도착 우선·카탈로그 밖 출발지(reselectStation)로 이전.
- JourneySnapshotTests: 카탈로그 조회(originName/bus), unknownStop/unknownBus, invalidDirection 테스트 삭제. emptyField 필드 확장, nameTooLong, 카탈로그 밖 id 통과 테스트로 대체. 도착지 계산 테스트(12정류장) 삭제(boarding이 details.journey를 복사하므로 필드 복사 테스트로 대체).
- JourneySnapshotStorageTests: v2 active 객체 corrupt, v2 null, v3 active 손상 3종(빈 객체/문자열/active 키 없음) 삭제(v1~v4 처리는 다른 작성자 범위). 아이콘·카드 불일치·진도 5 손상 3건은 v5 기준으로 유지.
- JourneySnapshotV4StorageTests: unknownStop/unknownBus 쓰기·읽기 6건, v3 읽기(AC-24~26) 7건 삭제. 분·경과·paused 검증과 왕복은 version 5로 유지.
- SnapshotCodecTests: LegacySnapshotV1/migrateV1 내부 함수 테스트 삭제(spec에 없음), v1 골든 재인코딩 테스트를 정류장 있는 스냅숏 v5 골든으로 교체.
- AppFoundationTests: invalidDirection 케이스 2건 삭제.
- StationSearchStateTests: 3건 고정 결과·방향 기반 테스트를 acceptance 카탈로그 기반 6건으로 재작성.
- JourneyMapControllerTests: 남은 거리(0.1km) 단언 삭제(카탈로그 미터는 CourseJourneyTests가 손계산). 정류장 9개/닫는 선 10점 → 6개/6점(닫는 선 없음).
- JourneyCourseProgressTests: 9정류장 순환·방향 180도·1초 스윕·거리 반올림 테스트 삭제. uiTestFixture 2014 코스 기준 위치·보간·도착·남은 정류장·다음 정류장으로 축소.
- ArrivalBriefingControllerTests / JourneyLiveActivityPolicyTests: "카탈로그 밖이면 nil" 3건 삭제(non-failable). 저장 값 사용 테스트로 대체.
- LifecycleSeedTests: 승차 식 일치(JourneyReach) 테스트를 카탈로그 leg 계산으로 교체, 저장 이름 4종 복사 테스트 추가, direction 단언 삭제.

## 레거시 바이트 사용 테스트의 처리 원칙
- "현재 형식 로드" 용도의 v1/v2 바이트는 v5 JSON(version 5, direction 없음, 영역 키 포함)으로 교체: AppFoundation, AppRecovery, CardIssuance, Profile, RecordStorage(emptyV5/envelope).
- 정류장이 필요 없는 카드 보충·카드 꾸미기 테스트의 레거시 바이트는 정류장 null로 바꿔 migration 쓰기가 끼지 않게 함: CardSupplementTests(→ presentedRoute .initialStationEntry), CardCustomizationAppModelTests(legacyV2 정류장 null, 필요한 곳에서 명시 저장).
- v1/v2를 일부러 읽는 테스트는 정류장 nil 기대로 변경: StorageV2Tests AC1, CardStyleStorageTests, RecordStorageTests AC14.
- 미지원 버전 샘플은 5 → 6.
- 오류 판정(inconsistentStage 등)이 필요한 레거시 바이트는 그대로 둠(spec: 기존 손상 판정 유지).

## 명세 해석 메모 / 모호한 점
1. StationSearchState 초기화는 인자 없는 `StationSearchState()` + `state.query = ...`로 가정(spec에 init 없음).
2. RouteCandidate는 `routeID`, `destination`, `stops`를 쓴다(spec의 busID=RouteCandidate.routeID 근거).
3. AppModel.journeyPlan은 기존처럼 var JourneyPlanDraft이고 `selectedRouteID`가 `selectedBusID`를 대체한다고 가정(spec에 selectedRouteID 명시).
4. 헬퍼 chooseRoute는 model.journeyOrigin/routeCatalog로 `journeyPlan.choose(routeID:origin:catalog:)`를 호출.
5. PreparationModelTests·CardCustomization 등은 distanceMeters를 카탈로그 값에서 받아 `> 0`만 단언(fixture 구간 미터 미상). PreparationDetails/BoardingPass는 6_600 → "6.6km"(RouteCandidates와 같은 소수 1자리 규칙 가정).
6. JourneyLifecycleModelTests·AlightingModelTests·Boarding·JourneyTimer·JourneyStart·Preparation·CardCustomization 모델은 `routeData: BoardingFixtures.readyRouteData()`(RouteCatalogStore(ready:))로 주입. AppModel 기본값(번들 로더)은 start가 로딩을 시작하지 않아 .loading 이므로 reachedStation(.loading)=.notLoaded 로 거절되기 때문.
7. v5에서 active 손상(모르는 아이콘·카드 불일치·진도 불일치)이 "진행 여정만 버리고 읽힌다"는 기존 동작이 유지된다고 가정(spec은 "기존 손상 판정 유지"만 명시). 다르면 JourneySnapshotStorageTests / V4StorageTests 해당 케이스 조정.
8. 역방향 노선 목적지 id(seoulForest-r에서 25분 → seongsuIntersection-r, seongsu-r에서 → seoulForest-r)는 design.md 시드 표와 9정류장 순서에서 손계산. 방면 라벨 "성수동 방면", 이름은 기존 테스트 값(성수역, 성수동, 뚝섬역, 서울숲역, 성수사거리).
9. 302 60분 → 8정류장(seongsuIntersection), 421 120분 → 17정류장(seongsuIntersection)은 design 검산표 기준.
10. RecoveryBootstrapTests의 invalidState 시드는 v1 + direction 키를 그대로 단언(UITestBootstrap 시드는 T5 범위).

## 오케스트레이터 확인 필요
- project.pbxproj는 테스트 파일을 명시 등재한다: 삭제한 StationCatalogTests.swift, JourneyCourseTests.swift 제거와 신규(A) 파일 등재가 필요하다.
- 참고: 조사 중 RouteCatalog+Fixture.swift 첫 5줄이 grep 출력에 노출됐다(내용 활용 없음).

## 추가 (코디네이터 요청)
- JourneyLifecycleTestDoubles.swift: FakeJourneyAbandoner에 `var canEndActiveJourney = true` 추가(JourneyAbandoning 프로토콜 요건, 테스트에서 변경 가능).
- pbxproj 등재 필요 항목은 synced folder라 무시(위 "오케스트레이터 확인 필요" 첫 항목 취소).

## 추가 (ready 시드 현재 정류장 변경)
- RecoveryBootstrapTests: readySnapshot 현재 정류장을 {seoulForest-r, 서울숲}으로 변경(시드 표 반영).
- 그 밖에 ready 시드의 현재 정류장 "seoulForest"를 기대하는 단위 테스트는 grep 결과 없음(ProfileSeedTests·LifecycleSeedTests 확인). UI 테스트는 손대지 않음.
