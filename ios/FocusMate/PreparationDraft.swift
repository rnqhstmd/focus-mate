import Foundation

enum PreparationTagIcon: String, CaseIterable, Equatable, Codable {
    case reading, work, study, development, writing
    var title: String {
        switch self {
        case .reading: "독서"
        case .work: "업무"
        case .study: "공부"
        case .development: "개발"
        case .writing: "쓰기"
        }
    }
    var systemImage: String {
        switch self {
        case .reading: "book"
        case .work: "briefcase"
        case .study: "graduationcap"
        case .development: "chevron.left.forwardslash.chevron.right"
        case .writing: "pencil"
        }
    }
}
enum PreparationTagColor: String, CaseIterable, Equatable, Codable {
    case sand, blue, purple, green, pink
    var title: String {
        switch self {
        case .sand: "모래빛"
        case .blue: "파랑"
        case .purple: "보라"
        case .green: "초록"
        case .pink: "분홍"
        }
    }
}
struct PreparationTag: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: PreparationTagIcon
    let color: PreparationTagColor
    static let defaults = [
        PreparationTag(id: "reading", name: "독서", icon: .reading, color: .sand),
        PreparationTag(id: "study", name: "공부", icon: .study, color: .purple),
        PreparationTag(id: "work", name: "업무", icon: .work, color: .blue),
        PreparationTag(id: "rest", name: "휴식", icon: .writing, color: .green),
    ]
}
struct TagEditorDraft: Equatable {
    var name: String = ""
    var icon: PreparationTagIcon = .reading
    var color: PreparationTagColor = .sand
}
enum TagNameIssue: Error, Equatable {
    case empty, tooLong, duplicate
    var message: String {
        switch self {
        case .empty: "태그 이름을 입력해주세요."
        case .tooLong: "태그 이름은 20자 이내로 입력해주세요."
        case .duplicate: "이미 있는 태그 이름이에요."
        }
    }
}
enum JourneySound: String, CaseIterable, Equatable, Codable {
    case bus, rainBus, subway, forest, none
    var title: String {
        switch self {
        case .bus: "버스"
        case .rainBus: "비 오는 버스"
        case .subway: "지하철"
        case .forest: "숲속"
        case .none: "소리 없음"
        }
    }
    var systemImage: String {
        switch self {
        case .bus: "bus"
        case .rainBus: "cloud.rain"
        case .subway: "tram"
        case .forest: "tree"
        case .none: "speaker.slash"
        }
    }
    var resourceName: String? {
        switch self {
        case .bus: "travel-bus-v2"
        case .rainBus: "travel-bus-rain-v2"
        case .subway: "travel-subway-v2"
        case .forest: "travel-forest-v2"
        case .none: nil
        }
    }
}
struct PreparationDraft: Equatable {
    private(set) var tags = PreparationTag.defaults
    private(set) var selectedTagID: String?
    private(set) var task = ""
    private(set) var sound: JourneySound = .none
    var selectedTag: PreparationTag? { tags.first { $0.id == selectedTagID } }
    var trimmedTask: String { task.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isComplete: Bool { selectedTag != nil && !trimmedTask.isEmpty }
    @discardableResult mutating func chooseTag(id: String) -> Bool {
        guard tags.contains(where: { $0.id == id }) else { return false }
        selectedTagID = id
        return true
    }
    mutating func setTask(_ value: String) {
        var result = String.UnicodeScalarView()
        var units = 0
        for scalar in value.unicodeScalars {
            let width = scalar.value > 0xFFFF ? 2 : 1
            guard units + width <= 80 else { break }
            result.append(scalar)
            units += width
        }
        task = String(result)
    }
    mutating func setSound(_ value: JourneySound) { sound = value }
    @discardableResult mutating func saveTag(_ editor: TagEditorDraft) -> Result<PreparationTag, TagNameIssue> {
        let name = editor.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .failure(.empty) }
        guard name.utf16.count <= 20 else { return .failure(.tooLong) }
        let normalized = name.precomposedStringWithCompatibilityMapping.lowercased()
        guard !tags.contains(where: {
            $0.name.precomposedStringWithCompatibilityMapping.lowercased() == normalized
        }) else { return .failure(.duplicate) }
        let tag = PreparationTag(id: UUID().uuidString,
                                 name: name,
                                 icon: editor.icon, color: editor.color)
        tags.append(tag)
        selectedTagID = tag.id
        return .success(tag)
    }
}
struct PreparedJourneyDetails: Equatable {
    let journey: JourneySelection
    let tag: PreparationTag
    let task: String
    let sound: JourneySound
    var originName: String { journey.originName }
    var boundLabel: String? { journey.boundLabel }
    var distanceText: String { RouteCandidates.distanceText(meters: journey.distanceMeters) }
}
