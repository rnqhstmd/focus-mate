import Foundation

/// 첫 출발지 검색 화면의 상태. 선택은 현재 검색 결과 안에 있을 때만 유효하다.
struct StationSearchState: Equatable {
    var query: String = ""
    private(set) var selectedID: String?

    func result(in catalog: RouteCatalog) -> StationSearchResult { StationSearch.search(query, in: catalog) }

    func selectedOption(in catalog: RouteCatalog) -> StopSearchOption? { selectedOption(from: result(in: catalog)) }

    /// 이미 구한 검색 결과에서 선택을 찾는다. 화면은 그릴 때마다 검색을 한 번만 한다(정류장 1만여 개).
    func selectedOption(from result: StationSearchResult) -> StopSearchOption? {
        Self.options(of: result).first { $0.id == selectedID }
    }

    func confirmationText(in catalog: RouteCatalog) -> String? { selectedOption(in: catalog).map(Self.confirmationText(for:)) }

    /// "이름 · 방면에서 출발". 방면이 없는 정류장은 "이름에서 출발"이다.
    static func confirmationText(for option: StopSearchOption) -> String {
        option.boundLabel.map { "\(option.name) · \($0)에서 출발" } ?? "\(option.name)에서 출발"
    }

    func canConfirm(in catalog: RouteCatalog) -> Bool { selectedOption(in: catalog) != nil }

    mutating func select(_ optionID: String, in catalog: RouteCatalog) -> Bool {
        guard Self.options(of: result(in: catalog)).contains(where: { $0.id == optionID }) else { return false }
        selectedID = optionID
        return true
    }

    private static func options(of result: StationSearchResult) -> [StopSearchOption] {
        if case let .results(options, _) = result { return options }
        return []
    }
}

extension StopSearchOption {
    var snapshot: StationSnapshot { StationSnapshot(id: id, name: name) }
}
