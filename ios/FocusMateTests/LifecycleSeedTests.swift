import Foundation
import XCTest
@testable import FocusMate

#if DEBUG
/// W07 life* 시드의 정합성. 이 시드가 틀리면 모든 W07 UI 테스트가 거짓 양성이 된다.
final class LifecycleSeedTests: XCTestCase {
    private static let names = [
        "lifePaused90", "lifePaused600", "lifePaused0", "lifePaused299", "lifePaused300",
        "lifePaused1499", "lifeReverse300", "lifeWrap900", "lifeArrived", "lifeAwaiting",
    ]
    /// PRD BR-1: 2014번 정류장 간격 5분. 모든 life* 시드는 2014번이다.
    private static let minutesPerStop2014 = 5

    private func seed(_ name: String) throws -> AppSnapshot {
        try XCTUnwrap(UITestBootstrap.lifecycleSnapshot(name), "시드 없음: \(name)")
    }

    private func active(_ name: String) throws -> JourneySnapshot {
        try XCTUnwrap(try seed(name).journey.active, "진행 여정 없음: \(name)")
    }

    // 깨짐: 시드 이름이 빠지거나 이름이 바뀌면 nil이 되어 실패한다.
    func test_모든_life_시드가_존재한다() {
        for name in Self.names {
            XCTAssertNotNil(UITestBootstrap.lifecycleSnapshot(name), name)
        }
    }

    // 깨짐: 없는 이름에 임의 시드를 돌려주면(조용한 통과) 실패한다.
    func test_없는_이름은_nil이다() {
        XCTAssertNil(UITestBootstrap.lifecycleSnapshot("lifeDoesNotExist"))
    }

    // 깨짐: 저장 형식 검증을 통과하지 못하는 시드(앱이 setupError로 시작)면 실패한다.
    func test_모든_life_시드는_저장_형식_검증을_통과한다() throws {
        for name in Self.names {
            let snapshot = try seed(name)
            let data = try SnapshotCodec.encode(snapshot)
            XCTAssertNoThrow(try SnapshotCodec.decode(data), name)
        }
    }

    // 깨짐: 시드가 메인이 아닌 곳(여행 화면 등)으로 열리면 실패한다.
    func test_모든_life_시드는_메인으로_열린다() throws {
        for name in Self.names {
            XCTAssertEqual(try seed(name).launchRoute(), .main, name)
        }
    }

    // 깨짐: 도착지가 승차 식(wrap(출발 + 방향 × 분/간격))과 다르면 실패한다.
    func test_도착지는_승차_식과_일치한다() throws {
        for name in Self.names {
            let journey = try active(name)
            let stops = journey.minutes / Self.minutesPerStop2014
            let expected = JourneyReach.station(
                originStopID: journey.originStopID, direction: journey.direction, stops: stops
            )?.id
            XCTAssertNotNil(expected, name)
            XCTAssertEqual(journey.destinationStopID, expected, name)
        }
    }

    // 깨짐: 현재 정류장이 출발지(id·방향)와 다르면 실패한다(AC-8·16이 현재 정류장 변화를 증명하려면 같아야 한다).
    func test_현재_정류장은_출발_정류장이다() throws {
        for name in Self.names {
            let snapshot = try seed(name)
            let journey = try active(name)
            XCTAssertEqual(snapshot.currentStation?.id, journey.originStopID, name)
            XCTAssertEqual(snapshot.currentStation?.direction, journey.direction, name)
        }
    }

    // 깨짐: 완료 기록이 1건이 아니면 "기록 수 불변" 단언(AC-31)이 의미를 잃어 실패한다.
    func test_완료_기록은_seed_record_1_한_건이다() throws {
        for name in Self.names {
            let items = try seed(name).records.items
            XCTAssertEqual(items.map(\.id), ["seed-record-1"], name)
        }
    }

    // 깨짐: 출발 후 시드가 paused=false이면 재실행된 상태와 달라 실패한다.
    func test_출발_후_시드는_일시정지이고_출발_대기_시드만_대기_단계다() throws {
        for name in Self.names where name != "lifeAwaiting" {
            let journey = try active(name)
            XCTAssertEqual(journey.phase, .departed, name)
            XCTAssertTrue(journey.paused, name)
        }
        XCTAssertEqual(try active("lifeAwaiting").phase, .awaitingDeparture)
    }

    // 깨짐: 시드의 경과 초·방향·출발지가 표(설계 F-12)와 다르면 실패한다.
    func test_시드_값은_설계_표와_같다() throws {
        let table: [(name: String, origin: String, direction: Int, elapsed: Int)] = [
            ("lifePaused90", "seongsu", 1, 90),
            ("lifePaused600", "seongsu", 1, 600),
            ("lifePaused0", "seongsu", 1, 0),
            ("lifePaused299", "seongsu", 1, 299),
            ("lifePaused300", "seongsu", 1, 300),
            ("lifePaused1499", "seongsu", 1, 1499),
            ("lifeReverse300", "seongsu", -1, 300),
            ("lifeWrap900", "seongsuBridgeNorth", 1, 900),
            ("lifeArrived", "seongsu", 1, 1500),
        ]
        for row in table {
            let journey = try active(row.name)
            XCTAssertEqual(journey.originStopID, row.origin, row.name)
            XCTAssertEqual(journey.direction, row.direction, row.name)
            XCTAssertEqual(journey.progress.elapsedSeconds, row.elapsed, row.name)
            XCTAssertEqual(journey.busID, "2014", row.name)
            XCTAssertEqual(journey.minutes, 25, row.name)
        }
    }
}
#endif
