import Foundation
import MapKit
import Observation
import OSLog

/// 정류장 두 곳 사이의 도로 경로를 주는 쪽. 실제는 Apple 길찾기, UI 테스트·단위 테스트는 가짜를 넣는다.
protocol RouteShapeProviding: Sendable {
    /// 도로를 따라가는 선. 받지 못하면 던진다(그 구간은 곧은 선으로 남는다).
    func roadPath(from: CoursePoint, to: CoursePoint) async throws -> [CoursePoint]
    /// 결과를 디스크에 남겨도 되는지(실제 길찾기만).
    var cachesToDisk: Bool { get }
}

/// Apple 길찾기(MKDirections, 자동차)로 구간 경로를 받는다.
struct MapKitRouteShapeProvider: RouteShapeProviding {
    var cachesToDisk: Bool { true }

    func roadPath(from: CoursePoint, to: CoursePoint) async throws -> [CoursePoint] {
        let request = MKDirections.Request()
        request.source = Self.item(from)
        request.destination = Self.item(to)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        let response = try await MKDirections(request: request).calculate()
        guard let polyline = response.routes.first?.polyline, polyline.pointCount >= 2 else {
            throw URLError(.cannotParseResponse)
        }
        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: polyline.pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        return coordinates.map { CoursePoint(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private static func item(_ point: CoursePoint) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        if #available(iOS 26.0, *) {
            return MKMapItem(location: CLLocation(latitude: point.latitude, longitude: point.longitude), address: nil)
        }
        return MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
    }
}

/// 네트워크 없이 곧은 선만 준다(UI 테스트 기본 — 화면이 결정적이다).
struct StraightRouteShapeProvider: RouteShapeProviding {
    var cachesToDisk: Bool { false }
    func roadPath(from: CoursePoint, to: CoursePoint) async throws -> [CoursePoint] { [from, to] }
}

private let log = Logger(subsystem: "app.focusmate", category: "RouteShape")

/// 노선 ID + 정류장 쌍으로 구간 하나를 가리킨다.
struct RouteSegmentRequest: Hashable, Sendable {
    let key: String
    let from: CoursePoint
    let to: CoursePoint

    init(routeID: String, fromID: String, toID: String, from: CoursePoint, to: CoursePoint) {
        key = "\(routeID)|\(fromID)|\(toID)"
        self.from = from
        self.to = to
    }
}

/// 구간 도로 경로 저장소. 메모리 + 디스크(Caches) 캐시, 동시 요청 수 제한, 실패 구간은 곧은 선.
/// 화면은 먼저 `segments(for:)`의 곧은 선으로 그리고, `revision`이 바뀌면(받아지는 대로) 다시 그린다.
@MainActor
@Observable
final class RouteShapeStore {
    static let maximumConcurrentRequests = 3

    /// 앱 전체에서 쓰는 저장소. UI 테스트(`--fm-ui-test-id`)는 `--fm-ui-route-shape live`가 없으면 곧은 선만 쓴다.
    static let shared: RouteShapeStore = {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--fm-ui-test-id") {
            let live = arguments.firstIndex(of: "--fm-ui-route-shape").map { arguments.indices.contains($0 + 1) && arguments[$0 + 1] == "live" } ?? false
            if !live { return RouteShapeStore(provider: StraightRouteShapeProvider(), cacheDirectory: nil) }
        }
        #endif
        return RouteShapeStore(provider: MapKitRouteShapeProvider(), cacheDirectory: defaultCacheDirectory)
    }()

    static var defaultCacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("RouteShapes/v2", isDirectory: true)
    }

    /// 받은(또는 규칙으로 곧은 선이 된) 구간 선. 실패한 구간은 넣지 않아 다음에 다시 시도한다.
    private(set) var resolved: [String: [CoursePoint]] = [:]
    private(set) var revision = 0
    @ObservationIgnored private var inFlight: Set<String> = []
    @ObservationIgnored private let provider: any RouteShapeProviding
    @ObservationIgnored private let cacheDirectory: URL?

    init(provider: any RouteShapeProviding, cacheDirectory: URL?) {
        self.provider = provider
        self.cacheDirectory = provider.cachesToDisk ? cacheDirectory : nil
    }

    /// 지금 가진 선. 아직 없는 구간은 두 정류장을 곧게 잇는다.
    func segments(for requests: [RouteSegmentRequest]) -> [[CoursePoint]] {
        requests.map { resolved[$0.key] ?? [$0.from, $0.to] }
    }

    func shape(for requests: [RouteSegmentRequest]) -> RouteShape { RouteShape(segments: segments(for: requests)) }

    /// 없는 구간을 디스크 캐시 → 길찾기 순으로 채운다. 동시에 최대 3개만 요청한다.
    func load(_ requests: [RouteSegmentRequest]) async {
        var seen = Set<String>()
        let pending = requests.filter { resolved[$0.key] == nil && !inFlight.contains($0.key) && seen.insert($0.key).inserted }
        guard !pending.isEmpty else { return }
        pending.forEach { inFlight.insert($0.key) }
        defer { pending.forEach { inFlight.remove($0.key) } }
        let provider = provider, directory = cacheDirectory
        await withTaskGroup(of: (String, [CoursePoint]?).self) { group in
            var queue = pending[...]
            func next() {
                guard let request = queue.popFirst() else { return }
                group.addTask { (request.key, await Self.fetch(request, provider: provider, directory: directory)) }
            }
            for _ in 0..<Self.maximumConcurrentRequests { next() }
            while let (key, path) = await group.next() {
                if let path {
                    resolved[key] = path
                    revision += 1
                }
                next()
            }
        }
    }

    /// 디스크에 있으면 그것을, 없으면 길찾기 결과를 규칙에 통과시킨다. 요청 자체가 실패하면 nil(저장 안 함).
    private nonisolated static func fetch(_ request: RouteSegmentRequest, provider: any RouteShapeProviding,
                                          directory: URL?) async -> [CoursePoint]? {
        let file = directory?.appendingPathComponent(fileName(for: request.key))
        if let file, let data = try? Data(contentsOf: file),
           let pairs = try? JSONDecoder().decode([[Double]].self, from: data), pairs.count >= 2 {
            return pairs.map { CoursePoint(latitude: $0[0], longitude: $0[1]) }
        }
        guard !Task.isCancelled else { return nil }
        let road: [CoursePoint]
        do { road = try await provider.roadPath(from: request.from, to: request.to) } catch {
            log.error("route shape \(request.key, privacy: .public) failed: \(String(describing: error), privacy: .public)")
            return nil
        }
        let path = RouteSegmentRule.resolve(road, from: request.from, to: request.to)
        log.info("route shape \(request.key, privacy: .public): \(road.count) → \(path.count) points")
        if let file, let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if let data = try? JSONEncoder().encode(path.map { [$0.latitude, $0.longitude] }) {
                try? data.write(to: file, options: .atomic)
            }
        }
        return path
    }

    nonisolated static func fileName(for key: String) -> String {
        String(key.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" }) + ".json"
    }
}

extension CoursePoint {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
