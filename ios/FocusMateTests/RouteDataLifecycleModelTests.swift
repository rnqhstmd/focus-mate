import Foundation
import XCTest
@testable import FocusMate

/// AppModel + RouteCatalogStore 주입: 가용성, 이전 알림, 정류장 재선택, 도달 정류장 기반 새 여정·포기·하차.
@MainActor
final class RouteDataLifecycleModelTests: XCTestCase {
    private typealias F = W16bFixtures

    private func lastSaved(_ probe: LifecycleProbe) throws -> AppSnapshot {
        try SnapshotCodec.decode(try XCTUnwrap(probe.writes.last))
    }

    private func readyModel(
        station: StationSnapshot? = F.stationA, active: JourneySnapshot? = nil,
        catalog: RouteCatalog, probe: LifecycleProbe
    ) throws -> AppModel {
        try F.model(
            snapshot: F.appSnapshot(station: station, active: active),
            routeData: RouteCatalogStore(ready: catalog), probe: probe
        )
    }

    // MARK: 가용성

    // 깨짐: 로딩 전 가용성이 .loading이 아니거나 카탈로그가 노출되면 실패한다.
    func testAvailabilityIsLoadingBeforeStartAndCatalogIsNil() throws {
        let model = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertEqual(model.routeAvailability, .loading)
        XCTAssertNil(model.routeCatalog)
    }

    // 깨짐: 모델이 주입한 스토어의 준비 상태를 반영하지 않으면 실패한다.
    func testReadyStoreIsExposedByModel() throws {
        let catalog = try F.single()
        let model = try readyModel(catalog: catalog, probe: LifecycleProbe())
        XCTAssertEqual(model.routeAvailability, .ready(catalog))
        XCTAssertEqual(model.routeCatalog, catalog)
    }

    // 깨짐: startRouteData가 로딩을 시작하지 않거나 완료 후 상태를 반영하지 않으면 실패한다.
    func testStartRouteDataLoadsCatalog() async throws {
        let catalog = try F.single()
        let model = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(catalog), probe: LifecycleProbe()
        )
        await model.startRouteData().value
        XCTAssertEqual(model.routeAvailability, .ready(catalog))
    }

    // 깨짐: 로딩 실패를 .failed로 반영하지 않으면 실패한다.
    func testStartRouteDataFailureIsFailed() async throws {
        let model = try F.model(
            snapshot: F.appSnapshot(), routeData: RouteCatalogStore(load: { throw W16bLoadFailure() }),
            probe: LifecycleProbe()
        )
        await model.startRouteData().value
        XCTAssertEqual(model.routeAvailability, .failed)
    }

    // 깨짐: start()가 카탈로그 로딩을 시작하면 카운터가 1이 되어 실패한다 (AC-55).
    func testStartDoesNotStartCatalogLoading() throws {
        let counter = W16bCallCounter()
        let catalog = try F.single()
        let probe = LifecycleProbe()
        let model = AppModel(
            store: F.store(bytes: try SnapshotCodec.encode(F.appSnapshot()), probe: probe),
            routeData: RouteCatalogStore(load: { counter.increment(); return catalog })
        )
        model.start()
        XCTAssertEqual(counter.count, 0)
        XCTAssertEqual(model.routeAvailability, .loading)
    }

    // MARK: 이전(start)

    private func legacyModel(version: Int, probe: LifecycleProbe) throws -> AppModel {
        AppModel(
            store: F.store(bytes: try F.legacyData(version: version), probe: probe),
            routeData: RouteCatalogStore(ready: try F.single())
        )
    }

    // 깨짐: 이전을 v5로 1회 저장하지 않거나 저장본에 정류장이 남으면 실패한다.
    func testStartPersistsMigratedSnapshotOnce() throws {
        let probe = LifecycleProbe()
        let model = try legacyModel(version: 4, probe: probe)

        model.start()

        XCTAssertEqual(probe.writes.count, 1)
        let report = try SnapshotCodec.decodeReport(try XCTUnwrap(probe.writes.first))
        XCTAssertNil(report.migration)
        XCTAssertNil(report.snapshot.currentStation)
        XCTAssertEqual(report.snapshot.cards.items.map(\.id), [F.cardID])
        XCTAssertEqual(report.snapshot.records.items, [F.record])
    }

    // 깨짐: 이전 후 안내(routeDataReplaced)와 정류장 선택 화면으로의 진입이 없으면 실패한다.
    func testStartAfterMigrationSetsNoticeAndOpensStationEntry() throws {
        let probe = LifecycleProbe()
        let model = try legacyModel(version: 3, probe: probe)

        model.start()

        XCTAssertEqual(model.stationResetNotice, .routeDataReplaced)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        XCTAssertNil(model.snapshot?.currentStation)
    }

    // 깨짐: v5 파일에서 저장하거나 안내를 띄우면 실패한다.
    func testStartWithV5DoesNotSaveOrNotify() throws {
        let probe = LifecycleProbe()
        let model = AppModel(
            store: F.store(bytes: try SnapshotCodec.encode(F.appSnapshot()), probe: probe),
            routeData: RouteCatalogStore(ready: try F.single())
        )

        model.start()

        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNil(model.stationResetNotice)
        XCTAssertEqual(model.snapshot?.currentStation, F.stationA)
    }

    // 깨짐: 정류장·여정이 없던 옛 파일에서 안내를 띄우거나 저장하면 실패한다.
    func testStartWithLegacyFileWithoutStationsDoesNotNotify() throws {
        let probe = LifecycleProbe()
        let model = AppModel(
            store: F.store(bytes: try F.legacyData(version: 4, station: nil), probe: probe),
            routeData: RouteCatalogStore(ready: try F.single())
        )

        model.start()

        XCTAssertNil(model.stationResetNotice)
    }

    // MARK: 안내 문구

    // 깨짐: 안내 문구가 명세와 다르면 실패한다.
    func testStationResetReasonTexts() {
        XCTAssertEqual(StationResetReason.routeDataReplaced.text, "정류장 데이터가 서울 전체로 바뀌어 출발 정류장을 다시 골라 주세요")
        XCTAssertEqual(StationResetReason.stationRemoved.text, "저장된 출발 정류장이 서울 버스 데이터에서 사라져 다시 골라 주세요")
    }

    // MARK: BR-16 / restartStationSelection

    // 깨짐: 카탈로그에 없는 현재 정류장을 로딩 후에도 그대로 두면 실패한다 (BR-16).
    func testStartRouteDataResetsStationMissingFromCatalog() async throws {
        let probe = LifecycleProbe()
        let missing = StationSnapshot(id: "GONE", name: "사라진역")
        let model = try F.model(
            snapshot: F.appSnapshot(station: missing), routeData: F.loadingStore(try F.single()), probe: probe
        )

        await model.startRouteData().value

        XCTAssertEqual(model.stationResetNotice, .stationRemoved)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        let saved = try lastSaved(probe)
        XCTAssertNil(saved.currentStation)
        XCTAssertNil(saved.initialStation)
        XCTAssertEqual(saved.cards.items.map(\.id), [F.cardID])
    }

    // 깨짐: 카탈로그에 있는 정류장을 초기화하면 실패한다.
    func testStartRouteDataKeepsStationPresentInCatalog() async throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: probe
        )

        await model.startRouteData().value

        XCTAssertNil(model.stationResetNotice)
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertEqual(model.snapshot?.currentStation, F.stationA)
    }

    // 깨짐: 진행 여정이 있는데 정류장 부재로 여정까지 지우면 실패한다 (BR-16은 진행 여정 없을 때만).
    func testStartRouteDataDoesNotResetWhileJourneyIsActive() async throws {
        let probe = LifecycleProbe()
        let missing = StationSnapshot(id: "GONE", name: "사라진역")
        let model = try F.model(
            snapshot: F.appSnapshot(station: missing, active: F.journey()),
            routeData: F.loadingStore(try F.single()), probe: probe
        )

        await model.startRouteData().value

        XCTAssertNil(model.stationResetNotice)
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNotNil(model.activeJourney)
    }

    // 깨짐: 로딩 실패 시 정류장을 근거 없이 지우면 실패한다.
    func testStartRouteDataFailureDoesNotResetStation() async throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(station: StationSnapshot(id: "GONE", name: "사라진역")),
            routeData: RouteCatalogStore(load: { throw W16bLoadFailure() }), probe: probe
        )

        await model.startRouteData().value

        XCTAssertNil(model.stationResetNotice)
        XCTAssertEqual(probe.attempts, 0)
    }

    // 깨짐: 재선택이 정류장·여정을 비우고 카드·기록을 유지한 채 한 번 저장하지 않으면 실패한다.
    func testRestartStationSelectionClearsStationsAndJourneyKeepingCardsAndRecords() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(), catalog: try F.single(), probe: probe)

        XCTAssertTrue(model.restartStationSelection(reason: .routeDataReplaced))

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertNil(saved.currentStation)
        XCTAssertNil(saved.initialStation)
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.cards.items.map(\.id), [F.cardID])
        XCTAssertEqual(saved.records.items, [F.record])
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        XCTAssertEqual(model.stationResetNotice, .routeDataReplaced)
        XCTAssertNil(model.activeJourney)
    }

    // 깨짐: 저장 실패인데 true를 돌려주거나 정류장을 비운 상태로 두면 실패한다.
    func testRestartStationSelectionReturnsFalseWhenSaveFails() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(catalog: try F.single(), probe: probe)
        probe.shouldFail = true

        XCTAssertFalse(model.restartStationSelection(reason: .stationRemoved))

        XCTAssertEqual(model.snapshot?.currentStation, F.stationA)
    }

    // 깨짐: 출발 정류장을 다시 확정해도 안내가 남아 있으면 실패한다.
    func testConfirmInitialStationClearsNotice() throws {
        let catalog = try F.single()
        let probe = LifecycleProbe()
        let model = try readyModel(catalog: catalog, probe: probe)
        XCTAssertTrue(model.restartStationSelection(reason: .routeDataReplaced))
        guard case let .results(options, _) = StationSearch.search("에이", in: catalog) else {
            return XCTFail("검색 결과 없음")
        }
        let option = try XCTUnwrap(options.first { $0.id == "A" })

        XCTAssertTrue(model.confirmInitialStation(option))

        XCTAssertNil(model.stationResetNotice)
        XCTAssertEqual(try lastSaved(probe).currentStation, StationSnapshot(id: "A", name: "에이"))
    }

    // MARK: 파생 값

    // 깨짐: 출발 정보가 카탈로그의 정류장 색인·이름·방면과 다르면 실패한다.
    func testJourneyOriginComesFromCatalogStop() throws {
        let catalog = try F.single()
        let model = try readyModel(catalog: catalog, probe: LifecycleProbe())
        let index = try XCTUnwrap(catalog.stopIndex(id: "A"))
        XCTAssertEqual(
            model.journeyOrigin,
            RouteOrigin(stopIndex: index, stopID: "A", name: "에이", boundLabel: "비 방면")
        )
    }

    // 깨짐: 로딩 중이거나 카탈로그에 없는 정류장인데 출발이 있으면 실패한다.
    func testJourneyOriginIsNilWhileLoadingOrWhenStationMissing() throws {
        let loading = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertNil(loading.journeyOrigin)
        let missing = try readyModel(
            station: StationSnapshot(id: "GONE", name: "사라진역"), catalog: try F.single(), probe: LifecycleProbe()
        )
        XCTAssertNil(missing.journeyOrigin)
    }

    // 깨짐: 현재 정류장 방면 문구가 카탈로그 방면과 다르면 실패한다.
    func testCurrentStationBoundIsCatalogBoundLabel() throws {
        let model = try readyModel(catalog: try F.single(), probe: LifecycleProbe())
        XCTAssertEqual(model.currentStationBound, "비 방면")
    }

    // 깨짐: 로딩·실패·정류장 없음에서 방면을 노출하면 실패한다.
    func testCurrentStationBoundIsNilWhenUnavailable() async throws {
        let loading = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertNil(loading.currentStationBound)
        let failed = try F.model(
            snapshot: F.appSnapshot(), routeData: await F.failedStore(), probe: LifecycleProbe()
        )
        XCTAssertNil(failed.currentStationBound)
        let none = try readyModel(station: nil, catalog: try F.single(), probe: LifecycleProbe())
        XCTAssertNil(none.currentStationBound)
    }

    // 깨짐: 로딩 중에도 끝낼 수 있다고 하거나 준비·실패에서 막으면 실패한다.
    func testCanEndActiveJourneyIsFalseOnlyWhileLoading() async throws {
        let loading = try F.model(
            snapshot: F.appSnapshot(active: F.journey()), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertFalse(loading.canEndActiveJourney)
        let ready = try readyModel(active: F.journey(), catalog: try F.single(), probe: LifecycleProbe())
        XCTAssertTrue(ready.canEndActiveJourney)
        let failed = try F.model(
            snapshot: F.appSnapshot(active: F.journey()), routeData: await F.failedStore(), probe: LifecycleProbe()
        )
        XCTAssertTrue(failed.canEndActiveJourney)
    }

    // 깨짐: 진행 상태 판정이 로딩/실패/출발 없음/선택 필요 순서로 나오지 않으면 실패한다.
    func testJourneyProceedStateFollowsAvailabilityAndOrigin() async throws {
        let loading = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertEqual(loading.journeyProceedState, .routeDataLoading)
        let failed = try F.model(
            snapshot: F.appSnapshot(), routeData: await F.failedStore(), probe: LifecycleProbe()
        )
        XCTAssertEqual(failed.journeyProceedState, .routeDataFailed)
        let missing = try readyModel(
            station: StationSnapshot(id: "GONE", name: "사라진역"), catalog: try F.single(), probe: LifecycleProbe()
        )
        XCTAssertEqual(missing.journeyProceedState, .originUnavailable)
        let ready = try readyModel(catalog: try F.single(), probe: LifecycleProbe())
        XCTAssertEqual(ready.journeyProceedState, .needsSelection)
    }

    // 깨짐: 기본 25분 후보가 카탈로그 노선에서 계산되지 않으면 실패한다.
    func testJourneyCandidatesComeFromCatalog() throws {
        let model = try readyModel(catalog: try F.single(), probe: LifecycleProbe())
        XCTAssertEqual(model.journeyCandidates.map(\.id), ["r-100"])
        let loading = try F.model(
            snapshot: F.appSnapshot(), routeData: F.loadingStore(try F.single()), probe: LifecycleProbe()
        )
        XCTAssertEqual(loading.journeyCandidates, [])
    }

    // MARK: 새 여정 / 포기 (reachedStation(in: routeAvailability))

    // 깨짐: 로딩 중 확정이 저장하거나 .done이면 실패한다 (.notLoaded → .rejected, 저장 0회).
    func testConfirmNewJourneyIsRejectedWhileLoadingWithoutSaving() throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(active: F.journey()), routeData: F.loadingStore(try F.single()), probe: probe
        )
        XCTAssertEqual(model.confirmNewJourney(), .rejected)
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNotNil(model.activeJourney)
    }

    // 깨짐: 로딩 중 포기가 저장하거나 .done이면 실패한다.
    func testAbandonIsRejectedWhileLoadingWithoutSaving() throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(active: F.journey()), routeData: F.loadingStore(try F.single()), probe: probe
        )
        model.open(.journey)
        XCTAssertEqual(model.abandonJourney(timerPaused: true), .rejected)
        XCTAssertEqual(probe.attempts, 0)
        XCTAssertNil(model.abandonNotice)
    }

    // 깨짐: 경과 600초에서 현재 정류장을 B(카탈로그 이름)로 저장하지 않으면 실패한다.
    func testConfirmNewJourneyWhenReadySavesReachedStationFromCatalog() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(elapsedSeconds: 600), catalog: try F.single(), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.currentStation, StationSnapshot(id: "B", name: "비"))
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.records.items, [F.record])
        XCTAssertNil(model.activeJourney)
    }

    // 깨짐: 실패 상태에서 새 여정이 막히거나 출발 정류장(저장 이름)을 쓰지 않으면 실패한다.
    func testConfirmNewJourneyWhenFailedStaysAtStoredOrigin() async throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(active: F.journey(elapsedSeconds: 600)),
            routeData: await F.failedStore(), probe: probe
        )

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(try lastSaved(probe).currentStation, StationSnapshot(id: "A", name: "옛 에이"))
    }

    // 깨짐: 노선이 사라졌을 때 출발 정류장을 카탈로그 이름으로 유지하지 않으면 실패한다.
    func testConfirmNewJourneyWhenRouteGoneStaysAtOriginWithCatalogName() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(), catalog: try F.withoutRoute100(), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(try lastSaved(probe).currentStation, StationSnapshot(id: "A", name: "에이"))
    }

    // 깨짐: 출발 정류장까지 사라졌을 때 정류장 재선택(저장·안내·진입)으로 가지 않으면 실패한다.
    func testConfirmNewJourneyWhenOriginGoneRestartsStationSelection() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(), catalog: try F.withoutStopA(), probe: probe)

        XCTAssertEqual(model.confirmNewJourney(), .done)

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertNil(saved.currentStation)
        XCTAssertNil(saved.initialStation)
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(model.stationResetNotice, .stationRemoved)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
    }

    // 깨짐: 도착한 여정에서 confirmNewJourney가 저장하거나 .done이면 실패한다 (도착 여정은 하차로만 끝낸다, W09).
    func testConfirmNewJourneyIsRejectedAfterArrivalRegardlessOfAvailability() async throws {
        let stores: [RouteCatalogStore] = [
            F.loadingStore(try F.single()), RouteCatalogStore(ready: try F.single()), await F.failedStore(),
        ]
        for store in stores {
            let probe = LifecycleProbe()
            let model = try F.model(
                snapshot: F.appSnapshot(active: F.journey(elapsedSeconds: 1500)), routeData: store, probe: probe
            )

            XCTAssertEqual(model.confirmNewJourney(), .rejected)

            XCTAssertEqual(probe.attempts, 0)
            XCTAssertNotNil(model.activeJourney)
        }
    }

    // 깨짐: 포기 성공 안내가 결과 정류장 이름(카탈로그 이름)이 아니면 실패한다.
    func testAbandonWhenReadySetsNoticeToReachedStationName() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(elapsedSeconds: 600), catalog: try F.single(), probe: probe)
        model.open(.journey)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)

        XCTAssertEqual(try lastSaved(probe).currentStation, StationSnapshot(id: "B", name: "비"))
        XCTAssertEqual(model.abandonNotice, "비")
    }

    // 깨짐: 재선택이 필요한 포기에서 안내 이름을 남기거나 재선택 안내를 놓치면 실패한다.
    func testAbandonWhenOriginGoneClearsNoticeAndRestartsSelection() throws {
        let probe = LifecycleProbe()
        let model = try readyModel(active: F.journey(), catalog: try F.withoutStopA(), probe: probe)
        model.open(.journey)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)

        XCTAssertNil(model.abandonNotice)
        XCTAssertEqual(model.stationResetNotice, .stationRemoved)
        XCTAssertNil(try lastSaved(probe).currentStation)
    }

    // MARK: 하차 (AC-36)

    // 깨짐: 하차가 카탈로그(로딩 중)에 의존하거나 기록 from/to/bus·현재 정류장이 저장 필드에서 오지 않으면 실패한다.
    func testAlightingUsesStoredFieldsWithoutCatalog() throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(active: F.journey(elapsedSeconds: 1500)),
            routeData: F.loadingStore(try F.single()), probe: probe
        )
        XCTAssertEqual(model.beginAlighting(), .done)
        XCTAssertEqual(model.confirmArrival(timerArrived: true), .done)

        XCTAssertTrue(model.alightJourney())

        XCTAssertEqual(probe.writes.count, 1)
        let saved = try lastSaved(probe)
        XCTAssertEqual(saved.records.items.count, 2)
        let record = try XCTUnwrap(saved.records.items.first { $0.id == "journey-1" })
        XCTAssertEqual(record.bus, "100")
        XCTAssertEqual(record.from, "옛 에이")
        XCTAssertEqual(record.to, "옛 디")
        XCTAssertEqual(record.minutes, 25)
        XCTAssertEqual(saved.currentStation, StationSnapshot(id: "D", name: "옛 디"))
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(model.alightingSummary?.destinationName, "옛 디")
    }

    // MARK: R1 리뷰 재현

    // 깨짐: 첫 읽기 실패 뒤 retryLoad로 옛 형식을 읽을 때 v5 저장·안내·정류장 선택 진입을 건너뛰면 실패한다.
    func testRetryLoadAfterReadFailureMigratesLegacyFile() throws {
        let probe = LifecycleProbe()
        let legacy = try F.legacyData(version: 4)
        var reads = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                reads += 1
                if reads == 1 { throw LifecycleProbe.Failure.expected }
                return legacy
            },
            createDirectory: { _ in },
            writeData: { data, _ in try probe.record(data) }
        )
        let model = AppModel(store: store, routeData: RouteCatalogStore(ready: try F.single()))

        model.start()
        XCTAssertEqual(model.launchState, .failed(.unreadable))
        XCTAssertEqual(probe.attempts, 0)

        model.retryLoad()

        XCTAssertEqual(probe.writes.count, 1)
        let report = try SnapshotCodec.decodeReport(try XCTUnwrap(probe.writes.first))
        XCTAssertNil(report.migration)
        XCTAssertNil(report.snapshot.currentStation)
        XCTAssertEqual(model.stationResetNotice, .routeDataReplaced)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
    }

    // 깨짐: 정류장 확정이 시간 선택 초안(선택 노선·분)을 초기화하지 않으면 이전 정류장의 선택이 남아 실패한다.
    func testConfirmInitialStationResetsJourneyPlanDraft() throws {
        let catalog = try F.single()
        let probe = LifecycleProbe()
        let model = try readyModel(catalog: catalog, probe: probe)
        let origin = try XCTUnwrap(model.journeyOrigin)
        XCTAssertTrue(model.journeyPlan.choose(routeID: "r-100", origin: origin, catalog: catalog))
        XCTAssertNotNil(model.journeyPlan.selectedRouteID)
        XCTAssertTrue(model.restartStationSelection(reason: .stationRemoved))
        guard case let .results(options, _) = StationSearch.search("에이", in: catalog) else {
            return XCTFail("검색 결과 없음")
        }
        let option = try XCTUnwrap(options.first { $0.id == "A" })

        XCTAssertTrue(model.confirmInitialStation(option))

        XCTAssertNil(model.journeyPlan.selectedRouteID)
        XCTAssertEqual(model.journeyPlan.minutes, JourneyPlanner.initialMinutes)
    }

    // MARK: AC-45 연속 시나리오

    // 깨짐: 로딩 중 포기를 막지 않거나, 로딩 완료 후에도 같은 포기가 거절되면(또는 도달 정류장이 다르면) 실패한다.
    func testAC45_로딩_중_포기는_거절되고_로딩_후_같은_포기는_도달_정류장으로_성공한다() async throws {
        let probe = LifecycleProbe()
        let model = try F.model(
            snapshot: F.appSnapshot(active: F.journey(elapsedSeconds: 600)),
            routeData: F.loadingStore(try F.single()), probe: probe
        )
        model.open(.journey)

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .rejected)
        XCTAssertEqual(probe.attempts, 0)

        await model.startRouteData().value

        XCTAssertEqual(model.abandonJourney(timerPaused: true), .done)
        XCTAssertEqual(probe.writes.count, 1)
        XCTAssertEqual(try lastSaved(probe).currentStation, StationSnapshot(id: "B", name: "비"))
        XCTAssertNil(try lastSaved(probe).journey.active)
    }
}
