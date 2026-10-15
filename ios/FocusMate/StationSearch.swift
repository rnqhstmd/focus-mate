import Foundation

/// 최초 정류장 검색 결과 한 건(서울 전체 데이터). 기존 예시 데이터의 `StationOption`을 대신할 타입이다.
struct StopSearchOption: Identifiable, Equatable {
    let id: String
    let stopIndex: Int
    let name: String
    let ars: String?
    let boundLabel: String?

    var accessibilityLabel: String {
        ([name, ars, boundLabel] as [String?]).compactMap { $0 }.joined(separator: ", ")
    }
}

enum StationSearchResult: Equatable {
    case prompt
    case empty
    case results([StopSearchOption], overflow: Bool)
}

/// BR-9 정류장 검색. 숫자만 입력하면 번호(정확 → 앞자리), 그 밖은 이름(정확 → 앞부분 → 부분) 일치 순이다.
enum StationSearch {
    static let limit = 50

    static func search(_ query: String, in catalog: RouteCatalog) -> StationSearchResult {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return .prompt }
        let ranked = term.allSatisfy { $0.isASCII && $0.isNumber }
            ? numberMatches(term, in: catalog) : nameMatches(term, in: catalog)
        guard !ranked.isEmpty else { return .empty }
        let options = ranked.prefix(limit).map { index in
            let stop = catalog.stops[index]
            return StopSearchOption(id: stop.id, stopIndex: index, name: stop.name, ars: stop.ars,
                                    boundLabel: catalog.boundLabel(stopIndex: index))
        }
        return .results(options, overflow: ranked.count > limit)
    }

    private static func numberMatches(_ term: String, in catalog: RouteCatalog) -> [Int] {
        catalog.stops.indices.compactMap { index -> (stage: Int, ars: String, id: String, index: Int)? in
            guard let ars = catalog.stops[index].ars, ars.hasPrefix(term) else { return nil }
            return (ars == term ? 0 : 1, ars, catalog.stops[index].id, index)
        }
        .sorted { ($0.stage, $0.ars, $0.id) < ($1.stage, $1.ars, $1.id) }
        .map(\.index)
    }

    private static func nameMatches(_ term: String, in catalog: RouteCatalog) -> [Int] {
        catalog.stops.indices.compactMap { index -> (stage: Int, stop: RouteCatalog.Stop, index: Int)? in
            let stop = catalog.stops[index]
            let name = stop.name.lowercased()
            if name == term { return (0, stop, index) }
            if name.hasPrefix(term) { return (1, stop, index) }
            if name.contains(term) { return (2, stop, index) }
            return nil
        }
        .sorted { lhs, rhs in
            if lhs.stage != rhs.stage { return lhs.stage < rhs.stage }
            if lhs.stop.name != rhs.stop.name { return lhs.stop.name < rhs.stop.name }
            switch (lhs.stop.ars, rhs.stop.ars) {
            case let (a?, b?) where a != b: return a < b
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.stop.id < rhs.stop.id
            }
        }
        .map(\.index)
    }
}
