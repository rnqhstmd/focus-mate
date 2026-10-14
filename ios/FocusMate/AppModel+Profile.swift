import Foundation

// 마이페이지 읽기·이동. 통계는 records 집계만 읽고 저장하지 않는다.
enum ProfileMenuItem {
    case settings
    var destination: Destination { .settings }
}

enum ProfileStats: Equatable {
    case loaded(RecordLifetimeSummary), unavailable

    /// 기록이 하나라도 유효하지 않으면 일부만 합산하지 않고 unavailable로 둔다.
    static func from(_ records: RecordSection?) -> ProfileStats {
        guard let summary = try? records?.lifetimeSummary() else { return .unavailable }
        return .loaded(summary)
    }
}

extension AppModel {
    var profileStats: ProfileStats { ProfileStats.from(snapshot?.records) }

    @discardableResult func openFromProfile(_ item: ProfileMenuItem) -> Bool {
        guard path.last == .profile else { return false }
        open(item.destination)
        return path.last == item.destination
    }
}
