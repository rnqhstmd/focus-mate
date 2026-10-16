import Foundation
import XCTest
@testable import FocusMate

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); value += 1; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
}

private struct LoadFailure: Error {}

@MainActor
final class RouteCatalogStoreTests: XCTestCase {
    private func catalog() throws -> RouteCatalog { try RouteCatalogFixture.acceptance() }

    // 깨짐: ready init이 .loading으로 시작하면 실패한다.
    func testReadyInitIsReadyWithCatalog() throws {
        let c = try catalog()
        let store = RouteCatalogStore(ready: c)
        XCTAssertEqual(store.availability, .ready(c))
        XCTAssertEqual(store.catalog, c)
    }

    func testAvailabilityIsLoadingBeforeStart() throws {
        let c = try catalog()
        let store = RouteCatalogStore(load: { c })
        XCTAssertEqual(store.availability, .loading)
        XCTAssertNil(store.catalog)
    }

    // 깨짐: 성공 결과를 상태에 반영하지 않으면 실패한다.
    func testSuccessfulLoadBecomesReady() async throws {
        let c = try catalog()
        let store = RouteCatalogStore(load: { c })
        await store.startLoading().value
        XCTAssertEqual(store.availability, .ready(c))
        XCTAssertNotNil(store.catalog)
    }

    // 깨짐: 에러를 삼키고 .loading에 머물면 실패한다.
    func testThrowingLoadBecomesFailed() async {
        let store = RouteCatalogStore(load: { throw LoadFailure() })
        await store.startLoading().value
        XCTAssertEqual(store.availability, .failed)
        XCTAssertNil(store.catalog)
    }

    // 깨짐: 호출마다 새로 로딩하면 카운터가 2가 되어 실패한다.
    func testStartLoadingTwiceLoadsOnce() async throws {
        let c = try catalog()
        let counter = CallCounter()
        let store = RouteCatalogStore(load: { counter.increment(); return c })
        let first = store.startLoading()
        let second = store.startLoading()
        await first.value
        await second.value
        XCTAssertEqual(counter.count, 1)
    }

    // 깨짐: 시작 전 호출 시 영원히 대기하거나 .loading을 돌려주면 실패한다.
    func testLoadedStartsAndReturnsResult() async throws {
        let c = try catalog()
        let store = RouteCatalogStore(load: { c })
        let result = await store.loaded()
        XCTAssertEqual(result, .ready(c))
    }

    func testLoadedReturnsFailedOnError() async {
        let store = RouteCatalogStore(load: { throw LoadFailure() })
        let result = await store.loaded()
        XCTAssertEqual(result, .failed)
    }
}
