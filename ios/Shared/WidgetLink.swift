import Foundation

enum WidgetLinkTarget: Equatable {
    case journey(expectedID: String?)
    case newJourney(expectedID: String?)
    case analytics(day: String?, tag: String?, kind: AnalyticsPeriodKind = .week)
}
struct WidgetLink: Equatable { let issuedAt: Date; let target: WidgetLinkTarget }
enum WidgetLinkParseResult: Equatable { case valid(WidgetLink), expired, invalid }
enum WidgetLinkCodec {
    static func makeURL(_ link: WidgetLink) -> URL? {
        let seconds = link.issuedAt.timeIntervalSince1970
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int64.max) else { return nil }
        var value = URLComponents(); value.scheme = "focusmate"; value.host = "widget"
        var query = [URLQueryItem(name: "v", value: "1"), URLQueryItem(name: "issuedAt", value: String(Int64(seconds)))]
        switch link.target {
        case .journey(let id), .newJourney(let id):
            if case .journey = link.target { value.path = "/journey" } else { value.path = "/new" }
            if let id { guard validText(id) else { return nil }; query.append(URLQueryItem(name: "id", value: id)) }
        case .analytics(let day, let tag, let kind):
            value.path = "/analytics"
            if let day { guard validDay(day) else { return nil }; query.append(URLQueryItem(name: "day", value: day)) }
            if let tag { guard validText(tag) else { return nil }; query.append(URLQueryItem(name: "tag", value: tag)) }
            query.append(URLQueryItem(name: "period", value: kind.rawValue))
        }
        value.queryItems = query
        guard let url = value.url, url.absoluteString.utf8.count <= 8192 else { return nil }
        return url
    }
    static func parse(_ url: URL, now: Date) -> WidgetLinkParseResult {
        guard url.absoluteString.utf8.count <= 8192,
              let value = URLComponents(url: url, resolvingAgainstBaseURL: false),
              value.scheme == "focusmate", value.host == "widget", value.user == nil, value.password == nil,
              value.port == nil, value.fragment == nil, let items = value.queryItems else { return .invalid }
        var query: [String: String] = [:]
        for item in items {
            guard let field = item.value, query[item.name] == nil else { return .invalid }
            query[item.name] = field
        }
        guard query["v"] == "1", let raw = query["issuedAt"], !raw.isEmpty,
              raw.utf8.allSatisfy({ (48...57).contains($0) }), let seconds = Int64(raw),
              now.timeIntervalSince1970.isFinite else { return .invalid }
        let issued = Date(timeIntervalSince1970: Double(seconds))
        let age = now.timeIntervalSince(issued)
        guard age >= 0 else { return .invalid }
        let target: WidgetLinkTarget
        switch value.path {
        case "/journey", "/new":
            guard Set(query.keys).isSubset(of: ["v", "issuedAt", "id"]), query["id"].map(validText) ?? true else { return .invalid }
            target = value.path == "/journey" ? .journey(expectedID: query["id"]) : .newJourney(expectedID: query["id"])
        case "/analytics":
            guard Set(query.keys).isSubset(of: ["v", "issuedAt", "day", "tag", "period"]),
                  query["day"].map(validDay) ?? true, query["tag"].map(validText) ?? true,
                  let kind = AnalyticsPeriodKind(rawValue: query["period"] ?? "week") else { return .invalid }
            target = .analytics(day: query["day"], tag: query["tag"], kind: kind)
        default: return .invalid
        }
        return age < 86400 ? .valid(WidgetLink(issuedAt: issued, target: target)) : .expired
    }
    private static func validText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.utf8.count <= 2048 && !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    }
    private static func validDay(_ day: String) -> Bool {
        (try? RecordsAnalytics.period(kind: .week, containing: day, calendar: Calendar(identifier: .gregorian))) != nil
    }
}
