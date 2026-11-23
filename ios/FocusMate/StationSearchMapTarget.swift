import Foundation

struct StationSearchMapTarget: Hashable {
    let stationID: String
    let point: CoursePoint

    init?(stationID: String?, catalog: RouteCatalog?) {
        guard let stationID, let catalog, let index = catalog.stopIndex(id: stationID) else { return nil }
        self.stationID = stationID
        point = catalog.stops[index].point
    }

    static func visibleHeight(viewHeight: CGFloat, bottomInset: CGFloat) -> CGFloat? {
        let height = viewHeight - max(0, bottomInset)
        return height >= 120 ? height : nil
    }
}
