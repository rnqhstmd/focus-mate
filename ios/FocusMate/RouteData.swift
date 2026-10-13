import Foundation

/// 순환 노선 위의 위치. `index`는 `RouteStops.all`의 순서, `direction`은 1(정방향) 또는 -1(역방향)이다.
struct StopPosition: Equatable, Hashable {
    let index: Int
    let direction: Int
}

/// 웹 프로토타입과 같은 9개 가상 순환 정류장. 저장되는 `StationSnapshot.id`는 이 id다.
enum RouteStops {
    static let all: [(id: String, name: String)] = [
        ("seongsu", "성수역"),
        ("seongsuDong", "성수동"),
        ("ttukseom", "뚝섬역"),
        ("seongdongSportsCenter", "성동구민체육센터"),
        ("seoulForest", "서울숲역"),
        ("seoulForestGate", "서울숲 입구"),
        ("seongsuBridgeNorth", "성수대교 북단"),
        ("ttukseomHangangPark", "뚝섬한강공원"),
        ("seongsuIntersection", "성수사거리"),
    ]

    static func wrap(_ offset: Int) -> Int {
        ((offset % all.count) + all.count) % all.count
    }

    static func name(at index: Int) -> String { all[wrap(index)].name }

    static func boundLabel(from position: StopPosition) -> String {
        name(at: position.index + position.direction) + " 방면"
    }

    static func position(of station: StationSnapshot) -> StopPosition? {
        guard let index = all.firstIndex(where: { $0.id == station.id }) else { return nil }
        return StopPosition(index: index, direction: station.direction)
    }
}

/// 첫 출발지 검색에 나오는 정류장·방면 한 건.
struct StationOption: Identifiable, Equatable {
    let id: String
    let stopID: String
    let position: StopPosition
    let name: String
    let aliases: [String]

    var boundLabel: String { RouteStops.boundLabel(from: position) }
    var snapshot: StationSnapshot { StationSnapshot(id: stopID, name: name, direction: position.direction) }

    init(index: Int, direction: Int, aliases: [String]) {
        let stop = RouteStops.all[index]
        id = "\(stop.id):\(direction)"
        stopID = stop.id
        position = StopPosition(index: index, direction: direction)
        name = stop.name
        self.aliases = aliases
    }
}

enum StationCatalog {
    static let all: [StationOption] = [
        StationOption(index: 0, direction: 1, aliases: ["성수", "서울숲"]),
        StationOption(index: 0, direction: -1, aliases: ["성수", "건대"]),
        StationOption(index: 4, direction: 1, aliases: ["서울숲", "성수"]),
    ]

    /// 앞뒤 공백을 지우고 대소문자를 무시해 이름·별칭·방면 문구 중 하나라도 부분 일치하면 결과에 넣는다.
    static func search(_ query: String) -> [StationOption] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return all }
        return all.filter { option in
            ([option.name, option.boundLabel] + option.aliases).contains { $0.lowercased().contains(term) }
        }
    }
}

struct BusLine: Identifiable, Equatable {
    let id: String
    let number: String
    let kind: String
    let minutesPerStop: Int

    static let all: [BusLine] = [
        BusLine(id: "2014", number: "2014", kind: "지선", minutesPerStop: 5),
        BusLine(id: "302", number: "강남02", kind: "마을", minutesPerStop: 6),
        BusLine(id: "421", number: "343", kind: "간선", minutesPerStop: 8),
    ]
}
