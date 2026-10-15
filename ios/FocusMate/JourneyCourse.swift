import Foundation

/// 지도 좌표. 순수 로직과 테스트가 CoreLocation 없이 돌도록 자체 타입을 둔다(지도 뷰에서만 변환한다).
struct CoursePoint: Equatable, Hashable {
    let latitude: Double
    let longitude: Double
}

/// 코스 위의 정류장. `index`는 코스 위치(출발 0), 나머지는 카탈로그 정류장 값이다.
struct CourseStop: Equatable {
    let index: Int
    let id: String
    let name: String
    let point: CoursePoint
}
