
## Part A (red-writer A: 새 동작 테스트, 신규 파일만)

작성 파일(ios/FocusMateTests/), 테스트 수 109:
- W16bTestSupport.swift (공용 헬퍼: W16bFixtures, W16bLoadFailure, W16bCallCounter)
- RouteDataMigrationTests.swift (19)
- JourneySnapshotV5Tests.swift (11)
- RouteReachTests.swift (14)
- CourseJourneyTests.swift (9)
- JourneyPlanDraftCatalogTests.swift (16)
- RouteDataLifecycleModelTests.swift (34)
- StoredJourneyDisplayTests.swift (6: RecordCompletionInput/ActiveJourneyCardContent/ArrivalBriefingContent/LiveActivity attributes)

빌드·테스트는 실행하지 않음(컴파일 확인은 오케스트레이터).

픽스처: RouteCatalogFixture(기존 테스트 파일)로 직접 만든 카탈로그. 정류장 A(에이) B(비) C(씨) D(디), 노선 id "r-100"(번호 100, 간선) A→B→C→D 구간 초 [600,540,360] 미터 [500,600,700], 25분(1500초)에 D 정확 일치. multi()는 r-200(지선 직행 3000m)·r-300(후보 불가) 추가. 저장 여정의 이름은 일부러 카탈로그와 다르게 "옛 에이"/"옛 디".

명세 해석·위험 메모:
- 의존하는 기존 헬퍼: RouteCatalogFixture, LifecycleProbe(JourneyLifecycleTestDoubles), assertStorageIssue/withTemporaryFile(StorageTestSupport). B가 이 파일들의 이름·시그니처를 바꾸면 깨진다. BoardingFixtures는 쓰지 않음.
- RouteCandidate는 기존 테스트 관용대로 `.id`(= 노선 id), `.busNumber`, `.destination`, `.stops`, `.distanceText` 사용(명세의 routeID 표기는 쓰지 않음).
- currentStationBound/RouteOrigin.boundLabel 기대값 "비 방면": 기존 RouteCatalogTests(S1→베타 방면)에 맞춰 "노선상 다음 정류장 이름 + 방면"으로 해석(단일 노선 카탈로그에서만 단언).
- journeyCandidates/journeyProceedState는 AppModel이 기본 25분 draft를 가진다고 해석(후보 ["r-100"], .needsSelection).
- restartStationSelection: 저장 실패 시 false + 정류장 유지만 단언(notice 상태는 단언 안 함). 경로는 launchState == .ready(.initialStationEntry)로 확인.
- BR-16: 진행 여정이 있으면 초기화하지 않음, 로딩 실패 시 초기화하지 않음으로 해석.
- v3·v4 옛 진행 여정 JSON은 현실적인 옛 형식 객체를 넣되 내용 해석은 기대하지 않음. 정류장·여정이 모두 없던 옛 파일은 migration nil.
- v1~v4 카드 2장 손상은 .invalidState(.multipleCards(2))로 단언.
- 하차(AC-36) 테스트는 카탈로그 로딩 중(.loading) 스토어에서 진행해 arrivedStation·저장 필드만 쓰는지 확인. 하차 후 records는 시드 1건 + 새 1건(2건)으로 단언.
- RecordCompletionInput 검증은 id/completedAt/bus/from/to/minutes/task/tag(이름)만(tagColor/sound 제외).
- JourneyLiveActivityPolicy.attributes는 XCTUnwrap 없이 직접 사용(비옵셔널 계약).

참조한 파일: .dev/feat-seoul-real-route-data/w16b-t3-interfaces.md, ios/FocusMateTests/{RouteCatalogTestFixtures, RouteLegTests, RouteCandidatesTests, RouteCatalogStoreTests, StationSearchTests, SnapshotCodecTests, JourneySnapshotTests, JourneySnapshotV4StorageTests, BoardingTestDoubles, StorageTestSupport, AlightingModelTests, JourneyLifecycleModelTests, JourneyLifecycleTestDoubles, ActiveJourneyCardContentTests, ArrivalBriefingControllerTests, JourneyLiveActivityPolicyTests, JourneyCourseProgressTests, StationSearchStateTests, JourneyPlanDraftTests, RecordSectionTests, AppFoundationTests, JourneyStartModelTests}.swift (프로덕션 코드·prd·design 미열람)
- 수정: testConfirmNewJourneyAfterArrivalWorksWhileLoading -> testConfirmNewJourneyIsRejectedAfterArrivalRegardlessOfAvailability (도착 여정 confirmNewJourney는 loading/ready/failed 모두 .rejected, 저장 0회; W09 규칙).

## 오케스트레이터 테스트 수정 (컴파일 결함)
- StoredJourneyDisplayTests.testRecordCompletionInputComesFromStoredFields: 명세 `init(alighting:completedAt: Date)`와 달리 문자열을 넘겨 컴파일 실패 → Date(2026-10-13T01:00:00Z)로 바꾸고 기대 문자열을 기존 포맷(소수 초 포함) "2026-10-13T01:00:00.000Z"로 맞춤. 단언 의도(저장 필드 출처) 불변.
- 수정: testV5FileMissingStoredFieldFailsToDecode -> testV5FileMissingStoredFieldDropsOnlyTheJourney (destinationName 누락 v5 여정은 decode 성공, journey.active nil, 카드·정류장 유지; JourneySection 기존 계약).
- R1 리뷰 재현: RouteDataLifecycleModelTests에 testRetryLoadAfterReadFailureMigratesLegacyFile(읽기 실패 후 retryLoad 이전), testConfirmInitialStationResetsJourneyPlanDraft(정류장 확정 시 journeyPlan 초기화) 추가. 가정: 모델 API retryLoad(), journeyPlan(var), launchState .failed. 분 초기화는 25분 상태에서만 확인 가능(약함).
- R1 재현 테스트 컴파일 결함(오케스트레이터): launchState .failed → .failed(.unreadable) (읽기 실패는 StorageIssue.unreadable)
