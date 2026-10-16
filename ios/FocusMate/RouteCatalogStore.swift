import Foundation
import Observation

/// 번들 정류장 데이터를 읽는 중인지, 읽었는지, 읽지 못했는지(번들 결함 — 재시도하지 않는다).
enum RouteDataAvailability: Equatable {
    case loading
    case ready(RouteCatalog)
    case failed
}

/// 앱 시작 직후 백그라운드에서 카탈로그를 한 번 읽는다. 첫 화면은 이 결과를 기다리지 않는다.
@MainActor
@Observable
final class RouteCatalogStore {
    private(set) var availability: RouteDataAvailability
    private let load: @Sendable () throws -> RouteCatalog
    private var task: Task<Void, Never>?

    init(load: @escaping @Sendable () throws -> RouteCatalog) {
        self.load = load
        availability = .loading
    }

    convenience init(ready catalog: RouteCatalog) {
        self.init(load: { catalog })
        availability = .ready(catalog)
    }

    var catalog: RouteCatalog? {
        if case let .ready(catalog) = availability { return catalog }
        return nil
    }

    @discardableResult
    func startLoading() -> Task<Void, Never> {
        if let task { return task }
        guard availability == .loading else {
            let done = Task {}
            task = done
            return done
        }
        let load = load
        let started = Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) { () -> RouteCatalog? in try? load() }.value
            self?.availability = result.map(RouteDataAvailability.ready) ?? .failed
        }
        task = started
        return started
    }

    func loaded() async -> RouteDataAvailability {
        await startLoading().value
        return availability
    }
}
