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
    private let catalog = BoardingFixtures.uiCatalog()

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

    // 깨짐: 도착지가 카탈로그 노선에서 다시 계산한 도착 정류장과 다르면 실패한다.
    func test_도착지는_카탈로그_노선_계산과_일치한다() throws {
        for name in Self.names {
            let journey = try active(name)
            let route = try XCTUnwrap(catalog.routeIndex(id: journey.busID), name)
            let origin = try XCTUnwrap(catalog.stopIndex(id: journey.originStopID), name)
            let leg = try XCTUnwrap(
                RouteLegFinder.leg(route: route, originStop: origin, minutes: journey.minutes, in: catalog), name
            )
            let expected = catalog.stops[try XCTUnwrap(leg.stopIndices.last)].id
            XCTAssertEqual(journey.destinationStopID, expected, name)
        }
    }

    // 깨짐: 저장된 이름 4종이 카탈로그 이름·노선 정보와 다르면 실패한다.
    func test_시드의_저장_이름은_카탈로그_값을_복사한다() throws {
        for name in Self.names {
            let journey = try active(name)
            let origin = catalog.stops[try XCTUnwrap(catalog.stopIndex(id: journey.originStopID), name)]
            let destination = catalog.stops[try XCTUnwrap(catalog.stopIndex(id: journey.destinationStopID), name)]
            let route = catalog.routes[try XCTUnwrap(catalog.routeIndex(id: journey.busID), name)]
            XCTAssertEqual(journey.originName, origin.name, name)
            XCTAssertEqual(journey.destinationName, destination.name, name)
            XCTAssertEqual(journey.busNumber, route.number, name)
            XCTAssertEqual(journey.busKind, route.kind, name)
        }
    }

    // 깨짐: 현재 정류장이 출발지(id)와 다르면 실패한다(AC-8·16이 현재 정류장 변화를 증명하려면 같아야 한다).
    func test_현재_정류장은_출발_정류장이다() throws {
        for name in Self.names {
            let snapshot = try seed(name)
            let journey = try active(name)
            XCTAssertEqual(snapshot.currentStation?.id, journey.originStopID, name)
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
        let table: [(name: String, origin: String, route: String, elapsed: Int)] = [
            ("lifePaused90", "seongsu", "2014", 90),
            ("lifePaused600", "seongsu", "2014", 600),
            ("lifePaused0", "seongsu", "2014", 0),
            ("lifePaused299", "seongsu", "2014", 299),
            ("lifePaused300", "seongsu", "2014", 300),
            ("lifePaused1499", "seongsu", "2014", 1499),
            ("lifeReverse300", "seongsu-r", "2014-r", 300),
            ("lifeWrap900", "seongsuBridgeNorth", "2014", 900),
            ("lifeArrived", "seongsu", "2014", 1500),
        ]
        for row in table {
            let journey = try active(row.name)
            XCTAssertEqual(journey.originStopID, row.origin, row.name)
                        XCTAssertEqual(journey.progress.elapsedSeconds, row.elapsed, row.name)
            XCTAssertEqual(journey.busID, row.route, row.name)
            XCTAssertEqual(journey.minutes, 25, row.name)
        }
    }

    // MARK: W09 alight* 시드

    private static let alightNames = ["alightPaused1499", "alightArrived", "alightMismatchArrived"]

    // 깨짐: 시드 이름이 빠지거나 바뀌면 nil이 되어 실패한다(UITestBootstrap에 새 시드가 없으면 전부 실패).
    func test_alight_시드가_존재하고_저장_형식_검증을_통과한다() throws {
        for name in Self.alightNames {
            let snapshot = try seed(name)
            XCTAssertNoThrow(try SnapshotCodec.decode(try SnapshotCodec.encode(snapshot)), name)
        }
    }

    // 깨짐: 할 일이 "논문"이 아니거나 기록이 0건이 아니면(요약·기록 수 단언의 전제) 실패한다.
    func test_alight_시드는_할_일_논문이고_기록은_0건이다() throws {
        for name in Self.alightNames {
            XCTAssertEqual(try active(name).task, "논문", name)
            XCTAssertEqual(try seed(name).records.items.count, 0, name)
        }
    }

    // 깨짐: 기본 값(2014번 25분 성수역 독서 출발 후 일시정지, 현재 정류장 성수역)이 다르면 실패한다.
    func test_alight_시드의_기본_값은_설계와_같다() throws {
        for name in Self.alightNames {
            let snapshot = try seed(name)
            let journey = try active(name)
            XCTAssertEqual(journey.busID, "2014", name)
            XCTAssertEqual(journey.minutes, 25, name)
            XCTAssertEqual(journey.originStopID, "seongsu", name)
            XCTAssertEqual(journey.phase, .departed, name)
            XCTAssertTrue(journey.paused, name)
            XCTAssertEqual(snapshot.currentStation?.id, "seongsu", name)
        }
    }

    // 깨짐: 1499는 도착 직전(1499), 나머지는 도착(1500)이 아니면 실패한다.
    func test_alight_시드의_경과_초와_도착_여부() throws {
        XCTAssertEqual(try active("alightPaused1499").progress.elapsedSeconds, 1499)
        XCTAssertEqual(try active("alightArrived").progress.elapsedSeconds, 1500)
        XCTAssertEqual(try active("alightMismatchArrived").progress.elapsedSeconds, 1500)
    }

    // 깨짐: 저장 도착지가 서울숲 입구(정상)/뚝섬역(불일치)이 아니면 실패한다.
    func test_alight_시드의_저장_도착지() throws {
        XCTAssertEqual(try active("alightPaused1499").destinationStopID, "seoulForestGate")
        XCTAssertEqual(try active("alightArrived").destinationStopID, "seoulForestGate")
        XCTAssertEqual(try active("alightMismatchArrived").destinationStopID, "ttukseom")
        XCTAssertEqual(try active("alightMismatchArrived").destinationName, "뚝섬역")
    }

    // 깨짐: 정상 도착지 시드가 코스 여정으로 변환되지 않거나, 불일치 시드가 변환되면(지도가 그려지면) 실패한다.
    func test_alight_코스_여정_변환은_정상만_성공한다() throws {
        XCTAssertNotNil(CourseJourney(journey: try active("alightArrived"), catalog: catalog))
        XCTAssertNil(CourseJourney(journey: try active("alightMismatchArrived"), catalog: catalog))
    }

    // MARK: 기록 화면 records* 시드

    private static func dateString(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func todayString() -> String {
        let c = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        return dateString(year: c.year!, month: c.month!, day: c.day!)
    }

    private static func thisYear() -> Int {
        Calendar.current.dateComponents(in: TimeZone.current, from: Date()).year!
    }

    // 깨짐: recordsMemo 시드가 없거나 12건이 아니면(더 보기 10건 단위 검증 전제) 실패한다.
    func test_recordsMemo_시드는_존재하고_기록_12건이며_진행_여정이_없다() throws {
        let snapshot = try seed("recordsMemo")
        XCTAssertEqual(snapshot.records.items.count, 12)
        XCTAssertNil(snapshot.journey.active)
        XCTAssertNoThrow(try SnapshotCodec.decode(try SnapshotCodec.encode(snapshot)))
    }

    // 깨짐: 메모 분포가 "집중 잘됨" 1건 + 빈 메모 11건이 아니면 실패한다.
    func test_recordsMemo_시드의_메모는_집중_잘됨_1건_나머지_빈_문자열이다() throws {
        let memos = try seed("recordsMemo").records.items.map(\.memo)
        XCTAssertEqual(memos.filter { $0 == "집중 잘됨" }.count, 1)
        XCTAssertEqual(memos.filter { $0.isEmpty }.count, 11)
    }

    // 깨짐: 기록 날짜가 실행 날짜(오늘)가 아니면 오늘 선택 상태 검증이 어긋나 실패한다.
    func test_recordsMemo_시드의_기록은_모두_오늘_날짜다() throws {
        let today = Self.todayString()
        for item in try seed("recordsMemo").records.items {
            XCTAssertEqual(item.date, today)
        }
    }

    // 깨짐: completedAt이 서로 같으면 최신순 정렬이 비결정적이 되어 실패한다.
    func test_recordsMemo_시드의_completedAt은_모두_다르다() throws {
        let stamps = try seed("recordsMemo").records.items.map(\.completedAt)
        XCTAssertEqual(Set(stamps).count, 12)
    }

    // 깨짐: recordsTwoYears가 없거나 3건이 아니면 실패한다.
    func test_recordsTwoYears_시드는_존재하고_기록_3건이며_진행_여정이_없다() throws {
        let snapshot = try seed("recordsTwoYears")
        XCTAssertEqual(snapshot.records.items.count, 3)
        XCTAssertNil(snapshot.journey.active)
    }

    // 깨짐: 연도 분포가 올해 1건(오늘) + 작년 2건(3/10, 6/20)이 아니면 실패한다.
    func test_recordsTwoYears_시드의_날짜는_올해_오늘과_작년_3월10일_6월20일이다() throws {
        let year = Self.thisYear()
        let dates = Set(try seed("recordsTwoYears").records.items.map(\.date))
        let expected: Set<String> = [
            Self.todayString(),
            Self.dateString(year: year - 1, month: 3, day: 10),
            Self.dateString(year: year - 1, month: 6, day: 20),
        ]
        XCTAssertEqual(dates, expected)
    }
}
#endif
