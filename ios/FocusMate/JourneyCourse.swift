import Foundation

/// 지도 좌표. 순수 로직과 테스트가 CoreLocation 없이 돌도록 자체 타입을 둔다(지도 뷰에서만 변환한다).
struct CoursePoint: Equatable, Hashable {
    let latitude: Double
    let longitude: Double
}

struct CourseStop: Equatable {
    let index: Int
    let id: String
    let name: String
    let point: CoursePoint
}

/// 앱 내 가상 코스(BR-1). 실제 버스 노선이 아니며 정류장 사이를 직선으로 잇는다.
/// 좌표는 정류장 id에 묶어 두어, 카탈로그가 서울 전역으로 늘어도 이 표에 항목만 추가하면 된다.
enum JourneyCourse {
    static let seoulBounds: (latitude: ClosedRange<Double>, longitude: ClosedRange<Double>) =
        (37.41...37.72, 126.76...127.19)

    /// 각 정류장의 실제 위치 근사(소수 4자리).
    static let coordinates: [String: CoursePoint] = [
        "seongsu": CoursePoint(latitude: 37.5446, longitude: 127.0559),
        "seongsuDong": CoursePoint(latitude: 37.5445, longitude: 127.0507),
        "ttukseom": CoursePoint(latitude: 37.5474, longitude: 127.0474),
        "seongdongSportsCenter": CoursePoint(latitude: 37.5466, longitude: 127.0429),
        "seoulForest": CoursePoint(latitude: 37.5437, longitude: 127.0447),
        "seoulForestGate": CoursePoint(latitude: 37.5432, longitude: 127.0396),
        "seongsuBridgeNorth": CoursePoint(latitude: 37.5403, longitude: 127.0355),
        "ttukseomHangangPark": CoursePoint(latitude: 37.5296, longitude: 127.0670),
        "seongsuIntersection": CoursePoint(latitude: 37.5410, longitude: 127.0573),
    ]

    static let stops: [CourseStop] = RouteStops.all.enumerated().map { index, stop in
        guard let point = coordinates[stop.id] else { preconditionFailure("좌표 없는 정류장: \(stop.id)") }
        return CourseStop(index: index, id: stop.id, name: stop.name, point: point)
    }

    static func point(at index: Int) -> CoursePoint { stops[RouteStops.wrap(index)].point }

    /// 마지막 정류장에서 첫 정류장으로 돌아오는 닫힌 선.
    static var closedPath: [CoursePoint] { stops.map(\.point) + [stops[0].point] }
}
