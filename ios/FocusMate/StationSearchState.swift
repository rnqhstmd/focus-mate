import Foundation

/// 출발지 검색 화면과 미리보기의 상태.
struct StationSearchState: Equatable {
    var query: String = "" {
        didSet { if query != oldValue { clearSelection() } }
    }
    private(set) var selectedID: String?

    func result(in catalog: RouteCatalog) -> StationSearchResult { StationSearch.search(query, in: catalog) }

    func selectedOption(in catalog: RouteCatalog) -> StopSearchOption? { selectedOption(from: result(in: catalog)) }

    /// 이미 구한 검색 결과에서 선택을 찾는다. 화면은 그릴 때마다 검색을 한 번만 한다(정류장 1만여 개).
    func selectedOption(from result: StationSearchResult) -> StopSearchOption? {
        Self.options(of: result).first { $0.id == selectedID }
    }

    func canConfirm(in catalog: RouteCatalog) -> Bool { selectedOption(in: catalog) != nil }

    mutating func select(_ optionID: String, in catalog: RouteCatalog) -> Bool {
        select(optionID, from: result(in: catalog))
    }

    mutating func select(_ optionID: String, from result: StationSearchResult) -> Bool {
        guard Self.options(of: result).contains(where: { $0.id == optionID }) else { return false }
        selectedID = optionID
        return true
    }

    mutating func clearSelection() { selectedID = nil }

    private static func options(of result: StationSearchResult) -> [StopSearchOption] {
        if case let .results(options, _) = result { return options }
        return []
    }
}

extension StopSearchOption {
    var snapshot: StationSnapshot { StationSnapshot(id: id, name: name) }
}
