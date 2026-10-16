import Foundation
import XCTest
@testable import FocusMate

/// 도달 정류장 계산: 카탈로그 상태(loading/ready/failed)와 저장 필드로 결정한다.
/// r-100: A→B→C→D 누적 [0, 600, 1140, 1500]. 저장 이름은 "옛 에이"/"옛 디", 카탈로그 이름은 "에이"/"비"/"씨"/"디".
final class RouteReachTests: XCTestCase {
    private typealias F = W16bFixtures

    private func station(_ id: String, _ name: String) -> StationSnapshot { StationSnapshot(id: id, name: name) }

    // MARK: arrivedStation

    // 깨짐: 도착 시 저장된 도착 id·이름 대신 카탈로그 이름을 쓰면 실패한다.
    func testArrivedStationUsesStoredDestinationFields() {
        let journey = F.journey(elapsedSeconds: 1500)
        XCTAssertEqual(journey.arrivedStation, station("D", "옛 디"))
    }

    // 깨짐: 미도착인데 정류장을 돌려주면 실패한다.
    func testArrivedStationIsNilBeforeArrival() {
        XCTAssertNil(F.journey(elapsedSeconds: 1499).arrivedStation)
        XCTAssertNil(F.journey(phase: .awaitingDeparture, elapsedSeconds: 0, paused: false).arrivedStation)
    }

    // MARK: reachedStation: 도착

    // 깨짐: 도착인데 로딩 상태를 기다리면(.notLoaded) 실패한다.
    func testArrivedResolvesStationEvenWhileLoading() throws {
        let attempt = F.journey(elapsedSeconds: 1500).reachedStation(in: .loading)
        XCTAssertEqual(attempt, .resolved(.station(station("D", "옛 디"))))
    }

    // 깨짐: 도착인데 실패 상태에서 출발 정류장으로 돌리면 실패한다.
    func testArrivedResolvesStationEvenWhenFailed() {
        let attempt = F.journey(elapsedSeconds: 1500).reachedStation(in: .failed)
        XCTAssertEqual(attempt, .resolved(.station(station("D", "옛 디"))))
    }

    // MARK: reachedStation: loading / failed

    // 깨짐: 미도착 + 로딩을 확정하면 실패한다.
    func testUnarrivedWhileLoadingIsNotLoaded() {
        XCTAssertEqual(F.journey(elapsedSeconds: 600).reachedStation(in: .loading), .notLoaded)
    }

    // 깨짐: 실패 시 카탈로그 이름이나 .reselectStation을 쓰면 실패한다 (저장된 출발 id·이름 유지).
    func testUnarrivedWhenFailedStaysAtStoredOrigin() {
        let attempt = F.journey(elapsedSeconds: 600).reachedStation(in: .failed)
        XCTAssertEqual(attempt, .resolved(.stayAtOrigin(station("A", "옛 에이"))))
    }

    // MARK: reachedStation: ready

    // 깨짐: 누적 시간 경계(<=)를 잘못 비교하면 해당 경과에서 실패한다.
    func testReadyPicksLastStopAtOrBeforeElapsed() throws {
        let catalog = try F.single()
        let cases: [(elapsed: Int, expected: StationSnapshot)] = [
            (0, station("A", "에이")),
            (599, station("A", "에이")),
            (600, station("B", "비")),
            (1139, station("B", "비")),
            (1140, station("C", "씨")),
            (1499, station("C", "씨")),
        ]
        for c in cases {
            let attempt = F.journey(elapsedSeconds: c.elapsed).reachedStation(in: .ready(catalog))
            XCTAssertEqual(attempt, .resolved(.station(c.expected)), "elapsed \(c.elapsed)")
        }
    }

    // 깨짐: 이름을 저장 필드에서 가져오면 "옛 에이"가 되어 실패한다 (카탈로그 이름 사용).
    func testReadyUsesCatalogNameForReachedStop() throws {
        let attempt = F.journey(originName: "저장된 이름", elapsedSeconds: 0).reachedStation(in: .ready(try F.single()))
        XCTAssertEqual(attempt, .resolved(.station(station("A", "에이"))))
    }

    // 깨짐: 노선이 사라졌는데 reselect로 보내거나 저장 이름을 쓰면 실패한다 (카탈로그의 출발 정류장 유지).
    func testReadyWhenRouteGoneStaysAtOriginWithCatalogName() throws {
        let attempt = F.journey(elapsedSeconds: 600).reachedStation(in: .ready(try F.withoutRoute100()))
        XCTAssertEqual(attempt, .resolved(.stayAtOrigin(station("A", "에이"))))
    }

    // 깨짐: 재계산 도착 id가 저장값과 다를 때 중간 정류장을 돌려주면 실패한다.
    func testReadyWhenRecomputedDestinationDiffersStaysAtOrigin() throws {
        let attempt = F.journey(destinationStopID: "C", elapsedSeconds: 600).reachedStation(in: .ready(try F.single()))
        XCTAssertEqual(attempt, .resolved(.stayAtOrigin(station("A", "에이"))))
    }

    // 깨짐: leg가 나오지 않는 분(3분)에서 크래시하거나 중간 정류장을 돌려주면 실패한다.
    func testReadyWhenNoLegStaysAtOrigin() throws {
        let attempt = F.journey(minutes: 3, elapsedSeconds: 60).reachedStation(in: .ready(try F.single()))
        XCTAssertEqual(attempt, .resolved(.stayAtOrigin(station("A", "에이"))))
    }

    // 깨짐: 출발 정류장까지 사라졌는데 stayAtOrigin을 돌려주면 실패한다.
    func testReadyWhenOriginAlsoGoneRequiresReselection() throws {
        let attempt = F.journey(elapsedSeconds: 600).reachedStation(in: .ready(try F.withoutStopA()))
        XCTAssertEqual(attempt, .resolved(.reselectStation))
    }

    // MARK: clearingStationsAndJourney

    // 깨짐: 정류장·여정을 안 비우거나 카드·기록을 지우면 실패한다.
    func testClearingStationsAndJourneyKeepsCardsAndRecords() {
        let before = F.appSnapshot(active: F.journey())
        let after = before.clearingStationsAndJourney()
        XCTAssertNil(after.initialStation)
        XCTAssertNil(after.currentStation)
        XCTAssertNil(after.journey.active)
        XCTAssertEqual(after.cards, before.cards)
        XCTAssertEqual(after.records, before.records)
        XCTAssertTrue(after.cardIssued)
    }

    // 깨짐: 이미 비어 있는 스냅숏에서 결과가 달라지면 실패한다 (멱등).
    func testClearingIsIdempotent() {
        let once = F.appSnapshot(active: F.journey()).clearingStationsAndJourney()
        XCTAssertEqual(once.clearingStationsAndJourney(), once)
    }
}
