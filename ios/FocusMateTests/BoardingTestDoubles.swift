import Foundation
import XCTest
@testable import FocusMate

/// 승차권·태그 기능 테스트가 함께 쓰는 픽스처.
enum BoardingFixtures {
    static let cardID = "FM-01234567"
    static let boardedAt = Date(timeIntervalSince1970: 1_791_882_000) // 2026-10-13T09:00:00Z

    static var details: PreparedJourneyDetails {
        let journey = JourneySelection(
            originStopID: "seongsu", originName: "성수역", boundLabel: "성수동 방면", minutes: 60,
            busID: "2014", busNumber: "2014", busKind: "지선",
            destinationStopID: "seongdongSportsCenter", destination: "성동구민체육센터",
            stops: 12, distanceMeters: 6_600
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        return PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)
    }

    /// uiTestFixture 카탈로그가 준비된 RouteCatalogStore. AppModel(routeData:)에 주입한다.
    @MainActor
    static func readyRouteData() -> RouteCatalogStore {
        RouteCatalogStore(ready: uiCatalog())
    }

    static func uiCatalog() -> RouteCatalog {
        // 고정 픽스처이므로 로딩 실패는 테스트 설정 오류다.
        do { return try RouteCatalog.uiTestFixture() } catch { fatalError("uiTestFixture 실패: \(error)") }
    }

    /// 모델의 현재 정류장 기준으로 노선을 고른다. 출발 정류장·카탈로그가 없으면 false.
    @MainActor
    @discardableResult
    static func chooseRoute(_ routeID: String, in model: AppModel) -> Bool {
        guard let origin = model.journeyOrigin, let catalog = model.routeCatalog else { return false }
        return model.journeyPlan.choose(routeID: routeID, origin: origin, catalog: catalog)
    }

    static func awaiting() -> JourneySnapshot {
        JourneySnapshot.boarding(details: details, cardID: cardID, id: "journey-1", boardedAt: boardedAt)
    }

    /// 한 필드만 바꿔 위반 후보를 만든다. 기본값은 유효한 대기 상태 여정.
    static func journey(
        id: String = "journey-1",
        cardID: String = BoardingFixtures.cardID,
        originStopID: String = "seongsu",
        originName: String = "성수역",
        minutes: Int = 60,
        busID: String = "2014",
        busNumber: String = "2014",
        busKind: String = "지선",
        destinationStopID: String = "seongdongSportsCenter",
        destinationName: String = "성동구민체육센터",
        tag: JourneySnapshot.Tag = JourneySnapshot.Tag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand),
        task: String = "책 읽기",
        phase: JourneySnapshot.Phase = .awaitingDeparture,
        elapsedSeconds: Int = 0,
        paused: Bool = false
    ) -> JourneySnapshot {
        JourneySnapshot(
            id: id, cardID: cardID, originStopID: originStopID, originName: originName, minutes: minutes,
            busID: busID, busNumber: busNumber, busKind: busKind,
            destinationStopID: destinationStopID, destinationName: destinationName,
            tag: tag, task: task, sound: .bus,
            boardedAt: boardedAt, phase: phase, progress: JourneySnapshot.Progress(elapsedSeconds: elapsedSeconds), paused: paused
        )
    }

    static func snapshot(active: JourneySnapshot?) -> AppSnapshot {
        let station = StationSnapshot(id: "seongsu", name: "성수")
        return XCTestCase.stage(true, station, station)
            .issuingCard(CardSnapshot(id: cardID, issuedAt: boardedAt))
            .updating(journey: JourneySection(active: active))
    }
}

/// 승차 저장 결과를 순서대로 돌려주고 호출 수를 센다. 결과가 소진되면 true.
@MainActor
final class FakeJourneyBoarder: JourneyBoarding {
    private var results: [Bool]
    private(set) var calls = 0

    init(results: [Bool] = [true]) { self.results = results }

    func boardJourney() -> Bool {
        calls += 1
        return results.isEmpty ? true : results.removeFirst()
    }
}

/// 출발 확정 결과를 순서대로 돌려주고 호출 수를 센다. 결과가 소진되면 true.
@MainActor
final class FakeDepartureConfirmer: DepartureConfirming {
    private var results: [Bool]
    private(set) var calls = 0

    init(results: [Bool] = [true]) { self.results = results }

    func confirmDeparture() -> Bool {
        calls += 1
        return results.isEmpty ? true : results.removeFirst()
    }
}

/// sleep 요청마다 대기를 따로 쌓는다. 요청 순서(0부터)로 골라 resume 할 수 있다.
@MainActor
final class QueuedSleep {
    private(set) var requested: [Duration] = []
    private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var waiter: (count: Int, continuation: CheckedContinuation<Void, Never>)?

    func sleep(_ duration: Duration) async {
        let position = requested.count
        requested.append(duration)
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            continuations[position] = c
            if let w = waiter, requested.count >= w.count {
                waiter = nil
                w.continuation.resume()
            }
        }
    }

    /// 요청이 count 건 이상 쌓여 멈출 때까지 기다린다.
    func untilSuspended(count: Int) async {
        if requested.count >= count, continuations.count + resumedCount >= count { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            waiter = (count, c)
        }
    }

    private var resumedCount = 0

    func resume(at position: Int) {
        guard let c = continuations.removeValue(forKey: position) else {
            XCTFail("resume 할 \(position)번 sleep 이 없다")
            return
        }
        resumedCount += 1
        c.resume()
    }

    func resumeOldest() {
        guard let position = continuations.keys.min() else {
            XCTFail("resume 할 sleep 이 없다")
            return
        }
        resume(at: position)
    }
}
