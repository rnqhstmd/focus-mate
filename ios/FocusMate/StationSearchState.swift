import Foundation

/// 첫 출발지 검색 화면의 상태. 선택은 현재 검색 결과 안에 있을 때만 유효하다.
struct StationSearchState: Equatable {
    var query: String = ""
    private(set) var selectedID: String?

    var results: [StationOption] { StationCatalog.search(query) }
    var selectedOption: StationOption? { results.first { $0.id == selectedID } }
    var confirmationText: String? { selectedOption.map { "\($0.name) · \($0.boundLabel)에서 출발" } }
    var canConfirm: Bool { selectedOption != nil }

    mutating func select(_ optionID: String) -> Bool {
        guard results.contains(where: { $0.id == optionID }) else { return false }
        selectedID = optionID
        return true
    }
}
