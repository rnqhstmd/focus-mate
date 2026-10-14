import Foundation

// 마이페이지 읽기·이동. 통계는 records 집계만 읽고 저장하지 않는다.
// W10 합류 절차(두 번째로 머지하는 브랜치가 수행 — design.md "W10 합류 절차"):
// 꾸미기 행을 W10 진입(beginCardCustomization)으로 연결하고 cardStudio 자리표시·ProfileMenuItem.customize를 제거하며,
// 마이페이지 카드를 PassFace(style:)로 바꾼다.

enum ProfileMenuItem {
    case customize, settings
    var destination: Destination {
        switch self {
        case .customize: .cardStudio
        case .settings: .settings
        }
    }
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
